require "Definitions/animal/AnimalPartsDefinitions"
require "Definitions/animal/ButcheringUtil"
require "TimedActions/Animals/ISRemoveHeadFromAnimal"
require "TimedActions/Animals/ISRemoveLeatherFromAnimal"
require "TimedActions/Animals/ISRemoveMeatFromAnimal"

local animalYieldByCarcass = setmetatable({}, { __mode = "k" })
local activeBoneExtraction = setmetatable({}, { __mode = "k" })
local estimateAnimalMass
local prepareBoneYield

local function isBoneType(fullType)
    if type(fullType) ~= "string" then return nil end
    fullType = string.lower(fullType)
    return string.find(fullType, "bone", 1, true) ~= nil
        or string.find(fullType, "fragment", 1, true) ~= nil
        or string.find(fullType, "skull", 1, true) ~= nil
end

local function isUndeadWildlifeAnimal(kind)
    local wildlife = UndeadWildlife
    if type(kind) ~= "string" or type(wildlife) ~= "table" then return false end
    return (type(wildlife.HostileTypes) == "table" and wildlife.HostileTypes[kind] == true)
        or (type(wildlife.SkeletalTypes) == "table" and wildlife.SkeletalTypes[kind] == true)
end

local undeadWildlifeMeatYield = {
    infectedrat = 0.2,
    infectedrabbit = 0.2,
    infectedchicken = 0.2,
    infectedcockerel = 0.2,
    infectedturkey = 0.3,
    infectedpiglet = 0.2,
    infectedlamb = 0.3,
    infectedraccoon = 0.4,
    infectedewe = 0.5,
    infectedram = 0.5,
    infecteddeerdoe = 0.6,
    infectedfarmpig = 0.8,
    infecteddeerstag = 0.9,
    infectedcowcalf = 0.8,
    infectedcow = 1.0,
    infectedbull = 1.0,
}

local function animalYieldBounds(carcass, player, yieldKind)
    local mass = estimateAnimalMass and estimateAnimalMass(carcass) or 25
    local skill = player and player:getPerkLevel(Perks.Butchering) or 0
    local skillBonus = math.floor(math.max(0, tonumber(skill) or 0) / 5)
    if mass < 1 then
        if yieldKind == "bone" then return 0, 0 end
        return 1, 1
    end

    -- Item yield grows with the square root of the animal's average live
    -- weight: large animals give more, without turning weight differences
    -- into dozens of extra individual items. Butchering adds one item per
    -- five skill levels to both ends of the range.
    local base = math.max(1, math.ceil(math.sqrt(mass) * 0.5))
    local maximum = base + skillBonus
    local minimum = math.max(1, math.floor(base * 0.55) + skillBonus)
    if yieldKind == "bone" then
        maximum = math.min(24, maximum)
        minimum = math.min(minimum, maximum)
    else
        maximum = math.min(30, maximum)
        minimum = math.min(minimum, maximum)
    end
    return minimum, maximum
end

local function chooseAnimalYield(carcass, player, yieldKind)
    local minimum, maximum = animalYieldBounds(carcass, player, yieldKind)
    if maximum <= minimum then return maximum end
    return ZombRand(minimum, maximum + 1)
end

local function limitedBoneCount(part, carcass, player)
    if not isBoneType(part.item) then return nil end
    local state = animalYieldByCarcass[carcass]
    if not state then
        state = { boneRemaining = chooseAnimalYield(carcass, player, "bone") }
        animalYieldByCarcass[carcass] = state
    end

    if state.boneAllocations then
        local fullType = part.item
        local typeRemaining = state.boneAllocationsByType
            and state.boneAllocationsByType[fullType]
        if typeRemaining ~= nil then
            local allocated = state.boneAllocations[part]
            if allocated == nil then allocated = typeRemaining end
            allocated = math.min(typeRemaining, math.max(0, allocated))
            state.boneAllocationsByType[fullType] = typeRemaining - allocated
            state.boneAllocations[part] = nil
            state.boneReserved = (state.boneReserved or 0) + allocated
            return allocated
        elseif state.boneAllocations[part] ~= nil then
            local allocated = math.max(0, state.boneAllocations[part])
            state.boneAllocations[part] = nil
            state.boneReserved = (state.boneReserved or 0) + allocated
            return allocated
        end
    end

    local remaining = (state.boneRemaining or 0) - (state.boneReserved or 0)
    if remaining <= 0 then return 0 end
    local requested = tonumber(part.nb)
    if requested == nil or requested < 0 then
        local minimum = tonumber(part.minNb)
        local maximum = tonumber(part.maxNb)
        local size = tonumber(carcass:getAnimalSize()) or 1
        if minimum and maximum and minimum >= 0 and maximum >= 0 then
            minimum = math.max(0, math.ceil(minimum * size))
            maximum = math.max(minimum, math.floor(maximum * size))
            requested = ZombRand(minimum, maximum + 1)
        else
            requested = remaining
        end
    end

    requested = math.min(remaining, math.max(0, math.floor(requested)))
    state.boneReserved = (state.boneReserved or 0) + requested
    return requested
