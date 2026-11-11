-- Reconcile Viewpoint Foraging pins with Rolling Hills terrain.
-- Use Rolling Hills' public selected-height API to align pins to terrain relative
-- to the player's camera origin. Viewpoint Foraging owns the camera projection.

require "ViewpointForaging/VPF_Core"
require "ViewpointForaging/VPF_Icons"

local VPF = ViewpointForaging
local TAG = "[ChilaSeda_ViewpointForagingHeightFix] "

if not VPF or type(VPF.project) ~= "function" or type(VPF.placePin) ~= "function" then
    print(TAG .. "Could not install: Viewpoint Foraging API is unavailable")
    return
end

if VPF.ChilaSedaHeightFixInstalled then
    return
end
VPF.ChilaSedaHeightFixInstalled = true

local HeightCalibration = require "ChilaSeda_ViewpointForagingHeightCalibration"

local vanillaProject = VPF.project
local vanillaPlacePin = VPF.placePin
local currentIcon = nil
local currentProjection = nil
local warned = false
local applied = false
local projectLogged = false
local placePinLogged = false
local playerHeightCache = {}
local pinLogState = setmetatable({}, { __mode = "k" })
local nextPinId = 0
local sessionId = nil
local logName = nil

local function safeText(value)
    if value == nil then return "UNAVAILABLE" end
    local ok, result = pcall(tostring, value)
    if not ok or type(result) ~= "string" then return "UNAVAILABLE" end
    local cleaned = result:gsub("[\r\n\t|;]", "_")
    return cleaned
end

local function numberText(value)
    if type(value) ~= "number" then return "UNAVAILABLE" end
    return string.format("%.6f", value)
end

local function appendLog(line)
    local ok, err = pcall(function()
        local writer = getFileWriter(logName, true, true)
        if not writer then error("getFileWriter returned nil") end
        writer:write(line .. "\n")
        writer:close()
    end)
    if not ok then
        print(TAG .. "diagnostic log write failed: " .. safeText(err))
    end
end

local function startSession()
    local sessionClock = os.time()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and value then sessionClock = value end
    end
    sessionId = os.date("%Y%m%d_%H%M%S") .. "_" .. tostring(sessionClock)
    logName = "ViewpointRebusquedaHills\\" .. sessionId .. ".log"
    pinLogState = setmetatable({}, { __mode = "k" })
    nextPinId = 0
    playerHeightCache = {}
    currentIcon = nil
    currentProjection = nil
    warned = false
    applied = false
    projectLogged = false
    placePinLogged = false
        appendLog("SESSION_START session=" .. sessionId .. " modversion=1.3.15")
end

local function iconValue(icon, method)
    if not icon or type(icon[method]) ~= "function" then return nil end
    local ok, value = pcall(function() return icon[method](icon) end)
    if ok then return value end
    return nil
end

local function sampleSignature(icon, projection)
    local function key(value)
        if type(value) == "number" then return string.format("%.3f", value) end
        return safeText(value)
    end
    local playerX = projection and projection.playerX
    local playerY = projection and projection.playerY
    return table.concat({
        safeText(icon.iconClass),
        safeText(icon.iconID),
        safeText(icon.itemType),
        safeText(icon.itemName),
        key(icon.xCoord), key(icon.yCoord), key(icon.zCoord),
        type(playerX) == "number" and tostring(math.floor(playerX)) or "UNAVAILABLE",
        type(playerY) == "number" and tostring(math.floor(playerY)) or "UNAVAILABLE",
        key(projection and projection.playerZ),
        key(projection and projection.pinHeight),
        key(projection and projection.playerHeight),
        key(projection and projection.heightDelta),
        key(projection and projection.heightCorrection),
        key(projection and projection.appliedCorrection),
        key(projection and projection.automaticLift),
        key(projection and projection.manualOffset),
        key(projection and projection.manualAnchorX),
        key(projection and projection.manualAnchorY),
        key(projection and projection.manualAnchorDistance),
        key(projection and projection.manualAnchorCount),
        safeText(projection and projection.manualAnchorKind),
        safeText(projection and projection.manualAnchorId),
        safeText(projection and projection.heightSourceStatus),
        key(projection and projection.baseLift),
        key(projection and projection.finalLift),
        safeText(projection and projection.pinReason),
        safeText(projection and projection.playerReason),
        safeText(projection and projection.pinEnabled),
        safeText(projection and projection.playerEnabled),
        safeText(projection and projection.pinReady),
        safeText(projection and projection.playerReady),
        safeText(icon.vpfOnScreen),
        key(icon.pinOffset),
        type(icon.zoom) == "number" and tostring(math.floor(icon.zoom * 20)) or "UNAVAILABLE",
        type(projection and projection.screenX) == "number"
            and tostring(math.floor(projection.screenX / 16)) or "UNAVAILABLE",
        type(projection and projection.screenY) == "number"
            and tostring(math.floor(projection.screenY / 16)) or "UNAVAILABLE",
        type(projection and projection.vpfScreenY) == "number"
            and tostring(math.floor(projection.vpfScreenY / 16)) or "UNAVAILABLE",
    }, "|")
