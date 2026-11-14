require "ISUI/ISModalDialog"
local confirmationKeys = require "ChilaSeda_ConfirmationDialogKeys_B42"
require "ISUI/ISInventoryPaneContextMenu"
require "ChilaSeda_FoodMenuOrder_B42"

ChilaSedaConfirmItemDelete = ChilaSedaConfirmItemDelete or {}
local M = ChilaSedaConfirmItemDelete
local TAG = "[ChilaSeda_AccessibleActions_B42] "
local activeDialog
local notificationQueue = {}
local nextNotificationAt = 0

local function getSelectedItems(items)
    local result, seen = {}, {}
    for _, entry in ipairs(items or {}) do
        local candidates = instanceof(entry, "InventoryItem") and { entry }
            or (type(entry) == "table" and entry.items)
        for _, item in ipairs(candidates or {}) do
            if item and instanceof(item, "InventoryItem") and not seen[item] then
                local container = item:getContainer()
                if container then
                    local worldObject
                    if container:getType() == "floor" then
                        local ok, worldItem = pcall(function() return item:getWorldItem() end)
                        if ok then worldObject = worldItem end
                    end
                    if container:getType() ~= "floor" or worldObject then
                        seen[item] = true
                        result[#result + 1] = { item = item, container = container, worldObject = worldObject }
                    end
                end
            end
        end
    end
    return result
end

local function getSelectedFloorItems(worldobjects)
    local result, seen = {}, {}
    for _, worldObject in ipairs(worldobjects or {}) do
        if worldObject and instanceof(worldObject, "IsoWorldInventoryObject") then
            local item = worldObject:getItem()
            if item and instanceof(item, "InventoryItem") and not seen[item] then
                local container = item:getContainer()
                if container and container:getType() == "floor" then
                    seen[item] = true
                    result[#result + 1] = { item = item, container = container, worldObject = worldObject }
                end
            end
        end
    end
    return result
end

local foodCleanupCategories = {
    {
        key = "rotten",
        optionKey = "UI_ChilaSeda_DeleteFood_OptionRotten",
        stateKey = "UI_ChilaSeda_DeleteFood_StateRotten",
        icon = "media/ui/Moodles/32/Mood_Nauseous.png",
    },
    {
        key = "stale",
        optionKey = "UI_ChilaSeda_DeleteFood_OptionStale",
        stateKey = "UI_ChilaSeda_DeleteFood_StateStale",
        icon = "media/ui/Moodles/32/Mood_Discomfort.png",
    },
    {
        key = "fresh",
        optionKey = "UI_ChilaSeda_DeleteFood_OptionFresh",
        stateKey = "UI_ChilaSeda_DeleteFood_StateFresh",
        icon = "media/ui/Moodles/32/Mood_Happy.png",
    },
    {
        key = "burnt",
        optionKey = "UI_ChilaSeda_DeleteFood_OptionBurnt",
        stateKey = "UI_ChilaSeda_DeleteFood_StateBurnt",
    },
}

local function isInstance(item, className)
    if not item or type(instanceof) ~= "function" then return false end
    local ok, result = pcall(instanceof, item, className)
    return ok and result == true
end

local function isInsidePreparedFoodContainer(container)
    if not container then return true end
    local ok, owner = pcall(function() return container:getContainingItem() end)
    if not ok then return true end
    return owner ~= nil and isInstance(owner, "Food")
        and isInstance(owner, "InventoryContainer")
end

local function getFoodState(item, container)
    if not isInstance(item, "Food") or isInstance(item, "InventoryContainer") then return nil end
    if isInsidePreparedFoodContainer(container) then return nil end

    local okBurnt, burnt = pcall(function() return item:isBurnt() end)
    if okBurnt and burnt then return "burnt" end

    local okRotten, rotten = pcall(function() return item:isRotten() end)
    if not okRotten then return nil end
    if rotten then return "rotten" end

    local okFresh, fresh = pcall(function() return item:isFresh() end)
    if not okFresh then return nil end
    if fresh then return "fresh" end
    return "stale"
end

local function getContainerFoodEntries(container, state)
    local result = {}
    if not container or container:getType() == "floor" or isInsidePreparedFoodContainer(container) then
        return result
    end

    local itemList = container:getItems()
    if not itemList then return result end
    for i = 0, itemList:size() - 1 do
        local item = itemList:get(i)
        if item and item:getContainer() == container and getFoodState(item, container) == state then
            result[#result + 1] = { item = item, container = container }
        end
    end
    return result
end

local function getSingleSelectedContainer(entries)
    if #entries == 0 then return nil end
    local container = entries[1].container
    if not container then return nil end
    for i = 2, #entries do
        if entries[i].container ~= container then return nil end
    end
    return container
end

local function setOptionIcon(option, path)
    if not option or type(getTexture) ~= "function" then return end
    local ok, texture = pcall(getTexture, path)
    if ok and texture then option.iconTexture = texture end
end

local function setVanillaItemIcon(option, fullTypes)
    if not option or type(getScriptManager) ~= "function" then return end
    local okManager, manager = pcall(getScriptManager)
    if not okManager or not manager then return end
    for _, fullType in ipairs(fullTypes or {}) do
        local okItem, scriptItem = pcall(manager.FindItem, manager, fullType)
        if okItem and scriptItem and type(scriptItem.getNormalTexture) == "function" then
            local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
            if okTexture and texture then
                option.iconTexture = texture
                return
            end
        end
    end
end

local function removeSelected(target, button)
    activeDialog = nil
    if not button or button.internal ~= "YES" then return end

    local playerIndex = target.playerIndex
    local player = getSpecificPlayer(playerIndex)
    if not player then return end

    local removed = 0
    local removedByType = {}
    for _, entry in ipairs(target.entries) do
        local item, container = entry.item, entry.container
        local matchesCategory = not target.category
            or (getFoodState(item, container) == target.category.key
                and item:getFullType() == target.fullType)
        if matchesCategory and item and container and item:getContainer() == container then
            if entry.worldObject then
                local worldObject = entry.worldObject
                local ok, worldItem = pcall(function() return worldObject:getItem() end)
                if not ok or worldItem ~= item then
                    item = nil
                else
                    local okRemove = pcall(function()
                        local square = worldObject:getSquare()
                        if square and isClient and not isClient() then
                            square:transmitRemoveItemFromSquare(worldObject)
                        end
                        worldObject:removeFromWorld()
                        worldObject:removeFromSquare()
                        worldObject:setSquare(nil)
                        item:setWorldItem(nil)
                        if container:contains(item) then container:DoRemoveItem(item) end
                    end)
                    if not okRemove then item = nil end
                end
            elseif container:contains(item) then
                container:DoRemoveItem(item)
                sendRemoveItemFromContainer(container, item)
            else
                item = nil
            end
            if item then
                if player:getInventory() == container then
                    player:removeAttachedItem(item)
                    if player:isEquipped(item) then
                        player:removeFromHands(item)
                        player:removeWornItem(item, false)
                        triggerEvent("OnClothingUpdated", player)
                    end
                end
                removed = removed + 1
                if target.category then
                    local fullType = item:getFullType()
                    removedByType[fullType] = (removedByType[fullType] or 0) + 1
                end
            end
        end
    end
    print(TAG .. "confirmed removal"
        .. (target.category and (" category=" .. target.category.key) or "")
        .. " count=" .. tostring(removed))
    if target.category then
        local fullTypes = {}
        for fullType in pairs(removedByType) do fullTypes[#fullTypes + 1] = fullType end
        table.sort(fullTypes)
        for _, fullType in ipairs(fullTypes) do
            local entries = removedByType[fullType]
            local name = fullType
            local scriptItem = getScriptManager():FindItem(fullType)
            if scriptItem then name = scriptItem:getDisplayName() or name end
            local icon
            if scriptItem and type(scriptItem.getNormalTexture) == "function" then
                local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
                if okTexture then icon = texture end
            end
            notificationQueue[#notificationQueue + 1] = {
                message = getText("UI_ChilaSeda_DeleteFood_Notification", entries, name),
                icon = icon,
            }
        end
        nextNotificationAt = 0
    end
end

Events.OnTick.Add(function()
    if #notificationQueue == 0 then return end
    local now = type(getTimestampMs) == "function" and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < nextNotificationAt then return end
    local notification = table.remove(notificationQueue, 1)
    local message = type(notification) == "table" and notification.message or notification
    local icon = type(notification) == "table" and notification.icon or nil
    local player = getSpecificPlayer(0)
    local halo = ChilaSeda_ViewpointHaloNotifications
    if player and halo and type(halo.showFixed) == "function" then
        halo.showFixed(message, { r = 1, g = 0.86, b = 0.42 }, icon)
    elseif player and HaloTextHelper and type(HaloTextHelper.addText) == "function" then
        HaloTextHelper.addText(player, message, " ", 255, 220, 120)
    end
    nextNotificationAt = now + 2200
end)

local function askToDelete(playerIndex, entries, category, fullType)
    if activeDialog or #entries == 0 then return end
    local core = getCore()
    if not core then return end

    local text
    if category then
        local stateName = getText(category.stateKey)
        text = #entries == 1
            and getText("UI_ChilaSeda_DeleteFood_ConfirmOne", entries[1].item:getName(), stateName)
            or getText("UI_ChilaSeda_DeleteFood_ConfirmMany", #entries, stateName)
    else
        text = #entries == 1
            and getText("UI_ChilaSeda_DeleteItem_ConfirmOne", entries[1].item:getName())
            or getText("UI_ChilaSeda_DeleteItem_ConfirmMany", #entries)
    end
    local width, height = 460, 150
    local target = { playerIndex = playerIndex, entries = entries, category = category, fullType = fullType }
    activeDialog = ISModalDialog:new((core:getScreenWidth() - width) / 2,
        (core:getScreenHeight() - height) / 2, width, height, text, true,
        target, removeSelected, playerIndex)
    activeDialog:initialise()
    confirmationKeys.attach(activeDialog)
    activeDialog:addToUIManager()
    activeDialog:setAlwaysOnTop(true)
    activeDialog:bringToTop()
end

local function onDeleteOption(playerIndex, entries)
    askToDelete(playerIndex, entries)
end

local function onFoodDeleteOption(playerIndex, category, entries, fullType)
    askToDelete(playerIndex, entries, category, fullType)
end

local function addDeleteOption(playerIndex, context, items)
    local entries = getSelectedItems(items)
    if #entries == 0 then return end

    local label = #entries == 1
        and getText("UI_ChilaSeda_DeleteItem_OptionOne")
        or getText("UI_ChilaSeda_DeleteItem_OptionMany", #entries)
    local option = context:addOption(label, playerIndex, onDeleteOption, entries)
    option.chilaSedaDeleteObject = true
    setOptionIcon(option, "media/ui/LootableMaps/map_garbage.png")
    if not option.iconTexture then
        setVanillaItemIcon(option, { "Base.Garbagebag", "Base.GarbageBag" })
    end
    if not option.iconTexture then
        local item = entries[1] and entries[1].item
        if item and type(item.getTexture) == "function" then
            local ok, texture = pcall(item.getTexture, item)
            if ok and texture then option.iconTexture = texture end
        end
    end
    ChilaSedaFoodMenuOrder.move(context, option)
end

local function addFoodCleanupOptions(playerIndex, context, items)
    local selectedEntries = getSelectedItems(items)
    local container = getSingleSelectedContainer(selectedEntries)
    if not container then return end

    local selectedTypes = {}
    local selectedTypeNames = {}
    for _, entry in ipairs(selectedEntries) do
        local state = getFoodState(entry.item, container)
        if state then
            local fullType = entry.item:getFullType()
            if not selectedTypes[fullType] then
                selectedTypes[fullType] = {}
                selectedTypeNames[#selectedTypeNames + 1] = fullType
            end
            selectedTypes[fullType][state] = true
        end
    end
    if #selectedTypeNames == 0 then return end

    -- For a floor panel, process only selected objects. For a regular inventory
    -- container, preserve the existing behavior of purging that selected type.
    table.sort(selectedTypeNames)
    for _, category in ipairs(foodCleanupCategories) do
        for _, fullType in ipairs(selectedTypeNames) do
            local states = selectedTypes[fullType]
            if states[category.key] then
                local entries = {}
                local candidates = container:getType() == "floor"
                    and selectedEntries or getContainerFoodEntries(container, category.key)
                for _, entry in ipairs(candidates) do
                    if getFoodState(entry.item, container) == category.key
                        and entry.item:getFullType() == fullType then
                        entries[#entries + 1] = entry
                    end
                end
                if #entries > 0 then
                    local scriptItem = getScriptManager():FindItem(fullType)
                    local itemName = scriptItem and scriptItem:getDisplayName() or fullType
                    local option = context:addOption(
                        getText(category.optionKey, #entries, itemName),
                        playerIndex,
                        onFoodDeleteOption,
                        category,
                        entries,
                        fullType
                    )
                    option.chilaSedaDeleteFoodCategory = category.key
                    setOptionIcon(option, category.icon)
                    if not option.iconTexture then setVanillaItemIcon(option, { fullType }) end
                    ChilaSedaFoodMenuOrder.move(context, option)
                end
            end
        end
    end
end

local function addFloorContextOptions(playerIndex, context, worldobjects, test)
    local entries = getSelectedFloorItems(worldobjects)
    if #entries == 0 then return end
    if test then
        if ISWorldObjectContextMenu then ISWorldObjectContextMenu.Test = true end
        return true
    end

    local label = #entries == 1
        and getText("UI_ChilaSeda_DeleteItem_OptionOne")
        or getText("UI_ChilaSeda_DeleteItem_OptionMany", #entries)
    local option = context:addOption(label, playerIndex, onDeleteOption, entries)
    option.chilaSedaDeleteObject = true
    setOptionIcon(option, "media/ui/LootableMaps/map_garbage.png")
    if not option.iconTexture then
        setVanillaItemIcon(option, { "Base.Garbagebag", "Base.GarbageBag" })
    end
    if not option.iconTexture and entries[1].item.getTexture then
        local ok, texture = pcall(entries[1].item.getTexture, entries[1].item)
        if ok and texture then option.iconTexture = texture end
    end
    ChilaSedaFoodMenuOrder.move(context, option)

    local selectedByType = {}
    for _, entry in ipairs(entries) do
        local state = getFoodState(entry.item, entry.container)
        if state then
            local fullType = entry.item:getFullType()
            selectedByType[fullType] = selectedByType[fullType] or {}
            selectedByType[fullType][state] = selectedByType[fullType][state] or {}
            table.insert(selectedByType[fullType][state], entry)
        end
    end
    for _, category in ipairs(foodCleanupCategories) do
        for fullType, states in pairs(selectedByType) do
            local foodEntries = states[category.key]
            if foodEntries and #foodEntries > 0 then
                local scriptItem = getScriptManager():FindItem(fullType)
                local itemName = scriptItem and scriptItem:getDisplayName() or fullType
                local foodOption = context:addOption(
                    getText(category.optionKey, #foodEntries, itemName),
                    playerIndex,
                    onFoodDeleteOption,
                    category,
                    foodEntries,
                    fullType
                )
                foodOption.chilaSedaDeleteFoodCategory = category.key
                setOptionIcon(foodOption, category.icon)
                if not foodOption.iconTexture then setVanillaItemIcon(foodOption, { fullType }) end
                ChilaSedaFoodMenuOrder.move(context, foodOption)
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addDeleteOption)
Events.OnFillInventoryObjectContextMenu.Add(addFoodCleanupOptions)
Events.OnPreFillWorldObjectContextMenu.Add(addFloorContextOptions)
print(TAG .. "loaded; confirmation is required before deleting selected inventory or floor items")
