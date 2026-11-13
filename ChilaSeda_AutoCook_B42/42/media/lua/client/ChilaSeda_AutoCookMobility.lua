local autoCookLoaded = pcall(require, "AutoCook")
if not autoCookLoaded or type(AutoCook) ~= "table"
        or type(AutoCook.continue) ~= "function"
        or type(AutoCook.stopAutoCook) ~= "function" then
    print("[ChilaSeda_AutoCookMobility] AutoCook is unavailable or has an incompatible API; patch skipped.")
    return
end
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"

if AutoCook.ChilaSedaMobilityInstalled then
    return
end

local TAG = "[ChilaSeda_AutoCookMobility] "
local originalContinue = AutoCook.continue
local originalStopAutoCook = AutoCook.stopAutoCook
local originalQueueAddItem = AutoCook.queueAddItem
local originalQueueAdd = ISTimedActionQueue.add
local originalQueueReset = ISTimedActionQueue.resetQueue
local originalTransferPerform = ISInventoryTransferAction.perform

local function sameItemId(item, id)
    if not item or id == nil then return false end
    local ok, itemId = pcall(item.getID, item)
    return ok and itemId == id
end

local function notifyBaseItemDestination(action, destination)
    local player = action.character
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, getText("UI_ChilaSeda_AutoCook_ReturnedTo", destination))
    end
end

ISInventoryTransferAction.perform = function(action, ...)
    local results = { originalTransferPerform(action, ...) }
    local returnInfo = action and action.ChilaSedaAutoCookBaseReturn
    if returnInfo then
        local item = action.item
        local ok, container = pcall(item.getContainer, item)
        if not ok or container ~= returnInfo.source then
            local okType, containerType = pcall(function() return container and container:getType() end)
            if okType and containerType == "floor" then
                notifyBaseItemDestination(action, getText("UI_ChilaSeda_AutoCook_Floor"))
                return unpack(results)
            end
            local inventory = action.character and action.character:getInventory()
            local square = action.character and action.character:getCurrentSquare()
            if item and inventory and inventory:contains(item) and square then
                inventory:Remove(item)
                square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
                notifyBaseItemDestination(action, getText("UI_ChilaSeda_AutoCook_Floor"))
            else
                notifyBaseItemDestination(action, getText("UI_ChilaSeda_AutoCook_Inventory"))
            end
        else
            notifyBaseItemDestination(action, returnInfo.label)
        end
    end
    return unpack(results)
end

AutoCook.queueAddItem = function(self, usedItem, ...)
    if self.baseItem and self.playerObj then
        local inventory = self.playerObj:getInventory()
        if not inventory:contains(self.baseItem) and not self.ChilaSedaBaseReturn then
            local source = self.baseItem:getContainer()
            if source and source ~= inventory then
                local okName, label = pcall(source.getName, source)
                self.ChilaSedaBaseReturn = {
                    source = source,
                    itemId = self.baseItem:getID(),
                    label = okName and label or getText("UI_ChilaSeda_AutoCook_Container"),
                }
                self:addToReturnContainer(self.baseItem)
            end
        end
    end
    return originalQueueAddItem(self, usedItem, ...)
end

local function decrementUsedItem(job, itemType)
    if not job or not job.usedItems or not itemType then
        return
    end
    for i = #job.usedItems, 1, -1 do
        local used = job.usedItems[i]
        if used.itemType == itemType then
            used.number = used.number - 1
            if used.number <= 0 then
                table.remove(job.usedItems, i)
            end
            return
        end
    end
end

local function escapeIsDown()
    if not Keyboard or not Keyboard.isKeyDown then return false end
    local ok, result = pcall(Keyboard.isKeyDown, Keyboard.KEY_ESCAPE)
    return ok and result == true
end

