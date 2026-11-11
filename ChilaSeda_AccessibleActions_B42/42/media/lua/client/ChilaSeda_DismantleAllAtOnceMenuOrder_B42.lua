-- Repositions Dismantle All at Once options without editing its Workshop files.
require "ISUI/ISCraftingUI"
require "ActionManager"
require "Entity/ISEntityUI"
require "Entity/TimedActions/ISHandcraftAction"
require "TimedActions/ISInventoryTransferUtil"
require "ChilaSeda_AccessibleActions_OptionalMods"

-- This compatibility layer only applies to the optional Dismantle All at Once mod.
if not ChilaSedaAccessibleActions
		or not ChilaSedaAccessibleActions.isModActive("DismantleAllAtOnce") then
	return
end

local GENERIC_OPTION = "ContextMenu_DismantleAllAtOnce"
local SURFACE_SUFFIX = "ContextMenu_DismantleAllAtOnce_RequiresSurface"

-- Dismantle All at Once queues every recipe input into the main inventory,
-- then vanilla places generated products there. Preserve the original
-- container of the selected stack and return those outputs after the final
-- queued craft action completes. The Workshop source already queues reusable
-- recipe inputs back to their source; this wrapper also honors that behavior
-- for characters with the Disorganized trait.
local activeDismantleContext
local producingAction

local function returnProducedItems(context)
    if not context or context.outputsReturned then return end
    context.outputsReturned = true
    for _, item in ipairs(context.outputs) do
        local destination = context.outputContainer
        local source = item and item:getContainer()
        if item and source and destination and source ~= destination then
            local action = ISInventoryTransferUtil.newInventoryTransferAction(
                context.player, item, source, destination, nil)
            if action and action.setAllowMissingItems then
                action:setAllowMissingItems(true)
            end
            if action then ISTimedActionQueue.add(action) end
        end
    end
end

