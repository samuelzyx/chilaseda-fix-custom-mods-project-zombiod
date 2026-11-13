local M = {pending = {}, order = {}, seen = {}, ready = false, busy = false, inGame = false,
    nextPoll = 0, nextWarning = 0, enabled = true}
local magnifier

local function warn(message)
    local now = getTimestampMs()
    if now >= M.nextWarning then
        print("[ChilaSeda Error Logs] " .. tostring(message))
        M.nextWarning = now + 30000
    end
end

local function observe()
    if not magnifier then return end
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

local function installMagnifier()
    if magnifier then return true end
    local ok, candidate = pcall(require, "errorMagnifier_Main")
    if not ok or type(candidate) ~= "table"
            or type(candidate.parseErrors) ~= "function"
            or type(candidate.parsedErrors) ~= "table"
            or type(candidate.parsedErrorsKeyed) ~= "table"
            or type(candidate.getZomboidSettingsHeader) ~= "function" then
        return false
    end

    local existing = candidate._ChilaSedaSessionLogs
    if type(existing) == "table" and existing ~= M then
        M = existing
        magnifier = candidate
        return true
    end

    magnifier = candidate
    candidate._ChilaSedaSessionLogs = M
    local originalParse = candidate.parseErrors
    candidate.parseErrors = function(...)
        local result = originalParse(...)
        if M.enabled and not M.busy then
            M.busy = true
            local parsed, failure = pcall(observe)
            M.busy = false
            if not parsed then
                M.enabled = false
                warn("Observer stopped: " .. tostring(failure))
            end
        end
        return result
    end
    observe()
    return true
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
    if not M.enabled or M.busy then return end
    local now = getTimestampMs()
    if now < M.nextPoll then return end
    M.nextPoll = now + 1000
    M.busy = true
    local ok, failure = pcall(function()
        local available = installMagnifier()
        if not M.inGame then return end
        if not available then
            warn("Waiting for Error Magnifier API")
            return
        end
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
            print("[ChilaSeda Error Logs] Loaded v1.0.1; session=" .. tostring(path))
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

-- Keep trying in the menu and after entering a save; the optional API may not
-- have finished loading when this file is first evaluated.
installMagnifier()
Events.OnTickEvenPaused.Add(update)
Events.OnFETick.Add(update)
Events.OnGameStart.Add(function()
    M.inGame = true
    M.ready = false
    M.nextPoll = 0
    M.nextWarning = 0
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
