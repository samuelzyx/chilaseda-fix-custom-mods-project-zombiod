local pendingZombies = {}
local waitingBodies = {}
local bindings
local warned
local bridgeFailed

local function javaField(class, name)
    local field = class:getDeclaredField(name)
    field:setAccessible(true)
    return field
end

local function initializeBindings()
    if bindings then return bindings end
    if not luajava or not luajava.bindClass then return nil end

    local Class = luajava.bindClass("java.lang.Class")
    local Boolean = luajava.bindClass("java.lang.Boolean")
    local goreClass = Class.forName("bloodfx.Gore")
    local corpsesClass = Class.forName("viewpoint.models.Corpses")
    local corpseClass = Class.forName("viewpoint.models.Corpses$Corpse")

    bindings = {
        bodyMask = javaField(goreClass, "bodyMask"):get(nil),
        cutByPlayer = javaField(goreClass, "cutByPlayer"):get(nil),
        posesSeen = javaField(goreClass, "posesSeen"):get(nil),
        listed = javaField(corpsesClass, "listed"):get(nil),
        bodyField = javaField(corpseClass, "body"),
        modelField = javaField(corpseClass, "model"),
        poseField = javaField(corpseClass, "pose"),
        previousField = javaField(corpseClass, "previous"),
        trueValue = Boolean.TRUE,
    }
    return bindings
end

local function ensureBindings()
    if bindings then return bindings end
    if bridgeFailed then return nil end
    local ok, result = pcall(initializeBindings)
    if ok and result then return result end
    bridgeFailed = true
    if not warned then
        warned = true
        print("[ChilaSeda_BloodFXCorpseLimbs] Java/Viewpoint bridge unavailable; mask handoff inactive")
    end
    return nil
end

local function snapshotMask(zombie)
    local ok, player = pcall(function() return zombie:getAnimationPlayer() end)
    if not ok or not player then return nil end

    local b = ensureBindings()
    if not b then return nil end
    local okMask, mask = pcall(function() return b.cutByPlayer:get(player) end)
    if not okMask or not mask then return nil end
    local okValue, value = pcall(function() return mask:intValue() end)
    if not okValue or value == 0 then return nil end
    return mask
end

local function readPosition(character)
    local ok, x, y, z = pcall(function()
        return character:getX(), character:getY(), character:getZ()
    end)
    if not ok then return nil end
    return { x = x, y = y, z = z }
end

local function isFemale(character)
    local ok, value = pcall(function() return character:isFemale() end)
    if ok then return value end
    return nil
end

local function onZombieDead(zombie)
    if not zombie then return end
    local mask = snapshotMask(zombie)
    if not mask then return end
    local position = readPosition(zombie)
    if not position then return end

    pendingZombies[zombie] = {
        mask = mask,
        position = position,
        female = isFemale(zombie),
        age = 0,
    }
end

local function matchDeadZombie(body)
    local position = readPosition(body)
    if not position then return nil end
    local female = isFemale(body)
    local bestZombie, bestData, bestDistance

    for zombie, data in pairs(pendingZombies) do
        local dz = math.abs(position.z - data.position.z)
        local dx = position.x - data.position.x
        local dy = position.y - data.position.y
        local distance = dx * dx + dy * dy
        if dz <= 0.1 and distance <= 0.75 * 0.75
            and (female == nil or data.female == nil or female == data.female)
            and (not bestDistance or distance < bestDistance) then
            bestZombie, bestData, bestDistance = zombie, data, distance
        end
    end

    if bestZombie then pendingZombies[bestZombie] = nil end
    return bestData
end

local function findCorpseEntry(body, b)
    local list = b.listed
    if not list then return nil end
    for index = 0, list:size() - 1 do
        local entry = list:get(index)
        local ok, entryBody = pcall(function() return b.bodyField:get(entry) end)
        if ok and entryBody == body then return entry end
    end
    return nil
end

local function applyMask(body, data, b)
    local entry = findCorpseEntry(body, b)
    if not entry then return false end

    -- Seed the body's mask so Blood FX's own first corpse-pose hook reads the final combat mask.
    local seeded = pcall(function() b.bodyMask:put(body, data.mask) end)
    if not seeded then return false end

    -- If the pose hook already ran, update its render player and keep its early dedupe guard
    -- from replacing the final mask with a freshly rebuilt full-body mask.
    local okModel, model = pcall(function() return b.modelField:get(entry) end)
    local appliedToPlayer = false
    if okModel and model then
        local okPlayer, player = pcall(function() return model:getAnimationPlayer() end)
        if okPlayer and player then
            appliedToPlayer = pcall(function() b.cutByPlayer:put(player, data.mask) end)
        end
    end
    if appliedToPlayer then
        local okPose, pose = pcall(function() return b.poseField:get(entry) end)
        if okPose and pose then pcall(function() b.posesSeen:put(pose, b.trueValue) end) end
        local okPrevious, previous = pcall(function() return b.previousField:get(entry) end)
        if okPrevious and previous then pcall(function() b.posesSeen:put(previous, b.trueValue) end) end
    end
    return appliedToPlayer
end

local function onDeadBodySpawn(body)
    if not body then return end
    local data = matchDeadZombie(body)
    waitingBodies[body] = { mask = data and data.mask or nil, age = 0 }
end

local function onTick()
    for zombie, data in pairs(pendingZombies) do
        data.age = data.age + 1
        if data.age > 300 then pendingZombies[zombie] = nil end
    end

    for body, data in pairs(waitingBodies) do
        if not data.mask then
            local match = matchDeadZombie(body)
            if match then data.mask = match.mask end
        end
        local b = ensureBindings()
        local applied = false
        if b and data.mask then
            local okApply, result = pcall(applyMask, body, data, b)
            applied = okApply and result
        end
        if applied then
            waitingBodies[body] = nil
        else
            data.age = data.age + 1
            if data.age > 300 then waitingBodies[body] = nil end
        end
    end

    ensureBindings()
end

if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
    Events.OnZombieDead.Add(onZombieDead)
end
if Events and Events.OnDeadBodySpawn and Events.OnDeadBodySpawn.Add then
    Events.OnDeadBodySpawn.Add(onDeadBodySpawn)
end
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(onTick)
end

print("[ChilaSeda_BloodFXCorpseLimbs] v0.1.2 loaded; preserving final combat dismemberment mask")
