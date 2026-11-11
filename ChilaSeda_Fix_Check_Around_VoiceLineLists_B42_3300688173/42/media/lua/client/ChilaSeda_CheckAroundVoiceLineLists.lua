local CheckAround = require "CheckAround_module"
local WorldTools = require "DoggyTools/WorldTools"
require "CheckAroundTimedActions/ISCheckBehindObject"

if not CheckAround or not ISCheckBehindObject or not WorldTools then
    print("[ChilaSeda CheckAroundVoiceLineLists] Dependencies unavailable; patch skipped")
    return
end

local function listShape(value)
    local valueType = type(value)
    if valueType ~= "table" then return valueType .. ":not-table" end
    local ok, length = pcall(function() return #value end)
    if not ok then return "table:length-error=" .. tostring(length) end
    return "table:length=" .. tostring(length)
end

local function usableList(value)
    if type(value) ~= "table" then return false end
    local ok, length = pcall(function() return #value end)
    return ok and length > 0
end

local function objectClass(object)
    if not object then return "nil" end
    local ok, class = pcall(function() return object:getClass() end)
    if ok and class then return tostring(class) end
    return type(object)
end

local function predicate(name, object)
    local method = WorldTools[name]
    if type(method) ~= "function" then return "unavailable" end
    local ok, value = pcall(method, object)
    if not ok then return "error:" .. tostring(value) end
    return tostring(value == true)
end

local function diagnostic(stage, action, note)
    local object = action and action.object
    print(string.format(
        "[ChilaSeda CheckAroundVoiceLineLists] %s class=%s door=%s window=%s noZombies=%s zombies=%s %s",
        tostring(stage), objectClass(object), predicate("IsDoor", object), predicate("IsWindow", object),
        listShape(action and action.voiceLine_noZombies), listShape(action and action.voiceLine_zombies),
        tostring(note or "")
    ))
end

local function restoreListsForRecognizedObject(action)
    local object = action.object
    local fallback

    if predicate("IsDoor", object) == "true" then
        if not usableList(action.voiceLine_noZombies) then
            action.voiceLine_noZombies = CheckAround.Voicelines_BehindDoorNoZombies
            fallback = "door-no-zombies"
        end
        if not usableList(action.voiceLine_zombies) then
            action.voiceLine_zombies = CheckAround.Voicelines_zombiesBehindDoor
            fallback = (fallback and fallback .. "," or "") .. "door-zombies"
        end
    elseif predicate("IsWindow", object) == "true" then
        if not usableList(action.voiceLine_noZombies) then
            action.voiceLine_noZombies = CheckAround.Voicelines_BehindWindowsNoZombies
            fallback = "window-no-zombies"
        end
        if not usableList(action.voiceLine_zombies) then
            action.voiceLine_zombies = CheckAround.Voicelines_zombiesBehindWindow
            fallback = (fallback and fallback .. "," or "") .. "window-zombies"
        end
    end

    return fallback
end

local originalSetVoicelines = ISCheckBehindObject.setVoicelines
if type(originalSetVoicelines) == "function" then
    ISCheckBehindObject.setVoicelines = function(self, ...)
        local result = originalSetVoicelines(self, ...)
        if not usableList(self.voiceLine_noZombies) or not usableList(self.voiceLine_zombies) then
            local fallback = restoreListsForRecognizedObject(self)
            diagnostic("setVoicelines", self, "fallback=" .. tostring(fallback or "none"))
        end
        return result
    end
end

local originalApplyVoiceline = CheckAround.ApplyVoiceline
if type(originalApplyVoiceline) == "function" then
    CheckAround.ApplyVoiceline = function(player, zombiesAmount, noZombieLines, zombieLines, ...)
        local selected = zombiesAmount > 0 and zombieLines or noZombieLines
        if not usableList(selected) then
            print(string.format(
                "[ChilaSeda CheckAroundVoiceLineLists] ApplyVoiceline skipped zombies=%s selected=%s noZombies=%s zombies=%s",
                tostring(zombiesAmount), listShape(selected), listShape(noZombieLines), listShape(zombieLines)
            ))
            return false
        end
        return originalApplyVoiceline(player, zombiesAmount, noZombieLines, zombieLines, ...)
    end
end

local originalPerform = ISCheckBehindObject.perform
if type(originalPerform) == "function" then
    ISCheckBehindObject.perform = function(self, ...)
        diagnostic("perform-before", self, "voiceLine lists before fallback")
        if not usableList(self.voiceLine_noZombies) or not usableList(self.voiceLine_zombies) then
            local fallback = restoreListsForRecognizedObject(self)
            diagnostic("perform-repair", self, "fallback=" .. tostring(fallback or "none"))
        end
        return originalPerform(self, ...)
    end
end

print("[ChilaSeda CheckAroundVoiceLineLists] Loaded v0.1.1")
