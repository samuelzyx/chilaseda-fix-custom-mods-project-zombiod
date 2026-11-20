-- Integrate Undead Wildlife with VisualSounds KA's actual SDI renderer.
-- The Workshop API has no VisualSoundsKA global; it exposes the SDI class.

require "SoundDirectionIndicatorMain"

local TAG = "[ChilaSeda_VisualSoundsUWColors] "
local SDI = SDI
if not SDI or type(SDI.HandleWorldSound) ~= "function" or type(SDI.render) ~= "function" then
    print(TAG .. "SDI API unavailable; patch skipped")
    return
end
local originalViewAngle = SDI.viewAngle
local angleBridgeFailureReported = false

local function renderSafeViewAngle()
    if not SDIGetOption or not SDIGetOption("VIEWPOINT") then return originalViewAngle() end
    local bridge = ChilaSedaVisualSoundsViewpointBridge
    if bridge and type(bridge.angle) == "function" then
        local ok, angle = pcall(bridge.angle)
        if ok and type(angle) == "number" and angle == angle then return angle end
    end
    if not angleBridgeFailureReported then
        angleBridgeFailureReported = true
        print(TAG .. "Viewpoint frame-angle bridge unavailable; using the isometric cue angle")
    end
    return originalViewAngle()
end

local function installRenderSafeViewAngle()
    local provider = SDI.viewAngle
    if type(provider) ~= "function" or provider == originalViewAngle or provider == renderSafeViewAngle then return end
    SDI.viewAngle = renderSafeViewAngle
    print(TAG .. "VisualSoundsKAViewpoint angle replaced with Viewpoint frame yaw; no thread-guarded Lua addon calls")
end

Events.OnGameBoot.Add(installRenderSafeViewAngle)

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

local function isZombieSource(source)
    if not source or type(instanceof) ~= "function" then return false end
    local ok, result = pcall(instanceof, source, "IsoZombie")
    return ok and result == true
end

local function livingWorldNPCType(source)
    if not source or type(source.getVariableBoolean) ~= "function" then return nil end
    local ok, marked = pcall(source.getVariableBoolean, source, "LivingWorldNPC")
    if not ok or marked ~= true then return nil end
    if type(source.getVariableString) == "function" then
        local typeOk, kind = pcall(source.getVariableString, source, "LivingWorldNPCType")
        if typeOk and type(kind) == "string" and kind ~= "" then return kind end
    end
    return "other"
end

local function addLivingWorldNPCCue(self, x, y, z, radius, volume, source)
    if not SDIGetOption or not SDIGetOption("SDIEnabled") then return end
    local player = self.playerObj or getSpecificPlayer(0)
    if not player or not source or source == player then return end
    self.sounds = self.sounds or {}

    local npcSound
    for _, sound in ipairs(self.sounds) do
        if sound.objsource == source then npcSound = sound; break end
    end
    if SDIGetOption("IGNOREPLAYERS") then
        if npcSound then
            for index = #self.sounds, 1, -1 do
                if self.sounds[index].objsource == source then table.remove(self.sounds, index) end
            end
        end
        return
    end

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
    if SDIGetOption("ONLYINSEARCHMODE") then
        local manager = ISSearchManager and ISSearchManager.getManager(player)
        if not manager or not manager.isSearchMode then return end
    end
    if SDIGetOption("ONLYCROUCHED") and not player:isSneaking() then return end

    if npcSound then
        npcSound.x, npcSound.y, npcSound.z = x, y, z
        npcSound.radius, npcSound.volume = adjustedRadius, volume
        npcSound.typesound, npcSound.loud = "PLAYERS", false
        npcSound.emissionTime = os.time()
    else
        local maxCues = tonumber(SDIGetOption("MAXVISUALCUES"))
        if maxCues and #self.sounds >= maxCues then return end
        npcSound = {
            x = x, y = y, z = z, radius = adjustedRadius, volume = volume,
            typesound = "PLAYERS", emissionTime = os.time(), objsource = source,
            zombieState = nil, loud = false,
        }
        table.insert(self.sounds, npcSound)
    end

    self:setDistance(distance)
    self:setDuration(100)
    self:setVisible(true)
end

