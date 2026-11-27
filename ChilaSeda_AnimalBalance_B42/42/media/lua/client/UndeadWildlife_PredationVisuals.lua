if not UndeadWildlife then pcall(require, "UndeadWildlife_Core") end
if type(UndeadWildlife) ~= "table" then return end

local SCAN_INTERVAL = 30
local SPOT_INTERVAL_MS = 500
local BITE_COOLDOWN_MS = 2800
local BITE_RANGE = 1.6
local PLAYER_PRIORITY_RANGE = 3
local SETTINGS_ID = "ChilaSeda_AnimalBalance_B42"
local SETTING_LIMITS = {
    maxHuntersPerAnimal = { id = "MaxHuntersPerAnimal", minimum = 1, maximum = 20, default = 2 },
    stallTimeoutSeconds = { id = "StallTimeoutSeconds", minimum = 5, maximum = 300, default = 20 },
    unreachablePreySeconds = { id = "UnreachablePreySeconds", minimum = 0, maximum = 600, default = 60 },
}
local STALL_COOLDOWN_MS = 15000
local DISTANCE_PROGRESS_MIN = 0.35
local activeSettings = {
    maxHuntersPerAnimal = SETTING_LIMITS.maxHuntersPerAnimal.default,
    stallTimeoutMs = SETTING_LIMITS.stallTimeoutSeconds.default * 1000,
    unreachablePreyMs = SETTING_LIMITS.unreachablePreySeconds.default * 1000,
}
local scanTicks = 0
local scanReports = 0
local settingsTraceLines = 0
local settingsLoaded = false
local states = setmetatable({}, { __mode = "k" })
local blockedUntil = setmetatable({}, { __mode = "k" })
local blockedAnimals = setmetatable({}, { __mode = "k" })
local feastingZombies = setmetatable({}, { __mode = "k" })
local pendingCorpseTextures = {}
local pendingRemoteRises = {}

local function debugLog(message)
    if UndeadWildlife.getOption("PredationDebug", false) then
        print("[UndeadWildlife Predation Client] " .. message)
    end
end

local function debugSettings(message)
    if settingsTraceLines >= 12 then return end
    settingsTraceLines = settingsTraceLines + 1
    debugLog("settings " .. message)
end

local function registerSettings()
    local api = PZAPI and PZAPI.ModOptions
    if not api or type(api.create) ~= "function" or type(api.getOptions) ~= "function" then
        debugSettings("register result=fallback reason=mod-options-api-unavailable")
        return nil
    end

    local existing = api:getOptions(SETTINGS_ID)
    if existing then return existing end

    local ok, options = pcall(function()
        local group = api:create(SETTINGS_ID, "UI_ChilaSeda_AnimalBalance_PredationOptions")
        if type(group.addDescription) == "function" then
            group:addDescription("UI_ChilaSeda_AnimalBalance_PredationDescription")
        end
        group:addSlider("MaxHuntersPerAnimal", "UI_ChilaSeda_AnimalBalance_MaxHunters",
            SETTING_LIMITS.maxHuntersPerAnimal.minimum, SETTING_LIMITS.maxHuntersPerAnimal.maximum, 1,
            SETTING_LIMITS.maxHuntersPerAnimal.default, "UI_ChilaSeda_AnimalBalance_MaxHuntersTooltip")
        group:addSlider("StallTimeoutSeconds", "UI_ChilaSeda_AnimalBalance_StallTimeout",
            SETTING_LIMITS.stallTimeoutSeconds.minimum, SETTING_LIMITS.stallTimeoutSeconds.maximum, 1,
            SETTING_LIMITS.stallTimeoutSeconds.default, "UI_ChilaSeda_AnimalBalance_StallTimeoutTooltip")
        group:addSlider("UnreachablePreySeconds", "UI_ChilaSeda_AnimalBalance_UnreachablePrey",
            SETTING_LIMITS.unreachablePreySeconds.minimum, SETTING_LIMITS.unreachablePreySeconds.maximum, 1,
            SETTING_LIMITS.unreachablePreySeconds.default, "UI_ChilaSeda_AnimalBalance_UnreachablePreyTooltip")
        return group
    end)
    if not ok or not options then
        debugSettings("register result=fallback reason=option-registration-failed error=" .. tostring(options))
        return nil
    end
    return options
end

local settingsGroup = registerSettings()

