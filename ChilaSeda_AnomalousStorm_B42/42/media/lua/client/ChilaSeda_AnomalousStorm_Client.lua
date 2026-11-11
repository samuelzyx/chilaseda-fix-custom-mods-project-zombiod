-- The overlay is shared by isometric and Viewpoint cameras. These helpers only
-- remove a leftover managed profile from older builds; active emissions do not
-- alter True Weathers profiles or settings.
local MOD_DATA_KEY = "AnomalousStorm"
local PROFILE_PATH = "TrueWeathers/profiles.txt"
local PROFILE_NAME = "ChilaSeda Anomalous Storm"
local BEGIN_MARKER = "# BEGIN ChilaSeda_AnomalousStorm_B42"
local END_MARKER = "# END ChilaSeda_AnomalousStorm_B42"
local GENERATED_FILE_MARKER = "# CREATED_BY_ChilaSeda_AnomalousStorm_B42"
local installedProfileLevel = nil
local syncBusy = false
local forcedViewpointOptions = false
local lastNotifiedPhase = nil
local lastMassDeathNoticeCycle = nil
local stormNoticeRouteLogged = false
local stormAlpha = 0
local stormPassed = false
local nextViewCheckMs = 0
local viewpointCameraActive = false
local lastPresentationViewpoint = nil
local lastOverlayCycleKey = nil
local VIEW_CHECK_INTERVAL_MS = 250
local ZOMBIE_SPEED_KEY = "ChilaSeda_AnomalousStorm_OriginalSpeed"
local ZOMBIE_DAMAGE_DUE_KEY = "ChilaSeda_AnomalousStorm_NextDamageAt"
local lastZombieExposureUpdateMs = 0
local cachedWorldMinutes = 0
local nextWorldMinuteRefreshMs = 0

local function registerModOptions()
    PZAPI = PZAPI or {}
    pcall(require, "PZAPI/ModOptions")
    if not PZAPI or not PZAPI.ModOptions then return end
    if PZAPI.ModOptions:getOptions("ChilaSeda_AnomalousStorm_B42") then return end

    local options = PZAPI.ModOptions:create("ChilaSeda_AnomalousStorm_B42", "IGUI_AnomalousStormOptions")
    local speedDefault = math.max(10, math.min(100,
        math.floor(tonumber(SandboxVars.AnomalousStormZombieSlowPercent) or 10)))
    local damageDefault = math.max(0, math.min(10,
        math.floor(tonumber(SandboxVars.AnomalousStormZombieDamagePerTenMinutes) or 10)))
    if damageDefault == 1 then damageDefault = 10 end -- Upgrade the previous 0.4.15 default.
    local speed = options:addSlider("ZombieSlowPercent", "IGUI_AnomalousStormZombieSlow", 10, 100, 1,
        speedDefault, "IGUI_AnomalousStormZombieSlowTooltip")
    speed.sandboxDefault = speedDefault
    local damage = options:addSlider("ZombieDamagePerTenMinutes", "IGUI_AnomalousStormZombieDamage", 0, 10, 1,
        damageDefault, "IGUI_AnomalousStormZombieDamageTooltip")
    damage.sandboxDefault = damageDefault
end

registerModOptions()

local function getZombieOption(optionId, sandboxName, fallback)
    local options = PZAPI and PZAPI.ModOptions
        and PZAPI.ModOptions:getOptions("ChilaSeda_AnomalousStorm_B42")
    local option = options and options:getOption(optionId)
    local value = tonumber(option and option:getValue())
    local sandboxValue = tonumber(SandboxVars[sandboxName])
    if option and option.sandboxDefault ~= nil then
        -- In single-player the local server reads the same SandboxVars table.
        local effective = value ~= nil and value ~= option.sandboxDefault
            and value or option.sandboxDefault
        SandboxVars[sandboxName] = effective
        return math.floor(effective)
    end
    return math.floor(sandboxValue or value or fallback)
end

