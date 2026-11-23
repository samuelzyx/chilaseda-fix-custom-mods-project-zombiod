require "ISUI/ISUIElement"
require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "ISUI/Animal/ISAnimalContextMenu"
require "Vehicles/TimedActions/ISPathFindAction"
require "TimedActions/Animals/ISButcherAnimal"
require "TimedActions/ISDropItemAction"

local TAG = "[ChilaSeda_ViewpointAnimalCorpsePrompt] "
local AIM_RADIUS = 120
local MAX_WORLD_DISTANCE = 8
local SEARCH_RADIUS = 6
local SCREEN_LIFT = 0.2
local PROMPT_GAP = 84
local REFRESH_MS = 32
local MAX_ACTION_TRACE_LINES = 48
local actionTraceCount = 0
local prompt

local function traceAction(message)
    if actionTraceCount >= MAX_ACTION_TRACE_LINES then return end
    actionTraceCount = actionTraceCount + 1
    print(TAG .. "actionTrace=" .. tostring(actionTraceCount) .. " " .. message)
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

local function targetBody(player)
    if not viewpointActive() then return nil end
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.prepareNativeForagePins) ~= "function"
            or type(bridge.projectNativeForagePin) ~= "function" then
        return nil
    end
    local playerNum = safeMethod(player, "getPlayerNum") or 0
    local prepared, ready = pcall(bridge.prepareNativeForagePins, playerNum)
    if not prepared or ready ~= true then return nil end
    local sizeOk, width, height = pcall(function()
        return bridge.nativeForagePinScreenWidth(), bridge.nativeForagePinScreenHeight()
    end)
    if not sizeOk or type(width) ~= "number" or type(height) ~= "number"
            or width <= 0 or height <= 0 then
        return nil
    end

    local px, py = safeMethod(player, "getX"), safeMethod(player, "getY")
    local pz = safeMethod(player, "getZ") or 0
    if type(px) ~= "number" or type(py) ~= "number" then return nil end
    local cell = safeMethod(player, "getCell") or (type(getCell) == "function" and getCell())
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end

    local originX, originY, originZ = math.floor(px), math.floor(py), math.floor(pz)
    local centerX, centerY = width / 2, height / 2
    local best, bestDistance
    local seen = {}
    for dx = -SEARCH_RADIUS, SEARCH_RADIUS do
        for dy = -SEARCH_RADIUS, SEARCH_RADIUS do
            if dx * dx + dy * dy <= SEARCH_RADIUS * SEARCH_RADIUS then
                local squareOk, square = pcall(cell.getGridSquare, cell,
                    originX + dx, originY + dy, originZ)
                if squareOk and square and type(square.getStaticMovingObjects) == "function" then
                    local objectsOk, objects = pcall(square.getStaticMovingObjects, square)
                    if objectsOk and objects then
                        for index = 0, objects:size() - 1 do
                            local body = objects:get(index)
                            if body and not seen[body] and isAnimalCorpse(body) then
                                seen[body] = true
                                local bx = safeMethod(body, "getX")
                                local by = safeMethod(body, "getY")
                                local bz = safeMethod(body, "getZ") or 0
                                if type(bx) == "number" and type(by) == "number" then
                                    local worldDx, worldDy = bx - px, by - py
                                    local worldDistance = worldDx * worldDx + worldDy * worldDy
                                    if worldDistance <= MAX_WORLD_DISTANCE * MAX_WORLD_DISTANCE then
                                        local projectOk, inFront = pcall(
                                            bridge.projectNativeForagePin, bx, by, bz, SCREEN_LIFT)
                                        if projectOk and inFront == true then
                                            local screenOk, screenX, screenY = pcall(function()
                                                return bridge.nativeForagePinScreenX(),
                                                    bridge.nativeForagePinScreenY()
                                            end)
                                            if screenOk and type(screenX) == "number"
                                                    and type(screenY) == "number"
                                                    and screenX >= 0 and screenX <= width
                                                    and screenY >= 0 and screenY <= height then
                                                local screenDx, screenDy = screenX - centerX,
                                                    screenY - centerY
                                                local screenDistance = screenDx * screenDx
                                                    + screenDy * screenDy
                                                if screenDistance <= AIM_RADIUS * AIM_RADIUS
                                                        and (not bestDistance or screenDistance < bestDistance) then
                                                    best = {
                                                        body = body,
                                                        player = player,
                                                        canButcher = corpseCanBeButchered(body, player),
                                                        canGetBones = safeMethod(body, "isAnimalSkeleton") == true,
                                                        screenX = screenX,
                                                        screenY = screenY,
                                                        name = bodyName(body),
                                                    }
                                                    bestDistance = screenDistance
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
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
    local current = targetBody(player)
    if current then
        traceAction("target=live name=" .. tostring(current.name))
        return current
    end
    local cached = prompt and prompt.target
    if cached and cached.player == player and isAnimalCorpse(cached.body) then
        traceAction("target=prompt-cache name=" .. tostring(cached.name))
        return cached
    end
    traceAction("target=none reason=outside-range-or-camera-projection")
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
        if ok and type(name) == "string" and name ~= "" then return "Ctrl+" .. name end
    end
    return "Ctrl+" .. tostring(key)
