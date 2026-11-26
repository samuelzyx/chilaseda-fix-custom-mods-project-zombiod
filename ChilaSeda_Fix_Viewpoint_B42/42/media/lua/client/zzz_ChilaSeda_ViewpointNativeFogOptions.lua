-- Mod Options control for the integrated Viewpoint search fog.
local TAG = "[ChilaSeda_ViewpointNativeFogOptions] "
local MOD_ID = "ChilaSeda_Fix_Viewpoint_B42"
local OPTION_ID = "searchFogStrength"
local ENABLE_OPTION_ID = "searchFogEnabled"
local STYLE_OPTION_ID = "searchFogStyle"
local FEATHER_OPTION_ID = "searchFogFeather"
local PACK_LAYER_OPTION_ID = "searchFogDepthLayer"
local PICKUP_KEY_OPTION_ID = "nativeForagePickupKey"
local ACTION_MODIFIER_OPTION_ID = "nativeActionModifier"
local CALIBRATION_KEY_OPTION_ID = "nativeForageCalibrationKey"
local ANIMAL_BUTCHER_KEY_OPTION_ID = "animalCorpseButcherKey"
local ANIMAL_PICKUP_KEY_OPTION_ID = "animalCorpsePickupKey"
local ANIMAL_BONES_KEY_OPTION_ID = "animalCorpseBonesKey"
local ANIMAL_CORPSE_MODIFIER_OPTION_ID = "animalCorpseActionModifier"
local CORPSE_PANEL_SCALE_OPTION_ID = "corpseLootPanelScale"
local CORPSE_WEAR_STYLE_OPTION_ID = "corpseWearStyle"
local HALO_XP_OPTION_ID = "haloXPEnabled"
local DEFAULT_STRENGTH = 0.9
local DEFAULT_FEATHER = 3
local DEFAULT_CORPSE_PANEL_SCALE = 1.5
local DEFAULT_CORPSE_WEAR_STYLE = "BAR"
local optionPage
local enabledOption
local styleOption
local strengthOption
local featherOption
local packLayerOption
local pickupKeyOption
local actionModifierOption
local calibrationKeyOption
local animalButcherKeyOption
local animalPickupKeyOption
local animalBonesKeyOption
local animalCorpseModifierOption
local corpsePanelScaleOption
local corpseWearStyleOption
local haloXpOption
local lastCorpseOptionsDiagnostic

ChilaSedaViewpointNativeFogStrength = DEFAULT_STRENGTH
ChilaSedaViewpointNativeFogEnabled = true
ChilaSedaViewpointNativeFogStyle = 0
ChilaSedaViewpointNativeFogFeather = DEFAULT_FEATHER
ChilaSedaViewpointShaderPackFogEnabled = true
ChilaSedaViewpointNativeForagePickupKey = Keyboard and Keyboard.KEY_G or 34
ChilaSedaViewpointNativeActionModifier = "ALT"
ChilaSedaViewpointNativeForageCalibrationKey = Keyboard and Keyboard.KEY_F6 or 64
ChilaSedaViewpointAnimalCorpseButcherKey = Keyboard and Keyboard.KEY_B or 48
ChilaSedaViewpointAnimalCorpsePickupKey = Keyboard and Keyboard.KEY_G or 34
ChilaSedaViewpointAnimalCorpseBonesKey = Keyboard and Keyboard.KEY_H or 35
ChilaSedaViewpointAnimalCorpseActionModifier = "ALT"
ChilaSedaViewpointCorpsePanelScale = DEFAULT_CORPSE_PANEL_SCALE
ChilaSedaViewpointCorpseWearStyle = DEFAULT_CORPSE_WEAR_STYLE
ChilaSedaViewpointHaloXPEnabled = true

local function optionValue(option, fallback)
    if not option or type(option.getValue) ~= "function" then return fallback end
    local ok, value = pcall(option.getValue, option)
    if not ok then return fallback end
    return value
end

