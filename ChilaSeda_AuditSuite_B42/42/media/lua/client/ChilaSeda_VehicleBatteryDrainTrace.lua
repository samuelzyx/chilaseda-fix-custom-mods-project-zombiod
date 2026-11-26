-- Bounded, read-only samples for nearby Spiffo vans and their towing partners.
local PREFIX = "[ChilaSedaVehicleBatteryTrace]"
local TARGET_SCRIPT = "Base.VanSpiffo"
local SEARCH_RADIUS_SQ = 50 * 50
local SAMPLE_TICKS = 300
local MAX_SAMPLES_PER_SESSION = 180
local MAX_VEHICLES_PER_SAMPLE = 8
local MAX_PART_LOADS = 10
local LOG_NAME = "ChilaSeda_VehicleBatteryTrace.log"

local Trace = {
	tick = 0,
	samples = 0,
	targetSignature = nil,
	finished = false,
	fileFallbackLogged = false,
}

local function safeText(value)
	if value == nil then return "na" end
	local ok, result = pcall(tostring, value)
	if not ok then return "unavailable" end
	result = result:gsub("[%c|;]", "_")
	return result
end

local function callMethod(object, method, ...)
	if object == nil then return false, nil end
	local args = { ... }
	local ok, result = pcall(function()
		local fn = object[method]
		if type(fn) ~= "function" then return nil end
		return fn(object, unpack(args))
	end)
	return ok, result
end

local function methodValue(object, method, ...)
	local ok, result = callMethod(object, method, ...)
	if not ok then return "err" end
	return safeText(result)
end

local function numberValue(object, method, ...)
	local ok, result = callMethod(object, method, ...)
	if not ok then return "err" end
	local number = tonumber(result)
	if not number then return "na" end
	return tostring(math.floor(number * 10000 + 0.5) / 10000)
end

local function boolValue(object, method, ...)
	local ok, result = callMethod(object, method, ...)
	if not ok or result == nil then return "na" end
	return result == true and "1" or "0"
end

local function log(message)
	local line = PREFIX .. " " .. message
	if type(print) == "function" then pcall(print, line) end

	local ok, err = pcall(function()
		if type(getFileWriter) ~= "function" then error("getFileWriter unavailable") end
		local writer = getFileWriter(LOG_NAME, true, true)
		if not writer then error("getFileWriter returned nil") end
		writer:write(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. line .. "\n")
		writer:close()
	end)
	if not ok and not Trace.fileFallbackLogged then
		Trace.fileFallbackLogged = true
		if type(print) == "function" then
			pcall(print, PREFIX .. " event=file-fallback destination=DebugLog reason=" .. safeText(err))
		end
	end
end

local function vehicleId(vehicle)
	local ok, id = callMethod(vehicle, "getId")
	if ok and id ~= nil then return safeText(id) end
	return safeText(vehicle)
end

local function xy(object)
	local xOk, x = callMethod(object, "getX")
	local yOk, y = callMethod(object, "getY")
	if not xOk or not yOk or not tonumber(x) or not tonumber(y) then return "na,na" end
	return numberValue({ get = function() return x end }, "get") .. ","
		.. numberValue({ get = function() return y end }, "get")
end

local function distanceSq(player, vehicle)
	local pxOk, px = callMethod(player, "getX")
	local pyOk, py = callMethod(player, "getY")
	local vxOk, vx = callMethod(vehicle, "getX")
	local vyOk, vy = callMethod(vehicle, "getY")
	if not pxOk or not pyOk or not vxOk or not vyOk then return nil end
	px, py, vx, vy = tonumber(px), tonumber(py), tonumber(vx), tonumber(vy)
	if not px or not py or not vx or not vy then return nil end
	local dx, dy = vx - px, vy - py
	return dx * dx + dy * dy
end

local function includeLoadPart(part)
	local id = methodValue(part, "getId")
	local lower = id:lower()
	return lower:find("battery", 1, true) ~= nil
		or lower:find("engine", 1, true) ~= nil
		or lower:find("light", 1, true) ~= nil
		or lower:find("radio", 1, true) ~= nil
		or lower:find("siren", 1, true) ~= nil
		or lower:find("heater", 1, true) ~= nil
		or lower:find("fridge", 1, true) ~= nil
		or lower:find("generator", 1, true) ~= nil
		or lower:find("alternator", 1, true) ~= nil
