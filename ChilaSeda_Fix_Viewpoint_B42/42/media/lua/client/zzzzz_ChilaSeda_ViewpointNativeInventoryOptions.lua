local TAG = "[ChilaSeda_ViewpointInventoryOptions] "
local MOD_OPTIONS_ID = "ChilaSeda_ViewpointNativeInventory"
local OPTION_ID = "integratedInventoryUI"
local TRACE_ENABLED = true
local MAX_TRACE_LINES = 24

local page
local option
local traceLines = 0

local function trace(event, details)
    if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    print(TAG .. "event=" .. tostring(event) .. " " .. tostring(details or ""))
end

local function translated(key, fallback)
    if type(getTextOrNull) ~= "function" then return fallback end
    local ok, value = pcall(getTextOrNull, key)
    if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    return fallback
end

local function bridge()
    local value = ChilaSedaViewpointInventoryOptionsJ
    if type(value) ~= "table"
        or type(value.integratedInventoryEnabled) ~= "function"
        or type(value.setIntegratedInventoryEnabled) ~= "function" then
        return nil
    end
    return value
end

local function nativeState()
    local native = bridge()
    if not native then return -1 end
    local ok, state = pcall(native.integratedInventoryEnabled)
    if not ok or type(state) ~= "number" or (state ~= 0 and state ~= 1) then return -1 end
    return state
end

local function setOptionEnabled(enabled)
    if option and type(option.setEnabled) == "function" then
        pcall(option.setEnabled, option, enabled)
    end
end

local function setOptionValue(enabled)
    if not option then return end
    if type(option.setValue) == "function" then
        pcall(option.setValue, option, enabled)
    else
        pcall(function() option.value = enabled end)
    end
end

local function refreshAvailability()
    local state = nativeState()
    setOptionEnabled(state >= 0)
    if state < 0 then
        trace("native-setting-fallback", "result=unavailable option=disabled")
    else
        setOptionValue(state == 1)
        trace("native-setting-ready", "integrated-ui=" .. tostring(state == 1))
    end
end

local function applyOptions(enabled)
    local native = bridge()
    if not native or not option or type(option.getValue) ~= "function" then
        trace("apply-fallback", "reason=native-bridge-or-option-unavailable")
        return
    end
    if type(enabled) ~= "boolean" then
        local okValue, current = pcall(option.getValue, option)
        if okValue then enabled = current end
    end
    if type(enabled) ~= "boolean" then
        trace("apply-fallback", "reason=invalid-option-value")
        return
    end
    local okSet, result = pcall(native.setIntegratedInventoryEnabled, enabled)
    if okSet and result == 1 then
        trace("apply-result", "result=saved integrated-ui=" .. tostring(enabled))
    else
        local current = nativeState()
        if current >= 0 then setOptionValue(current == 1) end
        trace("apply-fallback", "reason=native-save-failed integrated-ui=" .. tostring(enabled))
    end
end

local function installNativeStateReloadSync()
    if not PZAPI or not PZAPI.ModOptions or PZAPI.ModOptions.chilaSedaViewpointInventorySync then return end
    local originalLoad = PZAPI.ModOptions.load
    if type(originalLoad) ~= "function" then
        trace("load-sync-fallback", "reason=mod-options-load-unavailable")
        return
    end
    PZAPI.ModOptions.load = function(self, ...)
        local result = originalLoad(self, ...)
        local state = nativeState()
        if state >= 0 then
            setOptionValue(state == 1)
            trace("load-sync", "result=native-value-restored integrated-ui=" .. tostring(state == 1))
        else
            trace("load-sync-fallback", "reason=native-setting-unavailable")
        end
        return result
    end
    PZAPI.ModOptions.chilaSedaViewpointInventorySync = true
end

local function installOptions()
    if page then
        refreshAvailability()
        return
    end
    if not (PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.create) == "function") then
        trace("registration-fallback", "reason=pzapi-mod-options-unavailable")
        return
    end

    local current = nativeState()
    local options = PZAPI.ModOptions.Dict and PZAPI.ModOptions.Dict[MOD_OPTIONS_ID]
    if options then
        page = options
    else
        local ok, created = pcall(PZAPI.ModOptions.create, PZAPI.ModOptions,
            MOD_OPTIONS_ID, "Viewpoint")
        if not ok or not created then
            trace("registration-fallback", "reason=page-create-failed")
            return
        end
        page = created
    end

    if type(page.addTitle) == "function" then
        pcall(page.addTitle, page, translated(
            "UI_ChilaSeda_ViewpointNativeInventory_Title", "Inventario integrado"))
    end
    if type(page.addTickBox) ~= "function" then
        trace("registration-fallback", "reason=tickbox-api-unavailable")
        return
    end
    local ok, createdOption = pcall(page.addTickBox, page, OPTION_ID,
        translated("UI_ChilaSeda_ViewpointNativeInventory_Enabled", "Usar el inventario integrado de Viewpoint"),
        current == 1,
        translated("UI_ChilaSeda_ViewpointNativeInventory_EnabledTooltip",
            "En primera o tercera persona, activa la pantalla de inventario de Viewpoint para usarla con I, Tab y los iconos laterales. Desactivado: Viewpoint usa las ventanas vanilla."))
    if not ok or not createdOption then
        trace("registration-fallback", "reason=tickbox-create-failed")
        return
    end
    option = createdOption
    option.onChangeApply = function(_, enabled)
        applyOptions(enabled)
    end
    setOptionEnabled(current >= 0)
    installNativeStateReloadSync()
    trace("page-registered", "modOptionsId=" .. MOD_OPTIONS_ID .. " native-state=" .. tostring(current))
end

if Events and Events.OnGameBoot and type(Events.OnGameBoot.Add) == "function" then
    Events.OnGameBoot.Add(installOptions)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installOptions)
end

installOptions()