local originalAddOrDropItem = Actions and Actions.addOrDropItem
if type(originalAddOrDropItem) == "function" then
    Actions.addOrDropItem = function(character, item)
        local context = producingAction and producingAction.chilaSedaDismantleContext
        if context and character == context.player and item then
            context.outputs[#context.outputs + 1] = item
        end
        return originalAddOrDropItem(character, item)
    end
end

local originalPerformRecipe = ISHandcraftAction.performRecipe
ISHandcraftAction.performRecipe = function(self, ...)
    if not self.chilaSedaDismantleContext then
        return originalPerformRecipe(self, ...)
    end
    local previousAction = producingAction
    producingAction = self
    local ok, result = pcall(originalPerformRecipe, self, ...)
    producingAction = previousAction
    if not ok then error(result) end
    return result
end

local originalHandcraftStartMultiple = ISEntityUI.HandcraftStartMultiple
ISEntityUI.HandcraftStartMultiple = function(player, logic, force, quantity, addToQueue)
    local actions = originalHandcraftStartMultiple(player, logic, force, quantity, addToQueue)
    local context = activeDismantleContext
    if context and context.player == player and type(actions) == "table" then
        for _, action in ipairs(actions) do
            action.chilaSedaDismantleContext = context
        end
    end
    return actions
end

local originalSetOnComplete = ISHandcraftAction.setOnComplete
ISHandcraftAction.setOnComplete = function(self, callback, target)
    local context = self.chilaSedaDismantleContext
    if not context or not callback or self.chilaSedaReturnCallbackWrapped then
        return originalSetOnComplete(self, callback, target)
    end
    self.chilaSedaReturnCallbackWrapped = true
    return originalSetOnComplete(self, function(callbackTarget)
        callback(callbackTarget)
        returnProducedItems(context)
    end, target)
end

local originalReturnItemToContainer = ISCraftingUI.ReturnItemToContainer
ISCraftingUI.ReturnItemToContainer = function(player, item, container)
    local context = activeDismantleContext
    if not context or context.player ~= player or not item or not container then
        return originalReturnItemToContainer(player, item, container)
    end
    local inventory = player:getInventory()
    if container == inventory then return end
    local action = ISInventoryTransferUtil.newInventoryTransferAction(
        player, item, inventory, container, nil)
    if action and action.setAllowMissingItems then
        action:setAllowMissingItems(true)
    end
    if action then ISTimedActionQueue.add(action) end
end

local function invokeDismantleAll(option, target, groupItems, recipe, ...)
    local previousContext = activeDismantleContext
    local shared = ChilaSedaAccessibleActions
    local previousRecipeItems = shared and shared.contextRecipeItems
    local firstItem = type(groupItems) == "table" and groupItems[1] or nil
    activeDismantleContext = {
        player = target,
        outputContainer = firstItem and firstItem:getContainer() or nil,
        outputs = {},
        outputsReturned = false,
    }
    if shared then shared.contextRecipeItems = groupItems end
    local ok, a, b, c, d = pcall(option.chilaSedaOriginalOnSelect,
        target, groupItems, recipe, ...)
    activeDismantleContext = previousContext
    if shared then shared.contextRecipeItems = previousRecipeItems end
    if not ok then error(a) end
    return a, b, c, d
end

local function moveAfterHandEquip(context, option)
    local options = context.options
    if type(options) ~= "table" then return end
    local equipLabels = {
        [getText("ContextMenu_Equip_Primary")] = true,
        [getText("ContextMenu_Equip_Secondary")] = true,
        [getText("ContextMenu_Equip_Two_Hands")] = true,
    }
    local optionIndex, lastEquipIndex
    for index, entry in ipairs(options) do
        if entry == option then optionIndex = index end
        if entry ~= option and equipLabels[entry.name] then lastEquipIndex = index end
    end
    if optionIndex then
        table.remove(options, optionIndex)
        if lastEquipIndex and optionIndex <= lastEquipIndex then lastEquipIndex = lastEquipIndex - 1 end
    end
    lastEquipIndex = lastEquipIndex or math.min(1, #options)
    table.insert(options, (lastEquipIndex > 0 and lastEquipIndex + 1 or 1), option)
    for index, entry in ipairs(options) do entry.id = index end
    pcall(function()
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
    end)
end

local function selectedItemIds(entries)
    local ids = {}
    for _, entry in ipairs(entries or {}) do
        local candidates = type(entry) == "table" and entry.items or nil
        if candidates then
            for _, item in ipairs(candidates) do
                if item and type(item.getID) == "function" then ids[item:getID()] = true end
            end
        elseif entry and type(entry.getID) == "function" then
            ids[entry:getID()] = true
        end
    end
    return ids
end

local function isDismantleAllOption(option, selected)
    if option.name == getText(GENERIC_OPTION) and option.subOption then return true end

    local recipeItems = option.param1
    local recipe = option.param2
    if type(recipeItems) ~= "table" or #recipeItems == 0
        or not recipe or type(recipe.getTranslationName) ~= "function" then
        return false
    end

    for _, item in ipairs(recipeItems) do
        if not item or type(item.getID) ~= "function" or not selected[item:getID()] then
            return false
        end
    end

    local expected = getText(recipe:getTranslationName()) .. " (" .. #recipeItems .. ")"
    if type(recipe.isAnySurfaceCraft) == "function" and recipe:isAnySurfaceCraft() then
        expected = expected .. getText(SURFACE_SUFFIX)
    end
    return option.name == expected
end

local function moveDismantleAllAfterHandEquip(_, context, entries)
    if not context or type(context.options) ~= "table" then return end
    local selected = selectedItemIds(entries)
    for index, option in ipairs(context.options) do
        if isDismantleAllOption(option, selected) then
            if option.onSelect and not option.chilaSedaOriginalOnSelect then
                option.chilaSedaOriginalOnSelect = option.onSelect
                option.onSelect = function(target, groupItems, recipe, ...)
                    return invokeDismantleAll(option, target, groupItems, recipe, ...)
                end
            end
            moveAfterHandEquip(context, option)
            return
        end
    end
end

local function stopInventoryAnimation(character)
	if not character then return end
	local emitter = type(character.getEmitter) == "function" and character:getEmitter()
	if emitter and type(character.stopAnimation) == "function" then
		character:stopAnimation()
	end
	local soundManager = type(getSoundManager) == "function" and getSoundManager()
	if soundManager and type(soundManager.stopCategoryLoop) == "function"
			and SoundCategory and SoundCategory.Inventory then
		soundManager:stopCategoryLoop(SoundCategory.Inventory)
	end
end

local originalISTimedActionQueueAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action)
	if action and action.complete and not action.soundLoopPatched then
		local originalActionComplete = action.complete
		action.complete = function(self)
			local result = originalActionComplete(self)
			local character = self.character
			if character and type(character.isSitting) == "function" and character:isSitting() then
				if type(self.getEmitter) == "function" and self:getEmitter()
						and type(self.stopSound) == "function" then
					self:stopSound()
				end
				stopInventoryAnimation(character)
			end
			return result
		end
		action.soundLoopPatched = true
	end
	return originalISTimedActionQueueAdd(action)
end

Events.OnFillInventoryObjectContextMenu.Add(moveDismantleAllAfterHandEquip)