end

local function logPinSample(icon, projection, placementOk, placementResult)
    if not icon or (icon.iconClass ~= "forageIcon" and icon.iconClass ~= "worldObject") then
        return
    end
    if not sessionId then startSession() end
    local signature = sampleSignature(icon, projection)
    local state = pinLogState[icon]
    if state and state.signature == signature then return end
    if not state then
        nextPinId = nextPinId + 1
        state = { id = nextPinId }
        pinLogState[icon] = state
    end
    state.signature = signature

    local details = projection or {}
    appendLog(table.concat({
        "PIN_SAMPLE",
        "pinId=" .. tostring(state.id),
        "iconId=" .. safeText(icon.iconID),
        "iconClass=" .. safeText(icon.iconClass),
        "itemType=" .. safeText(icon.itemType),
        "itemName=" .. safeText(icon.itemName),
        "iconName=" .. safeText(icon.name),
        "player=" .. safeText(details.player),
        "playerXYZ=" .. numberText(details.playerX) .. "," .. numberText(details.playerY)
            .. "," .. numberText(details.playerZ),
        "playerHillsHeight=" .. numberText(details.playerHeight),
        "playerHillsEnabled=" .. safeText(details.playerEnabled),
        "playerHillsReady=" .. safeText(details.playerReady),
        "playerHeightStatus=" .. safeText(details.playerReason),
        "pinWorldXYZ=" .. numberText(details.x) .. "," .. numberText(details.y) .. "," .. numberText(details.z),
        "pinHillsHeight=" .. numberText(details.pinHeight),
        "pinHillsEnabled=" .. safeText(details.pinEnabled),
        "pinHillsReady=" .. safeText(details.pinReady),
        "pinHeightStatus=" .. safeText(details.pinReason),
        "terrainHeightDeltaPinMinusPlayer=" .. numberText(details.heightDelta),
        "terrainHeightCorrection=" .. numberText(details.heightCorrection),
        "appliedCorrection=" .. numberText(details.appliedCorrection),
        "automaticLift=" .. numberText(details.automaticLift),
        "manualOffset=" .. numberText(details.manualOffset),
        "manualAnchorXY=" .. numberText(details.manualAnchorX) .. "," .. numberText(details.manualAnchorY),
        "manualAnchorDistance=" .. numberText(details.manualAnchorDistance),
        "manualAnchorCount=" .. safeText(details.manualAnchorCount),
        "manualAnchorKind=" .. safeText(details.manualAnchorKind),
        "manualAnchorId=" .. safeText(details.manualAnchorId),
        "heightSourceStatus=" .. safeText(details.heightSourceStatus),
        "baseLift=" .. numberText(details.baseLift),
        "appliedLift=" .. numberText(details.finalLift),
        "projectionScreenXY=" .. numberText(details.screenX) .. "," .. numberText(details.screenY),
        "projectionDepth=" .. numberText(details.screenDepth),
        "projectionInFront=" .. safeText(details.screenFront),
        "vpfAnchorXY=" .. numberText(details.vpfScreenX) .. "," .. numberText(details.vpfScreenY),
        "iconScreenXY=" .. numberText(iconValue(icon, "getX")) .. "," .. numberText(iconValue(icon, "getY")),
        "iconSize=" .. numberText(icon.width) .. "x" .. numberText(icon.height),
        "zoom=" .. numberText(icon.zoom),
        "textureOffset=" .. numberText(icon.pinOffset),
        "screenOffsetApplied=" .. numberText(details.screenOffset),
        "iconOffsetApplied=" .. numberText(details.iconOffsetApplied),
        "vpfOffsetApplied=" .. numberText(details.vpfOffsetApplied),
        "visible=" .. safeText(icon.vpfOnScreen),
        "placementOk=" .. tostring(placementOk),
        "placementResult=" .. safeText(placementResult),
    }, " "))
end

if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(startSession)
end

