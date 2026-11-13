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
                name = tostring(option.name or ""),
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
                isDrinkSmart = isDrinkSmartOption(option),
                order = #entries + 1,
            }
        end
    end

    -- Preserve order within groups: hand equip, Drink Smart, other mod actions, then native actions.
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
        local aPriority = a.isHandEquipGroup and 3
            or (a.isDrinkSmartGroup and 2 or (a.isModGroup and 1 or 0))
        local bPriority = b.isHandEquipGroup and 3
            or (b.isDrinkSmartGroup and 2 or (b.isModGroup and 1 or 0))
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
        if type(command) == "function" and not radialOwnedCallbacks[command] then
            local menu = self
            local originalCommand = command
            command = function()
                normalizeScannedItemLists(menu.playerNum)
                originalCommand(arg1, arg2, arg3, arg4, arg5, arg6)
            end
            radialOwnedCallbacks[command] = true
        end
        return originalAddSlice(self, text, texture, command, item,
            itemCount, extraTooltipText, craftingTooltipForced,
            arg1, arg2, arg3, arg4, arg5, arg6)
    end
    print("[" .. MOD_ID .. "] native Smart Radial actions preserved; invalid item lists are normalized (1.1.12)")
end

Events.OnGameBoot.Add(install)
Events.OnGameStart.Add(install)
