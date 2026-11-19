require "TimedActions/ISTimedActionQueue"
if not ISTimedActionQueue then
    print("[ChilaSeda_ViewpointActionProgress] timed-action queue unavailable; patch skipped.")
    return
end

local FLAG = "_ChilaSeda_ViewpointActionProgress"
local sharedProgressBar = nil
local currentProgressAction = nil
local suppressedNativeAction = nil
local trackedActions = setmetatable({}, { __mode = "k" })
local activationLogged = {}
local customBarDrawLogged = false
local customBarDrawnThisFrame = false
local customBarDrawFailureLogged = false
local nativeFallbackLogged = false
local MIN_PROGRESS_HEIGHT = 3
local ORANGE_PROGRESS = { r = 1.00, g = 0.40, b = 0.06, a = 1.00 }
local REQUIRED_CUSTOM_BAR_ACTIONS = {
    ISDismantleAction = true,
    ISDrinkFluidAction = true,
    -- Vanilla disables this action's own bar in ISForageAction:start().
    ISForageAction = true,
    ISButcherAnimal = true,
    ISTakeWaterAction = true,
    ISCleanBandageAccessible = true,
    ISChilaSedaFatCombine = true,
}
local requiredBarTraceCount = {}

local function localizedText(key)
    if type(getText) ~= "function" then return key end
    local ok, value = pcall(getText, key)
    if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    return key
end

local function localizedFormat(key, ...)
    local value = localizedText(key)
    for index, replacement in ipairs({...}) do
        value = value:gsub("%%" .. index, function() return tostring(replacement) end)
    end
    return value
end

