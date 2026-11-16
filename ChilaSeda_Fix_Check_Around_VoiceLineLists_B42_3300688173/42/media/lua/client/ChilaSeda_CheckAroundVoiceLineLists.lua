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

-- Check Around still calls the pre-B42.22 character:HasTrait("name") API in
-- rollCreek. Build 42.22 exposes hasTrait(CharacterTrait) instead; the nil
-- method call aborts start() before its beam is initialized, causing the later
-- setDirection errors. Keep the mod's sound chance calculation with both APIs.
local function hasTrait(character, legacyName, trait)
    if not character then return false end
    if character.hasTrait and trait then
        local ok, result = pcall(character.hasTrait, character, trait)
        if ok then return result == true end
    end
    if character.HasTrait then
        local ok, result = pcall(character.HasTrait, character, legacyName)
        if ok then return result == true end
    end
    return false
end

ISCheckBehindObject.rollCreek = function(self, object)
    local character = self and self.character
    if not character or not object then return end

    local lightfoot = character:getPerkLevel(Perks.Lightfoot)
    local nimble = character:getPerkLevel(Perks.Nimble)
    local sneak = character:getPerkLevel(Perks.Sneak)
    local traits = CharacterTrait
    local graceful = hasTrait(character, "Graceful", traits and traits.GRACEFUL) and 10 or 0
    local inconspicuous = hasTrait(character, "Inconspicuous", traits and traits.INCONSPICUOUS) and 10 or 0
    local conspicuous = hasTrait(character, "Conspicuous", traits and traits.CONSPICUOUS) and 10 or 0
    local clumsy = hasTrait(character, "Clumsy", traits and traits.CLUMSY) and 10 or 0
    local crouching = character:isSneaking() and 20 or 0

    local stats = character:getStats()
    local panic = stats:getPanic() / 2
    local stress = stats:getStress() * 100 / 2
    local pain = stats:getPain() / 2
    local doorHealth = object:getHealth() / object:getMaxHealth() * 100
    local successChance = doorHealth + lightfoot + nimble + sneak + graceful + inconspicuous
        + crouching - conspicuous - clumsy - panic - stress - pain

    if successChance < GENERAL_RANDOM:random(0, 100) then
        local square = object:getSquare()
        getWorld():getFreeEmitter():playSoundImpl("DoorCreek", square)
        local radius = SandboxVars.CheckAround.Radius + 1
        addSound(nil, square:getX(), square:getY(), square:getZ(), radius, radius)
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
