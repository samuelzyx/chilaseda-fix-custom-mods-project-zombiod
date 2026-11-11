require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISUnequipAction"
require "TimedActions/ISEquipWeaponAction"
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISCraftAction"
require "TimedActions/Animals/ISDropAnimalCorpseAndThen"
require "TimedActions/Animals/ISButcherAnimal"
require "ISUI/Animal/ISAnimalContextMenu"

local pending = {}

local function itemPresent(item)
    local container = item and item:getContainer()
    return container ~= nil and container:contains(item)
end

local function appendAfter(previous, action)
    if not action then return previous end
    local queue, inserted = ISTimedActionQueue.addAfter(previous, action)
    if queue and inserted then return inserted end
    return previous
end

local function addTransferAfter(previous, character, item, destination)
    local source = item and item:getContainer()
    if not source or not destination or source == destination or not source:contains(item) then
        return previous
    end
    return appendAfter(previous,
        ISInventoryTransferUtil.newInventoryTransferAction(character, item, source, destination, nil))
end

ISChilaSedaRestoreAutoToolsAction = ISBaseTimedAction:derive("ISChilaSedaRestoreAutoToolsAction")

function ISChilaSedaRestoreAutoToolsAction:isValid()
    return self.character ~= nil
end

function ISChilaSedaRestoreAutoToolsAction:start()
    self:setActionAnim("Loot")
end

function ISChilaSedaRestoreAutoToolsAction:update() end

function ISChilaSedaRestoreAutoToolsAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISChilaSedaRestoreAutoToolsAction:perform()
    local character = self.character
    local inventory = character:getInventory()
    local previous = self
    local tools = self.snapshot.tools

    -- First free any hand occupied by an automatically equipped tool, then put it
    -- back into the container from which the action borrowed it.
    for _, record in ipairs(tools) do
        local tool = record.item
        if itemPresent(tool) then
            if character:getPrimaryHandItem() == tool or character:getSecondaryHandItem() == tool then
                previous = appendAfter(previous, ISUnequipAction:new(character, tool, 50))
            end
            previous = addTransferAfter(previous, character, tool, record.container)
        end
    end

    local function restoreHand(slot)
        local record = self.snapshot.hands[slot]
        if not record or not record.item then return end
        local current
        if slot == "primary" then
            current = character:getPrimaryHandItem()
        else
            current = character:getSecondaryHandItem()
        end
        if current ~= nil and current ~= record.tool then return end
        local item = record.item
        if not itemPresent(item) then return end
        previous = addTransferAfter(previous, character, item, inventory)
        local twoHands = self.snapshot.hands.primary
            and self.snapshot.hands.secondary
            and self.snapshot.hands.primary.item == self.snapshot.hands.secondary.item
        previous = appendAfter(previous,
            ISEquipWeaponAction:new(character, item, 50, slot == "primary", twoHands == true))
    end

    restoreHand("primary")
    restoreHand("secondary")
    ISBaseTimedAction.perform(self)
end

function ISChilaSedaRestoreAutoToolsAction:new(character, snapshot)
    local o = ISBaseTimedAction.new(self, character)
    o.snapshot = snapshot
    o.stopOnWalk, o.stopOnRun = false, false
    o.maxTime = 1
    return o
end

local function resolveTool(character, handItem, item)
    if instanceof(item, "InventoryItem") then return item end
    if type(item) == "function" then
        if handItem and item(handItem) then return handItem end
        return character:getInventory():getFirstEvalRecurse(item)
    end
    if type(item) == "string" then
        if handItem and handItem:getType() == item and not handItem:isBroken() then return handItem end
        return character:getInventory():getFirstTypeEvalRecurse(item,
            function(candidate) return not candidate:isBroken() end)
    end
    return nil
end

local function toolRestoreSnapshot(character, tool, primaryBefore, secondaryBefore)
    return {
        character = character,
        expected = 0,
        seen = 0,
        tools = { { item = tool, container = tool and tool:getContainer() } },
        toolIds = {},
        hands = {
            primary = primaryBefore ~= tool and { item = primaryBefore, tool = tool } or nil,
            secondary = secondaryBefore == tool and { item = secondaryBefore, tool = tool } or nil,
        },
    }
end

local function queueButcherWithTool(character, body, tool)
    if not tool then return end
    local primaryBefore = character:getPrimaryHandItem()
    local secondaryBefore = character:getSecondaryHandItem()
    local inventory = character:getInventory()
    local toolContainer = tool and tool:getContainer()
    if toolContainer and toolContainer ~= inventory then
        local transfer = ISInventoryTransferUtil.newInventoryTransferAction(
            character, tool, toolContainer, inventory, nil)
        ISTimedActionQueue.add(transfer)
    end
    if tool and primaryBefore ~= tool then
        ISTimedActionQueue.add(ISEquipWeaponAction:new(character, tool, 50, true, false))
    end
    local action = ISButcherAnimal:new(character, body)
    action.chilaSedaToolRestore = toolRestoreSnapshot(character, tool, primaryBefore, secondaryBefore)
    ISTimedActionQueue.add(action)
