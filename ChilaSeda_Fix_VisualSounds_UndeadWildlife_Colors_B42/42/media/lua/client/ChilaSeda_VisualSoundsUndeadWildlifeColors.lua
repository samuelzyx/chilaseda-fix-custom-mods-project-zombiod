-- Integrate Undead Wildlife with VisualSounds KA's actual SDI renderer.
-- The Workshop API has no VisualSoundsKA global; it exposes the SDI class.

require "SoundDirectionIndicatorMain"

local TAG = "[ChilaSeda_VisualSoundsUWColors] "
local SDI = SDI
if not SDI or type(SDI.HandleWorldSound) ~= "function" or type(SDI.render) ~= "function" then
    print(TAG .. "SDI API unavailable; patch skipped")
    return
end

local zombieAnimals = {
    infectedraccoon = true,
    infectedcockerel = true,
    infectedchicken = true,
    infectedturkey = true,
    infectedrabbit = true,
    infectedpiglet = true,
    infectedfarmpig = true,
    infecteddeerdoe = true,
    infecteddeerstag = true,
    infectedcow = true,
    infectedcowcalf = true,
    infectedbull = true,
    infectedewe = true,
    infectedram = true,
    infectedlamb = true,
    infectedrat = true,
}

-- Match the distance bands in VisualSoundsKA's SDI renderer.
local cueTextures = {
    "ChilaSeda_UW_ZombieCue_1", "ChilaSeda_UW_ZombieCue_2",
    "ChilaSeda_UW_ZombieCue_3", "ChilaSeda_UW_ZombieCue_4",
    "ChilaSeda_UW_ZombieCue_5", "ChilaSeda_UW_ZombieCue_6",
    "ChilaSeda_UW_ZombieCue_7", "ChilaSeda_UW_ZombieCue_8",
}
local normalCueTextures = {
    "ChilaSeda_UW_NormalCue_1", "ChilaSeda_UW_NormalCue_2",
    "ChilaSeda_UW_NormalCue_3", "ChilaSeda_UW_NormalCue_4",
    "ChilaSeda_UW_NormalCue_5", "ChilaSeda_UW_NormalCue_6",
    "ChilaSeda_UW_NormalCue_7", "ChilaSeda_UW_NormalCue_8",
}
local zombieCuePalette
local normalCuePalette

local function loadPalette(names)
    local textures = {}
    for index, name in ipairs(names) do
        textures[index] = getTexture("media/textures/" .. name .. ".png")
        if not textures[index] then return nil end
    end
    return textures
end

local function getZombieCuePalette()
    if not zombieCuePalette then zombieCuePalette = loadPalette(cueTextures) end
    return zombieCuePalette
end

local function getNormalCuePalette()
    if not normalCuePalette then normalCuePalette = loadPalette(normalCueTextures) end
    return normalCuePalette
end

local function animalType(source)
    if not source or type(source.getAnimalType) ~= "function" then return nil end
    local ok, value = pcall(function() return source:getAnimalType() end)
    if ok and type(value) == "string" then
        value = string.lower(value):match("([^%.:]+)$") or string.lower(value)
        return value
    end
    return nil
end

local function isZombieAnimal(source)
    local kind = animalType(source)
    if not kind then return false end
    -- Some Undead Wildlife variants use the `undead*` skeleton definitions,
    -- not one of the sixteen `infected*` herd types listed above.
    return zombieAnimals[kind] == true
        or string.sub(kind, 1, 8) == "infected"
        or string.sub(kind, 1, 6) == "undead"
end

