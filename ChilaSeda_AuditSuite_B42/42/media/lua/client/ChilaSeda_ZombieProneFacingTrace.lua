-- Bounded, read-only trace for melee knockdown facing reports.
local PREFIX = "[ChilaSeda ZombieProneTrace]"
local MAX_HITS_PER_SESSION = 16
local LAST_TICK = 10
local trace = { pending = {}, hits = 0, nextId = 0 }

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

local function text(value)
	if value == nil then return "na" end
	return tostring(value):gsub("[%c|]", "_")
end

local function field(object, method, ...)
	local ok, value = read(object, method, ...)
	if not ok or value == nil then return "na" end
	return text(value)
end

local function booleanField(object, method, ...)
	local ok, value = read(object, method, ...)
	if not ok or value == nil then return "na" end
	return value == true and "1" or "0"
end

local function isZombie(object)
	if type(instanceof) ~= "function" then return false end
	local ok, value = pcall(instanceof, object, "IsoZombie")
	return ok and value == true
end

local function localPlayer(attacker)
	if attacker == nil then return false end
	local ok, player = pcall(getSpecificPlayer, 0)
	if ok and player ~= nil and player == attacker then return true end
	local okLocal, isLocal = read(attacker, "isLocalPlayer")
	return okLocal and isLocal == true
end

local function weaponName(weapon)
	local name = field(weapon, "getFullType")
	if name ~= "na" then return name end
	return field(weapon, "getType")
end

local function vector(object)
	local ok, direction = read(object, "getForwardDirection")
	if not ok or direction == nil then return "na,na" end
	return field(direction, "getX") .. "," .. field(direction, "getY")
end

local function sample(track)
	local now = tonumber(getTimestampMs()) or track.startedAt
	local age = math.floor(now - track.startedAt)
	local attacker = track.attacker
	local victim = track.victim
	print(string.format(
		"%s id=%d sample=%d ageMs=%d weapon=%s part=%s state=%s reaction=%s dead=%s floor=%s crawl=%s hitBehind=%s behindVar=%s fallFrontVar=%s forward=%s zombieXY=%s,%s attackerXY=%s,%s",
		PREFIX,
		track.id,
		track.tick,
		age,
		track.weapon,
		track.part,
		field(victim, "getActionStateName"),
		field(victim, "getHitReaction"),
		booleanField(victim, "isDead"),
		booleanField(victim, "isOnFloor"),
		booleanField(victim, "isCrawling"),
		booleanField(victim, "isHitFromBehind"),
		booleanField(victim, "getVariableBoolean", "FromBehind"),
		booleanField(victim, "getVariableBoolean", "FallOnFront"),
		vector(victim),
		field(victim, "getX"),
		field(victim, "getY"),
		field(attacker, "getX"),
		field(attacker, "getY")
	))
end

local function onHitZombie(victim, attacker, part, weapon)
	if not isZombie(victim) or not localPlayer(attacker) then return end
	local okMelee, melee = read(weapon, "isMelee")
	if okMelee and melee == false then return end
	if trace.hits >= MAX_HITS_PER_SESSION then
		if trace.hits == MAX_HITS_PER_SESSION then
			print(PREFIX .. " capped=1 maxHits=" .. tostring(MAX_HITS_PER_SESSION))
			trace.hits = trace.hits + 1
		end
		return
	end
	trace.hits = trace.hits + 1
	trace.nextId = trace.nextId + 1
	local id = trace.nextId
	local startedAt = tonumber(getTimestampMs()) or 0
	local track = {
		id = id,
		victim = victim,
		attacker = attacker,
		weapon = weaponName(weapon),
		part = text(part),
		startedAt = startedAt,
		tick = 0,
	}
	trace.pending[#trace.pending + 1] = track
	print(string.format("%s id=%d event=hit weapon=%s part=%s", PREFIX, id, track.weapon, track.part))
end

local function onTick()
	local index = 1
	while index <= #trace.pending do
		local track = trace.pending[index]
		sample(track)
		track.tick = track.tick + 1
		if track.tick > LAST_TICK then
			table.remove(trace.pending, index)
		else
			index = index + 1
		end
	end
end

local function reset()
	trace.pending = {}
	trace.hits = 0
	trace.nextId = 0
	print(PREFIX .. " session=ready maxHits=" .. tostring(MAX_HITS_PER_SESSION)
		.. " samples=0-" .. tostring(LAST_TICK))
end

Events.OnHitZombie.Add(onHitZombie)
Events.OnTick.Add(onTick)
Events.OnGameStart.Add(reset)
Events.OnMainMenuEnter.Add(function() trace.pending = {} end)
print(PREFIX .. " loaded readOnly=1")
