local loaded = pcall(function()
    require "UndeadWildlife_Core"
end)
if not loaded or type(UndeadWildlife) ~= "table" then return end

local alertAt = {}
local interruptAt = {}
local injuryAt = {}
local pendingAnimalAttacks = {}
local recentlyHit = {}

local function getPlayerKey(player)
    local username = player:getUsername()
    if username and username ~= "" then
        return username
    end
    return tostring(player:getOnlineID()) .. ":" .. tostring(player:getPlayerNum())
end

local function showNotice(player, message, red, green, blue, icon)
    if HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, message, icon or "media/ui/Skull1.png", red or 255, green or 220, blue or 120)
    end
end

local function isVehicleSealed(vehicle)
    if not vehicle or not vehicle.getPartCount or not vehicle.getPartByIndex then
        return false
    end

    local doorCount = 0
    local windowCount = 0
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            if part.getDoor then
                local door = part:getDoor()
                if door then
                    doorCount = doorCount + 1
                    if not door.isOpen or door:isOpen() or not part.getCondition or part:getCondition() <= 0 then
                        return false
                    end
                    -- A closed door with a missing/unreadable window is not
                    -- treated as a sealed barrier.
                    if not part.getWindow then
                        return false
                    end
                    local doorWindow = part:getWindow()
                    if not doorWindow or not doorWindow.isDestroyed or doorWindow:isDestroyed() then
                        return false
                    end
                end
            end
            if part.getWindow then
                local window = part:getWindow()
                if window then
                    windowCount = windowCount + 1
                    if not window.isOpen or window:isOpen() then
                        return false
                    end
                    if not window.isDestroyed or window:isDestroyed() then
                        return false
                    end
                end
            end
        end
    end

    -- Fail open if this vehicle exposes no door/window state to Lua.
    return doorCount > 0 and windowCount > 0
end

local function isPlayerTarget(args, player)
    return args.target and args.target == getPlayerKey(player)
end

local function showInjuryNotice(player, animalId, allowFallback)
    local now = getTimestampMs()
    animalId = tostring(animalId or "unknown")
    if allowFallback or (pendingAnimalAttacks[animalId] and now <= pendingAnimalAttacks[animalId]) then
        if now >= (injuryAt[animalId] or 0) then
            injuryAt[animalId] = now + 2000
            pendingAnimalAttacks[animalId] = nil
            showNotice(player, getText("UI_ChilaSeda_UW_InjuryNotice"), 255, 80, 80)
        end
    end
end

local function onPlayerGetDamage(character, damageType, damage)
    local player = getPlayer()
    if character ~= player or damageType ~= "WEAPONHIT" or not damage or (tonumber(damage) or 0) <= 0 then
        return
    end
    local now = getTimestampMs()
    for animalId, expiresAt in pairs(pendingAnimalAttacks) do
        if now > expiresAt then
            pendingAnimalAttacks[animalId] = nil
        else
            showInjuryNotice(player, animalId, false)
            return
        end
    end
end

local function onServerCommand(module, command, args)
    if module ~= "UndeadWildlife" or not args then
        return
    end

    local player = getPlayer()
    if not player or player:isDead() then
        return
    end

    if command == "AnimalAttackStart" and isPlayerTarget(args, player) then
        local id = tostring(args.animalID)
        local now = getTimestampMs()
        pendingAnimalAttacks[id] = now + 2500
        if now >= (alertAt[id] or 0) then
            alertAt[id] = now + 2500
            showNotice(player, getText("UI_ChilaSeda_UW_IncomingAttack"), 255, 120, 80)
        end

        local vehicle = player:getVehicle()
        if isVehicleSealed(vehicle) and now >= (interruptAt[id] or 0) then
            interruptAt[id] = now + 1000
            sendClientCommand(player, "UndeadWildlife", "AnimalAttackInterrupt", { id = tonumber(args.animalID) })
        end
        return
    end

    if command == "AnimalAttack" then
        showInjuryNotice(player, args.animalID, true)
    end
end

local function onWeaponHitXp(owner, weapon, hitObject)
    local player = getPlayer()
    if owner ~= player or not hitObject or not instanceof(hitObject, "IsoAnimal") then
        return
    end
    local animalType = hitObject:getAnimalType()
    if not UndeadWildlife.HostileTypes or not UndeadWildlife.HostileTypes[animalType] then
        return
    end
    recentlyHit[hitObject] = getTimestampMs() + 15000
end

local function checkDefeatedAnimals()
    local now = getTimestampMs()
    local player = getPlayer()
    for animal, expiresAt in pairs(recentlyHit) do
        if animal:isDead() then
            if player and not player:isDead() then
                showNotice(player, getText("UI_ChilaSeda_UW_Victory"), 150, 230, 150)
            end
            recentlyHit[animal] = nil
        elseif now >= expiresAt then
            recentlyHit[animal] = nil
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnPlayerGetDamage.Add(onPlayerGetDamage)
Events.OnWeaponHitXp.Add(onWeaponHitXp)
Events.OnTick.Add(checkDefeatedAnimals)

print("[ChilaSeda_AnimalBalance] optional Undead Wildlife combat and vehicle protection loaded")
