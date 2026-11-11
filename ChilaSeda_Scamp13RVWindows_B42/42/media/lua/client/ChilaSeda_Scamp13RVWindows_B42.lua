-- Model-specific, reversible window prototype for KI5's '87 Scamp 13.
-- This is a single-player runtime addon; it does not edit Workshop files or map binaries.

if isMultiplayer() then return end

local MOD_ID = "ChilaSeda_Scamp13RVWindows_B42"
local TARGET_SCRIPT = "Base.Trailer87Scamp13"
local WINDOW_MARKER = "ChilaSeda_Scamp13RVWindows_B42"
-- The 3x2 room slots are spaced 60 tiles apart; 29 tiles covers this slot without
-- reaching the next assigned room.
local CLEAN_MARGIN = 29
local CLEAN_INTERVAL_TICKS = 30

local active = nil
local pending = nil
local tickCount = 0
local missingChunkReported = false

local function log(message)
    print("[" .. MOD_ID .. "] " .. tostring(message))
end

local function scriptName(vehicle)
    if not vehicle then return nil end
    local ok, name = pcall(function()
        return tostring(vehicle:getScript():getFullName())
    end)
    return ok and name or nil
end

local function sameRoom(a, b)
    return a and b and a.x == b.x and a.y == b.y and (a.z or 0) == (b.z or 0)
end

local function squareHasLoadedChunk(square)
    if not square then return false end
    local ok, chunk = pcall(function() return square:getChunk() end)
    if ok and chunk ~= nil then return true end
    if not missingChunkReported then
        missingChunkReported = true
        log("skipped tile-object operation because the square's chunk was unavailable")
    end
    return false
end

local function roomDimensions(typeDef)
    local width = tonumber(typeDef and typeDef.roomWidth) or 3
    local height = tonumber(typeDef and typeDef.roomHeight) or 2
    return math.abs(width), math.abs(height)
end

local function removeObject(square, object)
    if not squareHasLoadedChunk(square) or not object then return end
    pcall(function() square:transmitRemoveItemFromSquare(object) end)
    pcall(function() square:RemoveTileObject(object) end)
    pcall(function() square:RemoveSpecialObject(object) end)
end

local function refreshSquare(square)
    if not squareHasLoadedChunk(square) then return end
    pcall(function() square:RecalcProperties() end)
    pcall(function() square:RecalcWithNeighbours(true) end)
end

