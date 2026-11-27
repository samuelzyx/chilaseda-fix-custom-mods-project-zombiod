require "TimedActions/ISTakeWaterAction"

local TAG = "[ChilaSeda_WaterFillCompletionGuard] "
local MAX_TRACE_LINES = 24
local traceLines = 0

if TRACE_WATER_FILL_COMPLETION_GUARD == nil then
    TRACE_WATER_FILL_COMPLETION_GUARD = true
end

local function trace(message)
    if TRACE_WATER_FILL_COMPLETION_GUARD ~= true or traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    print(TAG .. message)
end

local function traceOnce(action, event, reason, result, detail)
    local key = "_ChilaSedaWaterFillTrace_" .. event .. "_" .. reason
    if action and action[key] then return end
    if action then action[key] = true end
    trace("event=" .. event .. " result=" .. result .. " reason=" .. reason
        .. (detail and " " .. detail or ""))
end

local function containerExists(action)
    if not action or not action.item then return false end
    local ok, container = pcall(function() return action.item:getContainer() end)
    return ok and container ~= nil
end

local function currentFillAmount(action)
    if not action or not action.item then return nil end
    local okContainer, fluidContainer = pcall(function()
        return action.item:getFluidContainer()
    end)
    if not okContainer or not fluidContainer then return nil end
    local okAmount, amount = pcall(function() return fluidContainer:getAmount() end)
    if not okAmount or type(amount) ~= "number" then return nil end
    return amount
end

local function reservedFillTarget(action)
    if not action or type(action.startUsedAmount) ~= "number"
            or type(action.waterUnit) ~= "number" or type(action.endUsedAmount) ~= "number"
            or action.waterUnit <= 0 then
        return nil
    end
    return math.min(action.startUsedAmount + action.waterUnit, action.endUsedAmount)
end

local function characterIsFull(action)
    if not action or not action.character then return false end
    local ok, full = pcall(function() return action.character:hasFullInventory() end)
    return ok and full == true
end

local function sourceHasFluid(action)
    if not action or not action.waterObject then return false end
    local ok, hasFluid = pcall(function() return action.waterObject:hasFluid() end)
    return ok and hasFluid == true
end

local function installGuard()
    local actionClass = ISTakeWaterAction
    if type(actionClass) ~= "table" then
        trace("event=install result=fallback reason=class-unavailable")
        return
    end
    if actionClass.ChilaSedaWaterFillCompletionGuard then
        trace("event=install result=kept reason=already-installed")
        return
    end

    local originalStart = actionClass.start
    local originalIsValid = actionClass.isValid
    local originalComplete = actionClass.complete
    if type(originalStart) ~= "function" or type(originalIsValid) ~= "function"
            or type(originalComplete) ~= "function" then
        trace("event=install result=fallback reason=vanilla-method-unavailable")
        return
    end

    actionClass.start = function(action, ...)
        local result = originalStart(action, ...)
        if action and action.item and type(action.waterUnit) == "number"
                and action.waterUnit > 0 then
            action._ChilaSedaWaterFillStarted = true
            local target = reservedFillTarget(action)
            traceOnce(action, "start", "reserved-fill", "started",
                "planned=" .. tostring(action.waterUnit)
                    .. " target=" .. tostring(target))
        end
        return result
    end

    actionClass.isValid = function(action, ...)
        local valid = originalIsValid(action, ...)
        if valid then return valid end

        if not action or action._ChilaSedaWaterFillStarted ~= true or not action.item then
            traceOnce(action, "isValid", "not-started-fill", "fallback")
            return false
        end
        if not containerExists(action) then
            traceOnce(action, "isValid", "item-container-missing", "fallback")
            return false
        end

        local target = reservedFillTarget(action)
        local current = currentFillAmount(action)
        if target == nil or current == nil then
            traceOnce(action, "isValid", "fill-state-unavailable", "fallback")
            return false
        end

        local epsilon = 0.0001
        if current + epsilon >= target then
            traceOnce(action, "isValid", "reserved-volume-reached", "allow",
                "amount=" .. tostring(current) .. " target=" .. tostring(target))
            return true
        end

        if characterIsFull(action) and sourceHasFluid(action)
                and current > action.startUsedAmount + epsilon then
            traceOnce(action, "isValid", "inventory-full-after-transfer", "allow",
                "amount=" .. tostring(current) .. " target=" .. tostring(target))
            return true
        end

        local reason = not sourceHasFluid(action) and "source-empty-before-target"
            or "vanilla-invalid-condition"
        traceOnce(action, "isValid", reason, "fallback",
            "amount=" .. tostring(current) .. " target=" .. tostring(target))
        return false
    end

    actionClass.complete = function(action, ...)
        local result = originalComplete(action, ...)
        if action and action._ChilaSedaWaterFillStarted then
            traceOnce(action, "complete", "vanilla-complete", tostring(result),
                "amount=" .. tostring(currentFillAmount(action)))
        end
        return result
    end

    actionClass.ChilaSedaWaterFillCompletionGuard = true
    trace("event=install result=installed method=ISTakeWaterAction.isValid")
end

installGuard()
