-- Persist Inventory Tetris container-grid collapse state and return handheld
-- light sources to the container they came from after they are unequipped.
-- This is a local integration; the Workshop files remain untouched.

local TRACE_TAG = "[ChilaSeda_InventoryTetrisSessionState]"
local STATE_KEY = "ChilaSedaInventoryTetrisSessionState"
local LIGHT_ORIGIN_KEY = "ChilaSedaInventoryTetrisLightOrigin"
local MAX_TRACE_LINES = 128
local MAX_CONTAINERS = 256
local MAX_CONTAINER_DEPTH = 12

local traceLines = 0
local lightOrigins = {}
local installed = false

local function trace(message)
    if traceLines >= MAX_TRACE_LINES then
        return
    end
    traceLines = traceLines + 1
    print(TRACE_TAG .. " " .. tostring(message))
end

local function property(object, name)
    if object == nil then
        return nil
    end
    local ok, value = pcall(function()
        return object[name]
    end)
    if ok then
        return value
    end
    return nil
end

local function safeMethod(object, name, ...)
    local method = property(object, name)
    if type(method) ~= "function" then
        return nil
    end
    local ok, first, second = pcall(method, object, ...)
    if not ok then
        return nil
    end
    return first, second
end

local function iterateList(list, callback)
    if list == nil then
        return
    end
    if type(list) == "table" then
        for _, value in pairs(list) do
            callback(value)
        end
        return
    end
    local size = safeMethod(list, "size")
    if type(size) ~= "number" then
        return
    end
    for index = 0, size - 1 do
        callback(safeMethod(list, "get", index))
    end
end

local function getContainerStore(ui)
    local inventory = ui and ui.inventory
    local player = ui and ui.player
    if inventory == nil then
        return nil, nil, "container-missing"
    end

    local playerInventory = safeMethod(player, "getInventory")
    if playerInventory ~= nil and inventory == playerInventory then
        return player, "grid:player-root", nil
    end

    local containingItem = safeMethod(inventory, "getContainingItem")
    if containingItem ~= nil then
        return containingItem, "grid:contained-item", nil
    end

    local parent = safeMethod(inventory, "getParent")
    if parent ~= nil then
        local containerType = safeMethod(inventory, "getType") or "unknown"
        return parent, "grid:object:" .. tostring(containerType), nil
    end

    if player ~= nil and playerInventory == nil then
        return player, "grid:player-root", nil
    end

    return nil, nil, "no-stable-container-owner"
end

local function getStoredCollapsed(owner, key)
    local modData = safeMethod(owner, "getModData")
    if type(modData) ~= "table" then
        return nil
    end
    local state = modData[STATE_KEY]
    if type(state) ~= "table" or type(state.collapsed) ~= "table" then
        return nil
    end
    local value = state.collapsed[key]
    if type(value) == "boolean" then
        return value
    end
    return nil
end

local function saveCollapsed(owner, key, collapsed)
    local modData = safeMethod(owner, "getModData")
    if type(modData) ~= "table" then
        return false, "moddata-unavailable"
    end
    local state = modData[STATE_KEY]
    if type(state) ~= "table" then
        state = { version = 1, collapsed = {} }
        modData[STATE_KEY] = state
    end
    if type(state.collapsed) ~= "table" then
        state.collapsed = {}
    end
    state.version = 1
    state.collapsed[key] = collapsed == true
    return true
end

local function bindCollapseState(ui)
    local owner, key, reason = getContainerStore(ui)
    if owner == nil or key == nil then
        ui._chilaTetrisCollapseReason = reason or "no-stable-container-owner"
        return
    end

    ui._chilaTetrisCollapseOwner = owner
    ui._chilaTetrisCollapseKey = key
    ui._chilaTetrisRestoreCollapsed = getStoredCollapsed(owner, key) == true
    if ui._chilaTetrisRestoreCollapsed then
        ui.isGridCollapsed = true
    end
end

local function persistCollapseState(ui, collapsed)
    local owner = ui and ui._chilaTetrisCollapseOwner
    local key = ui and ui._chilaTetrisCollapseKey
    if owner == nil or key == nil then
        trace("grid.save result=fallback reason=" .. tostring(ui and ui._chilaTetrisCollapseReason or "no-stable-container-owner"))
        return
    end
    if collapsed == nil then
        collapsed = ui.isGridCollapsed == true
    end
    local ok, reason = saveCollapsed(owner, key, collapsed == true)
    if ok then
        trace("grid.save result=stored key=" .. tostring(key) .. " collapsed=" .. tostring(collapsed == true))
    else
        trace("grid.save result=fallback key=" .. tostring(key) .. " reason=" .. tostring(reason))
    end