end

-- Both animal menu routes explicitly queue the knife with the butcher action.
AnimalContextMenu.onButcherAnimal = function(body, character, knife)
    if luautils.walkAdj(character, body:getSquare()) then
        queueButcherWithTool(character, body, knife)
    end
end

AnimalContextMenu.onButcherAnimalFromInv = function(body, character, knife)
    if not body or not character then return end
    local action = ISDropAnimalCorpseAndThen:new(character, body, "butcher")
    action.butcheringKnife = knife
    ISTimedActionQueue.add(action)
end

local originalDropComplete = ISDropAnimalCorpseAndThen.complete
ISDropAnimalCorpseAndThen.complete = function(self, ...)
    local queue = ISTimedActionQueue.getTimedActionQueue(self.character).queue
    local beforeActions = {}
    for _, action in ipairs(queue) do beforeActions[action] = true end
    local result = originalDropComplete(self, ...)
    if self.andThen == "butcher" and self.butcheringKnife and not isClient() and not isServer() then
        queue = ISTimedActionQueue.getTimedActionQueue(self.character).queue
        local butcherIndex, butcherAction
        for i = 1, #queue do
            local action = queue[i]
            if action and not beforeActions[action] and instanceof(action, "ISButcherAnimal") then
                butcherIndex, butcherAction = i, action
                break
            end
        end
        if butcherIndex and butcherAction then
            local previous = queue[butcherIndex - 1] or self
            local tool = self.butcheringKnife
            local inventory = self.character:getInventory()
            local toolContainer = tool:getContainer()
            local primaryBefore = self.character:getPrimaryHandItem()
            local secondaryBefore = self.character:getSecondaryHandItem()
            if toolContainer and toolContainer ~= inventory then
                local transfer = ISInventoryTransferUtil.newInventoryTransferAction(
                    self.character, tool, toolContainer, inventory, nil)
                local _, inserted = ISTimedActionQueue.addAfter(previous, transfer)
                if inserted then previous = inserted end
            end
            if primaryBefore ~= tool then
                local equip = ISEquipWeaponAction:new(self.character, tool, 50, true, false)
                local _, inserted = ISTimedActionQueue.addAfter(previous, equip)
                if inserted then previous = inserted end
            end
            butcherAction.chilaSedaToolRestore = toolRestoreSnapshot(
                self.character, tool, primaryBefore, secondaryBefore)
        end
    end
    return result
end

local originalButcherComplete = ISButcherAnimal.complete
ISButcherAnimal.complete = function(self, ...)
    local result = originalButcherComplete(self, ...)
    if self.chilaSedaToolRestore then
        local restore = ISChilaSedaRestoreAutoToolsAction:new(
            self.character, self.chilaSedaToolRestore)
        ISTimedActionQueue.add(restore)
        self.chilaSedaToolRestore = nil
    end
    return result
end

local originalEquip = ISWorldObjectContextMenu.equip
ISWorldObjectContextMenu.equip = function(character, handItem, item, primary, twoHands)
    local tool = resolveTool(character, handItem, item)
    local primaryBefore = character:getPrimaryHandItem()
    local secondaryBefore = character:getSecondaryHandItem()
    local targetBefore = primary and primaryBefore or secondaryBefore
    local needsEquip = tool ~= nil and targetBefore ~= tool
    local snapshot

    if needsEquip then
        snapshot = pending[character]
        if not snapshot then
            snapshot = { character = character, expected = 0, seen = 0, tools = {}, toolIds = {}, hands = {} }
            pending[character] = snapshot
        end
        snapshot.expected = snapshot.expected + 1
        if primary then
            snapshot.hands.primary = { item = primaryBefore, tool = tool }
            if twoHands then snapshot.hands.secondary = { item = secondaryBefore, tool = tool } end
        else
            snapshot.hands.secondary = { item = secondaryBefore, tool = tool }
        end
        local id = tool:getID()
        if not snapshot.toolIds[id] then
            snapshot.toolIds[id] = true
            snapshot.tools[#snapshot.tools + 1] = { item = tool, container = tool:getContainer() }
        end
    end

    local result = originalEquip(character, handItem, item, primary, twoHands)
    if snapshot and result then
        local function expire()
            Events.OnTick.Remove(expire)
            if pending[character] == snapshot then pending[character] = nil end
        end
        Events.OnTick.Add(expire)
    end
    return result
end

local originalQueueAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action)
    local character = action and action.character
    local snapshot = character and pending[character]
    local isEquip = action and instanceof(action, "ISEquipWeaponAction")
    local isTransfer = action and instanceof(action, "ISInventoryTransferAction")

    if snapshot and isEquip then snapshot.seen = snapshot.seen + 1 end
    local result = originalQueueAdd(action)

    if snapshot and snapshot.seen >= snapshot.expected and not isEquip and not isTransfer
        and not instanceof(action, "ISUnequipAction") then
        if instanceof(action, "ISCraftAction") then
            -- Keep the borrowed tool and hand snapshot attached to the craft. Its
            -- completion may queue more same-recipe actions before restoration.
            action.chilaSedaToolRestore = snapshot
            pending[character] = nil
        else
            local restore = ISChilaSedaRestoreAutoToolsAction:new(character, snapshot)
            local queue, inserted = ISTimedActionQueue.addAfter(action, restore)
            if queue and inserted and pending[character] == snapshot then
                pending[character] = nil
            end
        end
    end
    return result