local function readIntegerSetting(setting)
    local option = settingsGroup and type(settingsGroup.getOption) == "function"
        and settingsGroup:getOption(setting.id) or nil
    if not option or type(option.getValue) ~= "function" then
        debugSettings("read result=fallback setting=" .. setting.id .. " reason=option-unavailable")
        return setting.default
    end

    local ok, rawValue = pcall(option.getValue, option)
    local value = ok and tonumber(rawValue) or nil
    if not value or value ~= value or value == math.huge or value == -math.huge then
        debugSettings("read result=fallback setting=" .. setting.id .. " reason=invalid-value")
        value = setting.default
    end
    local normalized = math.max(setting.minimum, math.min(setting.maximum, math.floor(value + 0.5)))
    if normalized ~= value then
        if type(option.setValue) == "function" then
            local setOk, setError = pcall(option.setValue, option, normalized)
            debugSettings("read result=" .. (setOk and "normalized" or "runtime-only-fallback")
                .. " setting=" .. setting.id .. " supplied=" .. tostring(value)
                .. " value=" .. tostring(normalized)
                .. (setOk and "" or " error=" .. tostring(setError)))
        else
            debugSettings("read result=runtime-only-fallback setting=" .. setting.id
                .. " supplied=" .. tostring(value) .. " value=" .. tostring(normalized)
                .. " reason=setter-unavailable")
        end
    end
    return normalized
end

local function refreshSettings(reason)
    local previous = activeSettings
    activeSettings = {
        maxHuntersPerAnimal = readIntegerSetting(SETTING_LIMITS.maxHuntersPerAnimal),
        stallTimeoutMs = readIntegerSetting(SETTING_LIMITS.stallTimeoutSeconds) * 1000,
        unreachablePreyMs = readIntegerSetting(SETTING_LIMITS.unreachablePreySeconds) * 1000,
    }
    local changed = previous.maxHuntersPerAnimal ~= activeSettings.maxHuntersPerAnimal
        or previous.stallTimeoutMs ~= activeSettings.stallTimeoutMs
        or previous.unreachablePreyMs ~= activeSettings.unreachablePreyMs
    if changed or not settingsLoaded then
        debugSettings("refresh result=loaded reason=" .. tostring(reason)
            .. " maxHunters=" .. tostring(activeSettings.maxHuntersPerAnimal)
            .. " stallSeconds=" .. tostring(activeSettings.stallTimeoutMs / 1000)
            .. " ignoreSeconds=" .. tostring(activeSettings.unreachablePreyMs / 1000))
    end
    settingsLoaded = true
end

if settingsGroup then
    local baseApply = settingsGroup.apply
    settingsGroup.apply = function(self, ...)
        local result
        if type(baseApply) == "function" then result = baseApply(self, ...) end
        refreshSettings("options-applied")
        return result
    end
end

local function loadSavedSettings()
    local api = PZAPI and PZAPI.ModOptions
    if api and type(api.load) == "function" then
        local ok, err = pcall(api.load, api)
        if not ok then
            debugSettings("load result=fallback reason=mod-options-load-failed error=" .. tostring(err))
        end
    end
    refreshSettings("game-start")
end

if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(loadSavedSettings)
else
    refreshSettings("script-load-fallback")
end

local function externalActive()
    local mods = getActivatedMods and getActivatedMods()
    return mods and mods:contains("ZombiesTargetAnimals") or false
end

local function alive(object)
    return object and not object:isDead()
end

local function isPreyTemporarilyBlocked(animal)
    local entry = blockedAnimals[animal]
    if not entry then
        return false
    end
    local now = getTimestampMs()
    local dx = animal:getX() - entry.x
    local dy = animal:getY() - entry.y
    local moved = animal:getZ() ~= entry.z or dx * dx + dy * dy >= 4
    if now >= entry.blockedAt + activeSettings.unreachablePreyMs or moved then
        blockedAnimals[animal] = nil
        debugLog("prey-unblocked type=" .. tostring(animal:getAnimalType())
            .. " reason=" .. (moved and "animal-moved" or "cooldown-expired"))
        return false
    end
    return true
end

local function eligible(animal)
    return alive(animal) and UndeadWildlife.LivingToUndead[animal:getAnimalType()] ~= nil
        and not isPreyTemporarilyBlocked(animal)
end

local function feasting(zombie)
    return feastingZombies[zombie] or zombie:getModData().UndeadWildlifeFeasting
end