local function restoreZombieSpeed(zombie)
    local data = zombie:getModData()
    local original = data and tonumber(data[ZOMBIE_SPEED_KEY])
    if original ~= nil then
        zombie:setSpeedMod(original)
        data[ZOMBIE_SPEED_KEY] = nil
    end
end

local function applySinglePlayerZombieExposure(zombie, state, worldMinutes)
    if not zombie or not instanceof(zombie, "IsoZombie") then return end
    -- Chunk streaming can leave a zombie's square alive briefly after its chunk
    -- has been detached. Do not change health, speed, or mod data in that window.
    local square = zombie:getCurrentSquare()
    if not square then return end
    local chunkOk, chunk = pcall(function() return square:getChunk() end)
    if not chunkOk or not chunk then return end

    local rainActive = state and state.RainActive == true
    local damagingRain = rainActive and state.Thunder == true
    local slowingRain = rainActive and state.ThunderStarted == true
    local slowPercent = math.max(10, math.min(100,
        getZombieOption("ZombieSlowPercent", "AnomalousStormZombieSlowPercent", 10)))
    local damagePerTenMinutes = math.max(0, math.min(10,
        getZombieOption("ZombieDamagePerTenMinutes", "AnomalousStormZombieDamagePerTenMinutes", 10))) / 100
    local data = zombie:getModData()
    local exposed = not zombie:isDead() and square:isOutside()
    if not exposed then
        restoreZombieSpeed(zombie)
        if data then data[ZOMBIE_DAMAGE_DUE_KEY] = nil end
        return
    end

    if slowingRain then
        local original = data and tonumber(data[ZOMBIE_SPEED_KEY])
        if original == nil then
            original = tonumber(zombie:getSpeedMod()) or 1
            if data then data[ZOMBIE_SPEED_KEY] = original end
        end
        -- Reapply during each native zombie update so AI movement updates cannot
        -- replace the weather multiplier between minute-based callbacks.
        zombie:setSpeedMod(original * slowPercent / 100)
    else
        restoreZombieSpeed(zombie)
    end

    if damagingRain and damagePerTenMinutes > 0 and data then
        local due = tonumber(data[ZOMBIE_DAMAGE_DUE_KEY])
        if due == nil then
            data[ZOMBIE_DAMAGE_DUE_KEY] = worldMinutes + 10
        elseif worldMinutes >= due then
            local ticks = math.floor((worldMinutes - due) / 10) + 1
            local health = tonumber(zombie:getHealth()) or 0
            if health > 0 then
                zombie:setHealth(math.max(0, health - damagePerTenMinutes * ticks))
            end
            data[ZOMBIE_DAMAGE_DUE_KEY] = due + ticks * 10
        end
    elseif data then
        data[ZOMBIE_DAMAGE_DUE_KEY] = nil
    end
end

local function updateSinglePlayerZombieExposure(zombie)
    -- In multiplayer the server owns zombie simulation; this path covers local
    -- single-player, whose Lua client owns both the weather and loaded zombies.
    if isClient() then return end
    local nowMs = getTimestampMs()
    if nowMs >= nextWorldMinuteRefreshMs then
        cachedWorldMinutes = getGameTime():getWorldAgeHours() * 60
        nextWorldMinuteRefreshMs = nowMs + 1000
    end
    local state = ModData.get(MOD_DATA_KEY)
    if isServer() and state then
        -- The local server's ten-minute callback owns health loss; this hook
        -- keeps the movement multiplier applied between server callbacks.
        state = { RainActive = state.RainActive, ThunderStarted = state.ThunderStarted, Thunder = false }
    end
    applySinglePlayerZombieExposure(zombie, state, cachedWorldMinutes)
end

