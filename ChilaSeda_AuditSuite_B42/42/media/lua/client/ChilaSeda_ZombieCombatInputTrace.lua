-- Bounded, read-only capture of right-mouse hold, Ctrl/Shift, and melee state transitions.
local PREFIX = "[ChilaSeda ZombieCombatInputTrace]"
local MAX_ATTEMPTS_PER_SESSION = 24
local MAX_TRACE_LINES = 768
local MAX_SAMPLES_PER_ATTEMPT = 10
local SAMPLE_INTERVAL_MS = 100
local CAPTURE_WINDOW_MS = 1400
local MAX_MOUSE_HOLDS_PER_SESSION = 24
local MAX_MOUSE_SAMPLES_PER_HOLD = 10
local MOUSE_SAMPLE_INTERVAL_MS = 250
local MAX_HIT_TRACE_LINES = 64
local trace = {
	attempts = 0,
	lines = 0,
	pending = {},
	capped = false,
	hitLines = 0,
	hitCapped = false,
	rightMouseHolds = 0,
	rightMouseCapped = false,
	rightMouseDown = false,
	rightMouseTrack = nil,
	lastCtrlDown = false,
}

local function nowMs()
	if type(getTimestampMs) == "function" then
		local ok, value = pcall(getTimestampMs)
		if ok and tonumber(value) then return tonumber(value) end
	end
	return 0
end

local function read(object, method, ...)
	if object == nil then return false, nil end
	local args = { ... }
	local ok, value = pcall(function()
		local fn = object[method]
		if type(fn) ~= "function" then return nil end
		return fn(object, unpack(args))
	end)
	return ok, value
end

local function safeText(value)
	if value == nil then return "na" end
	return tostring(value):gsub("[%c|,]", "_")
end

local function value(object, method, ...)
	if object == nil then return "na" end
	local ok, result = read(object, method, ...)
	if not ok then return "err" end
	return safeText(result)
end

local function boolValue(object, method, ...)
	local ok, result = read(object, method, ...)
	if not ok or result == nil then return "na" end
	return result == true and "1" or "0"
end

local function isZombie(object)
	if type(instanceof) ~= "function" then return false end
	local ok, result = pcall(instanceof, object, "IsoZombie")
	return ok and result == true
end

local function localPlayer(player)
	if player == nil then return false end
	local ok, mainPlayer = pcall(getSpecificPlayer, 0)
	if ok and mainPlayer ~= nil then return player == mainPlayer end
	local localOk, result = read(player, "isLocalPlayer")
	return localOk and result == true
end

local function keyDown(name, fallback)
	if Keyboard and type(Keyboard.isKeyDown) == "function" then
		local key = Keyboard[name] or fallback
		if key ~= nil then
			local ok, down = pcall(Keyboard.isKeyDown, key)
			if ok and down == true then return true end
		end
	end
	return false
end

local function shiftDown()
	if keyDown("KEY_LSHIFT", 42) or keyDown("KEY_RSHIFT", 54) then return true end
	if type(isShiftKeyDown) == "function" then
		local ok, down = pcall(isShiftKeyDown)
		return ok and down == true
	end
	return false
end

local function ctrlDown()
	if Keyboard and type(Keyboard.isKeyDown) == "function" then
		local left, right = Keyboard.KEY_LCONTROL, Keyboard.KEY_RCONTROL
		if left ~= nil then
			local ok, down = pcall(Keyboard.isKeyDown, left)
			if ok and down then return true end
		end
		if right ~= nil then
			local ok, down = pcall(Keyboard.isKeyDown, right)
			if ok and down then return true end
		end
	end
	if type(isCtrlKeyDown) == "function" then
		local ok, down = pcall(isCtrlKeyDown)
		return ok and down == true
	end
	return false
end

local function mouseDown(button)
	if type(isMouseButtonDown) ~= "function" then return "na" end
	local ok, down = pcall(isMouseButtonDown, button)
	if not ok then return "err" end
	return down == true and "1" or "0"
end

local function typeName(object)
	if object == nil then return "none" end
	local kind = object.Type or object.type
	if kind ~= nil then return safeText(kind) end
	return value(object, "getActionStateName")
end