local originalHandleWorldSound = SDI.HandleWorldSound
local function addZombieAnimalCue(self, x, y, z, radius, volume, source)
    if not SDIGetOption or not SDIGetOption("SDIEnabled") then return end
    local player = self.playerObj or getSpecificPlayer(0)
    if not player or not source then return end
    local maxCues = tonumber(SDIGetOption("MAXVISUALCUES"))
    if maxCues and #self.sounds > maxCues then return end

    local adjustedRadius = tonumber(radius) or 0
    if CharacterTrait and CharacterTrait.DEAF and player:hasTrait(CharacterTrait.DEAF) then
        adjustedRadius = 0
    elseif CharacterTrait and CharacterTrait.KEEN_HEARING and player:hasTrait(CharacterTrait.KEEN_HEARING) then
        adjustedRadius = adjustedRadius * 1.2
    elseif CharacterTrait and CharacterTrait.HARD_OF_HEARING and player:hasTrait(CharacterTrait.HARD_OF_HEARING) then
        adjustedRadius = adjustedRadius * 0.8
    end

    local distance = IsoUtils.DistanceTo(player:getX(), player:getY(), x, y)
    if distance >= adjustedRadius then return end
    if source == player then return end
    if SDIGetOption("ONLYINSEARCHMODE") then
        local manager = ISSearchManager and ISSearchManager.getManager(player)
        if not manager or not manager.isSearchMode then return end
    end
    if SDIGetOption("ONLYCROUCHED") and not player:isSneaking() then return end

    for _, sound in ipairs(self.sounds) do
        if sound.objsource == source then
            sound.typesound = "ZOMBIES"
            sound.loud = true
            return
        end
    end

    self:setDistance(distance)
    self:setAngleFromPoint(x, y)
    self:setDuration(100)
    self:setVisible(true)
    table.insert(self.sounds, {
        x = x, y = y, z = z, radius = adjustedRadius, volume = volume,
        typesound = "ZOMBIES", emissionTime = os.time(), objsource = source,
        zombieState = nil, loud = true,
    })
end

local function isAnimalSource(source)
    if not source or type(instanceof) ~= "function" then return false end
    local ok, result = pcall(instanceof, source, "IsoAnimal")
    return ok and result == true
end

SDI.HandleWorldSound = function(self, x, y, z, radius, volume, source, ...)
    originalHandleWorldSound(self, x, y, z, radius, volume, source, ...)
    if not isAnimalSource(source) then return end

    local player = self.playerObj or getSpecificPlayer(0)
    if not player then return end
    local adjustedRadius = tonumber(radius) or 0
    if CharacterTrait and CharacterTrait.DEAF and player:hasTrait(CharacterTrait.DEAF) then
        adjustedRadius = 0
    elseif CharacterTrait and CharacterTrait.KEEN_HEARING and player:hasTrait(CharacterTrait.KEEN_HEARING) then
        adjustedRadius = adjustedRadius * 1.2
    elseif CharacterTrait and CharacterTrait.HARD_OF_HEARING and player:hasTrait(CharacterTrait.HARD_OF_HEARING) then
        adjustedRadius = adjustedRadius * 0.8
    end
    if IsoUtils.DistanceTo(player:getX(), player:getY(), x, y) >= adjustedRadius then return end
    if SDIGetOption("ONLYINSEARCHMODE") then
        local manager = ISSearchManager and ISSearchManager.getManager(player)
        if not manager or not manager.isSearchMode then return end
    end
    if SDIGetOption("ONLYCROUCHED") and not player:isSneaking() then return end

    for _, sound in ipairs(self.sounds) do
        if sound.objsource == source then
            sound.x, sound.y, sound.z = x, y, z
            sound.emissionTime = os.time()
            sound.typesound = isZombieAnimal(source) and "ZOMBIES" or "LAMBDA"
            sound.loud = isZombieAnimal(source) or sound.loud
            self:setDistance(IsoUtils.DistanceTo(player:getX(), player:getY(), x, y))
            self:setAngleFromPoint(x, y)
            self:setDuration(100)
            self:setVisible(true)
            return
        end
    end

    if isZombieAnimal(source) then
        -- The vanilla handler classifies IsoAnimal as LAMBDA and can discard
        -- it under IGNORELAMBDA; hostile wildlife must still use its own cue.
        addZombieAnimalCue(self, x, y, z, radius, volume, source)
    end
end

local originalRender = SDI.render
local distanceBands = { 1, 4, 6.5, 9, 11.5, 14, 20 }
local ANIMAL_SCAN_INTERVAL_MS = 250
local ANIMAL_RANGE = 15
local ANIMAL_RANGE_SQ = ANIMAL_RANGE * ANIMAL_RANGE
local nextAnimalScanAt = 0

local function cueBand(distance)
    for index, maxDistance in ipairs(distanceBands) do
        if distance <= maxDistance then return index end
    end
    return #distanceBands + 1
end