end

local function dataActive(part)
	local ok, data = callMethod(part, "getModData")
	if not ok or data == nil then return "na" end
	local valueOk, active = pcall(function() return data.active end)
	if not valueOk or active == nil then return "na" end
	return active == true and "1" or "0"
end

local function partLoadSummary(vehicle)
	local count = tonumber(methodValue(vehicle, "getPartCount")) or 0
	local loads = {}
	for index = 0, math.min(count - 1, 63) do
		local ok, part = callMethod(vehicle, "getPartByIndex", index)
		if ok and part and includeLoadPart(part) then
			local id = methodValue(part, "getId")
			local itemOk, item = callMethod(part, "getInventoryItem")
			if not itemOk then item = nil end
			local deviceOk, device = callMethod(part, "getDeviceData")
			if not deviceOk then device = nil end
			loads[#loads + 1] = id .. "[active=" .. dataActive(part)
				.. ",deviceOn=" .. boolValue(device, "getIsTurnedOn")
				.. ",item=" .. methodValue(item, "getFullType")
				.. ",itemCond=" .. numberValue(item, "getCondition") .. "]"
			if #loads >= MAX_PART_LOADS then break end
		end
	end
	return #loads > 0 and table.concat(loads, ",") or "none"
end

local function vehicleSummary(entry, player)
	local vehicle = entry.vehicle
	local batteryOk, batteryPart = callMethod(vehicle, "getPartById", "Battery")
	if not batteryOk or batteryPart == nil then
		batteryOk, batteryPart = callMethod(vehicle, "getBattery")
	end
	local itemOk, batteryItem = callMethod(batteryPart, "getInventoryItem")
	if not itemOk then batteryItem = nil end
	local towingOk, towing = callMethod(vehicle, "getVehicleTowing")
	if not towingOk then towing = nil end
	local towedByOk, towedBy = callMethod(vehicle, "getVehicleTowedBy")
	if not towedByOk then towedBy = nil end
	local distance = distanceSq(player, vehicle)
	local distanceTiles = distance and math.sqrt(distance) or nil
	local engineSpeedOk, engineSpeed = callMethod(vehicle, "getEngineSpeed")
	local out = {
		"id=" .. vehicleId(vehicle),
		"script=" .. methodValue(vehicle, "getScriptName"),
		"role=" .. entry.role,
		"xy=" .. xy(vehicle),
		"distance=" .. (distanceTiles and tostring(math.floor(distanceTiles * 100 + 0.5) / 100) or "na"),
		"towing=" .. (towing and vehicleId(towing) or "none"),
		"towedBy=" .. (towedBy and vehicleId(towedBy) or "none"),
		"batteryCharge=" .. numberValue(vehicle, "getBatteryCharge"),
		"hasLiveBattery=" .. boolValue(vehicle, "hasLiveBattery"),
		"batteryPartCondition=" .. numberValue(batteryPart, "getCondition"),
		"batteryItem=" .. methodValue(batteryItem, "getFullType"),
		"batteryItemCondition=" .. numberValue(batteryItem, "getCondition"),
		"batteryItemUsedDelta=" .. numberValue(batteryItem, "getUsedDelta"),
		"engineRunning=" .. boolValue(vehicle, "isEngineRunning"),
		"engineStarted=" .. boolValue(vehicle, "isEngineStarted"),
		"keysInIgnition=" .. boolValue(vehicle, "isKeysInIgnition"),
		"engineSpeed=" .. (engineSpeedOk and safeText(engineSpeed) or "err"),
		"engineCondition=" .. numberValue(vehicle, "getEngineCondition"),
		"speedKmh=" .. numberValue(vehicle, "getCurrentSpeedKmHour"),
		"headlights=" .. boolValue(vehicle, "getHeadlightsOn"),
		"windowLights=" .. boolValue(vehicle, "getWindowLightsOn"),
		"lightbarLights=" .. methodValue(vehicle, "getLightbarLightsMode"),
		"lightbarSiren=" .. methodValue(vehicle, "getLightbarSirenModeObject"),
		"loads=" .. partLoadSummary(vehicle),
	}
	return table.concat(out, " ")
end

local function addVehicle(result, seen, vehicle, role, depth)
	if not vehicle or #result >= MAX_VEHICLES_PER_SAMPLE or depth > 2 then return end
	local id = vehicleId(vehicle)
	local key = id ~= "na" and id or safeText(vehicle)
	if seen[key] then return end
	seen[key] = true
	result[#result + 1] = { vehicle = vehicle, role = role }

	local towingOk, towing = callMethod(vehicle, "getVehicleTowing")
	if towingOk and towing then addVehicle(result, seen, towing, "spiffo_towing", depth + 1) end
	local towedByOk, towedBy = callMethod(vehicle, "getVehicleTowedBy")
	if towedByOk and towedBy then addVehicle(result, seen, towedBy, "spiffo_towed_by", depth + 1) end
end

local function nearbySpiffoVehicles(player)
	if type(getCell) ~= "function" then return {}, 0 end
	local cellOk, cell = pcall(getCell)
	if not cellOk or not cell then return {}, 0 end
	local vehiclesOk, vehicles = callMethod(cell, "getVehicles")
	if not vehiclesOk or not vehicles then return {}, 0 end
	local iteratorOk, iterator = callMethod(vehicles, "iterator")
	if not iteratorOk or not iterator then return {}, 0 end

	local result, seen = {}, {}
	local nearbyCount = 0
	while true do
		local hasNextOk, hasNext = callMethod(iterator, "hasNext")
		if not hasNextOk or hasNext ~= true then break end
		local nextOk, vehicle = callMethod(iterator, "next")
		if not nextOk or not vehicle then break end
		if methodValue(vehicle, "getScriptName") == TARGET_SCRIPT then
			local distance = distanceSq(player, vehicle)
			if distance and distance <= SEARCH_RADIUS_SQ then
				nearbyCount = nearbyCount + 1
				addVehicle(result, seen, vehicle, "near_spiffo", 0)
			end
		end
	end
	return result, nearbyCount
end

local function playerPosition(player)
	return xy(player)
end

local function onTick()
	if Trace.finished then return end
	Trace.tick = Trace.tick + 1
	if Trace.tick ~= 1 and Trace.tick % SAMPLE_TICKS ~= 0 then return end

	local playerOk, player = pcall(getSpecificPlayer, 0)
	if not playerOk or not player then return end
	local vehicles, nearbyCount = nearbySpiffoVehicles(player)
	local ids = {}
	for _, entry in ipairs(vehicles) do
		ids[#ids + 1] = entry.role .. ":" .. vehicleId(entry.vehicle)
	end
	local targetSignature = table.concat(ids, ",")
	if targetSignature ~= Trace.targetSignature then
		Trace.targetSignature = targetSignature
		log("event=target-set readOnly=1 nearbySpiffo=" .. safeText(nearbyCount)
			.. " linkedVehicles=" .. safeText(#vehicles)
			.. " vehicles=" .. (#ids > 0 and targetSignature or "none"))
	end
	if #vehicles == 0 then return end

	Trace.samples = Trace.samples + 1
	local summaries = {}
	for _, entry in ipairs(vehicles) do
		summaries[#summaries + 1] = vehicleSummary(entry, player)
	end
	log("event=sample readOnly=1 sample=" .. safeText(Trace.samples)
		.. " tick=" .. safeText(Trace.tick)
		.. " playerXY=" .. playerPosition(player)
		.. " nearbySpiffo=" .. safeText(nearbyCount)
		.. " vehicleCount=" .. safeText(#vehicles)
		.. " vehicles=" .. table.concat(summaries, " ; "))

	if Trace.samples >= MAX_SAMPLES_PER_SESSION then
		Trace.finished = true
		log("event=cap reached=1 maxSamples=" .. safeText(MAX_SAMPLES_PER_SESSION)
			.. " readOnly=1 restartSessionForFreshTrace=1")
	end
end

Events.OnTick.Add(onTick)
log("event=loaded readOnly=1 target=" .. TARGET_SCRIPT
	.. " radiusTiles=50 sampleTicks=" .. safeText(SAMPLE_TICKS)
	.. " maxSamples=" .. safeText(MAX_SAMPLES_PER_SESSION)
	.. " maxVehicles=" .. safeText(MAX_VEHICLES_PER_SAMPLE)
	.. " fields=battery,condition,engine,lights,radio,loads,towing")
