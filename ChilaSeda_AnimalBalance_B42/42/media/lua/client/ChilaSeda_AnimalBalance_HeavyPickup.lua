require "ISUI/Animal/ISAnimalContextMenu"
require "ISUI/ISWorldObjectContextMenu"
require "TimedActions/Animals/ISPickupAnimal"
require "TimedActions/ISGrabCorpseAction"

local MAX_PICKUP_MASS_KG = 50

local function safeCall(object, method)
    if not object then return nil end
    local ok, value = pcall(function()
        local fn = object[method]
        if type(fn) ~= "function" then return nil end
        return fn(object)
    end)
    if ok then return tonumber(value) end
    return nil
end

local function liveAnimalMass(animal)
    local data = animal and animal:getData()
    return safeCall(data, "getWeight")
end

local function isAnimalCorpse(body)
    local item = body and body:getItem()
    return item and item:getFullType() == "Base.CorpseAnimal"
end

local function animalCorpseMass(body)
    if not isAnimalCorpse(body) then return nil end
    return safeCall(body, "getWeight")
end

local function isOverLimit(mass)
    return mass ~= nil and mass > MAX_PICKUP_MASS_KG
end

local function notifyBlocked(player, mass)
    if not player then return end
    local message = getText("UI_AnimalBalance_HeavyPickup",
        string.format("%.1f", mass), string.format("%.0f", MAX_PICKUP_MASS_KG))
    pcall(function() player:setHaloNote(message) end)
    print("[ChilaSeda AnimalBalance] blocked pickup: mass=" .. tostring(mass)
        .. " kg, limit=" .. tostring(MAX_PICKUP_MASS_KG) .. " kg")
end

local function blockLiveAnimal(animal, player)
    local mass = liveAnimalMass(animal)
    if not isOverLimit(mass) then return false end
    notifyBlocked(player, mass)
    return true
end

local function blockAnimalCorpse(body, player)
    local mass = animalCorpseMass(body)
    if not isOverLimit(mass) then return false end
    notifyBlocked(player, mass)
    return true
end

local function install()
    if AnimalContextMenu.ChilaSedaHeavyPickupInstalled then return end
    AnimalContextMenu.ChilaSedaHeavyPickupInstalled = true

    local originalPickupAnimal = AnimalContextMenu.onPickupAnimal
    AnimalContextMenu.onPickupAnimal = function(animal, player)
        if blockLiveAnimal(animal, player) then return end
        return originalPickupAnimal(animal, player)
    end

    local originalAnimalIsValid = ISPickupAnimal.isValid
    ISPickupAnimal.isValid = function(action)
        if blockLiveAnimal(action.animal, action.character) then return false end
        return originalAnimalIsValid(action)
    end

    local originalAnimalComplete = ISPickupAnimal.complete
    ISPickupAnimal.complete = function(action, ...)
        if blockLiveAnimal(action.animal, action.character) then return false end
        return originalAnimalComplete(action, ...)
    end

    local originalGrabCorpse = ISWorldObjectContextMenu.onGrabCorpseItem
    ISWorldObjectContextMenu.onGrabCorpseItem = function(worldObjects, body, playerNum)
        local player = getSpecificPlayer(playerNum)
        if blockAnimalCorpse(body, player) then return end
        return originalGrabCorpse(worldObjects, body, playerNum)
    end

    local originalCorpseIsValid = ISGrabCorpseAction.isValid
    ISGrabCorpseAction.isValid = function(action)
        if blockAnimalCorpse(action.corpseBody, action.character) then return false end
        return originalCorpseIsValid(action)
    end

    local originalCorpseComplete = ISGrabCorpseAction.complete
    ISGrabCorpseAction.complete = function(action, ...)
        if blockAnimalCorpse(action.corpseBody, action.character) then return false end
        return originalCorpseComplete(action, ...)
    end

    print("[ChilaSeda AnimalBalance] heavy pickup guard installed; max animal pickup mass="
        .. tostring(MAX_PICKUP_MASS_KG) .. " kg")
end

Events.OnGameBoot.Add(install)
