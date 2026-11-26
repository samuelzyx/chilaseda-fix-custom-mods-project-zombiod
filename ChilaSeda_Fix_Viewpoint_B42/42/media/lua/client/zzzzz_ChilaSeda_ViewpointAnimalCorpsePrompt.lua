require "ISUI/ISUIElement"
require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "ISUI/Animal/ISAnimalContextMenu"
require "Vehicles/TimedActions/ISPathFindAction"
require "TimedActions/Animals/ISButcherAnimal"
require "TimedActions/ISInventoryTransferAction"

local TAG = "[ChilaSeda_ViewpointAnimalCorpsePrompt] "
local AIM_RADIUS = 120
local MAX_WORLD_DISTANCE = 8
local SEARCH_RADIUS = 6
local SCREEN_LIFT = 0.2
local PROMPT_GAP = 84
local REFRESH_MS = 32
local MAX_ACTION_TRACE_LINES = 256
local MAX_MODIFIER_REJECT_TRACE_LINES = 24
local MAX_BUTCHER_TRACE_LINES = 96
local actionTraceCount = 0
local modifierRejectTraceCount = 0
local butcherTraceCount = 0
local lastModifierRejectTraceAt = nil
local butcherRestoreAttemptCount = 0
local butcherActionContexts = {}
local restoreActionContexts = {}
local lifecycleUnavailableLogged = {}
local prompt

local function traceAction(message)
    if actionTraceCount >= MAX_ACTION_TRACE_LINES then return end
    actionTraceCount = actionTraceCount + 1
    print(TAG .. "actionTrace=" .. tostring(actionTraceCount) .. " " .. message)
end

local function traceModifierReject(key, actionName)
    if modifierRejectTraceCount >= MAX_MODIFIER_REJECT_TRACE_LINES then return end
    local now = type(getTimestampMs) == "function" and getTimestampMs() or nil
    if type(now) == "number" and type(lastModifierRejectTraceAt) == "number"
            and now >= lastModifierRejectTraceAt and now - lastModifierRejectTraceAt < 2000 then
        return
    end
    modifierRejectTraceCount = modifierRejectTraceCount + 1
    if type(now) == "number" then lastModifierRejectTraceAt = now end
    traceAction("input=modifier-rejected action=" .. tostring(actionName)
        .. " keyCode=" .. tostring(key)
        .. " configured=" .. tostring(ChilaSedaViewpointAnimalCorpseActionModifier or "ALT")
        .. " modifierDown=false")
end

local function safeMethod(object, method, ...)
    if not object then return nil end
    local args = { ... }
    local unpackValues = table.unpack or unpack
    local ok, result = pcall(function()
        local fn = object[method]
        if type(fn) ~= "function" then return nil end
        return fn(object, unpackValues(args))
    end)
    return ok and result or nil
end

local function traceButcher(message)
    if butcherTraceCount >= MAX_BUTCHER_TRACE_LINES then return end
    butcherTraceCount = butcherTraceCount + 1
    print(TAG .. "butcherTrace=" .. tostring(butcherTraceCount) .. " " .. message)
end

local function diagnosticValue(value)
    if value == nil then value = "nil" end
    return string.gsub(tostring(value), "[%s,;]", "_")
end

local function diagnosticItem(item)
    if not item then return "none" end
    local itemType = safeMethod(item, "getFullType") or safeMethod(item, "getType") or "unknown"
    local itemId = safeMethod(item, "getID") or safeMethod(item, "getItemID") or "na"
    local container = safeMethod(item, "getContainer")
    local containerType = safeMethod(container, "getType") or "none"
    local parent = safeMethod(container, "getParent")
    local parentType = safeMethod(parent, "getFullType") or safeMethod(parent, "getObjectName")
        or safeMethod(parent, "getName") or safeMethod(parent, "getType") or "none"
    return "type=" .. diagnosticValue(itemType) .. ",id=" .. diagnosticValue(itemId)
        .. ",container=" .. diagnosticValue(containerType)
        .. ",parent=" .. diagnosticValue(parentType)
end

local function diagnosticHands(player)
    return "hands{primary{" .. diagnosticItem(safeMethod(player, "getPrimaryHandItem"))
        .. "},secondary{" .. diagnosticItem(safeMethod(player, "getSecondaryHandItem")) .. "}}"
end

local function diagnosticActionItem(action)
    if not action then return "none" end
    return "item{" .. diagnosticItem(action.item or action.weapon) .. "},primaryItem{"
        .. diagnosticItem(action.primaryItem) .. "},secondaryItem{" .. diagnosticItem(action.secondaryItem) .. "}"
end

local function packValues(...)
    return { n = select("#", ...), ... }
end

local function unpackValues(values, first)
    local unpackFunction = table.unpack or unpack
    return unpackFunction(values, first or 1, values.n)
end

local function installActionLifecycleTrace(actionClass, actionName, contexts)
    if type(actionClass) ~= "table" then
        if not lifecycleUnavailableLogged[actionName] then
            lifecycleUnavailableLogged[actionName] = true
            traceButcher("lifecycle-hook=waiting action=" .. tostring(actionName) .. " reason=class-unavailable")
        end
        return false
    end
    if actionClass.ChilaSedaButcherLifecycleTraceInstalled then return true end

    local wrappedMethods = {}
    for _, method in ipairs({ "isValid", "start", "perform", "complete", "stop" }) do
        local original = actionClass[method]
        if type(original) == "function" then
            local methodName = method
            local originalMethod = original
            actionClass[methodName] = function(action, ...)
                local context = contexts[action]
                if not context then return originalMethod(action, ...) end

                local player = context.player or action.character
                local traceMethod = true
                if methodName == "isValid" then
                    context.isValidTraceCount = (context.isValidTraceCount or 0) + 1
                    traceMethod = context.isValidTraceCount <= 4
                end
                if traceMethod then
                    traceButcher("attempt=" .. tostring(context.attempt)
                        .. " lifecycle=" .. tostring(context.kind) .. " method=" .. methodName
                        .. " phase=before expected{" .. diagnosticItem(context.expected) .. "} "
                        .. diagnosticHands(player) .. " " .. diagnosticActionItem(action))
                end

                local results = packValues(pcall(originalMethod, action, ...))
                if not results[1] then
                    traceButcher("attempt=" .. tostring(context.attempt)
                        .. " lifecycle=" .. tostring(context.kind) .. " method=" .. methodName
                        .. " phase=error reason=" .. diagnosticValue(results[2])
                        .. " expected{" .. diagnosticItem(context.expected) .. "} "
                        .. diagnosticHands(player) .. " " .. diagnosticActionItem(action))
                    if methodName == "complete" or methodName == "stop" then contexts[action] = nil end
                    error(results[2])
                end

                local result = results[2]
                local traceResult = true
                if methodName == "isValid" then
                    context.isValidResultTraceCount = (context.isValidResultTraceCount or 0) + 1
                    traceResult = context.isValidResultTraceCount <= 4
                end
                if traceResult then
                    traceButcher("attempt=" .. tostring(context.attempt)
                        .. " lifecycle=" .. tostring(context.kind) .. " method=" .. methodName
                        .. " phase=after result=" .. diagnosticValue(result)
                        .. " expected{" .. diagnosticItem(context.expected) .. "} "
                        .. diagnosticHands(player) .. " " .. diagnosticActionItem(action))
                end
                if methodName == "complete" or methodName == "stop" then contexts[action] = nil end
                return unpackValues(results, 2)
            end
            table.insert(wrappedMethods, methodName)
        end
    end

    if #wrappedMethods == 0 then
        traceButcher("lifecycle-hook=waiting action=" .. tostring(actionName) .. " reason=no-methods")
        return false
    end
    actionClass.ChilaSedaButcherLifecycleTraceInstalled = true
    traceButcher("lifecycle-hook=installed action=" .. tostring(actionName)
        .. " methods=" .. table.concat(wrappedMethods, ","))
    return true