local function updateSinglePlayerZombieExposureFallback()
    if isClient() then return end
    local nowMs = getTimestampMs()
    if nowMs - lastZombieExposureUpdateMs < 250 then return end
    lastZombieExposureUpdateMs = nowMs
    local state = ModData.get(MOD_DATA_KEY)
    local worldMinutes = getGameTime():getWorldAgeHours() * 60
    local cell = getCell()
    local zombies = cell and cell:getZombieList()
    if not zombies then return end
    if isServer() and state then
        state = { RainActive = state.RainActive, ThunderStarted = state.ThunderStarted, Thunder = false }
    end
    for index = 0, zombies:size() - 1 do
        applySinglePlayerZombieExposure(zombies:get(index), state, worldMinutes)
    end
end

local PROFILE_PALETTES = {
    start = {
        day = { sky = {1.7, 0.55, 0.45}, sun = {1.55, 0.55, 0.45}, fog = {1.5, 0.5, 0.45}, zenith = {1.65, 0.4, 0.35}, saturation = 1.1, contrast = 1.08, warmth = 0.22 },
        night = { sky = {1.8, 0.48, 0.35}, sun = {1.1, 0.45, 0.35}, fog = {1.5, 0.48, 0.38}, zenith = {1.7, 0.35, 0.28}, saturation = 1.15, contrast = 1.1, warmth = 0.3 },
    },
    peak = {
        day = { sky = {2.0, 0.3, 0.3}, sun = {2.0, 0.3, 0.3}, fog = {2.0, 0.3, 0.3}, zenith = {2.0, 0.3, 0.3}, saturation = 1.35, contrast = 1.18, warmth = 0.3 },
        night = { sky = {1.8, 0.3, 0.3}, sun = {1.1, 0.3, 0.3}, fog = {1.5, 0.3, 0.3}, zenith = {1.8, 0.3, 0.3}, saturation = 1.25, contrast = 1.12, warmth = 0.3 },
    },
    after = {
        day = { sky = {1.45, 0.72, 0.65}, sun = {1.4, 0.72, 0.65}, fog = {1.3, 0.7, 0.65}, zenith = {1.4, 0.65, 0.6}, saturation = 1.02, contrast = 1.04, warmth = 0.12 },
        night = { sky = {1.5, 0.65, 0.55}, sun = {1.05, 0.65, 0.55}, fog = {1.3, 0.62, 0.55}, zenith = {1.5, 0.55, 0.48}, saturation = 1.0, contrast = 1.05, warmth = 0.2 },
    },
}

local function rgbText(rgb)
    return string.format("%.2f %.2f %.2f", rgb[1], rgb[2], rgb[3])
end

