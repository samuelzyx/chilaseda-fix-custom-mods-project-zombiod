-- Give every item definition a 100-item Tetris stack, including mod items,
-- containers, and definitions that vanilla treats as non-stackable. Restrict
-- only non-container grids to 1x1, 1x2, or 2x1.

local ok, TetrisItemData = pcall(require, "InventoryTetris/Data/TetrisItemData")
if not ok or type(TetrisItemData) ~= "table"
    or type(TetrisItemData._getItemDataByFullType) ~= "function" then
    print("[ChilaSeda_InventoryTetrisSizeCap] Inventory Tetris item data API unavailable; size cap not installed")
    return
end

local okCalculator, TetrisItemCalculator = pcall(require, "InventoryTetris/Data/TetrisItemCalculator")
if not okCalculator or type(TetrisItemCalculator) ~= "table"
    or type(TetrisItemCalculator._calculateItemStackability) ~= "function" then
    print("[ChilaSeda_InventoryTetrisSizeCap] stackability calculator API unavailable; size cap not installed")
    return
end

local okContainerData, TetrisContainerData = pcall(require, "InventoryTetris/Data/TetrisContainerData")
if not okContainerData or type(TetrisContainerData) ~= "table"
    or type(TetrisContainerData.calculateInnerSize) ~= "function" then
    print("[ChilaSeda_InventoryTetrisSizeCap] Inventory Tetris container data API unavailable; size cap not installed")
    return
end

if TetrisItemData.ChilaSedaSizeCapInstalled then
    return
end

local originalGetItemDataByFullType = TetrisItemData._getItemDataByFullType
local adjustedBackpacks = {}
TetrisItemCalculator._calculateItemStackability = function()
    return 100
end

local function isContainerScriptItem(scriptItem)
    if scriptItem and ItemType and ItemType.CONTAINER and scriptItem.isItemType then
        local okType, isContainerType = pcall(scriptItem.isItemType, scriptItem, ItemType.CONTAINER)
        if okType and isContainerType then
            return true
        end
    end

    return false
end

local function getBackpackContainer(item, fullType)
    if not item then
        if type(fullType) ~= "string" then
            return nil
        end

        local baseFullType = string.gsub(fullType, "__squished$", "")
        local okManager, scriptManager = pcall(getScriptManager)
        if not okManager or not scriptManager or not scriptManager.FindItem then
            return nil
        end

        local okScriptItem, scriptItem = pcall(scriptManager.FindItem, scriptManager, baseFullType)
        if not okScriptItem or not isContainerScriptItem(scriptItem) then
            return nil
        end

        local okItem, itemInstance = pcall(instanceItem, baseFullType)
        if not okItem then
            return nil
        end
        item = itemInstance
    end

    if not item or not item.canBeEquipped or not item.getItemContainer
        or not ItemBodyLocation or not ItemBodyLocation.BACK then
        return nil
    end

    local okLocation, bodyLocation = pcall(item.canBeEquipped, item)
    if not okLocation or bodyLocation ~= ItemBodyLocation.BACK then
        return nil
    end

    return item:getItemContainer()
end

local function ensureBackpackGridFits(data, item, fullType, isSquished)
    if isSquished then
        return
    end

    local width = tonumber(data.width)
    local height = tonumber(data.height)
    if not width or not height or width < 1 or height < 1 then
        return
    end

    local itemContainer = getBackpackContainer(item, fullType)
    if not itemContainer then
        return
    end

    local innerSlots = TetrisContainerData.calculateInnerSize(itemContainer)
    if type(innerSlots) ~= "number" or innerSlots <= width * height then
        return
    end

    local bestWidth
    local bestHeight
    local bestArea = math.huge
    local currentAspect = width / height
    local bestAspectDifference = math.huge

    for candidateWidth = width, innerSlots do
        local candidateHeight = math.max(height, math.ceil(innerSlots / candidateWidth))
        local area = candidateWidth * candidateHeight
        local aspectDifference = math.abs(candidateWidth / candidateHeight - currentAspect)
        if area < bestArea or (area == bestArea and aspectDifference < bestAspectDifference) then
            bestWidth = candidateWidth
            bestHeight = candidateHeight
            bestArea = area
            bestAspectDifference = aspectDifference
        end
    end

    if bestWidth and bestHeight then
        data.width = bestWidth
        data.height = bestHeight
        if not adjustedBackpacks[fullType] then
            print("[ChilaSeda_InventoryTetrisSizeCap] expanded " .. tostring(fullType)
                .. " grid to " .. tostring(bestWidth) .. "x" .. tostring(bestHeight)
                .. " for " .. tostring(innerSlots) .. " internal slots")
            adjustedBackpacks[fullType] = true
        end
    end
end

