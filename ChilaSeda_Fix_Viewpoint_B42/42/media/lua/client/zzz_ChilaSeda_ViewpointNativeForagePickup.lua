-- Targets Viewpoint's native 3D forage pins and queues their normal pickup action.
require "ISUI/ISUIElement"

local TAG = "[ChilaSeda_ViewpointNativeForagePickup] "
local AIM_RADIUS = 110
local MAX_REACH = 12
local PIN_LIFT = 0.35
local PICKUP_PROMPT_GAP = 8
local PROMPT_REFRESH_MS = 16
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

local function displayName(item)
    if not item then return nil end
    for _, methodName in ipairs({"getDisplayName", "getName"}) do
        local method = item[methodName]
        if type(method) == "function" then
            local ok, name = pcall(method, item)
            if ok and type(name) == "string" and name ~= "" then return name end
        end
    end
    return nil
end

local function foundItemName(icon)
    if icon and icon.identified then
        local itemList = icon.itemList
        local listHasItems = false
        if itemList and type(itemList.isEmpty) == "function" then
            local ok, empty = pcall(itemList.isEmpty, itemList)
            listHasItems = ok and empty ~= true
        end
        if listHasItems and type(itemList.get) == "function" then
            local ok, item = pcall(itemList.get, itemList, 0)
            if ok then
                local name = displayName(item)
                if name then return name end
            end
        end
        local name = displayName(icon.itemObj)
        if name then return name end
    end
    if type(getText) == "function" then
        local key = "UI_ChilaSeda_ViewpointNativeForageFound"
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return nil
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
    if best then best.itemName = foundItemName(best.icon) end
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
    -- Viewpoint moves the projected pin with each camera frame; refresh at roughly
    -- render rate instead of letting a throttled sample lag behind the camera.
    self.nextTargetUpdate = now + PROMPT_REFRESH_MS
    self.target = pickupKeyName() and aimedFindForPickup() or nil
end

function PickupPrompt:render()
    local target = self.target
    local keyName = pickupKeyName()
    if not target or not keyName then return end

    local textKey = "UI_ChilaSeda_ViewpointNativeForagePrompt"
    local text = keyName
    if type(getText) == "function" then
        local ok, translated = pcall(getText, textKey, keyName)
        if ok and type(translated) == "string" and translated ~= "" and translated ~= textKey then
            text = translated
        end
    end
    local nameText = target.itemName
    local font = UIFont and (UIFont.Small or UIFont.Medium) or nil
    local function textWidth(value)
        if type(getTextManager) == "function" and font then
            local ok, measured = pcall(function()
                return getTextManager():MeasureStringX(font, value)
            end)
            if ok and type(measured) == "number" then return measured + 12 end
        end
        return math.max(42, #value * 7 + 12)
    end

    local width = textWidth(text)
    if type(getTextManager) == "function" and UIFont and UIFont.Small then
        width = math.max(42, width)
    end
    local height = 20
    local core = getCore and getCore() or nil
    local screenWidth = core and core:getScreenWidth() or nil
    local function centeredX(textWidthValue)
        local x = target.screenX - textWidthValue / 2
        if type(screenWidth) == "number" then
            x = math.max(4, math.min(x, math.max(4, screenWidth - textWidthValue - 4)))
        end
        return x
    end

    local keyX = centeredX(width)
    local keyY = math.max(4, target.screenY - height - PICKUP_PROMPT_GAP)
    self:drawRect(keyX, keyY, width, height, 0.82, 0.02, 0.02, 0.02)
    self:drawTextCentre(text, keyX + width / 2, keyY + 2, 1, 0.86, 0.35, 1, font)

    if type(nameText) == "string" and nameText ~= "" then
        local nameWidth = textWidth(nameText)
        local nameX = centeredX(nameWidth)
        local nameY = math.max(4, keyY - height - 2)
        self:drawRect(nameX, nameY, nameWidth, height, 0.82, 0.02, 0.02, 0.02)
        self:drawTextCentre(nameText, nameX + nameWidth / 2, nameY + 2, 1, 1, 1, 1, font)
    end
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