end

local function snapshotInventory(inventory)
    local snapshot = {}
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local count = 1
            if type(item.getCount) == "function" then
                local ok, value = pcall(item.getCount, item)
                if ok and tonumber(value) then count = math.max(0, math.floor(tonumber(value))) end
            end
            snapshot[item] = { count = count }
        end
    end
    return snapshot
end

local function ensureMeatBudget(carcass, player)
    local state = animalYieldByCarcass[carcass]
    if not state then state = {}; animalYieldByCarcass[carcass] = state end
    if state.meatRemaining == nil then
        state.meatTarget = chooseAnimalYield(carcass, player, "meat")
        state.meatRemaining = state.meatTarget
    end
    return state
end

local function capNewFoodToBudget(carcass, player, inventory, snapshot)
    local state = ensureMeatBudget(carcass, player)
    local addedFood = {}
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and instanceof(item, "Food") then
            local previous = snapshot[item]
            local previousCount = previous and previous.count or 0
            local currentCount = 1
            if type(item.getCount) == "function" then
                local ok, value = pcall(item.getCount, item)
                if ok and tonumber(value) then
                    currentCount = math.max(0, math.floor(tonumber(value)))
                end
            end
            local addedCount = math.max(0, currentCount - previousCount)
            if addedCount > 0 then
                addedFood[#addedFood + 1] = {
                    item = item,
                    addedCount = addedCount,
                    previousCount = previousCount,
                    currentCount = currentCount,
                }
            end
        end
    end

    local allowed = math.max(0, state.meatRemaining or 0)
    local kept = 0
    local removed = 0
    local unadjusted = 0
    for index = #addedFood, 1, -1 do
        local entry = addedFood[index]
        local item = entry.item
        local keepFromEntry = math.min(entry.addedCount, math.max(0, allowed - kept))
        local excess = entry.addedCount - keepFromEntry
        if excess <= 0 then
            kept = kept + keepFromEntry
        elseif type(item.setCount) == "function" then
            local targetCount = entry.previousCount + keepFromEntry
            local okSet = pcall(item.setCount, item, targetCount)
            if okSet then
                if targetCount <= 0 then
                    local okRemove = pcall(inventory.Remove, inventory, item)
                    if okRemove and type(sendRemoveItemFromContainer) == "function" then
                        pcall(sendRemoveItemFromContainer, inventory, item)
                    end
                elseif type(sendItemStats) == "function" then
                    pcall(sendItemStats, item)
                end
                kept = kept + keepFromEntry
                removed = removed + excess
            else
                kept = kept + entry.addedCount
                unadjusted = unadjusted + excess
            end
        else
            -- If an existing stack cannot be adjusted, preserve its old units and
            -- account for the excess as still present instead of deleting the stack.
            kept = kept + entry.addedCount
            unadjusted = unadjusted + excess
        end
    end
    state.meatRemaining = math.max(0, allowed - kept)
    state.meatProduced = (state.meatProduced or 0) + kept
    local mass = estimateAnimalMass and estimateAnimalMass(carcass) or 25
    local skill = player:getPerkLevel(Perks.Butchering)
        print("[ChilaSeda_AnimalBalance] MEAT_YIELD animal=" .. tostring(carcass:getAnimalType())
        .. " mass=" .. tostring(mass) .. " skill=" .. tostring(skill)
        .. " kept=" .. tostring(kept) .. " removed=" .. tostring(removed)
        .. " unadjusted=" .. tostring(unadjusted)
        .. " remaining=" .. tostring(state.meatRemaining) .. " target=" .. tostring(state.meatTarget))
