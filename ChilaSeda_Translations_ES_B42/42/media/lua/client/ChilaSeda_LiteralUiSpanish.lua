local CONTEXT_KEYS = {
    ["No action available"] = "UI_MiniHealthPanel_NoActionAvailable",
    ["Open the journal"] = "UI_HunterExpansion_OpenJournal",
    ["Feeding zone information"] = "UI_HunterExpansion_FeederZoneInfo",
}

local logged = {}

local function traceOnce(event, detail)
    if logged[event] then return end
    logged[event] = true
    print("[ChilaSeda Literal Spanish] event=" .. event .. " " .. (detail or ""))
end

local function lookup(key)
    if type(getText) ~= "function" then
        traceOnce("translation-fallback", "key=" .. key .. " reason=getText-unavailable")
        return nil
    end
    local ok, value = pcall(getText, key)
    if ok and type(value) == "string" and value ~= "" and value ~= key then
        return value
    end
    traceOnce("translation-fallback", "key=" .. key .. " reason=key-unavailable")
    return nil
end

local function translateContextLabel(value)
    if type(value) ~= "string" then return value, false end

    local key = CONTEXT_KEYS[value]
    if key then
        local translated = lookup(key)
        if translated then
            traceOnce("menu-label-translated", "source=" .. value)
            return translated, false
        end
        return value, false
    end

    local sourcePrefix = "Fill with "
    if string.sub(value, 1, #sourcePrefix) == sourcePrefix then
        local translatedPrefix = lookup("UI_HunterExpansion_FeederFillPrefix")
        if translatedPrefix then
            traceOnce("menu-label-translated", "source=Fill with <localized item>")
            return translatedPrefix .. string.sub(value, #sourcePrefix + 1), true
        end
    end

    return value, false
end

local function translateFeederTooltip(value)
    if type(value) ~= "string" then return value end
    local units, multiplier = string.match(value, "^(%d+) units, worth x([%d%.]+) to a boar%.$")
    if not units then return value end

    local template = lookup("UI_HunterExpansion_FeederTooltip")
    if not template then return value end
    local ok, translated = pcall(string.format, template, units, multiplier)
    if not ok or type(translated) ~= "string" then
        traceOnce("tooltip-fallback", "reason=format-failed")
        return value
    end
    traceOnce("feeder-tooltip-translated", "units=" .. units .. " multiplier=" .. multiplier)
    return translated
end

local function watchFeederTooltip(option)
    if type(option) ~= "table" or type(getmetatable) ~= "function" or type(setmetatable) ~= "function" then
        traceOnce("tooltip-fallback", "reason=option-metatable-unavailable")
        return
    end

    local oldMetatable = getmetatable(option)
    if oldMetatable ~= nil then
        traceOnce("tooltip-fallback", "reason=option-already-has-metatable")
        return
    end

    local watcher = {}
    watcher.__newindex = function(target, key, value)
        if key == "toolTip" then
            setmetatable(target, oldMetatable)
            if type(value) == "table" and type(value.description) == "string" then
                value.description = translateFeederTooltip(value.description)
            end
            rawset(target, key, value)
            return
        end
        rawset(target, key, value)
    end

    local ok = pcall(setmetatable, option, watcher)
    if not ok then traceOnce("tooltip-fallback", "reason=setmetatable-failed") end
end

local function installContextMenu()
    local menu = ISContextMenu
    if not menu or menu.chilaLiteralUiSpanishInstalled or type(menu.addOption) ~= "function" then return end

    local original = menu.addOption
    menu.addOption = function(self, name, ...)
        local translatedName, watchTooltip = translateContextLabel(name)
        local option = original(self, translatedName, ...)
        if watchTooltip then watchFeederTooltip(option) end
        return option
    end
    menu.chilaLiteralUiSpanishInstalled = true
    traceOnce("context-menu-hook-installed", "targets=MiniHealthPanel,HunterExpansion")
end

local function installViewpointMenuLabel()
    local options = MainOptions
    if not options or options.chilaLiteralUiSpanishInstalled or type(options.addCombo) ~= "function" then return end

    local original = options.addCombo
    options.addCombo = function(page, x, y, width, height, name, ...)
        if name == "Menu framerate" then
            local translated = lookup("UI_Viewpoint_MenuFramerate")
            if translated then
                name = translated
                traceOnce("viewpoint-label-translated", "source=Menu framerate")
            end
        end
        return original(page, x, y, width, height, name, ...)
    end
    options.chilaLiteralUiSpanishInstalled = true
    traceOnce("viewpoint-options-hook-installed", "target=Viewpoint-0.1.7")
end

local function install()
    installContextMenu()
    installViewpointMenuLabel()
end

install()
if Events then
    if Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then Events.OnGameBoot.Add(install) end
    if Events.OnMainMenuEnter and type(Events.OnMainMenuEnter.Add) == "function" then Events.OnMainMenuEnter.Add(install) end
end