local ACTION_LABELS = {
    -- Acciones de animales y naturaleza
    ISButcherAnimal = "UI_ChilaSeda_ViewpointActionLabel_ISButcherAnimal",
    ISDismantleAction = "UI_ChilaSeda_ViewpointActionLabel_ISDismantleAction",
    ISGetAnimalBones = "UI_ChilaSeda_ViewpointActionLabel_ISGetAnimalBones",
    ISBuryCorpse = "UI_ChilaSeda_ViewpointActionLabel_ISBuryCorpse",
    ISChopTreeAction = "UI_ChilaSeda_ViewpointActionLabel_ISChopTreeAction",
    ISFishingAction = "UI_ChilaSeda_ViewpointActionLabel_ISFishingAction",
    ISGrabCorpseAction = "UI_ChilaSeda_ViewpointActionLabel_ISGrabCorpseAction",
    ISRemoveBush = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveBush",
    ISSeedFlowerAction = "UI_ChilaSeda_ViewpointActionLabel_ISSeedFlowerAction",
    ISShovelGround = "UI_ChilaSeda_ViewpointActionLabel_ISShovelGround",
    ISWaterPlantAction = "UI_ChilaSeda_ViewpointActionLabel_ISWaterPlantAction",
    -- Acciones de crafting y construccion
    ISBBQLightFromKindle = "UI_ChilaSeda_ViewpointActionLabel_ISBBQLightFromKindle",
    ISBBQLightFromLiterature = "UI_ChilaSeda_ViewpointActionLabel_ISBBQLightFromLiterature",
    ISBBQLightFromPetrol = "UI_ChilaSeda_ViewpointActionLabel_ISBBQLightFromPetrol",
    ISLightFromKindle = "UI_ChilaSeda_ViewpointActionLabel_ISLightFromKindle",
    ISLightFromLiterature = "UI_ChilaSeda_ViewpointActionLabel_ISLightFromLiterature",
    ISLightFromLiteratura = "UI_ChilaSeda_ViewpointActionLabel_ISLightFromLiteratura",
    ISLightFromPetrol = "UI_ChilaSeda_ViewpointActionLabel_ISLightFromPetrol",
    ISBBQAddFuel = "UI_ChilaSeda_ViewpointActionLabel_ISBBQAddFuel",
    ISBBQExtinguish = "UI_ChilaSeda_ViewpointActionLabel_ISBBQExtinguish",
    ISBBQToggle = "UI_ChilaSeda_ViewpointActionLabel_ISBBQToggle",
    ISBBQInsertPropaneTank = "UI_ChilaSeda_ViewpointActionLabel_ISBBQInsertPropaneTank",
    ISBBQRemovePropaneTank = "UI_ChilaSeda_ViewpointActionLabel_ISBBQRemovePropaneTank",
    ISPickupFishAction = "UI_ChilaSeda_ViewpointActionLabel_ISPickupFishAction",
    ISAddBaitToFishNetAction = "UI_ChilaSeda_ViewpointActionLabel_ISAddBaitToFishNetAction",
    ISRemoveFishingNetAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveFishingNetAction",
    ISPlaceFishingNetAction = "UI_ChilaSeda_ViewpointActionLabel_ISPlaceFishingNetAction",
    ISCheckFishingNetAction = "UI_ChilaSeda_ViewpointActionLabel_ISCheckFishingNetAction",
    ISChangeFishingRodEquip = "UI_ChilaSeda_ViewpointActionLabel_ISChangeFishingRodEquip",
    AIAttachLureAction = "UI_ChilaSeda_ViewpointActionLabel_AIAttachLureAction",
    AIRemoveLureAction = "UI_ChilaSeda_ViewpointActionLabel_AIRemoveLureAction",
    AddChumToWaterAction = "UI_ChilaSeda_ViewpointActionLabel_AddChumToWaterAction",
    CreateChumFromGroundSandAction = "UI_ChilaSeda_ViewpointActionLabel_CreateChumFromGroundSandAction",
    ISBuildAction = "UI_ChilaSeda_ViewpointActionLabel_ISBuildAction",
    ISCookAction = "UI_ChilaSeda_ViewpointActionLabel_ISCookAction",
    ISCraftAction = "UI_ChilaSeda_ViewpointActionLabel_ISCraftAction",
    ISFireplaceAction = "UI_ChilaSeda_ViewpointActionLabel_ISFireplaceAction",
    ISHandcraftAction = "UI_ChilaSeda_ViewpointActionLabel_ISHandcraftAction",
    ISPlaceCampfireAction = "UI_ChilaSeda_ViewpointActionLabel_ISPlaceCampfireAction",
    ISPlaceItemAction = "UI_ChilaSeda_ViewpointActionLabel_ISPlaceItemAction",
    ISPrepareSoup = "UI_ChilaSeda_ViewpointActionLabel_ISPrepareSoup",
    ISPrepareStew = "UI_ChilaSeda_ViewpointActionLabel_ISPrepareStew",
    ISPutOutCampfireAction = "UI_ChilaSeda_ViewpointActionLabel_ISPutOutCampfireAction",
    ISStartFireAction = "UI_ChilaSeda_ViewpointActionLabel_ISStartFireAction",
    ["put out campfire"] = "UI_ChilaSeda_ViewpointActionLabel_put_out_campfire",
    -- Acciones de inventario y transferencia
    ISDetachItemHotbar = "UI_ChilaSeda_ViewpointActionLabel_ISDetachItemHotbar",
    ISDropItemAction = "UI_ChilaSeda_ViewpointActionLabel_ISDropItemAction",
    ISDumpWaterAction = "UI_ChilaSeda_ViewpointActionLabel_ISDumpWaterAction",
    ISForageAction = "UI_ChilaSeda_ViewpointActionLabel_ISForageAction",
    ISGrabItemAction = "UI_ChilaSeda_ViewpointActionLabel_ISGrabItemAction",
    ISWalkToCursorTimedAction = "UI_ChilaSeda_ViewpointActionLabel_ISWalkToCursorTimedAction",
    ISPickUpGroundCoverItem = "UI_ChilaSeda_ViewpointActionLabel_ISPickUpGroundCoverItem",
    ISInventoryTransferAction = "UI_ChilaSeda_ViewpointActionLabel_ISInventoryTransferAction",
    ISOpenContainerAction = "UI_ChilaSeda_ViewpointActionLabel_ISOpenContainerAction",
    ISOpenMechanicsUIAction = "UI_ChilaSeda_ViewpointActionLabel_ISOpenMechanicsUIAction",
    ISPourInAction = "UI_ChilaSeda_ViewpointActionLabel_ISPourInAction",
    ISPourOutAction = "UI_ChilaSeda_ViewpointActionLabel_ISPourOutAction",
    ISRemoveItemAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveItemAction",
    ISStoreItemAction = "UI_ChilaSeda_ViewpointActionLabel_ISStoreItemAction",
    ISThrowAction = "UI_ChilaSeda_ViewpointActionLabel_ISThrowAction",
    ISTransferWaterAction = "UI_ChilaSeda_ViewpointActionLabel_ISTransferWaterAction",
    ISUnpackAction = "UI_ChilaSeda_ViewpointActionLabel_ISUnpackAction",
    ISUnpackContainer = "UI_ChilaSeda_ViewpointActionLabel_ISUnpackContainer",
    -- Acciones de ropa y salud
    ISApplyBandage = "UI_ChilaSeda_ViewpointActionLabel_ISApplyBandage",
    ISCleanBandage = "UI_ChilaSeda_ViewpointActionLabel_ISCleanBandage",
    ISCleanBandageAccessible = "UI_ChilaSeda_ViewpointActionLabel_ISCleanBandageAccessible",
    ISCleanBandageInRain = "UI_ChilaSeda_ViewpointActionLabel_ISCleanBandageInRain",
    ISDrinkFluidAction = "UI_ChilaSeda_ViewpointActionLabel_ISDrinkFluidAction",
    ISDryMyself = "UI_ChilaSeda_ViewpointActionLabel_ISDryMyself",
    ISEatFoodAction = "UI_ChilaSeda_ViewpointActionLabel_ISEatFoodAction",
    ISEquipWeaponAction = "UI_ChilaSeda_ViewpointActionLabel_ISEquipWeaponAction",
    ISInsertClothingPadAction = "UI_ChilaSeda_ViewpointActionLabel_ISInsertClothingPadAction",
    ISRemoveClothingPadAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveClothingPadAction",
    ISRemovePatch = "UI_ChilaSeda_ViewpointActionLabel_ISRemovePatch",
    ISRepairClothing = "UI_ChilaSeda_ViewpointActionLabel_ISRepairClothing",
    ISPlantainCataplasm = "UI_ChilaSeda_ViewpointActionLabel_ISPlantainCataplasm",
    ISStitch = "UI_ChilaSeda_ViewpointActionLabel_ISStitch",
    ISSutureAction = "UI_ChilaSeda_ViewpointActionLabel_ISSutureAction",
    ISTakePillAction = "UI_ChilaSeda_ViewpointActionLabel_ISTakePillAction",
    ISTakeWaterAction = "UI_ChilaSeda_ViewpointActionLabel_ISTakeWaterAction",
    ISUnequipAction = "UI_ChilaSeda_ViewpointActionLabel_ISUnequipAction",
    ISWashClothing = "UI_ChilaSeda_ViewpointActionLabel_ISWashClothing",
    ISWashYourself = "UI_ChilaSeda_ViewpointActionLabel_ISWashYourself",
    ISWearClothing = "UI_ChilaSeda_ViewpointActionLabel_ISWearClothing",
    -- Acciones de estructuras e interaccion
    ISAddSheetAction = "UI_ChilaSeda_ViewpointActionLabel_ISAddSheetAction",
    ISBarricadeAction = "UI_ChilaSeda_ViewpointActionLabel_ISBarricadeAction",
    ISClimbOverFence = "UI_ChilaSeda_ViewpointActionLabel_ISClimbOverFence",
    ISClimbOverWall = "UI_ChilaSeda_ViewpointActionLabel_ISClimbOverWall",
    ISClimbSheetRope = "UI_ChilaSeda_ViewpointActionLabel_ISClimbSheetRope",
    ISClimbThroughWindow = "UI_ChilaSeda_ViewpointActionLabel_ISClimbThroughWindow",
    ISCloseCurtainAction = "UI_ChilaSeda_ViewpointActionLabel_ISCloseCurtainAction",
    ISDefeatCrawlingZombieAction = "UI_ChilaSeda_ViewpointActionLabel_ISDefeatCrawlingZombieAction",
    ISDestroyStuffAction = "UI_ChilaSeda_ViewpointActionLabel_ISDestroyStuffAction",
    ISDigGravesAction = "UI_ChilaSeda_ViewpointActionLabel_ISDigGravesAction",
    ISEmptyGraves = "UI_ChilaSeda_ViewpointActionLabel_ISEmptyGraves",
    ISFillGrave = "UI_ChilaSeda_ViewpointActionLabel_ISFillGrave",
    ISOpenDoor = "UI_ChilaSeda_ViewpointActionLabel_ISOpenDoor",
    ISPaintAction = "UI_ChilaSeda_ViewpointActionLabel_ISPaintAction",
    ISPickupBrokenGlass = "UI_ChilaSeda_ViewpointActionLabel_ISPickupBrokenGlass",
    ISRemoveBrokenGlass = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveBrokenGlass",
    ISPlumbItem = "UI_ChilaSeda_ViewpointActionLabel_ISPlumbItem",
    ISRemoveGlassAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveGlassAction",
    ISRemoveInsulationAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveInsulationAction",
    ISRemoveSheetAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveSheetAction",
    ISSawAction = "UI_ChilaSeda_ViewpointActionLabel_ISSawAction",
    ISSmashWindow = "UI_ChilaSeda_ViewpointActionLabel_ISSmashWindow",
    ISToggleLightAction = "UI_ChilaSeda_ViewpointActionLabel_ISToggleLightAction",
    ISToggleStoveAction = "UI_ChilaSeda_ViewpointActionLabel_ISToggleStoveAction",
    ISToggleWashingMachine = "UI_ChilaSeda_ViewpointActionLabel_ISToggleWashingMachine",
    ISToggleWindowLock = "UI_ChilaSeda_ViewpointActionLabel_ISToggleWindowLock",
    ISUpRopeAction = "UI_ChilaSeda_ViewpointActionLabel_ISUpRopeAction",
    ISWaterWindowAction = "UI_ChilaSeda_ViewpointActionLabel_ISWaterWindowAction",
    -- Acciones de armas y combate
    ISExerciseAction = "UI_ChilaSeda_ViewpointActionLabel_ISExerciseAction",
    ISFireExtinguisherAction = "UI_ChilaSeda_ViewpointActionLabel_ISFireExtinguisherAction",
    ISInsertMagazine = "UI_ChilaSeda_ViewpointActionLabel_ISInsertMagazine",
    ISPourWaterOnSmokeAction = "UI_ChilaSeda_ViewpointActionLabel_ISPourWaterOnSmokeAction",
    ISReloadWeaponAction = "UI_ChilaSeda_ViewpointActionLabel_ISReloadWeaponAction",
    ISUnloadBulletsFromMagazine = "UI_ChilaSeda_ViewpointActionLabel_ISUnloadBulletsFromMagazine",
    ISUnloadMagazine = "UI_ChilaSeda_ViewpointActionLabel_ISUnloadMagazine",
    -- Acciones de vehiculos
    ISEnterVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISEnterVehicle",
    ISExitVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISExitVehicle",
    ISSwitchVehicleSeat = "UI_ChilaSeda_ViewpointActionLabel_ISSwitchVehicleSeat",
    ISStartVehicleEngine = "UI_ChilaSeda_ViewpointActionLabel_ISStartVehicleEngine",
    ISShutOffVehicleEngine = "UI_ChilaSeda_ViewpointActionLabel_ISShutOffVehicleEngine",
    ISHotwireVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISHotwireVehicle",
    ISOpenVehicleDoor = "UI_ChilaSeda_ViewpointActionLabel_ISOpenVehicleDoor",
    ISCloseVehicleDoor = "UI_ChilaSeda_ViewpointActionLabel_ISCloseVehicleDoor",
    ISLockVehicleDoor = "UI_ChilaSeda_ViewpointActionLabel_ISLockVehicleDoor",
    ISLockDoors = "UI_ChilaSeda_ViewpointActionLabel_ISLockDoors",
    ISUnlockVehicleDoor = "UI_ChilaSeda_ViewpointActionLabel_ISUnlockVehicleDoor",
    ISOpenCloseVehicleWindow = "UI_ChilaSeda_ViewpointActionLabel_ISOpenCloseVehicleWindow",
    ISSmashVehicleWindow = "UI_ChilaSeda_ViewpointActionLabel_ISSmashVehicleWindow",
    ISConfigHeadlight = "UI_ChilaSeda_ViewpointActionLabel_ISConfigHeadlight",
    ISAttachTrailerToVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISAttachTrailerToVehicle",
    ISDetachTrailerFromVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISDetachTrailerFromVehicle",
    ISWashVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISWashVehicle",
    ISRefuelFromGasPump = "UI_ChilaSeda_ViewpointActionLabel_ISRefuelFromGasPump",
    ISTakeGasolineFromVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISTakeGasolineFromVehicle",
    ISAddFuel = "UI_ChilaSeda_ViewpointActionLabel_ISAddFuel",
    ISAddFuelAction = "UI_ChilaSeda_ViewpointActionLabel_ISAddFuelAction",
    ISAddGasolineToVehicle = "UI_ChilaSeda_ViewpointActionLabel_ISAddGasolineToVehicle",
    ISAttachCarBatteryChargerAction = "UI_ChilaSeda_ViewpointActionLabel_ISAttachCarBatteryChargerAction",
    ISPlaceCarBatteryChargerAction = "UI_ChilaSeda_ViewpointActionLabel_ISPlaceCarBatteryChargerAction",
    ISRemoveCarBatteryFromChargerAction = "UI_ChilaSeda_ViewpointActionLabel_ISRemoveCarBatteryFromChargerAction",
    ISRainCollectorAction = "UI_ChilaSeda_ViewpointActionLabel_ISRainCollectorAction",
    ISTrapControlAction = "UI_ChilaSeda_ViewpointActionLabel_ISTrapControlAction",
    ISVehicleActions = "UI_ChilaSeda_ViewpointActionLabel_ISVehicleActions",
    IFP_FuelTransfer = "UI_ChilaSeda_ViewpointActionLabel_IFP_FuelTransfer",
    ISCheckBehindObject = "UI_ChilaSeda_ViewpointActionLabel_ISCheckBehindObject",
    ["enter to vehicle"] = "UI_ChilaSeda_ViewpointActionLabel_ISEnterVehicle",
    ["enter vehicle"] = "UI_ChilaSeda_ViewpointActionLabel_ISEnterVehicle",
    ["exit from vehicle"] = "UI_ChilaSeda_ViewpointActionLabel_ISExitVehicle",
    ["exit vehicle"] = "UI_ChilaSeda_ViewpointActionLabel_ISExitVehicle",
    -- Acciones de lectura y escritura
    ISReadABook = "UI_ChilaSeda_ViewpointActionLabel_ISReadABook",
    ISReadMagazine = "UI_ChilaSeda_ViewpointActionLabel_ISReadMagazine",
    ISReadWorldMap = "UI_ChilaSeda_ViewpointActionLabel_ISReadWorldMap",
    ISResearchRecipe = "UI_ChilaSeda_ViewpointActionLabel_ISResearchRecipe",
    ISRestAction = "UI_ChilaSeda_ViewpointActionLabel_ISRestAction",
    ISWriteOnPaper = "UI_ChilaSeda_ViewpointActionLabel_ISWriteOnPaper",
    -- Acciones de navegacion
    ISPathFindAction = "UI_ChilaSeda_ViewpointActionLabel_ISPathFindAction",
    ISPathFind = "UI_ChilaSeda_ViewpointActionLabel_ISPathFind",
    ISWalkToTimedAction = "UI_ChilaSeda_ViewpointActionLabel_ISWalkToTimedAction",
    butcher = "UI_ChilaSeda_ViewpointActionLabel_butcher",
    ["butcher animal"] = "UI_ChilaSeda_ViewpointActionLabel_butcher_animal",
    ["Butcher Animal"] = "UI_ChilaSeda_ViewpointActionLabel_Butcher_Animal_2",
    ["walk to time"] = "UI_ChilaSeda_ViewpointActionLabel_walk_to_time",
    ["walk to"] = "UI_ChilaSeda_ViewpointActionLabel_walk_to",
    ["walking to"] = "UI_ChilaSeda_ViewpointActionLabel_walking_to",
    ["pick up broken glass"] = "UI_ChilaSeda_ViewpointActionLabel_pick_up_broken_glass",
    ["pick up broken glasses"] = "UI_ChilaSeda_ViewpointActionLabel_pick_up_broken_glasses",
    ["removing broken glass"] = "UI_ChilaSeda_ViewpointActionLabel_removing_broken_glass",
    ["remove broken glass"] = "UI_ChilaSeda_ViewpointActionLabel_remove_broken_glass",
    ["removing cristales rotos"] = "UI_ChilaSeda_ViewpointActionLabel_removing_cristales_rotos",
    ["read world map"] = "UI_ChilaSeda_ViewpointActionLabel_read_world_map",
    ["drop content"] = "UI_ChilaSeda_ViewpointActionLabel_drop_content",
    ["drop contents"] = "UI_ChilaSeda_ViewpointActionLabel_drop_contents",
    ["research recipe"] = "UI_ChilaSeda_ViewpointActionLabel_research_recipe",
    ["dry me"] = "UI_ChilaSeda_ViewpointActionLabel_dry_me",
    ["pathfinding"] = "UI_ChilaSeda_ViewpointActionLabel_pathfinding",
    ["prepare soup"] = "UI_ChilaSeda_ViewpointActionLabel_prepare_soup",
    ["prepare stew"] = "UI_ChilaSeda_ViewpointActionLabel_prepare_stew",
    ["make salad"] = "UI_ChilaSeda_ViewpointActionLabel_make_salad",
    ["make fruit salad"] = "UI_ChilaSeda_ViewpointActionLabel_make_fruit_salad",
    ["complementar receta"] = "UI_ChilaSeda_ViewpointActionLabel_complementar_receta",
    moveable = "UI_ChilaSeda_ViewpointActionLabel_moveable",
    moveables = "UI_ChilaSeda_ViewpointActionLabel_moveables",
    ["light actions"] = "UI_ChilaSeda_ViewpointActionLabel_light_actions",
    ["pick up"] = "UI_ChilaSeda_ViewpointActionLabel_pick_up",
    ["taking water"] = "UI_ChilaSeda_ViewpointActionLabel_taking_water",
    ["take water"] = "UI_ChilaSeda_ViewpointActionLabel_take_water",
    ISForageAction = "UI_ChilaSeda_ViewpointActionLabel_ISForageAction_2",
    ISChilaSedaFatCombine = "UI_ChilaSeda_ViewpointActionLabel_ISChilaSedaFatCombine",
    ISInventoryTransferAction = "UI_ChilaSeda_ViewpointActionLabel_ISInventoryTransferAction_2",
    ISCleanBandage = "UI_ChilaSeda_ViewpointActionLabel_ISCleanBandage_2",
    ISCleanBandageInRain = "UI_ChilaSeda_ViewpointActionLabel_ISCleanBandageInRain_2",
    ISCraftAction = "UI_ChilaSeda_ViewpointActionLabel_ISCraftAction_2",
    ISUnpackAction = "UI_ChilaSeda_ViewpointActionLabel_ISUnpackAction_2",
    ISUnpackContainer = "UI_ChilaSeda_ViewpointActionLabel_ISUnpackContainer_2",
    ISHandcraftAction = "UI_ChilaSeda_ViewpointActionLabel_ISHandcraftAction_2",
    Handcraft = "UI_ChilaSeda_ViewpointActionLabel_Handcraft",
    ISEatFoodAction = "UI_ChilaSeda_ViewpointActionLabel_ISEatFoodAction_2",
    ISReadABook = "UI_ChilaSeda_ViewpointActionLabel_ISReadABook_2",
    ISRestAction = "UI_ChilaSeda_ViewpointActionLabel_ISRestAction_2",
    ISWearClothing = "UI_ChilaSeda_ViewpointActionLabel_ISWearClothing_2",
    ISUnequipAction = "UI_ChilaSeda_ViewpointActionLabel_ISUnequipAction_2",
    ISRepairClothing = "UI_ChilaSeda_ViewpointActionLabel_ISRepairClothing_2",
    ISRemovePatch = "UI_ChilaSeda_ViewpointActionLabel_ISRemovePatch_2",
}

