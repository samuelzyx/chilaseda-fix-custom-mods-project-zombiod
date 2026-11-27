require "LootTracker/LT_Core"

LootTracker = LootTracker or {}
local LT = LootTracker
local TARGET_KEY = "IGUI_LootTracker_MyCar_LeftDays"
local MAX_TRACE_LINES = 8
local traceLines = 0

if LT.TRACE_FORMAT_GUARD == nil then
    LT.TRACE_FORMAT_GUARD = true
end

local function trace(event, detail)
    if LT.TRACE_FORMAT_GUARD ~= true or traceLines >= MAX_TRACE_LINES then return end
    if type(print) ~= "function" then return end
    traceLines = traceLines + 1
    print("[ChilaSeda_LootTrackerFormatGuard] event=" .. tostring(event)
        .. (detail and (" detail=" .. tostring(detail)) or ""))
end

if LT.__ChilaSedaLeftDaysFormatGuardInstalled then
    trace("install", "already-installed")
    return
end

if type(LT.text) ~= "function" then
    trace("install", "fallback-text-api-unavailable")
    return
end

local originalText = LT.text
local resolvedText = nil

LT.text = function(key, fallback)
    if key ~= TARGET_KEY then
        return originalText(key, fallback)
    end

    if resolvedText ~= nil then return resolvedText end

    local translated = nil
    if type(getTextOrNull) == "function" then
        -- The B42 Translator formats %1 immediately. Supplying the placeholder as its
        -- argument preserves Loot Tracker's own later %1 replacement without a warning.
        local ok, value = pcall(getTextOrNull, key, "%1")
        if ok and type(value) == "string" and value ~= "" and value ~= key then
            translated = string.gsub(value, "%%(%d)%$s", "%%%1")
        end
    end

    if translated == nil or translated == "" then
        resolvedText = fallback or key
        trace("resolve", "fallback")
    else
        resolvedText = translated
        trace("resolve", "translated")
    end
    return resolvedText
end

LT.__ChilaSedaLeftDaysFormatGuardInstalled = true
trace("install", "installed")
