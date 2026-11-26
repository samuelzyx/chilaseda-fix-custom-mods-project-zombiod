-- Keep vehicle entry available from Viewpoint's native interaction menu when
-- vanilla points getUseablePart at a hood/mechanics part instead of a door.
local TRACE_LIMIT = 32
local traceCount = 0
local hooked = false

local function trace(message)
    if traceCount >= TRACE_LIMIT then return end
    traceCount = traceCount + 1
    print("[ChilaSedaViewpointVehicleEntry] " .. tostring(message))
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return false, nil end
    local ok, value = pcall(fn, object, ...)
    return ok, value
end

local function seatFor(player, vehicle, part)
    if part then
        local okDoor, door = call(part, "getDoor")
        local okItem, item = call(part, "getInventoryItem")
        if okDoor and door and okItem and item then
            local okMax, maxPassengers = call(vehicle, "getMaxPassengers")
            if okMax and maxPassengers then
                for seat = 0, maxPassengers - 1 do
                    local okFirst, first = call(vehicle, "getPassengerDoor", seat)
                    local okSecond, second = call(vehicle, "getPassengerDoor2", seat)
                    if okFirst and first == part or okSecond and second == part then
                        return seat, "usable-door"
                    end
                end
            end
        end
    end

    local okSeat, seat = call(vehicle, "getBestSeat", player)
    if okSeat and type(seat) == "number" and seat >= 0 then
        return seat, part and "best-seat-fallback" or "best-seat"
    end
    return -1, part and "non-door-no-seat" or "no-seat"
end

local function getGITDCPlan(player, vehicle)
    local ok, selector = pcall(require, "GetInTheDamnCar/GITDC_VehicleSelector")
    if not ok or type(selector) ~= "table" or type(selector.find) ~= "function" then
        return nil, "selector-unavailable"
    end
    local planOk, plan, reason = pcall(selector.find, player)
    if not planOk then return nil, "selector-error:" .. tostring(plan) end
    if not plan or plan.vehicle ~= vehicle then return nil, reason or "other-or-no-vehicle" end
    return plan, "approach-plan"
end

local function runApproach(player, vehicle, plan)
    if not player or not vehicle or not plan then return end
    local deadOk, dead = call(player, "isDead")
    if deadOk and dead then return end
    local inVehicleOk, inVehicle = call(player, "getVehicle")
    if inVehicleOk and inVehicle then return end
    local blockedOk, blocked = call(player, "isBlockMovement")
    if blockedOk and blocked then return end
    if ISTimedActionQueue.isPlayerDoingAction(player) then return end

    if plan.targetHasItems and not ISVehicleMenu.moveItemsFromSeat(
            player, vehicle, plan.targetSeat, true, false) then
        trace("event=select result=seat-items-blocked")
        return
    end

    local queue = ISTimedActionQueue.getTimedActionQueue(player)
    local existing = {}
    for _, action in ipairs(queue.queue) do existing[action] = true end

    local amcPart = vehicle:getPartById("AMCConfig")
    local amcInfo = amcPart and amcPart:getTable("AMCConfig")
    if not plan.secondary and amcInfo and amcInfo.noDoor
            and vehicle:getPassengerDoor(plan.entrySeat) then
        ISTimedActionQueue.add(ISPathFindAction:pathToVehicleSeat(
            player, vehicle, plan.entrySeat))
    end

    if plan.secondary then
        ISVehicleMenu.onEnterAux2(player, vehicle, plan.entrySeat)
    else
        ISVehicleMenu.onEnterAux(player, vehicle, plan.entrySeat)
    end
    if plan.entrySeat ~= plan.targetSeat then
        ISTimedActionQueue.add(ISSwitchVehicleSeat:new(
            player, plan.targetSeat, plan.entrySeat))
    end

    local approach = require("GetInTheDamnCar/GITDC_Approach")
    local token = { approachComplete = true }
    local approachActions = {}
    for _, action in ipairs(queue.queue) do
        if not existing[action] and action.goal
                and action.goal[1] == "VehicleSeat"
                and action.goal[2] == vehicle
                and action.goal[3] == plan.entrySeat then
            approachActions[action] = true
            token = approach.prepare(action, vehicle, plan.entrySeat, token, nil)
        end
    end
    for _, action in ipairs(queue.queue) do
        if not existing[action] and not approachActions[action] then
            approach.guard(action, vehicle, plan.entrySeat, token)
        end
    end
    trace("event=select result=approach-queued entrySeat=" .. tostring(plan.entrySeat)
        .. " targetSeat=" .. tostring(plan.targetSeat))
