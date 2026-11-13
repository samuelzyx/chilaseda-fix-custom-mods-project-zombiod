-- Connects Viewpoint's integrated search state to this patch's native fog renderer.
local TAG = "[ChilaSeda_ViewpointSearchFog] "
local last = {}
local warned = false

local function warnOnce(message)
    if warned then return end
    warned = true
    print(TAG .. message)
end

local function integratedForageAvailable()
    return type(ViewpointForage) == "table" and type(ViewpointForage.found) == "function"
end

local function bridgeActive()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.active) ~= "function" then return false end
    local ok, active = pcall(bridge.active)
    return ok and active == true
end

local function searchManager(player)
    if not player or not ISSearchManager or type(ISSearchManager.getManager) ~= "function" then return nil end
    local ok, manager = pcall(ISSearchManager.getManager, player)
    return ok and manager or nil
end

local function searchRadius(manager)
    if manager and type(manager.radius) == "number" then return manager.radius end
    if manager and type(manager.maxRadius) == "number" then return manager.maxRadius end
    return 3
end

local function updateFog()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.setSearchFog) ~= "function" then return end

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    local manager = searchManager(player)
    local active = integratedForageAvailable() and bridgeActive()
    local inVehicle = false
    if player then
        local ok, vehicle = pcall(player.getVehicle, player)
        inVehicle = ok and vehicle ~= nil
    end
    local on = active and manager ~= nil and manager.isSearchMode == true and not inVehicle

    local radius, darkness, desat = 10, 0.1, 0
    if manager then
        radius = searchRadius(manager)
        local overlay = manager.overlayValues
        if overlay then
            darkness = overlay.darkness or darkness
            desat = overlay.desaturation or 0
        end
    end

    local feather, style = 3, 0
    local strength = type(ChilaSedaViewpointNativeFogStrength) == "number"
        and math.max(0, math.min(1, ChilaSedaViewpointNativeFogStrength)) or 1
    if last.on == on and last.radius == radius and last.darkness == darkness and last.desat == desat
            and last.feather == feather and last.style == style and last.strength == strength then
        return
    end
    last = { on = on, radius = radius, darkness = darkness, desat = desat,
        feather = feather, style = style, strength = strength }
    local ok, err = pcall(bridge.setSearchFog, on == true, radius, feather, darkness, desat, style, strength)
    if not ok then warnOnce("Workshop fog bridge call failed: " .. tostring(err)) end
end

local function clearVanillaOverlay(manager)
    if not integratedForageAvailable() or not bridgeActive() or manager.isOverride then return end
    local overlay = manager.searchModeOverlay
    if not overlay then return end
    pcall(function()
        overlay:getBlur():setTargets(0, 0)
        overlay:getDesat():setTargets(0, 0)
        overlay:getDarkness():setTargets(0, 0)
    end)
end

if ISSearchManager and type(ISSearchManager.updateOverlay) == "function" then
    local vanillaUpdateOverlay = ISSearchManager.updateOverlay
    ISSearchManager.updateOverlay = function(self, ...)
        local result = vanillaUpdateOverlay(self, ...)
        clearVanillaOverlay(self)
        return result
    end
end

if Events and Events.OnPreUIDraw and type(Events.OnPreUIDraw.Add) == "function" then
    Events.OnPreUIDraw.Add(updateFog)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(updateFog)
end
updateFog()
