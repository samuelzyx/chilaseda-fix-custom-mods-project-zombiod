if ChilaSedaModMemoryAudit and ChilaSedaModMemoryAudit.started then return end

local okManifest, manifest = pcall(require, "ChilaSeda_ModMemoryAuditManifest_B42")
if not okManifest or type(manifest) ~= "table" then
    manifest = { generated_utc = "UNAVAILABLE", mods = {}, vehicle_owners = {} }
end

local Audit = {
    started = false,
    elapsedMs = 0,
    startMs = 0,
    lastTickMs = 0,
    sampleEveryMs = 10000,
    heapWindowEveryMs = 75000,
    lastHeapWindowMs = 0,
    warned = false,
    sessionId = "",
    loadChunkTotal = 0,
    loadChunkPending = 0,
    lastVehicleCounts = {},
    seenVehicleScripts = {},
}
ChilaSedaModMemoryAudit = Audit

local LOG_NAME = "ChilaSeda_ModMemoryAudit.log"

local function safeText(value)
    if value == nil then return "UNAVAILABLE" end
    local ok, result = pcall(tostring, value)
    if not ok or type(result) ~= "string" then return "UNAVAILABLE" end
    return result:gsub("[\r\n\t|;]", "_")
end

local function call(object, method, ...)
    if object == nil then return nil end
    local args = {...}
    local ok, result = pcall(function() return object[method](object, unpack(args)) end)
    if ok then return result end
    return nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and value then return tonumber(value) or 0 end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and value then return tonumber(value) or 0 end
    end
    return 0
end

local function utcNow()
    local ok, value = pcall(function() return os.date("!%Y-%m-%dT%H:%M:%SZ") end)
    if ok and value then return value end
    return safeText(os.time())
end

local function appendLines(lines)
    local ok, err = pcall(function()
        local writer = getFileWriter(LOG_NAME, true, true)
        if not writer then error("getFileWriter returned nil") end
        for i = 1, #lines do writer:write(lines[i] .. "\n") end
        writer:close()
    end)
    if not ok then
        print("[ModMemoryAudit] LOG_WRITE_FAILED " .. safeText(err))
    end
end