end

local function itemModData(item, create)
    local data = safeMethod(item, "getModData")
    if type(data) ~= "table" then
        return nil
    end
    if create and type(data[LIGHT_ORIGIN_KEY]) ~= "table" then
        data[LIGHT_ORIGIN_KEY] = { version = 1 }
    end
    local origin = data[LIGHT_ORIGIN_KEY]
    if type(origin) == "table" then
        return origin, data
    end
    return nil, data
end

local function clearLightOrigin(item)
    local origin, modData = itemModData(item, false)
    if modData ~= nil then
        modData[LIGHT_ORIGIN_KEY] = nil
    end
    lightOrigins[item] = nil
end

local function isHandheldLight(item)
    local strength = safeMethod(item, "getLightStrength")
    if type(strength) == "number" and strength > 0 then
        return true
    end
    local fullType = safeMethod(item, "getFullType")
    if type(fullType) == "string" then
        return string.find(fullType, "Flashlight", 1, true) ~= nil
            or string.find(fullType, "HandTorch", 1, true) ~= nil
            or string.find(fullType, "Lantern", 1, true) ~= nil
    end
    return false
end

local function describeOrigin(source, character)
    if source == nil then
        return nil, "source-container-missing"
    end
    if source == safeMethod(character, "getInventory") then
        return nil, "source-is-main-inventory"
    end

    local containerType = safeMethod(source, "getType") or "unknown"
    local containingItem = safeMethod(source, "getContainingItem")
    if containingItem ~= nil then
        local itemID = safeMethod(containingItem, "getID")
        local fullType = safeMethod(containingItem, "getFullType")
        if type(itemID) == "number" and itemID > 0 then
            return {
                kind = "item",
                itemID = itemID,
                itemType = type(fullType) == "string" and fullType or nil,
                containerType = tostring(containerType),
            }
        end
        return nil, "containing-item-id-unavailable"
    end

    local parent = safeMethod(source, "getParent")
    if parent == nil then
        return nil, "source-owner-unavailable"
    end
    local descriptor = {
        kind = "object",
        containerType = tostring(containerType),
    }
    local x = safeMethod(parent, "getX")
    local y = safeMethod(parent, "getY")
    local z = safeMethod(parent, "getZ")
    if type(x) == "number" and type(y) == "number" and type(z) == "number" then
        descriptor.x = x
        descriptor.y = y
        descriptor.z = z
    end
    local parentID = safeMethod(parent, "getId") or safeMethod(parent, "getID")
    if type(parentID) == "number" and parentID > 0 then
        descriptor.parentID = parentID
    end
    local sprite = safeMethod(parent, "getSprite")
    local spriteName = safeMethod(sprite, "getName")
    if type(spriteName) == "string" then
        descriptor.spriteName = spriteName
    end
    if descriptor.x ~= nil or descriptor.parentID ~= nil then
        return descriptor
    end
    return nil, "source-owner-has-no-stable-id"
end

local function readLightOrigin(item)
    local origin = itemModData(item, false)
    if type(origin) == "table" and (origin.kind == "item" or origin.kind == "object") then
        return origin
    end
    return nil
end

