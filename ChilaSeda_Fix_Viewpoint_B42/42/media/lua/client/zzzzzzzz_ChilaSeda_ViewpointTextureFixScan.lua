-- Replaces TextureFix (Viewpoint)'s F10 scanner, whose Java class-name call fails in Kahlua.
local TAG = "[VPFIXSCAN] "
local RADIUS = 4
local MAX_OBJECT_LINES = 64
local warned = {}

local function warnOnce(key, message)
	if warned[key] then return end
	warned[key] = true
	print(TAG .. message)
end

local function safeCall(object, method, ...)
	if not object then return nil, false, "object unavailable" end
	local lookupOk, fn = pcall(function() return object[method] end)
	if not lookupOk then return nil, false, "method lookup failed" end
	if fn == nil then return nil, false, "method unavailable" end
	local ok, value = pcall(fn, object, ...)
	if ok then return value, true end
	return nil, false, tostring(value)
end

local function removeWorkshopScanner()
	local bridge = ChilaSedaViewpointTextureFixScanJ
	if not bridge or type(bridge.removeWorkshopScannerCallbacks) ~= "function" then
		return nil, "Java event bridge unavailable"
	end
	local ok, removed = pcall(function()
		return bridge.removeWorkshopScannerCallbacks()
	end)
	if not ok then return nil, tostring(removed) end
	if type(removed) ~= "number" or removed < 0 then
		return nil, "OnKeyPressed event or callback list unavailable"
	end
	return removed
end

local function objectName(object)
	local name = safeCall(object, "getObjectName")
	if type(name) == "string" and name ~= "" then return name end
	return "unknown"
end

local function spriteName(object)
	local sprite = safeCall(object, "getSprite")
	local name = safeCall(sprite, "getName")
	if type(name) == "string" and name ~= "" then return name end
	return "nil"
end

local function isIgnoredSprite(name)
	return name:find("^floors_") ~= nil or name:find("^blends_") ~= nil
end

local function scan()
	if type(isServer) == "function" and isServer() then return end
	local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
	if not player then
		warnOnce("player", "scan skipped: player unavailable")
		return
	end
	local x = safeCall(player, "getX")
	local y = safeCall(player, "getY")
	local z = safeCall(player, "getZ")
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		warnOnce("position", "scan skipped: player position unavailable")
		return
	end
	local px, py, pz = math.floor(x), math.floor(y), math.floor(z)
	local cell = type(getCell) == "function" and getCell() or nil
	if not cell then
		warnOnce("cell", "scan skipped: cell unavailable")
		return
	end
	local direction = safeCall(player, "getDir")
	print(TAG .. "---- player " .. px .. "," .. py .. "," .. pz .. " facing " .. tostring(direction) .. " ----")

	local objectCount = 0
	local printed = 0
	for tileX = px - RADIUS, px + RADIUS do
		for tileY = py - RADIUS, py + RADIUS do
			local square = safeCall(cell, "getGridSquare", tileX, tileY, pz)
			local objects = safeCall(square, "getObjects")
			local count = safeCall(objects, "size")
			if type(count) == "number" then
				for index = 0, count - 1 do
					local object = safeCall(objects, "get", index)
					if object then
						local sprite = spriteName(object)
						if not isIgnoredSprite(sprite) then
							objectCount = objectCount + 1
							if printed < MAX_OBJECT_LINES then
								printed = printed + 1
								print(TAG .. tileX .. "," .. tileY .. "," .. pz
									.. " idx=" .. index .. " object=" .. objectName(object)
									.. " spr=" .. sprite)
							end
						end
					end
				end
			end
		end
	end
	if objectCount > printed then
		print(TAG .. "truncated=" .. (objectCount - printed) .. " object(s)")
	end
	print(TAG .. "---- end objects=" .. objectCount .. " printed=" .. printed .. " ----")
end

local function onKeyPressed(key)
	if not Keyboard or key ~= Keyboard.KEY_F10 then return end
	local ok, reason = pcall(scan)
	if not ok then warnOnce("scan", "scan failed: " .. tostring(reason)) end
end

local keyEvent = Events and Events.OnKeyPressed
if keyEvent then
	local removed, removeFailure = removeWorkshopScanner()
	if removed == nil then
		warnOnce("remove-workshop", "Workshop scanner removal failed: " .. tostring(removeFailure))
	elseif removed == 0 then
		warnOnce("workshop-not-found", "Workshop F10 callback was not found; replacement may not suppress it")
	end
	local addOk, addReason = pcall(function() keyEvent.Add(onKeyPressed) end)
	if addOk then
		print(TAG .. "local scanner installed removedWorkshop=" .. tostring(removed or 0)
			.. " maxObjects=" .. MAX_OBJECT_LINES)
	else
		warnOnce("register", "could not register local scanner: " .. tostring(addReason))
	end
else
	warnOnce("event", "could not register local scanner: OnKeyPressed unavailable")
end
