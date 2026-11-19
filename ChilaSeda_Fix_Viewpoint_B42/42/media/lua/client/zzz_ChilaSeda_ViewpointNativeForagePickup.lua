-- Targets Viewpoint's native 3D forage pins and queues their normal pickup action.
require "ISUI/ISUIElement"

local TAG = "[ChilaSeda_ViewpointNativeForagePickup] "
local AIM_RADIUS = 110
local MAX_REACH = 12
local PIN_LIFT = 0.35
local warned = false
local pickupPrompt

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

local function aimedFindForPickup()
    if not nativeViewpointActive() or not nativeForageAvailable() then return end
    if type(isGamePaused) == "function" and isGamePaused() then return end

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    if not player then return end
    local manager = getManager(player)
    if not manager or manager.isSearchMode ~= true then return end

    local okVehicle, vehicle = pcall(player.getVehicle, player)
    if okVehicle and vehicle ~= nil then return end

    return aimedForagePin(manager)
end

local function pickupAimedFind()
    local selected = aimedFindForPickup()
    if selected then queueNativePickup(selected) end
end

local function pickupKeyName()
    local key = ChilaSedaViewpointNativeForagePickupKey
    if type(key) ~= "number" or key <= 0 then return nil end
    if Keyboard and type(Keyboard.getKeyName) == "function" then
        local ok, name = pcall(Keyboard.getKeyName, key)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
    return tostring(key)
end

local PickupPrompt = ISUIElement:derive("ChilaSedaViewpointNativeForagePickupPrompt")

function PickupPrompt:new()
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.anchorLeft, o.anchorTop = true, true
    o.target = nil
    o.nextTargetUpdate = 0
    return o
end

function PickupPrompt:onMouseDown() return false end
function PickupPrompt:onMouseUp() return false end
function PickupPrompt:onRightMouseDown() return false end
function PickupPrompt:onRightMouseUp() return false end

function PickupPrompt:prerender()
    local now = type(getTimestampMs) == "function"
        and getTimestampMs() or math.floor(os.clock() * 1000)
    if now < self.nextTargetUpdate then return end
    self.nextTargetUpdate = now + 100
    self.target = pickupKeyName() and aimedFindForPickup() or nil
end

function PickupPrompt:render()
    local target = self.target
    local keyName = pickupKeyName()
    if not target or not keyName then return end

    local text = "[" .. keyName .. "]"
    local width = 42
    if type(getTextManager) == "function" and UIFont and UIFont.Small then
        local ok, measured = pcall(function()
            return getTextManager():MeasureStringX(UIFont.Small, text)
        end)
        if ok and type(measured) == "number" then width = measured + 12 end
    end
    local height = 20
    local x, y = target.screenX + 18, target.screenY - height / 2
    local screenWidth = getCore and getCore():getScreenWidth() or nil
    if type(screenWidth) == "number" then x = math.min(x, screenWidth - width - 4) end
    x = math.max(4, x)
    y = math.max(4, y)

    self:drawRect(x, y, width, height, 0.82, 0.02, 0.02, 0.02)
    self:drawTextCentre(text, x + width / 2, y + 2, 1, 0.86, 0.35, 1, UIFont and UIFont.Small or UIFont.Medium)
end

local function createPickupPrompt()
    if pickupPrompt then pickupPrompt:removeFromUIManager() end
    pickupPrompt = PickupPrompt:new()
    pickupPrompt:initialise()
    pickupPrompt:addToUIManager()
    pcall(function() pickupPrompt:backMost() end)
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
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(createPickupPrompt)
end
createPickupPrompt()

print(TAG .. "native 3D search pickup key handler and pin prompt loaded")