end

local function text(key, fallback, ...)
    if type(getText) == "function" then
        local ok, value = pcall(getText, key, ...)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallback
end

local function viewpointActive()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.active) ~= "function" then return false end
    local ok, active = pcall(bridge.active)
    return ok and active == true
end

local function playerForPrompt()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local player = getSpecificPlayer(0)
    if not player or safeMethod(player, "getVehicle") then return nil end
    if type(isGamePaused) == "function" and isGamePaused() then return nil end
    return player
end

local function isAnimalCorpse(body)
    if not body or not instanceof then return false end
    local ok, deadBody = pcall(instanceof, body, "IsoDeadBody")
    if not ok or not deadBody then return false end
    return safeMethod(body, "isAnimal") == true
end

local function bodyName(body)
    return safeMethod(body, "getCustomName") or safeMethod(body, "getDisplayName")
        or text("UI_ChilaSeda_ViewpointAnimalCorpseName", "Cadaver de animal")
end

local function butcherKnife(player)
    if not ItemTag or not ItemTag.BUTCHER_ANIMAL then return nil end
    local inventory = safeMethod(player, "getInventory")
    if not inventory then return nil end
    local predicate = function(item)
        return safeMethod(item, "isBroken") ~= true
    end
    local ok, knife = pcall(inventory.getFirstTagEvalRecurse, inventory,
        ItemTag.BUTCHER_ANIMAL, predicate)
    return ok and knife or nil
end

local function corpseCanBeButchered(body, player)
    if safeMethod(body, "isAnimalSkeleton") == true
            or safeMethod(body, "hasAnimalParts") ~= true then
        return false
    end
    return butcherKnife(player) ~= nil
end

local function targetBody(player, includeDiagnostics)
    local details = includeDiagnostics and {
        reason = "not-searched", squares = 0, objects = 0, animals = 0,
        inWorldRange = 0, projected = 0, onScreen = 0, withinAim = 0,
        invalidPosition = 0, projectionRejected = 0, screenRejected = 0, aimRejected = 0,
    } or nil
    local function noTarget(reason)
        if details then details.reason = reason; return nil, details end
        return nil
    end
    if not viewpointActive() then return noTarget("viewpoint-inactive") end
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.prepareNativeForagePins) ~= "function"
            or type(bridge.projectNativeForagePin) ~= "function" then
        return noTarget("pin-bridge-unavailable")
    end
    local playerNum = safeMethod(player, "getPlayerNum") or 0
    local prepared, ready = pcall(bridge.prepareNativeForagePins, playerNum)
    if not prepared or ready ~= true then return noTarget("pin-preparation-failed") end
    local sizeOk, width, height = pcall(function()
        return bridge.nativeForagePinScreenWidth(), bridge.nativeForagePinScreenHeight()
    end)
    if not sizeOk or type(width) ~= "number" or type(height) ~= "number"
            or width <= 0 or height <= 0 then
        return noTarget("screen-size-unavailable")
    end

    local px, py = safeMethod(player, "getX"), safeMethod(player, "getY")
    local pz = safeMethod(player, "getZ") or 0
    if type(px) ~= "number" or type(py) ~= "number" then return noTarget("player-position-unavailable") end
    local cell = safeMethod(player, "getCell") or (type(getCell) == "function" and getCell())
    if not cell or type(cell.getGridSquare) ~= "function" then return noTarget("cell-unavailable") end

    local originX, originY, originZ = math.floor(px), math.floor(py), math.floor(pz)
    local centerX, centerY = width / 2, height / 2
    local best, bestDistance
    local seen = {}
    for dx = -SEARCH_RADIUS, SEARCH_RADIUS do
        for dy = -SEARCH_RADIUS, SEARCH_RADIUS do
            if dx * dx + dy * dy <= SEARCH_RADIUS * SEARCH_RADIUS then
                if details then details.squares = details.squares + 1 end
                local squareOk, square = pcall(cell.getGridSquare, cell,
                    originX + dx, originY + dy, originZ)
                if squareOk and square and type(square.getStaticMovingObjects) == "function" then
                    local objectsOk, objects = pcall(square.getStaticMovingObjects, square)
                    if objectsOk and objects then
                        for index = 0, objects:size() - 1 do
                            local body = objects:get(index)
                            if body and not seen[body] then
                                seen[body] = true
                                if details then details.objects = details.objects + 1 end
                                if isAnimalCorpse(body) then
                                    if details then details.animals = details.animals + 1 end
                                    local bx = safeMethod(body, "getX")
                                    local by = safeMethod(body, "getY")
                                    local bz = safeMethod(body, "getZ") or 0
                                    if type(bx) == "number" and type(by) == "number" then
                                        local worldDx, worldDy = bx - px, by - py
                                        local worldDistance = worldDx * worldDx + worldDy * worldDy
                                        if worldDistance <= MAX_WORLD_DISTANCE * MAX_WORLD_DISTANCE then
                                            if details then details.inWorldRange = details.inWorldRange + 1 end
                                            local projectOk, inFront = pcall(
                                                bridge.projectNativeForagePin, bx, by, bz, SCREEN_LIFT)
                                            if projectOk and inFront == true then
                                                if details then details.projected = details.projected + 1 end
                                                local screenOk, screenX, screenY = pcall(function()
                                                    return bridge.nativeForagePinScreenX(),
                                                        bridge.nativeForagePinScreenY()
                                                end)
                                                if screenOk and type(screenX) == "number"
                                                        and type(screenY) == "number"
                                                        and screenX >= 0 and screenX <= width
                                                        and screenY >= 0 and screenY <= height then
                                                    if details then details.onScreen = details.onScreen + 1 end
                                                    local screenDx, screenDy = screenX - centerX,
                                                        screenY - centerY
                                                    local screenDistance = screenDx * screenDx
                                                        + screenDy * screenDy
                                                    if details and (not details.nearestScreenDistanceSquared
                                                            or screenDistance < details.nearestScreenDistanceSquared) then
                                                        details.nearestScreenDistanceSquared = screenDistance
                                                        details.nearestScreenDistance = math.sqrt(screenDistance)
                                                        details.nearestWorldDistance = math.sqrt(worldDistance)
                                                        details.nearestBodyId = safeMethod(body, "getObjectIDAsLong")
                                                        details.nearestScreenX = screenX
                                                        details.nearestScreenY = screenY
                                                    end
                                                    if screenDistance <= AIM_RADIUS * AIM_RADIUS then
                                                        if details then details.withinAim = details.withinAim + 1 end
                                                        if not bestDistance or screenDistance < bestDistance then
                                                            best = {
                                                                body = body,
                                                                player = player,
                                                                canButcher = corpseCanBeButchered(body, player),
                                                                canGetBones = safeMethod(body, "isAnimalSkeleton") == true,
                                                                screenX = screenX,
                                                                screenY = screenY,
                                                                worldDistance = details and math.sqrt(worldDistance) or nil,
                                                                screenDistance = details and math.sqrt(screenDistance) or nil,
                                                                name = bodyName(body),
                                                            }
                                                            bestDistance = screenDistance
                                                        end
                                                    elseif details then
                                                        details.aimRejected = details.aimRejected + 1
                                                    end
                                                elseif details then
                                                    details.screenRejected = details.screenRejected + 1
                                                end
                                            elseif details then
                                                details.projectionRejected = details.projectionRejected + 1
                                            end
                                        end
                                    elseif details then
                                        details.invalidPosition = details.invalidPosition + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if best then return best, details end
    if details then
        if details.animals == 0 then details.reason = "no-animal-corpse-in-search-grid"
        elseif details.inWorldRange == 0 then details.reason = "outside-world-range"
        elseif details.projected == 0 then details.reason = "camera-projection-rejected"
        elseif details.onScreen == 0 then details.reason = "projected-outside-screen"
        else details.reason = "outside-aim-radius" end
        return nil, details
    end
    return nil
