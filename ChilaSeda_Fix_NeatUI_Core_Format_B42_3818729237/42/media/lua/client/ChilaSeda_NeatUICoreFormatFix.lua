-- Keep NeatUI Core's percentage labels intact while escaping them for getText/String.format.
local function fixNeatUICoreLabels()
    local api = PZAPI and PZAPI.ModOptions
    local options = api and api:getOptions("NeatUI_Core")
    if not options then return end

    local iconScale = options:getOption("ICON_SCALE")
    if iconScale and iconScale.name == "Icon size (%)" then
        iconScale.name = "Icon size (%%)"
    end

    local opacity = options:getOption("OPACITY")
    if opacity and opacity.name == "Window body opacity (%)" then
        opacity.name = "Window body opacity (%%)"
    end
end

fixNeatUICoreLabels()

-- Apply again immediately before vanilla builds the mod-options panel.
if MainOptions and MainOptions.addModOptionsPanel
        and not MainOptions.chilaSedaNeatUICoreFormatFixHooked then
    MainOptions.chilaSedaNeatUICoreFormatFixHooked = true
    local build = MainOptions.addModOptionsPanel
    function MainOptions:addModOptionsPanel(...)
        fixNeatUICoreLabels()
        return build(self, ...)
    end
end
