-- Small integration layer: reuse Living World's fishing job and shelter action.
local PREFIX = "[ChilaSeda_LivingWorldFieldcraft] "
local TRACE_ENABLED = true
local TRACE_LIMIT = 128
local traceCount = 0
local lastStormState = {}

local function trace(message)
    if not TRACE_ENABLED or traceCount >= TRACE_LIMIT then return end
    traceCount = traceCount + 1
    print(PREFIX .. message .. " trace=" .. traceCount .. "/" .. TRACE_LIMIT)
end

-- Fishing.lua registers the "fish" job with LivingWorld.Work as a require side effect.
local fishOk, FishingJob = pcall(require, "LivingWorld/Fishing")
if fishOk and type(FishingJob) == "table" and type(FishingJob.catch) == "function" then
    trace("fishing=loaded job=fish registration=module-side-effect fallback=LivingWorld-native-job")
    local nativeCatch = FishingJob.catch
    local catchTraces = 0
    FishingJob.catch = function(level, lure, x, y)
        local item, isTrash = nativeCatch(level, lure, x, y)
        if TRACE_ENABLED and catchTraces < 32 then
            catchTraces = catchTraces + 1
            trace("fishing=catch level=" .. tostring(level) .. " lure=" .. tostring(lure)
                .. " result=" .. (item and (isTrash and "trash" or "fish") or "no-bite")
                .. " fallback=LivingWorld-native-catch catchTrace=" .. catchTraces .. "/32")
        end
        return item, isTrash
    end
else
    trace("fishing=unavailable error=" .. tostring(FishingJob) .. " fallback=LivingWorld-job-not-registered")
end

local actionsOk, Actions = pcall(require, "LivingWorld/Actions")
if not actionsOk or type(Actions) ~= "table" or type(Actions.shelter) ~= "table" then
    trace("shelter=unavailable error=" .. tostring(Actions) .. " fallback=LivingWorld-native-shelter")
    return
end

local shelter = Actions.shelter
local nativeScore, nativeStart = shelter.score, shelter.start
local function stormPhase()
    if not ModData or type(ModData.get) ~= "function" then return "unavailable" end
    local ok, state = pcall(ModData.get, "AnomalousStorm")
    if not ok or type(state) ~= "table" then return "idle" end
    if state.Warning == true then return "warning" end
    if state.RainActive == true or state.Phase == "rain-ramping"
            or state.Phase == "thunderstorm" or state.Phase == "clearing" then
        return tostring(state.Phase or "red-rain")
    end
    return "idle"
end

local function personKey(ctx)
    return tostring(ctx.personId or (ctx.person and (ctx.person.id or ctx.person.forename)) or "unknown")
end

shelter.score = function(ctx)
    local phase = stormPhase()
    local key = personKey(ctx)
    if phase == "idle" or phase == "unavailable" then
        if lastStormState[key] and lastStormState[key] ~= "idle" then
            trace("storm=ended npc=" .. key .. " fallback=LivingWorld-native-shelter-score")
        end
        lastStormState[key] = "idle"
        return nativeScore(ctx)
    end

    local square = ctx.body and ctx.body:getCurrentSquare()
    local eligible = square ~= nil and square:isOutside() and (ctx.threatCount or 0) <= 0
    if not eligible then
        lastStormState[key] = phase
        return nativeScore(ctx)
    end
    if ctx.mind.giveUpUntil and ctx.now < ctx.mind.giveUpUntil then
        return nativeScore(ctx)
    end

    if lastStormState[key] ~= phase then
        trace("storm=" .. phase .. " npc=" .. key .. " outside=true threats=" .. tostring(ctx.threatCount or 0)
            .. " decision=seek-shelter fallback=existing-shelter-action")
        lastStormState[key] = phase
    end
    local ordinary = nativeScore(ctx)
    return math.max(ordinary or 0, 1.25)
end

shelter.start = function(ctx)
    local phase = stormPhase()
    if phase ~= "idle" and phase ~= "unavailable" then
        trace("shelter=start phase=" .. phase .. " npc=" .. personKey(ctx)
            .. " route=LivingWorld-Comfort.shelterNear radius=20")
    end
    return nativeStart(ctx)
end

-- A team member ordered to stay is normally leashed to the base by Goals.goTo.
-- During red rain, relax only that leash check for the shelter walk; forbidden
-- zones and normal path checks remain enforced by the native errand path.
local goalsOk, Goals = pcall(require, "LivingWorld/Brain/Goals")
local coreOk, BrainCore = pcall(require, "LivingWorld/Brain/Core")
local personsOk, Persons = pcall(require, "LivingWorld/Persons")
if goalsOk and coreOk and personsOk and type(Goals.goTo) == "function" then
    local nativeGoTo = Goals.goTo
    Goals.goTo = function(personId, x, y, z, gait)
        local person = Persons.get(personId)
        local mind = BrainCore.mindOf(personId)
        if stormPhase() == "idle" or stormPhase() == "unavailable"
                or not person or person.order ~= "stay" or not mind or mind.action ~= "shelter" then
            return nativeGoTo(personId, x, y, z, gait)
        end
        local previous = mind.action
        mind.action = "errand"
        local ok, result = pcall(nativeGoTo, personId, x, y, z, gait)
        mind.action = previous
        if not ok then error(result) end
        trace("shelter=leash-bypass npc=" .. tostring(personId) .. " order=stay fallback=Goals.errand-base-leash")
        return result
    end
    trace("shelter=stay-order-hooked goal=LivingWorld.Brain.Goals.goTo scope=storm-shelter-only")
else
    trace("shelter=stay-order-hook-unavailable fallback=LivingWorld-native-base-leash")
end

trace("shelter=hooked action=LivingWorld.Actions.shelter stormSource=ModData.AnomalousStorm")
