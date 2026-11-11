-- Localize the literal option strings supplied by Viewpoint Foraging.
-- The Workshop module passes display text directly to PZAPI.ModOptions, so
-- the language pack cannot replace these labels until the page is assembled.

local TAG = "[ChilaSeda_ViewpointForagingSpanishOptions] "

local TRANSLATION_KEYS = {
    ["Viewpoint Foraging"] = "IGUI_VPF_OptionsPage",
    ["3D foraging (Project Viewpoint)"] = "IGUI_VPF_OptionsTitleMain",
    ["Foraging in 3D"] = "IGUI_VPF_OptionsEnabled",
    ["Place search-mode pins, arrows and the search radius in Viewpoint's first and third person views. Off: vanilla behaviour."] = "IGUI_VPF_OptionsEnabledTooltip",
    ["Forage / pick up what the crosshair targets"] = "IGUI_VPF_OptionsPickKey",
    ["Aim near a pin while search mode is on, then press this key. Same as double-clicking the pin."] = "IGUI_VPF_OptionsPickKeyTooltip",
    ["Pins"] = "IGUI_VPF_OptionsPinsTitle",
    ["Pin size"] = "IGUI_VPF_OptionsPinSize",
    ["Size of the pins in 3D."] = "IGUI_VPF_OptionsPinSizeTooltip",
    ["Hide pins outside the search radius"] = "IGUI_VPF_OptionsHideOutside",
    ["Pins fade out past your current search radius, like the dark ring in 2D."] = "IGUI_VPF_OptionsHideOutsideTooltip",
    ["Crosshair assist"] = "IGUI_VPF_OptionsAssist",
    ["The pin nearest your crosshair is ringed and can be taken with the key above."] = "IGUI_VPF_OptionsAssistTooltip",
    ["Crosshair assist reach (tiles)"] = "IGUI_VPF_OptionsReach",
    ["Farthest pin the crosshair assist will pick."] = "IGUI_VPF_OptionsReachTooltip",
    ["Search eye height (0 = top, 1 = bottom)"] = "IGUI_VPF_OptionsEyeHeight",
    ["Where the search-mode eye sits on screen in 3D."] = "IGUI_VPF_OptionsEyeHeightTooltip",
    ["Mark found ground tracks in 3D"] = "IGUI_VPF_OptionsTrackMarkers",
    ["Footprints and grazed plants you find while tracking get a marker, since ground decals can be hard to see in 3D."] = "IGUI_VPF_OptionsTrackMarkersTooltip",
    ["Arrows"] = "IGUI_VPF_OptionsArrowsTitle",
    ["Arrows towards things off screen"] = "IGUI_VPF_OptionsArrows",
    ["When something is spotted outside your view, an arrow on the screen border points to it."] = "IGUI_VPF_OptionsArrowsTooltip",
    ["Arrow size (px)"] = "IGUI_VPF_OptionsArrowSize",
    ["Size of the nearest arrows. Arrows to farther finds are drawn smaller and fainter."] = "IGUI_VPF_OptionsArrowSizeTooltip",
    ["Arrow border (px)"] = "IGUI_VPF_OptionsArrowBorder",
    ["How far from the screen edge the arrows stay, so they are never cut off."] = "IGUI_VPF_OptionsArrowBorderTooltip",
    ["Search radius"] = "IGUI_VPF_OptionsSearchRadiusTitle",
    ["Bubble size"] = "IGUI_VPF_OptionsBubbleSize",
    ["Level-based: grows with your Foraging level; penalties (stress, tiredness, pain, clothing, weather, darkness, running) shrink it, but never below the share set below. Exact: the game's own search radius, which stacked penalties can push to the 3-tile minimum at any level."] = "IGUI_VPF_OptionsBubbleSizeTooltip",
    ["Level-based (penalties shrink it)"] = "IGUI_VPF_OptionsBubbleLevelBased",
    ["Exact game radius"] = "IGUI_VPF_OptionsBubbleExact",
    ["Penalties can shrink the bubble to (share of level size)"] = "IGUI_VPF_OptionsPenaltyFloor",
    ["0.5 = with every penalty maxed, the bubble is half its size for your level. 1 = penalties do nothing."] = "IGUI_VPF_OptionsPenaltyFloorTooltip",
    ["Fog outside the search radius"] = "IGUI_VPF_OptionsFog",
    ["While search mode is on, Viewpoint's fog closes in to your search radius so you cannot see past it."] = "IGUI_VPF_OptionsFogTooltip",
    ["Fog style"] = "IGUI_VPF_OptionsFogStyle",
    ["Dark: outside the radius goes dark (closest to 2D). Mist: outside goes hazy in the sky's colour."] = "IGUI_VPF_OptionsFogStyleTooltip",
    ["Dark"] = "IGUI_VPF_OptionsFogDark",
    ["Mist"] = "IGUI_VPF_OptionsFogMist",
    ["Fog strength"] = "IGUI_VPF_OptionsFogStrength",
    ["0 turns the fog off."] = "IGUI_VPF_OptionsFogStrengthTooltip",
    ["Fog edge softness (tiles)"] = "IGUI_VPF_OptionsFogFeather",
    ["Round fog bubble (own fog layer)"] = "IGUI_VPF_OptionsPackFog",
    ["The mod draws its own fog layer: a clean circle around you, and it also works with Minecraft shader packs (Bliss, BSL, Complementary...). Turn off to use Viewpoint's built-in fog instead (Minecraft packs then get no bubble)."] = "IGUI_VPF_OptionsPackFogTooltip",
}

local function localized(value)
    if type(value) ~= "string" then return value end
    local key = TRANSLATION_KEYS[value]
    if not key or type(getTextOrNull) ~= "function" then return value end
    local translated = getTextOrNull(key)
    if type(translated) == "string" and translated ~= "" and translated ~= key then
        return translated
    end
    return value
end

local function applyTranslations()
    local modOptions = PZAPI and PZAPI.ModOptions
    if not modOptions or type(modOptions.getOptions) ~= "function" then return end
    local ok, page = pcall(modOptions.getOptions, modOptions, "ViewpointForaging")
    if not ok or not page or type(page.data) ~= "table" then return end

    page.name = localized(page.name)
    for _, option in ipairs(page.data) do
        option.name = localized(option.name)
        option.tooltip = localized(option.tooltip)
        option.text = localized(option.text)
        if type(option.values) == "table" then
            for index, entry in ipairs(option.values) do
                if type(entry) == "string" then
                    option.values[index] = localized(entry)
                elseif type(entry) == "table" then
                    entry.name = localized(entry.name)
                end
            end
        end
    end

    if not page.ChilaSedaSpanishOptionsLogged then
        page.ChilaSedaSpanishOptionsLogged = true
        print(TAG .. "localized Viewpoint Foraging options when Spanish keys are available")
    end
end

applyTranslations()
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(applyTranslations) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(applyTranslations) end
    if Events.OnGameStart then Events.OnGameStart.Add(applyTranslations) end
end
