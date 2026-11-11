require "ISUI/ISInventoryPane"
require "ISUI/PlayerData/ISPlayerData"
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISInventoryTransferAction"

local viewpointLoaded = pcall(require, "Viewpoint_Loot")
if not viewpointLoaded or type(ViewpointLoot) ~= "table" then
    print("[ChilaSeda_ViewpointCorpseLootDestination] Viewpoint unavailable; patch skipped.")
    return
end

if not ISInventoryPane or type(ISInventoryPane.transferItemsByWeight) ~= "function"
        or not ISInventoryTransferUtil
        or type(ISInventoryTransferUtil.newInventoryTransferAction) ~= "function" then
    print("[ChilaSeda_ViewpointCorpseLootDestination] inventory transfer API unavailable; patch skipped.")
    return
end

local function isCorpseContainer(container)
    if not container then return false end
    local kind = container:getType()
    if kind == "inventorymale" or kind == "inventoryfemale" then return true end
    local parent = container:getParent()
    return parent ~= nil and instanceof(parent, "IsoDeadBody")
end

local function selectedPlayerContainer(playerNum)
    local page = getPlayerInventory(playerNum)
    if not page then return nil, nil end
    local pane = page.inventoryPane
    local selected = pane and pane.inventory
    if selected and type(selected.getItems) == "function" then
        return selected, page
    end
    return page.inventory, page
end

local function canStoreIn(container, character, item)
    return container and character and item and container:isItemAllowed(item)
        and container:hasRoomFor(character, item)
        and container:getCapacityWeight() + item:getUnequippedWeight()
            <= container:getEffectiveCapacity(character)
end

local function callWithPageInventory(page, inventory, callback, ...)
    local previous = page.inventory
    page.inventory = inventory
    local ok, result = pcall(callback, ...)
    page.inventory = previous
    if not ok then error(result, 0) end
    return result
end

local originalTransferFactory = ISInventoryTransferUtil.newInventoryTransferAction
ISInventoryTransferUtil.newInventoryTransferAction = function(character, item, source, destination, time)
    if character and item and isCorpseContainer(source)
            and ChilaSeda_EquipFromCorpse ~= true then
        local playerNum = character:getPlayerNum()
        local selected, page = selectedPlayerContainer(playerNum)
        local mainInventory = character:getInventory()
        if selected and page and selected ~= mainInventory and canStoreIn(selected, character, item)
            and (destination == page.inventory or destination == mainInventory or destination == selected) then
            return callWithPageInventory(page, mainInventory, originalTransferFactory,
                character, item, source, selected, time)
        end
    end
    -- ISGrabCorpseItem.complete always inserts into character:getInventory().
    -- Temporarily presenting the real root inventory to its dispatcher makes
    -- it choose ISInventoryTransferAction for a selected nested bag instead.
    return originalTransferFactory(character, item, source, destination, time)
end

local function itemsAllFromCorpses(items)
    if type(items) ~= "table" or #items == 0 then return false end
    for _, item in ipairs(items) do
        if not item or not isCorpseContainer(item:getContainer()) then return false end
    end
    return true
end

local originalTransferByWeight = ISInventoryPane.transferItemsByWeight
ISInventoryPane.transferItemsByWeight = function(self, items, destination, ...)
    local page = getPlayerInventory(self.player)
    local selected = page and page.inventoryPane and page.inventoryPane.inventory
    local player = getSpecificPlayer(self.player)
    local mainInventory = player and player:getInventory()
    if page and selected and player and selected ~= mainInventory
        and (destination == page.inventory or destination == mainInventory or destination == selected)
        and itemsAllFromCorpses(items) then
        return callWithPageInventory(page, mainInventory, originalTransferByWeight,
            self, items, selected, ...)
    end
    -- With a bag selected, corpseStorageCheck no longer routes these items
    -- through ISGrabCorpseItem, which ignores the requested destination.
    return originalTransferByWeight(self, items, destination, ...)
end
