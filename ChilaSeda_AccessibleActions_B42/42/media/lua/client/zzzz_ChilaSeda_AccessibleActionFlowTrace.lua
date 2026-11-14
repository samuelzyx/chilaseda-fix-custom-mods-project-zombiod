require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTransferAction"

local TAG = "[ChilaSeda_AccessibleActionTrace] "
if ISTimedActionQueue.__ChilaSedaAccessibleActionTrace then return end
ISTimedActionQueue.__ChilaSedaAccessibleActionTrace = true

local function call(object, method, ...)
    if not object then return nil end
    local ok, fn = pcall(function() return object[method] end)
    if not ok or type(fn) ~= "function" then return nil end
    local args = {...}
    local unpackValues = table.unpack or unpack
    local success, value = pcall(function() return fn(object, unpackValues(args)) end)
    if success then return value end
end

local function itemName(item)
    return item and tostring(call(item, "getFullType") or call(item, "getName") or "?") or "nil"
end

local function containerName(container)
    if not container then return "nil" end
    local bag = call(container, "getContainingItem")
    local parent = call(container, "getParent")
    local square = call(parent, "getSquare")
    local coords = square and string.format("%s,%s,%s", tostring(call(square, "getX")),
        tostring(call(square, "getY")), tostring(call(square, "getZ"))) or "?"
    return string.format("%s[%s]@%s", tostring(call(container, "getType") or "?"),
        itemName(bag), coords)
end

local function relevant(action)
    local kind = tostring(action and action.Type or "")
    return kind:find("Eat", 1, true) or kind:find("Unequip", 1, true)
        or kind:find("Wear", 1, true) or kind:find("Transfer", 1, true)
        or kind:find("Equip", 1, true) or kind:find("Fire", 1, true)
        or kind:find("Light", 1, true) or kind:find("Ignit", 1, true)
        or kind:find("Fuel", 1, true) or kind:find("Kindle", 1, true)
end

local function trace(event, action, result)
    if not relevant(action) then return end
    local item = action.item or action.itemToEat or action.itemToEquip
        or action.clothing or action.fuelItem or action.fireStarter
    print(TAG .. event .. " type=" .. tostring(action.Type or "?")
        .. " item=" .. itemName(item)
        .. " itemContainer=" .. containerName(item and call(item, "getContainer"))
        .. " source=" .. containerName(action.srcContainer)
        .. " destination=" .. containerName(action.destContainer)
        .. " target=" .. itemName(action.item)
        .. " result=" .. tostring(result or "n/a"))
end

local queueAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action, ...)
    trace("QUEUED", action == ISTimedActionQueue and select(1, ...) or action)
    return queueAdd(action, ...)
end

local queueComplete = ISTimedActionQueue.onCompleted
ISTimedActionQueue.onCompleted = function(self, action, ...)
    trace("QUEUE_COMPLETED", action, "queue callback")
    return queueComplete(self, action, ...)
end

local queueReset = ISTimedActionQueue.resetQueue
ISTimedActionQueue.resetQueue = function(self, ...)
    for _, action in ipairs(self and self.queue or {}) do
        trace("QUEUE_RESET_CANCEL", action, "resetQueue")
    end
    return queueReset(self, ...)
end

local function wrapTransfer(class, method, itemArg, destinationArg)
    if not class or type(class[method]) ~= "function" then return end
    local original = class[method]
    class[method] = function(self, ...)
        local item = select(itemArg, ...)
        if item == nil then item = self and self.item end
        local before = item and call(item, "getContainer")
        local dest = self and self.destContainer or select(destinationArg, ...)
        local result = original(self, ...)
        print(TAG .. "TRANSFER type=" .. tostring(self and self.Type or method)
            .. " item=" .. itemName(item) .. " source=" .. containerName(before)
            .. " destination=" .. containerName(dest)
            .. " after=" .. containerName(item and call(item, "getContainer")))
        return result
    end
end

wrapTransfer(ISInventoryTransferAction, "transferItem", 1, 0)
wrapTransfer(ISTransferAction, "transferItem", 2, 4)
print(TAG .. "installed; traces food, clothing, fire/fuel and item transfer outcomes")
