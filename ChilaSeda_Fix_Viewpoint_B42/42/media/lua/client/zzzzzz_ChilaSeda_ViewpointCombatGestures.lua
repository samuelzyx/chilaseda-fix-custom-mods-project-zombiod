require "ISUI/ISUIElement"

local TAG = "[ChilaSeda_ViewpointCombatGestures] "
local MIN_DISTANCE = 48
local MAX_STROKE_MS = 900
local PENDING_MS = 450
local DISPLAY_MS = 900
local MAX_POINTS = 32
local overlay
local stroke
local pending
local armed
local activeAttackOverride
local lastAttackStarted = false
local lastLeftMouseDown = false
local initAttempts = 0
local nextInitAt = 0
local initialized = false
local warnedMissing = false
local warnedBridgeFailure = false
local lastPreviewKind
local display = { points = {}, label = nil, expires = 0 }

local function controlIsDown()
    if Keyboard and type(Keyboard.isKeyDown) == "function" then
        local left, right = Keyboard.KEY_LCONTROL, Keyboard.KEY_RCONTROL
        if left ~= nil then
            local ok, down = pcall(Keyboard.isKeyDown, left)
            if ok and down then return true end
        end
        if right ~= nil then
            local ok, down = pcall(Keyboard.isKeyDown, right)
            if ok and down then return true end
        end
    end
    if type(isCtrlKeyDown) == "function" then
        local ok, down = pcall(isCtrlKeyDown)
        return ok and down == true
    end
    return false
end

local function safeMethod(object, method, ...)
    if not object then return nil end
    local args = { ... }
    local unpackValues = table.unpack or unpack
    local ok, value = pcall(function()
        local fn = object[method]
        if type(fn) ~= "function" then return nil end
        return fn(object, unpackValues(args))
    end)
    return ok and value or nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and type(value) == "number" then return value end
    end
    return math.floor(os.clock() * 1000)
end

local function viewpointAvailable()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge then return false end
    local check = bridge.available or bridge.active
    if type(check) ~= "function" then return false end
    local ok, available = pcall(check)
    return ok and available == true
end

local function copyPoints(points)
    local copy = {}
    for i, point in ipairs(points or {}) do
        copy[i] = { x = point.x, y = point.y }
    end
    return copy
end

local function showGesture(points, label, expires)
    display.points = copyPoints(points)
    display.label = label
    display.expires = expires or (nowMs() + DISPLAY_MS)
end

local function makeStroke()
    local core = type(getCore) == "function" and getCore() or nil
    local width = core and core:getScreenWidth() or 1280
    local height = core and core:getScreenHeight() or 720
    local x, y = width * 0.5, height * 0.72
    return {
        startedAt = nowMs(),
        lastAt = nowMs(),
        length = 0,
        turn = 0,
        points = { { x = x, y = y } },
        dx = 0,
        dy = 0,
        lastDX = 0,
        lastDY = 0,
    }
end

