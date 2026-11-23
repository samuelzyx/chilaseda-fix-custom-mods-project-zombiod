local viewpointLoaded = pcall(require, "Viewpoint_Loot")
local viewpointLootAvailable = viewpointLoaded and type(ViewpointLoot) == "table"
local TAG = "[ChilaSeda_ViewpointSelectedContainer] "
if not viewpointLootAvailable then
    print(TAG .. "Viewpoint loot API unavailable; continuing with vanilla transfer routing.")
end
pcall(require, "Foraging/ISForageIcon")
pcall(require, "Foraging/ISWorldItemIcon")
pcall(require, "TimedActions/ISGrabItemAction")
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISContextMenu"
local fireTransfersLoaded, fireTransfers = pcall(require, "ChilaSeda_ViewpointFireTransfers")
local fireTransfersAvailable = fireTransfersLoaded and type(fireTransfers) == "table"

local function translatedText(key, ...)
	if type(getText) ~= "function" then return key end
	local ok, value = pcall(getText, key, ...)
	if not ok or type(value) ~= "string" or value == "" or value == key then return key end
	for index, replacement in ipairs({...}) do
		value = value:gsub("%%" .. index, function() return tostring(replacement) end)
	end
	return value
end

local function selectedDestination(playerNum)
    local page = getPlayerInventory(playerNum)
    if not page then return nil, nil end

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(playerNum) or nil
    local main = player and player:getInventory() or page.inventory
    local selected = (page.inventoryPane and page.inventoryPane.inventory) or page.inventory
    if selected and selected ~= main and type(selected.getItems) == "function"
            and selected:getType() ~= "floor" then
        return selected, page
    end
    return main, page
end

local function selectedDestinationForIcon(icon, requested)
	-- ISBaseIcon's native "Put in container" submenu passes its choice here.
	-- Keep even an explicit root-inventory choice; only direct clicks without
	-- a target should inherit the currently selected inventory pane container.
	if requested ~= nil then return requested end
	if not icon then return nil end
	local selected = selectedDestination(icon.player)
	return selected
end

local function canStoreIn(container, player, item)
    if not container or not player or not item then return false end
    return container:isItemAllowed(item) and container:hasRoomFor(player, item)
        and container:getCapacityWeight() + item:getUnequippedWeight()
            <= container:getEffectiveCapacity(player)
end

