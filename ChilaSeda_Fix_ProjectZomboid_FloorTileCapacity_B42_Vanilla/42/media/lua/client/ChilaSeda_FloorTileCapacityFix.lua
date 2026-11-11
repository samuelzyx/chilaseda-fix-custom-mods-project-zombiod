require "ISUI/ISInventoryPage"

local MAX_FLOOR_TILE_CAPACITY = 1000

local function installFloorCapacity()
    if not ISInventoryPage or type(ISInventoryPage.GetFloorContainer) ~= "function" then
        return false
    end
    if ISInventoryPage.ChilaSedaFloorCapacityInstalled then
        return true
    end

    local originalGetFloorContainer = ISInventoryPage.GetFloorContainer
    ISInventoryPage.GetFloorContainer = function(playerNum)
        local container = originalGetFloorContainer(playerNum)
        if container and type(container.setCapacity) == "function" then
            container:setCapacity(MAX_FLOOR_TILE_CAPACITY)
        end
        return container
    end
    ISInventoryPage.ChilaSedaFloorCapacityInstalled = true
    print("[ChilaSeda FloorTileCapacity] installed; floor tile capacity="
        .. tostring(MAX_FLOOR_TILE_CAPACITY))
    return true
end

if not installFloorCapacity() and Events and Events.OnGameStart then
    Events.OnGameStart.Add(installFloorCapacity)
end