SDI.render = function(self, ...)
    local zombiePalette = getZombieCuePalette()
    local normalPalette = getNormalCuePalette()
    if not zombiePalette or not normalPalette then return originalRender(self, ...) end

    local otherSounds, normalAnimalSounds, zombieAnimalSounds = {}, {}, {}
    for _, sound in ipairs(self.sounds or {}) do
        local source = sound.objsource
        local isAnimal = false
        if source and type(instanceof) == "function" then
            local okAnimal, isAnimalValue = pcall(instanceof, source, "IsoAnimal")
            isAnimal = okAnimal and isAnimalValue == true
            if isAnimal then
                local okPosition, x, y, z = pcall(function()
                    return source:getX(), source:getY(), source:getZ()
                end)
                if okPosition then sound.x, sound.y, sound.z = x, y, z end
            end
        end
        if isAnimal and isZombieAnimal(source) then
            sound.typesound = "ZOMBIES"
            sound.loud = true
            zombieAnimalSounds[#zombieAnimalSounds + 1] = sound
        elseif isAnimal then
            sound.typesound = "LAMBDA"
            normalAnimalSounds[#normalAnimalSounds + 1] = sound
        else
            otherSounds[#otherSounds + 1] = sound
        end
    end

    local originalZombieTextures = self.textures.ZOMBIES
    local originalLambdaTextures = self.textures.LAMBDA
    self.sounds = otherSounds
    local normalResult = originalRender(self, ...)
    otherSounds = self.sounds

    self.textures.LAMBDA = normalPalette
    self.sounds = normalAnimalSounds
    local normalAnimalResult = originalRender(self, ...)
    normalAnimalSounds = self.sounds

    self.textures.ZOMBIES = zombiePalette
    self.sounds = zombieAnimalSounds
    local zombieAnimalResult = originalRender(self, ...)
    zombieAnimalSounds = self.sounds

    self.textures.ZOMBIES = originalZombieTextures
    self.textures.LAMBDA = originalLambdaTextures
    self.sounds = otherSounds
    for _, sound in ipairs(normalAnimalSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    for _, sound in ipairs(zombieAnimalSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    return zombieAnimalResult or normalAnimalResult or normalResult
end

local function scanNearbyAnimals()
    if not SDIGetOption or not SDIGetOption("SDIEnabled")
            or type(SDI.OnWorldSound) ~= "function" then
        return
    end

    local now = type(getTimestampMs) == "function"
        and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < nextAnimalScanAt then return end
    nextAnimalScanAt = now + ANIMAL_SCAN_INTERVAL_MS

    local player = getSpecificPlayer(0)
    if not player then return end
    local cell = type(player.getCell) == "function" and player:getCell() or getCell()
    if not cell or type(cell.getGridSquare) ~= "function" then return end

    local playerX, playerY = player:getX(), player:getY()
    local baseX, baseY = math.floor(playerX), math.floor(playerY)
    local playerZ = math.floor(player:getZ())
    for dx = -ANIMAL_RANGE, ANIMAL_RANGE do
        for dy = -ANIMAL_RANGE, ANIMAL_RANGE do
            if dx * dx + dy * dy < ANIMAL_RANGE_SQ then
                local square = cell:getGridSquare(baseX + dx, baseY + dy, playerZ)
                local objects = square and square:getMovingObjects()
                if objects then
                    for index = 0, objects:size() - 1 do
                        local animal = objects:get(index)
                        if isAnimalSource(animal) then
                            local ok, x, y, z, dead = pcall(function()
                                return animal:getX(), animal:getY(), animal:getZ(),
                                    type(animal.isDead) == "function" and animal:isDead()
                            end)
                            if ok and not dead then
                                local dxAnimal, dyAnimal = playerX - x, playerY - y
                                local distanceSq = dxAnimal * dxAnimal + dyAnimal * dyAnimal
                                if distanceSq < ANIMAL_RANGE_SQ then
                                    -- Refresh existing cues before their one-second lifetime
                                    -- expires; the Workshop returns early for duplicate sources.
                                    SDI.OnWorldSound(x, y, z, ANIMAL_RANGE, 7, animal)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(scanNearbyAnimals)

print(TAG .. "SDI hooks loaded; normal animals use teal-to-amber cues; infected/undead animals use cyan-to-magenta cues")
