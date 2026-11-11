-- Optional Undead Wildlife integration. Keep Animal Balance usable when UW is absent.
local loaded, loadError = pcall(function()
    require "Definitions/animal/AnimalAvatarDefinition"
    require "Definitions/animal/UndeadWildlife_Definitions"
    require "UndeadWildlife_Butchering"
end)
if not loaded or type(UndeadWildlife) ~= "table"
    or type(AnimalAvatarDefinition) ~= "table" or type(ButcheringUtil) ~= "table" then
    if not loaded then
        print("[ChilaSeda_AnimalBalance] Undead Wildlife butchering integration inactive: " .. tostring(loadError))
    end
    return
end

ChilaSeda_AnimalBalance_UndeadWildlife = ChilaSeda_AnimalBalance_UndeadWildlife or {}

local equivalents = {
    infectedraccoon = "raccoonboar", infectedcockerel = "cockerel",
    infectedchicken = "hen", infectedturkey = "turkeyhen",
    infectedrabbit = "rabdoe", infectedpiglet = "piglet",
    infectedfarmpig = "sow", infecteddeerdoe = "doe",
    infecteddeerstag = "buck", infectedcow = "cow",
    infectedcowcalf = "cowcalf", infectedbull = "bull",
    infectedewe = "ewe", infectedram = "ram", infectedlamb = "lamb",
    infectedrat = "rat",
}

local function target(animalType, data)
    if data and data.UndeadWildlifeNoButcher then return nil end
    if UndeadWildlife.SkeletalTypes and UndeadWildlife.SkeletalTypes[animalType] then return nil end
    return equivalents[animalType]
end

-- Only the synchronous vanilla operation sees the equivalent avatar definition.
-- Do not globally enable hooks or change infected UI/animations/model positioning.
-- Preserve the original function's one return value; restore even on failure.
local function withAvatar(animalType, source, operation)
    local previous = AnimalAvatarDefinition[animalType]
    AnimalAvatarDefinition[animalType] = AnimalAvatarDefinition[source]
    local ok, result = pcall(operation)
    AnimalAvatarDefinition[animalType] = previous
    if not ok then error("[ChilaUWButchering] " .. tostring(result)) end
    return result
end

ChilaSeda_AnimalBalance_UndeadWildlife.withVanillaAvatar = function(carcass, operation)
    if type(operation) ~= "function" then return nil end
    if not carcass then return operation() end
    local data = carcass:getModData()
    local kind = data and data.AnimalType or carcass:getAnimalType()
    local source = target(kind, data)
    if not source then return operation() end
    return withAvatar(kind, source, operation)
end

local installed = false
local function install()
    if installed then return end
    installed = true
    local originalBodyData = setAnimalBodyData
    local originalGround = ButcheringUtil.butcherAnimalFromGround

    setAnimalBodyData = function(animal, data)
        local kind = animal:getAnimalType()
        local source = target(kind, data)
        if not source then return originalBodyData(animal, data) end
        return withAvatar(kind, source, function()
            return originalBodyData(animal, data)
        end)
    end

    ButcheringUtil.butcherAnimalFromGround = function(carcass, player, keepCorpse)
        local data = carcass:getModData()
        local kind = carcass:getAnimalType()
        local source = target(kind, data)
        if not source then return originalGround(carcass, player, keepCorpse) end
        return withAvatar(kind, source, function()
            -- Repair this single classification on existing, still-intact bodies.
            -- Never repopulate parts/head/feathers or rerun setAnimalBodyData.
            local avatar = AnimalAvatarDefinition[source]
            if not isClient() and data.parts and avatar and avatar.hook then
                data.babyLeather = nil
            end
            return originalGround(carcass, player, keepCorpse)
        end)
    end

    print("[ChilaSeda_AnimalBalance] optional Undead Wildlife ground classification loaded.")
end

Events.OnGameBoot.Add(install)
