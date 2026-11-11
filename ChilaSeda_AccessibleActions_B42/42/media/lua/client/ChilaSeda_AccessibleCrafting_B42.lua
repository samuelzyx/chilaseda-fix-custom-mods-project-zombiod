require "ISUI/ISInventoryPaneContextMenu"
require "ChilaSeda_FoodMenuOrder_B42"
require "TimedActions/ISConsolidateDrainable"
require "Entity/TimedActions/ISHandcraftAction"
require "TimedActions/ISInventoryTransferUtil"
require "Entity/ISEntityUI"
require "ActionManager"

ChilaSedaAccessibleConsolidation = ChilaSedaAccessibleConsolidation or {}
local M = ChilaSedaAccessibleConsolidation

-- CraftRecipeManager scans the containers returned by this vanilla helper.
-- Add the carried inventory and each nested bag recursively so recipes can
-- consume reachable ingredients even when their bag is not open in a pane.
local vanillaGetContainers = ISInventoryPaneContextMenu.getContainers
if vanillaGetContainers then
    ISInventoryPaneContextMenu.getContainers = function(character, selectedItem)
        local result, visited = ArrayList.new(), {}
        local function addTree(container)
            if not container or visited[container] then return end
            visited[container] = true
            result:add(container)

            local items = container:getItems()
            if not items then return end
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and instanceof(item, "InventoryContainer") then
                    addTree(item:getInventory())
                end
            end
        end

        if character then addTree(character:getInventory()) end
        if selectedItem and selectedItem.getContainer then
            addTree(selectedItem:getContainer())
        end

        -- Vanilla builds the inventory context menu before it passes the
        -- selected item to recipe hooks. Expose those selected source
        -- containers during that call so corpse/container recipes can be
        -- discovered without moving the item into the main inventory first.
        local contextItems = ChilaSedaAccessibleActions
            and ChilaSedaAccessibleActions.contextRecipeItems
        for _, entry in ipairs(type(contextItems) == "table" and contextItems or {}) do
            if instanceof(entry, "InventoryItem") then
                addTree(entry:getContainer())
            elseif type(entry) == "table" and type(entry.items) == "table" then
                for index = 2, #entry.items do
                    local item = entry.items[index]
                    if item and instanceof(item, "InventoryItem") then
                        addTree(item:getContainer())
                    end
                end
            end
        end

        if character then
            local ok, vanillaContainers = pcall(vanillaGetContainers, character)
            if ok and vanillaContainers then
                for i = 0, vanillaContainers:size() - 1 do
                    addTree(vanillaContainers:get(i))
                end
            end
        end
        return result
    end
end

local vanillaCreateInventoryContextMenu = ISInventoryPaneContextMenu.createMenu
if vanillaCreateInventoryContextMenu then
    ISInventoryPaneContextMenu.createMenu = function(player, isInPlayerInventory, items, ...)
        local shared = ChilaSedaAccessibleActions
        local previousItems = shared and shared.contextRecipeItems
        if shared then shared.contextRecipeItems = items end

        local results = { pcall(vanillaCreateInventoryContextMenu,
            player, isInPlayerInventory, items, ...) }
        if shared then shared.contextRecipeItems = previousItems end
        if not results[1] then error(results[2], 0) end
        local unpackValues = table.unpack or unpack
        return unpackValues(results, 2)
    end
end

local function contextRecipeLogic(playerObj, recipe, selectedItem)
    local logic = HandcraftLogic.new(playerObj, nil, nil)
    logic:setIsoObject(logic:findCraftSurface(playerObj, 2))
    logic:setContainers(ISInventoryPaneContextMenu.getContainers(playerObj, selectedItem))
    logic:setRecipeFromContextClick(recipe, selectedItem)
    return logic
end

local function possibleContextRecipeCrafts(playerObj, recipe, selectedItem)
    local logic = contextRecipeLogic(playerObj, recipe, selectedItem)
    if not logic:canPerformCurrentRecipe() then return 0 end
    return math.max(0, math.floor(tonumber(logic:getPossibleCraftCount(true)) or 0))
end

local function textureForFullType(fullType)
    if type(fullType) ~= "string" or type(getScriptManager) ~= "function" then return nil end
    local okManager, manager = pcall(getScriptManager)
    if not okManager or not manager then return nil end
    local okItem, scriptItem = pcall(manager.FindItem, manager, fullType)
    if not okItem or not scriptItem then return nil end
    local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
    return okTexture and texture or nil
end

local activeRecipeBatch
local producingRecipeAction
local notifyCraftingDestination