end

local function invokeCorpseAction(actionName, queueType, callback, ...)
    if type(callback) ~= "function" then
        traceAction("action=" .. actionName .. " result=skipped reason=callback-unavailable")
        return false
    end

    local queue = ISTimedActionQueue
    local oldAdd = queue and queue.add
    local queueCount = 0
    local queueTypes = {}
    local wrappedAdd
    if type(oldAdd) == "function" then
        wrappedAdd = function(action, ...)
            local actionType = action and action.Type
            if actionType ~= nil then
                if #queueTypes < 4 then queueTypes[#queueTypes + 1] = tostring(actionType) end
                if actionType == queueType then queueCount = queueCount + 1 end
            end
            return oldAdd(action, ...)
        end
        queue.add = wrappedAdd
    end

    local utilities = luautils
    local oldWalkAdj = utilities and utilities.walkAdj
    local walkCalls, walkResult, walkError = 0, nil, nil
    local wrappedWalkAdj
    if type(oldWalkAdj) == "function" then
        wrappedWalkAdj = function(character, square, ...)
            walkCalls = walkCalls + 1
            local ok, result = pcall(oldWalkAdj, character, square, ...)
            if not ok then
                walkError = result
                error(result)
            end
            walkResult = result
            return result
        end
        utilities.walkAdj = wrappedWalkAdj
    end

    local callbackOk, callbackResult = pcall(callback, ...)
    if queue and queue.add == wrappedAdd then queue.add = oldAdd end
    if utilities and utilities.walkAdj == wrappedWalkAdj then utilities.walkAdj = oldWalkAdj end

    local queueSummary = #queueTypes > 0 and table.concat(queueTypes, ",") or "none"
    traceAction("action=" .. actionName
        .. " result=" .. (callbackOk and "callback-ok" or "callback-error")
        .. " walkAdjCalls=" .. tostring(walkCalls)
        .. " walkAdj=" .. tostring(walkResult)
        .. " walkError=" .. (walkError and tostring(walkError) or "none")
        .. " queued=" .. tostring(queueCount)
        .. " queueTypes=" .. queueSummary
        .. " callbackResult=" .. tostring(callbackResult))
    if not callbackOk then
        traceAction("action=" .. actionName .. " error=" .. tostring(callbackResult))
    end
    return callbackOk and queueCount > 0
end

local function performButchering(target)
    local body, player = target and target.body, target and target.player
    if not body or not player or not corpseCanBeButchered(body, player)
            or not AnimalContextMenu or type(AnimalContextMenu.onButcherAnimal) ~= "function" then
        traceAction("action=butcher result=skipped reason=target-or-vanilla-callback-unavailable")
        return false
    end
    return invokeCorpseAction("butcher", "ISButcherAnimal",
        AnimalContextMenu.onButcherAnimal, body, player, butcherKnife(player))
end

local function pickUpCorpse(target)
    local body, player = target and target.body, target and target.player
    if not body or not player or not ISWorldObjectContextMenu
            or type(ISWorldObjectContextMenu.onGrabCorpseItem) ~= "function" then
        traceAction("action=pickup result=skipped reason=target-or-vanilla-callback-unavailable")
        return false
    end
    return invokeCorpseAction("pickup", "ISGrabCorpseAction",
        ISWorldObjectContextMenu.onGrabCorpseItem, {}, body, safeMethod(player, "getPlayerNum") or 0)
end

local function getAnimalBones(target)
    local body, player = target and target.body, target and target.player
    if not body or not player or safeMethod(body, "isAnimalSkeleton") ~= true
            or not AnimalContextMenu or type(AnimalContextMenu.onGetAnimalBones) ~= "function" then
        traceAction("action=bones result=skipped reason=target-or-vanilla-callback-unavailable")
        return false
    end
    return invokeCorpseAction("bones", "ISGetAnimalBones",
        AnimalContextMenu.onGetAnimalBones, body, player)
end