local function pushMouseDelta(dx, dy)
    if not stroke then
        pending = nil
        stroke = makeStroke()
    end
    if math.abs(dx) + math.abs(dy) < 0.5 then return end
    local screenDY = -dy
    local previous = stroke.points[#stroke.points]
    local point = { x = previous.x + dx, y = previous.y + screenDY }
    stroke.length = stroke.length + math.sqrt(dx * dx + dy * dy)
    stroke.dx = stroke.dx + dx
    stroke.dy = stroke.dy + screenDY
    if stroke.lastDX ~= 0 or stroke.lastDY ~= 0 then
        local cross = stroke.lastDX * screenDY - stroke.lastDY * dx
        local dot = stroke.lastDX * dx + stroke.lastDY * screenDY
        stroke.turn = stroke.turn + math.abs(math.atan2(cross, dot))
    end
    stroke.lastDX, stroke.lastDY = dx, screenDY
    stroke.lastAt = nowMs()
    stroke.points[#stroke.points + 1] = point
    if #stroke.points > MAX_POINTS then table.remove(stroke.points, 2) end
end

local function classifyStroke(value)
    if not value or #value.points < 3 or value.length < MIN_DISTANCE
            or nowMs() - value.startedAt > MAX_STROKE_MS then
        return nil
    end
    local first, last = value.points[1], value.points[#value.points]
    local dx, dy = last.x - first.x, last.y - first.y
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance < MIN_DISTANCE then return nil end

    -- A deliberate C from lower-left toward upper-right is the floor-execution gesture.
    if value.turn >= 1.45 and value.length >= distance * 1.35
            and dx > distance * 0.25 and dy < -distance * 0.25 then
        return "execute", "EJECUCION"
    end

    local straightness = distance / math.max(1, value.length)
    if straightness < 0.72 then return nil end
    if dx < -math.abs(dy) * 1.15 then return "swing", "BOLADO" end
    if dy > math.abs(dx) * 1.15 then return "overhead", "VERTICAL" end
    if dx > 0 and dy < 0 then return "backhand", "REVES" end
    return nil
end

local function sampleCameraGesture()
    local bridge = ChilaSedaViewpointCombatGesturesJ
    if not bridge or not viewpointAvailable()
            or (type(isGamePaused) == "function" and isGamePaused()) then
        stroke, pending, lastPreviewKind = nil, nil, nil
        return
    end
    if controlIsDown() then
        if not stroke then
            stroke = makeStroke()
            print(TAG .. "capture started source=org.lwjglx.input.Mouse.getDX/getDY")
        end
        local okX, dx = pcall(bridge.mouseDeltaX)
        local okY, dy = pcall(bridge.mouseDeltaY)
        if okX and okY and type(dx) == "number" and type(dy) == "number" then
            pushMouseDelta(dx, dy)
            local kind, label = classifyStroke(stroke)
            if kind then
                pending = { kind = kind, label = label, expires = nowMs() + PENDING_MS,
                    points = copyPoints(stroke.points) }
                showGesture(stroke.points, label, nowMs() + DISPLAY_MS)
                if lastPreviewKind ~= kind then
                    print(TAG .. "preview " .. label .. " points=" .. #stroke.points
                        .. " length=" .. string.format("%.1f", stroke.length))
                    lastPreviewKind = kind
                end
            else
                pending = nil
                lastPreviewKind = nil
            end
        elseif not warnedBridgeFailure then
            warnedBridgeFailure = true
            print(TAG .. "mouse delta read failed; capture values unavailable")
        end
    elseif stroke then
        local finished = stroke
        local kind, label = classifyStroke(finished)
        print(TAG .. "capture ended points=" .. #finished.points
            .. " length=" .. string.format("%.1f", finished.length)
            .. " turn=" .. string.format("%.2f", finished.turn)
            .. " dx=" .. string.format("%.1f", finished.dx)
            .. " dy=" .. string.format("%.1f", finished.dy)
            .. " result=" .. (kind and label or "unrecognized"))
        if kind then
            pending = { kind = kind, label = label, expires = nowMs() + PENDING_MS,
                points = copyPoints(finished.points) }
            showGesture(finished.points, label, nowMs() + DISPLAY_MS)
            print(TAG .. "recognized " .. label .. "; waiting for left-click")
        else
            pending = nil
        end
        stroke = nil
        lastPreviewKind = nil
    end
    if pending and nowMs() > pending.expires then pending = nil end
end

local function restoreAttackOverride(reason)
    if not activeAttackOverride then return end
    local bridge = ChilaSedaViewpointCombatGesturesJ
    local ok, result = false, "combat gesture bridge unavailable"
    if bridge and type(bridge.restoreAttackOverride) == "function" then
        ok, result = pcall(bridge.restoreAttackOverride, reason)
    end
    if ok and result == "restored" then
        print(TAG .. "restored vanilla attack choices (" .. reason .. ")")
    else
        print(TAG .. "could not restore vanilla attack choices; result=" .. tostring(result))
    end
    activeAttackOverride = nil
end

local function installAttackOverride(gesture, player)
    local bridge = ChilaSedaViewpointCombatGesturesJ
    if not bridge or not player or type(bridge.armAttack) ~= "function" then
        return false, "combat gesture bridge unavailable"
    end
    local ok, result = pcall(bridge.armAttack, player, gesture.kind)
    if not ok or type(result) ~= "string" or string.sub(result, 1, 2) == "! " then
        return false, ok and tostring(result) or ("bridge error: " .. tostring(result))
    end
    local name = result
    activeAttackOverride = true
    armed = {
        kind = gesture.kind,
        label = gesture.label,
        attackName = name,
        expires = nowMs() + PENDING_MS + 700,
        points = copyPoints(gesture.points),
    }
    print(TAG .. "armed " .. gesture.label .. " as " .. name)
    return true
end

local function leftMouseDown()
    local bridge = ChilaSedaViewpointCombatGesturesJ
    if not bridge or type(bridge.leftMouseDown) ~= "function" then return false end
    local ok, down = pcall(bridge.leftMouseDown)
    return ok and down == true
end

local function armGestureOnClick()
    if not pending or nowMs() > pending.expires or not leftMouseDown() then return end
    if type(isGamePaused) == "function" and isGamePaused() then return end
    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    if not player or safeMethod(player, "isAttackStarted") == true then return end
    local gesture = pending
    pending = nil
    stroke = nil
    local ok, reason = installAttackOverride(gesture, player)
    if ok then
        showGesture(gesture.points, gesture.label, nowMs() + DISPLAY_MS)
    else
        showGesture(gesture.points, gesture.label .. " - VANILLA", nowMs() + DISPLAY_MS)
        print(TAG .. "gesture stayed vanilla: " .. tostring(reason))
    end
end

local function onMouseDown()
    armGestureOnClick()
end

local CombatGestureOverlay = ISUIElement:derive("ChilaSedaViewpointCombatGestureOverlay")

function CombatGestureOverlay:new()
    local core = type(getCore) == "function" and getCore() or nil
    local width = core and core:getScreenWidth() or 1280
    local height = core and core:getScreenHeight() or 720
    local element = ISUIElement.new(self, 0, 0, width, height)
    element.anchorLeft, element.anchorTop = true, true
    return element
end

function CombatGestureOverlay:onMouseDown() return false end
function CombatGestureOverlay:onMouseUp() return false end
function CombatGestureOverlay:onRightMouseDown() return false end
function CombatGestureOverlay:onRightMouseUp() return false end

function CombatGestureOverlay:render()
    if nowMs() > display.expires or not display.label then return end
    local points = display.points or {}
    for i = 2, #points do
        local before, after = points[i - 1], points[i]
        if whiteTexture then
            self:DrawLine(whiteTexture, before.x, before.y, after.x, after.y,
                3, 1, 0.52, 0.08, 0.92)
        else
            local distance = math.sqrt((after.x - before.x) ^ 2 + (after.y - before.y) ^ 2)
            local steps = math.max(1, math.floor(distance / 4))
            for step = 0, steps do
                local t = step / steps
                self:drawRect(before.x + (after.x - before.x) * t - 1.5,
                    before.y + (after.y - before.y) * t - 1.5, 3, 3,
                    0.92, 1, 0.52, 0.08)
            end
        end
    end
    local core = type(getCore) == "function" and getCore() or nil
    local width = core and core:getScreenWidth() or 1280
    self:drawTextCentre(display.label, width * 0.5, 30, 1, 0.62, 0.16, 0.96,
        UIFont and UIFont.Small or nil)
end

local function createOverlay()
    if overlay then overlay:removeFromUIManager() end
    overlay = CombatGestureOverlay:new()
    overlay:initialise()
    overlay:addToUIManager()
    pcall(function() overlay:backMost() end)
end

local function missingApis()
    local missing = {}
    local bridge = ChilaSedaViewpointCombatGesturesJ
    if not bridge then
        missing[#missing + 1] = "ChilaSedaViewpointCombatGesturesJ"
    else
        for _, method in ipairs({ "available", "mouseDeltaX", "mouseDeltaY", "leftMouseDown",
                "armAttack", "restoreAttackOverride", "attackTypeName" }) do
            if type(bridge[method]) ~= "function" then
                missing[#missing + 1] = "bridge." .. method
            end
        end
        if #missing == 0 then
            local ok, available = pcall(bridge.available)
            if not ok or available ~= true then
                missing[#missing + 1] = "Project Zomboid mouse/combat APIs"
            end
        end
    end
    if not viewpointAvailable() then missing[#missing + 1] = "Viewpoint API" end
    return missing
end

local function init()
    initAttempts = initAttempts + 1
    if not overlay then
        local ok = pcall(createOverlay)
        if not ok then overlay = nil end
    end

    local missing = missingApis()
    if #missing == 0 then
        if not initialized then
            initialized = true
            print(TAG .. "ready; mouse capture and vanilla attack bridge connected")
        end
        warnedMissing = false
    elseif initAttempts >= 4 and getSpecificPlayer
            and type(getSpecificPlayer) == "function" and getSpecificPlayer(0)
            and not warnedMissing then
        warnedMissing = true
        print(TAG .. "gesture APIs unavailable: " .. table.concat(missing, ", ")
            .. "; vanilla combat remains active")
    end
end

local function onTick()
    if not initialized and nowMs() >= nextInitAt then
        nextInitAt = nowMs() + 500
        init()
    end
    sampleCameraGesture()
    local leftDown = leftMouseDown()
    if leftDown and not lastLeftMouseDown then armGestureOnClick() end
    lastLeftMouseDown = leftDown

    local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
    local started = player and safeMethod(player, "isAttackStarted") == true or false
    if started and not lastAttackStarted then
        if activeAttackOverride then restoreAttackOverride("vanilla selected the gesture") end
        if armed then
            local bridge = ChilaSedaViewpointCombatGesturesJ
            local ok, actualName = false, ""
            if bridge and type(bridge.attackTypeName) == "function" then
                ok, actualName = pcall(bridge.attackTypeName, player)
            end
            if not ok then actualName = "unknown" end
            if actualName == armed.attackName then
                showGesture(armed.points, armed.label, nowMs() + DISPLAY_MS)
                print(TAG .. "attack started with gesture " .. armed.label
                    .. " (" .. armed.attackName .. ")")
            else
                showGesture(armed.points, armed.label .. " - VANILLA", nowMs() + DISPLAY_MS)
                print(TAG .. "attack used " .. tostring(actualName) .. "; expected "
                    .. armed.attackName .. "; vanilla choice kept")
            end
            armed = nil
        elseif pending then
            showGesture(pending.points, pending.label .. " - VANILLA", nowMs() + DISPLAY_MS)
            print(TAG .. "attack started before gesture was armed; vanilla attack kept")
            pending = nil
        end
    end
    lastAttackStarted = started

    if armed and nowMs() > armed.expires then
        restoreAttackOverride("click did not start an attack")
        showGesture(armed.points, armed.label .. " - VANILLA", nowMs() + DISPLAY_MS)
        print(TAG .. "gesture click did not start an attack; vanilla choices restored")
        armed = nil
    end
    if (type(isGamePaused) == "function" and isGamePaused()) and activeAttackOverride then
        restoreAttackOverride("game paused")
        armed = nil
    end
end

if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(onTick)
end
if Events and Events.OnMouseDown and type(Events.OnMouseDown.Add) == "function" then
    Events.OnMouseDown.Add(onMouseDown)
end
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(init)
end
init()