end

local function selectedLootContainer(player, inventory)
    if not player or type(player.getPlayerNum) ~= "function" then return nil end
    local okPlayerNum, playerNum = pcall(player.getPlayerNum, player)
    if not okPlayerNum then return nil end
    if type(getPlayerInventory) == "function" then
        local okPage, page = pcall(getPlayerInventory, playerNum)
        local pane = okPage and page and page.inventoryPane
        local selected = pane and pane.inventory
        local main = okPage and page and page.inventory
        if selected and selected ~= inventory and selected ~= main then
            return selected, playerNum
        end
    end
    return nil, playerNum
end

local function canStoreIn(container, player, item)
    if not container or not player or not item then return false end
    local okAllowed, allowed = pcall(container.isItemAllowed, container, item)
    if not okAllowed or not allowed then return false end
    local okRoom, hasRoom = pcall(container.hasRoomFor, container, player, item)
    if not okRoom or not hasRoom then return false end
    local okWeight, currentWeight = pcall(container.getCapacityWeight, container)
    local okItem, itemWeight = pcall(item.getUnequippedWeight, item)
    local okCapacity, capacity = pcall(container.getEffectiveCapacity, container, player)
    return okWeight and okItem and okCapacity and currentWeight + itemWeight <= capacity
end

local function dropItemToFloor(player, inventory, item)
    -- Verify the returned world item; a successful pcall alone does not prove
    -- that the bone left the inventory.
    local square = nil
    if player and type(player.getCurrentSquare) == "function" then
        local okSquare, currentSquare = pcall(player.getCurrentSquare, player)
        if okSquare then square = currentSquare end
    end
    if not square or type(square.AddWorldInventoryItem) ~= "function" then
        return false
    end
    local okRemove = pcall(inventory.Remove, inventory, item)
    local okContainer, currentContainer = pcall(item.getContainer, item)
    if not okRemove or not okContainer or currentContainer == inventory then
        return false
    end
    if type(sendRemoveItemFromContainer) == "function" then
        sendRemoveItemFromContainer(inventory, item)
    end
    local ok, worldItem = pcall(square.AddWorldInventoryItem, square, item, 0.5, 0.5, 0)
    okContainer, currentContainer = pcall(item.getContainer, item)
    local okWorldObject, worldObject = pcall(item.getWorldItem, item)
    if ok and worldItem and okContainer and currentContainer ~= inventory
            and okWorldObject and worldObject then
        return true
    end
    pcall(inventory.AddItem, inventory, item)
    if type(sendAddItemToContainer) == "function" then
        sendAddItemToContainer(inventory, item)
    end
    return false
end

local function moveItemToContainer(inventory, destination, item)
    local okRemove = pcall(inventory.Remove, inventory, item)
    local okContainer, currentContainer = pcall(item.getContainer, item)
    if not okRemove or not okContainer or currentContainer == inventory then return false end
    if type(sendRemoveItemFromContainer) == "function" then
        sendRemoveItemFromContainer(inventory, item)
    end

    local okAdd = pcall(destination.AddItem, destination, item)
    local okContainer, itemContainer = pcall(item.getContainer, item)
    if okAdd and okContainer and itemContainer == destination then
        if type(sendAddItemToContainer) == "function" then
            sendAddItemToContainer(destination, item)
        end
        return true
    end
    local okRestore = pcall(inventory.AddItem, inventory, item)
    if okRestore and type(sendAddItemToContainer) == "function" then
        sendAddItemToContainer(inventory, item)
    end
    return false
end