local function safeMethod(object, methodName)
    if not object then return nil end
    local ok, method = pcall(function() return object[methodName] end)
    if ok and type(method) == "function" then return method end
    return nil
end

local function safeCall(object, methodName, ...)
    local method = safeMethod(object, methodName)
    if not method then return false, nil end
    return pcall(method, object, ...)
end

local function accessibleThreadItem(item)
    if not item then return false end
    local getFullType = safeMethod(item, "getFullType")
    if not getFullType then return false end
    local ok, fullType = pcall(getFullType, item)
    if not ok or type(fullType) ~= "string" then return false end
    if fullType == "Base.AnimalSinew" or fullType == "Base.Twine"
        or fullType == "Base.Rope" or fullType == "Base.SheetRope" then
        return true
    end

    local getTags = safeMethod(item, "getTags")
    if not getTags then return fullType == "Base.Twine" end
    local tagsOk, tags = pcall(getTags, item)
    if not tagsOk or not tags then return fullType == "Base.Twine" end

    local function hasTag(tag)
        if not tag then return false end
        local contains = safeMethod(tags, "contains")
        if not contains then return false end
        local success, matched = pcall(contains, tags, tag)
        return success and matched
    end

    return hasTag(ItemTag.THREAD)
        or hasTag(ItemTag.FISHING_LINE)
        or fullType == "Base.Twine" or fullType == "Base.Rope"
        or fullType == "Base.SheetRope"
end

-- The item/tag wrappers can still throw from Java-backed collections that
-- exist but fail during invocation. Keep context-menu hooks fail-closed so a
-- broken classification only hides this extra recipe option, never the menu.
local function isAccessibleThreadItem(item)
    local ok, accessible = pcall(accessibleThreadItem, item)
    return ok and accessible == true
end

local function threadRecipeAllowed(item, recipe)
    if not item or not recipe then return false end
    if item:getFullType() ~= "Base.AnimalSinew" then return true end
    local ok, name = safeCall(recipe, "getName")
    return ok and name == "MakeSinewThread"
end

local function isThreadOutput(fullType)
    return fullType == "Base.Twine" or fullType == "Base.Rope"
        or fullType == "Base.SheetRope" or fullType == "Base.Thread"
        or fullType == "Base.Thread_Sinew"
end

local function threadOutputFullType(recipe)
    if not recipe then return nil end
    local okOutputs, outputs = safeCall(recipe, "getOutputs")
    if okOutputs and outputs then
        local okSize, size = safeCall(outputs, "size")
        if okSize and type(size) == "number" then
            for index = 0, size - 1 do
                local okOutput, output = safeCall(outputs, "get", index)
                if okOutput and output then
                    local okScript, outputScript = safeCall(output, "getCreateToItemScript")
                    if okScript and outputScript then
                        local okItems, items = safeCall(outputScript, "getPossibleResultItems")
                        if okItems and items then
                            local okCount, count = safeCall(items, "size")
                            if okCount and type(count) == "number" then
                                for itemIndex = 0, count - 1 do
                                    local okItem, scriptItem = safeCall(items, "get", itemIndex)
                                    if okItem and scriptItem then
                                        local okName, fullType = safeCall(scriptItem, "getFullName")
                                        if okName and type(fullType) == "string"
                                            and isThreadOutput(fullType) then
                                            return fullType
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Compatibility fallback for older Recipe objects; Build 42 CraftRecipe
    -- instances expose outputs through getOutputs() instead.
    local okResult, result = safeCall(recipe, "getResult")
    if okResult and result then
        local okType, fullType = safeCall(result, "getFullType")
        if okType and type(fullType) == "string" and isThreadOutput(fullType) then
            return fullType
        end
    end
    return nil
end

local function producesThreadItem(recipe)
    return threadOutputFullType(recipe) ~= nil
end

