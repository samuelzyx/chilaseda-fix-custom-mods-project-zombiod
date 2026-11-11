local MOD_DATA_KEY = "AnomalousStorm"
local ZOMBIE_SPEED_KEY = "ChilaSeda_AnomalousStorm_OriginalSpeed"
local EXPOSURE_DAMAGE_MULTIPLIER_KEY = "ChilaSeda_AnomalousStorm_DamageMultiplier"
local EXPOSURE_DAMAGE_CYCLE_KEY = "ChilaSeda_AnomalousStorm_DamageCycle"
local function getThunderBounds(state)
	if not state then return nil, nil end
	if state.DebugOverride == true then
		return tonumber(state.DebugThunderAt), tonumber(state.DebugClearingAt)
	end
	return tonumber(state.ThunderAt), tonumber(state.ClearingAt)
end

local function getLethalDamageScale(state, now)
	local thunderAt, clearingAt = getThunderBounds(state)
	if not thunderAt or not clearingAt or clearingAt <= thunderAt then return 1 end
	local percent = math.floor(tonumber(SandboxVars.AnomalousStormLethalExposurePercent) or 75)
	percent = math.max(50, math.min(95, percent))
	local rampStart = thunderAt + (clearingAt - thunderAt) * percent / 100
	if now <= rampStart then return 1 end
	local rampDuration = clearingAt - rampStart
	if rampDuration <= 0 then return 1 end
	local progress = math.max(0, math.min(1, (now - rampStart) / rampDuration))
	return 1 + progress * 10.5
end

local function getExposureDamageMultiplier(actor, state)
	local data = actor:getModData()
	if not data then return 1 end
	local cycle
	if state.DebugOverride == true then
		cycle = "debug:" .. tostring(state.DebugRunId or state.DebugStartedAt)
	else
		cycle = "scheduled:" .. tostring(state.StormAt or state.ThunderAt)
	end
	local multiplier = tonumber(data[EXPOSURE_DAMAGE_MULTIPLIER_KEY])
	if data[EXPOSURE_DAMAGE_CYCLE_KEY] ~= cycle or not multiplier then
		multiplier = ZombRand(75, 226) / 100
		data[EXPOSURE_DAMAGE_MULTIPLIER_KEY] = multiplier
		data[EXPOSURE_DAMAGE_CYCLE_KEY] = cycle
	end
	return multiplier
end
local function getTimingOption(name, fallback, minValue, maxValue)
	local value = math.floor(tonumber(SandboxVars[name]) or fallback)
	return math.max(minValue, math.min(maxValue, value)) / 60
end

local function getWarningHours()
	return getTimingOption("AnomalousStormWarningMinutes", 0, 0, 180)
end

local function getThunderDelayHours()
	return getTimingOption("AnomalousStormThunderDelayMinutes", 60, 0, 180)
end

local function getClearingHours()
	return getTimingOption("AnomalousStormCalmRainMinutes", 60, 0, 180)
end

local function getRedFadeHours()
	return getTimingOption("AnomalousStormRedFadeMinutes", 60, 0, 180)
end

local function getFrequencyBounds()
	local minDays = math.floor(tonumber(SandboxVars.AnomalousStormDaysMin) or 3)
	-- The Workshop defaults were min=3/max=7, but ZombRand's upper bound is
	-- exclusive, so its actual default interval was 3-6 days. Keep that behavior
	-- while exposing intuitive inclusive min/max options in the B42 port.
	local maxDays = math.floor(tonumber(SandboxVars.AnomalousStormDaysMax) or 6)
	minDays = math.max(1, math.min(90, minDays))
	maxDays = math.max(minDays, math.min(90, maxDays))
	return minDays, maxDays
end

local function randomBetweenInclusive(minValue, maxValue)
	return ZombRand(minValue, maxValue + 1)
end

local function randomStormHour(length)
	-- Keep the original Workshop's eligible hour range.
	local upperBound = 23 - length
	if SandboxVars.DayLength == 1 then
		upperBound = 16 - length
	end
	return ZombRand(1, upperBound)
end

local function transmitStormData()
	if isServer() then
		ModData.transmit(MOD_DATA_KEY)
	end
end

