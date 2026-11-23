local Calibration = require "ChilaSeda_ViewpointNativeForageHeightCalibration"
local TAG = "[ChilaSeda_ViewpointNativeForageCalibration] "

local binding = nil
local warned = false
local basePinHeight = nil
local basePinUp = nil
local lastPinHeight = nil
local lastPinUp = nil
local lastGroundArrowOffset = nil
local groundArrowOffsetWarned = false
local groundArrowOffsetTraceCount = 0
local MAX_GROUND_ARROW_OFFSET_TRACES = 24
local arrowProjectionStateReported = nil

local function safeText(value)
    if value == nil then return "UNAVAILABLE" end
    local ok, result = pcall(tostring, value)
    if not ok then return "UNAVAILABLE" end
    return result:gsub("[\r\n\t|;]", "_")
end

local function setNativeArrowProjectionEnabled(enabled)
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.setNativeForageEnabled) ~= "function" then return end
    local active = enabled == true
    pcall(bridge.setNativeForageEnabled, active)
    if arrowProjectionStateReported ~= active then
        local state = active and "enabled; integrated API available"
            or "inactive; integrated API unavailable, using native arrow"
        print(TAG .. "native arrow projection " .. state)
        arrowProjectionStateReported = active
    end
end

local function warnOnce(message)
    if warned then return end
    warned = true
    print(TAG .. message)
end

local function bindTuning()
    if binding then
        local apiAvailable = type(ViewpointForage) == "table"
            and type(ViewpointForage.found) == "function"
        Calibration.nativeIntegrated = apiAvailable
        local bridge = binding.bridge or ChilaSedaViewpointForageTuningJ
        Calibration.nativeGroundArrowOffsetAvailable = bridge ~= nil
            and type(bridge.setNativeGroundArrowOffset) == "function"
        setNativeArrowProjectionEnabled(apiAvailable)
        return binding
    end
    local bridge = ChilaSedaViewpointForageTuningJ
    if bridge then
        local availableOk, available = pcall(function()
            return bridge.isNativeTuningAvailable()
        end)
        if availableOk and available == true then
            local heightOk, height = pcall(function()
                return bridge.nativeFindPinHeightBase()
            end)
            local upOk, up = pcall(function()
                return bridge.nativeFindPinUpBase()
            end)
            if heightOk and upOk and type(height) == "number" and type(up) == "number" then
                binding = { bridge = bridge }
                basePinHeight = height
                basePinUp = up
                Calibration.nativeTuningAvailable = true
                Calibration.nativeGroundArrowOffsetAvailable =
                    type(bridge.setNativeGroundArrowOffset) == "function"
                local apiAvailable = type(ViewpointForage) == "table"
                    and type(ViewpointForage.found) == "function"
                Calibration.nativeIntegrated = apiAvailable
                Calibration.nativeTuningStatus = "ready; source=Java bridge"
                setNativeArrowProjectionEnabled(apiAvailable)
                print(TAG .. "connected through local Java tuning bridge; forage API "
                    .. (apiAvailable and "available" or "unavailable"))
                return binding
            end
        end
        local detail = "bridge did not expose native tuning fields"
        local statusOk, bridgeStatus = pcall(function() return bridge.nativeTuningStatus() end)
        if statusOk and bridgeStatus ~= nil then detail = safeText(bridgeStatus) end
        Calibration.nativeTuningAvailable = false
        Calibration.nativeTuningStatus = detail
        warnOnce("native tuning bridge unavailable: " .. detail)
    end
    if not luajava or type(luajava.bindClass) ~= "function" then
        Calibration.nativeTuningAvailable = false
        Calibration.nativeIntegrated = false
        Calibration.nativeTuningStatus = Calibration.nativeTuningStatus
            or "no local Java tuning bridge or luajava.bindClass"
        setNativeArrowProjectionEnabled(false)
        warnOnce("native tuning controls inactive: " .. safeText(Calibration.nativeTuningStatus))
        return nil
    end

    local ok, result = pcall(function()
        local JavaClass = luajava.bindClass("java.lang.Class")
        local tuning = JavaClass.forName("viewpoint.platform.Tuning")
        local pinHeight = tuning:getDeclaredField("findPinHeight")
        local pinUp = tuning:getDeclaredField("findPinUp")
        pinHeight:setAccessible(true)
        pinUp:setAccessible(true)
        return {
            pinHeight = pinHeight,
            pinUp = pinUp,
            basePinHeight = pinHeight:getFloat(nil),
            basePinUp = pinUp:getFloat(nil),
        }
    end)
    if not ok or not result then
        Calibration.nativeTuningAvailable = false
        Calibration.nativeTuningStatus = "luajava reflection failed: " .. safeText(result)
        warnOnce("native tuning controls inactive: " .. safeText(Calibration.nativeTuningStatus))
        return nil
    end

    binding = result
    basePinHeight = result.basePinHeight
    basePinUp = result.basePinUp
    Calibration.nativeTuningAvailable = true
    Calibration.nativeGroundArrowOffsetAvailable = false
    Calibration.nativeTuningStatus = "ready; source=luajava reflection"
    local apiAvailable = type(ViewpointForage) == "table"
        and type(ViewpointForage.found) == "function"
    Calibration.nativeIntegrated = apiAvailable
    setNativeArrowProjectionEnabled(apiAvailable)
    print(TAG .. "connected to Viewpoint native tuning fields; forage API "
        .. (apiAvailable and "available" or "unavailable"))
    return binding
