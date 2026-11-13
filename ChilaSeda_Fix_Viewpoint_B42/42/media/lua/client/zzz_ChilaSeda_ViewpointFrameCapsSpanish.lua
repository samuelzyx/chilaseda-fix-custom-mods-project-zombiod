local function translated(key, fallback)
    if type(getTextOrNull) == "function" then
        local value = getTextOrNull(key)
        if type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function installSpanishFrameCapLabels()
    if not MainOptions or MainOptions.chilaFrameCapLabelsInstalled
            or type(MainOptions.addDisplayPanel) ~= "function"
            or type(MainOptions.addCombo) ~= "function" then
        return
    end

    local originalDisplayPanel = MainOptions.addDisplayPanel
    MainOptions.addDisplayPanel = function(self, ...)
        local originalAddCombo = MainOptions.addCombo
        local menuRateLabel = translated("UI_ChilaSeda_Viewpoint_MenuFramerate", "Menu framerate")
        local sameAsGame = translated("UI_ChilaSeda_Viewpoint_SameAsGame", "Same as in-game")

        MainOptions.addCombo = function(page, x, y, w, h, name, options, selected, target, onchange)
            local isMenuRate = name == "Menu framerate"
            local combo = originalAddCombo(page, x, y, w, h,
                isMenuRate and menuRateLabel or name, options, selected, target, onchange)
            if isMenuRate and combo and type(combo.addOptionWithData) == "function" then
                local addOptionWithData = combo.addOptionWithData
                pcall(function()
                    combo.addOptionWithData = function(control, label, data, ...)
                        if label == "Same as in-game" then label = sameAsGame end
                        return addOptionWithData(control, label, data, ...)
                    end
                end)
            end
            return combo
        end

        local ok, result = pcall(originalDisplayPanel, self, ...)
        MainOptions.addCombo = originalAddCombo
        if not ok then error(result) end
        return result
    end
    MainOptions.chilaFrameCapLabelsInstalled = true
    print("[ChilaSeda_ViewpointFrameCapsSpanish] translated Viewpoint frame-cap labels")
end

installSpanishFrameCapLabels()
if Events and Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then
    Events.OnGameBoot.Add(installSpanishFrameCapLabels)
end
