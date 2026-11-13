require "ISUI/ISInventoryPaneContextMenu"

local TAG = "[ChilaSeda_InventoryTetrisNoPaneGuard] "
local menu = ISInventoryPaneContextMenu
if not menu or type(menu.getContainers) ~= "function" then
    print(TAG .. "getContainers is unavailable; guard skipped")
    return
end

-- Inventory Tetris adds keyring containers from OnGameBoot, but its wrapper
-- assumes the player's inventory page and pane already exist. Weight Monitor
-- and other update hooks can query carried containers before those UI objects
-- are created, so keep a safe inventory-only path for that case.
local baseGetContainers = menu.getContainers
local warnedFallback = false

local function inventoryPageReady(character)
    if not character or type(getPlayerInventory) ~= "function" then return false end
    local okNumber, playerNum = pcall(character.getPlayerNum, character)
    if not okNumber or type(playerNum) ~= "number" then return false end
    local okPage, page = pcall(getPlayerInventory, playerNum)
    if not okPage or not page or not page.inventoryPane then return false end
    return page.inventoryPane.inventoryPage ~= nil
end

local function fallbackContainers(character, selectedItem, ...)
    local result = ArrayList.new()
    local visited = {}
    local function addTree(container)
        if not container or visited[container] then return end
        visited[container] = true
        result:add(container)
        local okItems, items = pcall(container.getItems, container)
        if not okItems or not items then return end
        local okSize, size = pcall(items.size, items)
        if not okSize or type(size) ~= "number" then return end
        for index = 0, size - 1 do
            local okItem, item = pcall(items.get, items, index)
            if okItem and item and instanceof(item, "InventoryContainer") then
                local okInventory, nested = pcall(item.getInventory, item)
                if okInventory then addTree(nested) end
            end
        end
    end

    if character and type(character.getInventory) == "function" then
        local okInventory, inventory = pcall(character.getInventory, character)
        if okInventory then addTree(inventory) end
    end
    if selectedItem and type(selectedItem.getContainer) == "function" then
        local okContainer, container = pcall(selectedItem.getContainer, selectedItem)
        if okContainer then addTree(container) end
    end

    -- Retain any additional containers the pre-Tetris helper can safely see.
    local okBase, base = pcall(baseGetContainers, character, selectedItem, ...)
    if okBase and base and type(base.size) == "function" and type(base.get) == "function" then
        local okSize, size = pcall(base.size, base)
        if okSize and type(size) == "number" then
            for index = 0, size - 1 do
                local okContainer, container = pcall(base.get, base, index)
                if okContainer then addTree(container) end
            end
        end
    end

    if not warnedFallback then
        warnedFallback = true
        print(TAG .. "inventory UI not ready; using carried containers")
    end
    return result
end

local function install()
    if menu.ChilaSedaNoPaneGuardInstalled then return end
    local original = menu.getContainers
    menu.getContainers = function(character, selectedItem, ...)
        if not inventoryPageReady(character) then
            return fallbackContainers(character, selectedItem, ...)
        end
        local ok, result = pcall(original, character, selectedItem, ...)
        if ok and result then return result end
        return fallbackContainers(character, selectedItem, ...)
    end
    menu.ChilaSedaNoPaneGuardInstalled = true
    print(TAG .. "guard installed around Inventory Tetris container lookup")
end

-- This callback is registered after Inventory Tetris because the local mod
-- declares loadModAfter=INVENTORY_TETRIS; wrap its OnGameBoot-installed hook.
Events.OnGameBoot.Add(install)