SDI.HandleWorldSound = function(self, x, y, z, radius, volume, source, ...)
    originalHandleWorldSound(self, x, y, z, radius, volume, source, ...)
    if livingWorldNPCType(source) then
        addLivingWorldNPCCue(self, x, y, z, radius, volume, source)
        return
    end
    if isZombieSource(source) then
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

        for _, sound in ipairs(self.sounds or {}) do
            if sound.objsource == source then
                -- Refresh synthetic proximity cues before the SDI's normal expiry.
                sound.x, sound.y, sound.z = x, y, z
                sound.emissionTime = os.time()
                sound.typesound = "ZOMBIES"
                sound.loud = true
                self:setDistance(IsoUtils.DistanceTo(player:getX(), player:getY(), x, y))
                self:setDuration(100)
                self:setVisible(true)
                return
            end
        end
        return
    end
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
-- Leave cue orientation to SDI.render; VisualSoundsKAViewpoint supplies SDI.viewAngle.
local originalDrawIcon = SDI.drawIcon
local distanceBands = { 1, 4, 6.5, 9, 11.5, 14, 20 }
local ZOMBIE_COLORS = {
    { 1.00, 0.04, 0.03 }, { 1.00, 0.08, 0.04 }, { 1.00, 0.13, 0.05 }, { 0.98, 0.19, 0.06 },
    { 0.96, 0.25, 0.08 }, { 0.93, 0.32, 0.11 }, { 0.90, 0.39, 0.16 }, { 0.86, 0.47, 0.22 },
}
local ALLY_NPC_COLORS = {
    { 0.08, 0.92, 0.16 }, { 0.11, 0.92, 0.23 }, { 0.17, 0.91, 0.30 }, { 0.25, 0.91, 0.37 },
    { 0.34, 0.92, 0.45 }, { 0.44, 0.94, 0.54 }, { 0.56, 0.96, 0.65 }, { 0.68, 0.98, 0.76 },
}
local OTHER_NPC_COLORS = {
    { 1.00, 0.78, 0.02 }, { 1.00, 0.80, 0.04 }, { 1.00, 0.82, 0.07 }, { 1.00, 0.84, 0.11 },
    { 1.00, 0.86, 0.17 }, { 1.00, 0.88, 0.24 }, { 1.00, 0.90, 0.33 }, { 1.00, 0.92, 0.43 },
}
local CREATURE_SCAN_INTERVAL_MS = 250
local ANIMAL_RANGE = 15
local ANIMAL_RANGE_SQ = ANIMAL_RANGE * ANIMAL_RANGE
local ZOMBIE_RANGE = 15
local ZOMBIE_RANGE_SQ = ZOMBIE_RANGE * ZOMBIE_RANGE
local nextCreatureScanAt = 0

local function cueBand(distance)
    for index, maxDistance in ipairs(distanceBands) do
        if distance <= maxDistance then return index end
    end
    return #distanceBands + 1
end

local activeCueColors
local function isCuePaletteTexture(self, texture)
    local palette = self and self.textures and self.textures.ZOMBIES
    if type(palette) ~= "table" then return false end
    for _, cueTexture in ipairs(palette) do
        if cueTexture == texture then return true end
    end
    return false
end

if type(originalDrawIcon) == "function" then
    SDI.drawIcon = function(self, tex, cx, cy, angle, scale)
        local colors = activeCueColors and activeCueColors[cueBand(self.distancetoPoint or 0)]
        if not colors or not isCuePaletteTexture(self, tex) then
            return originalDrawIcon(self, tex, cx, cy, angle, scale)
        end
        local radians = math.rad(180 + angle)
        local cosine, sine = math.cos(radians), math.sin(radians)
        local dx, dy = tex:getWidth() / 2 * scale, tex:getHeight() / 2 * scale
        local xc, xs, yc, ys = cosine * dx, sine * dx, cosine * dy, sine * dy
        local ox, oy = self:getAbsoluteX() + cx, self:getAbsoluteY() + cy
        self.javaObject:DrawTexture(tex,
            ox + xc - ys, oy + yc + xs, ox - xc - ys, oy + yc - xs,
            ox - xc + ys, oy - yc - xs, ox + xc + ys, oy - yc + xs,
            colors[1], colors[2], colors[3], 1)
    end
end