local function queueSummary(player)
	local queueApi = ISTimedActionQueue
	local queues = queueApi and queueApi.queues
	if type(queues) ~= "table" then return "queue=unavailable" end
	local queue = queues[player]
	if queue == nil then
		for _, candidate in pairs(queues) do
			if candidate and candidate.character == player then
				queue = candidate
				break
			end
		end
	end
	if queue == nil then return "queue=none" end
	local actions = queue.queue
	local types = {}
	if type(actions) == "table" then
		for index = 1, math.min(#actions, 5) do
			types[#types + 1] = typeName(actions[index])
		end
	end
	return "queueCurrent=" .. typeName(queue.current)
		.. " queue=" .. (#types > 0 and table.concat(types, ":") or "empty")
end

local function xy(object)
	if object == nil then return "na,na" end
	return value(object, "getX") .. "," .. value(object, "getY")
end

local function distance(player, target)
	if player == nil or target == nil then return "na" end
	local okX, px = read(player, "getX")
	local okY, py = read(player, "getY")
	local okTX, tx = read(target, "getX")
	local okTY, ty = read(target, "getY")
	if not (okX and okY and okTX and okTY)
			or type(px) ~= "number" or type(py) ~= "number"
			or type(tx) ~= "number" or type(ty) ~= "number" then return "na" end
	return string.format("%.2f", math.sqrt((tx - px) * (tx - px) + (ty - py) * (ty - py)))
end

local function targetFor(player)
	local ok, target = read(player, "getTarget")
	if ok and target ~= nil then return target end
	return nil
end

local function log(message)
	if trace.lines >= MAX_TRACE_LINES then return end
	trace.lines = trace.lines + 1
	print(PREFIX .. " line=" .. tostring(trace.lines) .. " " .. message)
end

local function sample(track, phase, eventButton)
	if track.samples >= MAX_SAMPLES_PER_ATTEMPT then return end
	track.samples = track.samples + 1
	local player = track.player
	local target = targetFor(player)
	local pathTarget = value(player, "getPathTargetX") .. ","
		.. value(player, "getPathTargetY") .. "," .. value(player, "getPathTargetZ")
	local attackSquare = nil
	local squareOk, square = read(player, "getAttackTargetSquare")
	if squareOk then attackSquare = square end
	local initialId = value(track.initialTarget, "getOnlineID")
	local currentId = value(target, "getOnlineID")
	local targetType = isZombie(target) and "IsoZombie" or (target and typeName(target) or "none")
	local targetFloor = isZombie(target) and boolValue(target, "isOnFloor") or "na"
	local targetCrawl = isZombie(target) and boolValue(target, "isCrawling") or "na"
	local forward = "na,na"
	if target then
		local forwardOk, direction = read(target, "getForwardDirection")
		if forwardOk and direction then
			forward = value(direction, "getX") .. "," .. value(direction, "getY")
		end
	end
	local shift = shiftDown() and "1" or "0"
	local ctrl = ctrlDown() and "1" or "0"
	local right = mouseDown(1)
	local left = mouseDown(0)
	local age = math.floor(nowMs() - track.startedAt)
	log("attempt=" .. tostring(track.id) .. " phase=" .. phase
		.. " sample=" .. tostring(track.samples - 1)
		.. " ageMs=" .. tostring(age)
		.. " eventButton=" .. safeText(eventButton)
		.. " shift=" .. shift .. " ctrl=" .. ctrl .. " mouse0=" .. left .. " mouse1=" .. right
		.. " playerState=" .. value(player, "getActionStateName")
		.. " running=" .. boolValue(player, "isRunning")
		.. " aiming=" .. boolValue(player, "isAiming")
		.. " guarding=" .. boolValue(player, "isGuarding")
		.. " attacking=" .. boolValue(player, "isAttacking")
		.. " attackStarted=" .. boolValue(player, "isAttackStarted")
		.. " attackAnim=" .. boolValue(player, "isPerformingAttackAnimation")
		.. " attackOutcome=" .. value(player, "getAttackOutcome")
		.. " attackDidDamage=" .. boolValue(player, "getAttackDidDamage")
		.. " pathRunning=" .. boolValue(player, "isPathfindRunning")
		.. " pathTarget=" .. pathTarget
		.. " targetType=" .. safeText(targetType)
		.. " targetId=" .. currentId .. " initialTargetId=" .. initialId
		.. " targetDistance=" .. distance(player, target)
		.. " targetState=" .. value(target, "getActionStateName")
		.. " targetReaction=" .. value(target, "getHitReaction")
		.. " targetFloor=" .. targetFloor .. " targetCrawl=" .. targetCrawl
		.. " targetHealth=" .. value(target, "getHealth")
		.. " targetForward=" .. forward
		.. " playerXY=" .. xy(player) .. " targetXY=" .. xy(target)
		.. " attackSquare=" .. (attackSquare and (value(attackSquare, "getX") .. ","
			.. value(attackSquare, "getY") .. "," .. value(attackSquare, "getZ")) or "none")
		.. " " .. queueSummary(player))
	track.lastTarget = target
end

local function rightMouseState(player, phase, track)
	if not player then return end
	local target = targetFor(player)
	local targetType = isZombie(target) and "IsoZombie" or (target and typeName(target) or "none")
	local targetFloor = isZombie(target) and boolValue(target, "isOnFloor") or "na"
	local targetCrawl = isZombie(target) and boolValue(target, "isCrawling") or "na"
	local pathTarget = value(player, "getPathTargetX") .. ","
		.. value(player, "getPathTargetY") .. "," .. value(player, "getPathTargetZ")
	local squareOk, attackSquare = read(player, "getAttackTargetSquare")
	local square = squareOk and attackSquare and (value(attackSquare, "getX") .. ","
		.. value(attackSquare, "getY") .. "," .. value(attackSquare, "getZ")) or "none"
	local age = track and math.floor(nowMs() - track.startedAt) or 0
	local sampleIndex = track and track.samples or 0
	log("right-button phase=" .. phase
		.. " hold=" .. tostring(track and track.id or "na")
		.. " sample=" .. tostring(sampleIndex)
		.. " ageMs=" .. tostring(age)
		.. " mouse1=" .. mouseDown(1)
		.. " mouse0=" .. mouseDown(0)
		.. " ctrl=" .. (ctrlDown() and "1" or "0")
		.. " shift=" .. (shiftDown() and "1" or "0")
		.. " playerState=" .. value(player, "getActionStateName")
		.. " aiming=" .. boolValue(player, "isAiming")
		.. " guarding=" .. boolValue(player, "isGuarding")
		.. " moving=" .. boolValue(player, "isMoving")
		.. " running=" .. boolValue(player, "isRunning")
		.. " attacking=" .. boolValue(player, "isAttacking")
		.. " attackStarted=" .. boolValue(player, "isAttackStarted")
		.. " attackAnim=" .. boolValue(player, "isPerformingAttackAnimation")
		.. " pathRunning=" .. boolValue(player, "isPathfindRunning")
		.. " pathTarget=" .. pathTarget
		.. " targetType=" .. safeText(targetType)
		.. " targetId=" .. value(target, "getOnlineID")
		.. " targetDistance=" .. distance(player, target)
		.. " targetState=" .. value(target, "getActionStateName")
		.. " targetFloor=" .. targetFloor
		.. " targetCrawl=" .. targetCrawl
		.. " attackSquare=" .. square
		.. " playerXY=" .. xy(player)
		.. " targetXY=" .. xy(target)
		.. " " .. queueSummary(player))
end

local function pollRightMouse(player)
	local now = nowMs()
	local rightDown = mouseDown(1) == "1"
	local controlDown = ctrlDown()
	local track = trace.rightMouseTrack

	if rightDown and not trace.rightMouseDown then
		trace.rightMouseDown = true
		if trace.rightMouseHolds < MAX_MOUSE_HOLDS_PER_SESSION then
			trace.rightMouseHolds = trace.rightMouseHolds + 1
			track = { id = trace.rightMouseHolds, startedAt = now, nextSampleAt = now + MOUSE_SAMPLE_INTERVAL_MS,
				samples = 0 }
			trace.rightMouseTrack = track
			rightMouseState(player, "down", track)
		elseif not trace.rightMouseCapped then
			trace.rightMouseCapped = true
			log("right-button capped=1 maxHolds=" .. tostring(MAX_MOUSE_HOLDS_PER_SESSION))
		end
	elseif not rightDown and trace.rightMouseDown then
		trace.rightMouseDown = false
		if track then rightMouseState(player, "up", track) end
		trace.rightMouseTrack = nil
	end

	if rightDown and track and now >= track.nextSampleAt
			and track.samples < MAX_MOUSE_SAMPLES_PER_HOLD then
		track.samples = track.samples + 1
		rightMouseState(player, "held", track)
		track.nextSampleAt = now + MOUSE_SAMPLE_INTERVAL_MS
	end

	if controlDown ~= trace.lastCtrlDown
			and (rightDown or boolValue(player, "isAiming") == "1"
				or boolValue(player, "isAttacking") == "1") then
		log("modifier phase=control-change ctrl=" .. (controlDown and "1" or "0")
			.. " mouse1=" .. mouseDown(1)
			.. " playerState=" .. value(player, "getActionStateName")
			.. " aiming=" .. boolValue(player, "isAiming")
			.. " attackStarted=" .. boolValue(player, "isAttackStarted"))
	end
	trace.lastCtrlDown = controlDown
end

local function closeTrack(track, reason)
	log("attempt=" .. tostring(track.id) .. " phase=window-end result=" .. reason
		.. " samples=" .. tostring(track.samples) .. " elapsedMs="
		.. tostring(math.floor(nowMs() - track.startedAt)))
end

local function onMouseDown(eventButton)
	local player = nil
	if type(getSpecificPlayer) == "function" then
		local ok, valuePlayer = pcall(getSpecificPlayer, 0)
		if ok then player = valuePlayer end
	end
	if not player then return end
	local left, right = mouseDown(0), mouseDown(1)
	local shift = shiftDown()
	local target = targetFor(player)
	local targetZombie = isZombie(target)
	local attacking = boolValue(player, "isAttacking") == "1"
	if not shift and not (left == "1" and (targetZombie or attacking))
			and not (right == "1" and targetZombie) then return end
	if trace.attempts >= MAX_ATTEMPTS_PER_SESSION then
		if not trace.capped then
			trace.capped = true
			log("capped=1 maxAttempts=" .. tostring(MAX_ATTEMPTS_PER_SESSION))
		end
		return
	end
	trace.attempts = trace.attempts + 1
	local track = {
		id = trace.attempts,
		player = player,
		initialTarget = target,
		startedAt = nowMs(),
		nextSampleAt = nowMs() + SAMPLE_INTERVAL_MS,
		samples = 0,
	}
	trace.pending[#trace.pending + 1] = track
	sample(track, "mouse-down", eventButton)
end

local function onPlayerUpdate(player)
	if not localPlayer(player) then return end
	pollRightMouse(player)
	local now = nowMs()
	local index = 1
	while index <= #trace.pending do
		local track = trace.pending[index]
		if track.player ~= player then
			index = index + 1
		elseif now >= track.nextSampleAt and track.samples < MAX_SAMPLES_PER_ATTEMPT
				and now - track.startedAt <= CAPTURE_WINDOW_MS then
			sample(track, "update", "na")
			track.nextSampleAt = now + SAMPLE_INTERVAL_MS
			index = index + 1
		elseif now - track.startedAt > CAPTURE_WINDOW_MS
				or track.samples >= MAX_SAMPLES_PER_ATTEMPT then
			closeTrack(track, "captured")
			table.remove(trace.pending, index)
		else
			index = index + 1
		end
	end
end

local function reset()
	trace.attempts = 0
	trace.lines = 0
	trace.pending = {}
	trace.capped = false
	trace.hitLines = 0
	trace.hitCapped = false
	trace.rightMouseHolds = 0
	trace.rightMouseCapped = false
	trace.rightMouseDown = false
	trace.rightMouseTrack = nil
	trace.lastCtrlDown = ctrlDown()
	print(PREFIX .. " session=ready readOnly=1 maxAttempts=" .. tostring(MAX_ATTEMPTS_PER_SESSION)
		.. " sampleIntervalMs=" .. tostring(SAMPLE_INTERVAL_MS)
		.. " captureWindowMs=" .. tostring(CAPTURE_WINDOW_MS)
		.. " maxRightMouseHolds=" .. tostring(MAX_MOUSE_HOLDS_PER_SESSION)
		.. " rightMouseSampleIntervalMs=" .. tostring(MOUSE_SAMPLE_INTERVAL_MS))
end

if Events and Events.OnMouseDown and type(Events.OnMouseDown.Add) == "function" then
	Events.OnMouseDown.Add(onMouseDown)
end
if Events and Events.OnPlayerUpdate and type(Events.OnPlayerUpdate.Add) == "function" then
	Events.OnPlayerUpdate.Add(onPlayerUpdate)
end
if Events and Events.OnHitZombie and type(Events.OnHitZombie.Add) == "function" then
	Events.OnHitZombie.Add(function(victim, attacker)
		if not isZombie(victim) or not localPlayer(attacker) then return end
		if trace.hitLines >= MAX_HIT_TRACE_LINES then
			if not trace.hitCapped then
				trace.hitCapped = true
				log("melee-hit capped=1 maxLines=" .. tostring(MAX_HIT_TRACE_LINES))
			end
			return
		end
		trace.hitLines = trace.hitLines + 1
		local inputId = "na"
		for index = #trace.pending, 1, -1 do
			local track = trace.pending[index]
			if track.player == attacker and (track.initialTarget == victim or track.lastTarget == victim) then
				inputId = tostring(track.id)
				break
			end
		end
		log("melee-hit inputAttempt=" .. inputId .. " targetId=" .. value(victim, "getOnlineID")
			.. " targetFloor=" .. boolValue(victim, "isOnFloor")
			.. " targetState=" .. value(victim, "getActionStateName"))
	end)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
	Events.OnGameStart.Add(reset)
end
if Events and Events.OnMainMenuEnter and type(Events.OnMainMenuEnter.Add) == "function" then
	Events.OnMainMenuEnter.Add(function() trace.pending = {} end)
end
print(PREFIX .. " loaded readOnly=1")
