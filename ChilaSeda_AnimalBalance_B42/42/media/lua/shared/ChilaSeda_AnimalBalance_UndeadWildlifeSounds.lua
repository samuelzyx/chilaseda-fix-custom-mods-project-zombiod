-- Make hostile Undead Wildlife animals vocalize more often without changing
-- their sound events, volume, or world-sound radius.
local loaded, loadError = pcall(function()
    require "UndeadWildlife_Core"
    require "Definitions/animal/UndeadWildlife_Definitions"
end)
if not loaded or type(UndeadWildlife) ~= "table" then
    if not loaded then
        print("[ChilaSeda_AnimalBalance] Undead Wildlife sound frequency patch inactive: " .. tostring(loadError))
    end
    return
end

local FREQUENCY_INTERVAL_SCALE = 0.5
local VOICE_SLOTS = { "idle", "idle_walk", "idle_fly", "stressed" }

local function shortenInterval(soundEntry)
    if type(soundEntry) ~= "table" then return false end

    local intervalMin = tonumber(soundEntry.intervalMin)
    local intervalMax = tonumber(soundEntry.intervalMax)
    if not intervalMin or not intervalMax or intervalMin <= 0 or intervalMax <= 0 then
        return false
    end

    local newMin = math.max(1, math.floor(intervalMin * FREQUENCY_INTERVAL_SCALE))
    local newMax = math.max(newMin, math.floor(intervalMax * FREQUENCY_INTERVAL_SCALE))
    if newMin == intervalMin and newMax == intervalMax then return false end

    soundEntry.intervalMin = newMin
    soundEntry.intervalMax = newMax
    return true
end

local function tuneUndeadWildlifeSounds()
    local wildlife = UndeadWildlife
    local definitions = AnimalDefinitions and AnimalDefinitions.animals
    if type(wildlife.HostileTypes) ~= "table" or type(definitions) ~= "table" then
        print("[ChilaSeda_AnimalBalance] Undead Wildlife sound frequency patch skipped: animal definitions unavailable")
        return
    end

    local adjustedTypes = 0
    local adjustedSlots = 0
    for animalType in pairs(wildlife.HostileTypes) do
        local definition = definitions[animalType]
        local typeAdjusted = false
        if definition and type(definition.breeds) == "table" then
            for _, breed in pairs(definition.breeds) do
                local sounds = breed and breed.sounds
                if type(sounds) == "table" then
                    for _, slotName in ipairs(VOICE_SLOTS) do
                        if shortenInterval(sounds[slotName]) then
                            adjustedSlots = adjustedSlots + 1
                            typeAdjusted = true
                        end
                    end
                end
            end
        end
        if typeAdjusted then adjustedTypes = adjustedTypes + 1 end
    end

    print("[ChilaSeda_AnimalBalance] Undead Wildlife ambient/stressed voice intervals halved for "
        .. tostring(adjustedSlots) .. " sound slots across " .. tostring(adjustedTypes)
        .. " hostile animal types; volume and radius unchanged")
end

-- Undead Wildlife registers its hostile AnimalDefinitions in its own
-- OnGameBoot callback. This mod loads after it, so tune the finished copies.
Events.OnGameBoot.Add(tuneUndeadWildlifeSounds)
