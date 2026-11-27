require "Viewpoint_InvGear"
require "Viewpoint_InvScreen"

ViewpointInventory = ViewpointInventory or {}
local inventory = ViewpointInventory
local MAX_TRACE_LINES = 24

local traceState = inventory.chilaSedaMirageAvatarPreviewTrace
if type(traceState) ~= "table" then
    traceState = { enabled = true, lines = 0 }
    inventory.chilaSedaMirageAvatarPreviewTrace = traceState
end
if type(traceState.enabled) ~= "boolean" then traceState.enabled = true end
if type(traceState.lines) ~= "number" then traceState.lines = 0 end

local function trace(message)
    if traceState.enabled ~= true or traceState.lines >= MAX_TRACE_LINES then return end
    if type(print) ~= "function" then return end
    traceState.lines = traceState.lines + 1
    pcall(print, "[ChilaSeda_ViewpointMirageAvatar] " .. tostring(message))
end

if inventory.chilaSedaMirageAvatarPreviewInstalled then
    trace("event=install result=already-installed")
    return
end

local avatarClass = ViewpointInvAvatar
local screenClass = ViewpointInvScreen
if type(avatarClass) ~= "table" or type(avatarClass.bind) ~= "function" then
    trace("event=install result=fallback reason=avatar-bind-unavailable")
    return
end

local originalBind = avatarClass.bind

local function mirageBind(avatar, player)
    local core = MirageWardrobeCore
    if not player or type(core) ~= "table"
            or type(core.isCleanAppearanceEnabled) ~= "function"
            or type(core.setAppearancePreviewCharacter) ~= "function" then
        trace("event=preview result=fallback reason=mirage-preview-api-unavailable")
        return originalBind(avatar, player), "vanilla-fallback"
    end

    local cleanOk, cleanAppearance = pcall(core.isCleanAppearanceEnabled, player)
    if not cleanOk or type(cleanAppearance) ~= "boolean" then
        trace("event=preview result=fallback reason=clean-appearance-state-unavailable")
        return originalBind(avatar, player), "vanilla-fallback"
    end

    avatar:setState("idle")
    avatar:setDirection(IsoDirections.S)
    avatar:setIsometric(false)

    local previewOk, applied, warning = pcall(
        core.setAppearancePreviewCharacter, avatar, player, cleanAppearance, nil)
    if previewOk and applied == true then
        trace("event=preview result=mirage clean=" .. tostring(cleanAppearance)
            .. (warning and (" warning=" .. tostring(warning):sub(1, 96)) or ""))
        return true, "mirage-preview"
    end

    local reason = previewOk and tostring(warning or "preview-capture-failed")
        or tostring(applied)
    trace("event=preview result=fallback reason=" .. reason:sub(1, 120))
    return originalBind(avatar, player), "vanilla-fallback"
end

avatarClass.bind = mirageBind

local pendingPlayer = nil
local pendingSource = nil

local function queueRefresh(source, player)
    if type(getSpecificPlayer) ~= "function" then
        trace("event=queue result=fallback reason=local-player-api-unavailable")
        return
    end
    local localPlayer = getSpecificPlayer(0)
    if not localPlayer then return end
    if player and player ~= localPlayer then return end
    if pendingPlayer == nil then
        pendingPlayer = localPlayer
        pendingSource = source
        trace("event=queue result=pending source=" .. tostring(source))
    end
end

local function flushRefresh()
    local player = pendingPlayer
    if not player then return end
    local source = pendingSource
    pendingPlayer, pendingSource = nil, nil

    if type(screenClass) ~= "table" or type(screenClass.isUp) ~= "function"
            or not screenClass.instance then
        trace("event=refresh result=fallback reason=screen-instance-unavailable")
        return
    end
    local upOk, isUp = pcall(screenClass.isUp)
    if not upOk or isUp ~= true then
        trace("event=refresh result=fallback reason=screen-not-up")
        return
    end

    local screen = screenClass.instance
    local avatar = screen.avatar
    if not avatar or type(avatar.bind) ~= "function" then
        trace("event=refresh result=fallback reason=avatar-panel-unavailable")
        return
    end

    local bindOk, _, mode = pcall(avatar.bind, avatar, player)
    if not bindOk then
        trace("event=refresh result=fallback source=" .. tostring(source)
            .. " reason=bind-failed")
        return
    end
    screen.redress = false
    screen.dirty = true
    if mode == "mirage-preview" then
        trace("event=refresh result=updated source=" .. tostring(source)
            .. " mode=mirage-preview")
    else
        trace("event=refresh result=fallback source=" .. tostring(source)
            .. " reason=vanilla-preview")
    end
end

local function subscribe(event, source)
    if event and type(event.Add) == "function" then
        event.Add(function(player) queueRefresh(source, player) end)
    else
        trace("event=register result=fallback source=" .. tostring(source)
            .. " reason=event-unavailable")
    end
end

if Events then
    subscribe(Events.OnClothingUpdated, "clothing")
    subscribe(Events.OnEquipPrimary, "primary-hand")
    subscribe(Events.OnEquipSecondary, "secondary-hand")
    if Events.OnPreUIDraw and type(Events.OnPreUIDraw.Add) == "function" then
        Events.OnPreUIDraw.Add(flushRefresh)
    else
        trace("event=register result=fallback source=pre-ui-draw reason=event-unavailable")
    end
else
    trace("event=register result=fallback reason=Events-unavailable")
end

inventory.chilaSedaMirageAvatarPreviewInstalled = true
trace("event=install result=wrapped")