local function moveNewItemsToSelectedContainer(player, inventory, snapshot)
    local destination = selectedLootContainer(player, inventory)
    local items = inventory:getItems()
    local movedToContainer, droppedToFloor, failed = 0, 0, 0
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and not snapshot[item] then
            local moved = false
            if destination and destination:getType() ~= "floor"
                    and canStoreIn(destination, player, item) then
                moved = moveItemToContainer(inventory, destination, item)
                if moved then movedToContainer = movedToContainer + 1 end
            end
            if not moved then
                moved = dropItemToFloor(player, inventory, item)
                if moved then droppedToFloor = droppedToFloor + 1 end
            end
            if not moved then
                failed = failed + 1
                print("[ChilaSeda_AnimalBalance] OUTPUT_TRANSFER_FAILED type="
                    .. tostring(item:getFullType()) .. " destination=floor")
            end
        end
    end
    if movedToContainer > 0 or droppedToFloor > 0 or failed > 0 then
        print("[ChilaSeda_AnimalBalance] OUTPUT_ROUTED container=" .. tostring(movedToContainer)
            .. " floor=" .. tostring(droppedToFloor) .. " failed=" .. tostring(failed))
        if HaloTextHelper and type(HaloTextHelper.addText) == "function" then
            local message
            if movedToContainer > 0 and droppedToFloor > 0 then
                message = "Carniceria: mochila seleccionada y piso"
            elseif movedToContainer > 0 then
                message = "Carniceria: mochila seleccionada"
            elseif droppedToFloor > 0 then
                message = "Carniceria: objetos en el piso"
            end
            if message then pcall(HaloTextHelper.addText, player, message, " ", 255, 220, 120) end
        end
    end
    return movedToContainer, droppedToFloor, failed
end

