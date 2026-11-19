require "TimedActions/ISGrabItemAction"
require "TimedActions/Fishing/TimedActions/ISPickupFishAction"

local TAG = "[ChilaSeda_ViewpointPickupDestination] "

local function selectedDestination(player)
    if not player or type(getPlayerInventory) ~= "function" then return nil end
    local page = getPlayerInventory(player:getPlayerNum())
    local pane = page and page.inventoryPane
    local main = player:getInventory()
    local selected = pane and pane.inventory
    if selected and selected ~= main and type(selected.getType) == "function"
            and selected:getType() ~= "floor" then
        return selected
    end
    return nil
end

local function canStore(container, player, item)
    if not container or not player or not item then return false end
    local ok, fits = pcall(function()
        return container:isItemAllowed(item) and container:hasRoomFor(player, item)
            and container:getCapacityWeight() + item:getUnequippedWeight()
                <= container:getEffectiveCapacity(player)
    end)
    return ok and fits == true
end

local function destinationFor(player, item)
    local main = player and player:getInventory()
    local selected = selectedDestination(player)
    if selected and canStore(selected, player, item) then return selected end
    return main
end

local originalGrabNew = ISGrabItemAction.new
ISGrabItemAction.new = function(self, character, worldItem, time, ...)
    local action = originalGrabNew(self, character, worldItem, time, ...)
    if not action then return action end

    local targetAction = action
    if action.ignoreAction then
        local queue = ISTimedActionQueue
            and type(ISTimedActionQueue.getTimedActionQueue) == "function"
            and ISTimedActionQueue.getTimedActionQueue(character) or nil
        local lastAction = queue and queue.queue and queue.queue[#queue.queue]
        if lastAction and lastAction.Type == "ISGrabItemAction" then
            targetAction = lastAction
        end
    end

    if targetAction and not targetAction.started then
        local queuedItem = action.item and action.item:getItem()
        if queuedItem then
            targetAction.destContainer = destinationFor(character, queuedItem)
        end
    end
    return action
end

local originalGrabIsValid = ISGrabItemAction.isValid
ISGrabItemAction.isValid = function(action, ...)
    -- Single-player checks each item immediately before transferring it, so a
    -- full selected bag can fall back to the root inventory without cancelling.
    if not isClient() and not isServer() and action.item and action.item:getItem() then
        action.destContainer = destinationFor(action.character, action.item:getItem())
    elseif not action.started and action.item and action.item:getItem() then
        action.destContainer = destinationFor(action.character, action.item:getItem())
    end
    return originalGrabIsValid(action, ...)
end

local originalFishPickupUpdate = ISPickupFishAction.PickupFishUpdate
ISPickupFishAction.PickupFishUpdate = function(action, ...)
    local wasInInventory = action.fishInInv == true
    local result = originalFishPickupUpdate(action, ...)
    if wasInInventory or action.fishInInv ~= true
            or action.ChilaSedaSelectedContainerChecked then
        return result
    end
    action.ChilaSedaSelectedContainerChecked = true

    -- Fish enters the root inventory in the vanilla action. In single-player,
    -- move that same item to the selected bag after its normal catch bookkeeping.
    local player = action.character
    if not player or not action.item then return result end
    local main = player:getInventory()
    local item = action.item
	if action.isFish and item:getContainer() == main and not isClient() and not isServer() then
		local selected = selectedDestination(player)
		if selected and canStore(selected, player, item) then
			local ok, moved = pcall(function()
				main:Remove(item)
				if item:getContainer() == main then return false end
				selected:AddItem(item)
				if item:getContainer() ~= selected then
					selected:Remove(item)
					main:AddItem(item)
					return false
				end
				if type(sendRemoveItemFromContainer) == "function" then
					sendRemoveItemFromContainer(main, item)
				end
				if type(sendAddItemToContainer) == "function" then
					sendAddItemToContainer(selected, item)
				end
				return true
			end)

			if not ok or not moved then
				if item:getContainer() ~= main and item:getContainer() ~= selected then
					pcall(main.AddItem, main, item)
				end
			end
		end
	end
	if type(ChilaSeda_ViewpointNotifyStoredItem) == "function" then
		ChilaSeda_ViewpointNotifyStoredItem(player, item)
	end
    return result
end

print(TAG .. "vanilla ground and fishing pickups use the selected bag when it fits")