local function isInventoryContainer(item, fullType)
    if item then
        local scriptItem = item.getScriptItem and item:getScriptItem() or nil
        if isContainerScriptItem(scriptItem) then
            return true
        end

        if item.IsInventoryContainer then
            local okContainer, isContainer = pcall(item.IsInventoryContainer, item)
            if okContainer and isContainer then
                return true
            end
        end
    end

    -- Tetris passes item=nil when a grid definition is already cached or
    -- edited through Item Edit Data. Resolve the script definition by full type
    -- so cached backpacks (including Tardis/Knox containers) are not mistaken
    -- for ordinary items and clamped to 1x2.
    if type(fullType) == "string" then
        local baseFullType = string.gsub(fullType, "__squished$", "")
        local okManager, scriptManager = pcall(getScriptManager)
        if okManager and scriptManager and scriptManager.FindItem then
            local okScriptItem, scriptItem = pcall(scriptManager.FindItem, scriptManager, baseFullType)
            if okScriptItem and isContainerScriptItem(scriptItem) then
                return true
            end
        end
    end

    return false
end

local function applySizeCap(item, fullType, data, isSquished)
    if type(data) ~= "table" then
        return data
    end

    -- Tetris reads this value when deciding whether another item of the same
    -- full type can join a grid stack. Apply it to every namespace and item
    -- category; the old Base-only and already-stackable checks left gaps.
    data.maxStackSize = 100

    -- Keep backpacks out of the item-size cap, but prevent Tetris's TARDIS
    -- check from rejecting a backpack whose internal grid exceeds its footprint.
    if isInventoryContainer(item, fullType) then
        ensureBackpackGridFits(data, item, fullType, isSquished)
        return data
    end

    local width = tonumber(data.width)
    local height = tonumber(data.height)
    if not width or not height or width < 1 or height < 1 or width * height <= 2 then
        return data
    end

    if width > height then
        data.width = 2
        data.height = 1
    else
        data.width = 1
        data.height = 2
    end

    return data
end

TetrisItemData._getItemDataByFullType = function(item, fullType, isSquished)
    local data = originalGetItemDataByFullType(item, fullType, isSquished)
    return applySizeCap(item, fullType, data, isSquished)
end

local originalGetMaxStackSize = TetrisItemData.getMaxStackSize
if type(originalGetMaxStackSize) == "function" then
    TetrisItemData.getMaxStackSize = function(item)
        local okData, data = pcall(TetrisItemData._getItemData, item)
        if okData and type(data) == "table" then
            data.maxStackSize = 100
        end
        return 100
    end
end

TetrisItemData.ChilaSedaSizeCapInstalled = true
print("[ChilaSeda_InventoryTetrisSizeCap] installed; stack calculator and all Tetris item stacks use maxStackSize 100; non-container grids are limited to 1x1, 1x2, or 2x1; undersized backpack grids are expanded to prevent TARDIS validation")

local function isBackpackInventory(container)
    if not container or not container.getContainingItem then
        return false
    end

    local ok, item = pcall(container.getContainingItem, container)
    if not ok or not item then
        return false
    end

    local fullType
    if item.getFullType then
        local okType, value = pcall(item.getFullType, item)
        if okType then fullType = value end
    end
    return isInventoryContainer(item, fullType)
end

local function withBackpackCapacityEnforced(container, callback, ...)
    if not isBackpackInventory(container) or not SandboxVars
            or not SandboxVars.InventoryTetris then
        return callback(...)
    end

    local options = SandboxVars.InventoryTetris
    local previous = options.EnforceCarryWeight
    options.EnforceCarryWeight = true
    local results = { pcall(callback, ...) }
    options.EnforceCarryWeight = previous

    if results[1] then
        return unpack(results, 2)
    end
    error(results[2])
end

local function wouldExceedBackpackCapacity(player, container, item)
    if not player or not container or not item then return false end
    local ok, hasRoom = pcall(function()
        return withBackpackCapacityEnforced(container, function()
            return container:isItemAllowed(item) and container:hasRoomFor(player, item)
        end)
    end)
    return ok and not hasRoom
end