local function enforceBoneExtractionCaps(carcass, player, inventory, snapshot)
    local state = animalYieldByCarcass[carcass]
    if not state or state.boneTarget == nil then state = prepareBoneYield(carcass, player) end
    local totalCap = state.boneRemaining or state.boneTarget or 0
    local seenByType = {}
    local seenTotal = 0
    local keptTotal = 0
    local removed = 0
    local skullSeen = state.boneSkullProduced == true
    local items = inventory:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and not snapshot[item] then
            local fullType = item:getFullType()
            if isBoneType(fullType) then
                seenTotal = seenTotal + 1
                seenByType[fullType] = (seenByType[fullType] or 0) + 1
                local isSkull = string.find(string.lower(fullType), "skull", 1, true) ~= nil
                local extraSkull = isSkull and skullSeen
                if extraSkull or seenTotal > totalCap then
                    local okRemove = pcall(inventory.Remove, inventory, item)
                    local okContainer, container = pcall(item.getContainer, item)
                    if okRemove and okContainer and container ~= inventory then
                        if type(sendRemoveItemFromContainer) == "function" then
                            sendRemoveItemFromContainer(inventory, item)
                        end
                        removed = removed + 1
                    else
                        keptTotal = keptTotal + 1
                        if isSkull then skullSeen = true end
                    end
                else
                    keptTotal = keptTotal + 1
                    if isSkull then skullSeen = true end
                end
            end
        end
    end

    state.boneProduced = (state.boneProduced or 0) + keptTotal
    state.boneRemaining = math.max(0, (state.boneTarget or 0) - state.boneProduced)
    state.boneSkullProduced = skullSeen
    state.boneReserved = 0
    state.boneAllocations = nil
    state.boneAllocationsByType = nil
    local moved, dropped, failed = moveNewItemsToSelectedContainer(player, inventory, snapshot)
    local counts = {}
    for fullType, count in pairs(seenByType) do
        counts[#counts + 1] = fullType .. ":" .. tostring(count)
    end
    table.sort(counts)
    local mass = estimateAnimalMass and estimateAnimalMass(carcass) or 25
    local skill = player:getPerkLevel(Perks.Butchering)
    print("[ChilaSeda_AnimalBalance] BONES_FINALIZED removed=" .. tostring(removed)
        .. " animal=" .. tostring(carcass:getAnimalType()) .. " mass=" .. tostring(mass)
        .. " skill=" .. tostring(skill)
        .. " total=" .. tostring(state.boneProduced) .. " target=" .. tostring(state.boneTarget)
        .. " counts=" .. table.concat(counts, ",")
        .. " routedContainer=" .. tostring(moved or 0) .. " routedFloor=" .. tostring(dropped or 0)
        .. " routeFailed=" .. tostring(failed or 0))
end

local function withBoneExtraction(carcass, player, operation)
    if not carcass or not player then return operation() end
    if activeBoneExtraction[carcass] then return operation() end

    local inventory = player:getInventory()
    local snapshot = inventory and snapshotInventory(inventory)
    if not inventory or not snapshot then return operation() end

    prepareBoneYield(carcass, player)
    activeBoneExtraction[carcass] = true
    local ok, result = pcall(operation)
    activeBoneExtraction[carcass] = nil
    enforceBoneExtractionCaps(carcass, player, inventory, snapshot)
    if not ok then error(result, 0) end
    return result
end

local wrappedActionOutput = {}
local function wrapActionOutput(actionClass, handlesBones)
    if not actionClass or type(actionClass.complete) ~= "function"
            or wrappedActionOutput[actionClass] then return end
    local originalComplete = actionClass.complete
    local routedComplete = function(self, ...)
        local player = self.character
        local inventory = player and player:getInventory()
        if handlesBones then
            local carcass = self.body or self.animal or self.corpse
            local args = { ... }
            local argCount = select("#", ...)
            return withBoneExtraction(carcass, player, function()
                return originalComplete(self, unpack(args, 1, argCount))
            end)
        end
        local before = inventory and snapshotInventory(inventory)
        local result = originalComplete(self, ...)
        if inventory and before then
            moveNewItemsToSelectedContainer(player, inventory, before)
        end
        return result
    end
    actionClass.complete = routedComplete
    wrappedActionOutput[actionClass] = true
end

local function clonePart(part)
    local result = {}
    for key, value in pairs(part) do result[key] = value end
    return result
end

local function randomizeZombieFood(item)
    local fresh = item:getOffAge()
    local rotten = item:getOffAgeMax()
    if type(fresh) ~= "number" or type(rotten) ~= "number" or rotten <= fresh then return end

    local roll = ZombRand(100)
    local age
    if roll < 25 then
        age = ZombRandFloat(0, math.max(0.01, fresh * 0.4))
    elseif roll < 50 then
        age = ZombRandFloat(math.max(0, fresh * 0.7), fresh)
    elseif roll < 75 then
        age = ZombRandFloat(fresh, rotten)
    else
        age = ZombRandFloat(rotten + 0.01, rotten + math.max(0.1, rotten * 0.5))
    end
    item:setAge(age)
    if type(sendItemStats) == "function" then sendItemStats(item) end
end

local carryWeightByAnimal = {
    chick = 0.20,
    hen = 4.50,
    cockerel = 4.50,
    mousepups = 0.10,
    mousefemale = 0.10,
    mouse = 0.12,
    ratbaby = 0.40,
    ratfemale = 0.50,
    rat = 0.70,
    rabkitten = 1.67,
    rabdoe = 4.00,
    rabbuck = 4.00,
    raccoonkit = 8.80,
    raccoonsow = 11.66,
    raccoonboar = 12.50,
    turkeypoult = 0.30,
    turkeyhen = 8.18,
    gobblers = 10.90,
    cowcalf = 291.67,
    cow = 863.64,
    bull = 1181.82,
    piglet = 91.67,
    sow = 304.35,
    boar = 304.35,
    lamb = 46.67,
    ewe = 92.31,
    ram = 153.85,
    fawn = 83.33,
    doe = 166.67,
    buck = 166.67,
}

local carryWeightSources = {
    infectedraccoon = "raccoonboar",
    infectedcockerel = "cockerel",
    infectedchicken = "hen",
    infectedturkey = "turkeyhen",
    infectedrabbit = "rabdoe",
    infectedpiglet = "piglet",
    infectedfarmpig = "sow",
    infecteddeerdoe = "doe",
    infecteddeerstag = "buck",
    infectedcow = "cow",
    infectedcowcalf = "cowcalf",
    infectedbull = "bull",
    infectedewe = "ewe",
    infectedram = "ram",
    infectedlamb = "lamb",
    infectedrat = "rat",
    undeadraccoon = "raccoonboar",
    undeadcockerel = "cockerel",
    undeadcockerelnohead = "cockerel",
    undeadchicken = "hen",
    undeadchickennohead = "hen",
    undeadturkey = "turkeyhen",
    undeadturkeynohead = "turkeyhen",
    undeadrabbit = "rabdoe",
    undeadpiglet = "piglet",
    undeadpig = "sow",
    undeadfarmpig = "sow",
    undeaddeerdoe = "doe",
    undeaddeerstag = "buck",
    undeadcow = "cow",
    undeadcownohead = "cow",
    undeadcowcalf = "cowcalf",
    undeadcalfnohead = "cowcalf",
    undeadbull = "bull",
    undeadbullnohead = "bull",
    undeadewe = "ewe",
    undeadewenohead = "ewe",
    undeadram = "ram",
    undeadramnohead = "ram",
    undeadlamb = "lamb",
    undeadlambnohead = "lamb",
    undeadrat = "rat",
    undeadratnohead = "rat",
    undeadturkeypoult = "turkeypoult",
    undeadturkeypoultnohead = "turkeypoult",
    undeadfawn = "fawn",
    undeadfawnnohead = "fawn",
    undeadrabkitten = "rabkitten",
    undeadrabkittennohead = "rabkitten",
    undeaddeerdoefullhead = "doe",
    undeaddeerstagfullhead = "buck",
    undeadrabbitnohead = "rabdoe",
    undeadfarmpigletfullhead = "piglet",
    undeadraccoonnohead = "raccoonboar",
    hewildboar = "boar",
    hewildsow = "sow",
    hewildpiglet = "piglet",
}

estimateAnimalMass = function(carcass)
    local animalDefinitions = AnimalDefinitions and AnimalDefinitions.animals
    if not animalDefinitions or not carcass then return 25 end
    local okKind, kind = pcall(carcass.getAnimalType, carcass)
    if (not okKind or type(kind) ~= "string" or kind == "none")
            and type(carcass.getModData) == "function" then
        local okData, data = pcall(carcass.getModData, carcass)
        if okData and data then kind = data.AnimalType or data.animalType end
    end
    if type(kind) ~= "string" or kind == "" or kind == "none" then return 25 end

    local definition = animalDefinitions[kind]
    local source = carryWeightSources[kind]
    if not definition and source then definition = animalDefinitions[source] end
    if not definition then
        local stripped = string.gsub(kind, "^infected", "")
        stripped = string.gsub(stripped, "^undead", "")
        local aliases = {
            rabbit = "rabdoe", chicken = "hen", deerdoe = "doe", deerstag = "buck",
            deer = "doe", sheep = "ewe", goat = "goat", pig = "sow",
            cow = "cow", calf = "cowcalf", turkey = "turkeyhen",
        }
        definition = animalDefinitions[stripped] or animalDefinitions[aliases[stripped]]
    end

    local minimum = definition and tonumber(definition.minWeight)
    local maximum = definition and tonumber(definition.maxWeight)
    if minimum and maximum and minimum >= 0 and maximum >= minimum then
        return (minimum + maximum) * 0.5
    end
    if minimum and minimum >= 0 then return minimum end
    if maximum and maximum >= 0 then return maximum end
    local normalizedKind = string.lower(kind)
    normalizedKind = string.gsub(normalizedKind, "^infected", "")
    normalizedKind = string.gsub(normalizedKind, "^undead", "")
    if string.find(normalizedKind, "mouse", 1, true)
            or string.find(normalizedKind, "rat", 1, true) then return 0.5 end
    if string.find(normalizedKind, "rabbit", 1, true)
            or string.find(normalizedKind, "chick", 1, true)
            or string.find(normalizedKind, "quail", 1, true)
            or string.find(normalizedKind, "poult", 1, true) then return 4 end
    if string.find(normalizedKind, "calf", 1, true)
            or string.find(normalizedKind, "lamb", 1, true)
            or string.find(normalizedKind, "piglet", 1, true)
            or string.find(normalizedKind, "fawn", 1, true) then return 50 end
    if string.find(normalizedKind, "cow", 1, true)
            or string.find(normalizedKind, "bull", 1, true)
            or string.find(normalizedKind, "bison", 1, true) then return 500 end
    if string.find(normalizedKind, "turkey", 1, true) then return 10 end
    if string.find(normalizedKind, "deer", 1, true)
            or string.find(normalizedKind, "sheep", 1, true)
            or string.find(normalizedKind, "ewe", 1, true)
            or string.find(normalizedKind, "ram", 1, true)
            or string.find(normalizedKind, "goat", 1, true)
            or string.find(normalizedKind, "pig", 1, true)
            or string.find(normalizedKind, "boar", 1, true) then return 120 end
    return 25
end

prepareBoneYield = function(carcass, player)
    local state = animalYieldByCarcass[carcass]
    if not state then state = {}; animalYieldByCarcass[carcass] = state end
    if state.boneTarget == nil then
        state.boneTarget = chooseAnimalYield(carcass, player, "bone")
        state.boneProduced = 0
    end
    state.boneRemaining = math.max(0, state.boneTarget - (state.boneProduced or 0))
    state.boneReserved = 0
    state.boneAllocations = {}
    state.boneAllocationsByType = {}
    animalYieldByCarcass[carcass] = state

    local modData = carcass and carcass:getModData()
    local skull = (not modData or not modData.headless)
        and ButcheringUtil.getSkull(ButcheringUtil.getCarcassName(carcass))
    local available = math.max(0, state.boneRemaining - (skull and not state.boneSkullProduced and 1 or 0))
    local parts = ButcheringUtil.getAllBonesDef(ButcheringUtil.getCarcassName(carcass)) or {}
    local weightedParts, totalWeight = {}, 0
    for _, part in pairs(parts) do
        local minimum = tonumber(part.minNb)
        local maximum = tonumber(part.maxNb)
        local weight = tonumber(part.nb)
        if not weight or weight < 0 then
            weight = (math.max(0, minimum or 1) + math.max(0, maximum or minimum or 1)) * 0.5
        end
        weight = math.max(0.01, weight)
        weightedParts[#weightedParts + 1] = { part = part, weight = weight }
        totalWeight = totalWeight + weight
    end

    local allocated = 0
    for _, entry in ipairs(weightedParts) do
        local exact = totalWeight > 0 and available * entry.weight / totalWeight or 0
        entry.count = math.floor(exact)
        entry.remainder = exact - entry.count
        allocated = allocated + entry.count
        state.boneAllocations[entry.part] = entry.count
        local itemType = entry.part.item
        state.boneAllocationsByType[itemType] = (state.boneAllocationsByType[itemType] or 0) + entry.count
    end
    table.sort(weightedParts, function(left, right) return left.remainder > right.remainder end)
    for index = 1, available - allocated do
        local entry = weightedParts[index]
        if entry then
            state.boneAllocations[entry.part] = state.boneAllocations[entry.part] + 1
            local itemType = entry.part.item
            state.boneAllocationsByType[itemType] = state.boneAllocationsByType[itemType] + 1
        end
    end
    return state
end

local function applyAnimalCarryWeights()
    local animals = AnimalDefinitions and AnimalDefinitions.animals
    if not animals then return end
    for kind, encumbrance in pairs(carryWeightByAnimal) do
        local definition = animals[kind]
        if definition then definition.baseEncumbrance = encumbrance end
    end
    for kind, source in pairs(carryWeightSources) do
        local definition = animals[kind]
        local sourceDefinition = animals[source]
        local encumbrance = carryWeightByAnimal[source]
            or (sourceDefinition and sourceDefinition.baseEncumbrance)
        if definition and encumbrance then
            definition.baseEncumbrance = encumbrance
        end
    end
end

-- Run during shared-Lua registration so copied definitions receive the target
-- before the animal registry is finalized, then repeat on game boot.
applyAnimalCarryWeights()

local installed = false
local function install()
    if installed then return end
    local originalAddAnimalPart = ButcheringUtil.addAnimalPart
    if type(originalAddAnimalPart) ~= "function" then
        print("[ChilaSeda_AnimalBalance] addAnimalPart unavailable; yield hook skipped")
        return
    end
    installed = true
    applyAnimalCarryWeights()

    local originalButcherAnimalFromGround = ButcheringUtil.butcherAnimalFromGround
    if type(originalButcherAnimalFromGround) == "function" then
        ButcheringUtil.butcherAnimalFromGround = function(carcass, player, keepCorpse)
            return withBoneExtraction(carcass, player, function()
                return originalButcherAnimalFromGround(carcass, player, keepCorpse)
            end)
        end
    end

    local originalGetAnimalBones = ButcheringUtil.getAnimalBones
    if type(originalGetAnimalBones) == "function" then
        ButcheringUtil.getAnimalBones = function(carcass, player)
            return withBoneExtraction(carcass, player, function()
                return originalGetAnimalBones(carcass, player)
            end)
        end
    end

    local function callOriginalAddAnimalPart(part, player, carcass, fromGround)
        local fixes = ChilaSeda_AnimalBalance_UndeadWildlife
        local withVanillaAvatar = fixes and fixes.withVanillaAvatar
        local operation = function()
            return originalAddAnimalPart(part, player, carcass, fromGround)
        end
        if type(withVanillaAvatar) == "function" then
            return withVanillaAvatar(carcass, operation)
        end
        return operation()
    end
    ButcheringUtil.addAnimalPart = function(part, player, carcass, fromGround)
        if not part or not carcass or not player then
            return callOriginalAddAnimalPart(part, player, carcass, fromGround)
        end

        local kind = carcass:getAnimalType()
        local undeadWildlifeAnimal = isUndeadWildlifeAnimal(kind)
        local foodPart = part.item and instanceof(instanceItem(part.item), "Food")
        local adjustedPart = part
        local partType = part.item
        local meatDefinition = type(partType) == "string" and (
            (AnimalPartsDefinitions and AnimalPartsDefinitions.meat
                and AnimalPartsDefinitions.meat[partType]) or
            string.find(string.lower(partType), "meat", 1, true) or
            string.find(string.lower(partType), "steak", 1, true)
        )
        if undeadWildlifeAnimal and foodPart and meatDefinition then
            local multiplier = tonumber(undeadWildlifeMeatYield[string.lower(kind)])
            if multiplier and multiplier < 1 then
                adjustedPart = clonePart(part)
                for _, key in ipairs({ "nb", "minNb", "maxNb" }) do
                    local amount = tonumber(part[key])
                    if amount and amount > 1 then
                        adjustedPart[key] = math.max(1, math.floor(amount * multiplier))
                    end
                end
            end
        end
        local partCopy = nil
        local inventory = player:getInventory()
        local beforeItems = snapshotInventory(inventory)

        if foodPart then
            local yieldState = ensureMeatBudget(carcass, player)
            if yieldState.meatRemaining <= 0 then return "" end
            partCopy = clonePart(adjustedPart)
            local requested = tonumber(adjustedPart.nb)
            if requested == nil or requested < 0 then
                partCopy.nb = yieldState.meatRemaining
            else
                partCopy.nb = math.min(math.floor(requested), yieldState.meatRemaining)
            end
        elseif isBoneType(part.item) then
            partCopy = clonePart(part)
            partCopy.nb = limitedBoneCount(part, carcass, player)
            if partCopy.nb < 1 then return "" end
        end

        if not partCopy then
            local result = callOriginalAddAnimalPart(part, player, carcass, fromGround)
            if not activeBoneExtraction[carcass] then
                moveNewItemsToSelectedContainer(player, inventory, beforeItems)
            end
            return result
        end

        local result = callOriginalAddAnimalPart(partCopy, player, carcass, fromGround)

        if undeadWildlifeAnimal and foodPart then
            local items = inventory:getItems()
            for i = items:size() - 1, 0, -1 do
                local item = items:get(i)
                if item and not beforeItems[item] and instanceof(item, "Food") then
                    randomizeZombieFood(item)
                end
            end
        end
        if foodPart then
            capNewFoodToBudget(carcass, player, inventory, beforeItems)
        end
        if not activeBoneExtraction[carcass] then
            if isBoneType(part.item) then
                enforceBoneExtractionCaps(carcass, player, inventory, beforeItems)
            else
                moveNewItemsToSelectedContainer(player, inventory, beforeItems)
            end
        end
        return result
    end

    wrapActionOutput(ISRemoveHeadFromAnimal, true)
    wrapActionOutput(ISRemoveLeatherFromAnimal)
    wrapActionOutput(ISRemoveMeatFromAnimal, true)

    local hasUndeadWildlife = type(UndeadWildlife) == "table"
        and type(UndeadWildlife.HostileTypes) == "table"
    print("[ChilaSeda_AnimalBalance] v2.0.0 yield/routing installed; Undead Wildlife="
        .. tostring(hasUndeadWildlife))
end

Events.OnGameBoot.Add(install)