local function appendWeatherProfile(lines, name, palette, weather, hours)
    lines[#lines + 1] = "[" .. name .. "]"
    lines[#lines + 1] = "seasons = all"
    lines[#lines + 1] = "weather = " .. weather
    lines[#lines + 1] = "hours = " .. hours
    lines[#lines + 1] = "sky = " .. rgbText(palette.sky)
    lines[#lines + 1] = "sun = " .. rgbText(palette.sun)
    lines[#lines + 1] = "fog = " .. rgbText(palette.fog)
    lines[#lines + 1] = "zenith = " .. rgbText(palette.zenith)
    lines[#lines + 1] = "saturation = " .. tostring(palette.saturation)
    lines[#lines + 1] = "contrast = " .. tostring(palette.contrast)
    lines[#lines + 1] = "warmth = " .. tostring(palette.warmth)
    lines[#lines + 1] = "weight = 2"
end

local function makeProfileText(level)
    local palette = PROFILE_PALETTES[level] or PROFILE_PALETTES.start
    local lines = { BEGIN_MARKER }
    local allWeather = "clear overcast fog rain storm snow blizzard approach afterrain"
    appendWeatherProfile(lines, PROFILE_NAME .. " - Day", palette.day, allWeather, "5-21")
    appendWeatherProfile(lines, PROFILE_NAME .. " - Night", palette.night, allWeather, "21-5")
    -- Replace True Weathers' default cool blue night grades only while this emission is active.
    appendWeatherProfile(lines, "Rainy night", palette.night, "rain storm", "21-5")
    appendWeatherProfile(lines, "Clear night", palette.night, "clear", "22-4.5")
    lines[#lines + 1] = END_MARKER
    return lines
end

local function readProfile()
    local reader
    local ok, result = pcall(function()
        reader = getFileReader(PROFILE_PATH, false)
        if not reader then return nil end
        local lines = {}
        while true do
            local line = reader:readLine()
            if line == nil then break end
            lines[#lines + 1] = line
        end
        return lines
    end)
    if reader then pcall(function() reader:close() end) end
    if not ok then
        print("[Anomalous Storm] Could not read Viewpoint profiles: " .. tostring(result))
        return nil, result
    end
    return result, nil
end

local function hasManagedProfile(lines)
    if not lines then return false end
    for _, line in ipairs(lines) do
        if line == BEGIN_MARKER then return true end
    end
    return false
end

local function withoutManagedProfile(lines)
    local out, skipping = {}, false
    for _, line in ipairs(lines or {}) do
        if line == BEGIN_MARKER then
            skipping = true
        elseif line == END_MARKER then
            skipping = false
        elseif not skipping then
            out[#out + 1] = line
        end
    end
    return out
end

local function makeBackup(lines)
    if not lines then return true end
    local stamp = os.date("%Y%m%d_%H%M%S")
    local backupDir = "mods/backups/" .. stamp .. "/TrueWeathers"
    local path = backupDir .. "/profiles.txt"
    local writer
    local ok, err = pcall(function()
        writer = getFileWriter(path, true, false)
        if not writer then error("backup writer unavailable") end
        for _, line in ipairs(lines) do writer:write(line .. "\r\n") end
    end)
    if writer then pcall(function() writer:close() end) end
    if not ok then print("[Anomalous Storm] Backup failed; profile was not changed: " .. tostring(err)) end
    return ok
end

local function writeProfile(lines)
    local writer
    local ok, err = pcall(function()
        writer = getFileWriter(PROFILE_PATH, true, false)
        if not writer then error("profile writer unavailable") end
        for _, line in ipairs(lines) do writer:write(line .. "\r\n") end
    end)
    if writer then pcall(function() writer:close() end) end
    if not ok then print("[Anomalous Storm] Could not update Viewpoint profiles: " .. tostring(err)) end
    return ok
end

local function reloadViewpointProfiles()
    if not VTWJ or not VTWJ.reloadProfiles then
        print("[Anomalous Storm] Viewpoint True Weathers profile reload API is unavailable.")
        return false
    end
    local ok, err = pcall(function() VTWJ.reloadProfiles() end)
    if not ok then print("[Anomalous Storm] Viewpoint profile reload failed: " .. tostring(err)) end
    return ok
end

local function refreshViewpointCameraMode(force)
    local now = getTimestampMs()
    if not force and now < nextViewCheckMs then return viewpointCameraActive end
    nextViewCheckMs = now + VIEW_CHECK_INTERVAL_MS

    if not VTWJ or not VTWJ.getState then
        viewpointCameraActive = false
        return viewpointCameraActive
    end
    local viewState = {}
    local ok, available = pcall(VTWJ.getState, viewState)
    if ok and available ~= false then
        viewpointCameraActive = viewState.firstPerson == true
            or viewState.thirdPerson == true or viewState.view == true
    end
    return viewpointCameraActive
end

local function enforceViewpointForEmission(active)
    if active then
        if not VTWJ or not VTW or not VTW.settings then return end
        local settings = VTW.settings
        local thunderVolume = tonumber(settings.thunderVolume) or 0.8
        local configuredForEmission = settings.enabled ~= false and settings.stormSky ~= false
            and settings.profiles == true and settings.usePack ~= false
            and tonumber(settings.precipitation or 3) > 1 and settings.lightning ~= false
            and settings.cloudFlashes ~= false and thunderVolume > 0
        if forcedViewpointOptions and configuredForEmission then return end
        local ok, err = pcall(function()
            if VTWJ.setSettings then
                VTWJ.setSettings(true, math.max(0, (tonumber(settings.quality) or 3) - 1), 2,
                    settings.wind ~= false, settings.wetSurfaces ~= false,
                    math.max(0, (tonumber(settings.haze) or 3) - 1), true,
                    tonumber(settings.lightningBrightness) or 1.0, true,
                    math.max(0.8, thunderVolume), settings.debug == true)
            end
            if VTWJ.setFeatures then
                VTWJ.setFeatures(true, true, settings.hail ~= false,
                    settings.blizzard ~= false, settings.windows ~= false, settings.windshield ~= false,
                    settings.autoWipers ~= false, settings.lightningShadows ~= false,
                    settings.snowCover ~= false, settings.farWeather ~= false)
            end
            if VTWJ.setUsePack then VTWJ.setUsePack(true) end
        end)
        if ok then
            forcedViewpointOptions = true
        else
            print("[Anomalous Storm] Could not enable the required Viewpoint shader/profile options: " .. tostring(err))
        end
    elseif forcedViewpointOptions then
        local ok, err = pcall(function()
            if VTW and VTW.push then VTW.push() end
        end)
        if not ok then print("[Anomalous Storm] Could not restore Viewpoint options: " .. tostring(err)) end
        forcedViewpointOptions = false
    end
end

local function setEmissionProfile(level)
	local active = level ~= nil and PROFILE_PALETTES[level] ~= nil
	local targetLevel = active and level or nil
	if syncBusy or installedProfileLevel == targetLevel then return end
    syncBusy = true

    local lines, readError = readProfile()
    if readError then
        syncBusy = false
        return
    end
    local existedBefore = lines ~= nil
    if lines == nil then lines = {} end
    local existed = hasManagedProfile(lines)
    local updated = withoutManagedProfile(lines)
	if active then
        if not existedBefore then table.insert(updated, 1, GENERATED_FILE_MARKER) end
		for _, line in ipairs(makeProfileText(targetLevel)) do updated[#updated + 1] = line end
    else
        local onlyGeneratedMarker = true
        local cleaned = {}
        for _, line in ipairs(updated) do
            if line ~= GENERATED_FILE_MARKER then
                cleaned[#cleaned + 1] = line
                if line:match("%S") then onlyGeneratedMarker = false end
            end
        end
        updated = cleaned
        if onlyGeneratedMarker then updated = {} end
    end

	local needsWrite = active or existed
    local success = true
    if needsWrite then
        success = makeBackup(existedBefore and lines or nil) and writeProfile(updated)
    end
    if success and (active or existed) and VTWJ then
        success = reloadViewpointProfiles()
    elseif success and active then
        success = false
    end
	if success then installedProfileLevel = targetLevel end
    syncBusy = false
end

local function updatePresentation(state, forceModeCheck)
    -- Keep True Weathers' user settings untouched. The same fullscreen red mask
    -- used in isometric view is rendered over Viewpoint cameras as well.
    enforceViewpointForEmission(false)
    setEmissionProfile(nil)
    lastPresentationViewpoint = refreshViewpointCameraMode(forceModeCheck)
end

local function showStormNotice(player, message, color)
	if not player or player:isDead() or type(message) ~= "string" or message == "" then return false end
	pcall(require, "ChilaSeda_ViewpointHaloNotifications")
	local notifications = ChilaSeda_ViewpointHaloNotifications
	if notifications and type(notifications.showFixed) == "function" then
		local ok, shown = pcall(notifications.showFixed, message, color)
		if ok and shown then
			if not stormNoticeRouteLogged then
				stormNoticeRouteLogged = true
				print("[Anomalous Storm] Halo notice queued through Viewpoint fixed overlay.")
			end
			return true
		end
	end
	if HaloTextHelper and HaloTextHelper.addText then
		local ok = pcall(HaloTextHelper.addText, player, message, " ",
			math.floor(color.r * 255), math.floor(color.g * 255), math.floor(color.b * 255))
		if ok then
			if not stormNoticeRouteLogged then
				stormNoticeRouteLogged = true
				print("[Anomalous Storm] Halo notice queued through HaloTextHelper fallback.")
			end
			return true
		end
	end
	return false
end

local function phaseNotice(phase)
	if phase == "warning" then
		return "Algo no anda bien con el clima...", { r = 1, g = 0.25, b = 0.20 }
	elseif phase == "rain-ramping" then
		return "El clima esta raro...", { r = 1, g = 0.25, b = 0.20 }
	elseif phase == "thunderstorm" then
		return "La tormenta ha alcanzado su punto mas peligroso.", { r = 1, g = 0.20, b = 0.15 }
	elseif phase == "clearing" then
		return "La tormenta parece estar cediendo.", { r = 0.80, g = 0.80, b = 0.80 }
	end
	return nil, nil
end

local function notifyPhase(player, phase)
	if not phase or phase == lastNotifiedPhase then return false end
	local message, color = phaseNotice(phase)
	if not message then
		lastNotifiedPhase = phase
		return true
	end
	if not player or player:isDead() then return false end
	if showStormNotice(player, message, color) then
		lastNotifiedPhase = phase
		return true
	end
	return false
end

local function notifyMassDeath(state)
	if state.ExposedPopulationEliminated ~= true then return end
	local cycle = state.DebugOverride == true
		and ("debug:" .. tostring(state.DebugRunId or state.DebugStartedAt))
		or ("scheduled:" .. tostring(state.StormAt))
	if cycle == lastMassDeathNoticeCycle then return end
	local player = getSpecificPlayer(0)
	if showStormNotice(player, getText("IGUI_AnomalousStormMassDeath"), { r = 1, g = 0.38, b = 0.34 }) then
		lastMassDeathNoticeCycle = cycle
	end
end

local function syncFromState()
    local state = ModData.get(MOD_DATA_KEY)
    if not state then
        if isClient() then ModData.request(MOD_DATA_KEY) end
        return
    end
    updatePresentation(state)
    notifyMassDeath(state)
    local phase = state.Phase
    if phase and phase ~= lastNotifiedPhase then
        notifyPhase(getSpecificPlayer(0), phase)
    end
end

local function updatePlayerExposure(player)
    local state = ModData.get(MOD_DATA_KEY)
    if not state or state.Active ~= true or state.Thunder ~= true then return end
    if not player or player:isDead() or not player:isOutside() or player:getVehicle() then return end

    -- Preserve the original exposure check and roll cadence on every player update.
    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end
    local bodyPart = bodyDamage:getBodyPart(BodyPartType.getRandom())
    local roll = ZombRand(600)
    if roll == 0 then
        bodyPart:setBurned()
    elseif roll < 6 then
        bodyPart:AddDamage(ZombRand(1, 4))
    end
end

local function removeIsometricOverlay()
    local overlayClass = ChilaSeda_AnomalousStorm_Rect
    local overlay = overlayClass and overlayClass.instance
    if overlay then overlay:setAlpha(0) end
end

local function updateIsometricOverlay()
    local state = ModData.get(MOD_DATA_KEY)
    if not state then
        state = { Warning = false, Active = false, Thunder = false }
    end

    local emissionActive = state.Warning == true or state.Active == true
    local cycleKey = nil
    if emissionActive then
        if state.DebugOverride == true then
            cycleKey = "debug:" .. tostring(state.DebugRunId or state.DebugStartedAt)
        else
            cycleKey = "scheduled:" .. tostring(state.StormAt)
        end
    end
    if cycleKey and cycleKey ~= lastOverlayCycleKey then
        stormAlpha = 0
        stormPassed = false
        removeIsometricOverlay()
        lastOverlayCycleKey = cycleKey
    elseif not emissionActive then
        lastOverlayCycleKey = nil
    end

    local viewpointMode = refreshViewpointCameraMode()
    if viewpointMode ~= lastPresentationViewpoint then updatePresentation(state, true) end
    if state.Thunder == true then
        stormPassed = true
        if stormAlpha < 0.4 then stormAlpha = stormAlpha + 0.002 end
    elseif state.Active == true or state.Warning == true then
        if stormPassed then
            if stormAlpha > 0.15 then stormAlpha = stormAlpha - 0.001 end
        elseif stormAlpha < 0.2 then
            stormAlpha = stormAlpha + 0.002
        end
    elseif stormAlpha > 0 then
        stormAlpha = stormAlpha - 0.001
    end

    if stormAlpha > 0.4 then
        stormAlpha = 0.4
    elseif stormAlpha <= 0 then
        stormAlpha = 0
        stormPassed = false
    end

    local overlayClass = ChilaSeda_AnomalousStorm_Rect
    if not overlayClass then return end
    if overlayClass.instance then
        overlayClass.instance:setAlpha(stormAlpha)
    elseif stormAlpha > 0 then
        local overlay = overlayClass:new(stormAlpha, 1, 0, 0)
        overlay:initialise()
        overlay:addToUIManager()
    end
end

Events.OnGameStart.Add(function()
    -- Remove a stale managed block if the game closed during an emission.
    local lines, readError = readProfile()
    if not readError and hasManagedProfile(lines) then
		installedProfileLevel = "stale"
		setEmissionProfile(nil)
    end
    if isClient() then ModData.request(MOD_DATA_KEY) end
end)

Events.OnReceiveGlobalModData.Add(function(key, data)
    if key == MOD_DATA_KEY and data then
        if data.Thunder == true then
            stormPassed = true
            stormAlpha = 0.4
        elseif data.Active == true or data.Warning == true then
            stormAlpha = 0.15
        end
        updatePresentation(data, true)
        notifyMassDeath(data)
        -- OnReceiveGlobalModData can run before the shared ModData lookup is refreshed.
        local phase = data.Phase
		if phase and phase ~= lastNotifiedPhase then
            notifyPhase(getSpecificPlayer(0), phase)
        end
    end
end)

local function debugLength(value)
    local length = math.floor(tonumber(value) or tonumber(SandboxVars.AnomalousStormLength) or 1)
    return math.max(1, math.min(5, length))
end

local function debugMinutes(name, fallback, maximum)
    local value = math.floor(tonumber(SandboxVars[name]) or fallback)
    return math.max(0, math.min(maximum, value)) / 60
end

local localDebugStop
local function localDebugStart(value)
    local state = ModData.getOrCreate(MOD_DATA_KEY)
    local length = debugLength(value)
    if state.DebugOverride == true then localDebugStop() end
    state = ModData.getOrCreate(MOD_DATA_KEY)
    if state.DebugOverride ~= true then
        state.DebugPrevious = {
            Day = state.Day,
            DayRandom = state.DayRandom,
            Today = state.Today,
            Hour = state.Hour,
            HourRandom = state.HourRandom,
        }
    end
    local ok, err = pcall(function() getClimateManager():stopWeatherAndThunder() end)
    if not ok then
        state.DebugPrevious = nil
        print("[Anomalous Storm] Could not clear the previous weather: " .. tostring(err))
        return false
    end
    state.DebugOverride = true
    state.DebugRunId = (tonumber(state.DebugRunId) or 0) + 1
    local now = getGameTime():getWorldAgeHours()
    state.DebugStartedAt = now
    -- Match the original event: start rain immediately unless warning is customized.
    local warningHours = debugMinutes("AnomalousStormWarningMinutes", 0, 180)
    state.DebugStormAt = now + warningHours
    state.DebugThunderAt = state.DebugStormAt + debugMinutes("AnomalousStormThunderDelayMinutes", 60, 180)
    state.DebugDuration = length
    state.DebugClearingAt = state.DebugThunderAt + length
    state.DebugRainEndAt = state.DebugClearingAt + debugMinutes("AnomalousStormCalmRainMinutes", 60, 180)
    state.DebugEndHour = state.DebugRainEndAt + debugMinutes("AnomalousStormRedFadeMinutes", 60, 180)
    state.DebugRemaining = math.ceil(state.DebugEndHour - now)
    state.Today = false
    state.Hour = 0
    state.Warning = warningHours > 0
    state.Active = false
    state.RainActive = false
    state.Thunder = false
    state.ThunderStarted = false
    state.Phase = state.Warning and "warning" or "idle"
    if isServer() then ModData.transmit(MOD_DATA_KEY) end
    updatePresentation(state, true)
    print("[Anomalous Storm] Test cycle scheduled; initial red warning is " .. tostring(math.floor(warningHours * 60)) .. " game minute(s).")
    return true
end

localDebugStop = function()
    local state = ModData.get(MOD_DATA_KEY)
    if not state or state.DebugOverride ~= true then
        print("[Anomalous Storm debug] No debug emission is active.")
        return false
    end
    pcall(function() getClimateManager():stopWeatherAndThunder() end)
    local previous = state.DebugPrevious or {}
    state.Day = previous.Day ~= nil and previous.Day or state.Day
    state.DayRandom = previous.DayRandom ~= nil and previous.DayRandom or state.DayRandom
    state.Today = previous.Today == true
    state.Hour = previous.Hour ~= nil and previous.Hour or 0
    state.HourRandom = previous.HourRandom ~= nil and previous.HourRandom or state.HourRandom
    state.Active = false
    state.Warning = false
    state.RainActive = false
    state.Thunder = false
    state.ThunderStarted = false
    state.Phase = "idle"
    state.DebugOverride = false
    state.DebugRemaining = nil
    state.DebugStartedAt = nil
    state.DebugStormAt = nil
    state.DebugThunderAt = nil
    state.DebugClearingAt = nil
    state.DebugRainEndAt = nil
    state.DebugDuration = nil
    state.DebugEndHour = nil
    state.DebugPrevious = nil
    if isServer() then ModData.transmit(MOD_DATA_KEY) end
    updatePresentation(state, true)
    print("[Anomalous Storm debug] Emission stopped.")
    return true
end

AnomalousStormDebug = AnomalousStormDebug or {}
AnomalousStormDebug.start = function(value)
    if isClient() then
        local player = getSpecificPlayer(0)
        if not player then return false end
        sendClientCommand(player, "ChilaSeda_AnomalousStormDebug", "start", { hours = debugLength(value) })
        print("[Anomalous Storm debug] Start request sent to the server.")
        return true
    end
    return localDebugStart(value)
end
AnomalousStormDebug.stop = function()
    if isClient() then
        local player = getSpecificPlayer(0)
        if not player then return false end
        sendClientCommand(player, "ChilaSeda_AnomalousStormDebug", "stop", {})
        print("[Anomalous Storm debug] Stop request sent to the server.")
        return true
    end
    return localDebugStop()
end
AnomalousStormDebug.status = function()
    local state = ModData.get(MOD_DATA_KEY)
    local message = state and state.DebugOverride == true
        and ("active; " .. tostring(state.DebugRemaining or 0) .. " game hour(s) remain")
        or "inactive"
    print("[Anomalous Storm debug] " .. message)
    return message
end

Events.EveryOneMinute.Add(syncFromState)
Events.OnPlayerUpdate.Add(updatePlayerExposure)
Events.OnPlayerUpdate.Add(updateIsometricOverlay)
if Events.OnZombieUpdate and Events.OnZombieUpdate.Add then
    Events.OnZombieUpdate.Add(updateSinglePlayerZombieExposure)
else
    print("[Anomalous Storm] OnZombieUpdate unavailable; using a throttled loaded-zombie scan.")
    Events.OnPlayerUpdate.Add(updateSinglePlayerZombieExposureFallback)
end

local function stormDebugHotkey(key)
    if key ~= Keyboard.KEY_F11 then return end
    local control = Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)
    local shift = Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
    if not control or not shift then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    local state = ModData.get(MOD_DATA_KEY)
    if state and state.DebugOverride == true then
        AnomalousStormDebug.stop()
    else
        AnomalousStormDebug.start()
    end
end

Events.OnKeyPressed.Add(stormDebugHotkey)
