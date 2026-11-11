require "Moveables/ISMoveableSpriteProps"
require "TimedActions/ISInventoryTransferUtil"
require "TimedActions/ISInventoryTransferAction"

local TAG = "[ChilaSeda_ViewpointBrokenGlassDestination] "

local function selectedDestination(player)
    if not player or type(getPlayerInventory) ~= "function" then return nil end
    local page = getPlayerInventory(player:getPlayerNum())
    local main = player:getInventory()
    local selected = page and page.inventoryPane and page.inventoryPane.inventory
    if selected and selected ~= main and type(selected.getItems) == "function"
            and selected:getType() ~= "floor" then
        return selected
    end
    return main
end

local function destinationName(player, container)
    if container == player:getInventory() then return "inventario principal" end
    local containingItem = container and container.getContainingItem
        and container:getContainingItem() or nil
    if containingItem and containingItem.getDisplayName then
        return containingItem:getDisplayName()
    end
    local parent = container and container.getParent and container:getParent() or nil
    if parent and parent.getDisplayName then return parent:getDisplayName() end
    return container and container.getType and container:getType() or "contenedor"
end

local function notify(player, text, fallback)
    if HaloTextHelper and type(HaloTextHelper.addText) == "function" then
        if fallback then
            HaloTextHelper.addText(player, text, " ", 255, 180, 70)
        else
            HaloTextHelper.addText(player, text, " ", 130, 235, 150)
        end
    end
end

local function canStore(container, player, item)
    if not container or not player or not item then return false end
    return container:isItemAllowed(item) and container:hasRoomFor(player, item)
        and container:getCapacityWeight() + item:getUnequippedWeight()
            <= container:getEffectiveCapacity(player)
end

local props = ISMoveableSpriteProps
if not props or type(props.pickUpMoveableInternal) ~= "function"
        or props.chilaBrokenGlassDestinationInstalled then
    print(TAG .. "moveable pickup API unavailable or already wrapped")
    return
end

local originalPickup = props.pickUpMoveableInternal
props.pickUpMoveableInternal = function(self, player, square, object, spriteInstance,
        spriteName, createItem, rotating)
    local item = originalPickup(self, player, square, object, spriteInstance,
        spriteName, createItem, rotating)
    if not item or self.isoType ~= "IsoBrokenGlass" or not createItem then return item end

    local main = player and player:getInventory()
    if not main or item:getContainer() ~= main then return item end
    local destination = selectedDestination(player)
    if not destination or destination == main then return item end

    if not canStore(destination, player, item) then
        notify(player, "Mochila seleccionada llena; cristales rotos en inventario principal", true)
        return item
    end

    local action = ISInventoryTransferUtil.newInventoryTransferAction(
        player, item, main, destination)
    if action and action:isValid() then
        ISTimedActionQueue.add(action)
        notify(player, "Cristales rotos guardados en: " .. destinationName(player, destination), false)
    else
        notify(player, "No se pudieron mover los cristales; quedaron en inventario principal", true)
    end
    return item
end
props.chilaBrokenGlassDestinationInstalled = true

print(TAG .. "broken-glass pickup routes to the selected container and reports fallback")