SDI.render = function(self, ...)
    local zombiePalette = getZombieCuePalette()
    local normalPalette = getNormalCuePalette()
    if not zombiePalette or not normalPalette then return originalRender(self, ...) end

    local otherSounds, zombieSounds, normalAnimalSounds, zombieAnimalSounds = {}, {}, {}, {}
    local alliedNpcSounds, otherNpcSounds = {}, {}
    for _, sound in ipairs(self.sounds or {}) do
        local source = sound.objsource
        local npcType = livingWorldNPCType(source)
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
        if npcType then
            sound.typesound = "PLAYERS"
            sound.loud = false
            if npcType == "team" then
                alliedNpcSounds[#alliedNpcSounds + 1] = sound
            else
                otherNpcSounds[#otherNpcSounds + 1] = sound
            end
        elseif isAnimal and isZombieAnimal(source) then
            sound.typesound = "ZOMBIES"
            sound.loud = true
            zombieAnimalSounds[#zombieAnimalSounds + 1] = sound
        elseif isAnimal then
            sound.typesound = "LAMBDA"
            normalAnimalSounds[#normalAnimalSounds + 1] = sound
        elseif isZombieSource(source) or sound.typesound == "ZOMBIES" then
            zombieSounds[#zombieSounds + 1] = sound
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
    self.sounds = zombieSounds
    activeCueColors = ZOMBIE_COLORS
    local zombieResult = originalRender(self, ...)
    zombieSounds = self.sounds

    self.sounds = alliedNpcSounds
    activeCueColors = ALLY_NPC_COLORS
    local alliedNpcResult = originalRender(self, ...)
    alliedNpcSounds = self.sounds

    self.sounds = otherNpcSounds
    activeCueColors = OTHER_NPC_COLORS
    local otherNpcResult = originalRender(self, ...)
    otherNpcSounds = self.sounds
    activeCueColors = nil

    self.textures.ZOMBIES = originalZombieTextures
    self.textures.LAMBDA = originalLambdaTextures
    self.sounds = otherSounds
    for _, sound in ipairs(zombieSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    for _, sound in ipairs(normalAnimalSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    for _, sound in ipairs(zombieAnimalSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    for _, sound in ipairs(alliedNpcSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    for _, sound in ipairs(otherNpcSounds) do
        self.sounds[#self.sounds + 1] = sound
    end
    return otherNpcResult or alliedNpcResult or zombieResult or zombieAnimalResult or normalAnimalResult or normalResult
end

local function scanNearbyCreatures()
    if not SDIGetOption or not SDIGetOption("SDIEnabled")
            or type(SDI.OnWorldSound) ~= "function" then
        return
    end

    local now = type(getTimestampMs) == "function"
        and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < nextCreatureScanAt then return end
    nextCreatureScanAt = now + CREATURE_SCAN_INTERVAL_MS

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
                        local source = objects:get(index)
                        if isAnimalSource(source) then
                            local ok, x, y, z, dead = pcall(function()
                                return source:getX(), source:getY(), source:getZ(),
                                    type(source.isDead) == "function" and source:isDead()
                            end)
                            if ok and not dead then
                                local dxAnimal, dyAnimal = playerX - x, playerY - y
                                local distanceSq = dxAnimal * dxAnimal + dyAnimal * dyAnimal
                                if distanceSq < ANIMAL_RANGE_SQ then
                                    -- Refresh existing cues before their one-second lifetime
                                    -- expires; the Workshop returns early for duplicate sources.
                                    SDI.OnWorldSound(x, y, z, ANIMAL_RANGE, 7, source)
                                end
                            end
                        elseif isZombieSource(source) then
                            local ok, x, y, z, dead = pcall(function()
                                return source:getX(), source:getY(), source:getZ(),
                                    type(source.isDead) == "function" and source:isDead()
                            end)
                            if ok and not dead then
                                local dxZombie, dyZombie = playerX - x, playerY - y
                                local distanceSq = dxZombie * dxZombie + dyZombie * dyZombie
                                if distanceSq < ZOMBIE_RANGE_SQ then
                                    -- Feed the SDI directly; this does not emit a game WorldSound.
                                    SDI.OnWorldSound(x, y, z, ZOMBIE_RANGE, 7, source)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnTick.Add(scanNearbyCreatures)

print(TAG .. "SDI hooks loaded; nearby zombies, animals, and Living World NPCs receive proximity cues without WorldSound; human zombies use red, NPC allies green, and other NPCs yellow")
