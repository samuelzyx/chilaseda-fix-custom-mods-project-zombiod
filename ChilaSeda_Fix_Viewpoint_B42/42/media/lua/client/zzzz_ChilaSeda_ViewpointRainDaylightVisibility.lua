local TAG = "[ChilaSeda_ViewpointRainDaylight] "
local RainManager
local ColorInfoClass
local nextUpdate = 0
local runtimeWarned = false
local bindWarned = false
local traceCount = 0
local TRACE_LIMIT = 16
local TRACE_INTERVAL_MS = 30000
local lastTraceKey
local lastTraceAt = 0

local function timestampMs()
	if type(getTimestampMs) ~= "function" then return 0 end
	local ok, value = pcall(getTimestampMs)
	if ok and type(value) == "number" then return value end
	return 0
end

local function trace(key, message)
	if traceCount >= TRACE_LIMIT then return end
	local now = timestampMs()
	if key == lastTraceKey and now - lastTraceAt < TRACE_INTERVAL_MS then return end
	traceCount = traceCount + 1
	lastTraceKey = key
	lastTraceAt = now
	print(TAG .. message)
end

local function bindClasses()
	if RainManager and ColorInfoClass then return true end
	if not luajava or type(luajava.bindClass) ~= "function" then
		return false, "luajava-unavailable"
	end
	local okRain, rainClass = pcall(luajava.bindClass, "zombie.iso.objects.RainManager")
	if not okRain or not rainClass then return false, "rain-manager-unavailable" end
	local okColor, colorClass = pcall(luajava.bindClass, "zombie.core.textures.ColorInfo")
	if not okColor or not colorClass then return false, "color-info-unavailable" end
	RainManager, ColorInfoClass = rainClass, colorClass
	return true
end

local function daylightStrength()
	if not ClimateManager or type(ClimateManager.getInstance) ~= "function" then return 0 end
	local ok, climate = pcall(ClimateManager.getInstance)
	if not ok or not climate or type(climate.getDayLightStrength) ~= "function" then return 0 end
	local read, value = pcall(climate.getDayLightStrength, climate)
	if not read or type(value) ~= "number" then return 0 end
	return math.max(0, math.min(1, value))
end

local function updateRainTint()
	local now = timestampMs()
	if now < nextUpdate then return end
	nextUpdate = now + 1000

	local bound, bindReason = bindClasses()
	if not bound then
		if not bindWarned then
			bindWarned = true
			trace("bind-fallback", "event=fallback reason=" .. tostring(bindReason))
		end
		return
	end

	local ok, failure = pcall(function()
		local daylight = daylightStrength()
		if daylight < 0.35 then
			trace("low-daylight", "event=skipped reason=low-daylight daylight=" .. tostring(daylight))
			return
		end
		if type(RainManager.getRainIntensity) ~= "function" then
			trace("rain-api-fallback", "event=fallback reason=rain-intensity-api-unavailable")
			return
		end
		local intensity = RainManager.getRainIntensity()
		if type(intensity) ~= "number" or intensity <= 0 then
			trace("no-rain", "event=skipped reason=no-rain daylight=" .. tostring(daylight))
			return
		end

		local drops = RainManager.raindropStack
		local baseTint = RainManager.raindropTintMod
		if not drops or not baseTint or drops:size() <= 0 then
			trace("no-drops", "event=skipped reason=no-raindrops daylight=" .. tostring(daylight)
				.. " intensity=" .. tostring(intensity))
			return
		end

		local boost = 1 + 0.75 * daylight
		local tint = ColorInfoClass.new(
			math.min(1, baseTint:getR() * boost),
			math.min(1, baseTint:getG() * boost),
			math.min(1, baseTint:getB() * boost),
			baseTint:getA()
		)
		local applied = 0
		for index = 0, drops:size() - 1 do
			local drop = drops:get(index)
			if drop then
				drop:ChangeTintMod(tint)
				applied = applied + 1
			end
		end
		trace("adjusted", "event=adjusted daylight=" .. tostring(daylight)
			.. " intensity=" .. tostring(intensity) .. " drops=" .. tostring(applied)
			.. " boost=" .. tostring(boost) .. " tint=" .. tostring(tint:getR()) .. ","
			.. tostring(tint:getG()) .. "," .. tostring(tint:getB()) .. "," .. tostring(tint:getA()))
	end)
	if not ok and not runtimeWarned then
		runtimeWarned = true
		trace("runtime-fallback", "event=fallback reason=runtime-error detail=" .. tostring(failure))
	end
end

Events.OnTickEvenPaused.Add(updateRainTint)
print(TAG .. "event=loaded")
