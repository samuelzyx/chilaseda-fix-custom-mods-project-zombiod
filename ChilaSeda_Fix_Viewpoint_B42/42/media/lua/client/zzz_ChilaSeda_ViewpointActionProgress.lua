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

local ACTION_LABELS = {
    -- Acciones de animales y naturaleza
    ISButcherAnimal = "Despiezando animal",
    ISDismantleAction = "Desarmando objeto",
    ISGetAnimalBones = "Extrayendo huesos del animal",
    ISBuryCorpse = "Enterrando cuerpo",
    ISChopTreeAction = "Cortando arbol",
    ISFishingAction = "Pescando",
    ISGrabCorpseAction = "Levantando cuerpo",
    ISRemoveBush = "Quitando arbusto",
    ISSeedFlowerAction = "Plantando semillas",
    ISShovelGround = "Cavando terreno",
    ISWaterPlantAction = "Regando planta",

    -- Acciones de crafting y construccion
    ISBBQLightFromKindle = "Encendiendo fuego",
    ISBBQLightFromLiterature = "Encendiendo fuego",
    ISBBQLightFromPetrol = "Encendiendo fuego",
    ISLightFromKindle = "Encendiendo fuego",
    ISLightFromLiterature = "Encendiendo fuego",
    ISLightFromLiteratura = "Encendiendo fuego",
    ISLightFromPetrol = "Encendiendo fuego",
    ISBBQAddFuel = "Agregando combustible a la barbacoa",
    ISBBQExtinguish = "Apagando fuego de la barbacoa",
    ISBBQToggle = "Encendiendo o apagando la barbacoa",
    ISBBQInsertPropaneTank = "Conectando tanque de propano",
    ISBBQRemovePropaneTank = "Quitando tanque de propano",
    ISPickupFishAction = "Recogiendo pez",
    ISAddBaitToFishNetAction = "Poniendo carnada en la red",
    ISRemoveFishingNetAction = "Retirando red de pesca",
    ISPlaceFishingNetAction = "Colocando red de pesca",
    ISCheckFishingNetAction = "Revisando red de pesca",
    ISChangeFishingRodEquip = "Preparando caña de pescar",
    AIAttachLureAction = "Colocando carnada en el anzuelo",
    AIRemoveLureAction = "Retirando carnada del anzuelo",
    AddChumToWaterAction = "Echando cebo al agua",
    CreateChumFromGroundSandAction = "Preparando cebo",
    ISBuildAction = "Construyendo",
    ISCookAction = "Cocinando",
    ISCraftAction = "Fabricando",
    ISFireplaceAction = "Usando chimenea",
    ISHandcraftAction = "Fabricando",
    ISPlaceCampfireAction = "Colocando fogata",
    ISPlaceItemAction = "Colocando objeto",
    ISPrepareSoup = "Preparar sopa",
    ISPrepareStew = "Preparar guiso",
    ISPutOutCampfireAction = "Apagando fogata",
    ISStartFireAction = "Encendiendo fuego",
    ["put out campfire"] = "Apagando fogata",

    -- Acciones de inventario y transferencia
    ISDetachItemHotbar = "Desprendiendo objeto",
    ISDropItemAction = "Vaciando contenido",
    ISDumpWaterAction = "Vaciando agua",
    ISForageAction = "Rebuscando",
    ISGrabItemAction = "Recogiendo objeto",
    ISPickUpGroundCoverItem = "Recogiendo cobertura del suelo",
    ISInventoryTransferAction = "Moviendo objeto",
    ISOpenContainerAction = "Abriendo contenedor",
    ISOpenMechanicsUIAction = "Abriendo interfaz de mecanica",
    ISPourInAction = "Vertiendo liquido",
    ISPourOutAction = "Vaciando liquido",
    ISRemoveItemAction = "Quitando objeto",
    ISStoreItemAction = "Guardando objeto",
    ISThrowAction = "Lanzando objeto",
    ISTransferWaterAction = "Transfiriendo agua",
    ISUnpackAction = "Desempacando de la mochila",
    ISUnpackContainer = "Desempacando de la mochila",

    -- Acciones de ropa y salud
    ISApplyBandage = "Aplicando vendaje",
    ISCleanBandage = "Lavando vendaje",
    ISCleanBandageAccessible = "Lavando vendaje",
    ISCleanBandageInRain = "Lavando vendaje bajo la lluvia",
    ISDrinkFluidAction = "Bebiendo",
    ISDryMyself = "Secando",
    ISEatFoodAction = "Comiendo",
    ISEquipWeaponAction = "Equipando arma",
    ISInsertClothingPadAction = "Insertando proteccion",
    ISRemoveClothingPadAction = "Quitando proteccion",
    ISRemovePatch = "Quitando remiendo",
    ISRepairClothing = "Remendando ropa",
    ISSutureAction = "Suturando herida",
    ISTakePillAction = "Tomando pastilla",
    ISTakeWaterAction = "Bebiendo agua",
    ISUnequipAction = "Quitando objeto",
    ISWashClothing = "Lavando ropa",
    ISWashYourself = "Lavandose",
    ISWearClothing = "Poniendose ropa",

    -- Acciones de estructuras e interaccion
    ISAddSheetAction = "Colocando sabana",
    ISBarricadeAction = "Barricando",
    ISClimbOverFence = "Saltando valla",
    ISClimbOverWall = "Saltando muro",
    ISClimbSheetRope = "Trepando cuerda",
    ISClimbThroughWindow = "Saltando ventana",
    ISCloseCurtainAction = "Cerrando cortina",
    ISDefeatCrawlingZombieAction = "Rematando zombie",
    ISDestroyStuffAction = "Destruyendo objeto",
    ISDigGravesAction = "Cavando tumba",
    ISEmptyGraves = "Vaciando tumba",
    ISFillGrave = "Rellenando tumba",
    ISOpenDoor = "Abriendo puerta",
    ISPaintAction = "Pintando",
    ISPickupBrokenGlass = "Recogiendo cristales rotos",
    ISRemoveBrokenGlass = "Quitando cristales rotos",
    ISPlumbItem = "Instalando tuberia",
    ISRemoveGlassAction = "Quitando cristales rotos",
    ISRemoveInsulationAction = "Quitando aislamiento",
    ISRemoveSheetAction = "Quitando sabana",
    ISSawAction = "Serrando",
    ISSmashWindow = "Rompiendo ventana",
    ISToggleLightAction = "Cambiando luz",
    ISToggleStoveAction = "Usando estufa",
    ISToggleWashingMachine = "Usando lavadora",
    ISToggleWindowLock = "Cambiando cerrojo",
    ISUpRopeAction = "Subiendo cuerda",
    ISWaterWindowAction = "Regando ventana",

    -- Acciones de armas y combate
    ISExerciseAction = "Ejercitando",
    ISFireExtinguisherAction = "Usando extintor",
    ISInsertMagazine = "Insertando cargador",
    ISPourWaterOnSmokeAction = "Apagando humo",
    ISReloadWeaponAction = "Recargando arma",
    ISUnloadBulletsFromMagazine = "Vaciando balas del cargador",
    ISUnloadMagazine = "Quitando cargador",

    -- Acciones de vehiculos
    ISAttachCarBatteryChargerAction = "Conectando cargador de bateria",
    ISPlaceCarBatteryChargerAction = "Colocando cargador de bateria",
    ISRainCollectorAction = "Usando colector de lluvia",
    ISTrapControlAction = "Usando trampa",
    ISVehicleActions = "Usando vehiculo",

    -- Acciones de lectura y escritura
    ISReadABook = "Leyendo",
    ISReadMagazine = "Leyendo revista",
    ISReadWorldMap = "Leyendo mapa del mundo",
    ISResearchRecipe = "Investigando receta",
    ISRestAction = "Descansando",
    ISWriteOnPaper = "Escribiendo",

    -- Acciones de navegacion
    ISPathFindAction = "Buscando ruta",
    ISPathFind = "Buscando ruta",
    ISWalkToTimedAction = "Caminando hacia",
    butcher = "Despiezando animal",
    ["butcher animal"] = "Despiezando animal",
    ["Butcher Animal"] = "Despiezando animal",
    ["walk to time"] = "Avanzando el tiempo",
    ["walk to"] = "Caminando hacia",
    ["walking to"] = "Caminando hacia",
    ["pick up broken glass"] = "Recogiendo cristales rotos",
    ["pick up broken glasses"] = "Recogiendo cristales rotos",
    ["removing broken glass"] = "Quitando cristales rotos",
    ["remove broken glass"] = "Quitando cristales rotos",
    ["removing cristales rotos"] = "Quitando cristales rotos",
    ["read world map"] = "Leyendo mapa del mundo",
    ["drop content"] = "Vaciando contenido",
    ["drop contents"] = "Vaciando contenido",
    ["research recipe"] = "Investigando receta",
    ["dry me"] = "Secando",
    ["pathfinding"] = "Buscando ruta",
    ["prepare soup"] = "Preparar sopa",
    ["prepare stew"] = "Preparar guiso",
    ["make salad"] = "Preparar ensalada",
    ["make fruit salad"] = "Preparar ensalada de frutas",
    ["complementar receta"] = "Complementar receta",
    moveable = "Desmantelando objeto",
    moveables = "Desmantelando objeto",
    ["light actions"] = "Modificando luz",
    ["pick up"] = "Recogiendo",
    ["taking water"] = "Bebiendo agua",
    ["take water"] = "Bebiendo agua",
    ISForageAction = "Rebuscando",
    ISChilaSedaFatCombine = "Combinando grasas",
    ISInventoryTransferAction = "Moviendo objeto",
    ISCleanBandage = "Lavando vendaje",
    ISCleanBandageInRain = "Lavando vendaje bajo la lluvia",
    ISCraftAction = "Fabricando",
    ISUnpackAction = "Desempacando de la mochila",
    ISUnpackContainer = "Desempacando de la mochila",
    ISHandcraftAction = "Fabricando",
    Handcraft = "Fabricando",
    ISEatFoodAction = "Comiendo",
    ISReadABook = "Leyendo",
    ISRestAction = "Descansando",
    ISWearClothing = "Poniendose ropa",
    ISUnequipAction = "Quitando objeto",
    ISRepairClothing = "Remendando ropa",
    ISRemovePatch = "Quitando remiendo",
}

