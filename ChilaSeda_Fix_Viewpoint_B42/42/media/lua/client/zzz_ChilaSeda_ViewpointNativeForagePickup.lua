-- Targets Viewpoint's native 3D forage pins and queues their normal pickup action.
require "ISUI/ISUIElement"

local TAG = "[ChilaSeda_ViewpointNativeForagePickup] "
local AIM_RADIUS = 110
local MAX_REACH = 12
local PIN_LIFT = 0.35
local CLOSE_PIN_PROXIMITY_REACH = 1.5
local PICKUP_PROMPT_GAP = 8
local PROMPT_REFRESH_MS = 16
local MAX_PICKUP_TRACE_LINES = 128
local MAX_PICKUP_INPUT_TRACE_LINES = 64
local MAX_PICKUP_LIFECYCLE_TRACE_LINES = 16
local RAT_DROPPINGS_FULL_TYPE = "Base.Dung_Rat"
local UNKNOWN_PIN_TEXTURE = "media/textures/Foraging/pinIconUnknown.png"
local POISON_PIN_TEXTURE = "media/ui/SkullPoison.png"
local MAX_NATIVE_WORLD_PIN_TRACE_LINES = 12
local warned = false
local pickupTraceCount = 0
local pickupInputTraceCount = 0
local pickupModifierRejectTraceCount = 0
local lastPickupModifierRejectTraceAt = nil
local pickupLifecycleTraceCount = 0
local nativeWorldPinTraceCount = 0
local tracedNativeWorldPinIds = {}
local tracedNoRatWorldPin = false
local pickupPrompt

local function warnOnce(message)
    if warned then return end
    warned = true
    print(TAG .. message)
end

local function tracePickup(message)
    if pickupTraceCount >= MAX_PICKUP_TRACE_LINES then return end
    pickupTraceCount = pickupTraceCount + 1
    print(TAG .. "attempt=" .. tostring(pickupTraceCount) .. " " .. message)
end

local function tracePickupLifecycle(message)
    if pickupLifecycleTraceCount >= MAX_PICKUP_LIFECYCLE_TRACE_LINES then return end
    pickupLifecycleTraceCount = pickupLifecycleTraceCount + 1
    print(TAG .. "lifecycle=" .. tostring(pickupLifecycleTraceCount) .. " " .. message)
end

local function tracePickupInput(message, modifierRejected)
    if pickupInputTraceCount >= MAX_PICKUP_INPUT_TRACE_LINES then return end
    if modifierRejected then
        if pickupModifierRejectTraceCount >= 16 then return end
        local now = type(getTimestampMs) == "function" and getTimestampMs() or nil
        if type(now) == "number" and type(lastPickupModifierRejectTraceAt) == "number"
                and now >= lastPickupModifierRejectTraceAt and now - lastPickupModifierRejectTraceAt < 2000 then
            return
        end
        pickupModifierRejectTraceCount = pickupModifierRejectTraceCount + 1
        if type(now) == "number" then lastPickupModifierRejectTraceAt = now end
    end
    pickupInputTraceCount = pickupInputTraceCount + 1
    print(TAG .. "input=" .. tostring(pickupInputTraceCount) .. " " .. message)
end

local function nativeViewpointActive()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.active) ~= "function" then return false end
    local ok, active = pcall(bridge.active)
    return ok and active == true
end

local function nativeForageAvailable()
    return type(ViewpointForage) == "table" and type(ViewpointForage.found) == "function"
end

local function getManager(player)
    if not player or not ISSearchManager or type(ISSearchManager.getManager) ~= "function" then return nil end
    local ok, manager = pcall(ISSearchManager.getManager, player)
    return ok and manager or nil
end

local function iconIsSeen(icon)
    if not icon or type(icon.getIsSeen) ~= "function" then return false end
    local ok, seen = pcall(icon.getIsSeen, icon)
    return ok and seen == true
end

local function iconAlpha(icon)
    if not icon or type(icon.getAlpha) ~= "function" then return 0 end
    local ok, alpha = pcall(icon.getAlpha, icon)
    return ok and type(alpha) == "number" and alpha or 0
end

local function traceNativeWorldPin(message)
    if nativeWorldPinTraceCount >= MAX_NATIVE_WORLD_PIN_TRACE_LINES then return end
    nativeWorldPinTraceCount = nativeWorldPinTraceCount + 1
    print(TAG .. "world-pin=" .. tostring(nativeWorldPinTraceCount) .. " " .. message)
