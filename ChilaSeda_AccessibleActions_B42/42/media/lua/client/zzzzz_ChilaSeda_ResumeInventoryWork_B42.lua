require "ActionManager"
require "Entity/TimedActions/ISHandcraftAction"
require "TimedActions/ISDryMyself"

local TAG = "[ChilaSeda_InventoryWorkResume] "
local jobsByPlayer = {}
local originalHandcraftNew = ISHandcraftAction.new
local originalDryMyselfNew = ISDryMyself.new
local originalQueueAdd = ISTimedActionQueue.add
local originalQueueReset = ISTimedActionQueue.resetQueue

ISDryMyself.new = function(self, character, item, ...)
    local action = originalDryMyselfNew(self, character, item, ...)
    if action then
        action.chilaSedaResumeDrying = true
        action.chilaSedaResumeBaseMaxTime = action.maxTime
    end
    return action
end

local function recipeLooksLikeInventoryWork(recipe)
    if not recipe then return false end
    local labels = {}
    if type(recipe.getName) == "function" then
        local ok, value = pcall(recipe.getName, recipe)
        if ok and value then labels[#labels + 1] = tostring(value) end
    end
    if type(recipe.getTranslationName) == "function" then
        local ok, value = pcall(recipe.getTranslationName, recipe)
        if ok and value then labels[#labels + 1] = tostring(value) end
    end
    for _, label in ipairs(labels) do
        label = string.lower(label):gsub("[%s_%-]", "")
        if string.find(label, "ripclothing", 1, true)
                or string.find(label, "tearclothing", 1, true)
                or string.find(label, "dismantle", 1, true) then
            return true
        end
    end
    return false
end

ISHandcraftAction.new = function(self, character, recipe, containers, isoObject,
        craftBench, ...)
    local action = originalHandcraftNew(self, character, recipe, containers,
        isoObject, craftBench, ...)
    -- Inventory dismantling and clothing recipes only. World-object furniture
    -- dismantling has an isoObject/craftBench and remains vanilla.
    if action and not isoObject and not craftBench
            and recipeLooksLikeInventoryWork(recipe) then
        action.chilaSedaInventoryWork = true
    end
    return action
end

local function makeJob(player)
    local job = { player = player, pendingActions = nil, pendingResume = false }
    jobsByPlayer[player] = job
    return job
end

local function jobForQueuedWork(player, action, context)
    if not player then return nil end
    local job
    if context then
        job = context.chilaSedaResumeJob or makeJob(player)
        context.chilaSedaResumeJob = job
        job.batchContext = context
    elseif action and (action.chilaSedaInventoryWork
            or action.chilaSedaResumeDrying) then
        job = jobsByPlayer[player] or makeJob(player)
    end
    if not job then return nil end
    if context then action.chilaSedaInventoryWork = true end
    action.chilaSedaInventoryWorkJob = job
    if action.chilaSedaResumeDrying then
        action.chilaSedaResumeDryingJob = job
    end
    action.stopOnWalk = false
    action.stopOnRun = false
    action.stopOnAim = false
    return job
end

local function isPlayerMoving(player)
    for _, methodName in ipairs({ "isWalking", "isRunning" }) do
        local method = player and player[methodName]
        if type(method) == "function" then
            local ok, moving = pcall(method, player)
            if ok and moving == true then return true end
        end
    end
    return false
end

local function dryingActionIsValid(action)
    if not action or type(action.isValid) ~= "function" then return false end
    local item = action.item
    if item and type(item.getCurrentUsesFloat) == "function" then
        local usesOk, uses = pcall(item.getCurrentUsesFloat, item)
        if not usesOk or type(uses) ~= "number" or uses <= 0 then return false end
    end
    local ok, valid = pcall(action.isValid, action)
    return ok and valid == true
end

ISTimedActionQueue.add = function(action, ...)
    if action and action.character then
        local shared = ChilaSedaAccessibleActions
        local context = shared and shared.dismantleQueueContext
        jobForQueuedWork(action.character, action, context)
    end
    return originalQueueAdd(action, ...)
end

ISTimedActionQueue.resetQueue = function(queue, ...)
    local player = queue and queue.character
    local job = player and jobsByPlayer[player]
    local snapshot = {}
    if job and queue.queue then
        for _, action in ipairs(queue.queue) do
            if action.chilaSedaInventoryWorkJob == job
                    or action.chilaSedaResumeDryingJob == job then
                if action.chilaSedaResumeDryingJob == job then
                    if not dryingActionIsValid(action) then
                        print(TAG .. "drying action is no longer valid; not resuming it")
                    else
                        -- Queued actions have no engine action until begin() runs.
                        if action.action and type(action.getJobDelta) == "function" then
                            local ok, delta = pcall(action.getJobDelta, action)
                            if ok and type(delta) == "number" then
                                action.chilaSedaResumeDelta = math.max(0, math.min(1, delta))
                            end
                        end
                        snapshot[#snapshot + 1] = action
                    end
                else
                    snapshot[#snapshot + 1] = action
                end
            end
        end
    end

    local results = { pcall(originalQueueReset, queue, ...) }
    if not results[1] then error(results[2]) end
    if job and #snapshot > 0 then
        job.pendingActions = snapshot
        job.pendingResume = true
        print(TAG .. "queued inventory work or drying paused; pending actions will resume after the interruption")
    end
    return unpack(results, 2)
end

local function resumeAfterInterruption()
    for player, job in pairs(jobsByPlayer) do
        if job.pendingResume then
            if not player or player:isDead() then
                jobsByPlayer[player] = nil
            elseif not (player.isAttacking and player:isAttacking()) then
                local queue = ISTimedActionQueue.getTimedActionQueue(player)
                if queue and queue.queue and #queue.queue == 0 then
                    local actions = job.pendingActions or {}
                    local dryingIsMoving = false
                    if isPlayerMoving(player) then
                        for _, action in ipairs(actions) do
                            if action.chilaSedaResumeDryingJob == job then
                                dryingIsMoving = true
                                break
                            end
                        end
                    end
                    if not dryingIsMoving then
                        job.pendingActions = nil
                        job.pendingResume = false
                        local resumedCount = 0
                        for _, action in ipairs(actions) do
                            if action.chilaSedaResumeDryingJob ~= job
                                    or dryingActionIsValid(action) then
                                if action.chilaSedaResumeDryingJob == job
                                        and type(action.chilaSedaResumeBaseMaxTime) == "number" then
                                    action.maxTime = action.chilaSedaResumeBaseMaxTime
                                end
                                originalQueueAdd(action)
                                local delta = action.chilaSedaResumeDelta
                                if action.chilaSedaResumeDryingJob == job
                                        and type(delta) == "number"
                                        and type(action.setJobDelta) == "function" then
                                    pcall(action.setJobDelta, action, delta)
                                    action.chilaSedaResumeDelta = nil
                                end
                                resumedCount = resumedCount + 1
                            else
                                print(TAG .. "drying action became invalid before resume; not re-queued")
                            end
                        end
                        print(TAG .. "resumed " .. tostring(resumedCount) .. " pending actions")
                    end
                end
            end
        else
            local queue = player and ISTimedActionQueue.getTimedActionQueue(player)
            if not queue or not queue.queue or #queue.queue == 0 then
                jobsByPlayer[player] = nil
            end
        end
    end
end

local function cancelOnEscape(key)
    if key ~= Keyboard.KEY_ESCAPE then return end
    local player = getSpecificPlayer(0)
    if player then
        local job = jobsByPlayer[player]
        if job then job.cancelled = true end
        jobsByPlayer[player] = nil
    end
end

Events.OnTick.Add(resumeAfterInterruption)
Events.OnKeyStartPressed.Add(cancelOnEscape)
print(TAG .. "installed for inventory dismantling, rip clothing, and drying")