local function heightAt(x, y)
    -- Rolling Hills may publish its Lua API after this patch is loaded.
    -- Resolve the global at projection time instead of capturing an early nil.
    local hills = RollingHills
    if not hills then
        return nil, "RollingHills global unavailable", "unknown", "unknown"
    end
    if type(hills.getSelectedHeight) ~= "function" then
        return nil, "getSelectedHeight is not callable", "unknown", "unknown"
    end

    local enabledState = "unknown"
    if type(hills.isEnabled) == "function" then
        local ok, enabled = pcall(function() return hills.isEnabled() end)
        if not ok then return nil, "isEnabled failed: " .. tostring(enabled), "error", "unknown" end
        enabledState = tostring(enabled == true)
        if not enabled then return nil, "terrain is disabled", enabledState, "unknown" end
    end

    local readinessNote = nil
    local readyState = "unknown"
    if type(hills.isReady) == "function" then
        local ok, ready = pcall(function() return hills.isReady() end)
        if not ok then
            readinessNote = "isReady failed: " .. tostring(ready)
            readyState = "error"
        elseif not ready then
            -- The terrain grid can be generated while an incompatible shader pack
            -- suspends its rendering. Try the selected-height API and trust only
            -- finite numeric results instead of rejecting them on this flag alone.
            readinessNote = "isReady=false"
            readyState = "false"
        else
            readyState = "true"
        end
    end

    local ok, value = pcall(hills.getSelectedHeight, x, y)
    if not ok then
        return nil, (readinessNote and readinessNote .. "; " or "")
            .. "getSelectedHeight failed: " .. tostring(value), enabledState, readyState
    end
    if type(value) ~= "number" or value ~= value
            or value == math.huge or value == -math.huge then
        return nil, (readinessNote and readinessNote .. "; " or "")
            .. "getSelectedHeight returned " .. type(value) .. ": " .. tostring(value),
            enabledState, readyState
    end
    return value, readinessNote, enabledState, readyState
end

local function characterHeightAt(playerIndex)
    local timestamp = getTimestampMs and getTimestampMs() or nil
    local cached = playerHeightCache[playerIndex]
    if timestamp and cached and cached.timestamp == timestamp then
        return cached.height, cached.reason, cached.x, cached.y, cached.enabled, cached.ready, cached.z
    end

    local character = nil
    if type(playerIndex) == "number" then
        character = getSpecificPlayer(playerIndex)
    elseif playerIndex and playerIndex.getX and playerIndex.getY then
        character = playerIndex
    end
    if not character then
        return nil, "player character unavailable", nil, nil, "unknown", "unknown"
    end

    local ok, x, y = pcall(function()
        return character:getX(), character:getY()
    end)
    if not ok or type(x) ~= "number" or type(y) ~= "number" then
        return nil, "player position unavailable", nil, nil, "unknown", "unknown"
    end
    local zOk, z = pcall(function() return character:getZ() end)
    if not zOk or type(z) ~= "number" then z = nil end
    local value, reason, enabled, ready = heightAt(x, y)
    if timestamp then
        playerHeightCache[playerIndex] = {
            timestamp = timestamp,
            height = value,
            reason = reason,
            x = x,
            y = y,
            z = z,
            enabled = enabled,
            ready = ready,
        }
    end
    return value, reason, x, y, enabled, ready, z
end

