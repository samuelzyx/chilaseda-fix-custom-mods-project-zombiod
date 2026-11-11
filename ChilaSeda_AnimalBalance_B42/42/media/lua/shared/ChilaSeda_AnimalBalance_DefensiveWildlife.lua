local function applyDefensiveWildlife()
    local definitions = AnimalDefinitions and AnimalDefinitions.animals
    if not definitions then
        print("[ChilaSeda_AnimalBalance] defensive wildlife skipped: animal definitions unavailable")
        return
    end

    local enabled = 0
    for _, definition in pairs(definitions) do
        local attackDistance = tonumber(definition.attackDist) or 0
        local baseDamage = tonumber(definition.baseDmg) or 0
        if attackDistance <= 0 or baseDamage <= 0 then
            local maxWeight = tonumber(definition.maxWeight) or 10
            if maxWeight < 1 then
                attackDistance, baseDamage = 0.5, 0.02
            elseif maxWeight < 10 then
                attackDistance, baseDamage = 0.75, 0.04
            elseif maxWeight < 50 then
                attackDistance, baseDamage = 1, 0.08
            elseif maxWeight < 150 then
                attackDistance, baseDamage = 1.25, 0.12
            elseif maxWeight < 400 then
                attackDistance, baseDamage = 1.5, 0.18
            else
                attackDistance, baseDamage = 2, 0.24
            end
            definition.attackDist = attackDistance
            definition.baseDmg = baseDamage
        end
        definition.attackBack = true
        definition.attackIfStressed = false
        enabled = enabled + 1
    end

    local undeadLoaded = pcall(require, "UndeadWildlife_Core")
    local registered = 0
    if undeadLoaded and type(UndeadWildlife) == "table"
        and type(UndeadWildlife.HostileTypes) == "table"
        and type(UndeadWildlife.LivingToUndead) == "table" then
        for animalType in pairs(UndeadWildlife.HostileTypes) do
            if definitions[animalType] and UndeadWildlife.LivingToUndead[animalType] == nil then
                -- This map gates targeting, infection and reanimation in Undead Wildlife.
                -- Mapping a hostile species to itself enables the existing lifecycle safely.
                UndeadWildlife.LivingToUndead[animalType] = animalType
                registered = registered + 1
            end
        end
    end

    print("[ChilaSeda_AnimalBalance] defensive wildlife enabled animalTypes=" .. tostring(enabled)
        .. " undeadWildlifeTypes=" .. tostring(registered))
end

Events.OnGameBoot.Add(applyDefensiveWildlife)
