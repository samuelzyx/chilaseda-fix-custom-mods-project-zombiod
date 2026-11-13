local Calibration = require "ChilaSeda_ViewpointNativeForageHeightCalibration"
local TAG = "[ChilaSeda_ViewpointNativeForageCalibration] "

local binding = nil
local warned = false
local basePinHeight = nil
local basePinUp = nil
local lastPinHeight = nil
local lastPinUp = nil
local arrowProjectionStateReported = false

local function setNativeArrowProjectionEnabled(enabled)
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.setNativeForageEnabled) ~= "function" then return end
    local active = enabled == true
    pcall(bridge.setNativeForageEnabled, active)
    if not arrowProjectionStateReported then
        arrowProjectionStateReported = true
        local state = active and "enabled; integrated API available"
            or "inactive; integrated API unavailable, using native arrow"
        print(TAG .. "native arrow projection " .. state)
    end
end

local function warnOnce(message)
    if warned then return end
    warned = true
    print(TAG .. message)
end

local function bindTuning()
    if binding then return binding end
    if type(ViewpointForage) ~= "table" or type(ViewpointForage.found) ~= "function"
            or not luajava or type(luajava.bindClass) ~= "function" then
        setNativeArrowProjectionEnabled(false)
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
        warnOnce("Viewpoint native tuning is unavailable; calibration controls are inactive")
        return nil
    end

    binding = result
    basePinHeight = result.basePinHeight
    basePinUp = result.basePinUp
    setNativeArrowProjectionEnabled(true)
    Calibration.nativeIntegrated = true
    print(TAG .. "connected to Viewpoint native foraging pins")
    return binding
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
    local pinZoom, circleZoom, iconZoom = Calibration.getVisualAt(x, y)
    offset = type(offset) == "number" and offset or 0
    pinZoom = type(pinZoom) == "number" and pinZoom or 1
    circleZoom = type(circleZoom) == "number" and circleZoom or 1
    iconZoom = type(iconZoom) == "number" and iconZoom or 1
    local zoom = math.max(0.25, math.min(4.0, (pinZoom + circleZoom + iconZoom) / 3))
    local nextPinHeight = basePinHeight * zoom
    local nextPinUp = basePinUp + offset

    local ok, err = pcall(function()
        if lastPinHeight == nil or math.abs(nextPinHeight - lastPinHeight) > 0.0001 then
            tuning.pinHeight:setFloat(nil, nextPinHeight)
            lastPinHeight = nextPinHeight
        end
        if lastPinUp == nil or math.abs(nextPinUp - lastPinUp) > 0.0001 then
            tuning.pinUp:setFloat(nil, nextPinUp)
            lastPinUp = nextPinUp
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