local function owned(zombie)
    if not isClient() then
        return true
    end
    local ok, remote = pcall(function()
        return zombie:isRemoteZombie()
    end)
    return ok and remote == false
end

local function nearestPlayerDistance(zombie)
    local players = getOnlinePlayers()
    if not players or players:size() == 0 then
        local player = getPlayer()
        return player and zombie:DistTo(player) or math.huge
    end
    local distance = math.huge
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if alive(player) and not player:isInvisible() and not player:isGhostMode() then
            distance = math.min(distance, zombie:DistTo(player))
        end
    end
    return distance
end

local function restoreSpeed(zombie, state)
    if not state.originalWalk then
        return
    end
    zombie:setWalkType(state.originalWalk)
    zombie:setSpeedTypeFromWalkType()
    if string.find(state.originalWalk, "sprint") then
        zombie:doSprinter()
    elseif string.find(state.originalWalk, "slow") then
        zombie:doShambler()
    else
        zombie:doFastShambler()
    end
    state.originalWalk = nil
end

local function clearTarget(zombie)
    local wasUseless = zombie:isUseless()
    zombie:setUseless(true)
    zombie:spotted(zombie, true)
    zombie:setUseless(wasUseless)
    zombie:setVariable("NoLungeAttack", false)
    zombie:setVariable("NoLungeTarget", false)
    if instanceof(zombie:getTarget(), "IsoAnimal") then
        zombie:setTarget(nil)
    end
end

local function release(zombie, reason, cooldown)
    local state = states[zombie]
    if not state then
        return
    end
    pcall(clearTarget, zombie)
    pcall(restoreSpeed, zombie, state)
    debugLog("release target=" .. tostring(state.animal and state.animal:getAnimalType()) .. " reason=" .. tostring(reason))
    states[zombie] = nil
    if cooldown then
        blockedUntil[zombie] = getTimestampMs() + cooldown
    end
end

local function findNearest(zombie, animals, range, targetCounts)
    local nearest
    local nearestDistance = range
    local capacityBlocked = 0
    for i = 0, animals:size() - 1 do
        local animal = animals:get(i)
        if eligible(animal) and animal:getZ() == zombie:getZ() then
            local distance = zombie:DistTo(animal)
            if distance <= range then
                if (targetCounts[animal] or 0) < activeSettings.maxHuntersPerAnimal then
                    if distance <= nearestDistance then
                        nearest = animal
                        nearestDistance = distance
                    end
                else
                    capacityBlocked = capacityBlocked + 1
                end
            end
        end
    end
    return nearest, capacityBlocked
end

local function engage(zombie, animal)
    local now = getTimestampMs()
    local distance = zombie:DistTo(animal)
    local state = {
        animal = animal,
        bestDistance = distance,
        lastProgressAt = now,
    }
    states[zombie] = state
    debugLog("engage target=" .. tostring(animal:getAnimalType()) .. " distance=" .. string.format("%.2f", zombie:DistTo(animal)))
    local speedType = zombie:getSpeedType()
    if speedType ~= 1 and speedType ~= 2 then
        state.originalWalk = zombie:getWalkType()
        state.boostWalk = tostring(ZombRand(5) + 1)
        zombie:setWalkType(state.boostWalk)
        zombie:setSpeedTypeFromWalkType()
        zombie:doFastShambler()
    end
end