end

local function selectEntry(player, vehicle, seat, plan)
    if seat >= 0 then
        trace("event=select result=vanilla-enter seat=" .. tostring(seat))
        return ISVehicleMenu.onEnter(player, vehicle, seat)
    end
    if plan then return runApproach(player, vehicle, plan) end
    trace("event=select result=no-safe-entry")
end

local function syncResult(result, actions, previousActions, previousResult)
    if type(result) ~= "table" then return end
    local previousIndex = {}
    for i, action in ipairs(previousActions or {}) do previousIndex[action] = i end
    result.labels, result.enabled, result.deliberate = {}, {}, {}
    result.tips, result.icons = {}, {}
    for i, action in ipairs(actions) do
        local old = previousIndex[action]
        result.labels[i] = action.name
        result.enabled[i] = action.enabled ~= false
        result.deliberate[i] = action.deliberate == true
        result.tips[i] = old and previousResult.tips and previousResult.tips[old] or nil
        result.icons[i] = old and previousResult.icons and previousResult.icons[old]
                or ViewpointInteractIcons.of(action, ViewpointInteract.target
                    and ViewpointInteract.target.vehicle)
    end
end

local function install()
    if hooked or not (ViewpointInteract and ViewpointInteract.harvestVehicle
            and ViewpointInteractOrder and ISVehicleMenu) then return false end
    local original = ViewpointInteract.harvestVehicle
    ViewpointInteract.harvestVehicle = function(player, vehicle, ...)
        local result = original(player, vehicle, ...)
        local actions = ViewpointInteract.actions
        if type(actions) ~= "table" then return result end
        local previousActions = {}
        for i, action in ipairs(actions) do previousActions[i] = action end
        local previousResult = {
            tips = result and result.tips,
            icons = result and result.icons,
        }

        local partOk, part = call(vehicle, "getUseablePart", player)
        if not partOk then part = nil end
        local seat, seatReason = seatFor(player, vehicle, part)
        local plan, planReason
        if seat < 0 then plan, planReason = getGITDCPlan(player, vehicle) end
        local entryIndex
        for i, action in ipairs(actions) do
            if action.fn == ISVehicleMenu.onEnter then entryIndex = i; break end
        end

        if entryIndex then
            local entry = table.remove(actions, entryIndex)
            entry.first, entry.rank = true, 0
            table.insert(actions, 1, entry)
        elseif seat >= 0 or plan then
            local label = getText("IGUI_EnterVehicle")
            local okDoor, door = call(part, "getDoor")
            if okDoor and door then
                local lockedOk, locked = call(door, "isLocked")
                if lockedOk and locked then label = label .. " [" .. getText("EC_Locked") .. "]" end
            end
            table.insert(actions, 1, {
                name = label,
                fn = selectEntry,
                args = { player, vehicle, seat, plan },
                n = 4,
                enabled = true,
                first = true,
                rank = 0,
                icon = getTexture("media/ui/vehicles/vehicle_changeseats.png"),
            })
        end

        syncResult(result, actions, previousActions, previousResult)
        local okPartId, partId = call(part, "getId")
        trace("event=menu seat=" .. tostring(seat) .. " seatReason=" .. seatReason
            .. " part=" .. tostring(okPartId and partId or "nil")
            .. " plan=" .. tostring(planReason or "not-needed")
            .. " entryFirst=" .. tostring(actions[1] and actions[1].fn == ISVehicleMenu.onEnter
                or actions[1] and actions[1].fn == selectEntry))
        return result
    end
    hooked = true
    trace("event=hook result=installed")
    return true
end

if not install() and Events and Events.OnGameStart then
    Events.OnGameStart.Add(install)
end