local function targetForShortcut(player)
    local current, details = targetBody(player, true)
    if current then
        traceAction("target=live name=" .. tostring(current.name)
            .. " bodyId=" .. tostring(safeMethod(current.body, "getObjectIDAsLong") or "unknown")
            .. " worldDistance=" .. tostring(current.worldDistance)
            .. " screenDistance=" .. tostring(current.screenDistance)
            .. " screenX=" .. tostring(current.screenX) .. " screenY=" .. tostring(current.screenY)
            .. " searchReason=matched"
            .. " scannedSquares=" .. tostring(details and details.squares or 0)
            .. " objects=" .. tostring(details and details.objects or 0)
            .. " animalCorpses=" .. tostring(details and details.animals or 0)
            .. " inWorldRange=" .. tostring(details and details.inWorldRange or 0)
            .. " projected=" .. tostring(details and details.projected or 0)
            .. " onScreen=" .. tostring(details and details.onScreen or 0)
            .. " withinAim=" .. tostring(details and details.withinAim or 0)
            .. " nearestWorldDistance=" .. tostring(details and details.nearestWorldDistance)
            .. " nearestScreenDistance=" .. tostring(details and details.nearestScreenDistance)
            .. " nearestBodyId=" .. tostring(details and details.nearestBodyId)
            .. " nearestScreenX=" .. tostring(details and details.nearestScreenX)
            .. " nearestScreenY=" .. tostring(details and details.nearestScreenY))
        return current
    end
    local cached = prompt and prompt.target
    local cachedIsAnimal = cached and isAnimalCorpse(cached.body) or false
    local cachedPlayerNumber = cached and safeMethod(cached.player, "getPlayerNum") or nil
    local activePlayerNumber = safeMethod(player, "getPlayerNum")
    local samePlayerNumber = cachedPlayerNumber ~= nil and activePlayerNumber ~= nil
        and cachedPlayerNumber == activePlayerNumber
    if cached and cached.player == player and cachedIsAnimal then
        traceAction("target=prompt-cache name=" .. tostring(cached.name)
            .. " bodyId=" .. tostring(safeMethod(cached.body, "getObjectIDAsLong") or "unknown")
            .. " playerWrapperSame=true playerNum=" .. tostring(activePlayerNumber)
            .. " searchReason=" .. tostring(details and details.reason or "unknown"))
        return cached
    end
    traceAction("target=none reason=" .. tostring(details and details.reason or "search-unavailable")
        .. " scannedSquares=" .. tostring(details and details.squares or 0)
        .. " objects=" .. tostring(details and details.objects or 0)
        .. " animalCorpses=" .. tostring(details and details.animals or 0)
        .. " inWorldRange=" .. tostring(details and details.inWorldRange or 0)
        .. " projected=" .. tostring(details and details.projected or 0)
        .. " onScreen=" .. tostring(details and details.onScreen or 0)
        .. " withinAim=" .. tostring(details and details.withinAim or 0)
        .. " invalidPosition=" .. tostring(details and details.invalidPosition or 0)
        .. " projectionRejected=" .. tostring(details and details.projectionRejected or 0)
        .. " screenRejected=" .. tostring(details and details.screenRejected or 0)
        .. " aimRejected=" .. tostring(details and details.aimRejected or 0)
        .. " nearestWorldDistance=" .. tostring(details and details.nearestWorldDistance)
        .. " nearestScreenDistance=" .. tostring(details and details.nearestScreenDistance)
        .. " nearestBodyId=" .. tostring(details and details.nearestBodyId)
        .. " nearestScreenX=" .. tostring(details and details.nearestScreenX)
        .. " nearestScreenY=" .. tostring(details and details.nearestScreenY)
        .. " cachePresent=" .. tostring(cached ~= nil)
        .. " cacheBodyAnimal=" .. tostring(cachedIsAnimal)
        .. " cacheWrapperSame=" .. tostring(cached ~= nil and cached.player == player)
        .. " cacheSamePlayerNum=" .. tostring(samePlayerNumber)
        .. " cachePlayerNum=" .. tostring(cachedPlayerNumber)
        .. " activePlayerNum=" .. tostring(activePlayerNumber))
    return nil
end

local function playerNumber(character)
    local number = safeMethod(character, "getPlayerNum")
    return type(number) == "number" and number or nil
end

local function sameCharacter(left, right)
    if left == right then return true end
    local leftNumber, rightNumber = playerNumber(left), playerNumber(right)
    return leftNumber ~= nil and rightNumber ~= nil and leftNumber == rightNumber
end

local function bodyObjectId(body)
    local objectId = safeMethod(body, "getObjectIDAsLong")
    if objectId == nil or tostring(objectId) == "-1" then return nil end
    return tostring(objectId)
end

local function sameBody(left, right)
    if left == right then return true end
    local leftId, rightId = bodyObjectId(left), bodyObjectId(right)
    return leftId ~= nil and rightId ~= nil and leftId == rightId
end

local function actionAlreadyQueued(player, body, actionType)
    local queues = ISTimedActionQueue and ISTimedActionQueue.queues
    if type(queues) ~= "table" then return false end
    for _, timedQueue in pairs(queues) do
        local actions = timedQueue and timedQueue.queue
        local queueCharacter = timedQueue and timedQueue.character
        if type(actions) == "table"
                and (queueCharacter == nil or sameCharacter(queueCharacter, player)) then
            for _, action in ipairs(actions) do
                local actionCharacter = action and action.character
                if action and action.Type == actionType and sameBody(action.body, body)
                        and (actionCharacter == nil or sameCharacter(actionCharacter, player)) then
                    return true
                end
            end
        end
    end
    return false
end

local function keyName(key)
    if type(key) ~= "number" or key <= 0 then return nil end
    if type(ChilaSedaViewpointFormatAnimalCorpseActionKey) == "function" then
        return ChilaSedaViewpointFormatAnimalCorpseActionKey(key)
    end
    if type(ChilaSedaViewpointFormatNativeActionKey) == "function" then
        return ChilaSedaViewpointFormatNativeActionKey(key)
    end
    if Keyboard and type(Keyboard.getKeyName) == "function" then
        local ok, name = pcall(Keyboard.getKeyName, key)
        if ok and type(name) == "string" and name ~= "" then return "Alt+" .. name end
    end
    return "Alt+" .. tostring(key)
end

local function defaultModifierIsDown()
    if Keyboard and type(Keyboard.isKeyDown) == "function" then
        local left, right = Keyboard.KEY_LMENU or 56, Keyboard.KEY_RMENU or 184
        if left then
            local ok, down = pcall(Keyboard.isKeyDown, left)
            if ok and down then return true end
        end
        if right then
            local ok, down = pcall(Keyboard.isKeyDown, right)
            if ok and down then return true end
        end
    end
    return false
