-- Localiza solo los textos visibles de las páginas PZAPI indicadas.
-- Los valores funcionales de los controles permanecen intactos.
local TRANSLATED_PAGES = {
    ProjectViewpointQOL = true,
    Viewpoint = true,
    ProjectViewpointADS = true,
    ViewpointBloodFX = true,
    ViewpointBloodFXAddon = true,
    ViewpointAdvancedThrowables = true,
    ViewpointTactical = true,
    WayMoreCarsOptionsID = true,
    ["MiniCompass.Client"] = true,
    visual_sound_extended_b42 = true,
    HeliEvent = true,
    P4HasBeenRead = true,
}

local function translate(pageId, value)
    if type(value) ~= "string" then return value end
    if type(getTextOrNull) ~= "function" then return value end
    local key = "IGUI_ES_PZAPI_" .. tostring(pageId) .. "_" .. value
    local translated = getTextOrNull(key)
    if type(translated) == "string" and translated ~= "" and translated ~= key then
        return translated
    end
    return value
end

local function translateOption(option, pageId)
    if type(option) ~= "table" then return end
    if type(option.name) == "string" then option.name = translate(pageId, option.name) end
    if type(option.tooltip) == "string" then option.tooltip = translate(pageId, option.tooltip) end
    if type(option.text) == "string" then option.text = translate(pageId, option.text) end
    if type(option.category) == "string" then option.category = translate(pageId, option.category) end
    if type(option.title) == "string" then option.title = translate(pageId, option.title) end
    if type(option.label) == "string" then option.label = translate(pageId, option.label) end
    if type(option.description) == "string" then option.description = translate(pageId, option.description) end

    -- Combo-box labels are visible text; their values and selected indices are settings.
    if type(option.values) == "table" then
        for index, entry in pairs(option.values) do
            if type(entry) == "string" then
                option.values[index] = translate(pageId, entry)
            elseif type(entry) == "table" and type(entry.name) == "string" then
                entry.name = translate(pageId, entry.name)
            end
        end
    end
end

local function applyTranslations()
    local modOptions = PZAPI and PZAPI.ModOptions
    if not modOptions or type(modOptions.getOptions) ~= "function" then return end

    for pageId in pairs(TRANSLATED_PAGES) do
        local ok, page = pcall(modOptions.getOptions, modOptions, pageId)
        if ok and page then
            if type(page.name) == "string" then page.name = translate(pageId, page.name) end
            if type(page.description) == "string" then page.description = translate(pageId, page.description) end
            if type(page.data) == "table" then
                for _, option in ipairs(page.data) do translateOption(option, pageId) end
            end
        end
    end
end

applyTranslations()
if Events then
    if Events.OnGameBoot then Events.OnGameBoot.Add(applyTranslations) end
    if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(applyTranslations) end
    if Events.OnGameStart then Events.OnGameStart.Add(applyTranslations) end
end