VPF.project = function(player, x, y, z, lift)
    local icon = currentIcon
    if icon and not projectLogged then
        projectLogged = true
        print(TAG .. "project hook received pin; iconClass=" .. tostring(icon.iconClass)
            .. ", player=" .. tostring(player or icon.player or 0))
    end
    -- World-object finds (including dropped items such as the car key in Chila's
    -- screenshot) use this class; forageIcon is used for the other forage finds.
    -- Both are passed through this placement hook while Viewpoint Foraging is active.
    if icon and (icon.iconClass == "forageIcon" or icon.iconClass == "worldObject") then
        local pinHeight, pinReason, pinEnabled, pinReady = heightAt(x, y)
        local playerHeight, playerReason, playerX, playerY, playerEnabled, playerReady, playerZ =
            characterHeightAt(player)
        local baseLift = lift or 0
        local heightDelta = nil
        local heightCorrection = nil
        local appliedCorrection = 0
        local heightSourceStatus = "RollingHills public selected-height delta"
        lift = baseLift

        -- Use the creator's public projection API, and the public terrain-height
        -- API. The camera origin follows the player's terrain elevation, so apply
        -- only the pin-to-player height delta. Do not inspect Camera3D internals:
        -- VPF does not expose its private relief sampler to Lua.
        local screenX, screenY, screenDepth, screenFront =
            vanillaProject(player, x, y, z, lift)
        if type(screenX) == "number" and type(screenY) == "number" and pinHeight ~= nil then
            if playerHeight ~= nil then
                heightDelta = pinHeight - playerHeight
                heightCorrection = heightDelta
                if math.abs(heightCorrection) > 0.01 then
                    appliedCorrection = heightCorrection
                    lift = baseLift + appliedCorrection
                    screenX, screenY, screenDepth, screenFront =
                        vanillaProject(player, x, y, z, lift)
                end
            else
                heightSourceStatus = "player selected height unavailable"
                if not warned then
                    warned = true
                    print(TAG .. "player terrain height unavailable; keeping original projection")
                end
            end
            if not applied and appliedCorrection ~= 0 then
                applied = true
                print(TAG .. "terrain-height delta applied; iconClass=" .. tostring(icon.iconClass)
                    .. ", playerHeight=" .. tostring(playerHeight)
                    .. ", pinHeight=" .. tostring(pinHeight)
                    .. ", expectedPinMinusPlayer=" .. tostring(heightDelta)
                    .. ", terrainCorrection=" .. tostring(heightCorrection)
                    .. ", appliedCorrection=" .. tostring(appliedCorrection)
                    .. ", baseLift=" .. tostring(baseLift) .. ", finalLift=" .. tostring(lift)
                    .. ", playerXY=" .. tostring(playerX) .. "," .. tostring(playerY)
                    .. ", pinXY=" .. tostring(x) .. "," .. tostring(y)
                    .. ", terrainState=" .. tostring(playerReason or pinReason)
                    .. ", heightSourceStatus=" .. heightSourceStatus
                )
            end
        elseif not warned then
            warned = true
            print(TAG .. "height correction skipped; iconClass=" .. tostring(icon.iconClass)
                .. ", x=" .. tostring(x) .. ", y=" .. tostring(y)
                .. ", player=" .. tostring(playerReason)
                .. ", pin=" .. tostring(pinReason)
                .. "; leaving original projection active")
        end
        -- Apply the optional per-location offset after automatic terrain alignment.
        local manualOffset, manualAnchor = HeightCalibration.getOffsetAt(x, y)
        if type(manualOffset) ~= "number" then manualOffset = 0 end
        if manualOffset ~= 0 then
            lift = (lift or baseLift) + manualOffset
            if type(screenX) == "number" and type(screenY) == "number" then
                screenX, screenY, screenDepth, screenFront =
                    vanillaProject(player, x, y, z, lift)
            end
        end
        currentProjection = {
            player = player,
            playerX = playerX,
            playerY = playerY,
            playerZ = playerZ,
            playerHeight = playerHeight,
            playerEnabled = playerEnabled,
            playerReady = playerReady,
            playerReason = playerReason,
            x = x,
            y = y,
            z = z,
            pinHeight = pinHeight,
            pinEnabled = pinEnabled,
            pinReady = pinReady,
            pinReason = pinReason,
            heightDelta = heightDelta,
            heightCorrection = heightCorrection,
            appliedCorrection = appliedCorrection,
            automaticLift = baseLift + appliedCorrection,
            manualOffset = manualOffset,
            manualAnchorX = manualAnchor and manualAnchor.x or nil,
            manualAnchorY = manualAnchor and manualAnchor.y or nil,
            manualAnchorDistance = manualAnchor and manualAnchor.distance or nil,
            manualAnchorCount = manualAnchor and manualAnchor.sampleCount or 0,
            manualAnchorKind = manualAnchor and manualAnchor.kind or "none",
            manualAnchorId = manualAnchor and manualAnchor.id or nil,
            heightSourceStatus = heightSourceStatus,
            baseLift = baseLift,
            finalLift = lift or baseLift,
        }
        currentProjection.screenX = screenX
        currentProjection.screenY = screenY
        currentProjection.screenDepth = screenDepth
        currentProjection.screenFront = screenFront
        return screenX, screenY, screenDepth, screenFront
    end
    return vanillaProject(player, x, y, z, lift)
end

