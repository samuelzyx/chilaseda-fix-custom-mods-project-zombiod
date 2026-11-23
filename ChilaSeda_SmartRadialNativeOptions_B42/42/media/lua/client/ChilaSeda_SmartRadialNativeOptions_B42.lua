require "ISUI/ISContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "SRMMenuObject"

local MOD_ID = "ChilaSeda_SmartRadialNativeOptions_B42"
local INSTALL_KEY = "_ChilaSedaSmartRadialNativeOptionsInstalled"
local DRINK_SMART_TEXTURE_PATH = "media/ui/DrinkSmart.png"
local SCANNED_ITEM_LISTS = {
    "foodItems", "smokeItems", "drinkItems", "medicalItems", "alarmItems",
    "spiceItems", "readingItems", "mapItems", "researchableItems",
    "clothingItems", "clothingWornItems", "craftingItems", "weaponItems",
    "weaponItemsNotInInventory", "ammoItems",
}

local DRINK_TRACE_MAX = 48
local drinkTraceLines = 0
local activeDrinkRadialContext = nil

local function drinkItemType(item)
    if not item then return "nil" end
    if item.getFullType then
        local ok, value = pcall(item.getFullType, item)
        if ok and value then return tostring(value) end
    end
    if item.getType then
        local ok, value = pcall(item.getType, item)
        if ok and value then return tostring(value) end
    end
    return "unknown"
end

local function drinkQueue(playerNum)
    if not ISTimedActionQueue or type(ISTimedActionQueue.getTimedActionQueue) ~= "function"
        or type(getSpecificPlayer) ~= "function" then return nil end
    local ok, player = pcall(getSpecificPlayer, playerNum)
    if not ok or not player then return nil end
    local queueOk, queue = pcall(ISTimedActionQueue.getTimedActionQueue, player)
    return queueOk and queue or nil
end