local function cancelAutoCook(job, queue)
    if not job or job.ChilaSedaWasCancelled then return nil end

    job.ChilaSedaExplicitStop = true
    job.ChilaSedaPendingResume = nil
    job.ChilaSedaManualResumeRequested = nil
    job.ChilaSedaEscapeRequested = nil

    local interruptedAdd = job.addAction
    if interruptedAdd and not interruptedAdd.ChilaSedaCookApplied
            and interruptedAdd.usedItem then
        decrementUsedItem(job, interruptedAdd.usedItem:getFullType())
    end

    AutoCook.ChilaSedaCancelledJob = job
    job.ChilaSedaWasCancelled = true

    local queueBelongsToJob = queue and queue.character == job.playerObj
    local hasQueuedAction = queueBelongsToJob and queue.queue and #queue.queue > 0
    if queueBelongsToJob then
        -- resetQueue does not stop an already-started Java action. Stop the
        -- player's animation even if an AutoCook action lost its Lua marker or
        -- the queue list is already empty while the action is still settling.
        local character = queue.character
        if character and character.StopAllActionQueue then
            character:StopAllActionQueue()
        end
        if hasQueuedAction then
            originalQueueReset(queue)
        end
    end

    AutoCook.ChilaSedaQueueJob = nil
    if AutoCook.ChilaSedaActiveJob == job then
        AutoCook.ChilaSedaActiveJob = nil
    end
    job:stopAutoCook()
    job.ChilaSedaExplicitStop = nil
    print(TAG .. "AutoCook cancelled by Escape; right-click the cooking item to resume")
end

local function sameInventoryItem(first, second)
    if first == second then return true end
    if not first or not second then return false end

    if (type(first) ~= "table" and type(first) ~= "userdata")
            or (type(second) ~= "table" and type(second) ~= "userdata") then
        return false
    end
    if not first.getID or not second.getID then return false end

    local okFirst, firstId = pcall(function() return first:getID() end)
    local okSecond, secondId = pcall(function() return second:getID() end)
    if not okFirst or not okSecond or firstId == nil or firstId ~= secondId then
        return false
    end
    local okFirstType, firstType = pcall(function() return first:getFullType() end)
    local okSecondType, secondType = pcall(function() return second:getFullType() end)
    return not okFirstType or not okSecondType or firstType == secondType
end

local function selectionContainsItem(entries, target)
    if type(entries) ~= "table" then return false end
    for _, entry in ipairs(entries) do
        if sameInventoryItem(entry, target) then return true end
        if type(entry) == "table" and type(entry.items) == "table" then
            for _, item in ipairs(entry.items) do
                if sameInventoryItem(item, target) then return true end
            end
        end
    end
    return false
end

local function returnCancelledIngredientsImmediately(job)
    local player = job and job.playerObj
    local inventory = player and player:getInventory()
    if not player or not inventory then return end
    local returned = 0
    local retained = 0
    for _, entry in ipairs(job and job.returnToContainer or {}) do
        local item = entry and entry.usedItem
        local source = entry and entry.sourceContainer
        if item and source and source ~= inventory and inventory:contains(item) then
            local transfer = ISInventoryTransferAction:new(player, item, inventory, source, nil)
            local okValid, valid = pcall(transfer.isValid, transfer)
            local okTransfer = false
            if okValid and valid then
                okTransfer = pcall(transfer.transferItem, transfer, item)
            end
            local okContainer, currentContainer = pcall(item.getContainer, item)
            if okTransfer and okContainer and currentContainer == source then
                returned = returned + 1
            else
                retained = retained + 1
            end
        end
    end
    if job then job.returnToContainer = {} end
    print(TAG .. "cancel cleanup returned=" .. tostring(returned)
        .. " retainedInInventory=" .. tostring(retained))
end

local function resumeCancelledAutoCook(job, selectedBaseItem)
    if not job or AutoCook.ChilaSedaCancelledJob ~= job
            or not sameInventoryItem(job.baseItem, selectedBaseItem) then
        return
    end

    local player = job.playerObj
    if not player or player:isDead() then return end

    AutoCook.ChilaSedaCancelledJob = nil
    job.ChilaSedaWasCancelled = nil
    job.ChilaSedaPendingResume = true
    job.ChilaSedaManualResumeRequested = true
    AutoCook.ChilaSedaActiveJob = job
    print(TAG .. "manual AutoCook resume requested")
