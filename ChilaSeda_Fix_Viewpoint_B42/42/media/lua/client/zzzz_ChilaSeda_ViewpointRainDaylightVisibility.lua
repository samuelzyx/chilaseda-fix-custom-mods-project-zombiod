local TAG = "[ChilaSeda_ViewpointRainDaylight] "
local RainManager
local ColorInfoClass
local nextUpdate = 0
local warned = false

local function bindClasses()
	if RainManager and ColorInfoClass then return true end
	if not luajava or type(luajava.bindClass) ~= "function" then return false end
	local okRain, rainClass = pcall(luajava.bindClass, "zombie.iso.objects.RainManager")
	local okColor, colorClass = pcall(luajava.bindClass, "zombie.core.textures.ColorInfo")
	if not okRain or not okColor then return false end
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
	local now = getTimestampMs()
	if now < nextUpdate then return end
	nextUpdate = now + 1000
	if not bindClasses() then return end

	local ok, failure = pcall(function()
		local daylight = daylightStrength()
		if daylight < 0.35 then return end
		if type(RainManager.getRainIntensity) ~= "function"
				or RainManager.getRainIntensity() <= 0 then return end

		local drops = RainManager.raindropStack
		local baseTint = RainManager.raindropTintMod
		if not drops or not baseTint or drops:size() <= 0 then return end

		local boost = 1 + 0.75 * daylight
		local tint = ColorInfoClass.new(
			math.min(1, baseTint:getR() * boost),
			math.min(1, baseTint:getG() * boost),
			math.min(1, baseTint:getB() * boost),
			baseTint:getA()
		)
		for index = 0, drops:size() - 1 do
			local drop = drops:get(index)
			if drop then drop:ChangeTintMod(tint) end
		end
	end)
	if not ok and not warned then
		warned = true
		print(TAG .. "daylight tint adjustment skipped: " .. tostring(failure))
	end
end

Events.OnTickEvenPaused.Add(updateRainTint)
print(TAG .. "daylight rain visibility loaded")