local MODIFIER_VALUES = {
    "CTRL", "ALT", "SHIFT", "CTRL+ALT", "CTRL+SHIFT", "ALT+SHIFT",
    "CTRL+ALT+SHIFT",
}

local function normalizedModifier(value)
    if type(value) == "number" then
        local index = math.floor(value)
        return MODIFIER_VALUES[index]
    end
    if type(value) ~= "string" then return nil end
    local normalized = string.upper(string.gsub(value, "%s+", ""))
    normalized = string.gsub(normalized, "Ú", "U")
    normalized = string.gsub(normalized, "ú", "U")
    normalized = string.gsub(normalized, "MAYÚS", "SHIFT")
    normalized = string.gsub(normalized, "MAYUS", "SHIFT")
    normalized = string.gsub(normalized, "MAY\195\186S", "SHIFT")
    normalized = string.gsub(normalized, "MAY\195\154S", "SHIFT")
    for _, candidate in ipairs(MODIFIER_VALUES) do
        if normalized == candidate then return candidate end
    end
    return nil
end

local function keyIsDown(primaryName, secondaryName, primaryCode, secondaryCode)
    if not Keyboard or type(Keyboard.isKeyDown) ~= "function" then return false end
    local primary = Keyboard[primaryName] or primaryCode
    local secondary = Keyboard[secondaryName] or secondaryCode
    for _, key in ipairs({ primary, secondary }) do
        if key ~= nil then
            local ok, down = pcall(Keyboard.isKeyDown, key)
            if ok and down == true then return true end
        end
    end
    return false
end

local function modifierMatches(selectedValue)
    local selected = normalizedModifier(selectedValue) or "ALT"
    local ctrl = keyIsDown("KEY_LCONTROL", "KEY_RCONTROL", 29, 157)
    local alt = keyIsDown("KEY_LMENU", "KEY_RMENU", 56, 184)
    local shift = keyIsDown("KEY_LSHIFT", "KEY_RSHIFT", 42, 54)
    local wantsCtrl = string.find(selected, "CTRL", 1, true) ~= nil
    local wantsAlt = string.find(selected, "ALT", 1, true) ~= nil
    local wantsShift = string.find(selected, "SHIFT", 1, true) ~= nil
    return ctrl == wantsCtrl and alt == wantsAlt and shift == wantsShift
end

function ChilaSedaViewpointNativeActionModifierMatches()
    return modifierMatches(ChilaSedaViewpointNativeActionModifier)
end

function ChilaSedaViewpointAnimalCorpseActionModifierMatches()
    return modifierMatches(ChilaSedaViewpointAnimalCorpseActionModifier)
end

local function formatActionKey(key, selectedValue)
    if type(key) ~= "number" or key <= 0 then return nil end
    local keyName
    if Keyboard and type(Keyboard.getKeyName) == "function" then
        local ok, value = pcall(Keyboard.getKeyName, key)
        if ok and type(value) == "string" and value ~= "" then keyName = value end
    end
    keyName = keyName or tostring(key)
    local selected = normalizedModifier(selectedValue) or "ALT"
    local display = string.gsub(selected, "CTRL", "Ctrl")
    display = string.gsub(display, "ALT", "Alt")
    display = string.gsub(display, "SHIFT", "Mayús")
    return display .. "+" .. keyName
end

function ChilaSedaViewpointFormatNativeActionKey(key)
    return formatActionKey(key, ChilaSedaViewpointNativeActionModifier)
end

function ChilaSedaViewpointFormatAnimalCorpseActionKey(key)
    return formatActionKey(key, ChilaSedaViewpointAnimalCorpseActionModifier)
end

local function currentStrength()
    local value = optionValue(strengthOption, ChilaSedaViewpointNativeFogStrength)
    if type(value) ~= "number" then return ChilaSedaViewpointNativeFogStrength end
    return math.max(0, math.min(2, value))
end

