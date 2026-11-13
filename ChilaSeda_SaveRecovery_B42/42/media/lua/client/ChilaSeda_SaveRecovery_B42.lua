local Recovery = {}

local MOD_ID = "ChilaSeda_SaveRecovery_B42"
local PLAYER_FLAG = "ChilaSeda_SaveRecovery_B42_done"
local BAG_FLAG = "ChilaSeda_SaveRecovery_B42_bag"
local BAG_TYPE = "KnoxPacks.KP_Bag_FieldRuck"
local BAG_NAME = "Fina Mochila de campaña"
local MAX_WAIT_TICKS = 300

local backupContents = {
    { "Base.Plantain", 4 },
    { "Base.Millipede2", 1 },
    { "Base.Termites", 1 },
    { "Base.SilkMothCaterpillar", 1 },
    { "Base.MonarchCaterpillar", 1 },
    { "Base.Egg", 6 },
    { "Base.Pumpkin", 1 },
    { "Base.LargeAnimalBone", 3 },
    { "Base.LetterOpener", 1 },
    { "Base.Pot", 2 },
    { "Base.CarvingFork2", 1 },
    { "Base.TreeBranch2", 1 },
    { "Base.CarBatteryCharger", 1 },
    { "Base.ClosedUmbrellaWhite", 1 },
    { "Base.TorchArmy2", 1 },
    { "Base.Comfrey", 3 },
    { "Base.Hops", 1 },
    { "Base.Rosemary", 1 },
    { "Base.SugarBeet", 1 },
    { "Base.MushroomGeneric3", 1 },
    { "Base.Socks_Long", 1 },
    { "Base.Shoes_TrainerTINT", 1 },
    { "AuthenticZClothing.Dress_Short2", 1 },
    { "Base.Briefs_SmallTrunks_Red", 1 },
    { "Base.Socks_Ankle", 1 },
    { "Base.Trousers_DefaultTEXTURE", 1 },
    { "Base.Vest_DefaultTEXTURE_TINT", 1 },
    { "Base.Shoes_WorkBoots", 1 },
    { "Base.MushroomGeneric7", 1 },
    { "Base.MuttonChop", 7 },
    { "Base.AnimalSinew", 2 },
    { "Base.AMR_Head_Sheep_Icelandic_Ram_V2_ram", 1 },
}

local laterMeatReplacement = {
    { "Base.ChickenWhole", 1 },
    { "Base.ChickenFoot", 2 },
    { "Base.SmallAnimalBone", 5 },
    { "Base.Venison", 3 },
    { "Base.Steak", 3 },
    { "Base.Beef", 3 },
    { "Base.AnimalBone", 6 },
    { "Base.LargeAnimalBone", 4 },
    { "Base.Salt", 2 },
}

local function log(message)
    print("[" .. MOD_ID .. "] " .. tostring(message))
end

local function hasRecoveryBag(square)
    local worldObjects = square:getWorldObjects()
    if not worldObjects then return false end

    for index = 0, worldObjects:size() - 1 do
        local worldObject = worldObjects:get(index)
        local item = worldObject and worldObject:getItem() or nil
        if item and item:getFullType() == BAG_TYPE then
            local itemData = item:getModData()
            if itemData and itemData[BAG_FLAG] == true then return true end
        end
    end

    return false
end

local function addContents(container, definitions)
    for _, definition in ipairs(definitions) do
        local fullType = definition[1]
        local amount = definition[2]

        for _ = 1, amount do
            local item = InventoryItemFactory.CreateItem(fullType)
            if not item then
                error("Item unavailable: " .. fullType)
            end
            container:AddItem(item)
        end
    end
end

local function makeRecoveryBag()
    local bag = InventoryItemFactory.CreateItem(BAG_TYPE)
    if not bag then error("Item unavailable: " .. BAG_TYPE) end

    bag:setName(BAG_NAME)
    bag:setCustomName(true)

    local visual = bag:getVisual()
    if visual then
        -- KnoxPacks FieldRuck texture choices: Olive Drab=0, Desert Tan=1, Black=2.
        visual:setTextureChoice(1)
        bag:synchWithVisual()
    end

    local container = bag:getItemContainer()
    if not container then error("FieldRuck has no item container") end

    addContents(container, backupContents)
    addContents(container, laterMeatReplacement)
    bag:getModData()[BAG_FLAG] = true
    return bag
end

local function finishPlayer(player, square)
    local playerData = player:getModData()
    if playerData[PLAYER_FLAG] == true then return true end
    if hasRecoveryBag(square) then
        playerData[PLAYER_FLAG] = true
        log("Existing recovery bag found at player square; skipped duplicate.")
        return true
    end

    local ok, bagOrError = pcall(makeRecoveryBag)
    if not ok then
        log("Could not build recovery bag: " .. tostring(bagOrError))
        return false
    end

    local okPlace, placedOrError = pcall(function()
        return square:AddWorldInventoryItem(bagOrError, 0.5, 0.5, 0.0)
    end)
    if not okPlace or not placedOrError then
        log("Could not place recovery bag at player feet: " .. tostring(placedOrError))
        return false
    end

    playerData[PLAYER_FLAG] = true
    log("Spawned one Desert Tan FieldRuck with DEAD contents and raw meat replacement at Jill's feet.")
    return true
end

local pending = {}
local waitTicks = 0

local function onTick()
    waitTicks = waitTicks + 1
    local hasPending = false

    for playerNum, player in pairs(pending) do
        if not player then player = getSpecificPlayer(playerNum) end
        if player and player:getModData()[PLAYER_FLAG] == true then
            pending[playerNum] = nil
        else
            local square = player and player:getCurrentSquare() or nil
            if square and finishPlayer(player, square) then
                pending[playerNum] = nil
            else
                pending[playerNum] = player
                hasPending = true
            end
        end
    end

    if not hasPending and next(pending) == nil then
        Events.OnTick.Remove(onTick)
    elseif waitTicks >= MAX_WAIT_TICKS then
        log("Player square was not ready; no items were spawned. Reload Jill to retry.")
        pending = {}
        Events.OnTick.Remove(onTick)
    end
end

local function onCreatePlayer(playerNum, player)
    if isClient() or playerNum ~= 0 then return end
    if not player then player = getSpecificPlayer(playerNum) end
    if player and player:getModData()[PLAYER_FLAG] == true then return end

    pending[playerNum] = player
    waitTicks = 0
    Events.OnTick.Remove(onTick)
    Events.OnTick.Add(onTick)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