end

local function addResumeOption(playerIndex, context, entries)
    local job = AutoCook.ChilaSedaCancelledJob
    if not job or AutoCook.ChilaSedaActiveJob or not context
            or not context.addOption then
        return
    end

    local player = getSpecificPlayer(playerIndex)
    if not player or player ~= job.playerObj or player:isDead()
            or not selectionContainsItem(entries, job.baseItem) then
        return
    end

    local option = context:addOption("Reanudar AutoCook", job, resumeCancelledAutoCook, job.baseItem)
    if not option then return end
    option.chilaSedaResumeAutoCook = true
    local okManager, manager = pcall(getScriptManager)
    if okManager and manager then
        local okItem, scriptItem = pcall(manager.FindItem, manager, "Base.Pot")
        if okItem and scriptItem then
            local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
            if okTexture and texture then option.iconTexture = texture end
        end
    end

end

AutoCook.continue = function(self, ...)
    if AutoCook.ChilaSedaCancelledJob
            and AutoCook.ChilaSedaCancelledJob ~= self then
        AutoCook.ChilaSedaCancelledJob = nil
    end
    local previousJob = AutoCook.ChilaSedaQueueJob
    AutoCook.ChilaSedaQueueJob = self
    local results = { originalContinue(self, ...) }
    AutoCook.ChilaSedaQueueJob = previousJob
    return unpack(results)
end

AutoCook.stopAutoCook = function(self, ...)
    self.ChilaSedaPendingResume = nil
    self.ChilaSedaManualResumeRequested = nil
    if self.ChilaSedaExplicitStop then
        AutoCook.ChilaSedaCancelledJob = self
        self.ChilaSedaWasCancelled = true
    end
    if AutoCook.ChilaSedaQueueJob == self then
        AutoCook.ChilaSedaQueueJob = nil
    end
    if AutoCook.ChilaSedaActiveJob == self then
        AutoCook.ChilaSedaActiveJob = nil
    end
    if self.ChilaSedaExplicitStop and not isClient() then
        returnCancelledIngredientsImmediately(self)
        return
    end
    AutoCook.ChilaSedaStoppingJob = self
    local results = { originalStopAutoCook(self, ...) }
    AutoCook.ChilaSedaStoppingJob = nil
    return unpack(results)
end

ISTimedActionQueue.add = function(action, ...)
    local job = AutoCook.ChilaSedaQueueJob
    local stoppingJob = AutoCook.ChilaSedaStoppingJob
    local returnInfo = stoppingJob and stoppingJob.ChilaSedaBaseReturn
    if action and returnInfo and sameItemId(action.item, returnInfo.itemId) then
        action.ChilaSedaAutoCookBaseReturn = returnInfo
    end
    if job and action and action.character == job.playerObj then
        action.ChilaSedaAutoCookJob = job
        action.stopOnWalk = false
        action.stopOnRun = false
        action.stopOnAim = false
        AutoCook.ChilaSedaActiveJob = job
    end
    return originalQueueAdd(action, ...)
end

