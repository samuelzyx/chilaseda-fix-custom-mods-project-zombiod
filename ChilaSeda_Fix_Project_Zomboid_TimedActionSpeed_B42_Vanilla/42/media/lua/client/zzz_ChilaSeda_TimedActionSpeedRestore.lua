require "TimedActions/ISTimedActionQueue"

local queue = ISTimedActionQueue
local observedQueueSpeedReset = false

local function clearOptionalFastForwardState()
    local viewpointQOL = rawget(_G, "ProjectViewpointQOL")
    if type(viewpointQOL) == "table" then
        viewpointQOL.desiredFastForwardSpeed = nil
        viewpointQOL.desiredFastForwardMultiplier = nil
        if type(viewpointQOL.clearSpeedKeeper) == "function" then
            pcall(viewpointQOL.clearSpeedKeeper)
        end
    end

    local speedKeeper = rawget(_G, "ViewpointQOLSpeed")
    if type(speedKeeper) == "table" then
        if type(speedKeeper.setUserSpeed) == "function" then
            pcall(speedKeeper.setUserSpeed, 1, 1)
        end
        if type(speedKeeper.reset) == "function" then
            pcall(speedKeeper.reset)
        end
    end
end

local function restoreNormalSpeed()
    local core = getCore and getCore()
    if core and core.getOptionTimedActionGameSpeedReset
            and not core:getOptionTimedActionGameSpeedReset() then
        return
    end

    local controls = UIManager and UIManager.getSpeedControls
            and UIManager.getSpeedControls()
    local gameTime = getGameTime and getGameTime()
    local selectedSpeed = controls and controls.getCurrentGameSpeed
            and controls:getCurrentGameSpeed()
    local gameSpeed = getGameSpeed and getGameSpeed()
    local multiplier = gameTime and gameTime.getTrueMultiplier
            and gameTime:getTrueMultiplier()

    local needsRestore = (selectedSpeed and selectedSpeed > 1)
            or (gameSpeed and gameSpeed > 1)
            or (multiplier and multiplier > 1)

    if needsRestore and controls and controls.SetCurrentGameSpeed then
        controls:SetCurrentGameSpeed(1)
    end
    if needsRestore and gameSpeed and gameSpeed > 1 and setGameSpeed then
        setGameSpeed(1)
    end
    if needsRestore and gameTime and gameTime.setMultiplier then
        gameTime:setMultiplier(1)
    end

    -- Vanilla may have already selected x1. Clear any optional cached override
    -- anyway, or its speed keeper can leave the character in a stale fast state.
    clearOptionalFastForwardState()

    if needsRestore then
        print("[ChilaSeda_TimedActionSpeedRestore] reset speed after action queue")
    end
end

local function onTick()
    if not queue then
        return
    end

    if queue.shouldResetGameSpeed then
        observedQueueSpeedReset = true
        return
    end

    if observedQueueSpeedReset then
        observedQueueSpeedReset = false
        restoreNormalSpeed()
    end
end

Events.OnTick.Add(onTick)
