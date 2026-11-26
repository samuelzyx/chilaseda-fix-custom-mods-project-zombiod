-- Bounded, read-only diagnostics for reports of an oversized HUD during a storm.
local PREFIX = "[Anomalous Storm HUD Trace]"
local MOD_DATA_KEY = "AnomalousStorm"
local POLL_INTERVAL_MS = 1000
local SAMPLE_INTERVAL_MS = 15000
local MAX_SAMPLES = 120
local MAX_CHANGES = 80

local METRIC_ORDER = {
    "gameHours", "phase", "warning", "active", "rain", "thunder",
    "screenW", "screenH", "coreW", "coreH", "uiScale", "fontSize",
    "zoomAllowed", "cameraZoom", "cameraW", "cameraH", "offscreenW",
    "offscreenH", "viewFirst", "viewThird", "viewEnabled", "overlayW",
    "overlayH", "overlayAlpha",
}
local CHANGE_ORDER = {
    "phase", "warning", "active", "rain", "thunder", "screenW", "screenH",
    "coreW", "coreH", "uiScale", "fontSize", "zoomAllowed", "cameraZoom",
    "cameraW", "cameraH", "offscreenW", "offscreenH", "viewFirst", "viewThird",
    "viewEnabled", "overlayW", "overlayH",
}

local boundClasses = {}
local fallbackLogged = {}
local javaBindingUnavailable = false
local trace = {
    cycleKey = nil,
    lastPollMs = 0,
    lastPeriodicMs = 0,
    lastFingerprint = nil,
    sampleCount = 0,
    changeCount = 0,
    sampleLimitLogged = false,
    changeLimitLogged = false,
}

local function atom(value)
    if value == nil then return "na" end
    local text = tostring(value)
    return (text:gsub("[%s]+", "_"))
end

local function logEvent(eventName, fields)
    local suffix = fields and fields ~= "" and (" " .. fields) or ""
    print(PREFIX .. " event=" .. eventName .. suffix)
end

local function logFallback(name, reason)
    if fallbackLogged[name] then return end
    fallbackLogged[name] = true
    logEvent("fallback", "api=" .. atom(name) .. " reason=" .. atom(reason))
end

local function readMetric(name, callback)
    local ok, value = pcall(callback)
    if not ok then
        logFallback(name, value)
        return nil
    end
    if value == nil then logFallback(name, "unavailable") end
    return value
end

local function bindClass(name, key)
    if boundClasses[key] then return boundClasses[key] end
    if javaBindingUnavailable then return nil end
    if not luajava or type(luajava.bindClass) ~= "function" then
        javaBindingUnavailable = true
        logFallback("luajava.bindClass", "unavailable")
        return nil
    end
    local class = readMetric("class." .. key, function()
        return luajava.bindClass(name)
    end)
    if class then boundClasses[key] = class end
    return class
end

local function cycleKey(state)
    if state.DebugOverride == true then
        return "debug:" .. atom(state.DebugRunId or state.DebugStartedAt)
    end
    if state.StormAt ~= nil then return "scheduled:" .. atom(state.StormAt) end
    if state.DebugRunId ~= nil then return "debug:" .. atom(state.DebugRunId) end
    return "phase:" .. atom(state.Phase)
end

local function stormIsVisible(state, overlay)
    if state and (state.Warning == true or state.Active == true
        or state.RainActive == true or state.Thunder == true) then
        return true
    end
    return overlay ~= nil and (tonumber(overlay.a) or 0) > 0
end

local function snapshot(state)
    local metrics = {
        phase = state and state.Phase,
        warning = state and state.Warning,
        active = state and state.Active,
        rain = state and state.RainActive,
        thunder = state and state.Thunder,
    }

    local gameTime = readMetric("gameTime", function() return getGameTime() end)
    if gameTime then
        metrics.gameHours = readMetric("gameTime.worldAgeHours", function()
            return gameTime:getWorldAgeHours()
        end)
    end

    local core = readMetric("core", function() return getCore() end)
    if core then
        metrics.screenW = readMetric("core.screenWidth", function() return core:getScreenWidth() end)
        metrics.screenH = readMetric("core.screenHeight", function() return core:getScreenHeight() end)
        metrics.fontSize = readMetric("core.fontSizeReal", function() return core:getOptionFontSizeReal() end)
        metrics.zoomAllowed = readMetric("core.zoomAllowed", function() return core:getOptionZoom() end)
    end

    local coreClass = bindClass("zombie.core.Core", "core")
    if coreClass then
        metrics.uiScale = readMetric("core.scale", function() return coreClass.scale end)
        metrics.coreW = readMetric("core.width", function() return coreClass.width end)
        metrics.coreH = readMetric("core.height", function() return coreClass.height end)
    end

    local cameraClass = bindClass("zombie.iso.IsoCamera", "camera")
    local frame = cameraClass and readMetric("camera.frameState", function() return cameraClass.frameState end)
    if frame then
        metrics.cameraZoom = readMetric("camera.zoom", function() return frame.zoom end)
        metrics.offscreenW = readMetric("camera.offscreenWidth", function() return frame.offscreenWidth end)
        metrics.offscreenH = readMetric("camera.offscreenHeight", function() return frame.offscreenHeight end)
        local cameras = cameraClass.cameras
        if cameras then
            local playerCamera = readMetric("camera.player0", function() return cameras[0] end)
            if playerCamera then
                metrics.cameraW = readMetric("camera.player0.width", function() return playerCamera.width end)
                metrics.cameraH = readMetric("camera.player0.height", function() return playerCamera.height end)
            end
        end
    end

    if VTWJ and VTWJ.getState then
        local viewState = {}
        local ok, available = pcall(VTWJ.getState, viewState)
        if ok and available ~= false then
            metrics.viewFirst = viewState.firstPerson == true
            metrics.viewThird = viewState.thirdPerson == true
            metrics.viewEnabled = viewState.view == true
        else
            logFallback("viewpoint.getState", ok and "unavailable" or available)
        end
    else
        logFallback("viewpoint.getState", "unavailable")
    end

    local overlayClass = ChilaSeda_AnomalousStorm_Rect
    local overlay = overlayClass and overlayClass.instance
    if overlay then
        metrics.overlayW = readMetric("overlay.width", function() return overlay.width end)
        metrics.overlayH = readMetric("overlay.height", function() return overlay.height end)
        metrics.overlayAlpha = readMetric("overlay.alpha", function() return overlay.a end)
    else
        metrics.overlayAlpha = 0
    end

    return metrics