local ACTION_LABEL_PREFIXES = {
    ["pick up "] = "Recogiendo ",
    ["pick up ground cover item"] = "Recogiendo cobertura del suelo",
    ["light from literature"] = "Encendiendo fuego",
    ["taking water "] = "Bebiendo agua ",
    ["take water "] = "Bebiendo agua ",
}

local MOVEABLE_ACTION_LABELS = {
    pickup = "Recogiendo objeto",
    place = "Colocando objeto",
    rotate = "Girando objeto",
    repair = "Reparando objeto",
    scrap = "Desmantelando",
}

local LIGHT_ACTION_LABELS = {
    AddLightBulb = "Instalando bombilla",
    RemoveLightBulb = "Quitando bombilla",
    ModifyLamp = "Modificando lámpara",
    AddBattery = "Instalando batería",
    RemoveBattery = "Quitando batería",
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
            local translatedRecipe = ACTION_LABELS[recipeName]
                or ACTION_LABELS[string.lower(recipeName)] or recipeName
            return "Completar receta: " .. translatedRecipe
        end
    end
    local exact = ACTION_LABELS[label] or ACTION_LABELS[string.lower(label)]
    if exact then return exact end

    for prefix, replacement in pairs(ACTION_LABEL_PREFIXES) do
        if lowerLabel:sub(1, #prefix) == prefix then
            return replacement .. label:sub(#prefix + 1)
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
        if name then return "Consolidando " .. name end
        return "Consolidando objeto"
    end
    local explicit = action and (action.label or action.jobType or action.name)
    if explicit ~= nil and tostring(explicit) ~= "" then
        return localizedActionLabel(explicit)
    end

    if typeName == "ISLightActions" then
        return LIGHT_ACTION_LABELS[action.mode] or "Modificando luz"
    end
    if typeName == "ISMoveablesAction" then
        local label = MOVEABLE_ACTION_LABELS[action.mode] or "Modificando objeto"
        if action.mode == "scrap" then
            local name = action.moveProps and action.moveProps.name
            if type(name) == "string" and name ~= "" then
                if Translator and type(Translator.getMoveableDisplayName) == "function" then
                    name = Translator.getMoveableDisplayName(name) or name
                end
                return label .. " " .. name
            end
        end
        return label
    end
    if typeName == "ISTakeWaterAction" then
        -- Vanilla uses this action both for direct drinking and filling a container.
        return action.item == nil and "Bebiendo agua" or "Llenando recipiente"
    end
    if typeName and ACTION_LABELS[typeName] then return ACTION_LABELS[typeName] end
    if action and action.ChilaSedaAutoCookJob then
        return "Cocinando"
    end
    if typeName then
        local readable = typeName:gsub("^IS", "")
            :gsub("Action$", "")
            :gsub("([a-z])([A-Z])", "%1 %2")
        if readable ~= "" then return readable end
    end
    return "Realizando accion"
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
