-- Targets Viewpoint's native 3D forage pins and queues their normal pickup action.
local TAG = "[ChilaSeda_ViewpointNativeForagePickup] "
local AIM_RADIUS = 110
local MAX_REACH = 12
local PIN_LIFT = 0.35
local warned = false

local function warnOnce(message)
    if warned then return end
    warned = true
    print(TAG .. message)
end

local function nativeViewpointActive()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.active) ~= "function" then return false end
    local ok, active = pcall(bridge.active)
    return ok and active == true
end

local function nativeForageAvailable()
    return type(ViewpointForage) == "table" and type(ViewpointForage.found) == "function"
end

local function getManager(player)
    if not player or not ISSearchManager or type(ISSearchManager.getManager) ~= "function" then return nil end
    local ok, manager = pcall(ISSearchManager.getManager, player)
    return ok and manager or nil
end

local function iconIsSeen(icon)
    if not icon or type(icon.getIsSeen) ~= "function" then return false end
    local ok, seen = pcall(icon.getIsSeen, icon)
    return ok and seen == true
end

local function iconAlpha(icon)
    if not icon or type(icon.getAlpha) ~= "function" then return 0 end
    local ok, alpha = pcall(icon.getAlpha, icon)
    return ok and type(alpha) == "number" and alpha or 0
end

local function targetPin(icon, bridge, centerX, centerY, width, height)
    if not icon or icon.isBeingRemoved or type(icon.onMouseDoubleClick) ~= "function"
            or not iconIsSeen(icon) or iconAlpha(icon) <= 0 then
        return nil
    end
    local distance = icon.distanceToPlayer
    if type(distance) ~= "number" or distance > MAX_REACH then return nil end

    local x, y, z = icon.xCoord, icon.yCoord, icon.zCoord or 0
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return nil end
    -- ISForageIcon stores the tile corner; Viewpoint Foraging projects its centre.
    if icon.iconClass == "forageIcon" and x == math.floor(x) and y == math.floor(y) then
        x, y = x + 0.5, y + 0.5
    end
    local ok, inFront = pcall(bridge.projectNativeForagePin, x, y, z, PIN_LIFT)
    if not ok or inFront ~= true then return nil end

    local okScreen, screenX, screenY = pcall(function()
        return bridge.nativeForagePinScreenX(), bridge.nativeForagePinScreenY()
    end)
    if not okScreen then return nil end
    if type(screenX) ~= "number" or type(screenY) ~= "number"
            or screenX < 0 or screenX > width or screenY < 0 or screenY > height then
        return nil
    end
    local dx, dy = screenX - centerX, screenY - centerY
    local distanceSquared = dx * dx + dy * dy
    if distanceSquared > AIM_RADIUS * AIM_RADIUS then return nil end
    return distanceSquared, screenX, screenY
end

local function eachNativeIcon(manager, callback)
    local categories = manager.iconCategories
    if type(categories) ~= "table" then
        for _, icon in pairs(manager.forageIcons or {}) do callback(icon) end
        return
    end
    for iconClass in pairs(categories) do
        local icons = manager[iconClass]
        if type(icons) == "table" then
            for _, icon in pairs(icons) do callback(icon) end
        end
    end
end

local function aimedForagePin(manager)
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.prepareNativeForagePins) ~= "function"
            or type(bridge.projectNativeForagePin) ~= "function" then
        warnOnce("native 3D pin projection is unavailable")
        return nil
    end
    local ok, prepared = pcall(bridge.prepareNativeForagePins, 0)
    if not ok or prepared ~= true then return nil end

    local okSize, width, height = pcall(function()
        return bridge.nativeForagePinScreenWidth(), bridge.nativeForagePinScreenHeight()
    end)
    if not okSize then return nil end
    if type(width) ~= "number" or type(height) ~= "number" or width <= 0 or height <= 0 then return nil end
    local centerX, centerY = width / 2, height / 2
    local best, bestDistance
    eachNativeIcon(manager, function(icon)
        local distance, screenX, screenY = targetPin(icon, bridge, centerX, centerY, width, height)
        if distance and (not bestDistance or distance < bestDistance) then
            best = { icon = icon, screenX = screenX, screenY = screenY }
            bestDistance = distance
        end
    end)
    return best
end

local function queueNativePickup(target)
    local icon = target and target.icon
    if not icon or icon.isBeingRemoved or type(icon.onMouseDoubleClick) ~= "function" then return false end
    local x, y = 0, 0
    if type(icon.getX) == "function" then
        local ok, value = pcall(icon.getX, icon)
        if ok and type(value) == "number" then x = value end
    end
    if type(icon.getY) == "function" then
        local ok, value = pcall(icon.getY, icon)
        if ok and type(value) == "number" then y = value end
    end
    local oldX, oldY = x, y
    local width = type(icon.getWidth) == "function" and select(2, pcall(icon.getWidth, icon)) or nil
    local height = type(icon.getHeight) == "function" and select(2, pcall(icon.getHeight, icon)) or nil
    if type(width) ~= "number" then width = 0 end
    if type(height) ~= "number" then height = 0 end
    x = target.screenX - width / 2
    y = target.screenY - height
    if type(icon.setX) == "function" then pcall(icon.setX, icon, x) end
    if type(icon.setY) == "function" then pcall(icon.setY, icon, y) end
    -- Matches the addon's G path: delegate to the icon's vanilla double-click callback.
    local ok, err = pcall(icon.onMouseDoubleClick, icon, x, y)
    if type(icon.setX) == "function" then pcall(icon.setX, icon, oldX) end
    if type(icon.setY) == "function" then pcall(icon.setY, icon, oldY) end
    if not ok then warnOnce("native forage pickup callback failed: " .. tostring(err)) end
    return ok
end

local function pickupAimedFind()
    if not nativeViewpointActive() or not nativeForageAvailable() then return end
    if type(isGamePaused) == "function" and isGamePaused() then return end

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    if not player then return end
    local manager = getManager(player)
    if not manager or manager.isSearchMode ~= true then return end

    local okVehicle, vehicle = pcall(player.getVehicle, player)
    if okVehicle and vehicle ~= nil then return end

    local selected = aimedForagePin(manager)
    if selected then queueNativePickup(selected) end
end

local function onKeyPressed(key)
    local pickupKey = ChilaSedaViewpointNativeForagePickupKey
    if type(pickupKey) == "number" and pickupKey > 0 and key == pickupKey then
        pickupAimedFind()
    end
end

if Events and Events.OnKeyPressed and type(Events.OnKeyPressed.Add) == "function" then
    Events.OnKeyPressed.Add(onKeyPressed)
end

print(TAG .. "native 3D search pickup key handler loaded")