end

local function serializeMetrics(metrics)
    local fields = {}
    local fingerprint = {}
    for _, name in ipairs(METRIC_ORDER) do
        local value = atom(metrics[name])
        fields[#fields + 1] = name .. "=" .. value
    end
    for _, name in ipairs(CHANGE_ORDER) do fingerprint[#fingerprint + 1] = atom(metrics[name]) end
    return table.concat(fields, " "), table.concat(fingerprint, "|")
end

local function resetCycle(key)
    trace.cycleKey = key
    trace.lastPeriodicMs = 0
    trace.lastFingerprint = nil
    trace.sampleCount = 0
    trace.changeCount = 0
    trace.sampleLimitLogged = false
    trace.changeLimitLogged = false
    logEvent("cycle-start", "cycle=" .. atom(key))
end

local function onPlayerUpdate()
    local state = ModData and ModData.get and ModData.get(MOD_DATA_KEY) or nil
    local overlayClass = ChilaSeda_AnomalousStorm_Rect
    local overlay = overlayClass and overlayClass.instance
    if not stormIsVisible(state, overlay) then
        if trace.cycleKey then logEvent("cycle-end", "cycle=" .. atom(trace.cycleKey)) end
        trace.cycleKey = nil
        trace.lastFingerprint = nil
        return
    end

    local key = cycleKey(state or {})
    if trace.cycleKey ~= key then resetCycle(key) end

    local nowMs = readMetric("clock.timestampMs", function() return getTimestampMs() end)
    nowMs = tonumber(nowMs) or 0
    if trace.lastPollMs ~= 0 and nowMs - trace.lastPollMs < POLL_INTERVAL_MS then return end
    trace.lastPollMs = nowMs

    local metrics = snapshot(state)
    local fields, fingerprint = serializeMetrics(metrics)
    local changed = trace.lastFingerprint ~= nil and fingerprint ~= trace.lastFingerprint
    if trace.lastFingerprint == nil then
        trace.sampleCount = 1
        trace.lastPeriodicMs = nowMs
        logEvent("sample", fields)
    elseif changed and trace.changeCount < MAX_CHANGES then
        trace.changeCount = trace.changeCount + 1
        logEvent("metrics-change", "change=" .. tostring(trace.changeCount) .. " " .. fields)
    elseif changed and not trace.changeLimitLogged then
        trace.changeLimitLogged = true
        logEvent("change-limit", "max=" .. tostring(MAX_CHANGES))
    elseif nowMs - trace.lastPeriodicMs >= SAMPLE_INTERVAL_MS then
        if trace.sampleCount < MAX_SAMPLES then
            trace.sampleCount = trace.sampleCount + 1
            trace.lastPeriodicMs = nowMs
            logEvent("sample", "index=" .. tostring(trace.sampleCount) .. " " .. fields)
        elseif not trace.sampleLimitLogged then
            trace.sampleLimitLogged = true
            logEvent("sample-limit", "max=" .. tostring(MAX_SAMPLES) .. " periodicMs=" .. tostring(SAMPLE_INTERVAL_MS))
        end
    end
    trace.lastFingerprint = fingerprint
end

if Events and Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
    logEvent("loaded", "pollMs=" .. tostring(POLL_INTERVAL_MS)
        .. " sampleMs=" .. tostring(SAMPLE_INTERVAL_MS)
        .. " maxSamples=" .. tostring(MAX_SAMPLES)
        .. " maxChanges=" .. tostring(MAX_CHANGES))
else
    logEvent("fallback", "api=Events.OnPlayerUpdate reason=unavailable")
end