if ISGrabItemAction and type(ISGrabItemAction.new) == "function"
		and not ISGrabItemAction.ChilaSedaSelectedContainer then
	local originalGrabNew = ISGrabItemAction.new
	ISGrabItemAction.new = function(self, player, worldItem, time, ...)
		local action = originalGrabNew(self, player, worldItem, time, ...)
		local selected = player and selectedDestination(player:getPlayerNum()) or nil
		local root = player and player:getInventory()
		local item = worldItem and worldItem.getItem and worldItem:getItem() or nil
		if not action or not selected or selected == root or not item
				or not canStoreIn(selected, player, item) then
			return action
		end
		local queue = ISTimedActionQueue.getTimedActionQueue(player)
		local last = queue and queue.queue and queue.queue[#queue.queue]
		if action.ignoreAction and last and last.Type == "ISGrabItemAction" then
			last.destContainer = selected
		else
			action.destContainer = selected
		end
		return action
	end
	ISGrabItemAction.ChilaSedaSelectedContainer = true
end

local function itemDisplayName(item)
	if not item then return nil end
	local display = item.getDisplayName and item:getDisplayName() or nil
	local itemType = item.getType and item:getType() or nil
	if display and display ~= "" and display ~= itemType then return display end
	local fullType = item.getFullType and item:getFullType() or nil
	if fullType and type(getText) == "function" then
		local key = "ItemName_" .. fullType
		local translated = getText(key)
		if translated and translated ~= key then return translated end
	end
	return display or translatedText("UI_ChilaSeda_Viewpoint_ItemUnknown") or itemType
end

local function containerIcon(container)
	if not container or type(container.getContainingItem) ~= "function" then return nil end
	local ok, owner = pcall(container.getContainingItem, container)
	if not ok or not owner or type(owner.getTexture) ~= "function" then return nil end
	local textureOk, texture = pcall(owner.getTexture, owner)
	return textureOk and texture or nil
end

local destinationName

local function selectDestinationFromMenu(page, container)
	if not page or not container then return end
	if type(page.selectButtonForContainer) == "function" then
		page:selectButtonForContainer(container)
	end
	if page.inventoryPane and page.inventoryPane.inventory ~= container
			and type(page.setNewContainer) == "function" then
		page:setNewContainer(container)
	end
	if page.inventoryPane then page.inventoryPane.lastinventory = container end
	local player = getSpecificPlayer(page.player)
	if player and HaloTextHelper and type(HaloTextHelper.addText) == "function" then
		HaloTextHelper.addText(player,
			translatedText("UI_ChilaSeda_Viewpoint_DestinationSelected", destinationName(player, container)),
			containerIcon(container) or " ", 255, 220, 120)
	end
end

local function canStoreBatch(container, player, items)
	if not container or not player or not items then return false end
	local plannedWeight = 0
	for _, item in ipairs(items) do
		if item and not instanceof(item, "InventoryContainer") then
			local weight
			local ok, fits = pcall(function()
				weight = item:getUnequippedWeight()
				return container:isItemAllowed(item) and container:hasRoomFor(player, item)
					and container:getCapacityWeight() + plannedWeight + weight
						<= container:getEffectiveCapacity(player)
			end)
			if not ok or not fits then return false end
			plannedWeight = plannedWeight + weight
		end
	end
	return true
end

local function showAlternateDestinationMenu(player, page, selected, items)
	if not player or not page or not ISContextMenu or type(ISContextMenu.get) ~= "function" then
		return false
	end
	local destinations, seen = {}, {}
	local function add(container)
		if not container or container == selected or seen[container]
				or not canStoreBatch(container, player, items) then return end
		seen[container] = true
		destinations[#destinations + 1] = container
	end
	add(player:getInventory())
	local worn = player:getWornItems()
	if worn then
		for i = 0, worn:size() - 1 do
			local wornItem = worn:getItemByIndex(i)
			if wornItem and instanceof(wornItem, "InventoryContainer")
					and not player:isHandItem(wornItem) then
				add(wornItem:getInventory())
			end
		end
	end
	if #destinations == 0 then
		if HaloTextHelper and type(HaloTextHelper.addText) == "function" then
			HaloTextHelper.addText(player,
				translatedText("UI_ChilaSeda_Viewpoint_NoAlternateDestination"),
				containerIcon(selected) or " ", 255, 220, 120)
		end
		return false
	end
	local playerNum = player:getPlayerNum()
	local x = type(getMouseX) == "function" and getMouseX() or 0
	local y = type(getMouseY) == "function" and getMouseY() or 0
	local menu = ISContextMenu.get(playerNum, x, y)
	if not menu then return false end
	local header = menu:addOption(translatedText("UI_ChilaSeda_Viewpoint_SelectedBackpackFull"), nil, nil)
	if header then header.notAvailable = true end
	local prompt = menu:addOption(translatedText("UI_ChilaSeda_Viewpoint_ChooseDestinationRetry"), nil, nil)
	if prompt then prompt.notAvailable = true end
	for _, container in ipairs(destinations) do
		menu:addOption(destinationName(player, container), page,
			selectDestinationFromMenu, container)
	end
	menu:addOption(translatedText("UI_ChilaSeda_Viewpoint_CancelLeaveInPlace"), nil, nil)
	return true
end

local function findContainerOwnerItem(root, target, visited)
	if not root or not target or visited[root] then return nil end
	visited[root] = true
	local items = root:getItems()
	if not items then return nil end
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		if item and item.getInventory then
			local child = item:getInventory()
			if child == target then return item end
			local owner = findContainerOwnerItem(child, target, visited)
			if owner then return owner end
		end
	end
	return nil
end

destinationName = function(player, container)
    if container == player:getInventory() then return translatedText("UI_ChilaSeda_Viewpoint_MainInventory") end
    local containingItem = container and container.getContainingItem
        and container:getContainingItem() or nil
    if not containingItem then
		containingItem = findContainerOwnerItem(player:getInventory(), container, {})
	end
	if not containingItem then
		local function searchOpenPage(ui)
			local root = ui and ui.inventoryPane and ui.inventoryPane.inventory
			return root and findContainerOwnerItem(root, container, {}) or nil
		end
		local playerNum = player:getPlayerNum()
		local page = type(getPlayerInventory) == "function" and getPlayerInventory(playerNum) or nil
		local loot = type(getPlayerLoot) == "function" and getPlayerLoot(playerNum) or nil
		containingItem = searchOpenPage(page) or searchOpenPage(loot)
	end
	local displayName = itemDisplayName(containingItem)
	if displayName then
		return displayName
    end
    local parent = container and container.getParent and container:getParent() or nil
    if parent and parent.getDisplayName then return parent:getDisplayName() end
    return container and container.getType and container:getType()
		or translatedText("UI_ChilaSeda_Viewpoint_Container")
end

local storedItemNoticeAt = setmetatable({}, { __mode = "k" })
local function notifyStoredItem(player, item)
	if not player or not item or not HaloTextHelper or type(HaloTextHelper.addText) ~= "function" then return end
	local ok, container = pcall(item.getContainer, item)
	if not ok or not container then return end
	local now = type(getTimestampMs) == "function" and getTimestampMs() or math.floor(os.clock() * 1000)
	local previous = storedItemNoticeAt[item]
	if previous and now - previous < 500 then return end
	storedItemNoticeAt[item] = now
	local name = itemDisplayName(item) or translatedText("UI_ChilaSeda_Viewpoint_ItemUnknown")
	local icon
	if type(item.getTexture) == "function" then
		local textureOk, texture = pcall(item.getTexture, item)
		if textureOk then icon = texture end
	end
	local overflowFrom = type(ChilaSeda_ViewpointPickupOverflowSource) == "function"
		and ChilaSeda_ViewpointPickupOverflowSource(item) or nil
	local message = overflowFrom and translatedText("UI_ChilaSeda_Viewpoint_ItemStoredFallback",
		name, destinationName(player, overflowFrom))
		or translatedText("UI_ChilaSeda_Viewpoint_ItemStored", name, destinationName(player, container))
	HaloTextHelper.addText(player, message, icon or " ", 255, 220, 120)
end
ChilaSeda_ViewpointNotifyStoredItem = notifyStoredItem

local function attachStoredItemNotice(action, player, item)
	if not action or not item or action.ChilaSedaDestinationNotice then return action end
	local originalPerform = action.perform
	if type(originalPerform) ~= "function" then return action end
	action.ChilaSedaDestinationNotice = true
	action.perform = function(self, ...)
		local result = originalPerform(self, ...)
		notifyStoredItem(player or self.character, item)
		return result
	end
	return action
end

local originalTransferFactory = ISInventoryTransferUtil.newInventoryTransferAction
local function installFireActionCallbacks()
	if not fireTransfersAvailable then return end
	pcall(require, "Camping/ISCampingMenu")
	if type(ISCampingMenu) ~= "table" then return end
	local installed = fireTransfers.install(ISCampingMenu)
	if installed > 0 then
		print(TAG .. "fire input callbacks wrapped=" .. tostring(installed))
	end
end

installFireActionCallbacks()
Events.OnGameStart.Add(installFireActionCallbacks)
Events.OnCreatePlayer.Add(installFireActionCallbacks)

ISInventoryTransferUtil.newInventoryTransferAction = function(player, item, source, destination, time, ...)
    local main = player and player:getInventory()
    local selected = player and selectedDestination(player:getPlayerNum()) or nil
    local sourceInPlayerInventory = source and main and source:getOutermostContainer() == main
	local fireCallback = fireTransfersAvailable
		and fireTransfers.callbackFor(player, source, destination, main) or nil
	if fireCallback then
		fireTransfers.trace(fireCallback, item, source)
		return originalTransferFactory(player, item, source, main, time, ...)
	end
    local pickupToPlayer = player and item and source and not sourceInPlayerInventory
        and (destination == main or destination == selected)
    if not pickupToPlayer then
        return originalTransferFactory(player, item, source, destination, time, ...)
    end

    -- Equipping from a corpse must put the item in the character's root
    -- inventory first; ISEquipWeaponAction:isValid() searches that inventory
    -- by ID and cancels if corpse-loot routing sends it to a nested bag.
    if ChilaSeda_EquipFromCorpse == true and destination == main then
        return attachStoredItemNotice(
			originalTransferFactory(player, item, source, main, time, ...), player, item)
    end

    local target = selected or main
    if target ~= main and not canStoreIn(target, player, item) then target = main end
    local action = originalTransferFactory(player, item, source, target, time, ...)
    if action and action:isValid() then
        return attachStoredItemNotice(action, player, item)
    end

    if target ~= main then
        target = main
        action = originalTransferFactory(player, item, source, target, time, ...)
    end
    if action and action:isValid() then return attachStoredItemNotice(action, player, item) end
	return action
end

pcall(require, "TimedActions/ISForageAction")
if ISForageAction and type(ISForageAction.perform) == "function"
		and not ISForageAction.ChilaSedaDestinationNotice then
	local originalForagePerform = ISForageAction.perform
	local function snapshotStoredItems(container, itemSet, containerSet)
		if not container or containerSet[container] then return end
		containerSet[container] = true
		local ok, items = pcall(container.getItems, container)
		if not ok or not items then return end
		for index = 0, items:size() - 1 do
			local item = items:get(index)
			if item and not itemSet[item] then
				itemSet[item] = true
				if item.getInventory then
					local childOk, child = pcall(item.getInventory, item)
					if childOk and child then snapshotStoredItems(child, itemSet, containerSet) end
				end
			end
		end
	end
	ISForageAction.perform = function(action, ...)
		local player = action.character
		local before, after = {}, {}
		if player and player.getInventory then
			snapshotStoredItems(player:getInventory(), before, {})
		end
		local result = originalForagePerform(action, ...)
		if player and player.getInventory then
			snapshotStoredItems(player:getInventory(), after, {})
			for item in pairs(after) do
				if not before[item] then notifyStoredItem(player, item) end
			end
		end
		return result
	end
	ISForageAction.ChilaSedaDestinationNotice = true
end

local originalGrabPerform = ISGrabItemAction and ISGrabItemAction.perform
if type(originalGrabPerform) == "function" and not ISGrabItemAction.ChilaSedaDestinationNotice then
	ISGrabItemAction.perform = function(action, ...)
		local queuedItems = {}
		local queued = action.queueList and action.queueList[1]
		for _, worldItem in ipairs(queued and queued.items or {}) do
			local item = worldItem and worldItem.getItem and worldItem:getItem() or nil
			if item then queuedItems[#queuedItems + 1] = item end
		end
		if #queuedItems == 0 then
			local item = action.item and action.item:getItem() or nil
			if item then queuedItems[1] = item end
		end
		local result = originalGrabPerform(action, ...)
		for _, item in ipairs(queuedItems) do notifyStoredItem(action.character, item) end
		return result
	end
	ISGrabItemAction.ChilaSedaDestinationNotice = true
end

local function withSelectedPageInventory(playerNum, callback, ...)
    local destination, page = selectedDestination(playerNum)
    if not destination or not page or destination == page.inventory then
        return callback(...)
    end

    local previous = page.inventory
    page.inventory = destination
    local ok, result = pcall(callback, ...)
    page.inventory = previous
    if not ok then error(result, 0) end
    return result
end

local function collectViewpointLootItems(items)
    local result = {}
    if not items then return result end
    if type(items) == "table" then
        for _, item in ipairs(items) do
            if item then result[#result + 1] = item end
        end
    elseif type(items.size) == "function" and type(items.get) == "function" then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if item then result[#result + 1] = item end
        end
    end
    return result
end

local function deferViewpointPickupForDestination(player, items)
    if not player then return false end
    local destination, page = selectedDestination(player:getPlayerNum())
    if not destination or not page or destination == page.inventory then return false end

    local eligible = {}
    for _, item in ipairs(items) do
        local unwanted = type(item.isUnwanted) == "function" and item:isUnwanted(player)
        local heavy = isForceDropHeavyItem and isForceDropHeavyItem(item)
        if not unwanted and not heavy then eligible[#eligible + 1] = item end
    end
    if #eligible == 0 or canStoreBatch(destination, player, eligible) then return false end

    showAlternateDestinationMenu(player, page, destination, eligible)
    return true
end

if ViewpointLoot and type(ViewpointLoot.take) == "function" then
    local originalTake = ViewpointLoot.take
    ViewpointLoot.take = function(player, item, ...)
        if deferViewpointPickupForDestination(player, { item }) then return end
        return withSelectedPageInventory(player:getPlayerNum(), originalTake, player, item, ...)
    end
end

if ViewpointLoot and type(ViewpointLoot.takeAll) == "function" then
    local originalTakeAll = ViewpointLoot.takeAll
    ViewpointLoot.takeAll = function(player, items, ...)
        if deferViewpointPickupForDestination(player, collectViewpointLootItems(items)) then return end
        return withSelectedPageInventory(player:getPlayerNum(), originalTakeAll, player, items, ...)
    end
end

local function isModActive(modId)
    if type(getActivatedMods) ~= "function" then return false end
    local ok, mods = pcall(getActivatedMods)
    if not ok or not mods then return false end
    if type(mods.contains) == "function" then
        local containsOk, contains = pcall(mods.contains, mods, modId)
        return containsOk and contains == true
    end
    if type(mods.size) == "function" and type(mods.get) == "function" then
        for i = 0, mods:size() - 1 do
            if mods:get(i) == modId then return true end
        end
    end
    return false
end

if isModActive("ViewpointForaging") and ISForageIcon
        and type(ISForageIcon.doForage) == "function" then
    local originalDoForage = ISForageIcon.doForage
    ISForageIcon.doForage = function(icon, x, y, contextOption, targetContainer)
        local destination = selectedDestinationForIcon(icon, targetContainer)
        return originalDoForage(icon, x, y, contextOption, destination)
    end
end

if isModActive("ViewpointForaging") and ISWorldItemIcon
        and type(ISWorldItemIcon.doPickup) == "function" then
    local originalDoPickup = ISWorldItemIcon.doPickup
    ISWorldItemIcon.doPickup = function(icon, x, y, contextOption, targetContainer, items)
        local destination = selectedDestinationForIcon(icon, targetContainer)
        return originalDoPickup(icon, x, y, contextOption, destination, items)
    end
end

local function installViewpointUI()
    local actions = ViewpointUI and ViewpointUI.Inventory and ViewpointUI.Inventory.Actions
    if not actions then return end

    if type(actions.planLoot) == "function" and not actions.ChilaSedaSelectedContainerPlan then
        local originalPlanLoot = actions.planLoot
        actions.planLoot = function(player, items, ...)
            local plan = originalPlanLoot(player, items, ...)
            local destination, page = selectedDestination(player:getPlayerNum())
            if not destination or not page or destination == player:getInventory() then return plan end

            local selectedPlan, overflowItems = {}, {}
            local planned = 0
            for _, entry in ipairs(plan) do
                local item = entry.item
                if item and not instanceof(item, "InventoryContainer") then
                    local weight = item:getUnequippedWeight()
                    if destination:isItemAllowed(item) and destination:hasRoomFor(player, item)
                            and destination:getCapacityWeight() + planned + weight
                                <= destination:getEffectiveCapacity(player) then
                        entry.dest = destination
                        planned = planned + weight
						table.insert(selectedPlan, entry)
					else
						table.insert(overflowItems, item)
                    end
				elseif item then
					table.insert(selectedPlan, entry)
                end
            end
			if #overflowItems > 0 then
				showAlternateDestinationMenu(player, page, destination, overflowItems)
				-- Do not let the items that fit move while the player is still
				-- deciding where the overflow should go. Dismissing the menu is
				-- cancellation: the complete batch stays in its source container.
				return {}
			end
			return selectedPlan
        end
        actions.ChilaSedaSelectedContainerPlan = true
    end

    if type(actions.grabWorldItem) == "function" and not actions.ChilaSedaSelectedContainerGrab then
        local originalGrabWorldItem = actions.grabWorldItem
        actions.grabWorldItem = function(player, worldItem, ...)
            if not player or not worldItem then
                return originalGrabWorldItem(player, worldItem, ...)
            end

            local item = worldItem:getItem()
            local source = item and item:getContainer()
            if not item or not source or (isForceDropHeavyItem and isForceDropHeavyItem(item)) then
                return originalGrabWorldItem(player, worldItem, ...)
            end

            local plan = actions.planLoot(player, { item })
            local destination = plan[1] and plan[1].dest
            local square = worldItem:getSquare()
            if destination and square and luautils.walkAdj(player, square) then
                ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(
                    player, item, source, destination))
            end
        end
        actions.ChilaSedaSelectedContainerGrab = true
    end

    print(TAG .. "Viewpoint UI loot routing installed")
end

installViewpointUI()
Events.OnGameStart.Add(installViewpointUI)
Events.OnCreatePlayer.Add(installViewpointUI)

local MAX_DESTINATION_MENU_TRACES, MAX_DESTINATION_CHOICE_TRACES = 12, 24
local destinationMenuTraceCount, destinationChoiceTraceCount = 0, 0

local function isDestinationChoiceAction(action)
	local fn = action and action.fn
	local world = ISWorldObjectContextMenu
	local animal = AnimalContextMenu
	local inventory = ISInventoryPaneContextMenu
	local build = ISInventoryBuildMenu
	local loot = ViewpointLoot
	return fn ~= nil and (
		world and (fn == world.onGrabWItem or fn == world.onGrabHalfWItems
			or fn == world.onGrabAllWItems or fn == world.onGrabCorpseItem)
		or animal and (fn == animal.onButcherAnimal or fn == animal.onGetAnimalBones
			or fn == animal.onButcherAnimalFromInv or fn == animal.onGetAnimalBonesFromInv)
		or inventory and fn == inventory.grabCorpseItem
		or build and fn == build.onTakeThing
		or loot and (fn == loot.take or fn == loot.takeAll)) == true
end

local function expandDestinationActionList(actions, destinations, destinationLabel)
	local expanded, added = {}, 0
	for _, action in ipairs(actions or {}) do
		if isDestinationChoiceAction(action) and action.enabled and destinations and #destinations > 0 then
			for _, destination in ipairs(destinations or {}) do
				local variant = {}
				for key, value in pairs(action) do variant[key] = value end
				variant.name = action.name .. " > " .. destinationLabel(action, destination)
				variant.chilaSedaDestination = destination
				variant.chilaSedaDestinationSource = action
				expanded[#expanded + 1] = variant
				added = added + 1
			end
		else
			expanded[#expanded + 1] = action
		end
	end
	return expanded, added
end

local function runWithChosenDestination(action, player, getPage, chooseDestination, callback)
	local destination = action and action.chilaSedaDestination
	if not destination then return callback() end
	local page = getPage(player:getPlayerNum())
	if not page or not page.inventoryPane then return false end
	if page.inventoryPane.inventory ~= destination then chooseDestination(page, destination) end
	return callback()
end

local function interactionDestinations(playerNum)
	local page = type(getPlayerInventory) == "function" and getPlayerInventory(playerNum) or nil
	local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(playerNum) or nil
	local root = player and player:getInventory() or page and page.inventory
	if not page or not root then return {}, nil end
	local destinations, seen = {}, {}
	local function add(container)
		if not container or seen[container] or type(container.getItems) ~= "function" then return end
		local ok, kind = pcall(container.getType, container)
		if ok and kind == "floor" then return end
		seen[container] = true
		destinations[#destinations + 1] = container
	end
	add(root)
	for _, backpack in ipairs(page.backpacks or {}) do
		add(backpack and backpack.inventory)
	end
	return destinations, player
end

local function installViewpointDestinationActions()
	pcall(require, "ISUI/ISWorldObjectContextMenu")
	pcall(require, "ISUI/Animal/ISAnimalContextMenu")
	pcall(require, "ISUI/ISInventoryPaneContextMenu")
	pcall(require, "ISUI/ISInventoryBuildMenu")
	pcall(require, "Viewpoint_Interact")
	local interact = ViewpointInteract
	if not interact or type(interact.build) ~= "function" or type(interact.finish) ~= "function"
			or type(interact.run) ~= "function" or interact.ChilaSedaDestinationActionsInstalled then return end

	local originalBuild = interact.build
	interact.build = function(playerNum, ...)
		interact.chilaSedaDestinationPlayerNum = playerNum
		return originalBuild(playerNum, ...)
	end

	local originalFinish = interact.finish
	interact.finish = function(actions, title, seen, thing)
		local result = originalFinish(actions, title, seen, thing)
		local ordered = interact.actions or {}
		local destinations, player = interactionDestinations(interact.chilaSedaDestinationPlayerNum or 0)
		if not player or #destinations == 0 then return result end
		local expanded, added = expandDestinationActionList(ordered, destinations, function(action, container)
			return translatedText("ContextMenu_PutInContainer", destinationName(player, container))
		end)
		if added == 0 then return result end
		local sourceIndexes = {}
		for index, action in ipairs(ordered) do sourceIndexes[action] = index end
		local labels, enabled, deliberate, tips, icons = {}, {}, {}, {}, {}
		for index, action in ipairs(expanded) do
			local source = action.chilaSedaDestinationSource or action
			local sourceIndex = sourceIndexes[source]
			labels[index] = action.name
			enabled[index] = action.enabled
			deliberate[index] = action.deliberate == true
			if sourceIndex then
				tips[index] = result.tips and result.tips[sourceIndex]
				icons[index] = result.icons and result.icons[sourceIndex]
			end
		end
		interact.actions = expanded
		result.labels, result.enabled = labels, enabled
		result.deliberate, result.tips, result.icons = deliberate, tips, icons
		if destinationMenuTraceCount < MAX_DESTINATION_MENU_TRACES then
			destinationMenuTraceCount = destinationMenuTraceCount + 1
			print(TAG .. "destination-menu title=" .. tostring(title) .. " actions=" .. tostring(#ordered)
				.. " choices=" .. tostring(added) .. " containers=" .. tostring(#destinations))
		end
		return result
	end

	local originalRun = interact.run
	interact.run = function(player, index, side, ...)
		local extraArgs, extraArgCount = { ... }, select("#", ...)
		local action = interact.actions and interact.actions[index]
		if action and action.chilaSedaDestination then
			local ok, result = pcall(runWithChosenDestination, action, player, getPlayerInventory,
				selectDestinationFromMenu,
				function() return originalRun(player, index, side, unpack(extraArgs, 1, extraArgCount)) end)
			if not ok then error(result, 0) end
			if result == false then return end
			if destinationChoiceTraceCount < MAX_DESTINATION_CHOICE_TRACES then
				destinationChoiceTraceCount = destinationChoiceTraceCount + 1
				print(TAG .. "destination-choice action=" .. tostring(action.chilaSedaDestinationSource.name)
					.. " container=" .. destinationName(player, action.chilaSedaDestination))
			end
			return result
		end
		return originalRun(player, index, side, unpack(extraArgs, 1, extraArgCount))
	end
	interact.ChilaSedaDestinationActionsInstalled = true
	print(TAG .. "Viewpoint native destination choices installed")
end

installViewpointDestinationActions()
Events.OnGameStart.Add(installViewpointDestinationActions)
Events.OnCreatePlayer.Add(installViewpointDestinationActions)

print(TAG .. "Selected-container transfer routing loaded")
