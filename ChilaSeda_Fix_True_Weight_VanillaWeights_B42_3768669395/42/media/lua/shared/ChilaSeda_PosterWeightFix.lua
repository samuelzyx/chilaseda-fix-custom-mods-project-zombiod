-- DGVPosters defines its wall posters as Furniture, so True Weight's
-- Literature preset does not rebalance them. Correct the script definitions
-- after True Weight, then migrate existing saved item instances as they are
-- present in the player's inventory or accessible open containers.

local POSTER_WEIGHT = 0.05
local POSTER_MODULE_PREFIX = "DGVPosters."

local function hasPosterPrefix(fullType)
    return type(fullType) == "string"
        and string.sub(fullType, 1, #POSTER_MODULE_PREFIX)
            == POSTER_MODULE_PREFIX
end

local function isDGVPoster(item)
    if not item then return false end

    if item.getFullType and hasPosterPrefix(item:getFullType()) then
        return true
    end
    if item.getFullName and hasPosterPrefix(item:getFullName()) then
        return true
    end
    return false
end

local function applyPosterWeight(item)
    if not isDGVPoster(item) then return false end
    local currentWeight = item:getActualWeight()
    if type(currentWeight) == "number"
            and math.abs(currentWeight - POSTER_WEIGHT) < 0.001 then
        return false
    end
    item:setActualWeight(POSTER_WEIGHT)
    return true
end

local function rebalancePosters()
    if not ScriptManager or not ScriptManager.instance then
        print("[ChilaSeda_PosterWeightFix] ScriptManager unavailable; poster weights unchanged")
        return
    end

    local allItems = ScriptManager.instance:getAllItems()
    if not allItems then
        print("[ChilaSeda_PosterWeightFix] item registry unavailable; poster weights unchanged")
        return
    end

    local changed = 0
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if applyPosterWeight(item) then changed = changed + 1 end
    end

    print("[ChilaSeda_PosterWeightFix] set " .. tostring(changed)
        .. " poster item(s) to " .. tostring(POSTER_WEIGHT) .. " kg")
end

local function rebalanceContainer(container, visited)
    if not container or visited[container] then return 0 end
    visited[container] = true

    local items = container:getItems()
    if not items then return 0 end

    local changed = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if applyPosterWeight(item) then changed = changed + 1 end

        if item and item.getInventory then
            local ok, nested = pcall(function() return item:getInventory() end)
            if ok and nested then
                changed = changed + rebalanceContainer(nested, visited)
            end
        end
    end
    return changed
end

local function rebalanceAccessibleItems()
    local playerCount = getNumActivePlayers and getNumActivePlayers() or 1
    for playerIndex = 0, playerCount - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(playerIndex)
        if player then
            local visited = {}
            rebalanceContainer(player:getInventory(), visited)

            local paneMenu = rawget(_G, "ISInventoryPaneContextMenu")
            if paneMenu and paneMenu.getContainers then
                local ok, containers = pcall(function()
                    return paneMenu.getContainers(player)
                end)
                if ok and containers then
                    for i = 0, containers:size() - 1 do
                        rebalanceContainer(containers:get(i), visited)
                    end
                end
            end
        end
    end
end

local tickCounter = 0
local function onTick()
    tickCounter = tickCounter + 1
    if tickCounter < 120 then return end
    tickCounter = 0
    rebalanceAccessibleItems()
end

Events.OnLoadedTileDefinitions.Add(rebalancePosters)
Events.OnTick.Add(onTick)