local function initializeStormData()
	local state = ModData.getOrCreate(MOD_DATA_KEY)
	local hadStormData = state.Hour ~= nil
	local minDays, maxDays = getFrequencyBounds()
	local length = math.floor(tonumber(SandboxVars.AnomalousStormLength) or 1)
	length = math.max(1, math.min(5, length))
	local migratedZombieDamageDefault = false
	if state.ZombieDamageDefaultMigration == nil then
		-- 0.4.15 used 1 (0.01 health) as its default. Jill was explicitly kept
		-- on this mod's defaults, so upgrade that legacy default to 10 (0.10).
		if hadStormData and tonumber(SandboxVars.AnomalousStormZombieDamagePerTenMinutes) == 1 then
			SandboxVars.AnomalousStormZombieDamagePerTenMinutes = 10
		end
		state.ZombieDamageDefaultMigration = 1
		migratedZombieDamageDefault = true
	end

	if state.Hour == nil then
		state.Day = 0
		state.DayRandom = randomBetweenInclusive(minDays, maxDays)
		state.Today = false
		state.Active = false
		state.Warning = false
		state.RainActive = false
		state.Thunder = false
		state.ThunderStarted = false
		state.Phase = "idle"
		state.Hour = 0
		state.HourRandom = randomStormHour(length)
		transmitStormData()
	else
		if state.Thunder == true then state.ThunderStarted = true end
		-- Apply changed Sandbox frequency bounds to a previously saved pending event.
		local pendingDays = tonumber(state.DayRandom)
		if pendingDays then
			local adjustedDays = math.max(minDays, math.min(maxDays, math.floor(pendingDays)))
			if adjustedDays ~= pendingDays then
				state.DayRandom = adjustedDays
				transmitStormData()
			end
		end
	end
	if migratedZombieDamageDefault then transmitStormData() end
	return state
end

local function debugDuration(value)
	local length = math.floor(tonumber(value) or tonumber(SandboxVars.AnomalousStormLength) or 1)
	return math.max(1, math.min(5, length))
end

local function stopDebugStorm(reason)
	local state = ModData.get(MOD_DATA_KEY)
	if not state or state.DebugOverride ~= true then return false end

	if reason ~= "duration complete" then
		pcall(function() getClimateManager():stopWeatherAndThunder() end)
	end
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
	state.ExposedActorsSeen = false
	state.ExposedPopulationEliminated = false
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
	transmitStormData()
	print("[Anomalous Storm debug] Stopped" .. (reason and (" (" .. reason .. ")") or ""))
	return true
end

local function startDebugStorm(value)
	local state = initializeStormData()
	local length = debugDuration(value)
	if state.DebugOverride == true then
		stopDebugStorm("restarted")
		state = initializeStormData()
	end
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
	-- Match the original: start the storm now unless a custom warning is configured.
	local warningHours = getWarningHours()
	state.DebugStormAt = now + warningHours
	state.DebugThunderAt = state.DebugStormAt + getThunderDelayHours()
	state.DebugDuration = length
	state.DebugClearingAt = state.DebugThunderAt + length
	state.DebugRainEndAt = state.DebugClearingAt + getClearingHours()
	state.DebugEndHour = state.DebugRainEndAt + getRedFadeHours()
	state.DebugRemaining = math.ceil(state.DebugEndHour - now)
	state.Today = false
	state.Hour = 0
	state.Warning = warningHours > 0
	state.Active = false
	state.RainActive = false
	state.Thunder = false
	state.ThunderStarted = false
	state.ExposedActorsSeen = false
	state.ExposedPopulationEliminated = false
	state.Phase = state.Warning and "warning" or "idle"
	transmitStormData()
	print("[Anomalous Storm] Test cycle scheduled; initial red warning is " .. tostring(math.floor(warningHours * 60)) .. " game minute(s).")
	return true
end

AnomalousStormDebug = AnomalousStormDebug or {}
AnomalousStormDebug.start = function(value)
	return startDebugStorm(value)
end
AnomalousStormDebug.stop = function()
	return stopDebugStorm("manual")
end
AnomalousStormDebug.status = function()
	local state = ModData.get(MOD_DATA_KEY)
	local message = state and state.DebugOverride == true
		and ("active; " .. tostring(state.DebugRemaining or 0) .. " game hour(s) remain")
		or "inactive"
	print("[Anomalous Storm debug] " .. message)
	return message
end

Events.OnClientCommand.Add(function(module, command, player, args)
	if module ~= "ChilaSeda_AnomalousStormDebug" then return end
	if not player then return end
	if command == "start" then
		startDebugStorm(args and args.hours)
	elseif command == "stop" then
		stopDebugStorm("hotkey command")
	elseif command == "status" then
		AnomalousStormDebug.status()
	end
end)