local function activeModIds()
    local result = {}
    local ok, list = pcall(getActivatedMods)
    if not ok or list == nil then return result end
    local size = tonumber(call(list, "size")) or 0
    for i = 0, size - 1 do
        local id = call(list, "get", i)
        if id ~= nil then result[#result + 1] = safeText(id) end
    end
    return result
end

local function inventoryLines(ids)
    local lines = { "MANIFEST generated_utc=" .. safeText(manifest.generated_utc) .. " active_mod_count=" .. #ids }
    local missing = 0
    for i = 1, #ids do
        local id = ids[i]
        local data = manifest.mods and manifest.mods[id]
        local info = nil
        if type(getModInfoByID) == "function" then
            local ok, result = pcall(getModInfoByID, id)
            if ok then info = result end
        end
        local name = safeText(call(info, "getName"))
        local workshop = safeText(call(info, "getWorkshopID"))
        if data then
            lines[#lines + 1] = table.concat({
                "MOD_ASSETS", "id=" .. id, "name=" .. name, "workshop=" .. workshop,
                "media_files=" .. safeText(data.media_files),
                "media_bytes=" .. safeText(data.media_bytes),
                "texture_files=" .. safeText(data.texture_files),
                "texture_bytes=" .. safeText(data.texture_bytes),
                "png_rgba_est_bytes=" .. safeText(data.png_rgba_est_bytes),
                "model_files=" .. safeText(data.model_files),
                "model_bytes=" .. safeText(data.model_bytes),
                "lua_bytes=" .. safeText(data.lua_bytes),
                "script_bytes=" .. safeText(data.script_bytes),
            }, " ")
        else
            missing = missing + 1
            lines[#lines + 1] = "MOD_ASSETS id=" .. id .. " name=" .. name .. " workshop=" .. workshop .. " inventory=UNAVAILABLE"
        end
    end
    lines[#lines + 1] = "MANIFEST missing_mods=" .. missing .. " vehicle_script_map=" .. tostring(manifest.vehicle_owners ~= nil)
    return lines
end

local function vehicleCounts()
    local byMod, byScript, newScripts = {}, {}, {}
    local total, attributed, unmapped = 0, 0, 0
    local ok, vehicles = pcall(function() return getCell():getVehicles() end)
    if not ok or vehicles == nil then return "UNAVAILABLE", 0, 0, 0 end
    local size = tonumber(call(vehicles, "size")) or 0
    total = size
    -- IsoCell.getVehicles() returns a Java Set, not a List; iterate its Set iterator.
    local iterator = call(vehicles, "iterator")
    if iterator == nil then return "UNAVAILABLE", total, 0, 0 end
    while call(iterator, "hasNext") do
        local vehicle = call(iterator, "next")
        if vehicle == nil then break end
        local scriptName = safeText(call(vehicle, "getScriptName"))
        local owner = manifest.vehicle_owners and manifest.vehicle_owners[scriptName]
        if not Audit.seenVehicleScripts[scriptName] then
            Audit.seenVehicleScripts[scriptName] = true
            newScripts[#newScripts + 1] = { script=scriptName, owner=(owner and owner ~= "AMBIGUOUS") and owner or "UNMAPPED" }
        end
        if owner and owner ~= "AMBIGUOUS" then
            byMod[owner] = (byMod[owner] or 0) + 1
            attributed = attributed + 1
        else
            byScript[scriptName] = (byScript[scriptName] or 0) + 1
            unmapped = unmapped + 1
        end
    end
    local entries = {}
    for id, count in pairs(byMod) do entries[#entries + 1] = id .. "=" .. count end
    table.sort(entries)
    local unknown = {}
    for scriptName, count in pairs(byScript) do unknown[#unknown + 1] = scriptName .. "=" .. count end
    table.sort(unknown)
    while #unknown > 40 do table.remove(unknown) end
    table.sort(newScripts, function(a, b) return a.script < b.script end)
    return table.concat(entries, ";") .. "|unknown:" .. table.concat(unknown, ";"), total, attributed, unmapped, byMod, newScripts
end

local function sample()
    local luaKb = "UNAVAILABLE"
    local ok, value = pcall(collectgarbage, "count")
    if ok and value then luaKb = string.format("%.2f", tonumber(value) or 0) end
    local player = nil
    pcall(function() player = getPlayer() end)
    local pos = "UNAVAILABLE"
    if player then
        pos = safeText(call(player, "getX")) .. "," .. safeText(call(player, "getY")) .. "," .. safeText(call(player, "getZ"))
    end
    local counts, total, attributed, unmapped, byMod, newScripts = vehicleCounts()
    local chunkDelta = Audit.loadChunkPending
    Audit.loadChunkPending = 0
    local lines = { table.concat({
        "SAMPLE", "session=" .. Audit.sessionId, "utc=" .. utcNow(),
        "elapsed_s=" .. math.floor(Audit.elapsedMs / 1000),
        "kahlua_kb=" .. luaKb, "player_xyz=" .. pos,
        "load_chunk_total=" .. Audit.loadChunkTotal, "load_chunks_since_previous=" .. chunkDelta,
        "loaded_cell_vehicles=" .. total,
        "attributed_vehicle_instances=" .. attributed,
        "unmapped_vehicle_instances=" .. unmapped,
        "vehicle_instances_by_mod=" .. counts,
    }, " ") }
    for _, entry in ipairs(newScripts) do
        lines[#lines + 1] = "VEHICLE_SCRIPT_FIRST_SEEN session=" .. Audit.sessionId .. " elapsed_s=" .. math.floor(Audit.elapsedMs / 1000) .. " script=" .. entry.script .. " owner=" .. entry.owner .. " player_xyz=" .. pos
    end
    local ownerIds = {}
    for id in pairs(Audit.lastVehicleCounts) do ownerIds[id] = true end
    for id in pairs(byMod) do ownerIds[id] = true end
    local sortedOwners = {}
    for id in pairs(ownerIds) do sortedOwners[#sortedOwners + 1] = id end
    table.sort(sortedOwners)
    for _, id in ipairs(sortedOwners) do
        local before = Audit.lastVehicleCounts[id] or 0
        local after = byMod[id] or 0
        if before ~= after then
            lines[#lines + 1] = "VEHICLE_COUNT_CHANGE session=" .. Audit.sessionId .. " elapsed_s=" .. math.floor(Audit.elapsedMs / 1000) .. " mod=" .. id .. " before=" .. before .. " after=" .. after .. " delta=" .. (after - before)
        end
    end
    local vehicleIncrease = 0
    for id, after in pairs(byMod) do
        local increase = after - (Audit.lastVehicleCounts[id] or 0)
        if increase > 0 then vehicleIncrease = vehicleIncrease + increase end
    end
    lines[#lines + 1] = "LOAD_DELTA session=" .. Audit.sessionId .. " elapsed_s=" .. math.floor(Audit.elapsedMs / 1000) .. " chunks=" .. chunkDelta .. " vehicle_instances=" .. vehicleIncrease
    Audit.lastVehicleCounts = byMod
    appendLines(lines)
    return chunkDelta, vehicleIncrease
end

local function requestHeapWindow(reason)
    local now = nowMs()
    if now - Audit.lastHeapWindowMs < 70000 then return false end
    Audit.lastHeapWindowMs = now
    local bridge = rawget(_G, "ChilaPerfJ")
    if type(bridge) ~= "table" or type(bridge.selftest) ~= "function" then
        appendLines({ "JAVA_HEAP_WINDOW_REQUEST session=" .. Audit.sessionId .. " elapsed_s=" .. math.floor(Audit.elapsedMs / 1000) .. " utc=" .. utcNow() .. " reason=" .. reason .. " result=UNAVAILABLE:no_java_bridge" })
        return false
    end
    local ok, result = pcall(function() return bridge.selftest() end)
    appendLines({ "JAVA_HEAP_WINDOW_REQUEST session=" .. Audit.sessionId .. " elapsed_s=" .. math.floor(Audit.elapsedMs / 1000) .. " utc=" .. utcNow() .. " reason=" .. reason .. " result=" .. safeText(ok and result or "UNAVAILABLE") .. " detail=ChilaPerformance.log" })
    return ok
end

local function beginSession()
    if Audit.started then return end
    Audit.started = true
    local startMs = nowMs()
    Audit.startMs = startMs
    Audit.lastTickMs = startMs
    Audit.elapsedMs = 0
    Audit.lastHeapWindowMs = startMs
    Audit.sessionId = tostring(os.time()) .. "-" .. tostring(startMs)
    local ids = activeModIds()
    local lines = {
        "SESSION_START session=" .. Audit.sessionId .. " utc=" .. utcNow() ..
            " game_mode=" .. safeText(call(getCore(), "getGameMode")) ..
            " active_mod_count=" .. #ids .. " manifest_utc=" .. safeText(manifest.generated_utc),
        "ACTIVE_MODS session=" .. Audit.sessionId .. " ids=" .. table.concat(ids, ";"),
    }
    local inventory = inventoryLines(ids)
    for i = 1, #inventory do lines[#lines + 1] = inventory[i] end
    appendLines(lines)
    print("[ModMemoryAudit] SESSION_START session=" .. Audit.sessionId .. " mods=" .. #ids .. " manifest=" .. safeText(manifest.generated_utc))
    sample()
end

if Events and Events.LoadChunk then
    Events.LoadChunk.Add(function(...)
        Audit.loadChunkTotal = Audit.loadChunkTotal + 1
        Audit.loadChunkPending = Audit.loadChunkPending + 1
    end)
end

local function tick()
    if not Audit.started then return end
    local now = nowMs()
    if now <= 0 then return end
    local previous = Audit.lastTickMs
    Audit.lastTickMs = now
    local delta = now - previous
    if delta < 0 or delta > 5000 then delta = 0 end
    Audit.elapsedMs = now - Audit.startMs
    Audit.accumulatedSampleMs = (Audit.accumulatedSampleMs or 0) + delta
    Audit.accumulatedHeapMs = (Audit.accumulatedHeapMs or 0) + delta
    if Audit.accumulatedSampleMs >= Audit.sampleEveryMs then
        Audit.accumulatedSampleMs = 0
        local chunks, vehicles = sample()
        if chunks >= 10 then
            requestHeapWindow("chunk_burst")
        elseif vehicles >= 5 then
            requestHeapWindow("vehicle_burst")
        end
    end
    if Audit.accumulatedHeapMs >= Audit.heapWindowEveryMs then
        Audit.accumulatedHeapMs = 0
        requestHeapWindow("periodic")
    end
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(beginSession) end
if Events and Events.OnTick then Events.OnTick.Add(tick) end
print("[ModMemoryAudit] LOADED v0.1.1; log-only 10s samples, chunk/vehicle changes, and 75s Java-heap windows")