end

local function controlIsDown()
    if Keyboard and type(Keyboard.isKeyDown) == "function" then
        local left, right = Keyboard.KEY_LCONTROL, Keyboard.KEY_RCONTROL
        if left ~= nil then
            local ok, down = pcall(Keyboard.isKeyDown, left)
            if ok and down then return true end
        end
        if right ~= nil then
            local ok, down = pcall(Keyboard.isKeyDown, right)
            if ok and down then return true end
        end
    end
    if type(isCtrlKeyDown) == "function" then
        local ok, down = pcall(isCtrlKeyDown)
        return ok and down == true
    end
    return false
end

local function configuredModifierIsDown()
    if type(ChilaSedaViewpointAnimalCorpseActionModifierMatches) == "function" then
        local ok, matches = pcall(ChilaSedaViewpointAnimalCorpseActionModifierMatches)
        return ok and matches == true
    end
    return controlIsDown()
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
    local modifierMatches = configuredModifierIsDown()
    traceAction("key=matched code=" .. tostring(key)
        .. " configured=" .. tostring(ChilaSedaViewpointAnimalCorpseActionModifier or "CTRL")
        .. " modifierDown=" .. tostring(modifierMatches))
    if not modifierMatches then return end
    if GameKeyboard and type(GameKeyboard.eatKeyPress) == "function" then
        pcall(GameKeyboard.eatKeyPress, key)
    end
    local player = playerForPrompt()
    if not player then
        traceAction("key=matched result=skipped reason=player-unavailable")
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

if ISDropItemAction and type(ISDropItemAction.perform) == "function"
        and not ISDropItemAction.ChilaSedaButcherDestinationHalo then
    local originalDropPerform = ISDropItemAction.perform
    ISDropItemAction.perform = function(action, ...)
        local result = originalDropPerform(action, ...)
        local item = action and action.item
        local player = item and pendingFloorNotices[item]
        if player then
            pendingFloorNotices[item] = nil
            notifyDroppedItem(player, item)
        end
        return result
    end
    ISDropItemAction.ChilaSedaButcherDestinationHalo = true
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

if ISButcherAnimal and type(ISButcherAnimal.complete) == "function"
        and not ISButcherAnimal.ChilaSedaSelectedBackpackRoute then
    local originalComplete = ISButcherAnimal.complete
    ISButcherAnimal.complete = function(action, ...)
        local player = action and action.character
        local inventory = player and safeMethod(player, "getInventory")
        local before = snapshotItems(inventory)
        local result = originalComplete(action, ...)
        if result == true then routeNewButcherItems(player, before) end
        return result
    end
    ISButcherAnimal.ChilaSedaSelectedBackpackRoute = true
end

if Events and Events.OnKeyStartPressed and type(Events.OnKeyStartPressed.Add) == "function" then
    Events.OnKeyStartPressed.Add(onKeyStartPressed)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(createPrompt)
end
createPrompt()

print(TAG .. "animal corpse prompt and selected-backpack butchering route loaded")