local function onEveryDay()
	local state = initializeStormData()
	if state.DebugOverride == true then return end
	local minDays, maxDays = getFrequencyBounds()
	state.Day = (tonumber(state.Day) or 0) + 1
	state.Hour = 0
	state.Active = false
	state.Warning = false
	state.RainActive = false
	state.Thunder = false
	state.ThunderStarted = false
	state.ExposedActorsSeen = false
	state.ExposedPopulationEliminated = false
	state.Phase = "idle"
	state.StormAt = nil
	state.ThunderAt = nil
	state.ClearingAt = nil
	state.RainEndAt = nil
	state.EndAt = nil

	if state.Day >= (tonumber(state.DayRandom) or minDays) then
		state.Today = true
		state.Day = 0
		state.DayRandom = randomBetweenInclusive(minDays, maxDays)
		state.HourRandom = randomStormHour(math.floor(tonumber(SandboxVars.AnomalousStormLength) or 1))
	else
		state.Today = false
	end

	transmitStormData()
end

local function onEveryHour()
	local state = ModData.get(MOD_DATA_KEY)
	if state and state.DebugOverride == true then return end
	if not state or state.Today ~= true then return end

	state.Hour = (tonumber(state.Hour) or 0) + 1
	local stormHour = tonumber(state.HourRandom) or 1

	if stormHour > 1 and state.Hour == stormHour - 1 then
		pcall(function() getClimateManager():stopWeatherAndThunder() end)
		state.Warning = false
		state.Active = false
		state.RainActive = false
		state.Thunder = false
		state.Phase = "idle"
		state.ExposedActorsSeen = false
		state.ExposedPopulationEliminated = false
		state.StormAt = getGameTime():getWorldAgeHours() + 1.0
		state.ThunderAt = state.StormAt + getThunderDelayHours()
		local length = math.floor(tonumber(SandboxVars.AnomalousStormLength) or 1)
		length = math.max(1, math.min(5, length))
		state.ClearingAt = state.ThunderAt + length
		state.RainEndAt = state.ClearingAt + getClearingHours()
		state.EndAt = state.RainEndAt + getRedFadeHours()
	elseif stormHour == 1 and state.Hour == 1 then
		pcall(function() getClimateManager():stopWeatherAndThunder() end)
		local now = getGameTime():getWorldAgeHours()
		state.Warning = false
		state.Active = false
		state.RainActive = false
		state.Thunder = false
		state.Phase = "idle"
		state.ExposedActorsSeen = false
		state.ExposedPopulationEliminated = false
		state.StormAt = now
		state.ThunderAt = now + getThunderDelayHours()
		local length = math.floor(tonumber(SandboxVars.AnomalousStormLength) or 1)
		length = math.max(1, math.min(5, length))
		state.ClearingAt = state.ThunderAt + length
		state.RainEndAt = state.ClearingAt + getClearingHours()
		state.EndAt = state.RainEndAt + getRedFadeHours()
	end

	transmitStormData()
end

local function updateDebugDuration()
	local state = ModData.get(MOD_DATA_KEY)
	if not state or state.DebugOverride ~= true then return end
	local ok, now = pcall(function() return getGameTime():getWorldAgeHours() end)
	if not ok then return end
	if state.Active ~= true and now >= (tonumber(state.DebugStormAt) or math.huge) then
		local started, err = pcall(function()
			local climate = getClimateManager()
			climate:stopWeatherAndThunder()
			climate:triggerCustomWeatherStage(WeatherPeriod.STAGE_STORM,
				math.max(1, math.min(5, tonumber(state.DebugDuration) or 1)))
		end)
		if not started then
			print("[Anomalous Storm] Failed to start the rain stage: " .. tostring(err))
			stopDebugStorm("weather stage failed")
			return
		end
		state.Warning = false
		state.Active = true
		state.RainActive = true
		state.Thunder = false
		state.Phase = "rain-ramping"
		transmitStormData()
		print("[Anomalous Storm] Phase rain-ramping; damage remains off during the rain buildup.")
	end
	if state.Active == true and state.Thunder ~= true and now >= (tonumber(state.DebugThunderAt) or math.huge) then
		state.Thunder = true
		state.ThunderStarted = true
		state.Phase = "thunderstorm"
		transmitStormData()
		print("[Anomalous Storm] Phase thunderstorm; player exposure damage enabled.")
	end
	if state.Active == true and state.Phase == "thunderstorm"
		and now >= (tonumber(state.DebugClearingAt) or math.huge) then
		state.Thunder = false
		state.Phase = "clearing"
		transmitStormData()
		print("[Anomalous Storm] Phase clearing; exposure damage disabled, calm rain continues.")
	end
	if state.Active == true and state.Phase == "clearing"
		and now >= (tonumber(state.DebugRainEndAt) or math.huge) then
		state.RainActive = false
		state.Phase = "red-fade"
		transmitStormData()
		print("[Anomalous Storm] Rain ended; the original red visual fade continues.")
	end
	local remaining = (tonumber(state.DebugEndHour) or now) - now
	if remaining <= 0 then
		stopDebugStorm("duration complete")
		return
	end
	local hours = math.ceil(remaining)
	if state.DebugRemaining ~= hours then
		state.DebugRemaining = hours
		transmitStormData()
	end
