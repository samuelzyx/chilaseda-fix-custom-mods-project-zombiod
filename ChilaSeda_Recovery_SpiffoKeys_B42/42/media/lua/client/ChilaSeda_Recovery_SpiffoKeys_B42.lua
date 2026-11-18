local MOD_ID = "ChilaSeda_Recovery_SpiffoKeys_B42"
local RECOVERY_FLAG = MOD_ID .. "_recovered"
local TARGETS_KEY = MOD_ID .. "_targets"
local LOG_NAME = "ChilaSeda_SpiffoKeyRecovery.log"
local MIN_FUEL_AMOUNT = 0.1
local KEY_COPIES_PER_VAN = 5
local SEARCH_RADIUS_SQ = 40 * 40
local SNAPSHOT_TICKS = 300
local SCAN_TICKS = 60

local Recovery = {
    tick = 0,
    lastSnapshot = {},
    lastScanState = nil,
    completed = {},
}

local function safeText(value)
    if value == nil then return "nil" end
    local ok, result = pcall(tostring, value)
    if not ok then return "unavailable" end
    return result:gsub("[\r\n\t|;]", "_")
end

local function log(message)
    local line = os.date("%Y-%m-%d %H:%M:%S") .. " | " .. message
    print("[" .. MOD_ID .. "] " .. message)
    local ok, err = pcall(function()
        local writer = getFileWriter(LOG_NAME, true, true)
        if not writer then error("getFileWriter returned nil") end
        writer:write(line .. "\n")
        writer:close()
    end)
    if not ok then print("[" .. MOD_ID .. "] LOG_WRITE_FAILED " .. safeText(err)) end
end