local ACTION_LABEL_PREFIXES = {
    ["pick up "] = "UI_ChilaSeda_ViewpointActionPrefix_pick_up",
    ["pick up ground cover item"] = "UI_ChilaSeda_ViewpointActionPrefix_pick_up_ground_cover_item",
    ["light from literature"] = "UI_ChilaSeda_ViewpointActionPrefix_light_from_literature",
    ["taking water "] = "UI_ChilaSeda_ViewpointActionPrefix_taking_water",
    ["take water "] = "UI_ChilaSeda_ViewpointActionPrefix_take_water",
}

local MOVEABLE_ACTION_LABELS = {
    pickup = "UI_ChilaSeda_ViewpointMoveable_pickup",
    place = "UI_ChilaSeda_ViewpointMoveable_place",
    rotate = "UI_ChilaSeda_ViewpointMoveable_rotate",
    repair = "UI_ChilaSeda_ViewpointMoveable_repair",
    scrap = "UI_ChilaSeda_ViewpointMoveable_scrap",
}

local LIGHT_ACTION_LABELS = {
    AddLightBulb = "UI_ChilaSeda_ViewpointLight_AddLightBulb",
    RemoveLightBulb = "UI_ChilaSeda_ViewpointLight_RemoveLightBulb",
    ModifyLamp = "UI_ChilaSeda_ViewpointLight_ModifyLamp",
    AddBattery = "UI_ChilaSeda_ViewpointLight_AddBattery",
    RemoveBattery = "UI_ChilaSeda_ViewpointLight_RemoveBattery",
}