end

local originalCraftPerform = ISCraftAction.perform
ISCraftAction.perform = function(action, ...)
    local snapshot = action.chilaSedaToolRestore
    action.chilaSedaToolRestore = nil

    local result = originalCraftPerform(action, ...)
    if not snapshot then return result end

    local queue = ISTimedActionQueue.getTimedActionQueue(action.character).queue
    for _, queuedAction in ipairs(queue) do
        if queuedAction ~= action
                and queuedAction.character == action.character
                and instanceof(queuedAction, "ISCraftAction")
                and queuedAction.recipe == action.recipe then
            -- Dismantle-all queues the next item from OnComplete. Keep the tool
            -- equipped through the batch and restore it only after its last item.
            queuedAction.chilaSedaToolRestore = snapshot
            return result
        end
    end

    -- Let any already queued return-to-container transfers finish before putting
    -- the borrowed tool back and restoring the original hand items.
    ISTimedActionQueue.add(ISChilaSedaRestoreAutoToolsAction:new(action.character, snapshot))
    return result
end

-- MovableRecipe dismantling equips its tools inside OnCraft, then queues the
-- craft action and the vanilla return-to-container transfers. Capture this
-- route explicitly so restoration does not depend on another mod or menu hook
-- preserving the temporary ISWorldObjectContextMenu.equip snapshot.
local originalInventoryOnCraft = ISInventoryPaneContextMenu.OnCraft
ISInventoryPaneContextMenu.OnCraft = function(selectedItem, recipe, player, all)
    if not recipe or not instanceof(recipe, "MovableRecipe") then
        return originalInventoryOnCraft(selectedItem, recipe, player, all)
    end

    local character = getSpecificPlayer(player)
    if not character then
        return originalInventoryOnCraft(selectedItem, recipe, player, all)
    end

    local containers = ISInventoryPaneContextMenu.getContainers(character)
    local primaryBefore = character:getPrimaryHandItem()
    local secondaryBefore = character:getSecondaryHandItem()
    local primaryTool = RecipeManager.GetMovableRecipeTool(true, recipe, selectedItem, character, containers)
    local secondaryTool = RecipeManager.GetMovableRecipeTool(false, recipe, selectedItem, character, containers)

    local snapshot
    if (primaryTool and primaryTool ~= primaryBefore)
            or (secondaryTool and secondaryTool ~= secondaryBefore) then
        snapshot = {
            character = character,
            expected = 0,
            seen = 0,
            tools = {},
            toolIds = {},
            hands = {},
        }

        local function rememberTool(tool)
            if not tool then return end
            local id = tool:getID()
            if not snapshot.toolIds[id] then
                snapshot.toolIds[id] = true
                snapshot.tools[#snapshot.tools + 1] = {
                    item = tool,
                    container = tool:getContainer(),
                }
            end
        end

        if primaryTool and primaryTool ~= primaryBefore then
            snapshot.hands.primary = { item = primaryBefore, tool = primaryTool }
            rememberTool(primaryTool)
        end
        if secondaryTool and secondaryTool ~= secondaryBefore then
            snapshot.hands.secondary = { item = secondaryBefore, tool = secondaryTool }
            rememberTool(secondaryTool)
        end
    end

    local queue = ISTimedActionQueue.getTimedActionQueue(character).queue
    local beforeActions = {}
    for _, action in ipairs(queue) do beforeActions[action] = true end

    local result = originalInventoryOnCraft(selectedItem, recipe, player, all)

    if snapshot then
        queue = ISTimedActionQueue.getTimedActionQueue(character).queue
        for _, action in ipairs(queue) do
            if action and not beforeActions[action]
                    and instanceof(action, "ISCraftAction")
                    and action.recipe == recipe then
                action.chilaSedaToolRestore = snapshot
                pending[character] = nil
                break
            end
        end
    end

    return result
end