local function applyOptions()
    local haloXpEnabled = optionValue(haloXpOption, ChilaSedaViewpointHaloXPEnabled)
    if type(haloXpEnabled) == "boolean" then
        ChilaSedaViewpointHaloXPEnabled = haloXpEnabled
    end

    local enabled = optionValue(enabledOption, ChilaSedaViewpointNativeFogEnabled)
    if type(enabled) == "boolean" then ChilaSedaViewpointNativeFogEnabled = enabled end

    local style = optionValue(styleOption, ChilaSedaViewpointNativeFogStyle)
    if style == "Mist" then
        ChilaSedaViewpointNativeFogStyle = 1
    elseif type(style) == "number" then
        ChilaSedaViewpointNativeFogStyle = style == 2 and 1 or 0
    end

    ChilaSedaViewpointNativeFogStrength = currentStrength()
    local feather = optionValue(featherOption, ChilaSedaViewpointNativeFogFeather)
    if type(feather) == "number" then
        ChilaSedaViewpointNativeFogFeather = math.max(0.5, math.min(10, feather))
    end
    local packLayer = optionValue(packLayerOption, ChilaSedaViewpointShaderPackFogEnabled)
    if type(packLayer) == "boolean" then ChilaSedaViewpointShaderPackFogEnabled = packLayer end
    local bridge = ChilaSedaViewpointFogJ
    if bridge and type(bridge.setShaderPackFogEnabled) == "function" then
        pcall(bridge.setShaderPackFogEnabled, ChilaSedaViewpointShaderPackFogEnabled)
    end
    if pickupKeyOption and type(pickupKeyOption.getValue) == "function" then
        local ok, key = pcall(pickupKeyOption.getValue, pickupKeyOption)
        if ok and type(key) == "number" then
            ChilaSedaViewpointNativeForagePickupKey = key
        end
    end
    local modifier = normalizedModifier(optionValue(actionModifierOption,
        ChilaSedaViewpointNativeActionModifier))
    if modifier then ChilaSedaViewpointNativeActionModifier = modifier end
    if calibrationKeyOption and type(calibrationKeyOption.getValue) == "function" then
        local ok, key = pcall(calibrationKeyOption.getValue, calibrationKeyOption)
        if ok and type(key) == "number" then
            ChilaSedaViewpointNativeForageCalibrationKey = key
        end
    end
    if animalButcherKeyOption and type(animalButcherKeyOption.getValue) == "function" then
        local ok, key = pcall(animalButcherKeyOption.getValue, animalButcherKeyOption)
        if ok and type(key) == "number" then ChilaSedaViewpointAnimalCorpseButcherKey = key end
    end
    if animalPickupKeyOption and type(animalPickupKeyOption.getValue) == "function" then
        local ok, key = pcall(animalPickupKeyOption.getValue, animalPickupKeyOption)
        if ok and type(key) == "number" then ChilaSedaViewpointAnimalCorpsePickupKey = key end
    end
    if animalBonesKeyOption and type(animalBonesKeyOption.getValue) == "function" then
        local ok, key = pcall(animalBonesKeyOption.getValue, animalBonesKeyOption)
        if ok and type(key) == "number" then ChilaSedaViewpointAnimalCorpseBonesKey = key end
    end
    local animalModifier = normalizedModifier(optionValue(animalCorpseModifierOption,
        ChilaSedaViewpointAnimalCorpseActionModifier))
    if animalModifier then ChilaSedaViewpointAnimalCorpseActionModifier = animalModifier end
    local panelScale = optionValue(corpsePanelScaleOption, ChilaSedaViewpointCorpsePanelScale)
    if type(panelScale) == "number" then
        ChilaSedaViewpointCorpsePanelScale = math.max(1, math.min(2, panelScale))
    end
    local wearStyle = optionValue(corpseWearStyleOption, ChilaSedaViewpointCorpseWearStyle)
    if type(wearStyle) == "number" then
        ChilaSedaViewpointCorpseWearStyle = wearStyle == 2 and "FRAME" or "BAR"
    elseif type(wearStyle) == "string" then
        local normalizedStyle = string.upper(wearStyle)
        if string.find(normalizedStyle, "MARCO", 1, true)
                or string.find(normalizedStyle, "FRAME", 1, true) then
            ChilaSedaViewpointCorpseWearStyle = "FRAME"
        else
            ChilaSedaViewpointCorpseWearStyle = "BAR"
        end
    end

    local diagnostic = string.format("scale=%.2f wear=%s nativeModifier=%s animalModifier=%s",
        tonumber(ChilaSedaViewpointCorpsePanelScale) or DEFAULT_CORPSE_PANEL_SCALE,
        tostring(ChilaSedaViewpointCorpseWearStyle or DEFAULT_CORPSE_WEAR_STYLE),
        tostring(ChilaSedaViewpointNativeActionModifier or "ALT"),
        tostring(ChilaSedaViewpointAnimalCorpseActionModifier or "ALT"))
    if diagnostic ~= lastCorpseOptionsDiagnostic then
        print(TAG .. "corpseOptions " .. diagnostic)
        lastCorpseOptionsDiagnostic = diagnostic
    end
