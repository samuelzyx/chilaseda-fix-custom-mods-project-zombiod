-- Mod Options control for the integrated Viewpoint search fog.
local TAG = "[ChilaSeda_ViewpointNativeFogOptions] "
local MOD_ID = "ChilaSeda_Fix_Viewpoint_B42"
local OPTION_ID = "searchFogStrength"
local ENABLE_OPTION_ID = "searchFogEnabled"
local STYLE_OPTION_ID = "searchFogStyle"
local FEATHER_OPTION_ID = "searchFogFeather"
local PACK_LAYER_OPTION_ID = "searchFogDepthLayer"
local PICKUP_KEY_OPTION_ID = "nativeForagePickupKey"
local DEFAULT_STRENGTH = 1
local DEFAULT_FEATHER = 3
local optionPage
local enabledOption
local styleOption
local strengthOption
local featherOption
local packLayerOption
local pickupKeyOption

ChilaSedaViewpointNativeFogStrength = DEFAULT_STRENGTH
ChilaSedaViewpointNativeFogEnabled = true
ChilaSedaViewpointNativeFogStyle = 0
ChilaSedaViewpointNativeFogFeather = DEFAULT_FEATHER
ChilaSedaViewpointShaderPackFogEnabled = true
ChilaSedaViewpointNativeForagePickupKey = Keyboard and Keyboard.KEY_G or 34

local function optionValue(option, fallback)
    if not option or type(option.getValue) ~= "function" then return fallback end
    local ok, value = pcall(option.getValue, option)
    if not ok then return fallback end
    return value
end

local function currentStrength()
    local value = optionValue(strengthOption, ChilaSedaViewpointNativeFogStrength)
    if type(value) ~= "number" then return ChilaSedaViewpointNativeFogStrength end
    return math.max(0, math.min(1, value))
end

local function applyOptions()
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
        MOD_ID, translated("UI_ChilaSeda_ViewpointFix_Page", "ChilaSeda Viewpoint Fix"))
    if not ok or not page then
        print(TAG .. "could not create Mod Options page")
        return
    end
    optionPage = page
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_FogTitle", "Native search fog"))
    end
    if type(page.addTickBox) == "function" then
        local added, option = pcall(page.addTickBox, page, ENABLE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogEnabled", "Enable search fog"), true,
            translated("UI_ChilaSeda_ViewpointFix_FogEnabledTooltip",
                "Show the search fog while native foraging mode is active."))
        if added then enabledOption = option end
    end
    if type(page.addComboBox) == "function" then
        local added, option = pcall(page.addComboBox, page, STYLE_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogStyle", "Fog style"),
            translated("UI_ChilaSeda_ViewpointFix_FogStyleTooltip",
                "Dark shades the area outside the search radius; Mist adds a softer haze."))
        if added and option then
            styleOption = option
            if type(option.addItem) == "function" then
                pcall(option.addItem, option,
                    translated("UI_ChilaSeda_ViewpointFix_FogDark", "Dark"), true)
                pcall(option.addItem, option,
                    translated("UI_ChilaSeda_ViewpointFix_FogMist", "Mist"), false)
            end
        end
    end
    if type(page.addSlider) == "function" then
        local added, option = pcall(page.addSlider, page, OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogStrength", "Fog intensity"),
            0, 1, 0.05, DEFAULT_STRENGTH,
            translated("UI_ChilaSeda_ViewpointFix_FogStrengthTooltip",
                "Lower this value to make search fog less dense; 0 disables it."))
        if added then strengthOption = option end
        local featherAdded, feather = pcall(page.addSlider, page, FEATHER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogFeather", "Fog feather"),
            0.5, 10, 0.5, DEFAULT_FEATHER,
            translated("UI_ChilaSeda_ViewpointFix_FogFeatherTooltip",
                "Controls how gradually the fog edge fades around the search radius."))
        if featherAdded then featherOption = feather end
    end
    if type(page.addTickBox) == "function" then
        local added, option = pcall(page.addTickBox, page, PACK_LAYER_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogDepthLayer", "Round depth fog layer"), true,
            translated("UI_ChilaSeda_ViewpointFix_FogDepthLayerTooltip",
                "Draw a circular fog layer from Viewpoint's depth buffer. Supports Iris and shader packs; turn off to use only Viewpoint's built-in fog."))
        if added then packLayerOption = option end
    end
    if type(page.addSeparator) == "function" then pcall(page.addSeparator, page) end
    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupTitle", "Native forage pickup"))
    end
    if type(page.addKeyBind) == "function" then
        local defaultKey = Keyboard and Keyboard.KEY_G or 34
        local added, option = pcall(page.addKeyBind, page, PICKUP_KEY_OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupKey", "Pick up aimed find"),
            defaultKey,
            translated("UI_ChilaSeda_ViewpointFix_ForagePickupKeyTooltip",
                "Aim at a visible native search find and press this key to start its normal pickup action."))
        if added then pickupKeyOption = option end
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