ISTimedActionQueue.resetQueue = function(queue, ...)
    local current = queue and queue.queue and queue.queue[1]
    local job = current and current.ChilaSedaAutoCookJob
    local activeJob = AutoCook.ChilaSedaActiveJob
    if not job and activeJob and queue
            and queue.character == activeJob.playerObj then
        job = activeJob
    end

    if job and AutoCook.ChilaSedaActiveJob == job
            and not job.ChilaSedaWasCancelled
            and (job.ChilaSedaEscapeRequested or escapeIsDown()) then
        cancelAutoCook(job, queue)
        return
    end

    if job and AutoCook.ChilaSedaActiveJob == job
            and not job.ChilaSedaPendingResume
            and not job.ChilaSedaExplicitStop then
        local interruptedAdd = job.addAction
        local interruptedBeforeAdd = interruptedAdd
            and not interruptedAdd.ChilaSedaCookApplied
        if interruptedBeforeAdd and interruptedAdd.usedItem then
            decrementUsedItem(job, interruptedAdd.usedItem:getFullType())
        end
        job.ChilaSedaPendingResume = true
    end

    local results = { originalQueueReset(queue, ...) }
    if job and AutoCook.ChilaSedaActiveJob == job
            and job.ChilaSedaPendingResume then
        print(TAG .. "AutoCook paused for another action; it will resume automatically")
    end
    return unpack(results)
end

local function resumeAfterOtherAction()
    local job = AutoCook.ChilaSedaActiveJob
    if not job then return end
    if job.ChilaSedaEscapeRequested then
        local queue = ISTimedActionQueue.getTimedActionQueue(job.playerObj)
        cancelAutoCook(job, queue)
        return
    end
    if not job.ChilaSedaPendingResume then return end

    local player = job.playerObj
    if not player or player:isDead() then
        job:stopAutoCook()
        return
    end
    if player.isAttacking and player:isAttacking() then return end

    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    if queue and queue.queue and #queue.queue > 0 then return end

    job.ChilaSedaPendingResume = nil
    job.ChilaSedaManualResumeRequested = nil
    print(TAG .. "resuming the original recipe after the other action")
    job:continue()
end

local function cancelAutoCookOnEscape(key)
    if key ~= Keyboard.KEY_ESCAPE then return end

    local job = AutoCook.ChilaSedaActiveJob
    if not job then return end
    job.ChilaSedaEscapeRequested = true
    job.ChilaSedaPendingResume = nil
    job.ChilaSedaManualResumeRequested = nil
    local queue = ISTimedActionQueue.getTimedActionQueue(job.playerObj)
    cancelAutoCook(job, queue)
end

require "TimedActions/ISAddItemInRecipe"
local originalComplete = ISAddItemInRecipe.complete

local function isExhaustedFood(item)
    if not item or not instanceof(item, "Food") then return false end

    local ok, hunger, calories, carbs, lipids, proteins = pcall(function()
        return item:getHungChange(), item:getCalories(), item:getCarbohydrates(),
            item:getLipids(), item:getProteins()
    end)
    return ok and hunger >= 0 and calories <= 0 and carbs <= 0
        and lipids <= 0 and proteins <= 0
end

local function removeExhaustedAutoCookIngredient(action)
    if not action.ChilaSedaAutoCookJob or not isExhaustedFood(action.usedItem) then
        return false
    end

    local item = action.usedItem
    local container = item:getContainer()
    if not container then return false end

    -- EvolvedRecipe can leave a depleted packaged spice as a +1 hunger,
    -- zero-nutrition Food object. AutoCook should not return that waste to
    -- its source container or leave it in the player's inventory.
    sendRemoveItemFromContainer(container, item)
    container:Remove(item)
    if action.character then
        action.character:removeFromHands(item)
    end
    return true
end

ISAddItemInRecipe.complete = function(self, ...)
    local result = originalComplete(self, ...)
    local ok, removed = pcall(removeExhaustedAutoCookIngredient, self)
    if ok and removed then
        print(TAG .. "removed exhausted AutoCook ingredient "
            .. tostring(self.usedItem and self.usedItem:getFullType() or "unknown"))
    end
    self.ChilaSedaCookApplied = true
    return result
end

AutoCook.ChilaSedaMobilityInstalled = true
Events.OnTick.Add(resumeAfterOtherAction)
Events.OnKeyStartPressed.Add(cancelAutoCookOnEscape)
Events.OnFillInventoryObjectContextMenu.Add(addResumeOption)
print(TAG .. "installed; AutoCook resumes after other actions; Escape cancels and the cooking item offers manual resume")