local function squareObjects(square)
    local result, seen = {}, {}
    if not squareHasLoadedChunk(square) then return result end
    local lists = {}
    pcall(function() lists[#lists + 1] = square:getObjects() end)
    pcall(function() lists[#lists + 1] = square:getSpecialObjects() end)
    for i = 1, #lists do
        local list = lists[i]
        if list then
            for j = 0, list:size() - 1 do
                local object = list:get(j)
                if object and not seen[object] then
                    seen[object] = true
                    result[#result + 1] = object
                end
            end
        end
    end
    return result
end

local function squareContains(square, wanted)
    local objects = squareObjects(square)
    for i = 1, #objects do
        if objects[i] == wanted then return true end
    end
    return false
end

local function createOriginalWall(square, data)
    if not squareHasLoadedChunk(square) or not data or not data.originalSprite then return nil end
    local sprite = getSprite(data.originalSprite)
    if not sprite then return nil end

    local restored = nil
    if data.originalWasThumpable then
        local ok, object = pcall(function()
            return IsoThumpable.new(getCell(), square, sprite, data.originalNorth == true, {})
        end)
        if ok then restored = object end
    else
        local ok, object = pcall(function()
            return IsoObject.new(getCell(), square, sprite)
        end)
        if ok then restored = object end
    end
    if restored then
        pcall(function() square:AddTileObject(restored) end)
        refreshSquare(square)
    end
    return restored
end

local function restoreOneWindow(square, window, state)
    if not squareHasLoadedChunk(square) or not window then return end
    local data = nil
    pcall(function() data = window:getModData()[WINDOW_MARKER] end)
    if not data then return end

    removeObject(square, window)
    local original = nil
    if state and state.replacements then
        for i = 1, #state.replacements do
            local replacement = state.replacements[i]
            if replacement.x == square:getX() and replacement.y == square:getY()
                and replacement.z == square:getZ() then
                original = replacement.original
                break
            end
        end
    end

    if original then
        if not squareContains(square, original) then
            pcall(function() square:AddTileObject(original) end)
        end
        refreshSquare(square)
    else
        createOriginalWall(square, data)
    end
end

local function restoreTaggedWindows(room, typeDef, state)
    if not room then return 0 end
    local width, height = roomDimensions(typeDef)
    local restored = 0
    local cell = getCell()
    local z = room.z or 0
    for x = room.x - 1, room.x + width + 1 do
        for y = room.y - 1, room.y + height + 1 do
            local square = cell:getGridSquare(x, y, z)
            if squareHasLoadedChunk(square) then
                local objects = squareObjects(square)
                for i = #objects, 1, -1 do
                    local object = objects[i]
                    if object and instanceof(object, "IsoWindow") then
                        local marked = false
                        pcall(function() marked = object:getModData()[WINDOW_MARKER] ~= nil end)
                        if marked then
                            restoreOneWindow(square, object, state)
                            restored = restored + 1
                        end
                    end
                end
            end
        end
    end
    return restored
end

local function removeExteriorZombies(state)
    if not state or not state.room then return 0 end
    local room = state.room
    local width, height = roomDimensions(state.typeDef)
    local z = room.z or 0
    local removed = 0
    local cell = getCell()
    for x = room.x - CLEAN_MARGIN, room.x + width + CLEAN_MARGIN do
        for y = room.y - CLEAN_MARGIN, room.y + height + CLEAN_MARGIN do
            local outside = x < room.x or x > room.x + width
                or y < room.y or y > room.y + height
            if outside then
                local square = cell:getGridSquare(x, y, z)
                if squareHasLoadedChunk(square) then
                    local moving = square:getMovingObjects()
                    for i = moving:size() - 1, 0, -1 do
                        local object = moving:get(i)
                        if object and instanceof(object, "IsoZombie") then
                            pcall(function() object:removeFromSquare() end)
                            pcall(function() object:removeFromWorld() end)
                            removed = removed + 1
                        end
                    end
                end
            end
        end
    end
    return removed
end

local function wallCandidate(square, object)
    if not object or instanceof(object, "IsoDoor") or instanceof(object, "IsoWindow")
        or instanceof(object, "IsoWindowFrame") then
        return nil
    end
    local sprite = object:getSprite()
    if not sprite then return nil end
    local props = sprite:getProperties()
    if not props then return nil end
    local north = props:has(IsoFlagType.WallN)
    local west = props:has(IsoFlagType.WallW)
    if north == west then return nil end

    local isDoor = false
    pcall(function() isDoor = object:isDoor() end)
    local isWindow = false
    pcall(function() isWindow = object:isWindow() end)
    if isDoor or isWindow then return nil end

    local spriteName = sprite:getName()
    if not spriteName or spriteName == "" then return nil end
    return {
        square = square,
        object = object,
        orientation = north and "N" or "W",
        line = north and square:getY() or square:getX(),
        along = north and square:getX() or square:getY(),
        spriteName = tostring(spriteName),
        isThumpable = instanceof(object, "IsoThumpable"),
    }
end

local function collectWallGroups(room, typeDef)
    local width, height = roomDimensions(typeDef)
    local groups = {}
    local cell = getCell()
    local z = room.z or 0
    for x = room.x - 1, room.x + width + 1 do
        for y = room.y - 1, room.y + height + 1 do
            local square = cell:getGridSquare(x, y, z)
            if square then
                -- Project RV interiors can keep generated wall pieces in the
                -- square's special-object collection. Scan both collections,
                -- just as restoration already does, or the wall groups appear
                -- empty and the window layout is silently skipped.
                local objects = squareObjects(square)
                for i = 1, #objects do
                    local candidate = wallCandidate(square, objects[i])
                    if candidate then
                        local key = candidate.orientation .. ":" .. tostring(candidate.line)
                        local group = groups[key]
                        if not group then
                            group = {
                                key = key,
                                orientation = candidate.orientation,
                                line = candidate.line,
                                segments = {},
                                count = 0,
                            }
                            groups[key] = group
                        end
                        -- Keep the topmost matching wall object at this tile.
                        group.segments[candidate.along] = candidate
                    end
                end
            end
        end
    end

    local result = {}
    for _, group in pairs(groups) do
        local minAlong, maxAlong, count = nil, nil, 0
        for along in pairs(group.segments) do
            count = count + 1
            minAlong = (not minAlong or along < minAlong) and along or minAlong
            maxAlong = (not maxAlong or along > maxAlong) and along or maxAlong
        end
        if count >= 2 then
            group.count = count
            group.minAlong = minAlong
            group.maxAlong = maxAlong
            group.extent = maxAlong - minAlong + 1
            result[#result + 1] = group
        end
    end
    table.sort(result, function(a, b)
        if a.extent ~= b.extent then return a.extent > b.extent end
        if a.count ~= b.count then return a.count > b.count end
        if a.orientation ~= b.orientation then return a.orientation < b.orientation end
        return a.line < b.line
    end)
    return result
end

local function closestUnusedSegment(group, fraction, used)
    if not group then return nil end
    local target = group.minAlong + (group.maxAlong - group.minAlong) * fraction
    local best, bestDistance = nil, nil
    for along, candidate in pairs(group.segments) do
        local key = candidate.orientation .. ":" .. candidate.square:getX() .. ":" .. candidate.square:getY()
        if not used[key] then
            local distance = math.abs(along - target)
            if not bestDistance or distance < bestDistance then
                best, bestDistance = candidate, distance
            end
        end
    end
    if best then
        used[best.orientation .. ":" .. best.square:getX() .. ":" .. best.square:getY()] = true
    end
    return best
end

local function chooseWindowSites(room, typeDef)
    local groups = collectWallGroups(room, typeDef)
    if #groups < 3 then return {}, #groups end

    local sideA, sideB = groups[1], groups[2]
    local used, sites = {}, {}
    local a1 = closestUnusedSegment(sideA, 0.33, used)
    local a2 = closestUnusedSegment(sideA, 0.67, used)
    local b1 = closestUnusedSegment(sideB, 0.67, used)
    if a1 then sites[#sites + 1] = a1 end
    if a2 then sites[#sites + 1] = a2 end
    if b1 then sites[#sites + 1] = b1 end

    local offset = typeDef and typeDef.offset or { x = 1, y = 1 }
    local entryX = room.x + (offset.x or 1)
    local entryY = room.y + (offset.y or 1)
    local rear, rearDistance = nil, -1
    for i = 3, #groups do
        local group = groups[i]
        local lineDistance = group.orientation == "N"
            and math.abs(group.line - entryY) or math.abs(group.line - entryX)
        if lineDistance > rearDistance then
            rear, rearDistance = group, lineDistance
        end
    end
    local rearWindow = closestUnusedSegment(rear, 0.5, used)
    if rearWindow then sites[#sites + 1] = rearWindow end
    return sites, #groups
end

local function windowSprite(orientation)
    -- The 32/33 chrome pair gives the closest stock look to the Scamp's metal window trim.
    local preferred = orientation == "N" and "fixtures_windows_01_33" or "fixtures_windows_01_32"
    local fallback = orientation == "N" and "fixtures_windows_01_1" or "fixtures_windows_01_0"
    local flag = orientation == "N" and IsoFlagType.windowN or IsoFlagType.windowW
    local sprite = getSprite(preferred)
    local matches = false
    if sprite then pcall(function() matches = sprite:getProperties():has(flag) end) end
    if matches then return sprite end
    sprite = getSprite(fallback)
    matches = false
    if sprite then pcall(function() matches = sprite:getProperties():has(flag) end) end
    if matches then return sprite end
    return nil
end

local function installWindow(site, state)
    local square, wall = site.square, site.object
    if not squareHasLoadedChunk(square) or not wall or not wall:getSquare() then return false end
    local wallSprite = wall:getSprite()
    if not wallSprite then return false end
    local north = site.orientation == "N"
    local glassSprite = windowSprite(site.orientation)
    if not glassSprite then return false end

    local ok, window = pcall(function()
        return IsoWindow.new(getCell(), square, glassSprite, north)
    end)
    if not ok or not window then return false end
    local data = {
        originalSprite = tostring(wallSprite:getName()),
        originalNorth = north,
        originalWasThumpable = site.isThumpable,
    }
    local marked = pcall(function() window:getModData()[WINDOW_MARKER] = data end)
    if not marked then return false end
    pcall(function() window:setIsLocked(true) end)
    pcall(function() window:setHealth(10000) end)

    removeObject(square, wall)
    local added = pcall(function() square:AddSpecialObject(window) end)
    if not added then
        pcall(function() square:AddTileObject(wall) end)
        refreshSquare(square)
        return false
    end
    refreshSquare(square)
    state.replacements[#state.replacements + 1] = {
        x = square:getX(), y = square:getY(), z = square:getZ(), original = wall,
    }
    return true
end

local function buildWindows(state)
    local stale = restoreTaggedWindows(state.room, state.typeDef, nil)
    if stale > 0 then log("restored " .. stale .. " stale test window(s) before rebuild") end
    local sites, groupCount = chooseWindowSites(state.room, state.typeDef)
    if #sites == 0 then
        log("could not find safe wall sites; wall groups=" .. groupCount)
        return false
    end
    local installed = 0
    for i = 1, #sites do
        if installWindow(sites[i], state) then installed = installed + 1 end
    end
    state.windowsInstalled = installed
    if installed > 0 then removeExteriorZombies(state) end
    log("Scamp 13 room " .. state.room.x .. "," .. state.room.y .. ": installed "
        .. installed .. "/" .. #sites .. " model-layout windows; wall groups=" .. groupCount)
    return installed > 0
end

local function restoreActive(reason)
    if not active then
        pending = nil
        return
    end
    local state = active
    active = nil
    pending = nil
    local restored = restoreTaggedWindows(state.room, state.typeDef, state)
    log("restored " .. restored .. " Scamp wall section(s) on " .. tostring(reason or "cleanup"))
end

local function onPostEnter(ctx)
    if not ctx or scriptName(ctx.vehicle) ~= TARGET_SCRIPT or not ctx.room then return end
    if active then restoreActive("new RV entry") end
    active = {
        player = ctx.player,
        vehicle = ctx.vehicle,
        room = ctx.room,
        typeDef = ctx.typeDef,
        replacements = {},
        buildAttempts = 0,
    }
    pending = active
    log("Scamp 13 entry detected; preparing temporary model-matched windows")
end

local function onPreExit(ctx)
    if active and ctx and sameRoom(active.room, ctx.room) then
        restoreActive("normal RV exit")
    end
end

local function onTick()
    tickCount = tickCount + 1
    if pending then
        pending.buildAttempts = pending.buildAttempts + 1
        if pending.buildAttempts >= 3 then
            buildWindows(pending)
            pending = nil
        end
    end
    if active and active.windowsInstalled and active.windowsInstalled > 0
        and not pending and tickCount % CLEAN_INTERVAL_TICKS == 0 then
        removeExteriorZombies(active)
    end
end

local ok, RVHooks = pcall(require, "RVHooks")
if not ok or not RVHooks or type(RVHooks.register) ~= "function" then
    log("RVHooks unavailable; check that PROJECT RV Interior loads before this addon")
    return
end

RVHooks.register("postEnter", onPostEnter, 900)
RVHooks.register("preExit", onPreExit, 900)
Events.OnTick.Add(onTick)
Events.OnPlayerDeath.Add(function(player)
    if active and (not player or player == active.player) then restoreActive("player death") end
end)

log("loaded v0.1.1 for " .. TARGET_SCRIPT .. " (chunk-guarded tile mutations)")