end

local function translated(key, fallback)
    if type(getTextOrNull) == "function" then
        local value = getTextOrNull(key)
        if type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function installOptions()
    if optionPage or not (PZAPI and PZAPI.ModOptions) then return end
    local ok, page = pcall(PZAPI.ModOptions.create, PZAPI.ModOptions,
        MOD_ID, translated("UI_ChilaSeda_ViewpointFix_Page", "Ajustes de rebusqueda Viewpoint"))
    if not ok or not page then
        print(TAG .. "could not create Mod Options page")
        return
    end
    optionPage = page
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_FogTitle", "Neblina de rebusqueda nativa"))
    end
    if type(page.addTickBox) == "function" then
        local added, option = pcall(page.addTickBox, page, ENABLE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogEnabled", "Activar neblina de rebusqueda"), true,
            translated("UI_ChilaSeda_ViewpointFix_FogEnabledTooltip",
                "Muestra la neblina mientras este activa la rebusqueda nativa."))
        if added then enabledOption = option end
    end
    if type(page.addComboBox) == "function" then
        local added, option = pcall(page.addComboBox, page, STYLE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogStyle", "Estilo de neblina"),
            translated("UI_ChilaSeda_ViewpointFix_FogStyleTooltip",
                "Oscuridad oscurece el exterior del radio; Neblina agrega una capa mas suave."))
        if added and option then
            styleOption = option
            if type(option.addItem) == "function" then
                pcall(option.addItem, option,
                translated("UI_ChilaSeda_ViewpointFix_FogDark", "Oscuridad"), true)
                pcall(option.addItem, option,
                translated("UI_ChilaSeda_ViewpointFix_FogMist", "Neblina"), false)
            end
        end
    end
    if type(page.addSlider) == "function" then
        local added, option = pcall(page.addSlider, page, OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogStrength", "Intensidad de la neblina"),
            0, 2, 0.05, DEFAULT_STRENGTH,
            translated("UI_ChilaSeda_ViewpointFix_FogStrengthTooltip",
                "Reduce este valor para aclarar la neblina; 0 la desactiva."))
        if added then strengthOption = option end
        local featherAdded, feather = pcall(page.addSlider, page, FEATHER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogFeather", "Suavizado del borde"),
            0.5, 10, 0.5, DEFAULT_FEATHER,
            translated("UI_ChilaSeda_ViewpointFix_FogFeatherTooltip",
                "Controla que tan gradual es el desvanecimiento del borde del radio de busqueda."))
        if featherAdded then featherOption = feather end
    end
    if type(page.addTickBox) == "function" then
        local added, option = pcall(page.addTickBox, page, PACK_LAYER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogDepthLayer", "Capa circular de profundidad de la neblina"), true,
            translated("UI_ChilaSeda_ViewpointFix_FogDepthLayerTooltip",
                "Dibuja una capa circular de neblina con el buffer de profundidad de Viewpoint. Funciona con Iris y los paquetes de shaders; desactivalo para usar solo la neblina integrada de Viewpoint."))
        if added then packLayerOption = option end
    end
    if type(page.addSeparator) == "function" then pcall(page.addSeparator, page) end
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupTitle", "Hallazgos con pin de rebusqueda"))
    end
    if type(page.addComboBox) == "function" then
        local added, option = pcall(page.addComboBox, page, ACTION_MODIFIER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_ActionModifier", "Modificador de los atajos"),
            translated("UI_ChilaSeda_ViewpointFix_ActionModifierTooltip",
                "Elige el modificador para los atajos de Viewpoint. PZ trata Ctrl, Alt y Mayus como parte exacta de cada atajo."))
        if added and option then
            actionModifierOption = option
            if type(option.addItem) == "function" then
                local choices = {
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrl", "Ctrl" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAlt", "Alt" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierShift", "Mayús" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrlAlt", "Ctrl + Alt" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrlShift", "Ctrl + Mayús" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAltShift", "Alt + Mayús" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAll", "Ctrl + Alt + Mayús" },
                }
                for index, choice in ipairs(choices) do
                    pcall(option.addItem, option, translated(choice[1], choice[2]), index == 2)
                end
            end
        end
    end
    if type(page.addKeyBind) == "function" then
        local defaultKey = Keyboard and Keyboard.KEY_G or 34
        local added, option = pcall(page.addKeyBind, page, PICKUP_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupKey", "Tecla para recoger hallazgo apuntado"),
            defaultKey,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupKeyTooltip",
                "Apunta a un hallazgo visible de la rebusqueda nativa y pulsa el modificador seleccionado mas esta tecla (G por defecto)."))
        if added then pickupKeyOption = option end
        local calibrationAdded, calibrationOption = pcall(page.addKeyBind, page,
            CALIBRATION_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_ForageCalibrationKey",
                "Abrir ajuste de altura del pin"),
            Keyboard and Keyboard.KEY_F6 or 64,
            translated("UI_ChilaSeda_ViewpointFix_ForageCalibrationKeyTooltip",
                "Abre el panel para ajustar la altura y escala de los pines nativos de rebusque."))
        if calibrationAdded then calibrationKeyOption = calibrationOption end
    end
    if type(page.addSeparator) == "function" then pcall(page.addSeparator, page) end
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page, translated("UI_ChilaSeda_ViewpointAnimalCorpseKeysTitle",
            "Cadaveres de animales"))
    end
    if type(page.addComboBox) == "function" then
        local modifierAdded, modifierOption = pcall(page.addComboBox, page,
            ANIMAL_CORPSE_MODIFIER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_AnimalCorpseActionModifier",
                "Modificador de atajos animales"),
            translated("UI_ChilaSeda_ViewpointFix_AnimalCorpseActionModifierTooltip",
                "Elige el modificador para Despiezar, Obtener huesos y Recoger."))
        if modifierAdded and modifierOption then
            animalCorpseModifierOption = modifierOption
            if type(modifierOption.addItem) == "function" then
                local choices = {
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrl", "Ctrl" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAlt", "Alt" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierShift", "Mayus" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrlAlt", "Ctrl + Alt" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierCtrlShift", "Ctrl + Mayus" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAltShift", "Alt + Mayus" },
                    { "UI_ChilaSeda_ViewpointFix_ModifierAll", "Ctrl + Alt + Mayus" },
                }
                for index, choice in ipairs(choices) do
                    pcall(modifierOption.addItem, modifierOption,
                        translated(choice[1], choice[2]), index == 2)
                end
            end
        end
    end
    if type(page.addKeyBind) == "function" then
        local butcherAdded, butcherOption = pcall(page.addKeyBind, page,
            ANIMAL_BUTCHER_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointAnimalCorpseButcherKey", "Tecla para despiezar"),
            Keyboard and Keyboard.KEY_B or 48,
            translated("UI_ChilaSeda_ViewpointAnimalCorpseButcherKeyTooltip",
                "Pulsa el modificador seleccionado mas esta tecla para despiezar el cadaver animal apuntado."))
        if butcherAdded then animalButcherKeyOption = butcherOption end
        local pickupAdded, pickupOption = pcall(page.addKeyBind, page,
            ANIMAL_PICKUP_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointAnimalCorpsePickupKey", "Tecla para recoger cadaver o esqueleto"),
            Keyboard and Keyboard.KEY_G or 34,
            translated("UI_ChilaSeda_ViewpointAnimalCorpsePickupKeyTooltip",
                "Pulsa el modificador seleccionado mas esta tecla para recoger el cadaver o esqueleto animal apuntado."))
        if pickupAdded then animalPickupKeyOption = pickupOption end
        local bonesAdded, bonesOption = pcall(page.addKeyBind, page,
            ANIMAL_BONES_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointAnimalCorpseBonesKey", "Tecla para obtener huesos"),
            Keyboard and Keyboard.KEY_H or 35,
            translated("UI_ChilaSeda_ViewpointAnimalCorpseBonesKeyTooltip",
                "Pulsa el modificador seleccionado mas esta tecla (H por defecto) para extraer huesos."))
        if bonesAdded then animalBonesKeyOption = bonesOption end
    end
    if type(page.addSeparator) == "function" then pcall(page.addSeparator, page) end
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_CorpsePanelTitle", "Panel flotante de botin"))
    end
    if type(page.addComboBox) == "function" then
        local wearStyleAdded, wearStyleOption = pcall(page.addComboBox, page,
            CORPSE_WEAR_STYLE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_CorpseWearStyle", "Indicador de desgaste"),
            translated("UI_ChilaSeda_ViewpointFix_CorpseWearStyleTooltip",
                "Elige una barra de desgaste o un marco con el color del objeto."))
        if wearStyleAdded and wearStyleOption then
            corpseWearStyleOption = wearStyleOption
            if type(wearStyleOption.addItem) == "function" then
                pcall(wearStyleOption.addItem, wearStyleOption,
                    translated("UI_ChilaSeda_ViewpointFix_CorpseWearStyleBar", "Barra de desgaste"), true)
                pcall(wearStyleOption.addItem, wearStyleOption,
                    translated("UI_ChilaSeda_ViewpointFix_CorpseWearStyleFrame", "Marco de color"), false)
            end
        end
    end
    if type(page.addSlider) == "function" then
        local scaleAdded, scaleOption = pcall(page.addSlider, page,
            CORPSE_PANEL_SCALE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_CorpsePanelScale", "Zoom del panel de botin"),
            1, 2, 0.05, DEFAULT_CORPSE_PANEL_SCALE,
            translated("UI_ChilaSeda_ViewpointFix_CorpsePanelScaleTooltip",
                "Aumenta el panel flotante del cadaver, incluidos sus iconos y texto."))
        if scaleAdded then corpsePanelScaleOption = scaleOption end
    end
    if type(page.addSeparator) == "function" then pcall(page.addSeparator, page) end
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_HaloNotesTitle", "Halo Notes"))
    end
    if type(page.addTickBox) == "function" then
        local added, option = pcall(page.addTickBox, page, HALO_XP_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_HaloXPEnabled", "Mensajes de experiencia"), true,
            translated("UI_ChilaSeda_ViewpointFix_HaloXPEnabledTooltip",
                "Muestra u oculta los mensajes de experiencia en Halo Notes."))
        if added then haloXpOption = option end
    end
    page.apply = applyOptions
    applyOptions()
end

if Events and Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then
    Events.OnGameBoot.Add(installOptions)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(function() installOptions(); applyOptions() end)
end
installOptions()