local function recipeDestinations(batch)
	local player = batch and batch.player
	local inventory = player and player:getInventory()
	local destinations, seen = {}, {}
	local function add(container)
		if container and type(container.getType) == "function"
				and container:getType() == "floor" then return end
		if container and not seen[container] then
			seen[container] = true
			destinations[#destinations + 1] = container
		end
	end
	add(batch and batch.selectedDestination)
	local function addNested(container)
		if not container or type(container.getItems) ~= "function" then return end
		local items = container:getItems()
		if not items then return end
		for i = 0, items:size() - 1 do
			local item = items:get(i)
			if item and instanceof(item, "InventoryContainer") then
				local nested = item:getInventory()
				add(nested)
				addNested(nested)
			end
		end
	end
	addNested(inventory)
	add(batch and batch.sourceDestination)
	add(batch and batch.destination)
	add(inventory)
	return destinations, inventory
end

local function finishRecipeBatch(batch)
    if not batch or batch.finished then return end
    batch.finished = true
    local grouped, order = {}, {}
    for _, item in ipairs(batch.outputs) do
        if item then
            local key = item:getFullType()
            if not grouped[key] then grouped[key] = {}; order[#order + 1] = key end
            grouped[key][#grouped[key] + 1] = item
        end
    end
    local remaining = {}
    for _, key in ipairs(order) do
        local group = grouped[key]
        local selected = group[1]
        local targets = {}
        for index = 2, #group do targets[#targets + 1] = group[index] end
        if instanceof(selected, "DrainableComboItem") and selected:canConsolidate()
            and #targets > 0 then
            ISInventoryPaneContextMenu.onConsolidateAll(selected, targets, batch.player)
            for _, item in ipairs(group) do remaining[#remaining + 1] = item end
        else
            for _, item in ipairs(group) do remaining[#remaining + 1] = item end
        end
    end
    for _, item in ipairs(remaining) do
        local source = item and item:getContainer()
        local player = batch.player
        local inventory = player and player:getInventory()
        if item and source and inventory and inventory:contains(item) then
			local destinations = recipeDestinations(batch)
            local moved = false
			local storedIn
            for _, destination in ipairs(destinations) do
                if destination == inventory then
					moved, storedIn = true, inventory
                    break
                elseif destination and destination ~= source then
                    local transfer = ISInventoryTransferAction:new(
                        player, item, source, destination, nil)
                    if transfer and transfer:isValid() then
                        transfer:transferItem(item)
                        if destination:contains(item) then
							moved, storedIn = true, destination
                            break
                        end
                    end
                elseif destination == source then
					moved, storedIn = true, destination
                    break
                end
            end
            if not moved then
                local square = player:getCurrentSquare()
                if square and inventory:contains(item) then
                    inventory:Remove(item)
                    square:AddWorldInventoryItem(item,
                        player:getX() - math.floor(player:getX()),
                        player:getY() - math.floor(player:getY()),
                        player:getZ() - math.floor(player:getZ()))
					storedIn = nil
                end
            end
			if inventory:contains(item) then storedIn = inventory end
			notifyCraftingDestination(player, storedIn)
        end
    end
end

local originalAddOrDrop = Actions and Actions.addOrDropItem
local function craftingDestinationLabel(character, destination)
    if not destination then return nil end
    if destination == character:getInventory() then return "inventario principal" end
    local parent = destination.getParent and destination:getParent() or nil
    if parent and parent.getDisplayName then return parent:getDisplayName() end
    if destination.getType then return destination:getType() end
    return "contenedor"
end

notifyCraftingDestination = function(character, destination)
    if not HaloTextHelper or not HaloTextHelper.addText then return end
    local label = destination and craftingDestinationLabel(character, destination)
        or "el suelo"
    HaloTextHelper.addText(character, "Fabricado: " .. tostring(label), " ", 255, 220, 120)
end

if type(originalAddOrDrop) == "function" then
    Actions.addOrDropItem = function(character, item)
        if producingRecipeAction and producingRecipeAction.chilaSedaRecipeBatch
            and character == producingRecipeAction.chilaSedaRecipeBatch.player and item then
            local batch = producingRecipeAction.chilaSedaRecipeBatch
            local inventory = character:getInventory()
            local destinations = recipeDestinations(batch)
            if not inventory:contains(item) then inventory:AddItem(item) end
            for _, destination in ipairs(destinations) do
                if destination and destination ~= inventory and not destination:contains(item) then
                    local transfer = ISInventoryTransferAction:new(
                        character, item, inventory, destination, nil)
                    if transfer and transfer:isValid() then
                        transfer:transferItem(item)
                        if destination:contains(item) then
                            break
                        end
                    end
                elseif destination == inventory or destination and destination:contains(item) then
                    break
                end
            end
            batch.outputs[#batch.outputs + 1] = item
            return
        end
        return originalAddOrDrop(character, item)
    end
end

local originalPerformRecipe = ISHandcraftAction.performRecipe
ISHandcraftAction.performRecipe = function(self, ...)
    local batch = self.chilaSedaRecipeBatch
    local ownsBatch = false
    if not batch then
        local selectedDestination
        local pane = ISInventoryPane and ISInventoryPane.getInventoryPane
            and ISInventoryPane.getInventoryPane(self.character:getPlayerNum())
        if pane then selectedDestination = pane.selected end
        local sourceDestination
        if self.items then
            for i = 0, self.items:size() - 1 do
                local item = self.items:get(i)
                local container = item and item:getContainer()
                if container and container ~= self.character:getInventory() then
                    sourceDestination = container
                    break
                end
            end
        end
        batch = { player = self.character, outputs = {},
            selectedDestination = selectedDestination, sourceDestination = sourceDestination }
        self.chilaSedaRecipeBatch = batch
        ownsBatch = true
    end
    local previous = producingRecipeAction
    producingRecipeAction = self
    local ok, result = pcall(originalPerformRecipe, self, ...)
    producingRecipeAction = previous
    if not ok then error(result) end
    if ownsBatch then
        finishRecipeBatch(batch)
        self.chilaSedaRecipeBatch = nil
    end
    return result
end

local function threadBatchLabel(recipe)
    local fullType = threadOutputFullType(recipe)
    if not fullType then return "Fabricando" end
    if fullType == "Base.Twine" then return "Trenzando cordeles" end
    if fullType == "Base.Rope" or fullType == "Base.SheetRope" then return "Uniendo cuerdas" end
    if fullType == "Base.Thread" or fullType == "Base.Thread_Sinew" then return "Haciendo hilo" end
    return "Fabricando"
end

local originalStartMultiple = ISEntityUI.HandcraftStartMultiple
ISEntityUI.HandcraftStartMultiple = function(player, logic, force, quantity, addToQueue)
    local actions = originalStartMultiple(player, logic, force, quantity, addToQueue)
    local batch = activeRecipeBatch
    if batch and batch.player == player and type(actions) == "table" then
        local last = actions[#actions]
        for _, action in ipairs(actions) do
            action.chilaSedaRecipeBatch = batch
            action.label = batch.label
        end
        if last then
            local callback = last.onComplete
            local target = last.onCompleteTarget
            last:setOnComplete(function(target)
                if callback then callback(target) end
                finishRecipeBatch(batch)
            end, target)
        end
    end
    return actions
end

local function queueThreadRecipe(option, player, selected, recipe)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not selected or not selected:getContainer()
        or (not isAccessibleThreadItem(selected) and not producesThreadItem(recipe))
        or not threadRecipeAllowed(selected, recipe) then return end
    local quantity = possibleContextRecipeCrafts(playerObj, recipe, selected)
    if quantity < 1 then return end
    local batch = { player = playerObj, destination = selected:getContainer(),
        outputs = {}, label = threadBatchLabel(recipe) }
    local logic = contextRecipeLogic(playerObj, recipe, selected)
    local previous = activeRecipeBatch
    activeRecipeBatch = batch
    local ok, err = pcall(ISEntityUI.HandcraftStartMultiple, playerObj, logic, false, quantity, true)
    activeRecipeBatch = previous
    if not ok then error(err) end
end

local vanillaRecipeContext = ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu
if vanillaRecipeContext then
    ISInventoryPaneContextMenu.addNewCraftingDynamicalContextMenu = function(
        selectedItem, context, recipeList, player, containerList, ...)
        local result = vanillaRecipeContext(selectedItem, context, recipeList, player, containerList, ...)
        if not selectedItem or not selectedItem:getContainer() then return result end
        local playerObj = getSpecificPlayer(player)
        if not playerObj then return result end
        local recipes = {}
        local count = 0
        if recipeList then
            local ok, size = pcall(function() return recipeList:size() end)
            count = ok and size or #recipeList
        end
        for index = 0, count - 1 do
            local recipe = recipeList.get and recipeList:get(index) or recipeList[index + 1]
            if threadRecipeAllowed(selectedItem, recipe) then
                local outputType = threadOutputFullType(recipe)
                if outputType then
                    local available = possibleContextRecipeCrafts(playerObj, recipe, selectedItem)
                    if available > 0 then
                        recipes[#recipes + 1] = {
                            recipe = recipe,
                            count = available,
                            outputType = outputType,
                        }
                    end
                end
            end
        end
        if #recipes == 0 then return result end
        local function addRecipeOption(targetContext, entry)
            local outputType = entry.outputType
            local outputName = getItemNameFromFullType(outputType)
            local label = "Encolar " .. outputName .. " (" .. entry.count .. ")"
            local option = targetContext:addOption(label, player, queueThreadRecipe, selectedItem, entry.recipe)
            option.iconTexture = textureForFullType(outputType)
            ChilaSedaFoodMenuOrder.move(targetContext, option)
        end
        if #recipes == 1 then
            addRecipeOption(context, recipes[1])
        else
            local option = context:addOption("Encolar fabricaciones posibles", nil, nil)
            option.iconTexture = textureForFullType("Base.Thread")
            local submenu = context:getNew(context)
            context:addSubMenu(option, submenu)
            for _, entry in ipairs(recipes) do addRecipeOption(submenu, entry) end
            ChilaSedaFoodMenuOrder.move(context, option)
        end
        return result
    end
end

local function containersFor(character, chosen)
    local result, visited = {}, {}
    local function addTree(container)
        if not container or visited[container] then return end
        visited[container] = true
        result[#result + 1] = container
        local items = container:getItems()
        if not items then return end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and instanceof(item, "InventoryContainer") then
                addTree(item:getInventory())
            end
        end
    end

    addTree(character and character:getInventory())
    addTree(chosen and chosen:getContainer())

    local paneMenu = rawget(_G, "ISInventoryPaneContextMenu")
    if paneMenu and paneMenu.getContainers then
        local ok, nearby = pcall(paneMenu.getContainers, character)
        if ok and nearby then
            for i = 0, nearby:size() - 1 do addTree(nearby:get(i)) end
        end
    end
    return result
end

local function containsAccessible(character, item)
    if not item then return false end
    local container = item:getContainer()
    if not container then return false end
    for _, accessible in ipairs(containersFor(character, item)) do
        if accessible == container then
            return container:contains(item)
        end
    end
    return false
end

local function collectTargets(character, selected)
    local targets = {}
    local seen = {}
    for _, container in ipairs(containersFor(character, selected)) do
        local items = container:getItems()
        if items then
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                if item and item ~= selected and not seen[item:getID()]
                    and item:getType() == selected:getType()
                    and instanceof(item, "DrainableComboItem")
                    and item:getCurrentUsesFloat() < 1 then
                    seen[item:getID()] = true
                    targets[#targets + 1] = item
                end
            end
        end
    end
    return targets
end

-- Put the accessible consolidation entries at the exact vanilla menu insertion
-- point (after Equip). The later inventory-menu event does not reliably retain
-- the same selected drainable for grouped and vehicle-container rows.
local vanillaCheckConsolidate = ISInventoryPaneContextMenu.checkConsolidate
ISInventoryPaneContextMenu.checkConsolidate = function(drainable, playerObj, context, previousPourInto)
    vanillaCheckConsolidate(drainable, playerObj, context, previousPourInto)
    if not drainable or not instanceof(drainable, "DrainableComboItem")
        or drainable:getCurrentUsesFloat() <= 0 then
        return
    end

    local targets = collectTargets(playerObj, drainable)
    if #targets == 0 then return end

    local label = getText("ContextMenu_Pour_into")
    if drainable:getConsolidateOption() then
        label = getText(drainable:getConsolidateOption())
    end
    context:removeOptionByName(label)

    local option = context:addOption(label, nil, nil)
    option.iconTexture = drainable:getTexture()
    local submenu = context:getNew(context)
    context:addSubMenu(option, submenu)

    if #targets > 1 then
        local mergeAll = submenu:addOption(getText("ContextMenu_MergeAll"), drainable,
            ISInventoryPaneContextMenu.onConsolidateAll, targets, playerObj)
        mergeAll.iconTexture = drainable:getTexture()
    end
    for _, target in ipairs(targets) do
        local percent = math.floor(target:getCurrentUsesFloat() * 100)
        local option = submenu:addOption(target:getName() .. " (" .. percent
            .. getText("ContextMenu_FullPercent") .. ")", drainable,
            ISInventoryPaneContextMenu.onConsolidate, target, playerObj)
        option.iconTexture = target:getTexture()
    end
end

-- Vanilla's action only validates items in the main inventory. Keep the same action
-- and animation while accepting items in carried bags and currently open containers.
function ISConsolidateDrainable:isValid()
    if not containsAccessible(self.character, self.intoItem)
        or not containsAccessible(self.character, self.drainable) then
        return false
    end
    if self.otherItems then
        for _, item in ipairs(self.otherItems) do
            if item and containsAccessible(self.character, item) then return true end
        end
        return false
    end
    return true
end

local vanillaStart = ISConsolidateDrainable.start
function ISConsolidateDrainable:start()
    if isClient() and self.intoItem and self.drainable then
        local inventory = self.character:getInventory()
        self.intoItem = inventory:getItemById(self.intoItem:getID()) or self.intoItem
        self.drainable = inventory:getItemById(self.drainable:getID()) or self.drainable
    end
    return vanillaStart(self)
end

function ISConsolidateDrainable:nextItem()
    if not self.otherItems then return nil end
    while #self.otherItems > 0 do
        local item = table.remove(self.otherItems, 1)
        if item and item:getCurrentUsesFloat() > 0 and containsAccessible(self.character, item) then
            return item
        end
    end
    return nil
end