local function drinkQueueSummary(playerNum)
    local queue = drinkQueue(playerNum)
    if not queue then return "unavailable" end
    local queueOk, actions = pcall(function() return queue.queue end)
    if not queueOk or type(actions) ~= "table" then return "unavailable" end
    local names = {}
    for _, action in ipairs(actions) do
        local kind = action and tostring(action.Type or "") or ""
        if kind == "ISInventoryTransferAction" or kind == "ISUnequipAction"
            or kind == "ISDrinkFluidAction" or kind == "ISWearClothing" then
            names[#names + 1] = kind
        end
    end
    return #names > 0 and table.concat(names, ">") or "empty"
end

local function drinkMaskName(playerNum)
    if type(getSpecificPlayer) ~= "function" then return "unknown" end
    local playerOk, player = pcall(getSpecificPlayer, playerNum)
    if not playerOk then return "unknown" end
    local getter = ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.getEatingMask
    if not player or type(getter) ~= "function" then return "unknown" end
    local ok, mask = pcall(getter, player, false)
    return ok and mask and drinkItemType(mask) or (ok and "none" or "unknown")
end

local function traceDrink(eventName, playerNum, item, extra)
    if drinkTraceLines >= DRINK_TRACE_MAX then return end
    drinkTraceLines = drinkTraceLines + 1
    print("[" .. MOD_ID .. "] drink-trace event=" .. tostring(eventName)
        .. " player=" .. tostring(playerNum)
        .. " item=" .. drinkItemType(item)
        .. " mask=" .. drinkMaskName(playerNum)
        .. " queue=" .. drinkQueueSummary(playerNum)
        .. (extra and (" " .. tostring(extra)) or ""))
end

local function isDrinkSequenceAction(action)
    local kind = action and tostring(action.Type or "") or ""
    return kind == "ISInventoryTransferAction" or kind == "ISUnequipAction"
        or kind == "ISDrinkFluidAction" or kind == "ISWearClothing"
end

local function drinkResetCaller()
    if type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
        return "unavailable"
    end
    local ok, info = pcall(debug.getinfo, 2, "nS")
    if not ok or type(info) ~= "table" then return "unknown" end
    local caller = info.name or info.short_src or info.source or "unknown"
    caller = string.gsub(tostring(caller), "[%s\r\n]+", " ")
    return string.sub(caller, 1, 100)
end

local function installDrinkActionDiagnostics()
    pcall(require, "TimedActions/ISTimedActionQueue")
    pcall(require, "TimedActions/ISDrinkFluidAction")
    local queue = ISTimedActionQueue
    if type(queue) == "table" and not queue.__ChilaSedaSmartRadialDrinkTrace then
        local originalAdd = queue.add
        if type(originalAdd) == "function" then
            queue.add = function(action, ...)
                local actualAction = action == queue and select(1, ...) or action
                local result = originalAdd(action, ...)
                if activeDrinkRadialContext and isDrinkSequenceAction(actualAction) then
                    actualAction.ChilaSedaSmartRadialDrinkTrace = true
                    actualAction.ChilaSedaSmartRadialDrinkPlayerNum = activeDrinkRadialContext.playerNum
                    actualAction.ChilaSedaSmartRadialDrinkItem = activeDrinkRadialContext.item
                    traceDrink("queue-add", activeDrinkRadialContext.playerNum,
                        activeDrinkRadialContext.item, "action=" .. tostring(actualAction.Type))
                end
                return result
            end
        end

        local originalComplete = queue.onCompleted
        if type(originalComplete) == "function" then
            queue.onCompleted = function(self, action, ...)
                if action and action.ChilaSedaSmartRadialDrinkTrace then
                    traceDrink("queue-complete", action.ChilaSedaSmartRadialDrinkPlayerNum,
                        action.ChilaSedaSmartRadialDrinkItem, "action=" .. tostring(action.Type))
                end
                return originalComplete(self, action, ...)
            end
        end

        local originalReset = queue.resetQueue
        if type(originalReset) == "function" then
            queue.resetQueue = function(self, ...)
                local queueOk, actions = pcall(function() return self and self.queue or {} end)
                if queueOk and type(actions) == "table" then
                    local caller
                    for _, action in ipairs(actions) do
                        if action and action.ChilaSedaSmartRadialDrinkTrace then
                            caller = caller or drinkResetCaller()
                            traceDrink("queue-reset-cancel",
                                action.ChilaSedaSmartRadialDrinkPlayerNum,
                                action.ChilaSedaSmartRadialDrinkItem,
                                "action=" .. tostring(action.Type)
                                    .. " caller=" .. tostring(caller))
                        end
                    end
                end
                return originalReset(self, ...)
            end
        end
        queue.__ChilaSedaSmartRadialDrinkTrace = true
    end

    local drinkAction = ISDrinkFluidAction
    if type(drinkAction) == "table" and not drinkAction.__ChilaSedaSmartRadialDrinkTrace
        and type(drinkAction.isValid) == "function" then
        local originalIsValid = drinkAction.isValid
        drinkAction.isValid = function(action, ...)
            local ok, valid = pcall(originalIsValid, action, ...)
            if action and action.ChilaSedaSmartRadialDrinkTrace
                and not action.ChilaSedaSmartRadialDrinkValidityLogged then
                action.ChilaSedaSmartRadialDrinkValidityLogged = true
                traceDrink(ok and (valid and "is-valid" or "is-invalid") or "is-valid-error",
                    action.ChilaSedaSmartRadialDrinkPlayerNum,
                    action.ChilaSedaSmartRadialDrinkItem,
                    "action=ISDrinkFluidAction"
                        .. (not ok and (" error=" .. tostring(valid)) or ""))
            end
            if not ok then error(valid) end
            return valid
        end
        drinkAction.__ChilaSedaSmartRadialDrinkTrace = true
    end
end

local function isDrinkSmartOption(option)
    local label = string.lower(tostring(option.name or ""))
    local compactLabel = string.gsub(label, "%s+", "")
    local hints = { "drink smart", "0%thirst", "0%sed", "sip", "sorbo" }
    for _, hint in ipairs(hints) do
        if string.find(label, hint, 1, true)
            or string.find(compactLabel, hint, 1, true) then return true end
    end
    return false
end

local function isDrinkSmartSliceName(name)
    local text = tostring(name or "")
    local lower = string.lower(text)
    return string.sub(lower, 1, 11) == "drink smart"
        or (string.sub(lower, 1, 6) == "beber "
            and string.find(text, "%d+%%") ~= nil)
end

local function localizeDrinkSmartName(name)
    local text = tostring(name or "")
    if string.sub(string.lower(text), 1, 11) == "drink smart" then
        return "Beber" .. string.sub(text, 12)
    end
    return text
end

local function normalizeScannedItemLists(playerNum)
    local scannedByPlayer = SRMRadialMenu and SRMRadialMenu.scannedItems
    local scanned = scannedByPlayer and scannedByPlayer[playerNum]
    if type(scanned) ~= "table" then return end

    for _, key in ipairs(SCANNED_ITEM_LISTS) do
        local items = scanned[key]
        if type(items) ~= "table" then
            local converted = {}
            local ok, size = pcall(function() return items and items:size() end)
            if ok and tonumber(size) then
                for index = 0, tonumber(size) - 1 do
                    local itemOk, item = pcall(function() return items:get(index) end)
                    if itemOk and item then converted[#converted + 1] = item end
                end
            elseif items ~= nil then
                print("[" .. MOD_ID .. "] replaced invalid Smart Radial item list: " .. key)
            end
            scanned[key] = converted
            if items ~= nil then
                print("[" .. MOD_ID .. "] normalized Smart Radial item list: " .. key)
            end
        end
    end
end

local function isDrinkRadialAction(label)
    local name = tostring(label or "")
    if isDrinkSmartOption({ name = name }) then return false end
    name = string.lower(name)
    local hints = { "drink", "beber", "open and drink", "abrir y beber", "tomar agua" }
    for _, hint in ipairs(hints) do
        if string.find(name, hint, 1, true) then return true end
    end
    return false
end

local function isDrinkableItemSelection(label, item)
    if not item or type(item.getFluidContainer) ~= "function" then return false end
    local containerOk, fluidContainer = pcall(function() return item:getFluidContainer() end)
    if not containerOk or not fluidContainer then return false end
    local nameOk, itemName = pcall(function() return item:getName() end)
    if not nameOk or tostring(label or "") ~= tostring(itemName or "") then return false end
    local canEmptyOk, canEmpty = pcall(function() return fluidContainer:canPlayerEmpty() end)
    local amountOk, amount = pcall(function() return fluidContainer:getAmount() end)
    local numericAmount = amountOk and tonumber(amount) or nil
    return canEmptyOk and canEmpty == true and numericAmount and numericAmount > 0
end

local function isHandEquipOption(option)
    local label = tostring(option.name or "")
    return label == getText("ContextMenu_Equip_Primary")
        or label == getText("ContextMenu_Equip_Secondary")
        or label == getText("ContextMenu_Equip_Two_Hands")
end

local function isModOption(option)
    local label = string.lower(tostring(option.name or ""))
    local hints = {
        "drink smart", "0% thirst", "0% sed", "sip", "sorbo",
        "reduce all fats", "reducir todas las grasas", "combine fats",
        "combinar grasas", "resume autocook", "reanudar autocook",
        "dismantle all at once", "desmantelar todo",
    }
    for _, hint in ipairs(hints) do
        if string.find(label, hint, 1, true) then return true end
    end

    if type(debug) == "table" and type(debug.getinfo) == "function"
        and type(option.onSelect) == "function" then
        local ok, info = pcall(debug.getinfo, option.onSelect, "S")
        local source = ok and info and (info.source or info.short_src)
        if type(source) == "string" then
            local lowerSource = string.lower(source)
            if string.find(lowerSource, "(mod:", 1, true)
                or string.find(lowerSource, "/mods/", 1, true)
                or string.find(lowerSource, "\\mods\\", 1, true)
                or string.find(lowerSource, "workshop", 1, true)
                or string.find(lowerSource, "chilaseda_", 1, true)
                or string.find(lowerSource, "drink_smart", 1, true) then
                return true
            end
        end
    end
    return false
end

local sortContextOptions
local drinkSmartTexture
local radialOwnedCallbacks = setmetatable({}, { __mode = "k" })

local function copyContextOptions(context, rootContext, depth)
    rootContext = rootContext or context
    if not context or depth > 8 then return {} end
    local entries = {}
    for _, option in ipairs(context.options or {}) do
        local childMenu
        if option.subOption then
            -- getSubMenu looks up the player's global context menu. The temporary
            -- menu built for the radial can outlive or lack that menu's instanceMap.
            -- Resolve children from the root menu we copied and skip stale indices.
            local instances = rootContext and rootContext.instanceMap
            local index = tonumber(option.subOption)
            if type(instances) == "table" and index then
                childMenu = instances[index]
            end
        end
        local children = childMenu and copyContextOptions(childMenu, rootContext, depth + 1) or nil
        local available = not option.notAvailable and not option.isDisabled
        if available and ((type(option.onSelect) == "function") or (children and #children > 0)) then
            entries[#entries + 1] = {
                name = localizeDrinkSmartName(option.name),
                target = option.target,
                onSelect = option.onSelect,
                params = {
                    option.param1, option.param2, option.param3, option.param4,
                    option.param5, option.param6, option.param7, option.param8,
                    option.param9, option.param10,
                },
                texture = option.iconTexture,
                children = children,
                isHandEquip = isHandEquipOption(option),
                isMod = isModOption(option),
                isDrinkSmart = isDrinkSmartOption(option)
                    or isDrinkSmartSliceName(option.name),
                order = #entries + 1,
            }
        end
    end

    -- Put Drink Smart first, then hand equip, other mod actions, and native actions.
    for _, entry in ipairs(entries) do
        if entry.children and #entry.children > 0 then
            entry.children = sortContextOptions(entry.children)
            for _, child in ipairs(entry.children) do
                if child.isModGroup then entry.isModGroup = true end
                if child.isDrinkSmartGroup then entry.isDrinkSmartGroup = true end
                if child.isHandEquipGroup then entry.isHandEquipGroup = true end
            end
        end
        entry.isModGroup = entry.isModGroup or entry.isMod
        entry.isDrinkSmartGroup = entry.isDrinkSmartGroup or entry.isDrinkSmart
        entry.isHandEquipGroup = entry.isHandEquipGroup or entry.isHandEquip
    end
    return sortContextOptions(entries)
end

sortContextOptions = function(entries)
    table.sort(entries, function(a, b)
        local aPriority = a.isDrinkSmartGroup and 4
            or (a.isHandEquipGroup and 3 or (a.isModGroup and 1 or 0))
        local bPriority = b.isDrinkSmartGroup and 4
            or (b.isHandEquipGroup and 3 or (b.isModGroup and 1 or 0))
        if aPriority ~= bPriority then return aPriority > bPriority end
        return a.order < b.order
    end)
    return entries
end

local function findDrinkOptions(entries)
    for _, entry in ipairs(entries or {}) do
        if isDrinkRadialAction(entry.name) and entry.children and #entry.children > 0 then
            return entry.children
        end
        if entry.children and #entry.children > 0 then
            local nested = findDrinkOptions(entry.children)
            if #nested > 0 then return nested end
        end
    end
    return {}
end

local function getDrinkSmartTexture()
    if drinkSmartTexture or type(getTexture) ~= "function" then return drinkSmartTexture end
    if not drinkSmartTexture then
        local ok, texture = pcall(getTexture, DRINK_SMART_TEXTURE_PATH)
        if ok then drinkSmartTexture = texture end
    end
    return drinkSmartTexture
end

local function getEntryTexture(entry)
    if entry.isDrinkSmart then return getDrinkSmartTexture() end
    if entry.texture then return entry.texture end
    return nil
end

local function applyDrinkSmartMenuIcons(context, rootContext, depth)
    rootContext = rootContext or context
    if not context or depth > 8 then return end
    local texture = getDrinkSmartTexture()
    for _, option in ipairs(context.options or {}) do
        if texture and isDrinkSmartOption(option) then
            option.iconTexture = texture
        end
        if option.subOption then
            local instances = rootContext and rootContext.instanceMap
            local index = tonumber(option.subOption)
            local childMenu = type(instances) == "table" and index and instances[index]
            if childMenu and childMenu ~= context then
                applyDrinkSmartMenuIcons(childMenu, rootContext, depth + 1)
            end
        end
    end
end

local function hideNativeMenu(context)
    if not context then return end
    if type(context.hideAndChildren) == "function" then
        context:hideAndChildren()
    else
        context:setVisible(false)
        context:removeFromUIManager()
    end
end

local function snapshotUI()
    local snapshot = {}
    if not UIManager or type(UIManager.getUI) ~= "function" then return snapshot end
    local ok, uis = pcall(UIManager.getUI)
    if not ok or not uis then return snapshot end
    for i = 0, uis:size() - 1 do
        local ui = uis:get(i)
        if ui then snapshot[ui] = true end
    end
    return snapshot
end

local function removeNewUI(snapshot)
    if not UIManager or type(UIManager.getUI) ~= "function" then return end
    local ok, uis = pcall(UIManager.getUI)
    if not ok or not uis then return end
    for i = uis:size() - 1, 0, -1 do
        local ui = uis:get(i)
        if ui and not snapshot[ui] then
            pcall(hideNativeMenu, ui)
        end
    end
end

local function buildNativeOptions(playerObj, item)
    if not playerObj or not item or not ISInventoryPaneContextMenu
        or type(ISInventoryPaneContextMenu.createMenu) ~= "function" then
        return {}
    end

    local isInPlayerInventory = false
    local containerOk, inCharacterInventory = pcall(function()
        local container = item:getContainer()
        return container and container:isInCharacterInventory(playerObj)
    end)
    if containerOk then isInPlayerInventory = inCharacterInventory == true end
    local playerNum = playerObj:getPlayerNum()
    local uiBefore = snapshotUI()
    local ok, context = pcall(ISInventoryPaneContextMenu.createMenu,
        playerNum, isInPlayerInventory, { item }, 0, 0)
    if not ok then
        removeNewUI(uiBefore)
        print("[" .. MOD_ID .. "] could not build native item menu: " .. tostring(context))
        return {}
    end

    local copied, entries = pcall(copyContextOptions, context, context, 0)
    hideNativeMenu(context)
    removeNewUI(uiBefore)
    if not copied then
        print("[" .. MOD_ID .. "] could not read native item menu: " .. tostring(entries))
        return {}
    end
    return entries
end

local function invokeNativeOption(entry)
    local params = entry.params or {}
    entry.onSelect(entry.target,
        params[1], params[2], params[3], params[4], params[5],
        params[6], params[7], params[8], params[9], params[10])
end

local function addEntriesToRadial(menu, entries, playerObj, item)
    for _, entry in ipairs(entries) do
        if entry.children and #entry.children > 0 then
            local current = entry
            local callback = function()
                if SRMRadialMenu and type(SRMRadialMenu.checkContainerAccess) == "function"
                    and SRMRadialMenu.checkContainerAccess(playerObj, item) then return end
                menu:createSubMenu(function(subMenu)
                    addEntriesToRadial(subMenu, current.children, playerObj, item)
                end)
            end
            radialOwnedCallbacks[callback] = true
            menu:addSlice(current.name, getEntryTexture(current), callback)
        else
            local current = entry
            local callback = function()
                if SRMRadialMenu and type(SRMRadialMenu.checkContainerAccess) == "function"
                    and SRMRadialMenu.checkContainerAccess(playerObj, item) then return end
                invokeNativeOption(current)
            end
            radialOwnedCallbacks[callback] = true
            menu:addSlice(current.name, getEntryTexture(current), callback)
        end
    end
end

local function openDrinkOptions(menu, playerObj, item, radialAction)
    if not playerObj then
        radialAction()
        return
    end
    if SRMRadialMenu and type(SRMRadialMenu.checkContainerAccess) == "function"
        and SRMRadialMenu.checkContainerAccess(playerObj, item) then return end
    local entries = buildNativeOptions(playerObj, item)
    if #entries == 0 then
        radialAction()
        return
    end

    -- Expose only the localized drink submenu. Never insert the item's complete
    -- context menu as an extra radial step.
    local drinkEntries = findDrinkOptions(entries)
    if #drinkEntries == 0 then
        radialAction()
        return
    end

    menu:createSubMenu(function(subMenu)
        addEntriesToRadial(subMenu, drinkEntries, playerObj, item)
    end)
end

local function install()
    if _G[INSTALL_KEY] then return end
    if not SRMMenuObject or type(SRMMenuObject.addSlice) ~= "function" then
        print("[" .. MOD_ID .. "] Smart Radial Menu API not loaded")
        return
    end
    _G[INSTALL_KEY] = true
    installDrinkActionDiagnostics()

    local originalDoDrinkFluidMenu = ISInventoryPaneContextMenu
        and ISInventoryPaneContextMenu.doDrinkFluidMenu
    if type(originalDoDrinkFluidMenu) == "function" then
        ISInventoryPaneContextMenu.doDrinkFluidMenu = function(playerObj, fluidContainer, context, ...)
            local result = originalDoDrinkFluidMenu(playerObj, fluidContainer, context, ...)
            applyDrinkSmartMenuIcons(context, context, 0)
            return result
        end
    end

    local originalAddSlice = SRMMenuObject.addSlice
    SRMMenuObject.addSlice = function(self, text, texture, command, item,
        itemCount, extraTooltipText, craftingTooltipForced,
        arg1, arg2, arg3, arg4, arg5, arg6)
        local drinkSmartSlice = isDrinkSmartSliceName(text)
        text = localizeDrinkSmartName(text)
        if type(command) == "function" and not radialOwnedCallbacks[command] then
            local menu = self
            local sliceItem = item
            local sliceLabel = text
            local originalCommand = command
            command = function()
                if not drinkSmartSlice then
                    normalizeScannedItemLists(menu.playerNum)
                    return originalCommand(arg1, arg2, arg3, arg4, arg5, arg6)
                end

                local previousContext = activeDrinkRadialContext
                activeDrinkRadialContext = {
                    playerNum = menu.playerNum,
                    item = sliceItem,
                    label = sliceLabel,
                }
                traceDrink("dispatch-start", menu.playerNum, sliceItem,
                    "slice=" .. tostring(sliceLabel))
                local ok, result = pcall(function()
                    normalizeScannedItemLists(menu.playerNum)
                    return originalCommand(arg1, arg2, arg3, arg4, arg5, arg6)
                end)
                traceDrink(ok and "dispatch-end" or "dispatch-error", menu.playerNum,
                    sliceItem, "slice=" .. tostring(sliceLabel)
                        .. (not ok and (" error=" .. tostring(result)) or ""))
                activeDrinkRadialContext = previousContext
                if not ok then error(result) end
                return result
            end
            radialOwnedCallbacks[command] = true
        end
        local result = originalAddSlice(self, text, texture, command, item,
            itemCount, extraTooltipText, craftingTooltipForced,
            arg1, arg2, arg3, arg4, arg5, arg6)
        local slices = self and self.slices
        if drinkSmartSlice and type(slices) == "table" and #slices > 1
            and type(self.setSliceText) == "function"
            and type(self.setSliceTexture) == "function" then
            table.insert(slices, 1, table.remove(slices, #slices))
            -- Keep the Java radial's visible index in sync with Lua's callback table.
            for index, slice in ipairs(slices) do
                self:setSliceText(index, slice.text)
                self:setSliceTexture(index, slice.texture)
            end
        end
        return result
    end
    print("[" .. MOD_ID .. "] Drink Smart is first and localized; radial callbacks stay aligned (1.1.14)")
end

Events.OnGameBoot.Add(install)
Events.OnGameStart.Add(install)
