local viewpointLoaded = pcall(require, "Viewpoint_Loot")
if not viewpointLoaded or type(ViewpointLoot) ~= "table" then
	print("[ChilaSeda_ViewpointSeatedRotation] Viewpoint unavailable; patch skipped.")
	return
end

local lastSeatedAngle = {}

local function updateSeatedRotation()
	if type(getNumActivePlayers) ~= "function" or type(getSpecificPlayer) ~= "function"
			or type(getCamera) ~= "function" then
		return
	end
	local playerCount = getNumActivePlayers() or 0
    for playerNum = 0, playerCount - 1 do
		local character = getSpecificPlayer(playerNum)
		local hasPositionAPI = character and type(character.getX) == "function"
			and type(character.getY) == "function"
		local seated = hasPositionAPI and type(character.isSitting) == "function"
			and character:isSitting()
		if seated then
			local camera = getCamera()
			if not camera or type(camera.getX) ~= "function" or type(camera.getY) ~= "function" then
				lastSeatedAngle[playerNum] = nil
			else
				local charX = character:getX()
				local charY = character:getY()
				local cameraX = camera:getX()
				local cameraY = camera:getY()

				if charX and charY and cameraX and cameraY
						and type(character.setDirectionAngle) == "function" then
					local angle = math.atan2(cameraY - charY, cameraX - charX)
					if not lastSeatedAngle[playerNum] or math.abs(angle - lastSeatedAngle[playerNum]) > 0.01 then
						lastSeatedAngle[playerNum] = angle
						local angleDegrees = math.deg(angle)
						character:setDirectionAngle(angleDegrees)
					end
				end
			end
		end
		if not seated then
			lastSeatedAngle[playerNum] = nil
		end
	end
end

-- OnTick is present in B42, but guard event registration so an incomplete event
-- table during Lua startup cannot stop the rest of this local patch from loading.
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
	Events.OnTick.Add(updateSeatedRotation)
end
