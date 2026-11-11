local okMagnifier, magnifier = pcall(require, "errorMagnifier_Main")
if not okMagnifier or type(magnifier) ~= "table"
        or type(magnifier.parseErrors) ~= "function"
        or type(magnifier.parsedErrors) ~= "table"
        or type(magnifier.parsedErrorsKeyed) ~= "table"
        or type(magnifier.getZomboidSettingsHeader) ~= "function" then
    print("[ChilaSeda Error Logs] Error Magnifier unavailable; session exporter skipped")
    return
end
if magnifier._ChilaSedaSessionLogs then return end

local M = {pending = {}, order = {}, seen = {}, ready = false, busy = false, inGame = false,
    nextPoll = 0, nextWarning = 0, enabled = true}
magnifier._ChilaSedaSessionLogs = M

local function warn(message)
    local now = getTimestampMs()
    if now >= M.nextWarning then
        print("[ChilaSeda Error Logs] " .. tostring(message))
        M.nextWarning = now + 30000
    end
end

local function observe()
    if M.sourceTable ~= magnifier.parsedErrors then
        M.sourceTable = magnifier.parsedErrors
        M.seen = {}
    end
    for _, text in ipairs(magnifier.parsedErrorsKeyed) do
        local count = magnifier.parsedErrors[text] or 0
        local delta = count - (M.seen[text] or 0)
        if delta > 0 then
            if not M.pending[text] then
                M.pending[text] = 0
                M.order[#M.order + 1] = text
            end
            M.pending[text] = M.pending[text] + delta
        end
        M.seen[text] = count
    end
end

local function drain()
    if #M.order == 0 then return end
    for _, text in ipairs(M.order) do
        local count = M.pending[text]
        if count and not ChilaErrorLogJ.record(text, string.format("%.0f", count)) then
            error("record failed: " .. tostring(ChilaErrorLogJ.lastError()))
        end
    end
    M.pending, M.order = {}, {}
end

local function update()
    if not M.enabled or M.busy or not M.inGame then return end
    local now = getTimestampMs()
    if now < M.nextPoll then return end
    M.nextPoll = now + 1000
    M.busy = true
    local ok, failure = pcall(function()
        observe()
        if not ChilaErrorLogJ then
            warn("Waiting for ZombieBuddy Java bridge")
            return
        end
        if not M.ready then
            local path = ChilaErrorLogJ.beginGame(magnifier.getZomboidSettingsHeader())
            if not path or path == "" then
                warn("Cannot start: " .. tostring(ChilaErrorLogJ.lastError()))
                return
            end
            M.ready = true
            print("[ChilaSeda Error Logs] Loaded v1.0.0; session=" .. tostring(path))
        end
        drain()
        if not ChilaErrorLogJ.flush() then
            warn("Write pending, will retry: " .. tostring(ChilaErrorLogJ.lastError()))
        end
    end)
    M.busy = false
    if not ok then
        M.enabled = false -- Avoid an exporter exception creating an error storm.
        warn("Exporter stopped: " .. tostring(failure))
    end
end

local originalParse = magnifier.parseErrors
magnifier.parseErrors = function(...)
    local result = originalParse(...)
    if M.enabled and not M.busy then
        M.busy = true
        local ok, failure = pcall(observe)
        M.busy = false
        if not ok then
            M.enabled = false
            warn("Observer stopped: " .. tostring(failure))
        end
    end
    return result
end

-- The same callbacks used by Error Magnifier cover the menu and paused gameplay.
Events.OnTickEvenPaused.Add(update)
Events.OnFETick.Add(update)
Events.OnGameStart.Add(function()
    M.inGame = true
    M.ready = false
    M.nextPoll = 0
    update()
end)
Events.OnMainMenuEnter.Add(function()
    local wasReady = M.ready
    M.inGame, M.ready = false, false
    if wasReady then
        local ok, failure = pcall(function()
            observe()
            drain()
            if not ChilaErrorLogJ.endGame() then
                warn("Write pending: " .. tostring(ChilaErrorLogJ.lastError()))
            end
        end)
        if not ok then
            M.enabled = false
            warn("Exporter stopped: " .. tostring(failure))
        end
    end
end)
observe()
