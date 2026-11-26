require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTransferAction"
require "TimedActions/ISWearClothing"
require "Entity/TimedActions/ISHandcraftAction"
require "ISUI/ISInventoryPaneContextMenu"
require "ISUI/ISWorldObjectContextMenu"
require "TimedActions/ISReadABook"
require "TimedActions/ISTakeWaterAction"

local TAG = "[ChilaSeda_AccessibleActionTrace] "
if ISTimedActionQueue.__ChilaSedaAccessibleActionTrace then return end
ISTimedActionQueue.__ChilaSedaAccessibleActionTrace = true

local CAPSLOCK_WATCH_MS = 3000
local CAPSLOCK_SCAN_INTERVAL_MS = 200
local MAX_CAPSLOCK_WINDOW_EVENTS = 32
local lastCapsLockAt = nil
local capsLockWatchUntil = 0
local lastCapsLockScanAt = 0
local lastCapsLockCameraState = nil
local capsLockWindows = {}
local capsLockWindowEventCount = 0
local capsLockWindowLimitLogged = false
local capsLockWindowScanFailureLogged = false
local waterTraceCount = 0
local MAX_WATER_TRACE_LINES = 96
local waterTraceLimitLogged = false
local TRACE_TRANSFER_CALLERS = true
local transferCallerTraceCount = 0
local MAX_TRANSFER_CALLSITE_TRACES = 32
local transferCallerTraceLimitLogged = false
local TRACE_WEAR_FLOW = true
local MAX_WEAR_FLOW_EVENTS = 128
local WEAR_FLOW_WINDOW_MS = 10000
local wearFlowSequence = 0
local wearFlowEventCount = 0
local wearFlowLimitLogged = false
local activeWearFlow = nil
local luaManagerClass = nil
local luaManagerBindAttempted = false
local luaManagerBindReason = "not-tried"

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

local function monotonicMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and type(value) == "number" then return math.floor(value), "game" end
    end
    if os and type(os.clock) == "function" then
        local ok, value = pcall(os.clock)
        if ok and type(value) == "number" then return math.floor(value * 1000), "os.clock" end
    end
    if os and type(os.time) == "function" then
        local ok, value = pcall(os.time)
        if ok and type(value) == "number" then return math.floor(value * 1000), "os.time" end
    end
    return 0, "unavailable"
end

local function timestampFields()
    local value, source = monotonicMs()
    return "timeMs=" .. tostring(value) .. " clock=" .. source
end

local function capsLockAgeMs()
    if not lastCapsLockAt then return nil end
    local now = monotonicMs()
    local age = now - lastCapsLockAt
    if age < 0 or age > CAPSLOCK_WATCH_MS then return nil end
    return age
end

local function logDiagnostic(event, fields)
    print(TAG .. event .. " " .. timestampFields() .. " " .. tostring(fields or ""))
end

local function safeField(object, field)
    local ok, value = pcall(function() return object and object[field] end)
    if ok then return value end
    return nil
end

