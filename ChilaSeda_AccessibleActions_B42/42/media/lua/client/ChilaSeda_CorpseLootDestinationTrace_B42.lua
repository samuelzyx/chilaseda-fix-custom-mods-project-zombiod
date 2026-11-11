require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "ISUI/ISInventoryPane"

local TAG = "[ChilaSeda AccessibleActions CorpseLootTrace]"
local activeRoute = "queue"

local function call(object, method)
    if not object then return nil end
    local ok, fn, value = pcall(function() return object[method] end)
    if not ok or type(fn) ~= "function" then return nil end
    ok, value = pcall(fn, object)
    if ok then return value end
    return nil
end

local function text(value)
    if value == nil then return "nil" end
    return tostring(value)
end

local function className(object)
    -- Java class objects are exposed as userdata by Kahlua; indexing getName
    -- can raise "attempted index ... of non-table". The Lua type is enough here.
    return type(object)
end

local function itemName(item)
    if not item then return "nil" end
    return text(call(item, "getFullType") or call(item, "getType") or className(item))
end

local function containerType(container)
    return text(call(container, "getType"))
end

local function isCorpseContainer(container)
    if not container then return false end
    local kind = containerType(container)
    if kind == "inventorymale" or kind == "inventoryfemale" then return true end

    local parent = call(container, "getParent")
    if instanceof and parent then
        local ok, result = pcall(instanceof, parent, "IsoDeadBody")
        if ok and result then return true end
    end
    return false
end

local function safeMetric(container, method, ...)
    if not container then return "n/a" end
    local args = { ... }
    local ok, fn = pcall(function() return container[method] end)
    if not ok or type(fn) ~= "function" then return "n/a" end
    local unpackValues = table.unpack or unpack
    local success, value = pcall(function() return fn(container, unpackValues(args)) end)
    ok = success
    if not ok then return "error" end
    return text(value)
end

local function logTransfer(action)
    local item = action and action.item
    local source = action and action.srcContainer
    if not item or not isCorpseContainer(source) then return end

    local player = action.character
    local destination = action.destContainer
    local mainInventory = player and call(player, "getInventory")
    local bag = call(destination, "getContainingItem")
    local parent = call(source, "getParent")
    print(string.format(
        "%s route=%s item=%s name=%s source=%s sourceParent=%s destination=%s destinationBag=%s destinationIsMain=%s hasRoom=%s itemAllowed=%s contentsWeight=%s capacity=%s",
        TAG, activeRoute, itemName(item), text(call(item, "getName")), containerType(source),
        className(parent), containerType(destination), itemName(bag),
        tostring(destination ~= nil and destination == mainInventory),
        safeMetric(destination, "hasRoomFor", player, item),
        safeMetric(destination, "isItemAllowed", item),
        safeMetric(destination, "getContentsWeight", nil, nil),
        safeMetric(destination, "getCapacity", nil, nil)
    ))
end

local originalQueueAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action, ...)
    local queuedAction = action
    if action == ISTimedActionQueue then queuedAction = select(1, ...) end
    if queuedAction and queuedAction.item and queuedAction.srcContainer then
        logTransfer(queuedAction)
    end
    return originalQueueAdd(action, ...)
end

local function withRoute(route, callback, ...)
    local previous = activeRoute
    activeRoute = route
    local ok, result = pcall(callback, ...)
    activeRoute = previous
    if not ok then error(result, 0) end
    return result
end

if ViewpointLoot and type(ViewpointLoot.take) == "function" then
    local originalTake = ViewpointLoot.take
    ViewpointLoot.take = function(player, item, ...)
        return withRoute("ViewpointLoot.take", originalTake, player, item, ...)
    end
end

if ISInventoryPane and type(ISInventoryPane.transferItemsByWeight) == "function" then
    local originalTransferItemsByWeight = ISInventoryPane.transferItemsByWeight
    ISInventoryPane.transferItemsByWeight = function(self, items, destination, ...)
        return withRoute("ISInventoryPane.transferItemsByWeight", originalTransferItemsByWeight,
            self, items, destination, ...)
    end
end

print(TAG .. " Loaded v1.0.0")