local function appendContainer(containers, seen, container, depth)
    if container == nil or seen[container] or #containers >= MAX_CONTAINERS then
        return
    end
    seen[container] = true
    containers[#containers + 1] = container
    if depth >= MAX_CONTAINER_DEPTH then
        return
    end
    local items = safeMethod(container, "getItems")
    iterateList(items, function(item)
        local nested = safeMethod(item, "getInventory")
        if nested ~= nil and nested ~= container then
            appendContainer(containers, seen, nested, depth + 1)
        end
    end)
end

local function collectAccessibleContainers(character)
    local containers = {}
    local seen = {}
    local root = safeMethod(character, "getInventory")
    appendContainer(containers, seen, root, 0)

    local playerNum = safeMethod(character, "getPlayerNum") or 0
    if type(getPlayerLoot) == "function" then
        local ok, loot = pcall(getPlayerLoot, playerNum)
        if ok and loot ~= nil then
            local pane = property(loot, "inventoryPane")
            appendContainer(containers, seen, property(pane, "inventory"), 0)
        end
    end
    if type(getPlayerInventory) == "function" then
        local ok, inventoryUI = pcall(getPlayerInventory, playerNum)
        if ok and inventoryUI ~= nil then
            local pane = property(inventoryUI, "inventoryPane")
            appendContainer(containers, seen, property(pane, "inventory"), 0)
        end
    end

    local menu = ISInventoryPaneContextMenu
    local getContainers = property(menu, "getContainers")
    if type(getContainers) == "function" then
        local ok, list = pcall(getContainers, character)
        if ok and list ~= nil then
            iterateList(list, function(container)
                appendContainer(containers, seen, container, 0)
            end)
        end
    end
    return containers
end

local function isAccessible(container, character, candidates)
    if container == nil then
        return false
    end
    if container == safeMethod(character, "getInventory") then
        return true
    end
    if safeMethod(container, "isInCharacterInventory", character) == true then
        return true
    end
    for _, candidate in ipairs(candidates) do
        if candidate == container then
            return true
        end
    end
    return false
end

local function matchesOrigin(container, descriptor)
    if safeMethod(container, "getType") ~= descriptor.containerType then
        return false
    end
    if descriptor.kind == "item" then
        local owner = safeMethod(container, "getContainingItem")
        if owner == nil or safeMethod(owner, "getID") ~= descriptor.itemID then
            return false
        end
        if descriptor.itemType ~= nil and safeMethod(owner, "getFullType") ~= descriptor.itemType then
            return false
        end
        return true
    end
    if descriptor.kind == "object" then
        local parent = safeMethod(container, "getParent")
        if parent == nil then
            return false
        end
        if descriptor.x ~= nil then
            if safeMethod(parent, "getX") ~= descriptor.x
                or safeMethod(parent, "getY") ~= descriptor.y
                or safeMethod(parent, "getZ") ~= descriptor.z then
                return false
            end
            if descriptor.spriteName ~= nil then
                local sprite = safeMethod(parent, "getSprite")
                if safeMethod(sprite, "getName") ~= descriptor.spriteName then
                    return false
                end
            end
            return true
        end
        local parentID = safeMethod(parent, "getId") or safeMethod(parent, "getID")
        return descriptor.parentID ~= nil and parentID == descriptor.parentID
    end
    return false
end

local function resolveOrigin(character, descriptor, candidates)
    if type(descriptor) ~= "table" then
        return nil
    end
    for _, container in ipairs(candidates) do
        if matchesOrigin(container, descriptor) then
            return container
        end
    end
    return nil
end

local function reportRestoredTransfer(action, succeeded)
    local record = action and action._chilaTetrisLightReturn
    if not record or record.reported then
        return
    end
    record.reported = true
    local item = record.item
    if succeeded then
        clearLightOrigin(item)
        trace("light-return result=stored item=" .. tostring(record.itemType) .. " container=" .. tostring(record.containerType))
    else
        trace("light-return result=fallback item=" .. tostring(record.itemType) .. " reason=transfer-did-not-reach-origin; item-remains-safe")
    end
end

local function queueLightReturn(unequipAction)
    local item = unequipAction and unequipAction.item
    local character = unequipAction and unequipAction.character
    if item == nil or character == nil or not isHandheldLight(item) then
        return
    end
    if unequipAction.reason == "drop" or unequipAction.reason == "place" then
        clearLightOrigin(item)
        trace("light-return result=skipped reason=" .. tostring(unequipAction.reason))
        return
    end

    local runtimeOrigin = lightOrigins[item]
    local descriptor = runtimeOrigin and runtimeOrigin.descriptor or readLightOrigin(item)
    if runtimeOrigin == nil and descriptor == nil then
        return
    end

    local currentContainer = safeMethod(item, "getContainer")
    local mainInventory = safeMethod(character, "getInventory")
    if currentContainer == nil or mainInventory == nil then
        trace("light-return result=fallback reason=current-container-unavailable; item-remains-safe")
        return
    end

    local candidates = collectAccessibleContainers(character)
    local destination = runtimeOrigin and runtimeOrigin.container or nil
    if not isAccessible(destination, character, candidates) then
        destination = resolveOrigin(character, descriptor, candidates)
    end
    if destination == nil then
        trace("light-return result=fallback reason=origin-not-accessible; item-remains-in-current-container")
        return
    end
    if destination == currentContainer then
        clearLightOrigin(item)
        trace("light-return result=already-at-origin container=" .. tostring(safeMethod(destination, "getType")))
        return
    end

    local transferClass = ISInventoryTransferAction
    local queueClass = ISTimedActionQueue
    if transferClass == nil or type(property(transferClass, "new")) ~= "function"
        or queueClass == nil or type(property(queueClass, "addAfter")) ~= "function" then
        trace("light-return result=fallback reason=transfer-api-unavailable; item-remains-safe")
        return
    end

    local okCreate, transfer = pcall(transferClass.new, transferClass, character, item, currentContainer, destination, 10)
    if not okCreate or transfer == nil then
        trace("light-return result=fallback reason=transfer-action-create-failed; item-remains-safe")
        return
    end
    transfer._chilaTetrisLightReturn = {
        item = item,
        itemType = safeMethod(item, "getFullType") or "unknown",
        containerType = safeMethod(destination, "getType") or "unknown",
    }
    local okQueue, queue = pcall(queueClass.addAfter, unequipAction, transfer)
    if not okQueue or queue == nil then
        trace("light-return result=fallback reason=action-queue-rejected; item-remains-safe")
        return
    end
    trace("light-return result=queued item=" .. tostring(transfer._chilaTetrisLightReturn.itemType)
        .. " container=" .. tostring(transfer._chilaTetrisLightReturn.containerType))
end

local function installGridHooks()
    local ok, uiClass = pcall(require, "InventoryTetris/UI/Container/ItemGridContainerUI")
    if not ok or type(uiClass) ~= "table" then
        return false, "tetris-grid-ui-unavailable"
    end
    if uiClass._chilaSedaSessionStateInstalled then
        return true
    end

    local originalNew = uiClass.new
    local originalInitialise = uiClass.initialise
    local originalCollapseClick = uiClass.onCollapseButtonClick
    if type(originalNew) ~= "function" or type(originalInitialise) ~= "function"
        or type(originalCollapseClick) ~= "function" then
        return false, "tetris-grid-methods-unavailable"
    end

    uiClass.new = function(self, inventory, inventoryPane, playerNum, containerDefOverride)
        local ui = originalNew(self, inventory, inventoryPane, playerNum, containerDefOverride)
        if ui ~= nil then
            bindCollapseState(ui)
        end
        return ui
    end

    uiClass.initialise = function(self, ...)
        local result = originalInitialise(self, ...)
        if self._chilaTetrisRestoreCollapsed == true and self.isGridCollapsed == true then
            self._chilaTetrisRestoreCollapsed = nil
            local button = self.collapseButton
            if button and type(property(button, "setTitle")) == "function" then
                pcall(button.setTitle, button, ">")
            end
            trace("grid.restore result=restored key=" .. tostring(self._chilaTetrisCollapseKey))
        end
        return result
    end

    uiClass.onCollapseButtonClick = function(self, button)
        local nextState = self.isGridCollapsed ~= true
        -- Tetris rebuilds the container UI inside this original method. Save
        -- first so the replacement widget can restore the intended state.
        persistCollapseState(self, nextState)
        local result = originalCollapseClick(self, button)
        if self.isGridCollapsed ~= nextState then
            persistCollapseState(self, self.isGridCollapsed == true)
        end
        return result
    end

    uiClass._chilaSedaSessionStateInstalled = true
    trace("grid-hooks result=installed api=ItemGridContainerUI")
    return true
end

local function installLightHooks()
    if type(ISEquipWeaponAction) == "table" and not ISEquipWeaponAction._chilaSedaSessionStateInstalled then
        local actionClass = ISEquipWeaponAction
        local originalNew = actionClass.new
        local originalComplete = actionClass.complete
        if type(originalNew) == "function" and type(originalComplete) == "function" then
            actionClass.new = function(self, character, item, ...)
                local action = originalNew(self, character, item, ...)
                if action ~= nil and isHandheldLight(item) then
                    local source = safeMethod(item, "getContainer")
                    local descriptor, reason = describeOrigin(source, character)
                    local sourceType = safeMethod(source, "getType")
                    local transientSource = sourceType == "floor" or sourceType == "TradeUI"
                    local clearReason = source == safeMethod(character, "getInventory")
                        and "equipped-from-main-inventory"
                        or (transientSource and "source-is-transient" or nil)
                    action._chilaTetrisOriginCandidate = {
                        container = source,
                        descriptor = descriptor,
                        reason = reason,
                        clear = clearReason ~= nil,
                        clearReason = clearReason,
                    }
                end
                return action
            end

            actionClass.complete = function(self, ...)
                local result = originalComplete(self, ...)
                local candidate = self._chilaTetrisOriginCandidate
                if result and candidate ~= nil then
                    local item = self.item
                    local character = self.character
                    local primary = safeMethod(character, "getPrimaryHandItem")
                    local secondary = safeMethod(character, "getSecondaryHandItem")
                    if primary == item or secondary == item then
                        if candidate.clear then
                            clearLightOrigin(item)
                            trace("light-origin result=cleared reason=" .. tostring(candidate.clearReason or "no-restorable-origin"))
                        elseif candidate.descriptor ~= nil or candidate.container ~= nil then
                            local origin, modData = itemModData(item, candidate.descriptor ~= nil)
                            if candidate.descriptor ~= nil and modData ~= nil then
                                modData[LIGHT_ORIGIN_KEY] = candidate.descriptor
                            elseif modData ~= nil then
                                modData[LIGHT_ORIGIN_KEY] = nil
                            end
                            lightOrigins[item] = {
                                container = candidate.container,
                                descriptor = candidate.descriptor,
                            }
                            trace("light-origin result=recorded kind=" .. tostring(candidate.descriptor and candidate.descriptor.kind or "session")
                                .. " container=" .. tostring(safeMethod(candidate.container, "getType") or "unknown"))
                        else
                            clearLightOrigin(item)
                            trace("light-origin result=fallback reason=" .. tostring(candidate.reason or "unstable-source"))
                        end
                    else
                        trace("light-origin result=skipped reason=equip-did-not-finish")
                    end
                    self._chilaTetrisOriginCandidate = nil
                end
                return result
            end
            actionClass._chilaSedaSessionStateInstalled = true
            trace("light-equip-hook result=installed")
        end
    end

    if type(ISUnequipAction) == "table" and not ISUnequipAction._chilaSedaSessionStateInstalled then
        local actionClass = ISUnequipAction
        local originalPerform = actionClass.perform
        if type(originalPerform) == "function" then
            actionClass.perform = function(self, ...)
                queueLightReturn(self)
                return originalPerform(self, ...)
            end
            actionClass._chilaSedaSessionStateInstalled = true
            trace("light-unequip-hook result=installed")
        end
    end

    if type(ISInventoryTransferAction) == "table" and not ISInventoryTransferAction._chilaSedaSessionStateInstalled then
        local actionClass = ISInventoryTransferAction
        local originalIsValid = actionClass.isValid
        local originalPerform = actionClass.perform
        local originalStop = actionClass.stop
        if type(originalIsValid) == "function" then
            actionClass.isValid = function(self, ...)
                local result = originalIsValid(self, ...)
                if self._chilaTetrisLightReturn ~= nil and result ~= true then
                    reportRestoredTransfer(self, false)
                    trace("light-return result=fallback reason=transfer-validation-failed; item-remains-safe")
                end
                return result
            end
        end
        if type(originalPerform) == "function" then
            actionClass.perform = function(self, ...)
                local record = self._chilaTetrisLightReturn
                local result = originalPerform(self, ...)
                if record ~= nil then
                    reportRestoredTransfer(self, safeMethod(record.item, "getContainer") == self.destContainer)
                end
                return result
            end
        end
        if type(originalStop) == "function" then
            actionClass.stop = function(self, ...)
                if self._chilaTetrisLightReturn ~= nil then
                    reportRestoredTransfer(self, false)
                end
                return originalStop(self, ...)
            end
        end
        if type(originalIsValid) == "function" or type(originalPerform) == "function" or type(originalStop) == "function" then
            actionClass._chilaSedaSessionStateInstalled = true
        end
    end
end

local function install()
    local gridOk, gridReason = installGridHooks()
    installLightHooks()
    if gridOk then
        installed = true
    elseif not installed then
        trace("install result=partial reason=" .. tostring(gridReason))
    end
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(install)
end
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(install)
end

install()