local function installBackpackCapacityValidation()
    if TetrisItemData.ChilaSedaBackpackCapacityValidationInstalled then
        return
    end

    require "ISUI/ISInventoryPane"
    require "ISUI/ISInventoryPage"
    require "TimedActions/ISInventoryTransferAction"
    require "ISUI/ISInventoryPaneContextMenu"

    local okGrid, ItemContainerGrid = pcall(require,
        "InventoryTetris/Model/ItemContainerGrid")
    if okGrid and type(ItemContainerGrid) == "table"
            and type(ItemContainerGrid.validateCapacityRestrictions) == "function" then
        local originalValidateCapacityRestrictions = ItemContainerGrid.validateCapacityRestrictions
        ItemContainerGrid.validateCapacityRestrictions = function(self, item, container, playerObj, ...)
            return withBackpackCapacityEnforced(container,
                originalValidateCapacityRestrictions, self, item, container, playerObj, ...)
        end
        print("[ChilaSeda_InventoryTetrisSizeCap] wrapped Inventory Tetris grid capacity validation")
    else
        print("[ChilaSeda_InventoryTetrisSizeCap] Inventory Tetris grid capacity validator unavailable")
    end

    local originalPaneCanPutIn = ISInventoryPane.canPutIn
    ISInventoryPane.canPutIn = function(self, ...)
        return withBackpackCapacityEnforced(self and self.inventory,
            originalPaneCanPutIn, self, ...)
    end

    if ISInventoryPaneDraggedItems and ISInventoryPaneDraggedItems.update then
        local originalDraggedItemsUpdate = ISInventoryPaneDraggedItems.update
        ISInventoryPaneDraggedItems.update = function(self, ...)
            local container
            -- Vanilla update() sets this before calling getDropContainer(). Seed it
            -- first because another mod may wrap getDropContainer and require it.
            if self and self.inventoryPane then
                self.playerNum = self.inventoryPane.player
            end
            if self and self.playerNum ~= nil and self.getDropContainer then
                local ok, result = pcall(self.getDropContainer, self)
                if ok then container = result end
            end
            return withBackpackCapacityEnforced(container,
                originalDraggedItemsUpdate, self, ...)
        end
    end

    local originalPageCanPutIn = ISInventoryPage.canPutIn
    ISInventoryPage.canPutIn = function(self, ...)
        local container = self and self.mouseOverButton
            and self.mouseOverButton.inventory or nil
        return withBackpackCapacityEnforced(container,
            originalPageCanPutIn, self, ...)
    end

    local capacityNoticeByItem = setmetatable({}, { __mode = "k" })
    local function containerName(player, container)
        if container == player:getInventory() then return "Inventario principal" end
        local item = container and container.getContainingItem
            and container:getContainingItem() or nil
        if item and item.getDisplayName then return item:getDisplayName() end
        return container and container.getType and container:getType() or "Contenedor"
    end

    local function selectDestination(page, container)
        if not page or not container then return end
        if type(page.selectButtonForContainer) == "function" then
            page:selectButtonForContainer(container)
        end
        if page.inventoryPane and page.inventoryPane.inventory ~= container
                and type(page.setNewContainer) == "function" then
            page:setNewContainer(container)
        end
        if page.inventoryPane then page.inventoryPane.lastinventory = container end
        local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(page.player) or nil
        if player and HaloTextHelper and type(HaloTextHelper.addText) == "function" then
            HaloTextHelper.addText(player, "Destino seleccionado: " .. containerName(player, container),
                " ", 255, 220, 120)
        end
    end

    local function showCapacityDestinations(player, blocked, item)
        if not player or not ISContextMenu or type(ISContextMenu.get) ~= "function"
                or type(getPlayerInventory) ~= "function" then return false end
        local playerNum = player:getPlayerNum()
        local page = getPlayerInventory(playerNum)
        if not page then return false end

        local destinations, seen = {}, {}
        local function add(container)
            if not container or container == blocked or seen[container] then return end
            local ok, fits = pcall(function()
                return container:isItemAllowed(item) and container:hasRoomFor(player, item)
                    and container:getCapacityWeight() + item:getUnequippedWeight()
                        <= container:getEffectiveCapacity(player)
            end)
            if ok and fits then
                seen[container] = true
                destinations[#destinations + 1] = container
            end
        end
        add(player:getInventory())
        local worn = player:getWornItems()
        if worn then
            for i = 0, worn:size() - 1 do
                local wornItem = worn:getItemByIndex(i)
                if wornItem and instanceof(wornItem, "InventoryContainer")
                        and not player:isHandItem(wornItem) then
                    add(wornItem:getInventory())
                end
            end
        end
        if #destinations == 0 then return false end
        local x = type(getMouseX) == "function" and getMouseX() or 0
        local y = type(getMouseY) == "function" and getMouseY() or 0
        local menu = ISContextMenu.get(playerNum, x, y)
        if not menu then return false end
        -- Offset the menu from the click that triggered the rejected transfer.
        -- Otherwise the same mouse release can land on the first destination.
        local screenW = getCore and getCore():getScreenWidth() or 1920
        local screenH = getCore and getCore():getScreenHeight() or 1080
        local menuX = math.min(x + 28, math.max(0, screenW - 300))
        local menuY = math.min(y + 28, math.max(0, screenH - 260))
        if type(menu.setX) == "function" then menu:setX(menuX) end
        if type(menu.setY) == "function" then menu:setY(menuY) end
        local header = menu:addOption("La mochila destino esta llena.", nil, nil)
        if header then header.notAvailable = true end
        local prompt = menu:addOption("Elige el destino de este objeto:", nil, nil)
        if prompt then prompt.notAvailable = true end
        for _, destination in ipairs(destinations) do
            menu:addOption(containerName(player, destination), page, selectDestination, destination)
        end
        menu:addOption("Cancelar movimiento", nil, nil)
        return true
    end

    local function notifyOverCapacity(self, transferredItem, targetContainer, targetPlayer)
        local player = targetPlayer or (self and self.character)
        local item = transferredItem or (self and self.item)
        local container = targetContainer or (self and self.destContainer)
        if not player or not item or not isBackpackInventory(container)
                or not HaloTextHelper or type(HaloTextHelper.addText) ~= "function" then
            return
        end

            if item:getContainer() == container
                    or not wouldExceedBackpackCapacity(player, container, item) then return end

        local now = type(getTimestampMs) == "function"
            and getTimestampMs() or math.floor(os.clock() * 1000)
        local previous = capacityNoticeByItem[item]
        if previous and previous.container == container and now - previous.at < 2000 then
            return
        end
        capacityNoticeByItem[item] = { container = container, at = now }
        if not showCapacityDestinations(player, container, item) then
            pcall(HaloTextHelper.addText, player,
                "La mochila esta llena; el objeto se queda donde esta.", " ", 255, 220, 120)
        end
    end

    local originalTransferIsValid = ISInventoryTransferAction.isValid
    ISInventoryTransferAction.isValid = function(self, ...)
        local player = self and self.character
        local item = self and self.item
        local container = self and self.destContainer
        if player and item and container and isBackpackInventory(container)
                and item:getContainer() ~= container then
            if wouldExceedBackpackCapacity(player, container, item) then
                notifyOverCapacity(self)
                return false
            end
        end

        local valid = withBackpackCapacityEnforced(self and self.destContainer,
            originalTransferIsValid, self, ...)
        if not valid then notifyOverCapacity(self) end
        return valid
    end

    -- Workshop queues InventoryTetris transfers through vanilla
    -- ISInventoryTransferAction:perform(), which checks isValid for each item.
    -- Keep this final check at the mutation point as a defense against any
    -- transfer route that reaches transferItem without a current weight check.
    local originalTransferItem = ISInventoryTransferAction.transferItem
    if type(originalTransferItem) == "function" then
        ISInventoryTransferAction.transferItem = function(self, item, ...)
            local player = self and self.character
            local container = self and self.destContainer
            if player and item and container and isBackpackInventory(container)
                    and item:getContainer() ~= container then
                if wouldExceedBackpackCapacity(player, container, item) then
                    notifyOverCapacity(self, item)
                    return
                end
            end
            return originalTransferItem(self, item, ...)
        end
    else
        print("[ChilaSeda_InventoryTetrisSizeCap] transferItem unavailable; per-item capacity guard not installed")
    end

    -- Tetris drags are eventually committed by ISInventoryTransferAction, but
    -- other wrappers can bypass that action-level method. Guard vanilla's
    -- actual removal/addition point before it removes the item from its source.
    -- This also rechecks each queued item after earlier items have transferred.
    require "TimedActions/ISTransferAction"
    local originalLowLevelTransferItem = ISTransferAction.transferItem
    if type(originalLowLevelTransferItem) == "function" then
        ISTransferAction.transferItem = function(self, player, item, sourceContainer,
                destinationContainer, ...)
            if player and item and destinationContainer
                    and isBackpackInventory(destinationContainer)
                    and item:getContainer() ~= destinationContainer then
                if wouldExceedBackpackCapacity(player, destinationContainer, item) then
                    notifyOverCapacity(nil, item, destinationContainer, player)
                    return item
                end
            end
            return originalLowLevelTransferItem(self, player, item, sourceContainer,
                destinationContainer, ...)
        end
    else
        print("[ChilaSeda_InventoryTetrisSizeCap] low-level transferItem unavailable; final backpack capacity guard not installed")
    end

    local originalHasRoomForAny = ISInventoryPaneContextMenu.hasRoomForAny
    ISInventoryPaneContextMenu.hasRoomForAny = function(playerObj, container, items, ...)
        return withBackpackCapacityEnforced(container,
            originalHasRoomForAny, playerObj, container, items, ...)
    end

    TetrisItemData.ChilaSedaBackpackCapacityValidationInstalled = true
    print("[ChilaSeda_InventoryTetrisSizeCap] restored weight-capacity checks for backpack insertions and transfers, including vanilla's final mutation point")
end

Events.OnGameStart.Add(installBackpackCapacityValidation)