local function blockUnreachablePrey(animal, zombie, state, now, distance)
    if blockedAnimals[animal] then
        return
    end
    blockedAnimals[animal] = {
        blockedAt = now,
        x = animal:getX(),
        y = animal:getY(),
        z = animal:getZ(),
    }
    debugLog("route-stalled zombie=" .. tostring(zombie:getOnlineID())
        .. " target=" .. tostring(animal:getAnimalType())
        .. " bestDistance=" .. string.format("%.2f", state.bestDistance or distance)
        .. " distance=" .. string.format("%.2f", distance)
        .. " stalledMs=" .. tostring(now - (state.lastProgressAt or now)))

    local affected = {}
    for hunter, hunterState in pairs(states) do
        if hunterState.animal == animal then
            affected[#affected + 1] = hunter
        end
    end
    for _, hunter in ipairs(affected) do
        release(hunter, "prey-route-stalled", STALL_COOLDOWN_MS)
    end
    debugLog("prey-temporarily-ignored type=" .. tostring(animal:getAnimalType())
        .. " releasedHunters=" .. tostring(#affected)
        .. " cooldownMs=" .. tostring(activeSettings.unreachablePreyMs))
end

local function updateZombie(zombie, state, now, range)
    local animal = state.animal
    if not owned(zombie) or not eligible(animal) or zombie:DistTo(animal) > range * 2 then
        release(zombie, "invalid-or-distant")
        return
    end
    if nearestPlayerDistance(zombie) <= PLAYER_PRIORITY_RANGE then
        release(zombie, "player-priority")
        return
    end
    local distance = zombie:DistTo(animal)
    if distance <= (state.bestDistance or distance) - DISTANCE_PROGRESS_MIN then
        state.bestDistance = distance
        state.lastProgressAt = now
    end
    if now - (state.lastProgressAt or now) >= activeSettings.stallTimeoutMs then
        blockUnreachablePrey(animal, zombie, state, now, distance)
        return
    end
    local action = string.lower(zombie:getActionStateName() or "")
    local attacking = string.find(action, "attack") or string.find(action, "lunge") or string.find(action, "bumped")
    if attacking then
        return
    end
    local target = zombie:getTarget()
    if target and not instanceof(target, "IsoAnimal") then
        release(zombie, "engine-player-target")
        return
    end
    if target ~= animal then
        zombie:setTarget(animal)
    end
    zombie:setVariable("NoLungeAttack", true)
    zombie:setVariable("NoLungeTarget", true)
    if state.nextSpotAt == nil or now >= state.nextSpotAt then
        zombie:setTargetSeenTime(60.0)
        zombie:spotted(animal, false)
        zombie:spotted(animal, true)
        state.nextSpotAt = now + SPOT_INTERVAL_MS
    end
    if zombie:DistTo(animal) <= BITE_RANGE and now >= (state.nextBiteAt or 0) and now >= (state.nextBumpAt or 0) then
        zombie:faceThisObject(animal)
        zombie:setBumpType("Bite")
        state.nextBumpAt = now + BITE_COOLDOWN_MS
    end
end

local function countActiveTargets()
    local counts = {}
    for zombie, state in pairs(states) do
        if alive(zombie) and eligible(state.animal) then
            counts[state.animal] = (counts[state.animal] or 0) + 1
        end
    end
    return counts
end

local function enforceHunterLimit(targetCounts)
    local huntersByAnimal = {}
    for zombie, state in pairs(states) do
        local animal = state.animal
        if alive(zombie) and eligible(animal) then
            huntersByAnimal[animal] = huntersByAnimal[animal] or {}
            table.insert(huntersByAnimal[animal], { zombie = zombie, distance = zombie:DistTo(animal) })
        end
    end

    local releasedCount = 0
    for animal, hunters in pairs(huntersByAnimal) do
        if #hunters > activeSettings.maxHuntersPerAnimal then
            table.sort(hunters, function(first, second)
                return first.distance < second.distance
            end)
            for index = #hunters, activeSettings.maxHuntersPerAnimal + 1, -1 do
                release(hunters[index].zombie, "capacity-reduced", STALL_COOLDOWN_MS)
                targetCounts[animal] = math.max(0, (targetCounts[animal] or #hunters) - 1)
                releasedCount = releasedCount + 1
            end
        end
    end
    return releasedCount
end

local function scan()
    if externalActive() or not UndeadWildlife.getOption("Enabled", true) or not UndeadWildlife.getOption("ZombiesHuntAnimals", true) then
        for zombie in pairs(states) do
            release(zombie, "disabled")
        end
        return
    end
    local cell = getCell()
    local zombies = cell and cell:getZombieList()
    local animals = cell and cell:getAnimals()
    if not zombies or not animals then
        return
    end
    local range = UndeadWildlife.getOption("ZombieAnimalDetectionRange", 30)
    local targetCounts = countActiveTargets()
    local capacityReleasedZombies = enforceHunterLimit(targetCounts)
    local ownedCount = 0
    local eligibleCount = 0
    local blockedPreyCount = 0
    local capacityRejectedZombies = 0
    local clearedAnimalTargets = 0
    for animal in pairs(blockedAnimals) do
        if isPreyTemporarilyBlocked(animal) then
            blockedPreyCount = blockedPreyCount + 1
        end
    end
    for i = 0, animals:size() - 1 do
        if eligible(animals:get(i)) then
            eligibleCount = eligibleCount + 1
        end
    end
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if alive(zombie) and owned(zombie) then
            ownedCount = ownedCount + 1
        end
        if blockedUntil[zombie] and getTimestampMs() >= blockedUntil[zombie] then
            blockedUntil[zombie] = nil
        end
        if alive(zombie) and owned(zombie) and not states[zombie] and not blockedUntil[zombie] and not feasting(zombie) and nearestPlayerDistance(zombie) > PLAYER_PRIORITY_RANGE then
            local target = zombie:getTarget()
            if not target or instanceof(target, "IsoAnimal") then
                local animal, capacityBlocked = findNearest(zombie, animals, range, targetCounts)
                if animal then
                    engage(zombie, animal)
                    targetCounts[animal] = (targetCounts[animal] or 0) + 1
                else
                    if capacityBlocked > 0 then
                        capacityRejectedZombies = capacityRejectedZombies + 1
                    end
                    if target and instanceof(target, "IsoAnimal") then
                        clearTarget(zombie)
                        blockedUntil[zombie] = getTimestampMs() + STALL_COOLDOWN_MS
                        clearedAnimalTargets = clearedAnimalTargets + 1
                    end
                end
            end
        end
    end
    scanReports = scanReports + 1
    if scanReports >= 10 then
        scanReports = 0
        debugLog("scan zombies=" .. tostring(zombies:size()) .. " owned=" .. tostring(ownedCount) .. " eligibleAnimals=" .. tostring(eligibleCount) .. " active=" .. tostring((function()
            local count = 0
            for _ in pairs(states) do
                count = count + 1
            end
            return count
        end)()) .. " blockedPrey=" .. tostring(blockedPreyCount)
            .. " maxHuntersPerAnimal=" .. tostring(activeSettings.maxHuntersPerAnimal)
            .. " capacityReleasedZombies=" .. tostring(capacityReleasedZombies)
            .. " capacityRejectedZombies=" .. tostring(capacityRejectedZombies)
            .. " clearedAnimalTargets=" .. tostring(clearedAnimalTargets))
    end
end

local function onTick()
    local now = getTimestampMs()
    local range = UndeadWildlife.getOption("ZombieAnimalDetectionRange", 30)
    for zombie, state in pairs(states) do
        local ok, err = pcall(updateZombie, zombie, state, now, range)
        if not ok then
            debugLog("update-error " .. tostring(err))
            release(zombie, "update-error")
        end
    end
    scanTicks = scanTicks + 1
    if scanTicks >= SCAN_INTERVAL then
        scanTicks = 0
        scan()
    end
end

local function onCollide(first, second)
    local zombie
    local animal
    if instanceof(first, "IsoZombie") and instanceof(second, "IsoAnimal") then
        zombie = first
        animal = second
    elseif instanceof(second, "IsoZombie") and instanceof(first, "IsoAnimal") then
        zombie = second
        animal = first
    else
        return
    end
    local state = states[zombie]
    if not state or state.animal ~= animal or not owned(zombie) or not eligible(animal) then
        return
    end
    local now = getTimestampMs()
    if zombie:DistTo(animal) > BITE_RANGE or now < (state.nextBiteAt or 0) then
        return
    end
    state.nextBiteAt = now + BITE_COOLDOWN_MS
    state.nextBumpAt = state.nextBiteAt
    state.nextSpotAt = 0
    state.lastProgressAt = now
    state.bestDistance = zombie:DistTo(animal)
    local player = getPlayer()
    if player then
        sendClientCommand(player, "UndeadWildlife", "AnimalBite", {
            animalID = animal:getAnimalID(),
            animalType = animal:getAnimalType(),
            x = animal:getX(),
            y = animal:getY(),
            z = animal:getZ(),
        })
        debugLog("collision target=" .. tostring(animal:getAnimalType()) .. " distance=" .. string.format("%.2f", zombie:DistTo(animal)))
    end
    zombie:faceThisObject(animal)
    zombie:setBumpDone(true)
end

local function onZombieUpdate(zombie)
    local state = states[zombie]
    if not state or not state.boostWalk then
        return
    end
    local action = zombie:getActionStateName() or ""
    if string.find(action, "attack") or string.find(action, "bumped") then
        return
    end
    zombie:setWalkType(state.boostWalk)
    zombie:setSpeedTypeFromWalkType()
    zombie:doFastShambler()
end

local function applyCorpseTexture(args)
    local cell = getCell()
    local nearest
    local nearestDistance = math.huge
    for x = math.floor(args.x) - 3, math.floor(args.x) + 3 do
        for y = math.floor(args.y) - 3, math.floor(args.y) + 3 do
            local square = cell:getGridSquare(x, y, args.z)
            local bodies = square and square:getDeadBodys()
            if bodies then
                for i = 0, bodies:size() - 1 do
                    local body = bodies:get(i)
                    if body:isAnimal() and body:getAnimalType() == args.animalType then
                        local dx = body:getX() - args.x
                        local dy = body:getY() - args.y
                        local distance = dx * dx + dy * dy
                        if distance < nearestDistance then
                            nearest = body
                            nearestDistance = distance
                        end
                    end
                end
            end
        end
    end
    local visual = nearest and nearest:getAnimalVisual()
    if not visual then
        return false
    end
    visual:setSkinTextureName(args.texture)
    nearest:invalidateCorpse()
    return true
end

local function processPendingCorpseTextures()
    local now = getTimestampMs()
    for i = #pendingCorpseTextures, 1, -1 do
        local entry = pendingCorpseTextures[i]
        if applyCorpseTexture(entry.args) or now >= entry.expiresAt then
            table.remove(pendingCorpseTextures, i)
        end
    end
end

local function findRemoteRiseAnimal(args)
    local animals = getCell():getAnimals()
    local nearest
    local nearestDistance = 9
    for i = 0, animals:size() - 1 do
        local animal = animals:get(i)
        if animal and not animal:isDead() and animal:getAnimalType() == args.animalType and animal:getZ() == args.z then
            local dx = animal:getX() - args.x
            local dy = animal:getY() - args.y
            local distance = dx * dx + dy * dy
            if distance < nearestDistance then
                nearest = animal
                nearestDistance = distance
            end
        end
    end
    return nearest
end

local function processPendingRemoteRises()
    local now = getTimestampMs()
    for i = #pendingRemoteRises, 1, -1 do
        local entry = pendingRemoteRises[i]
        local animal = entry.animal or findRemoteRiseAnimal(entry.args)
        if animal and not entry.animal then
            entry.animal = animal
            entry.dueAt = now + entry.args.duration
            entry.direction = animal:getDir()
            animal:setVariable("UndeadWildlifeRising", true)
            animal:setIgnoreMovement(true)
            animal:getBehavior():setBlockMovement(true)
        end
        if animal and now < (entry.dueAt or 0) then
            animal:getPathFindBehavior2():cancel()
            animal:stopAllMovementNow()
            animal:setIgnoreMovement(true)
            animal:getBehavior():setBlockMovement(true)
            animal:setDir(entry.direction)
        elseif animal then
            animal:clearVariable("UndeadWildlifeRising")
            animal:setIgnoreMovement(false)
            animal:getBehavior():setBlockMovement(false)
            table.remove(pendingRemoteRises, i)
        elseif now >= entry.expiresAt then
            table.remove(pendingRemoteRises, i)
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= "UndeadWildlife" then
        return
    end
    if command == "AnimalCorpseInfected" then
        if not applyCorpseTexture(args) then
            pendingCorpseTextures[#pendingCorpseTextures + 1] = {
                args = args,
                expiresAt = getTimestampMs() + 5000,
            }
        end
        return
    end
    if command == "AnimalRiseStart" then
        pendingRemoteRises[#pendingRemoteRises + 1] = {
            args = args,
            expiresAt = getTimestampMs() + 5000,
        }
        return
    end
    if command ~= "ZombieAnimalFeastStart" and command ~= "ZombieAnimalFeastEnd" then
        return
    end
    local zombies = getCell():getZombieList()
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:getOnlineID() == tonumber(args.zombieID) then
            if command == "ZombieAnimalFeastStart" then
                if states[zombie] then
                    release(zombie, "feast-start")
                else
                    pcall(clearTarget, zombie)
                end
                feastingZombies[zombie] = true
                return
            end
            if states[zombie] then
                release(zombie, "feast-complete")
            else
                pcall(clearTarget, zombie)
            end
            feastingZombies[zombie] = nil
            blockedUntil[zombie] = nil
            scanTicks = SCAN_INTERVAL
            return
        end
    end
end

Events.OnTick.Add(onTick)
Events.OnCharacterCollide.Add(onCollide)
Events.OnZombieUpdate.Add(onZombieUpdate)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(processPendingCorpseTextures)
Events.OnTick.Add(processPendingRemoteRises)