end

local function updateScheduledTimeline()
	local state = ModData.get(MOD_DATA_KEY)
	if not state or state.DebugOverride == true or state.Today ~= true then return end
	local ok, now = pcall(function() return getGameTime():getWorldAgeHours() end)
	if not ok then return end

	local warningAt = (tonumber(state.StormAt) or math.huge) - getWarningHours()
	if not state.Active and getWarningHours() > 0 and now >= warningAt and now < (tonumber(state.StormAt) or math.huge) then
		if state.Warning ~= true then
			state.Warning = true
			state.Phase = "warning"
			transmitStormData()
			print("[Anomalous Storm] Optional warning phase started.")
		end
	end
	if state.StormAt ~= nil and state.Active ~= true and now >= (tonumber(state.StormAt) or math.huge) then
		local length = math.floor(tonumber(SandboxVars.AnomalousStormLength) or 1)
		length = math.max(1, math.min(5, length))
		local started, err = pcall(function()
			local climate = getClimateManager()
			climate:stopWeatherAndThunder()
			climate:triggerCustomWeatherStage(WeatherPeriod.STAGE_STORM, length)
		end)
		if not started then
			print("[Anomalous Storm] Scheduled rain stage failed: " .. tostring(err))
			state.Warning = false
			state.Phase = "idle"
			transmitStormData()
			return
		end
		state.Warning = false
		state.Active = true
		state.RainActive = true
		state.Thunder = false
		state.ThunderStarted = false
		state.Phase = "rain-ramping"
		state.RainEndAt = (tonumber(state.ClearingAt) or (now + getThunderDelayHours() + length)) + getClearingHours()
		state.EndAt = state.RainEndAt + getRedFadeHours()
		transmitStormData()
		print("[Anomalous Storm] Scheduled phase rain-ramping.")
	end

	if state.Active == true and state.Thunder ~= true and now >= (tonumber(state.ThunderAt) or math.huge) then
		state.Thunder = true
		state.ThunderStarted = true
		state.Phase = "thunderstorm"
		transmitStormData()
		print("[Anomalous Storm] Scheduled phase thunderstorm; exposure damage enabled.")
	end
	if state.Active == true and state.Phase == "thunderstorm"
		and now >= (tonumber(state.ClearingAt) or math.huge) then
		state.Thunder = false
		state.Phase = "clearing"
		transmitStormData()
		print("[Anomalous Storm] Scheduled phase clearing; calm rain continues.")
	end
	if state.Active == true and state.Phase == "clearing"
		and now >= (tonumber(state.RainEndAt) or math.huge) then
		state.RainActive = false
		state.Phase = "red-fade"
		transmitStormData()
		print("[Anomalous Storm] Scheduled rain ended; the original red visual fade continues.")
	end

	if state.Active == true and now >= (tonumber(state.EndAt) or math.huge) then
		state.Active = false
		state.Warning = false
		state.RainActive = false
		state.Thunder = false
		state.ThunderStarted = false
		state.Phase = "idle"
		state.StormAt = nil
		state.ThunderAt = nil
		state.ClearingAt = nil
		state.RainEndAt = nil
		state.EndAt = nil
		state.Today = false
		transmitStormData()
		print("[Anomalous Storm] Emission entered clearing; exposure effects disabled.")
	end
end

local function getLoadedActorSquare(actor)
	if not actor then return nil end
	local squareOk, square = pcall(function() return actor:getCurrentSquare() end)
	if not squareOk or not square then return nil end
	local chunkOk, chunk = pcall(function() return square:getChunk() end)
	if not chunkOk or not chunk then return nil end
	return square
end

local function isOutside(zombie)
	local square = getLoadedActorSquare(zombie)
	return square ~= nil and square:isOutside()
end

local function restoreZombieSpeed(zombie)
	local data = zombie:getModData()
	if not data then return end
	local original = tonumber(data[ZOMBIE_SPEED_KEY])
	if original then
		zombie:setSpeedMod(original)
		data[ZOMBIE_SPEED_KEY] = nil
	end
end