local function localizedActionLabel(value)
    if value == nil then return nil end
    local label = tostring(value)
    local lowerLabel = string.lower(label)
    local recipePrefixes = {
        "complete recipe:", "completar receta:", "complementar receta:",
    }
    for _, prefix in ipairs(recipePrefixes) do
        if lowerLabel:sub(1, #prefix) == prefix then
            local recipeName = string.gsub(string.sub(label, #prefix + 1), "^%s+", "")
            local recipeKey = ACTION_LABELS[recipeName]
                or ACTION_LABELS[string.lower(recipeName)]
            local translatedRecipe = recipeKey and localizedText(recipeKey) or recipeName
            return localizedFormat("UI_ChilaSeda_ViewpointAction_CompleteRecipe", translatedRecipe)
        end
    end
    local exact = ACTION_LABELS[label] or ACTION_LABELS[string.lower(label)]
    if exact then return localizedText(exact) end

    local prefixes = {}
    for prefix in pairs(ACTION_LABEL_PREFIXES) do prefixes[#prefixes + 1] = prefix end
    table.sort(prefixes, function(a, b) return #a > #b end)
    for _, prefix in ipairs(prefixes) do
        if lowerLabel:sub(1, #prefix) == prefix then
            return localizedText(ACTION_LABEL_PREFIXES[prefix]) .. label:sub(#prefix + 1)
        end
    end
    return label
end

local function actionTypeName(action)
    if not action then return nil end
    local typeName = action.Type or action.type
    if type(typeName) == "string" and typeName ~= "" then return typeName end
    local meta = getmetatable(action)
    if type(meta) == "table" then
        local className = rawget(meta, "Type") or rawget(meta, "type")
        if type(className) == "string" and className ~= "" then return className end
    end
    return nil
end

local function actionLabel(action)
    local typeName = actionTypeName(action)
    if typeName == "ISConsolidateDrainable" then
        -- The destination is the object being consolidated into; its name is
        -- the useful label when the consumed source is another compatible item.
        local function itemName(item)
            if not item or type(item.getName) ~= "function" then return nil end
            local ok, name = pcall(item.getName, item)
            if ok and type(name) == "string" and name ~= "" then return name end
            return nil
        end
        local name = itemName(action.intoItem) or itemName(action.drainable)
        if name then return localizedFormat("UI_ChilaSeda_ViewpointAction_Consolidating", name) end
        return localizedText("UI_ChilaSeda_ViewpointAction_ConsolidatingObject")
    end
    local explicit = action and (action.label or action.jobType or action.name)
    if explicit ~= nil and tostring(explicit) ~= "" then
        local label = localizedActionLabel(explicit)
        if label ~= tostring(explicit) then return label end
        if typeName and ACTION_LABELS[typeName] then
            return localizedText(ACTION_LABELS[typeName])
        end
        return localizedText("UI_ChilaSeda_ViewpointAction_Generic")
    end

    if typeName == "ISLightActions" then
        local key = LIGHT_ACTION_LABELS[action.mode]
        return key and localizedText(key) or localizedText("UI_ChilaSeda_ViewpointAction_ModifyingLight")
    end
    if typeName == "ISMoveablesAction" then
        local key = MOVEABLE_ACTION_LABELS[action.mode]
        if action.mode == "scrap" then
            local name = action.moveProps and action.moveProps.name
            if type(name) == "string" and name ~= "" then
                if Translator and type(Translator.getMoveableDisplayName) == "function" then
                    name = Translator.getMoveableDisplayName(name) or name
                end
                return localizedFormat("UI_ChilaSeda_ViewpointMoveable_ScrapItem", name)
            end
        end
        return key and localizedText(key) or localizedText("UI_ChilaSeda_ViewpointAction_ModifyingObject")
    end
    if typeName == "ISTakeWaterAction" then
        -- Vanilla uses this action both for direct drinking and filling a container.
        return action.item == nil
            and localizedText("UI_ChilaSeda_ViewpointAction_DrinkingWater")
            or localizedText("UI_ChilaSeda_ViewpointAction_FillingContainer")
    end
    if typeName and ACTION_LABELS[typeName] then return localizedText(ACTION_LABELS[typeName]) end
    if action and action.ChilaSedaAutoCookJob then
        return localizedText("UI_ChilaSeda_ViewpointAction_Cooking")
    end
    return localizedText("UI_ChilaSeda_ViewpointAction_Generic")
end

local function hasSpecificActionLabel(action, typeName)
    if typeName == "ISConsolidateDrainable" then return true end
    local explicit = action and (action.label or action.jobType or action.name)
    if explicit ~= nil then
        local label = tostring(explicit)
        local mapped = ACTION_LABELS[label] or ACTION_LABELS[string.lower(label)]
        if mapped then return true end
        local localized = localizedActionLabel(label)
        if localized ~= label then return true end
    end
    if typeName == "ISLightActions" then
        return LIGHT_ACTION_LABELS[action.mode] ~= nil
    end
    if typeName == "ISMoveablesAction" then
        return MOVEABLE_ACTION_LABELS[action.mode] ~= nil
    end
    return (typeName and ACTION_LABELS[typeName] ~= nil)
        or (action and action.ChilaSedaAutoCookJob == true)
end

local function logActionActivation(action, typeName, covered, label)
    local actionName = typeName or "unknown"
    if activationLogged[actionName] then return end
    activationLogged[actionName] = true
    local mode = action and action.mode
    print("[ChilaSeda_ViewpointActionProgress][ACTIVATION] action=" .. actionName
        .. " mode=" .. tostring(mode or "-")
        .. " covered=" .. (covered and "yes" or "no")
        .. " label=" .. tostring(label or "-")
        .. " specificLabel=" .. (hasSpecificActionLabel(action, typeName) and "yes" or "no")
        .. " vanillaUseProgressBar=" .. tostring(action and action.useProgressBar)
        .. " vanillaForceProgressBar=" .. tostring(action and action.forceProgressBar))
end

local function markAction(action)
    if not action then return end
    if action[FLAG] then
        -- Keep the engine bar off while the local renderer owns the action.
        if sharedProgressBar then
            action.useProgressBar = false
            action.forceProgressBar = false
        end
        return
    end

    local typeName = actionTypeName(action)
    local requiredCustomBar = typeName and REQUIRED_CUSTOM_BAR_ACTIONS[typeName] == true
    local hasNativeBar = action.forceProgressBar == true or action.useProgressBar ~= false
        or requiredCustomBar
    local label = actionLabel(action)
    logActionActivation(action, typeName, hasNativeBar, label)
    if not hasNativeBar then return end

    action[FLAG] = {
        label = label,
        useProgressBar = action.useProgressBar,
        forceProgressBar = action.forceProgressBar,
    }
    trackedActions[action] = true
    -- Jill's screenshot confirms that the local renderer draws correctly.
    -- Disable the engine flags before the action starts to avoid two bars.
    if sharedProgressBar then
        action.useProgressBar = false
        action.forceProgressBar = false
    end
    if requiredCustomBar and (requiredBarTraceCount[typeName] or 0) < 3 then
        requiredBarTraceCount[typeName] = (requiredBarTraceCount[typeName] or 0) + 1
        print("[ChilaSeda_ViewpointActionProgress] required action marked: " .. typeName
            .. " label=" .. tostring(action[FLAG].label))
    end
end

local function restoreAction(action)
    if not action then return end
    local saved = action[FLAG]
    if saved then
        action.useProgressBar = saved.useProgressBar
        action.forceProgressBar = saved.forceProgressBar
    end
    action[FLAG] = nil
    trackedActions[action] = nil
    if suppressedNativeAction == action then suppressedNativeAction = nil end
end

local function restoreSuppressedNativeAction()
    local action = suppressedNativeAction
    local saved = action and action[FLAG]
    if saved then
        action.useProgressBar = saved.useProgressBar
        action.forceProgressBar = saved.forceProgressBar
    end
    suppressedNativeAction = nil
end

local function suppressNativeAfterCustomRender()
    local action = currentProgressAction
    local saved = action and action[FLAG]
    if not saved then return end
    action.useProgressBar = false
    action.forceProgressBar = false
    suppressedNativeAction = action
    if not customBarDrawLogged then
        customBarDrawLogged = true
        print("[ChilaSeda_ViewpointActionProgress] custom orange bar rendered; native bar suppressed: "
            .. tostring(actionTypeName(action)) .. " label=" .. tostring(saved.label))
    end
end

local originalAdd = ISTimedActionQueue.add
ISTimedActionQueue.add = function(action)
    -- Queue.add may start the action before it returns; record its orange-bar label first.
    markAction(action)
    return originalAdd(action)
end

local originalAddAfter = ISTimedActionQueue.addAfter
ISTimedActionQueue.addAfter = function(previousAction, action)
    markAction(action)
    return originalAddAfter(previousAction, action)
end

local function actionProgress(action)
    local fraction = 0
    if action and type(action.getJobDelta) == "function" then
        local ok, delta = pcall(action.getJobDelta, action)
        if ok and type(delta) == "number" then fraction = delta end
    end
    return fraction
end

local function updateAndDrawProgress(player, allowDraw)
    local timedQueue = ISTimedActionQueue.queues and ISTimedActionQueue.queues[player]
    local actions = timedQueue and timedQueue.queue
    local queuedActions = {}
    if actions then
        for _, action in ipairs(actions) do
            markAction(action)
            if action[FLAG] then queuedActions[action] = true end
        end
    end
    local finishedActions = {}
    for action in pairs(trackedActions) do
        if not queuedActions[action] then finishedActions[#finishedActions + 1] = action end
    end
    for _, action in ipairs(finishedActions) do restoreAction(action) end

    local action = actions and actions[1]
    if suppressedNativeAction and suppressedNativeAction ~= action then
        restoreSuppressedNativeAction()
    end
    currentProgressAction = action
    local saved = action and action[FLAG]
    if not sharedProgressBar then
        if saved and not nativeFallbackLogged then
            nativeFallbackLogged = true
            print("[ChilaSeda_ViewpointActionProgress] custom bar not initialized; native bar retained")
        end
        return
    end
    if not saved then
        restoreSuppressedNativeAction()
        currentProgressAction = nil
        sharedProgressBar:set(nil, 0)
        sharedProgressBar:display(false)
        return
    end

    sharedProgressBar:set(saved.label, actionProgress(action))
    sharedProgressBar:display(allowDraw)
    if not allowDraw then restoreSuppressedNativeAction() end
end

do
    require "ISUI/ISUIElement"
    local LocalActionProgress = ISUIElement:derive("ChilaSedaLocalActionProgress")
    function LocalActionProgress:new()
        local core = getCore()
        local width = core:getScreenWidth()
        local height = core:getScreenHeight()
        local o = ISUIElement.new(self, 0, 0, width, height)
        o.x, o.y, o.width, o.height = 0, 0, width, height
        o.label, o.fraction, o.visible = nil, 0, false
        o:initialise()
        o:instantiate()
        return o
    end
    function LocalActionProgress:set(label, fraction)
        self.label = label
        self.fraction = math.max(0, math.min(1, tonumber(fraction) or 0))
    end
    function LocalActionProgress:display(value)
        -- Keep both visibility states in sync: UIManager checks the Java object,
        -- while this renderer checks the Lua field before drawing.
        local visible = value == true
        self.visible = visible
        self:setVisible(visible)
    end
    function LocalActionProgress:render()
        if not self.visible or not self.label then return end
        local core = getCore()
        local width, height = core:getScreenWidth(), core:getScreenHeight()
        local barWidth = math.min(360, width - 40)
        local x, y = math.floor((width - barWidth) / 2), math.floor(height * 0.57)
        local font = UIFont.Small
        local textWidth = getTextManager():MeasureStringX(font, self.label)
        self:drawText(self.label, math.floor((width - textWidth) / 2), y - 24,
            1, 1, 1, 1, font)
        self:drawRect(x, y, barWidth, 3, 0.9, 0.12, 0.12, 0.12)
        self:drawRect(x, y, math.floor(barWidth * self.fraction), 3,
            ORANGE_PROGRESS.a, ORANGE_PROGRESS.r, ORANGE_PROGRESS.g, ORANGE_PROGRESS.b)
        if self == sharedProgressBar and currentProgressAction then
            customBarDrawnThisFrame = true
            suppressNativeAfterCustomRender()
        end
    end
    sharedProgressBar = LocalActionProgress:new()
    sharedProgressBar:addToUIManager()
    sharedProgressBar:setAlwaysOnTop(true)
    if Events and Events.OnTick then
        Events.OnTick.Add(function()
            customBarDrawnThisFrame = false
            local player = getPlayer()
            if player then updateAndDrawProgress(player, true) end
        end)
    end
    -- In some B42/Viewpoint UI stacks the registered Lua element is made
    -- visible but UIManager never calls its render callback. Draw it at the
    -- explicit end-of-UI hook as a fallback; the per-frame guard prevents a
    -- duplicate when UIManager did render it normally.
    if Events and Events.OnPostUIDraw then
        Events.OnPostUIDraw.Add(function()
            if customBarDrawnThisFrame or not sharedProgressBar
                    or not sharedProgressBar.visible then
                return
            end
            local ok, err = pcall(sharedProgressBar.render, sharedProgressBar)
            if not ok and not customBarDrawFailureLogged then
                customBarDrawFailureLogged = true
                print("[ChilaSeda_ViewpointActionProgress] post-UI draw fallback failed: "
                    .. tostring(err))
            end
        end)
    end
end

print("[ChilaSeda_ViewpointActionProgress] active: orange bars use local timed-action data; no Viewpoint state gate")