end

local function appendRatDroppingsWorldPins(player, reach, pins, manager)
    local worldIcons = manager and manager.worldObjectIcons
    if type(worldIcons) ~= "table" then return 0 end

    local playerX, playerY, playerZ
    if player and type(player.getX) == "function" and type(player.getY) == "function"
            and type(player.getZ) == "function" then
        local ok, x, y, z = pcall(function()
            return player:getX(), player:getY(), player:getZ()
        end)
        if ok then playerX, playerY, playerZ = x, y, z end
    end
    local radius = type(reach) == "number" and reach or 0
    local existing = {}
    for index = 1, #pins, 9 do
        if pins[index] ~= nil then existing[tostring(pins[index])] = true end
    end

    local appended = 0
    for id, icon in pairs(worldIcons) do
        if icon and icon.itemType == RAT_DROPPINGS_FULL_TYPE and not icon.isTrack then
            local pinId = icon.iconID or icon.id or id
            local idKey = tostring(pinId)
            local x, y, z = icon.xCoord, icon.yCoord, icon.zCoord or 0
            local seen = iconIsSeen(icon)
            local pointed = icon.worldMarker ~= nil
            if type(x) == "number" and type(y) == "number" and type(z) == "number" then
                local shown = seen and type(playerX) == "number" and type(playerY) == "number"
                    and type(playerZ) == "number" and type(reach) == "number"
                    and math.floor(z) == math.floor(playerZ)
                    and math.abs(x - playerX) <= radius and math.abs(y - playerY) <= radius
                if not existing[idKey] and (shown or pointed) then
                    local known = icon.itemTexture and icon.identified and icon.renderItemTexture
                    local texture = known and icon.texture or nil
                    if not texture and type(getTexture) == "function" then
                        local ok, value = pcall(getTexture, UNKNOWN_PIN_TEXTURE)
                        if ok then texture = value end
                    end
                    local itemTexture = known and icon.itemTexture or false
                    local poisonTexture = false
                    if known and icon.isKnownPoison and type(getTexture) == "function" then
                        local ok, value = pcall(getTexture, POISON_PIN_TEXTURE)
                        if ok then poisonTexture = value end
                    end

                    pins[#pins + 1] = pinId
                    pins[#pins + 1] = x
                    pins[#pins + 1] = y
                    pins[#pins + 1] = z
                    pins[#pins + 1] = texture or false
                    pins[#pins + 1] = itemTexture
                    pins[#pins + 1] = poisonTexture
                    pins[#pins + 1] = shown and true or false
                    pins[#pins + 1] = pointed
                    existing[idKey] = true
                    appended = appended + 1

                    if not tracedNativeWorldPinIds[idKey] then
                        tracedNativeWorldPinIds[idKey] = true
                        traceNativeWorldPin("status=appended item=" .. RAT_DROPPINGS_FULL_TYPE
                            .. " id=" .. idKey .. " seen=" .. tostring(seen)
                            .. " shown=" .. tostring(shown) .. " pointed=" .. tostring(pointed))
                    end
                end
            end
        end
    end
    return appended
end

local function wrapRatDroppingsWorldPins()
    local api = ViewpointForage
    if type(api) ~= "table" or type(api.found) ~= "function" then
        traceNativeWorldPin("status=fallback reason=viewpoint-forage-api-unavailable")
        return false
    end
    if api.chilaSedaRatDroppingsPinsWrapped then return true end

    local originalFound = api.found
    api.found = function(player, reach)
        local pins = originalFound(player, reach)
        if type(pins) ~= "table" then
            traceNativeWorldPin("status=fallback reason=forage-api-returned-" .. type(pins))
            return pins
        end
        local manager = getManager(player)
        local appended = appendRatDroppingsWorldPins(player, reach, pins, manager)
        if appended == 0 and not tracedNoRatWorldPin
                and manager and type(manager.worldObjectIcons) == "table" then
            tracedNoRatWorldPin = true
            traceNativeWorldPin("status=checked item=" .. RAT_DROPPINGS_FULL_TYPE .. " appended=0")
        end
        return pins
    end
    api.chilaSedaRatDroppingsPinsWrapped = true
    traceNativeWorldPin("status=installed item=" .. RAT_DROPPINGS_FULL_TYPE .. " source=worldObjectIcons")
    return true
end

local function rejectTargetPin(diagnostics, reason)
    if diagnostics then diagnostics.rejected[reason] = (diagnostics.rejected[reason] or 0) + 1 end
    return nil
end

local function targetPin(icon, bridge, centerX, centerY, width, height, diagnostics)
    if not icon or icon.isBeingRemoved or type(icon.onMouseDoubleClick) ~= "function" then
        return rejectTargetPin(diagnostics, "icon-unavailable")
    end
    if not iconIsSeen(icon) then return rejectTargetPin(diagnostics, "not-seen") end
    if iconAlpha(icon) <= 0 then return rejectTargetPin(diagnostics, "transparent") end
    local distance = icon.distanceToPlayer
    if type(distance) ~= "number" then return rejectTargetPin(diagnostics, "distance-unavailable") end
    if distance > MAX_REACH then return rejectTargetPin(diagnostics, "out-of-reach") end

    local x, y, z = icon.xCoord, icon.yCoord, icon.zCoord or 0
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
        return rejectTargetPin(diagnostics, "coordinates-unavailable")
    end
    -- ISForageIcon stores the tile corner; Viewpoint Foraging projects its centre.
    if icon.iconClass == "forageIcon" and x == math.floor(x) and y == math.floor(y) then
        x, y = x + 0.5, y + 0.5
    end
    local ok, inFront = pcall(bridge.projectNativeForagePin, x, y, z, PIN_LIFT)
    if not ok or inFront ~= true then
        if distance <= CLOSE_PIN_PROXIMITY_REACH then
            if diagnostics then diagnostics.closeFallback = diagnostics.closeFallback + 1 end
            return AIM_RADIUS * AIM_RADIUS + distance * distance, centerX, centerY, true
        end
        return rejectTargetPin(diagnostics, "camera-projection-rejected")
    end

    local okScreen, screenX, screenY = pcall(function()
        return bridge.nativeForagePinScreenX(), bridge.nativeForagePinScreenY()
    end)
    if not okScreen then
        if distance <= CLOSE_PIN_PROXIMITY_REACH then
            if diagnostics then diagnostics.closeFallback = diagnostics.closeFallback + 1 end
            return AIM_RADIUS * AIM_RADIUS + distance * distance, centerX, centerY, true
        end
        return rejectTargetPin(diagnostics, "screen-projection-error")
    end
    if type(screenX) ~= "number" or type(screenY) ~= "number"
            or screenX < 0 or screenX > width or screenY < 0 or screenY > height then
        if distance <= CLOSE_PIN_PROXIMITY_REACH then
            if diagnostics then diagnostics.closeFallback = diagnostics.closeFallback + 1 end
            return AIM_RADIUS * AIM_RADIUS + distance * distance, centerX, centerY, true
        end
        return rejectTargetPin(diagnostics, "projected-outside-screen")
    end
    local dx, dy = screenX - centerX, screenY - centerY
    local distanceSquared = dx * dx + dy * dy
    if distanceSquared <= AIM_RADIUS * AIM_RADIUS then
        return distanceSquared, screenX, screenY, false
    end
    if distance <= CLOSE_PIN_PROXIMITY_REACH then
        if diagnostics then diagnostics.closeFallback = diagnostics.closeFallback + 1 end
        return AIM_RADIUS * AIM_RADIUS + distance * distance, centerX, centerY, true
    end
    return rejectTargetPin(diagnostics, "outside-aim-radius")
end

local function eachNativeIcon(manager, callback)
    local categories = manager.iconCategories
    if type(categories) ~= "table" then
        for _, icon in pairs(manager.forageIcons or {}) do callback(icon) end
        return
    end
    for iconClass in pairs(categories) do
        local icons = manager[iconClass]
        if type(icons) == "table" then
            for _, icon in pairs(icons) do callback(icon) end
        end
    end
end

local function displayName(item)
    if not item then return nil end
    for _, methodName in ipairs({"getDisplayName", "getName"}) do
        local method = item[methodName]
        if type(method) == "function" then
            local ok, name = pcall(method, item)
            if ok and type(name) == "string" and name ~= "" then return name end
        end
    end
    return nil
end

local function foundItemName(icon)
    if icon and icon.identified then
        local itemList = icon.itemList
        local listHasItems = false
        if itemList and type(itemList.isEmpty) == "function" then
            local ok, empty = pcall(itemList.isEmpty, itemList)
            listHasItems = ok and empty ~= true
        end
        if listHasItems and type(itemList.get) == "function" then
            local ok, item = pcall(itemList.get, itemList, 0)
            if ok then
                local name = displayName(item)
                if name then return name end
            end
        end
        local name = displayName(icon.itemObj)
        if name then return name end
    end
    if type(getText) == "function" then
        local key = "UI_ChilaSeda_ViewpointNativeForageFound"
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return nil
end

local function aimedForagePin(manager)
    local diagnostics = { iconCount = 0, eligible = 0, closeFallback = 0, rejected = {} }
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.prepareNativeForagePins) ~= "function"
            or type(bridge.projectNativeForagePin) ~= "function" then
        warnOnce("native 3D pin projection is unavailable")
        return nil, "reason=pin-bridge-unavailable"
    end
    local ok, prepared = pcall(bridge.prepareNativeForagePins, 0)
    if not ok or prepared ~= true then return nil, "reason=pin-preparation-failed" end

    local okSize, width, height = pcall(function()
        return bridge.nativeForagePinScreenWidth(), bridge.nativeForagePinScreenHeight()
    end)
    if not okSize then return nil, "reason=screen-size-error" end
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then
        return nil, "reason=screen-size-unavailable"
    end
    local centerX, centerY = width / 2, height / 2
    local best, bestDistance
    eachNativeIcon(manager, function(icon)
        diagnostics.iconCount = diagnostics.iconCount + 1
        local distance, screenX, screenY, closeFallback =
            targetPin(icon, bridge, centerX, centerY, width, height, diagnostics)
        if distance then diagnostics.eligible = diagnostics.eligible + 1 end
        if distance and (not bestDistance or distance < bestDistance) then
            best = {
                icon = icon, screenX = screenX, screenY = screenY,
                closeFallback = closeFallback == true,
            }
            bestDistance = distance
        end
    end)
    if best then best.itemName = foundItemName(best.icon) end
    local reason = best and "selected" or "no-pin-passed-target-filters"
    local rejected = diagnostics.rejected
    local summary = "reason=" .. reason
        .. " icons=" .. tostring(diagnostics.iconCount)
        .. " eligible=" .. tostring(diagnostics.eligible)
        .. " closeFallback=" .. tostring(diagnostics.closeFallback)
        .. " rejectedNotSeen=" .. tostring(rejected["not-seen"] or 0)
        .. " rejectedTransparent=" .. tostring(rejected.transparent or 0)
        .. " rejectedOutOfReach=" .. tostring(rejected["out-of-reach"] or 0)
        .. " rejectedProjection=" .. tostring(rejected["camera-projection-rejected"] or 0)
        .. " rejectedScreenError=" .. tostring(rejected["screen-projection-error"] or 0)
        .. " rejectedScreen=" .. tostring(rejected["projected-outside-screen"] or 0)
        .. " rejectedAim=" .. tostring(rejected["outside-aim-radius"] or 0)
    if best then
        summary = summary .. " icon=" .. tostring(best.icon.iconID)
            .. " distance=" .. tostring(best.icon.distanceToPlayer)
            .. " screenX=" .. tostring(best.screenX) .. " screenY=" .. tostring(best.screenY)
            .. " targeting=" .. (best.closeFallback and "proximity" or "crosshair")
    end
    return best, summary
end

local function playerNumber(character)
    if not character then return nil end
    local ok, number = pcall(function()
        if type(character.getPlayerNum) ~= "function" then return nil end
        return character:getPlayerNum()
    end)
    return ok and type(number) == "number" and number or nil
end

local function sameCharacter(left, right)
    if left == right then return true end
    local leftNumber, rightNumber = playerNumber(left), playerNumber(right)
    return leftNumber ~= nil and rightNumber ~= nil and leftNumber == rightNumber
end

local function forageActionAlreadyQueued(icon)
    local queues = ISTimedActionQueue and ISTimedActionQueue.queues
    if type(queues) ~= "table" or not icon then return false end
    for _, timedQueue in pairs(queues) do
        local actions = timedQueue and timedQueue.queue
        local queueCharacter = timedQueue and timedQueue.character
        if type(actions) == "table"
                and (queueCharacter == nil or sameCharacter(queueCharacter, icon.character)) then
            for _, action in ipairs(actions) do
                local actionCharacter = action and action.character
                local actionPinId = action
                    and (action.ChilaSedaViewpointPinId or action.iconID)
                if action and action.Type == "ISForageAction"
                        and actionPinId ~= nil
                        and tostring(actionPinId) == tostring(icon.iconID)
                        and (actionCharacter == nil or sameCharacter(actionCharacter, icon.character)) then
                    return true
                end
            end
        end
    end
    return false
end

local function tagForagePickupAction(action, icon, mode)
    if action and action.Type == "ISForageAction" then
        action.ChilaSedaViewpointPinId = icon.iconID
        action.ChilaSedaViewpointPickupMode = mode
        if action.ChilaSedaViewpointLifecycleTraced then return end
        action.ChilaSedaViewpointLifecycleTraced = true
        for _, methodName in ipairs({ "isValid", "start", "complete", "perform", "stop" }) do
            local eventName = methodName
            local original = action[eventName]
            if type(original) == "function" then
                action[eventName] = function(self, ...)
                    local actionMode = self.ChilaSedaViewpointPickupMode or "unknown"
                    local pinId = self.ChilaSedaViewpointPinId or self.iconID
                    local results = { original(self, ...) }
                    if eventName == "isValid" then
                        local validity = tostring(results[1])
                        if self.ChilaSedaViewpointValidity ~= validity then
                            self.ChilaSedaViewpointValidity = validity
                            local running = "unknown"
                            if self.character and type(self.character.isRunning) == "function" then
                                local ok, value = pcall(self.character.isRunning, self.character)
                                if ok then running = tostring(value) end
                            end
                            tracePickupLifecycle("event=isValid result=" .. tostring(results[1])
                                .. " mode=" .. tostring(actionMode) .. " running=" .. running
                                .. " icon=" .. tostring(pinId))
                        end
                    else
                        tracePickupLifecycle("event=" .. eventName .. " mode=" .. tostring(actionMode)
                            .. " icon=" .. tostring(pinId))
                    end
                    if eventName == "complete" then
                        tracePickupLifecycle("event=complete-result result=" .. tostring(results[1])
                            .. " mode=" .. tostring(actionMode) .. " icon=" .. tostring(pinId))
                    end
                    return unpack(results)
                end
            end
        end
    end
end

local function queueNativePickup(target)
    local icon = target and target.icon
    if not icon or icon.isBeingRemoved or type(icon.onMouseDoubleClick) ~= "function" then return false end
    if forageActionAlreadyQueued(icon) then
        tracePickup("result=suppressed reason=already-queued icon=" .. tostring(icon.iconID))
        return true
    end
    local x, y = 0, 0
    if type(icon.getX) == "function" then
        local ok, value = pcall(icon.getX, icon)
        if ok and type(value) == "number" then x = value end
    end
    if type(icon.getY) == "function" then
        local ok, value = pcall(icon.getY, icon)
        if ok and type(value) == "number" then y = value end
    end
    local oldX, oldY = x, y
    local width = type(icon.getWidth) == "function" and select(2, pcall(icon.getWidth, icon)) or nil
    local height = type(icon.getHeight) == "function" and select(2, pcall(icon.getHeight, icon)) or nil
    if type(width) ~= "number" then width = 0 end
    if type(height) ~= "number" then height = 0 end
    x = target.screenX - width / 2
    y = target.screenY - height
    if type(icon.setX) == "function" then pcall(icon.setX, icon, x) end
    if type(icon.setY) == "function" then pcall(icon.setY, icon, y) end
    -- All distances use vanilla doForage so walkAdj validates reach and preserves queue behavior.
    local queue = ISTimedActionQueue
    local oldAdd = queue and queue.add
    local forageQueued = false
    if type(oldAdd) == "function" then
        queue.add = function(action, ...)
            if action and action.Type == "ISForageAction" then
                forageQueued = true
                tagForagePickupAction(action, icon, "vanilla")
            end
            return oldAdd(action, ...)
        end
    end
    local utilities = luautils
    local oldWalkAdj = utilities and utilities.walkAdj
    local walkAdjCalls, walkAdjResult = 0, nil
    local wrappedWalkAdj
    if type(oldWalkAdj) == "function" then
        wrappedWalkAdj = function(character, square, ...)
            walkAdjCalls = walkAdjCalls + 1
            local results = { oldWalkAdj(character, square, ...) }
            walkAdjResult = results[1]
            return unpack(results)
        end
        utilities.walkAdj = wrappedWalkAdj
    end
    local ok, err = pcall(icon.onMouseDoubleClick, icon, x, y)
    if queue and type(oldAdd) == "function" then queue.add = oldAdd end
    if utilities and utilities.walkAdj == wrappedWalkAdj then utilities.walkAdj = oldWalkAdj end
    if type(icon.setX) == "function" then pcall(icon.setX, icon, oldX) end
    if type(icon.setY) == "function" then pcall(icon.setY, icon, oldY) end
    if not ok then
        tracePickup("result=error mode=vanilla distance=" .. tostring(icon.distanceToPlayer)
            .. " reason=" .. tostring(err))
        warnOnce("native forage pickup callback failed: " .. tostring(err))
    else
        tracePickup("result=" .. (forageQueued and "queued" or "not-queued")
            .. " mode=vanilla distance=" .. tostring(icon.distanceToPlayer)
            .. " targeting=" .. (target.closeFallback and "proximity" or "crosshair")
            .. " walkAdjCalls=" .. tostring(walkAdjCalls)
            .. " walkAdj=" .. tostring(walkAdjResult) .. " icon=" .. tostring(icon.iconID))
    end
    return ok and forageQueued
end

local function aimedFindForPickup()
    if not nativeViewpointActive() then return nil, "reason=viewpoint-inactive" end
    if not nativeForageAvailable() then return nil, "reason=forage-api-unavailable" end
    if type(isGamePaused) == "function" and isGamePaused() then return nil, "reason=game-paused" end

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    if not player then return nil, "reason=player-unavailable" end
    local manager = getManager(player)
    if not manager then return nil, "reason=search-manager-unavailable" end
    if manager.isSearchMode ~= true then return nil, "reason=search-mode-inactive" end

    local okVehicle, vehicle = pcall(player.getVehicle, player)
    if not okVehicle then return nil, "reason=vehicle-state-error" end
    if vehicle ~= nil then return nil, "reason=player-in-vehicle" end

    return aimedForagePin(manager)
end

local function pickupAimedFind()
    local selected, diagnostic = aimedFindForPickup()
    if not selected then
        tracePickup("result=no-target mode=aimed " .. tostring(diagnostic or "reason=unknown"))
        return
    end
    tracePickup("target=selected item=" .. tostring(selected.itemName or "unknown")
        .. " icon=" .. tostring(selected.icon and selected.icon.iconID)
        .. " distance=" .. tostring(selected.icon and selected.icon.distanceToPlayer)
        .. " screenX=" .. tostring(selected.screenX) .. " screenY=" .. tostring(selected.screenY)
        .. " targeting=" .. (selected.closeFallback and "proximity" or "crosshair")
        .. " " .. tostring(diagnostic or "reason=selected"))
    queueNativePickup(selected)
end

local function pickupKeyName()
    local key = ChilaSedaViewpointNativeForagePickupKey
    if type(key) ~= "number" or key <= 0 then return nil end
    if type(ChilaSedaViewpointFormatNativeActionKey) == "function" then
        return ChilaSedaViewpointFormatNativeActionKey(key)
    end
    local name
    if Keyboard and type(Keyboard.getKeyName) == "function" then
        local ok, value = pcall(Keyboard.getKeyName, key)
        if ok and type(value) == "string" and value ~= "" then name = value end
    end
    return "Alt+" .. (name or tostring(key))
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
    if type(ChilaSedaViewpointNativeActionModifierMatches) == "function" then
        local ok, matches = pcall(ChilaSedaViewpointNativeActionModifierMatches)
        return ok and matches == true
    end
    return defaultModifierIsDown()
end

local function consumeVanillaKeyRelease(key)
    if GameKeyboard and type(GameKeyboard.eatKeyPress) == "function" then
        pcall(GameKeyboard.eatKeyPress, key)
    end
end

local PickupPrompt = ISUIElement:derive("ChilaSedaViewpointNativeForagePickupPrompt")

function PickupPrompt:new()
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorTop = true, true
    o.target = nil
    o.nextTargetUpdate = 0
    return o
end

function PickupPrompt:onMouseDown() return false end
function PickupPrompt:onMouseUp() return false end
function PickupPrompt:onRightMouseDown() return false end
function PickupPrompt:onRightMouseUp() return false end

function PickupPrompt:prerender()
    local now = type(getTimestampMs) == "function"
        and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < self.nextTargetUpdate then return end
    -- Viewpoint moves the projected pin with each camera frame; refresh at roughly
    -- render rate instead of letting a throttled sample lag behind the camera.
    self.nextTargetUpdate = now + PROMPT_REFRESH_MS
    self.target = pickupKeyName() and aimedFindForPickup() or nil
end

function PickupPrompt:render()
    local target = self.target
    local keyName = pickupKeyName()
    if not target or not keyName then return end

    local textKey = "UI_ChilaSeda_ViewpointNativeForagePrompt"
    local text = keyName
    if type(getText) == "function" then
        local ok, translated = pcall(getText, textKey, keyName)
        if ok and type(translated) == "string" and translated ~= "" and translated ~= textKey then
            text = translated
        end
    end
    local nameText = target.itemName
    local font = UIFont and (UIFont.Small or UIFont.Medium) or nil
    local function textWidth(value)
        if type(getTextManager) == "function" and font then
            local ok, measured = pcall(function()
                return getTextManager():MeasureStringX(font, value)
            end)
            if ok and type(measured) == "number" then return measured + 12 end
        end
        return math.max(42, #value * 7 + 12)
    end

    local width = textWidth(text)
    if type(getTextManager) == "function" and UIFont and UIFont.Small then
        width = math.max(42, width)
    end
    local height = 20
    local core = getCore and getCore() or nil
    local screenWidth = core and core:getScreenWidth() or nil
    local function centeredX(textWidthValue)
        local x = target.screenX - textWidthValue / 2
        if type(screenWidth) == "number" then
            x = math.max(4, math.min(x, math.max(4, screenWidth - textWidthValue - 4)))
        end
        return x
    end

    local keyX = centeredX(width)
    local keyY = math.max(4, target.screenY - height - PICKUP_PROMPT_GAP)
    self:drawRect(keyX, keyY, width, height, 0.82, 0.02, 0.02, 0.02)
    self:drawTextCentre(text, keyX + width / 2, keyY + 2, 1, 0.86, 0.35, 1, font)

    if type(nameText) == "string" and nameText ~= "" then
        local nameWidth = textWidth(nameText)
        local nameX = centeredX(nameWidth)
        local nameY = math.max(4, keyY - height - 2)
        self:drawRect(nameX, nameY, nameWidth, height, 0.82, 0.02, 0.02, 0.02)
        self:drawTextCentre(nameText, nameX + nameWidth / 2, nameY + 2, 1, 1, 1, 1, font)
    end
end

local function createPickupPrompt()
    if pickupPrompt then pickupPrompt:removeFromUIManager() end
    pickupPrompt = PickupPrompt:new()
    pickupPrompt:initialise()
    pickupPrompt:addToUIManager()
    pcall(function() pickupPrompt:backMost() end)
end

local function onKeyStartPressed(key)
    local pickupKey = ChilaSedaViewpointNativeForagePickupKey
    if type(pickupKey) ~= "number" or pickupKey <= 0 or key ~= pickupKey then return end
    local modifierMatches = configuredModifierIsDown()
    local keyLabel = pickupKeyName()
    if not modifierMatches then
        tracePickupInput("result=modifier-rejected keyCode=" .. tostring(key)
            .. " key=" .. tostring(keyLabel or key)
            .. " configured=" .. tostring(ChilaSedaViewpointNativeActionModifier or "ALT")
            .. " modifierDown=false", true)
        return
    end
    tracePickupInput("result=accepted keyCode=" .. tostring(key)
        .. " key=" .. tostring(keyLabel or key)
        .. " configured=" .. tostring(ChilaSedaViewpointNativeActionModifier or "ALT")
        .. " modifierDown=true")
    consumeVanillaKeyRelease(key)
    pickupAimedFind()
end

if Events and Events.OnKeyStartPressed and type(Events.OnKeyStartPressed.Add) == "function" then
    Events.OnKeyStartPressed.Add(onKeyStartPressed)
end
wrapRatDroppingsWorldPins()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(function()
        wrapRatDroppingsWorldPins()
        createPickupPrompt()
    end)
end
createPickupPrompt()

print(TAG .. "native 3D search pickup key handler and pin prompt loaded")