end

Calibration.ensureNativeTuning = function()
    return bindTuning() ~= nil
end

local function playerPosition()
    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    if not player and type(getPlayer) == "function" then player = getPlayer() end
    if not player then return nil, nil end
    local ok, x, y = pcall(function() return player:getX(), player:getY() end)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil, nil end
    return x, y
end

local function applyCalibration()
    local tuning = bindTuning()
    if not tuning then return end

    local x, y = playerPosition()
    if not x then return end

    local offset = Calibration.getOffsetAt(x, y)
    local groundArrowOffset, arrowInfo = Calibration.getGroundArrowOffsetAt(x, y)
    local pinZoom, circleZoom, iconZoom = Calibration.getVisualAt(x, y)
    offset = type(offset) == "number" and offset or 0
    pinZoom = type(pinZoom) == "number" and pinZoom or 1
    circleZoom = type(circleZoom) == "number" and circleZoom or 1
    iconZoom = type(iconZoom) == "number" and iconZoom or 1
    groundArrowOffset = type(groundArrowOffset) == "number" and groundArrowOffset or 0
    local zoom = math.max(0.25, math.min(4.0, (pinZoom + circleZoom + iconZoom) / 3))
    local nextPinHeight = basePinHeight * zoom
    local nextPinUp = basePinUp + offset

    local ok, err = pcall(function()
        local heightChanged = lastPinHeight == nil
            or math.abs(nextPinHeight - lastPinHeight) > 0.0001
        local upChanged = lastPinUp == nil
            or math.abs(nextPinUp - lastPinUp) > 0.0001
        if tuning.bridge then
            if heightChanged or upChanged then
                local applied = tuning.bridge.setNativePinTuning(nextPinHeight, nextPinUp)
                if applied ~= true then
                    error(safeText(tuning.bridge.nativeTuningStatus()))
                end
                lastPinHeight = nextPinHeight
                lastPinUp = nextPinUp
            end
        else
            if heightChanged then
                tuning.pinHeight:setFloat(nil, nextPinHeight)
                lastPinHeight = nextPinHeight
            end
            if upChanged then
                tuning.pinUp:setFloat(nil, nextPinUp)
                lastPinUp = nextPinUp
            end
        end

        local arrowBridge = tuning.bridge or ChilaSedaViewpointForageTuningJ
        if arrowBridge and type(arrowBridge.setNativeGroundArrowOffset) == "function" then
            Calibration.nativeGroundArrowOffsetAvailable = true
            local arrowChanged = lastGroundArrowOffset == nil
                or math.abs(groundArrowOffset - lastGroundArrowOffset) > 0.0001
            if arrowChanged then
                local applied = arrowBridge.setNativeGroundArrowOffset(groundArrowOffset)
                if applied == true then
                    lastGroundArrowOffset = groundArrowOffset
                    if groundArrowOffsetTraceCount < MAX_GROUND_ARROW_OFFSET_TRACES then
                        groundArrowOffsetTraceCount = groundArrowOffsetTraceCount + 1
                        local source = arrowInfo and arrowInfo.kind or "default"
                        local samples = arrowInfo and arrowInfo.sampleCount or 0
                        print(TAG .. "ground-arrow-offset=" .. string.format("%+.3f", groundArrowOffset)
                            .. " source=" .. safeText(source) .. " samples=" .. tostring(samples))
                    end
                elseif not groundArrowOffsetWarned then
                    groundArrowOffsetWarned = true
                    print(TAG .. "ground-arrow-offset write rejected value="
                        .. string.format("%+.3f", groundArrowOffset))
                end
            end
        else
            Calibration.nativeGroundArrowOffsetAvailable = false
            if not groundArrowOffsetWarned then
                groundArrowOffsetWarned = true
                print(TAG .. "ground-arrow-offset unavailable: Java bridge setter missing")
            end
        end
    end)
    if not ok then warnOnce("could not apply native pin calibration: " .. tostring(err)) end
end

if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(applyCalibration)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(applyCalibration)
end
if Events and Events.OnTickEvenPaused and type(Events.OnTickEvenPaused.Add) == "function" then
    Events.OnTickEvenPaused.Add(applyCalibration)
end

applyCalibration()