end

local function configuredModifierIsDown()
    if type(ChilaSedaViewpointAnimalCorpseActionModifierMatches) == "function" then
        local ok, matches = pcall(ChilaSedaViewpointAnimalCorpseActionModifierMatches)
        return ok and matches == true
    end
    return defaultModifierIsDown()
end

local AnimalCorpsePrompt = ISUIElement:derive("ChilaSedaViewpointAnimalCorpsePrompt")

function AnimalCorpsePrompt:new()
    local element = ISUIElement.new(self, 0, 0, 1, 1)
    element.anchorLeft, element.anchorTop = true, true
    element.target = nil
    element.nextRefresh = 0
    return element
end

function AnimalCorpsePrompt:onMouseDown() return false end
function AnimalCorpsePrompt:onMouseUp() return false end
function AnimalCorpsePrompt:onRightMouseDown() return false end
function AnimalCorpsePrompt:onRightMouseUp() return false end

function AnimalCorpsePrompt:prerender()
    local now = type(getTimestampMs) == "function"
        and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < self.nextRefresh then return end
    self.nextRefresh = now + REFRESH_MS
    local player = playerForPrompt()
    self.target = player and targetBody(player) or nil
end

function AnimalCorpsePrompt:render()
    local target = self.target
    if not target then return end
    local pickupKey = keyName(ChilaSedaViewpointAnimalCorpsePickupKey)
    local butcherKey = target.canButcher
        and keyName(ChilaSedaViewpointAnimalCorpseButcherKey) or nil
    local bonesKey = target.canGetBones
        and keyName(ChilaSedaViewpointAnimalCorpseBonesKey) or nil
    if not pickupKey and not butcherKey and not bonesKey then return end

    local font = UIFont and (UIFont.Small or UIFont.Medium) or nil
    local rows = {}
    if butcherKey then
        rows[#rows + 1] = text("UI_ChilaSeda_ViewpointAnimalCorpseButcherPrompt",
            "Despiezar: %1", butcherKey)
    end
    if bonesKey then
        rows[#rows + 1] = text("UI_ChilaSeda_ViewpointAnimalSkeletonBonesPrompt",
            "Obtener huesos: %1", bonesKey)
    end
    local pickupText = safeMethod(target.body, "isAnimalSkeleton") == true
        and text("UI_ChilaSeda_ViewpointAnimalSkeletonPickupPrompt", "Recoger esqueleto: %1", pickupKey)
        or text("UI_ChilaSeda_ViewpointAnimalCorpsePickupPrompt", "Recoger cadaver: %1", pickupKey)
    rows[#rows + 1] = pickupText

    local function widthOf(value)
        if type(getTextManager) == "function" and font then
            local ok, width = pcall(function() return getTextManager():MeasureStringX(font, value) end)
            if ok and type(width) == "number" then return width + 18 end
        end
        return #value * 7 + 18
    end
    local core = type(getCore) == "function" and getCore() or nil
    local screenWidth = core and core:getScreenWidth() or nil
    local function centeredX(width)
        local x = target.screenX - width / 2
        if type(screenWidth) == "number" then
            x = math.max(4, math.min(x, math.max(4, screenWidth - width - 4)))
        end
        return x
    end

    local lineHeight = 20
    local y = math.max(4, target.screenY - PROMPT_GAP - lineHeight * (#rows + 1))
    local name = target.name
    local nameWidth = widthOf(name)
    local nameX = centeredX(nameWidth)
    self:drawRect(nameX, y, nameWidth, lineHeight, 0.84, 0.02, 0.02, 0.02)
    self:drawTextCentre(name, nameX + nameWidth / 2, y + 2, 1, 1, 1, 1, font)
    y = y + lineHeight + 2

    for _, label in ipairs(rows) do
        local width = widthOf(label)
        local x = centeredX(width)
        self:drawRect(x, y, width, lineHeight, 0.84, 0.02, 0.02, 0.02)
        self:drawTextCentre(label, x + width / 2, y + 2, 1, 0.88, 0.48, 1, font)
        y = y + lineHeight + 2
    end
end

local function createPrompt()
    if prompt then prompt:removeFromUIManager() end
    prompt = AnimalCorpsePrompt:new()
    prompt:initialise()
    prompt:addToUIManager()
    pcall(function() prompt:backMost() end)
end

local function onKeyStartPressed(key)
    local butcherKey = ChilaSedaViewpointAnimalCorpseButcherKey
    local pickupKey = ChilaSedaViewpointAnimalCorpsePickupKey
    local bonesKey = ChilaSedaViewpointAnimalCorpseBonesKey
    local matchesActionKey = (type(butcherKey) == "number" and key == butcherKey)
        or (type(pickupKey) == "number" and key == pickupKey)
        or (type(bonesKey) == "number" and key == bonesKey)
    if not matchesActionKey then return end
    local actionName = type(butcherKey) == "number" and key == butcherKey and "butcher"
        or type(bonesKey) == "number" and key == bonesKey and "bones"
        or type(pickupKey) == "number" and key == pickupKey and "pickup" or "unknown"
    local modifierMatches = configuredModifierIsDown()
    if not modifierMatches then
        traceModifierReject(key, actionName)
        return
    end
    if GameKeyboard and type(GameKeyboard.eatKeyPress) == "function" then
        pcall(GameKeyboard.eatKeyPress, key)
    end
    local player = playerForPrompt()
    local paused = type(isGamePaused) == "function" and isGamePaused() or false
    traceAction("input=accepted action=" .. tostring(actionName)
        .. " keyCode=" .. tostring(key) .. " key=" .. tostring(keyName and keyName(key) or key)
        .. " configured=" .. tostring(ChilaSedaViewpointAnimalCorpseActionModifier or "ALT")
        .. " modifierDown=true playerAvailable=" .. tostring(player ~= nil)
        .. " playerNum=" .. tostring(player and safeMethod(player, "getPlayerNum") or "unknown")
        .. " viewpointActive=" .. tostring(viewpointActive()) .. " paused=" .. tostring(paused)
        .. " inVehicle=" .. tostring(player == nil and getSpecificPlayer
            and getSpecificPlayer(0) and safeMethod(getSpecificPlayer(0), "getVehicle") ~= nil or false))
    if not player then
        traceAction("input=result=skipped reason=player-unavailable")
        return
    end
    local target = targetForShortcut(player)
    if not target then return end
    if type(butcherKey) == "number" and key == butcherKey then
        if actionAlreadyQueued(player, target.body, "ISButcherAnimal") then
            traceAction("action=butcher result=suppressed reason=already-queued")
            return
        end
        performButchering(target)
    elseif type(bonesKey) == "number" and key == bonesKey then
        if actionAlreadyQueued(player, target.body, "ISGetAnimalBones") then
            traceAction("action=bones result=suppressed reason=already-queued")
            return
        end
        getAnimalBones(target)
    elseif type(pickupKey) == "number" and key == pickupKey then
        pickUpCorpse(target)
    end
end

local function selectedBackpack(player)
    if not player or type(getPlayerInventory) ~= "function" then return nil end
    local page = getPlayerInventory(safeMethod(player, "getPlayerNum") or 0)
    local selected = page and page.inventoryPane and page.inventoryPane.inventory
    local root = safeMethod(player, "getInventory")
    if not selected or selected == root or safeMethod(selected, "getType") == "floor" then return nil end
    local owner = safeMethod(selected, "getContainingItem")
    if not owner or not instanceof then return nil end
    local ok, isBackpack = pcall(instanceof, owner, "InventoryContainer")
    if not ok or not isBackpack then return nil end
    return selected
end

local function canStore(container, player, item)
    if not container or not player or not item then return false end
    local ok, fits = pcall(function()
        return container:isItemAllowed(item) and container:hasRoomFor(player, item)
            and container:getCapacityWeight() + item:getUnequippedWeight()
                <= container:getEffectiveCapacity(player)
    end)
    return ok and fits == true
end

local function snapshotItems(inventory)
    local present = {}
    local items = safeMethod(inventory, "getItems")
    if items then
        for index = 0, items:size() - 1 do
            local item = items:get(index)
            if item then present[item] = true end
        end
    end
    return present
end

local pendingFloorNotices = setmetatable({}, { __mode = "k" })

local function notifyDroppedItem(player, item)
    if not player or not item or not HaloTextHelper
            or type(HaloTextHelper.addText) ~= "function" then return end
    local name = safeMethod(item, "getDisplayName") or "Objeto"
    if type(getText) == "function" then
        local ok, translated = pcall(getText, "UI_ChilaSeda_Viewpoint_ItemDropped", name)
        if ok and type(translated) == "string" and translated ~= "UI_ChilaSeda_Viewpoint_ItemDropped" then
            name = translated:gsub("%%1", function() return tostring(safeMethod(item, "getDisplayName") or "Objeto") end)
        else
            name = "Soltado: " .. tostring(name) .. " en el piso"
        end
    else
        name = "Soltado: " .. tostring(name) .. " en el piso"
    end
    local icon = safeMethod(item, "getTexture") or " "
    HaloTextHelper.addText(player, name, icon, 255, 220, 120)
end
ChilaSeda_ViewpointNotifyDroppedItem = notifyDroppedItem

local function routeNewButcherItems(player, before)
    if not player or (type(isClient) == "function" and isClient())
            or (type(isServer) == "function" and isServer()) then
        return
    end
    local main = safeMethod(player, "getInventory")
    local items = safeMethod(main, "getItems")
    if not main or not items then return end
    local selected = selectedBackpack(player)
    local stored, dropped = 0, 0
    local newItems = {}
    for index = 0, items:size() - 1 do
        local item = items:get(index)
        if item and not before[item] and safeMethod(item, "getContainer") == main then
            newItems[#newItems + 1] = item
        end
    end
    for _, item in ipairs(newItems) do
        local moved = false
        if selected and canStore(selected, player, item) then
            local ok, result = pcall(function()
                main:Remove(item)
                if item:getContainer() == main then return false end
                selected:AddItem(item)
                if item:getContainer() ~= selected then return false end
                if type(sendRemoveItemFromContainer) == "function" then
                    pcall(sendRemoveItemFromContainer, main, item)
                end
                if type(sendAddItemToContainer) == "function" then
                    pcall(sendAddItemToContainer, selected, item)
                end
                pcall(main.setDrawDirty, main, true)
                pcall(selected.setDrawDirty, selected, true)
                return true
            end)
            moved = ok and result == true
            if not moved then
                pcall(function()
                    local current = item:getContainer()
                    if current and current ~= main then current:Remove(item) end
                    if item:getContainer() ~= main then main:AddItem(item) end
                    if type(sendAddItemToContainer) == "function" then
                        pcall(sendAddItemToContainer, main, item)
                    end
                end)
            end
        end
        if moved then
            stored = stored + 1
            if type(ChilaSeda_ViewpointNotifyStoredItem) == "function" then
                pcall(ChilaSeda_ViewpointNotifyStoredItem, player, item)
            end
        elseif selected and ISInventoryPaneContextMenu
                and type(ISInventoryPaneContextMenu.dropItem) == "function" then
            pendingFloorNotices[item] = player
            local ok = pcall(ISInventoryPaneContextMenu.dropItem, item,
                safeMethod(player, "getPlayerNum") or 0)
            if ok then
                dropped = dropped + 1
            else
                pendingFloorNotices[item] = nil
            end
        end
    end
    if stored > 0 or dropped > 0 then
        print(TAG .. string.format("butcher output routed: backpack=%d, floor=%d", stored, dropped))
        if type(ISPlayerData) == "table" and type(getPlayerData) == "function" then
            local data = getPlayerData(safeMethod(player, "getPlayerNum") or 0)
            if data and data.playerInventory and type(data.playerInventory.refreshBackpacks) == "function" then
                pcall(data.playerInventory.refreshBackpacks, data.playerInventory)
            end
        end
    end
end

local function pendingFloorNoticeItems(action)
    local pending = {}
    local function add(item)
        local player = item and pendingFloorNotices[item]
        if player then pending[#pending + 1] = { item = item, player = player } end
    end
    add(action and action.item)
    for _, batch in ipairs(action and action.queueList or {}) do
        for _, item in ipairs(batch.items or {}) do add(item) end
    end
    return pending
end

if ISInventoryTransferAction and type(ISInventoryTransferAction.perform) == "function"
        and not ISInventoryTransferAction.ChilaSedaButcherDestinationHalo then
    local originalTransferPerform = ISInventoryTransferAction.perform
    ISInventoryTransferAction.perform = function(action, ...)
        local pending = pendingFloorNoticeItems(action)
        local results = packValues(originalTransferPerform(action, ...))
        local destination = action and action.destContainer
        local isFloor = safeMethod(destination, "getType") == "floor"
        for _, entry in ipairs(pending) do
            local reachedFloor = isFloor and safeMethod(entry.item, "getContainer") == destination
            pendingFloorNotices[entry.item] = nil
            traceButcher("floor-notice transfer=perform result="
                .. (reachedFloor and "delivered" or "not-delivered")
                .. " destination=" .. diagnosticValue(safeMethod(destination, "getType"))
                .. " " .. diagnosticItem(entry.item))
            if reachedFloor then notifyDroppedItem(entry.player, entry.item) end
        end
        return unpackValues(results)
    end
    ISInventoryTransferAction.ChilaSedaButcherDestinationHalo = true
    traceButcher("hook=installed feature=floor-notice action=ISInventoryTransferAction.perform")
end

local function installViewpointSkeletonBonesAction()
    local view = ViewpointInteract
    if not view or type(view.harvest) ~= "function" or view.chilaSkeletonBonesInstalled then return end
    local originalHarvest = view.harvest
    view.harvest = function(player, object, ...)
        local result = originalHarvest(player, object, ...)
        if type(result) ~= "table" or safeMethod(object, "isAnimalSkeleton") ~= true
                or type(result.labels) ~= "table" or type(result.enabled) ~= "table"
                or not AnimalContextMenu or type(AnimalContextMenu.onGetAnimalBones) ~= "function" then
            return result
        end

        local actions = view.actions
        if type(actions) ~= "table" then return result end
        for _, action in ipairs(actions) do
            if action.fn == AnimalContextMenu.onGetAnimalBones
                    or action.fn == AnimalContextMenu.onGetAnimalBonesFromInv then
                return result
            end
        end

        local bodyName = safeMethod(object, "getDisplayName") or safeMethod(object, "getCustomName") or ""
        local label = getText("ContextMenu_GetBones", bodyName)
        local iconPath = safeMethod(object, "getInvIcon")
        local icon = iconPath and getTexture(iconPath) or nil
        local entry = { name = label, fn = AnimalContextMenu.onGetAnimalBones,
            args = { object, player }, n = 2, enabled = true, first = false, menu = true, icon = icon }
        local oldCount = #(result.labels or {})
        local index = #actions + 1
        local primary = getText("ContextMenu_Equip_Primary")
        local secondary = getText("ContextMenu_Equip_Secondary")
        local both = getText("ContextMenu_Equip_Two_Hands")
        for i, action in ipairs(actions) do
            if action.name == primary or action.name == secondary or action.name == both then index = i + 1 end
        end
        table.insert(actions, index, entry)
        table.insert(result.labels, index, label)
        table.insert(result.enabled, index, true)
        if type(result.deliberate) == "table" then table.insert(result.deliberate, index, false) end
        for _, field in ipairs({ "tips", "icons" }) do
            local values = result[field]
            if type(values) == "table" then
                for i = oldCount, index, -1 do values[i + 1] = values[i] end
                values[index] = field == "icons" and icon or nil
            end
        end
        return result
    end
    view.chilaSkeletonBonesInstalled = true
end

installViewpointSkeletonBonesAction()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installViewpointSkeletonBonesAction)
end

local function installButcherPrimaryWeaponRestore()
    if AnimalContextMenu and AnimalContextMenu.ChilaSedaButcherWeaponRestoreInstalled then
        return true
    end
    if not AnimalContextMenu or type(AnimalContextMenu.onButcherAnimal) ~= "function" then
        traceButcher("hook=waiting feature=primary-restore reason=butcher-callback-unavailable")
        return false
    end

    local originalButcher = AnimalContextMenu.onButcherAnimal
    AnimalContextMenu.onButcherAnimal = function(body, player, knife)
        local previousPrimary = safeMethod(player, "getPrimaryHandItem")
        local previousSecondary = safeMethod(player, "getSecondaryHandItem")
        butcherRestoreAttemptCount = butcherRestoreAttemptCount + 1
        local attempt = butcherRestoreAttemptCount
        local bodyId = safeMethod(body, "getObjectIDAsLong") or safeMethod(body, "getID") or "na"
        local context = {
            attempt = attempt,
            kind = "butcher",
            player = player,
            expected = previousPrimary,
            knife = knife,
            bodyId = bodyId,
        }
        local queue = ISTimedActionQueue
        local originalAdd = queue and queue.add
        local butcherQueued = 0
        local queuedActionTypes = {}
        local wrappedAdd
        traceButcher("attempt=" .. tostring(attempt) .. " phase=callback-before body="
            .. diagnosticValue(bodyId) .. " previousPrimary{" .. diagnosticItem(previousPrimary)
            .. "} previousSecondary{" .. diagnosticItem(previousSecondary) .. "} knife{"
            .. diagnosticItem(knife) .. "} " .. diagnosticHands(player))
        if type(originalAdd) == "function" then
            wrappedAdd = function(action, ...)
                local actionType = action and action.Type or "unknown"
                local relevant = actionType == "ISButcherAnimal" or actionType == "ISEquipWeaponAction"
                if actionType == "ISButcherAnimal" then
                    butcherQueued = butcherQueued + 1
                    butcherActionContexts[action] = context
                end
                if relevant then
                    table.insert(queuedActionTypes, tostring(actionType))
                    traceButcher("attempt=" .. tostring(attempt) .. " phase=vanilla-queue-before action="
                        .. diagnosticValue(actionType) .. " " .. diagnosticActionItem(action)
                        .. " " .. diagnosticHands(player))
                end
                local results = packValues(originalAdd(action, ...))
                if relevant then
                    traceButcher("attempt=" .. tostring(attempt) .. " phase=vanilla-queue-after action="
                        .. diagnosticValue(actionType) .. " " .. diagnosticActionItem(action)
                        .. " " .. diagnosticHands(player))
                end
                return unpackValues(results)
            end
            queue.add = wrappedAdd
        end

        local ok, result = pcall(originalButcher, body, player, knife)
        if queue and queue.add == wrappedAdd then queue.add = originalAdd end
        if not ok then
            traceButcher("attempt=" .. tostring(attempt) .. " phase=callback-error reason="
                .. diagnosticValue(result) .. " queued=" .. tostring(butcherQueued)
                .. " actions=" .. table.concat(queuedActionTypes, ",") .. " " .. diagnosticHands(player))
            error(result)
        end
        traceButcher("attempt=" .. tostring(attempt) .. " phase=callback-after butcherQueued="
            .. tostring(butcherQueued) .. " actions=" .. table.concat(queuedActionTypes, ",")
            .. " previousPrimary{" .. diagnosticItem(previousPrimary) .. "} " .. diagnosticHands(player))

        if butcherQueued == 0 then
            traceButcher("attempt=" .. tostring(attempt)
                .. " result=skipped reason=butcher-not-queued " .. diagnosticHands(player))
            return result
        end
        if not previousPrimary then
            traceButcher("attempt=" .. tostring(attempt)
                .. " result=skipped reason=no-previous-primary " .. diagnosticHands(player))
            return result
        end
        if previousPrimary == knife then
            traceButcher("attempt=" .. tostring(attempt) .. " result=skipped reason=knife-was-primary"
                .. " previousPrimary{" .. diagnosticItem(previousPrimary) .. "} " .. diagnosticHands(player))
            return result
        end

        local twoHands = safeMethod(previousPrimary, "isTwoHandWeapon") == true
            or safeMethod(previousPrimary, "isRequiresEquippedBothHands") == true
        local equip = ISWorldObjectContextMenu and ISWorldObjectContextMenu.equip
        if type(equip) == "function" then
            local queue = ISTimedActionQueue
            local currentAdd = queue and queue.add
            local restoreQueued = 0
            local wrappedRestoreAdd
            installActionLifecycleTrace(ISEquipWeaponAction, "restore", restoreActionContexts)
            if type(currentAdd) == "function" then
                wrappedRestoreAdd = function(action, ...)
                    if action and action.Type == "ISEquipWeaponAction" then
                        restoreQueued = restoreQueued + 1
                        restoreActionContexts[action] = {
                            attempt = attempt,
                            kind = "restore",
                            player = player,
                            expected = previousPrimary,
                            path = "world-context-equip",
                        }
                        local actionClass = ISEquipWeaponAction
                        if type(actionClass) ~= "table" and type(getmetatable) == "function" then
                            local metatableOk, metatable = pcall(getmetatable, action)
                            if metatableOk and type(metatable) == "table" then actionClass = metatable end
                        end
                        installActionLifecycleTrace(actionClass, "restore", restoreActionContexts)
                        traceButcher("attempt=" .. tostring(attempt)
                            .. " phase=restore-queue-before route=world-context-equip expected{"
                            .. diagnosticItem(previousPrimary) .. "} " .. diagnosticActionItem(action)
                            .. " " .. diagnosticHands(player))
                    end
                    local results = packValues(currentAdd(action, ...))
                    if action and action.Type == "ISEquipWeaponAction" then
                        traceButcher("attempt=" .. tostring(attempt)
                            .. " phase=restore-queue-after route=world-context-equip expected{"
                            .. diagnosticItem(previousPrimary) .. "} " .. diagnosticActionItem(action)
                            .. " " .. diagnosticHands(player))
                    end
                    return unpackValues(results)
                end
                queue.add = wrappedRestoreAdd
            end
            local restoreOk, restoreError = pcall(equip, player, knife, previousPrimary, true, twoHands)
            if queue and queue.add == wrappedRestoreAdd then queue.add = currentAdd end
            if restoreOk and restoreQueued > 0 then
                traceButcher("attempt=" .. tostring(attempt)
                    .. " result=queued route=world-context-equip expected{" .. diagnosticItem(previousPrimary)
                    .. "} twoHands=" .. tostring(twoHands) .. " " .. diagnosticHands(player))
                return result
            end
            local reason = restoreOk and "world-context-action-not-queued" or tostring(restoreError)
            traceButcher("attempt=" .. tostring(attempt) .. " fallback=direct-action reason="
                .. diagnosticValue(reason) .. " expected{" .. diagnosticItem(previousPrimary) .. "} "
                .. diagnosticHands(player))
        end

        local actionType = ISEquipWeaponAction
        if not queue or type(queue.add) ~= "function" or not actionType
                or type(actionType.new) ~= "function" then
            traceButcher("attempt=" .. tostring(attempt)
                .. " result=skipped reason=equip-action-unavailable " .. diagnosticHands(player))
            return result
        end
        local actionOk, action = pcall(actionType.new, actionType, player, previousPrimary, 50, true, twoHands)
        if not actionOk or not action then
            traceButcher("attempt=" .. tostring(attempt) .. " result=skipped reason=action-create-failed"
                .. " error=" .. diagnosticValue(action) .. " expected{" .. diagnosticItem(previousPrimary)
                .. "} " .. diagnosticHands(player))
            return result
        end
        restoreActionContexts[action] = {
            attempt = attempt,
            kind = "restore",
            player = player,
            expected = previousPrimary,
            path = "direct-action",
        }
        installActionLifecycleTrace(actionType, "restore", restoreActionContexts)
        local queued, queueError = pcall(queue.add, action)
        traceButcher("attempt=" .. tostring(attempt) .. " result=" .. (queued and "queued" or "failed")
            .. " route=direct-action expected{" .. diagnosticItem(previousPrimary) .. "} twoHands="
            .. tostring(twoHands) .. " reason=" .. (queued and "none" or diagnosticValue(queueError))
            .. " " .. diagnosticHands(player))
        return result
    end
    AnimalContextMenu.ChilaSedaButcherWeaponRestoreInstalled = true
    traceButcher("hook=installed feature=primary-restore callback=AnimalContextMenu.onButcherAnimal")
    return true
end

installButcherPrimaryWeaponRestore()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installButcherPrimaryWeaponRestore)
end

if ISButcherAnimal and type(ISButcherAnimal.complete) == "function"
        and not ISButcherAnimal.ChilaSedaSelectedBackpackRoute then
    local originalComplete = ISButcherAnimal.complete
    ISButcherAnimal.complete = function(action, ...)
        local player = action and action.character
        local inventory = player and safeMethod(player, "getInventory")
        local before = snapshotItems(inventory)
        local context = butcherActionContexts[action]
        if context then
            traceButcher("attempt=" .. tostring(context.attempt)
                .. " lifecycle=butcher method=complete phase=route-before body="
                .. diagnosticValue(context.bodyId) .. " " .. diagnosticHands(player))
        end
        local results = packValues(originalComplete(action, ...))
        local result = results[1]
        if result == true then routeNewButcherItems(player, before) end
        if context then
            traceButcher("attempt=" .. tostring(context.attempt)
                .. " lifecycle=butcher method=complete phase=route-after result="
                .. diagnosticValue(result) .. " " .. diagnosticHands(player))
        end
        return unpackValues(results)
    end
    ISButcherAnimal.ChilaSedaSelectedBackpackRoute = true
end

local function installButcherLifecycleTraces()
    installActionLifecycleTrace(ISButcherAnimal, "butcher", butcherActionContexts)
    installActionLifecycleTrace(ISEquipWeaponAction, "restore", restoreActionContexts)
end
installButcherLifecycleTraces()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installButcherLifecycleTraces)
end

if Events and Events.OnKeyStartPressed and type(Events.OnKeyStartPressed.Add) == "function" then
    Events.OnKeyStartPressed.Add(onKeyStartPressed)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(createPrompt)
end
createPrompt()

print(TAG .. "animal corpse prompt and selected-backpack butchering route loaded")
