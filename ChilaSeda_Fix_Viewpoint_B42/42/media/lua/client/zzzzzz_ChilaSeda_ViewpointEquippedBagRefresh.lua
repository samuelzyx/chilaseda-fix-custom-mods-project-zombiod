local TAG = "[ChilaSeda_ViewpointEquippedBagRefresh] "
local TRACE_ENABLED = true
local MAX_TRACE_LINES = 24
local traceLines = 0

local viewpointInventory = ViewpointInventory
if type(viewpointInventory) ~= "table" then
    viewpointInventory = {}
    ViewpointInventory = viewpointInventory
end
if viewpointInventory.chilaSedaEquippedBagRefreshLoaded then return end
viewpointInventory.chilaSedaEquippedBagRefreshLoaded = true

local function trace(message)
    if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    if type(print) == "function" then pcall(print, TAG .. message) end
end

local function countButtons(page)
    local buttons = page and page.backpacks
    if type(buttons) ~= "table" then return 0 end
    return #buttons
end

local function inventoryOf(item)
    if not item then return nil end
    local okContainer, isContainer = pcall(function() return item:IsInventoryContainer() end)
    if not okContainer or not isContainer then return nil end
    local okInventory, inventory = pcall(function() return item:getInventory() end)
    return okInventory and inventory or nil
end

local function isListed(page, inventory)
    if not inventory or type(page.backpacks) ~= "table" then return false end
    for _, button in ipairs(page.backpacks) do
        if button and button.inventory == inventory then return true end
    end
    return false
end

local function refresh(eventName, eventPlayer)
    if eventPlayer then
        local okPlayerNum, playerNum = pcall(function() return eventPlayer:getPlayerNum() end)
        if okPlayerNum and type(playerNum) == "number" and playerNum ~= 0 then return end
    end

    if type(getSpecificPlayer) ~= "function" then
        trace("event=" .. eventName .. " result=fallback reason=player-api-unavailable")
        return
    end
    local player = getSpecificPlayer(0)
    if not player then
        trace("event=" .. eventName .. " result=fallback reason=local-player-unavailable")
        return
    end
    if type(getPlayerInventory) ~= "function" then
        trace("event=" .. eventName .. " result=fallback reason=inventory-page-api-unavailable")
        return
    end
    local page = getPlayerInventory(0)
    if not page or type(page.refreshBackpacks) ~= "function" then
        trace("event=" .. eventName .. " result=fallback reason=refreshBackpacks-unavailable")
        return
    end

    local before = countButtons(page)
    local secondary = type(player.getSecondaryHandItem) == "function"
        and player:getSecondaryHandItem() or nil
    local secondaryInventory = inventoryOf(secondary)
    local okRefresh, err = pcall(page.refreshBackpacks, page)

    local screen = ViewpointInvScreen and ViewpointInvScreen.instance
    if screen then screen.dirty = true end

    local after = countButtons(page)
    if not okRefresh then
        trace("event=" .. eventName .. " result=fallback reason=refresh-call-failed error=" .. tostring(err))
    elseif secondaryInventory and not isListed(page, secondaryInventory) then
        trace("event=" .. eventName .. " result=fallback reason=secondary-container-not-listed buttons="
            .. tostring(before) .. "->" .. tostring(after))
    else
        local state = secondaryInventory and "listed" or "none"
        trace("event=" .. eventName .. " result=refreshed secondary-container=" .. state
            .. " buttons=" .. tostring(before) .. "->" .. tostring(after))
    end
end

local function subscribe(eventName, event, label)
    if event and type(event.Add) == "function" then
        event.Add(function(player) refresh(label, player) end)
    else
        trace("event=" .. label .. " result=fallback reason=" .. eventName .. "-unavailable")
    end
end

if Events then
    subscribe("OnEquipPrimary", Events.OnEquipPrimary, "primary")
    subscribe("OnEquipSecondary", Events.OnEquipSecondary, "secondary")
    subscribe("OnClothingUpdated", Events.OnClothingUpdated, "clothing")
else
    trace("event=register result=fallback reason=Events-unavailable")
end