local function appendCallerFrame(frames, value)
    if type(value) ~= "string" then return end
    local frame = value:gsub("\\", "/"):gsub("[%s\r\n]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if frame == "" or not frame:find("%.lua:%d+")
        or frame:find("AccessibleActionFlowTrace", 1, true)
        or frame:find("ISTimedActionQueue.add", 1, true) then
        return
    end
    frame = frame:match("([^/]+%.lua:%d+)") or frame
    if #frame > 140 then frame = frame:sub(1, 137) .. "..." end
    frames[#frames + 1] = frame
end

local function callerStackSummary()
    local frames = {}
    local stackSource = "LuaManager"
    local stack
    local java = safeField(_G, "luajava")
    local bindClass = safeField(java, "bindClass")
    if type(bindClass) == "function" and not luaManagerBindAttempted then
        luaManagerBindAttempted = true
        local ok, bound = pcall(function() return bindClass("zombie.Lua.LuaManager") end)
        if ok and bound then
            luaManagerClass = bound
            luaManagerBindReason = "bound"
        else
            luaManagerBindReason = "bind-failed"
        end
    elseif type(bindClass) ~= "function" then
        luaManagerBindReason = "luajava-bindClass-unavailable"
    end
    local stackGetter = safeField(luaManagerClass, "getLuaStackTraceStrings")
    if type(stackGetter) == "function" then
        local ok, value = pcall(function() return stackGetter(nil) end)
        if ok then
            stack = value
        else
            luaManagerBindReason = "stack-call-failed"
        end
    else
        luaManagerBindReason = luaManagerClass and "stack-method-unavailable" or luaManagerBindReason
    end

    local function appendStack(value)
        if value == nil then return end
        local isLuaTable = type(value) == "table"
        local count = isLuaTable and #value or call(value, "size")
        if type(count) ~= "number" then return end
        for index = 1, math.min(count, 16) do
            local frame = isLuaTable and value[index] or call(value, "get", index - 1)
            appendCallerFrame(frames, frame)
            if #frames >= 5 then break end
        end
    end
    appendStack(stack)

    if #frames == 0 then
        stackSource = "getLuaStackTrace"
        local stackGetter = safeField(_G, "getLuaStackTrace")
        if type(stackGetter) == "function" then
            local ok, fallbackStack = pcall(stackGetter)
            if ok then appendStack(fallbackStack) end
        end
    end

    if #frames == 0 then
        stackSource = "debug.traceback"
        local debugLibrary = safeField(_G, "debug")
        local traceback = safeField(debugLibrary, "traceback")
        if type(traceback) == "function" then
            local ok, fallbackStack = pcall(traceback)
            if ok and type(fallbackStack) == "string" then
                for frame in fallbackStack:gmatch("[^\r\n]+") do
                    appendCallerFrame(frames, frame)
                    if #frames >= 5 then break end
                end
            end
        end
    end

    if #frames == 0 then return "unavailable:lua-stack-api:" .. luaManagerBindReason, "none" end
    return table.concat(frames, ">"), stackSource
end

local function cameraState()
    local bridge = ChilaSedaViewpointFogJ
    local getter = safeField(bridge, "movableCameraState")
    if type(getter) ~= "function" then return "unavailable:bridge" end
    local ok, state = pcall(getter)
    if not ok then return "error:call" end
    if type(state) ~= "number" then return "unavailable:result" end
    return state
end

local function actionName(action)
    if not action then return "nil" end
    local item = action.item or action.itemToRead or action.itemToEat or action.itemToEquip
    return tostring(action.Type or "?") .. ":" .. itemName(item)
end

local function queueFor(character)
    local queues = ISTimedActionQueue and ISTimedActionQueue.queues
    return queues and character and queues[character] or nil
end

local function queueSummary(character)
    local queue = queueFor(character)
    local actions = queue and queue.queue
    if type(actions) ~= "table" then return "unavailable" end
    local labels = {}
    for index, action in ipairs(actions) do
        if index > 5 then break end
        labels[#labels + 1] = actionName(action)
    end
    return "count=" .. tostring(#actions) .. ",actions="
        .. (#labels > 0 and table.concat(labels, ";") or "none")
end

local function currentPlayer()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local ok, player = pcall(getSpecificPlayer, 0)
    if ok then return player end
    return nil
end

local function windowLabel(window)
    local title = call(window, "getUIName") or call(window, "getTitle")
        or call(window, "getName")
    local kind = safeField(window, "Type") or "UIElement"
    return tostring(kind) .. "[" .. tostring(title or "?") .. "]"
end

local function windowIdentity(window, index)
    local hash = call(window, "hashCode")
    if type(hash) == "number" then return "hash:" .. tostring(hash) end
    return windowLabel(window) .. "#" .. tostring(index or "?")
end

local function windowVisibility(window)
    local visible = call(window, "isVisible")
    if type(visible) == "boolean" then return visible end
    visible = call(window, "getIsVisible")
    if type(visible) == "boolean" then return visible end
    visible = safeField(window, "visible")
    if type(visible) == "boolean" then return visible end
    return nil
end

local function collectWindows()
    local manager = UIManager
    local getter = safeField(manager, "getUI")
    if type(getter) ~= "function" then return nil, "getUI-unavailable" end
    local ok, list = pcall(function() return getter() end)
    if not ok or not list then return nil, "getUI-failed" end

    local windows = {}
    local function add(window, index)
        if window then
            local id = windowIdentity(window, index)
            windows[id] = {
                id = id,
                label = windowLabel(window),
                visible = windowVisibility(window),
            }
        end
    end
    if type(list) == "table" then
        for index, window in pairs(list) do add(window, index) end
        return windows
    end

    local size = call(list, "size")
    if type(size) ~= "number" then return nil, "window-list-size-unavailable" end
    for index = 0, size - 1 do add(call(list, "get", index), index + 1) end
    return windows
end

local function visibleWindowSummary(windows)
    local labels, visibleCount = {}, 0
    for _, window in pairs(windows or {}) do
        if window.visible == true then
            visibleCount = visibleCount + 1
            if #labels < 8 then labels[#labels + 1] = window.label end
        end
    end
    return tostring(visibleCount) .. "[" .. (#labels > 0 and table.concat(labels, ";") or "none") .. "]"
end

local function logCapsLockWindowChange(event, window)
    if capsLockWindowEventCount >= MAX_CAPSLOCK_WINDOW_EVENTS then
        if not capsLockWindowLimitLogged then
            capsLockWindowLimitLogged = true
            logDiagnostic("CAPSLOCK_WINDOW_TRACE_LIMIT", "limit=" .. tostring(MAX_CAPSLOCK_WINDOW_EVENTS))
        end
        return
    end
    capsLockWindowEventCount = capsLockWindowEventCount + 1
    local age = capsLockAgeMs()
    logDiagnostic("CAPSLOCK_WINDOW_" .. event,
        "ageMs=" .. tostring(age or "expired") .. " window=" .. tostring(window and window.label or "?"))
end

local function recipeForAction(action)
    return action and (action.recipe or action.currentRecipe)
        or call(action and action.recipeData, "getRecipe")
end

local function recipeName(action)
    local recipe = recipeForAction(action)
    return recipe and tostring(call(recipe, "getTranslationName")
        or call(recipe, "getName") or "?") or "?"
end

local function isWaterAction(action)
    local kind = tostring(action and action.Type or "")
    return kind:find("Water", 1, true) ~= nil
        or kind:find("Fill", 1, true) ~= nil
        or kind:find("Fluid", 1, true) ~= nil
end

local function waterSourceLabel(source)
    return tostring(call(source, "getObjectName") or call(source, "getFluidUiName")
        or call(source, "getName") or call(source, "getType") or "unknown")
end

local function waterActionFields(action)
    local item = action and (action.item or action.waterContainer or action.itemToFill)
    local fluid = call(item, "getFluidContainer")
    local source = action and (action.waterObject or action.waterSource or action.sourceObject)
    return "waterSource=" .. waterSourceLabel(source)
        .. " sourceAmount=" .. tostring(call(source, "getFluidAmount") or "n/a")
        .. " sourceTainted=" .. tostring(call(source, "isTaintedWater"))
        .. " waterItem=" .. itemName(item)
        .. " itemContainer=" .. containerName(item and call(item, "getContainer"))
        .. " itemFluid=" .. tostring(call(fluid, "getAmount") or "n/a")
        .. " itemCapacity=" .. tostring(call(fluid, "getCapacity") or "n/a")
        .. " beingFilled=" .. tostring(call(item, "isBeingFilled"))
end

local function takeWaterTraceSlot()
    if waterTraceCount >= MAX_WATER_TRACE_LINES then
        if not waterTraceLimitLogged then
            waterTraceLimitLogged = true
            logDiagnostic("WATER_TRACE_LIMIT", "limit=" .. tostring(MAX_WATER_TRACE_LINES))
        end
        return false
    end
    waterTraceCount = waterTraceCount + 1
    return true
end

local function logWaterEvent(event, fields)
    if not takeWaterTraceSlot() then return end
    logDiagnostic("WATER_" .. event, fields)
end

local function logWaterAction(event, action, result)
    if not takeWaterTraceSlot() then return end
    logDiagnostic("WATER_" .. event,
        "type=" .. tostring(action and action.Type or "ISTakeWaterAction")
            .. " " .. waterActionFields(action)
            .. " result=" .. tostring(result or "n/a"))
end

local function relevant(action)
    local kind = tostring(action and action.Type or "")
    if isWaterAction(action) then return true end
    if kind:find("Handcraft", 1, true) then
        if action.chilaSedaAccessibleBatch or action.chilaSedaDismantleContext then
            return true
        end
        local name = string.lower(recipeName(action))
        return name:find("reduce", 1, true) ~= nil
            or name:find("grasa", 1, true) ~= nil
            or name:find("tallow", 1, true) ~= nil
    end
    return kind:find("Eat", 1, true) or kind:find("Unequip", 1, true)
        or kind:find("Wear", 1, true) or kind:find("Transfer", 1, true)
        or kind:find("Equip", 1, true) or kind:find("Fire", 1, true)
        or kind:find("Light", 1, true) or kind:find("Ignit", 1, true)
        or kind:find("Fuel", 1, true) or kind:find("Kindle", 1, true)
        or kind:find("ReadABook", 1, true)
end

local function trace(event, action, result, force)
    if not force and not relevant(action) then return end
    if isWaterAction(action) then
        logWaterAction("ACTION_" .. event, action, result)
        return
    end
    local item = action and (action.item or action.itemToRead or action.itemToEat or action.itemToEquip
        or action.clothing or action.fuelItem or action.fireStarter)
    local recipe = recipeForAction(action)
    local capsAge = capsLockAgeMs()
    print(TAG .. event .. " " .. timestampFields()
        .. " capsLockAgeMs=" .. tostring(capsAge or "n/a")
        .. " type=" .. tostring(action and action.Type or "?")
        .. " item=" .. itemName(item)
        .. " itemContainer=" .. containerName(item and call(item, "getContainer"))
        .. " source=" .. containerName(action.srcContainer)
        .. " destination=" .. containerName(action.destContainer)
        .. " target=" .. itemName(action.item)
        .. " recipe=" .. recipeName(action)
        .. " canDoFromFloor=" .. tostring(call(recipe, "isCanBeDoneFromFloor"))
        .. " result=" .. tostring(result or "n/a"))
end

local function traceClothingTransferCaller(action)
    if not TRACE_TRANSFER_CALLERS or not action
        or action.Type ~= "ISInventoryTransferAction"
        or call(action.item, "IsClothing") ~= true then
        return
    end
    if transferCallerTraceCount >= MAX_TRANSFER_CALLSITE_TRACES then
        if not transferCallerTraceLimitLogged then
            transferCallerTraceLimitLogged = true
            logDiagnostic("TRANSFER_CALLSITE_LIMIT", "limit=" .. tostring(MAX_TRANSFER_CALLSITE_TRACES))
        end
        return
    end
    transferCallerTraceCount = transferCallerTraceCount + 1
    local caller, callerSource = callerStackSummary()
    logDiagnostic("TRANSFER_CALLSITE",
        "item=" .. itemName(action.item)
            .. " source=" .. containerName(action.srcContainer)
            .. " destination=" .. containerName(action.destContainer)
            .. " callerApi=" .. tostring(callerSource)
            .. " caller=" .. tostring(caller))
end

local function wearItemId(item)
    local id = call(item, "getID") or safeField(item, "id")
    return id == nil and "na" or tostring(id)
end

local function sameWearItem(record, item)
    if not record or not item then return false end
    if item == record.item then return true end
    return wearItemId(item) == record.itemId and itemName(item) == record.itemType
end

local function wearSlotState(player, item)
    local slot = call(item, "canBeEquipped")
    if slot == nil or slot == "" then slot = call(item, "getBodyLocation") end
    if slot == nil or slot == "" then return "none", nil end
    return tostring(slot), call(player, "getWornItem", slot)
end

local function wearFlowCurrent()
    if not TRACE_WEAR_FLOW or not activeWearFlow then return nil end
    local now = monotonicMs()
    if activeWearFlow.startedAt > 0 and now > 0
        and now - activeWearFlow.startedAt > WEAR_FLOW_WINDOW_MS then
        return nil
    end
    return activeWearFlow
end

local function logWearFlow(event, record, item, fields)
    if not TRACE_WEAR_FLOW or not record then return end
    if wearFlowEventCount >= MAX_WEAR_FLOW_EVENTS then
        if not wearFlowLimitLogged then
            wearFlowLimitLogged = true
            logDiagnostic("WEAR_FLOW_LIMIT", "limit=" .. tostring(MAX_WEAR_FLOW_EVENTS))
        end
        return
    end
    wearFlowEventCount = wearFlowEventCount + 1
    local observedItem = item or record.item
    local slot, wornItem = wearSlotState(record.player, observedItem)
    print(TAG .. "WEAR_FLOW_" .. tostring(event) .. " " .. timestampFields()
        .. " seq=" .. tostring(record.sequence)
        .. " item=" .. itemName(observedItem)
        .. " id=" .. wearItemId(observedItem)
        .. " container=" .. containerName(call(observedItem, "getContainer"))
        .. " slot=" .. slot
        .. " worn=" .. itemName(wornItem)
        .. " wornId=" .. wearItemId(wornItem)
        .. (fields and (" " .. tostring(fields)) or ""))
end

local function beginWearFlow(item, playerNum)
    if not TRACE_WEAR_FLOW then return nil end
    local player
    if type(getSpecificPlayer) == "function" then
        local ok, value = pcall(getSpecificPlayer, playerNum)
        if ok then player = value end
    end
    wearFlowSequence = wearFlowSequence + 1
    local startedAt = monotonicMs()
    activeWearFlow = {
        sequence = wearFlowSequence,
        item = item,
        itemId = wearItemId(item),
        itemType = itemName(item),
        player = player,
        playerNum = tonumber(playerNum) or call(player, "getPlayerNum"),
        startedAt = startedAt,
    }
    local caller, callerSource = callerStackSummary()
    logWearFlow("REQUEST", activeWearFlow, item,
        "playerNum=" .. tostring(playerNum)
            .. " callerApi=" .. tostring(callerSource)
            .. " caller=" .. tostring(caller))
    return activeWearFlow
end

local function wearActionTypeRelevant(action)
    local kind = tostring(action and action.Type or "")
    return kind:find("Transfer", 1, true) ~= nil
        or kind:find("Wear", 1, true) ~= nil
        or kind:find("Unequip", 1, true) ~= nil
        or kind:find("Equip", 1, true) ~= nil
end

local function traceWearQueuedAction(action, queueMethod)
    local record = wearFlowCurrent()
    if not record or not action then return end
    local actionPlayerNum = call(action.character, "getPlayerNum")
    local samePlayer = record.playerNum == nil or actionPlayerNum == nil
        or tonumber(actionPlayerNum) == tonumber(record.playerNum)
    local matchesItem = sameWearItem(record, action.item)
    if not samePlayer or (not matchesItem and not wearActionTypeRelevant(action)) then return end
    local caller, callerSource = callerStackSummary()
    logWearFlow("" .. tostring(queueMethod), record, action.item,
        "type=" .. tostring(action.Type or "?")
            .. " selectedItem=" .. tostring(matchesItem)
            .. " source=" .. containerName(action.srcContainer)
            .. " destination=" .. containerName(action.destContainer)
            .. " callerApi=" .. tostring(callerSource)
            .. " caller=" .. tostring(caller))
end

local function packWearResults(...)
    return { n = select("#", ...), ... }
end

local function unpackWearResults(values)
    local unpackValues = table.unpack or unpack
    return unpackValues(values, 1, values.n)
end

local function wrapWearLifecycle(methodName)
    local actionClass = ISWearClothing
    if not actionClass or type(actionClass[methodName]) ~= "function"
        or actionClass["__ChilaSedaWearFlow_" .. methodName] then
        return
    end
    local original = actionClass[methodName]
    actionClass[methodName] = function(self, ...)
        local record = wearFlowCurrent()
        local item = self and self.item
        if not record or not sameWearItem(record, item) then
            return original(self, ...)
        end
        local slotBefore, wornBefore = wearSlotState(self.character, item)
        logWearFlow("ACTION_" .. string.upper(methodName) .. "_BEGIN", record, item,
            "slotBefore=" .. slotBefore .. " wornBefore=" .. itemName(wornBefore)
                .. " wornBeforeId=" .. wearItemId(wornBefore))
        local results = packWearResults(original(self, ...))
        local slotAfter, wornAfter = wearSlotState(self.character, item)
        logWearFlow("ACTION_" .. string.upper(methodName) .. "_END", record, item,
            "slotBefore=" .. slotBefore .. " wornBefore=" .. itemName(wornBefore)
                .. " wornBeforeId=" .. wearItemId(wornBefore)
                .. " slotAfter=" .. slotAfter .. " wornAfter=" .. itemName(wornAfter)
                .. " wornAfterId=" .. wearItemId(wornAfter)
                .. " result=" .. tostring(results[1]))
        return unpackWearResults(results)
    end
    actionClass["__ChilaSedaWearFlow_" .. methodName] = true
end

if ISInventoryPaneContextMenu and type(ISInventoryPaneContextMenu.wearItem) == "function"
    and not ISInventoryPaneContextMenu.__ChilaSedaWearFlowTrace then
    local originalWearItem = ISInventoryPaneContextMenu.wearItem
    ISInventoryPaneContextMenu.wearItem = function(item, playerNum, ...)
        local record = beginWearFlow(item, playerNum)
        local results = packWearResults(originalWearItem(item, playerNum, ...))
        if record then
            logWearFlow("REQUEST_QUEUED", record, item, "result=" .. tostring(results[1]))
        end
        return unpackWearResults(results)
    end
    ISInventoryPaneContextMenu.__ChilaSedaWearFlowTrace = true
end

for _, methodName in ipairs({ "start", "complete", "perform", "stop" }) do
    wrapWearLifecycle(methodName)
end

local function wrapWaterAction(methodName)
    local actionClass = ISTakeWaterAction
    if not actionClass or type(actionClass[methodName]) ~= "function" then return end
    local original = actionClass[methodName]
    actionClass[methodName] = function(self, ...)
        logWaterAction(string.upper(methodName) .. "_BEGIN", self)
        local result = original(self, ...)
        logWaterAction(string.upper(methodName) .. "_END", self, result)
        return result
    end
end

for _, methodName in ipairs({ "isValid", "start", "complete", "perform", "stop", "transferFluid" }) do
    wrapWaterAction(methodName)
end

local function summarizeWaterItems(items)
    if type(items) ~= "table" then return itemName(items) end
    local names = {}
    for index, item in ipairs(items) do
        if index > 12 then names[#names + 1] = "+" .. tostring(#items - 12); break end
        names[#names + 1] = itemName(item)
    end
    return #names > 0 and table.concat(names, ",") or "none"
end

local onTakeWater = ISWorldObjectContextMenu and ISWorldObjectContextMenu.onTakeWater
if type(onTakeWater) == "function" then
    ISWorldObjectContextMenu.onTakeWater = function(worldobjects, waterObject, waterContainerList,
            waterContainer, playerIndex, ...)
        local playerObj = type(getSpecificPlayer) == "function" and getSpecificPlayer(playerIndex) or nil
        local selected = waterContainerList and #waterContainerList > 0
            and summarizeWaterItems(waterContainerList) or itemName(waterContainer)
        logWaterEvent("FILL_CALLBACK_BEGIN", "source=" .. waterSourceLabel(waterObject)
            .. " sourceAmount=" .. tostring(call(waterObject, "getFluidAmount") or "n/a")
            .. " selected=" .. selected .. " player=" .. tostring(playerIndex)
            .. " queue=" .. queueSummary(playerObj))
        local result = onTakeWater(worldobjects, waterObject, waterContainerList,
            waterContainer, playerIndex, ...)
        logWaterEvent("FILL_CALLBACK_END", "source=" .. waterSourceLabel(waterObject)
            .. " selected=" .. selected .. " result=" .. tostring(result or "n/a")
            .. " queue=" .. queueSummary(playerObj))
        return result
    end
end

local function wrapHandcraftLifecycle(methodName)
    local actionClass = ISHandcraftAction
    if not actionClass or type(actionClass[methodName]) ~= "function" then return end
    local original = actionClass[methodName]
    actionClass[methodName] = function(self, ...)
        trace("HANDCRAFT_" .. string.upper(methodName) .. "_BEGIN", self)
        local result = original(self, ...)
        trace("HANDCRAFT_" .. string.upper(methodName) .. "_END", self)
        return result
    end
end

wrapHandcraftLifecycle("start")
wrapHandcraftLifecycle("perform")
wrapHandcraftLifecycle("stop")
wrapHandcraftLifecycle("complete")

local function wrapReadBookLifecycle(methodName)
    local actionClass = ISReadABook
    if not actionClass or type(actionClass[methodName]) ~= "function" then return end
    local original = actionClass[methodName]
    actionClass[methodName] = function(self, ...)
        trace("READBOOK_" .. string.upper(methodName) .. "_BEGIN", self)
        local result = original(self, ...)
        trace("READBOOK_" .. string.upper(methodName) .. "_END", self, result)
        return result
    end
end

wrapReadBookLifecycle("start")
wrapReadBookLifecycle("perform")
wrapReadBookLifecycle("stop")
wrapReadBookLifecycle("complete")

local function itemPrintMedia(item)
    local data = call(item, "getModData")
    return data and tostring(data.printMedia or "none") or "unavailable"
end

local function literatureSelectionSummary(items)
    local actual = items
    if ISInventoryPane and type(ISInventoryPane.getActualUniqueItems) == "function" then
        local ok, result = pcall(ISInventoryPane.getActualUniqueItems, items)
        if ok and result then actual = result end
    end
    local names, count = {}, 0
    if type(actual) == "table" then
        for _, item in ipairs(actual) do
            count = count + 1
            if #names < 8 then
                names[#names + 1] = itemName(item) .. "{printMedia=" .. itemPrintMedia(item) .. "}"
            end
        end
    else
        local size = call(actual, "size")
        if type(size) == "number" then
            count = size
            for index = 0, math.min(size - 1, 7) do
                local item = call(actual, "get", index)
                names[#names + 1] = itemName(item) .. "{printMedia=" .. itemPrintMedia(item) .. "}"
            end
        end
    end
    return "count=" .. tostring(count) .. ",items="
        .. (#names > 0 and table.concat(names, ";") or "unavailable")
end

local function wrapLiteratureCallback(methodName, eventName)
    local contextMenu = ISInventoryPaneContextMenu
    if not contextMenu or type(contextMenu[methodName]) ~= "function" then return end
    local original = contextMenu[methodName]
    contextMenu[methodName] = function(items, player, ...)
        local before = methodName == "onLiteratureItems"
            and literatureSelectionSummary(items)
            or ("item=" .. itemName(items) .. " printMedia=" .. itemPrintMedia(items)
                .. " container=" .. containerName(call(items, "getContainer")))
        logDiagnostic(eventName .. "_BEGIN", "player=" .. tostring(player) .. " " .. before)
        local result = original(items, player, ...)
        local after = methodName == "readItem"
            and ("item=" .. itemName(items) .. " container=" .. containerName(call(items, "getContainer"))
                .. " queue=" .. queueSummary(currentPlayer()))
            or before
        logDiagnostic(eventName .. "_END", "player=" .. tostring(player) .. " " .. after)
        return result
    end
end

wrapLiteratureCallback("onLiteratureItems", "LITERATURE_INSPECT")
wrapLiteratureCallback("readItem", "LITERATURE_READ_ITEM")

local queueAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action, ...)
    local queuedAction = action == ISTimedActionQueue and select(1, ...) or action
    trace("QUEUED", queuedAction)
    traceClothingTransferCaller(queuedAction)
    traceWearQueuedAction(queuedAction, "QUEUE_ADD")
    local result = queueAdd(action, ...)
    local age = capsLockAgeMs()
    if age then
        logDiagnostic("CAPSLOCK_QUEUE_ADD", "ageMs=" .. tostring(age)
            .. " action=" .. actionName(action) .. " queue=" .. queueSummary(action and action.character))
    end
    return result
end

if type(ISTimedActionQueue.addAfter) == "function"
    and not ISTimedActionQueue.__ChilaSedaWearFlowAddAfterTrace then
    local queueAddAfter = ISTimedActionQueue.addAfter
    ISTimedActionQueue.addAfter = function(previousAction, action, ...)
        local queuedAction = action
        if previousAction == ISTimedActionQueue then queuedAction = select(1, ...) end
        traceWearQueuedAction(queuedAction, "QUEUE_ADD_AFTER")
        return queueAddAfter(previousAction, action, ...)
    end
    ISTimedActionQueue.__ChilaSedaWearFlowAddAfterTrace = true
end

local queueComplete = ISTimedActionQueue.onCompleted
ISTimedActionQueue.onCompleted = function(self, action, ...)
    trace("QUEUE_COMPLETED", action, "queue callback")
    return queueComplete(self, action, ...)
end

local queueReset = ISTimedActionQueue.resetQueue
ISTimedActionQueue.resetQueue = function(self, ...)
    local capsAge = capsLockAgeMs()
    for _, action in ipairs(self and self.queue or {}) do
        trace("QUEUE_RESET_CANCEL", action, "resetQueue", capsAge ~= nil)
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
        local wearRecord = wearFlowCurrent()
        local wearRelated = wearRecord and (sameWearItem(wearRecord, item)
            or call(dest, "getType") == "floor")
        if wearRelated then
            local caller, callerSource = callerStackSummary()
            logWearFlow("TRANSFER_BEGIN", wearRecord, item,
                "type=" .. tostring(self and self.Type or method)
                    .. " source=" .. containerName(before)
                    .. " destination=" .. containerName(dest)
                    .. " callerApi=" .. tostring(callerSource)
                    .. " caller=" .. tostring(caller))
        end
        local result = original(self, ...)
        if wearRelated then
            logWearFlow("TRANSFER_END", wearRecord, item,
                "type=" .. tostring(self and self.Type or method)
                    .. " source=" .. containerName(before)
                    .. " destination=" .. containerName(dest)
                    .. " result=" .. tostring(result)
                    .. " after=" .. containerName(item and call(item, "getContainer")))
        end
        print(TAG .. "TRANSFER " .. timestampFields()
            .. " capsLockAgeMs=" .. tostring(capsLockAgeMs() or "n/a")
            .. " type=" .. tostring(self and self.Type or method)
            .. " item=" .. itemName(item) .. " source=" .. containerName(before)
            .. " destination=" .. containerName(dest)
            .. " after=" .. containerName(item and call(item, "getContainer")))
        return result
    end
end

wrapTransfer(ISInventoryTransferAction, "transferItem", 1, 0)
wrapTransfer(ISTransferAction, "transferItem", 2, 4)

local function isCapsLockKey(key)
    local keyCodes = { 58 }
    local keyboard = Keyboard
    local capital = safeField(keyboard, "KEY_CAPITAL")
    local capsLock = safeField(keyboard, "KEY_CAPSLOCK")
    if type(capital) == "number" then keyCodes[#keyCodes + 1] = capital end
    if type(capsLock) == "number" then keyCodes[#keyCodes + 1] = capsLock end
    for _, keyCode in ipairs(keyCodes) do
        if tonumber(key) == keyCode then return true end
    end
    return false
end

local function onCapsLockPressed(key)
    if not isCapsLockKey(key) then return end
    local now = monotonicMs()
    lastCapsLockAt = now
    capsLockWatchUntil = now + CAPSLOCK_WATCH_MS
    lastCapsLockScanAt = now
    lastCapsLockCameraState = cameraState()
    capsLockWindowEventCount = 0
    capsLockWindowLimitLogged = false
    capsLockWindowScanFailureLogged = false
    capsLockWindows = collectWindows() or {}
    logDiagnostic("CAPSLOCK_PRESSED", "key=" .. tostring(key)
        .. " cameraState=" .. tostring(lastCapsLockCameraState)
        .. " queue=" .. queueSummary(currentPlayer())
        .. " visibleWindows=" .. visibleWindowSummary(capsLockWindows))
end

local function onCapsLockWatchTick()
    if not lastCapsLockAt then return end
    local now = monotonicMs()
    if now > capsLockWatchUntil then
        logDiagnostic("CAPSLOCK_WATCH_END", "cameraState=" .. tostring(cameraState())
            .. " queue=" .. queueSummary(currentPlayer())
            .. " visibleWindows=" .. visibleWindowSummary(capsLockWindows))
        lastCapsLockAt = nil
        capsLockWindows = {}
        return
    end
    if now - lastCapsLockScanAt < CAPSLOCK_SCAN_INTERVAL_MS then return end
    lastCapsLockScanAt = now

    local state = cameraState()
    if state ~= lastCapsLockCameraState then
        logDiagnostic("CAPSLOCK_CAMERA_STATE", "ageMs=" .. tostring(capsLockAgeMs() or "n/a")
            .. " before=" .. tostring(lastCapsLockCameraState) .. " after=" .. tostring(state))
        lastCapsLockCameraState = state
    end

    local current, reason = collectWindows()
    if not current then
        if not capsLockWindowScanFailureLogged then
            capsLockWindowScanFailureLogged = true
            logDiagnostic("CAPSLOCK_WINDOW_SCAN_UNAVAILABLE", "reason=" .. tostring(reason))
        end
        return
    end
    for id, previous in pairs(capsLockWindows) do
        local currentWindow = current[id]
        if not currentWindow then
            if previous.visible ~= false then logCapsLockWindowChange("REMOVED", previous) end
        elseif previous.visible ~= currentWindow.visible then
            local change = currentWindow.visible == false and "HIDDEN"
                or (currentWindow.visible == true and "SHOWN" or "VISIBILITY_UNKNOWN")
            logCapsLockWindowChange(change, currentWindow)
        end
    end
    for id, currentWindow in pairs(current) do
        if not capsLockWindows[id] and currentWindow.visible == true then
            logCapsLockWindowChange("OPENED", currentWindow)
        end
    end
    capsLockWindows = current
end

if Events and Events.OnKeyStartPressed and type(Events.OnKeyStartPressed.Add) == "function" then
    Events.OnKeyStartPressed.Add(onCapsLockPressed)
else
    logDiagnostic("CAPSLOCK_TRACE_UNAVAILABLE", "reason=OnKeyStartPressed-missing")
end

if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(onCapsLockWatchTick)
else
    logDiagnostic("CAPSLOCK_TRACE_UNAVAILABLE", "reason=OnTick-missing")
end

logDiagnostic("INSTALLED", "traces=timed-actions,transfers,literature-inspect,capslock-window-camera-queue")