local function applyZombieSlow(zombie)
	local data = zombie:getModData()
	if not data then return end

	local original = tonumber(data[ZOMBIE_SPEED_KEY])
	if original == nil then
		original = tonumber(zombie:getSpeedMod()) or 1
		data[ZOMBIE_SPEED_KEY] = original
	end

	local percent = math.floor(tonumber(SandboxVars.AnomalousStormZombieSlowPercent) or 10)
	percent = math.max(10, math.min(100, percent))
	zombie:setSpeedMod(original * percent / 100)
end

local function forEachLoadedZombie(callback)
	local cell = getCell()
	if not cell then return end
	local zombies = cell:getZombieList()
	if not zombies then return end
	for index = 0, zombies:size() - 1 do
		local zombie = zombies:get(index)
		if zombie and instanceof(zombie, "IsoZombie") then
			callback(zombie)
		end
	end
end

local function forEachLoadedAnimal(callback)
	local cell = getCell()
	if not cell then return end
	local ok, animals = pcall(function() return cell:getAnimals() end)
	if not ok or not animals then return end
	local sizeOk, size = pcall(function() return animals:size() end)
	if not sizeOk or not tonumber(size) then return end
	for index = 0, tonumber(size) - 1 do
		local animalOk, animal = pcall(function() return animals:get(index) end)
		if animalOk and animal and instanceof(animal, "IsoAnimal") then callback(animal) end
	end
end

local function updateActorExposure()
	local state = ModData.get(MOD_DATA_KEY)
	local rainActive = state ~= nil and state.RainActive == true
	local damagingRain = rainActive and state.Thunder == true
	if state and state.Thunder == true then state.ThunderStarted = true end
	local slowingRain = rainActive and state.ThunderStarted == true
	local damagePerMinute = math.floor(tonumber(SandboxVars.AnomalousStormZombieDamagePerTenMinutes) or 10) / 1000
	local now = getGameTime():getWorldAgeHours()
	local damageScale = damagingRain and getLethalDamageScale(state, now) or 1
	local sawExposedActor = false

	forEachLoadedZombie(function(zombie)
		local square = getLoadedActorSquare(zombie)
		if not square then return end
		if zombie:isDead() or not square:isOutside() then
			restoreZombieSpeed(zombie)
			return
		end
		sawExposedActor = true

		if slowingRain then
			applyZombieSlow(zombie)
		else
			restoreZombieSpeed(zombie)
		end

		if damagingRain and damagePerMinute > 0 then
			local health = tonumber(zombie:getHealth()) or 0
			if health > 0 then
				local amount = damagePerMinute * getExposureDamageMultiplier(zombie, state) * damageScale
				zombie:setHealth(math.max(0, health - amount))
			end
		end
	end)

	if not damagingRain then return end
	forEachLoadedAnimal(function(animal)
		local square = getLoadedActorSquare(animal)
		if animal:isDead() or not square or not square:isOutside() then return end
		sawExposedActor = true
		if damagePerMinute > 0 then
			local health = tonumber(animal:getHealth()) or 0
			if health > 0 then
				local amount = damagePerMinute * getExposureDamageMultiplier(animal, state) * damageScale
				animal:setHealth(math.max(0, health - amount))
			end
		end
	end)
	if sawExposedActor then state.ExposedActorsSeen = true end

	if damagingRain and state.ExposedActorsSeen and not state.ExposedPopulationEliminated then
		local survivor = false
		forEachLoadedZombie(function(zombie)
			if not survivor and not zombie:isDead() and isOutside(zombie)
					and (tonumber(zombie:getHealth()) or 0) > 0 then survivor = true end
		end)
		if not survivor then
			forEachLoadedAnimal(function(animal)
				local square = getLoadedActorSquare(animal)
				if not survivor and not animal:isDead() and square and square:isOutside()
						and (tonumber(animal:getHealth()) or 0) > 0 then survivor = true end
			end)
		end
		if not survivor then
			state.ExposedPopulationEliminated = true
			transmitStormData()
			print("[Anomalous Storm] All loaded actors exposed to electrical rain have died.")
		end
	end
end

Events.OnInitGlobalModData.Add(initializeStormData)
Events.OnGameStart.Add(function()
	local state = ModData.get(MOD_DATA_KEY)
	if state and state.DebugOverride == true then
		stopDebugStorm("cleared after reload")
	end
end)
Events.EveryDays.Add(onEveryDay)
Events.EveryHours.Add(onEveryHour)
Events.EveryOneMinute.Add(function()
	updateDebugDuration()
	updateScheduledTimeline()
	updateActorExposure(true)
end)
