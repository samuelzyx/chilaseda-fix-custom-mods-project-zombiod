-- Mod Options control for the integrated Viewpoint search fog.
local TAG = "[ChilaSeda_ViewpointNativeFogOptions] "
local MOD_ID = "ChilaSeda_Fix_Viewpoint_B42"
local OPTION_ID = "searchFogStrength"
local DEFAULT_STRENGTH = 1
local optionPage
local strengthOption

ChilaSedaViewpointNativeFogStrength = DEFAULT_STRENGTH

local function currentStrength()
    if not strengthOption or type(strengthOption.getValue) ~= "function" then
        return ChilaSedaViewpointNativeFogStrength
    end
    local ok, value = pcall(strengthOption.getValue, strengthOption)
    if not ok or type(value) ~= "number" then return ChilaSedaViewpointNativeFogStrength end
    return math.max(0, math.min(1, value))
end

local function applyOptions()
    ChilaSedaViewpointNativeFogStrength = currentStrength()
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
    if type(page.addSlider) == "function" then
        local added, option = pcall(page.addSlider, page, OPTION_ID,
            translated("UI_ChilaSeda_ViewpointFix_FogStrength", "Fog intensity"),
            0, 1, 0.05, DEFAULT_STRENGTH,
            translated("UI_ChilaSeda_ViewpointFix_FogStrengthTooltip",
                "Lower this value to make search fog less dense; 0 disables it."))
        if added then strengthOption = option end
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
