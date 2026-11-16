local MOD_ID = "ChilaSeda_Recovery_SpiffoKeys_B42"
local RECOVERY_FLAG = MOD_ID .. "_recovered"
local TARGETS_KEY = MOD_ID .. "_targets"
local LOG_NAME = "ChilaSeda_SpiffoKeyRecovery.log"
local TARGET_COUNT = 2
local KEY_COPIES_PER_VAN = 5
local SEARCH_RADIUS_SQ = 40 * 40
local SNAPSHOT_TICKS = 300

local Recovery = {
    tick = 0,
    lastSnapshot = {},
    targets = {},
    finished = false,
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
    if not cell then return {} end
    local vehicles = cell:getVehicles()
    if not vehicles then return {} end

    local found = {}
    local playerX, playerY = player:getX(), player:getY()
    for index = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(index)
        if vehicle and vehicle:getScriptName() == "Base.VanSpiffo" then
            local dx = vehicle:getX() - playerX
            local dy = vehicle:getY() - playerY
            local distanceSq = dx * dx + dy * dy
            if distanceSq <= SEARCH_RADIUS_SQ then
                found[#found + 1] = { vehicle = vehicle, distanceSq = distanceSq }
            end
        end
    end

    table.sort(found, function(a, b) return a.distanceSq < b.distanceSq end)
    while #found > TARGET_COUNT do table.remove(found) end
    return found
end

local function vehicleLabel(vehicle)
    return "vehicle=" .. safeText(vehicle:getId())
        .. " keyId=" .. safeText(vehicle:getKeyId())
        .. " script=" .. safeText(vehicle:getScriptName())
        .. " xy=" .. safeText(math.floor(vehicle:getX())) .. "," .. safeText(math.floor(vehicle:getY()))
end

local function recoverKeys(player, nearby)
    if #nearby < TARGET_COUNT then return false end

    local inventory = player:getInventory()
    local targetIds = {}
    for _, entry in ipairs(nearby) do
        local vehicle = entry.vehicle
        local keyId = vehicle:getKeyId()
        if not keyId or keyId < 0 then
            log("RECOVERY_WAIT invalid_key_id " .. vehicleLabel(vehicle))
            return false
        end

        targetIds[#targetIds + 1] = keyId
        local copies = countMatchingKeys(inventory, keyId, 0, {})
        local copiesAdded = 0
        while copies < KEY_COPIES_PER_VAN do
            local key = instanceItem("Base.CarKey")
            if not key then
                log("RECOVERY_FAILED create_car_key " .. vehicleLabel(vehicle))
                return false
            end
            key:setKeyId(keyId)
            local added = inventory:AddItem(key)
            if not added then
                log("RECOVERY_FAILED add_car_key " .. vehicleLabel(vehicle))
                return false
            end
            local updatedCopies = countMatchingKeys(inventory, keyId, 0, {})
            if updatedCopies <= copies then
                log("RECOVERY_FAILED verify_car_key " .. vehicleLabel(vehicle))
                return false
            end
            copiesAdded = copiesAdded + (updatedCopies - copies)
            copies = updatedCopies
        end
        log((copiesAdded > 0 and "RECOVERED_COPIES" or "RECOVERY_PRESENT")
            .. " copies_added=" .. safeText(copiesAdded)
            .. " copies_total=" .. safeText(copies)
            .. " " .. vehicleLabel(vehicle)
            .. " ignition=" .. safeText(vehicle:isKeysInIgnition()))
    end

    local data = player:getModData()
    data[TARGETS_KEY] = targetIds
    data[RECOVERY_FLAG] = true
    Recovery.targets = nearby
    Recovery.finished = true
    log("RECOVERY_COMPLETE target_count=" .. safeText(#nearby))
    return true
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
        local label = vehicleLabel(vehicle)
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
    if Recovery.finished then
        if Recovery.tick ~= 1 and Recovery.tick % SNAPSHOT_TICKS ~= 0 then return end
    elseif Recovery.tick ~= 1 and Recovery.tick % 60 ~= 0 then
        return
    end

    local player = getSpecificPlayer(0)
    if not player then return end

    local nearby = getNearbySpiffoVans(player)
    if not Recovery.finished then
        local data = player:getModData()
        if data[RECOVERY_FLAG] == true then
            Recovery.finished = true
            Recovery.targets = nearby
            log("RECOVERY_ALREADY_DONE saved_flag=true")
        else
            recoverKeys(player, nearby)
        end
    end

    monitor(player, nearby)
end

Events.OnTick.Add(onTick)
log("LOADED recovery=two_nearest_spiffo_vans radius_tiles=40 copies_per_van="
    .. KEY_COPIES_PER_VAN .. " snapshot_ticks=" .. SNAPSHOT_TICKS)