VPF.placePin = function(icon)
    local previous = currentIcon
    currentIcon = icon
    currentProjection = nil
    if not placePinLogged then
        placePinLogged = true
        print(TAG .. "placePin hook received iconClass=" .. tostring(icon and icon.iconClass))
    end
    local ok, result = pcall(vanillaPlacePin, icon)
    if ok and icon
            and (icon.iconClass == "forageIcon" or icon.iconClass == "worldObject") then
        local pinX = currentProjection and currentProjection.x or icon.xCoord
        local pinY = currentProjection and currentProjection.y or icon.yCoord
        local pinZoom, circleZoom, iconZoom = HeightCalibration.getVisualAt(pinX, pinY)
        pinZoom = type(pinZoom) == "number" and pinZoom or 1
        circleZoom = type(circleZoom) == "number" and circleZoom or 1
        iconZoom = type(iconZoom) == "number" and iconZoom or 1
        -- VPF's 3D placement omits the offset ISBaseIcon computes for the
        -- found object's texture. Reapply it in scaled screen pixels so both
        -- the pin and the HUD's homing arrow follow the actual item.
        local pinOffset = type(icon.pinOffset) == "number" and icon.pinOffset or 0
        local zoom = type(icon.zoom) == "number" and icon.zoom or 1
        -- Vanilla pinOffset is for isometric placement. VPF anchors the marker
        -- tip at its 3D projection, so this offset moves it away from the find.
        local screenOffset = 0
        if screenOffset ~= 0 then
            if icon.vpfOnScreen then
                icon:setY(icon:getY() + screenOffset)
            end
            if type(icon.vpfSY) == "number" then
                icon.vpfSY = icon.vpfSY + screenOffset
            end
        end
        icon.chilaSedaPinZoom = pinZoom
        icon.chilaSedaCircleZoom = circleZoom
        icon.chilaSedaIconZoom = iconZoom
        if pinZoom ~= 1 then
            local width = type(icon.width) == "number" and icon.width or 0
            local height = type(icon.height) == "number" and icon.height or 0
            icon:setWidth(width * pinZoom)
            icon:setHeight(height * pinZoom)
            if type(icon.vpfSX) == "number" and type(icon.vpfSY) == "number"
                    and type(VPF.screenSize) == "function" then
                local screenWidth, screenHeight = VPF.screenSize(icon.player)
                local visible = icon.vpfFront and icon.vpfSX > -icon.width
                    and icon.vpfSX < screenWidth + icon.width
                    and icon.vpfSY > -icon.height
                    and icon.vpfSY < screenHeight + icon.height
                    and (icon.vpfFade or 0) > 0
                icon.vpfOnScreen = visible
                if visible then
                    icon:setX(icon.vpfSX - icon.width / 2)
                    icon:setY(icon.vpfSY - icon.height)
                else
                    icon:setX(-100000)
                    icon:setY(-100000)
                end
            end
        end
        if zoom ~= 0 and iconZoom ~= 1 then
            icon.zoom = zoom / iconZoom
        end
        if currentProjection then
            currentProjection.screenOffset = screenOffset
            currentProjection.vpfScreenX = icon.vpfSX
            currentProjection.vpfScreenY = icon.vpfSY
            currentProjection.iconOffsetApplied = icon.vpfOnScreen and screenOffset or 0
            currentProjection.vpfOffsetApplied =
                type(icon.vpfSY) == "number" and screenOffset or 0
        end
        -- Vanilla can leave the UI element hidden even when the 3D projection
        -- is on-screen. UIManager skips render() for hidden elements, so keep
        -- eligible pins drawable after each placement.
        if icon.vpfOnScreen and type(icon.setVisible) == "function" then
            pcall(icon.setVisible, icon, true)
        end
    end
    logPinSample(icon, currentProjection, ok, result)
    currentIcon = previous
    currentProjection = nil
    if not ok then
        error(result)
    end
    return result
end

local circleZoomHookInstalled = false
local function installCircleZoomHook()
    if circleZoomHookInstalled or type(VPF_HUD) ~= "table"
            or type(VPF_HUD.render) ~= "function" then return false end
    local originalRender = VPF_HUD.render
    VPF_HUD.render = function(hud, ...)
        local target = hud and hud.target
        local ratio = 1
        if target and target.vpfOnScreen then
            local pinScale = tonumber(target.chilaSedaPinZoom) or 1
            local circleScale = tonumber(target.chilaSedaCircleZoom) or 1
            if pinScale ~= 0 then ratio = circleScale / pinScale end
        end
        if ratio == 1 or not target then return originalRender(hud, ...) end
        local originalWidth, originalHeight = target.width, target.height
        target.width, target.height = originalWidth * ratio, originalHeight * ratio
        local ok, result = pcall(originalRender, hud, ...)
        target.width, target.height = originalWidth, originalHeight
        if not ok then error(result) end
        return result
    end
    circleZoomHookInstalled = true
    print(TAG .. "per-anchor pin, inner-sprite, and target-ring scaling installed")
    return true
end

installCircleZoomHook()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installCircleZoomHook)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(function()
        if not circleZoomHookInstalled then installCircleZoomHook() end
    end)
end

print(TAG .. "installed; automatic reconciliation plus optional per-area manual pin offset")