local function callMethod(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local args = { ... }
    local ok, result = pcall(function()
        return object[method](object, unpack(args))
    end)
    if ok then return result end
    return nil
end

local function countMatchingKeys(container, keyId, depth, visited)
    if not container or depth > 6 or visited[container] then return 0 end
    visited[container] = true

    local items = callMethod(container, "getItems")
    local size = tonumber(callMethod(items, "size")) or 0
    local count = 0
    for index = 0, size - 1 do
        local item = callMethod(items, "get", index)
        if item then
            if tonumber(callMethod(item, "getKeyId")) == tonumber(keyId) then
                count = count + 1
            end
            local nested = callMethod(item, "getInventory") or callMethod(item, "getItemContainer")
            count = count + countMatchingKeys(nested, keyId, depth + 1, visited)
        end
    end
    return count
end

local function getNearbySpiffoVans(player)
    local cell = getCell()
    if not cell then return {}, 0, 0, 0 end
    local vehicles = cell:getVehicles()
    if not vehicles then return {}, 0, 0, 0 end

    local found = {}
    local nearbySpiffoCount = 0
    local emptyFuelCount = 0
    local missingTankCount = 0
    local iterator = vehicles:iterator()
    if not iterator then return {}, 0, 0, 0 end

    local playerX, playerY = player:getX(), player:getY()
    while iterator:hasNext() do
        local vehicle = iterator:next()
        if vehicle and vehicle:getScriptName() == "Base.VanSpiffo" then
            local dx = vehicle:getX() - playerX
            local dy = vehicle:getY() - playerY
            local distanceSq = dx * dx + dy * dy
            if distanceSq <= SEARCH_RADIUS_SQ then
                nearbySpiffoCount = nearbySpiffoCount + 1
                local gasTank = vehicle:getPartById("GasTank")
                local fuelAmount = gasTank and tonumber(gasTank:getContainerContentAmount()) or nil
                if fuelAmount and fuelAmount > MIN_FUEL_AMOUNT then
                    found[#found + 1] = {
                        vehicle = vehicle,
                        distanceSq = distanceSq,
                        fuelAmount = fuelAmount,
                    }
                elseif fuelAmount == nil then
                    missingTankCount = missingTankCount + 1
                else
                    emptyFuelCount = emptyFuelCount + 1
                end
            end
        end
    end

    table.sort(found, function(a, b) return a.distanceSq < b.distanceSq end)
    return found, nearbySpiffoCount, emptyFuelCount, missingTankCount
end

local function vehicleLabel(vehicle, fuelAmount)
    return "vehicle=" .. safeText(vehicle:getId())
        .. " keyId=" .. safeText(vehicle:getKeyId())
        .. " script=" .. safeText(vehicle:getScriptName())
        .. " xy=" .. safeText(math.floor(vehicle:getX())) .. "," .. safeText(math.floor(vehicle:getY()))
        .. " fuel=" .. safeText(fuelAmount)
end

local function recoverKeys(player, nearby)
    local inventory = player:getInventory()
    local targetIds = {}
    local recoveredCount = 0

    for _, entry in ipairs(nearby) do
        local vehicle = entry.vehicle
        local vehicleId = safeText(vehicle:getId())
        if not Recovery.completed[vehicleId] then
            local keyId = vehicle:getKeyId()
            if not keyId or keyId < 0 then
                log("RECOVERY_WAIT invalid_key_id " .. vehicleLabel(vehicle, entry.fuelAmount))
                return false
            end

            local copies = countMatchingKeys(inventory, keyId, 0, {})
            local copiesAdded = 0
            while copies < KEY_COPIES_PER_VAN do
                local key = instanceItem("Base.CarKey")
                if not key then
                    log("RECOVERY_FAILED create_car_key " .. vehicleLabel(vehicle, entry.fuelAmount))
                    return false
                end
                key:setKeyId(keyId)
                local added = inventory:AddItem(key)
                if not added then
                    log("RECOVERY_FAILED add_car_key " .. vehicleLabel(vehicle, entry.fuelAmount))
                    return false
                end
                local updatedCopies = countMatchingKeys(inventory, keyId, 0, {})
                if updatedCopies <= copies then
                    log("RECOVERY_FAILED verify_car_key " .. vehicleLabel(vehicle, entry.fuelAmount))
                    return false
                end
                copiesAdded = copiesAdded + (updatedCopies - copies)
                copies = updatedCopies
            end

            Recovery.completed[vehicleId] = true
            targetIds[#targetIds + 1] = keyId
            recoveredCount = recoveredCount + 1
            log((copiesAdded > 0 and "RECOVERED_COPIES" or "RECOVERY_PRESENT")
                .. " copies_added=" .. safeText(copiesAdded)
                .. " copies_total=" .. safeText(copies)
                .. " " .. vehicleLabel(vehicle, entry.fuelAmount)
                .. " ignition=" .. safeText(vehicle:isKeysInIgnition()))
        end
    end

    if recoveredCount > 0 then
        local data = player:getModData()
        local savedTargets = data[TARGETS_KEY]
        if type(savedTargets) ~= "table" then savedTargets = {} end
        local savedSet = {}
        for _, savedKeyId in ipairs(savedTargets) do
            savedSet[tostring(savedKeyId)] = true
        end
        for _, keyId in ipairs(targetIds) do
            if not savedSet[tostring(keyId)] then
                savedTargets[#savedTargets + 1] = keyId
                savedSet[tostring(keyId)] = true
            end
        end
        data[TARGETS_KEY] = savedTargets
        data[RECOVERY_FLAG] = true
        log("RECOVERY_COMPLETE newly_processed=" .. safeText(recoveredCount))
        return true
    end
    return false
end

local function readDiagnosticState(player, vehicle)
    local keyId = vehicle:getKeyId()
    local inventoryCopies = countMatchingKeys(player:getInventory(), keyId, 0, {})
    local ignition = vehicle:isKeysInIgnition() == true
    local door = vehicle:isKeyIsOnDoor() == true
    return table.concat({ tostring(inventoryCopies), tostring(ignition), tostring(door) }, ",")
end

local function monitor(player, nearby)
    for _, entry in ipairs(nearby) do
        local vehicle = entry.vehicle
        local label = vehicleLabel(vehicle, entry.fuelAmount)
        local state = readDiagnosticState(player, vehicle)
        local key = safeText(vehicle:getId())
        if Recovery.lastSnapshot[key] ~= state then
            log("KEY_STATE " .. label .. " inventory_copies,ignition,key_on_door=" .. state)
            Recovery.lastSnapshot[key] = state
        end
    end
end

local function onTick()
    Recovery.tick = Recovery.tick + 1
    if Recovery.tick ~= 1 and Recovery.tick % SCAN_TICKS ~= 0 then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    local nearby, spiffoCount, emptyFuelCount, missingTankCount = getNearbySpiffoVans(player)
    local eligibleDetails = {}
    for _, entry in ipairs(nearby) do
        local vehicleId = safeText(entry.vehicle:getId())
        local fuel = math.floor(entry.fuelAmount * 10 + 0.5) / 10
        eligibleDetails[#eligibleDetails + 1] = vehicleId .. "=" .. safeText(fuel)
    end
    local scanState = table.concat({
        safeText(spiffoCount), safeText(#nearby), safeText(emptyFuelCount), safeText(missingTankCount),
        table.concat(eligibleDetails, ","),
    }, "/")
    if Recovery.lastScanState ~= scanState then
        Recovery.lastScanState = scanState
        log("SCAN radius_tiles=40 nearby_spiffo=" .. safeText(spiffoCount)
            .. " fuelled=" .. safeText(#nearby) .. " excluded_empty=" .. safeText(emptyFuelCount)
            .. " missing_tank=" .. safeText(missingTankCount) .. " eligible=" .. table.concat(eligibleDetails, ","))
    end

    local recovered = recoverKeys(player, nearby)
    if recovered or Recovery.tick % SNAPSHOT_TICKS == 0 then
        monitor(player, nearby)
    end
end

Events.OnTick.Add(onTick)
log("LOADED recovery=fuelled_spiffo_vans radius_tiles=40 min_fuel=" .. MIN_FUEL_AMOUNT
    .. " copies_per_van=" .. KEY_COPIES_PER_VAN .. " scan_ticks=" .. SCAN_TICKS
    .. " snapshot_ticks=" .. SNAPSHOT_TICKS)