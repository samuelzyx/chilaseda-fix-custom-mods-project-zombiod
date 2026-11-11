require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"

local Calibration = {}
local TAG = "[ChilaSeda_ViewpointNativeForageHeightCalibration] "
Calibration.nativeIntegrated = false
local CONFIG_FILE = "ViewpointNativeForage_manual_offsets.txt"
local RADIUS = 64
local REPLACE_RADIUS = 12
local MAX_OFFSET = 64
local HEIGHT_NUDGE = 5.0
local VISUAL_NUDGE = 0.05
local MIN_ZOOM = 0.25
local MAX_ZOOM = 4.00
local REPORT_FILE = "ViewpointNativeForage_pin_reports.log"
local HEADER_ICON_PATH = "media/ui/Sidebar/48/Search_On_48.png"
local headerIcon = nil
local headerIconLoaded = false

local anchors = {}
local globalVisualZoom = { pin = 1, circle = 1, icon = 1 }
local previewAnchor = nil
local loaded = false
local window = nil
local windowPosition = nil

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function clampOffset(value)
    if not finite(value) then return nil end
    return math.max(-MAX_OFFSET, math.min(MAX_OFFSET, value))
end

local function clampZoom(value)
    if not finite(value) then return nil end
    return math.max(MIN_ZOOM, math.min(MAX_ZOOM, value))
end

local function commonZoom(pinZoom, circleZoom, iconZoom)
    local pin = clampZoom(pinZoom) or 1
    local circle = clampZoom(circleZoom) or 1
    local icon = clampZoom(iconZoom) or 1
    return (pin + circle + icon) / 3
end

local function normalizedAnchor(x, y, offset, pinZoom, circleZoom, iconZoom)
    local height = clampOffset(offset)
    local pin = clampZoom(pinZoom or 1)
    local circle = clampZoom(circleZoom or 1)
    local inner = clampZoom(iconZoom or 1)
    if not finite(x) or not finite(y) or height == nil or pin == nil
            or circle == nil or inner == nil then return nil end
    return {
        x = x, y = y, offset = height,
        pinZoom = pin, circleZoom = circle, iconZoom = inner,
    }
end

local function safeText(value)
    if value == nil then return "UNAVAILABLE" end
    local ok, result = pcall(tostring, value)
    if not ok then return "UNAVAILABLE" end
    return result:gsub("[\r\n\t|;]", "_")
end

local function loadConfig()
    if type(getFileReader) ~= "function" then
        loaded = false
        return
    end

    anchors = {}
    globalVisualZoom = { pin = 1, circle = 1, icon = 1 }
    windowPosition = nil
    local foundGlobalZoom = false
    local ok, err = pcall(function()
        local reader = getFileReader(CONFIG_FILE, false)
        if not reader then return end
        while true do
            local line = reader:readLine()
            if not line then break end
            local windowXText, windowYText = line:match("^window,([^,]+),([^,]+)$")
            local savedWindowX = windowXText and tonumber(windowXText) or nil
            local savedWindowY = windowYText and tonumber(windowYText) or nil
            if finite(savedWindowX) and finite(savedWindowY) then
                windowPosition = { x = savedWindowX, y = savedWindowY }
            end
            local globalPinText, globalCircleText, globalIconText =
                line:match("^global,([^,]+),([^,]+),([^,]+)$")
            local globalPin = globalPinText and clampZoom(tonumber(globalPinText)) or nil
            local globalCircle = globalCircleText and clampZoom(tonumber(globalCircleText)) or nil
            local globalIcon = globalIconText and clampZoom(tonumber(globalIconText)) or nil
            if globalPin and globalCircle and globalIcon then
                globalVisualZoom = { pin = globalPin, circle = globalCircle, icon = globalIcon }
                foundGlobalZoom = true
            end
            local xText, yText, offsetText, pinText, circleText, iconText =
                line:match("^anchor,([^,]+),([^,]+),([^,]+),?([^,]*),?([^,]*),?([^,]*)$")
            local x = xText and tonumber(xText) or nil
            local y = yText and tonumber(yText) or nil
            local offset = offsetText and clampOffset(tonumber(offsetText)) or nil
            if finite(x) and finite(y) and offset ~= nil then
                local anchor = normalizedAnchor(x, y, offset,
                    tonumber(pinText) or 1, tonumber(circleText) or 1, tonumber(iconText) or 1)
                if anchor then anchors[#anchors + 1] = anchor end
            end
        end
        reader:close()
    end)
    if not ok then
        print(TAG .. "could not load saved offsets: " .. safeText(err))
        anchors = {}
    end
    -- Older config files may only contain per-anchor zoom. Migrate the most
    -- recently saved values once, then use the global line for every pin.
    if not foundGlobalZoom and #anchors > 0 then
        local latest = anchors[#anchors]
        globalVisualZoom = {
            pin = latest.pinZoom or 1,
            circle = latest.circleZoom or 1,
            icon = latest.iconZoom or 1,
        }
    end
    loaded = true
    print(TAG .. "loaded " .. tostring(#anchors) .. " saved area offset(s)")
end

local function saveConfig()
    if type(getFileWriter) ~= "function" then
        return false, "getFileWriter unavailable"
    end
    local ok, err = pcall(function()
        local writer = getFileWriter(CONFIG_FILE, true, false)
        if not writer then error("getFileWriter returned nil") end
        writer:write("# Viewpoint Foraging manual pin settings v2\n")
        writer:write(string.format("global,%.3f,%.3f,%.3f\n",
            globalVisualZoom.pin, globalVisualZoom.circle, globalVisualZoom.icon))
        if windowPosition and finite(windowPosition.x) and finite(windowPosition.y) then
            writer:write(string.format("window,%.0f,%.0f\n", windowPosition.x, windowPosition.y))
        end
        for _, anchor in ipairs(anchors) do
            writer:write(string.format("anchor,%.4f,%.4f,%.4f,%.3f,%.3f,%.3f\n",
                anchor.x, anchor.y, anchor.offset, anchor.pinZoom or 1,
                anchor.circleZoom or 1, anchor.iconZoom or 1))
        end
        writer:close()
    end)
    if not ok then
        print(TAG .. "could not save offsets: " .. safeText(err))
        return false, safeText(err)
    end
    return true
end

local function getNearbyAnchorSamples(x, y)
	local samples = {}
	local function add(anchor, kind, id)
		local dx = x - anchor.x
		local dy = y - anchor.y
		local distanceSquared = dx * dx + dy * dy
		if distanceSquared <= RADIUS * RADIUS then
			samples[#samples + 1] = {
				anchor = anchor,
				kind = kind,
				id = id,
				distance = math.sqrt(distanceSquared),
				distanceSquared = distanceSquared,
			}
		end
	end
	for index, anchor in ipairs(anchors) do add(anchor, "saved", index) end
	if previewAnchor then add(previewAnchor, "preview", "preview") end
	table.sort(samples, function(a, b)
		if a.distanceSquared ~= b.distanceSquared then
			return a.distanceSquared < b.distanceSquared
		end
		return a.kind == "preview" and b.kind ~= "preview"
	end)
	return samples
end

local function interpolateAnchors(samples)
	local nearest = samples[1]
	local first = nearest.anchor
	if nearest.distanceSquared <= 0.000001 then
		return first.offset, {
			x = first.x, y = first.y, offset = first.offset,
			pinZoom = first.pinZoom or 1, circleZoom = first.circleZoom or 1,
			iconZoom = first.iconZoom or 1, distance = nearest.distance,
			kind = nearest.kind, id = nearest.id, sampleCount = 1,
		}
	end

	local totals = { offset = 0, pinZoom = 0, circleZoom = 0, iconZoom = 0 }
	local weightTotal = 0
	for _, sample in ipairs(samples) do
		local anchor = sample.anchor
		local weight = 1 / math.max(sample.distanceSquared, 0.000001)
		weightTotal = weightTotal + weight
		totals.offset = totals.offset + anchor.offset * weight
		totals.pinZoom = totals.pinZoom + (anchor.pinZoom or 1) * weight
		totals.circleZoom = totals.circleZoom + (anchor.circleZoom or 1) * weight
		totals.iconZoom = totals.iconZoom + (anchor.iconZoom or 1) * weight
	end
	return totals.offset / weightTotal, {
		x = first.x, y = first.y,
		offset = totals.offset / weightTotal,
		pinZoom = totals.pinZoom / weightTotal,
		circleZoom = totals.circleZoom / weightTotal,
		iconZoom = totals.iconZoom / weightTotal,
		distance = nearest.distance,
		kind = #samples > 1 and "interpolated" or nearest.kind,
		id = nearest.id,
		sampleCount = #samples,
	}
end

function Calibration.getOffsetAt(x, y)
	if not finite(x) or not finite(y) then return 0, nil end
	local samples = getNearbyAnchorSamples(x, y)
	if #samples == 0 then return 0, nil end
	return interpolateAnchors(samples)
end

function Calibration.getVisualAt(x, y)
    local _, info = Calibration.getOffsetAt(x, y)
    -- Anchors control height only. A zoom edit must affect every pin, including
    -- pins near older anchors and pins with no anchor at all.
    return globalVisualZoom.pin, globalVisualZoom.circle, globalVisualZoom.icon, info
end

function Calibration.getRecentAnchor(rank)
	if type(rank) ~= "number" or rank < 1 or rank % 1 ~= 0 then return nil end
	local index = #anchors - rank + 1
	local anchor = index >= 1 and anchors[index] or nil
	if not anchor then return nil end
	return {
		x = anchor.x, y = anchor.y, offset = anchor.offset,
        pinZoom = globalVisualZoom.pin,
        circleZoom = globalVisualZoom.circle,
        iconZoom = globalVisualZoom.icon,
	}
end

function Calibration.getRadius()
    return RADIUS
end

function Calibration.saveWindowPosition(x, y, width, height)
    if not loaded or not finite(x) or not finite(y) or type(getCore) ~= "function" then
        return false
    end
    local core = getCore()
    if not core then return false end
    local screenWidth, screenHeight
    local ok = pcall(function()
        screenWidth = core:getScreenWidth()
        screenHeight = core:getScreenHeight()
    end)
    if not ok then return false end
    if not finite(screenWidth) or not finite(screenHeight) then return false end
    local panelWidth = finite(width) and width or 800
    local panelHeight = finite(height) and height or 430
    local maxX = math.max(0, screenWidth - panelWidth)
    local maxY = math.max(0, screenHeight - panelHeight)
    windowPosition = {
        x = math.max(0, math.min(math.floor(x), maxX)),
        y = math.max(0, math.min(math.floor(y), maxY)),
    }
    local ok, err = saveConfig()
    if not ok then print(TAG .. "could not save panel position: " .. safeText(err)) end
    return ok
end

function Calibration.setPreview(x, y, offset, pinZoom, circleZoom, iconZoom)
    local anchor = normalizedAnchor(x, y, offset, pinZoom, circleZoom, iconZoom)
    if not anchor then
        return false, "Altura: -64 a 64; zoom de pin, circulo e icono: 0.25 a 4.00."
    end
    previewAnchor = anchor
    return true
end

function Calibration.clearPreview()
    previewAnchor = nil
end

local function safeMember(object, field)
    local ok, value = pcall(function() return object and object[field] end)
    if ok then return value end
    return nil
end

local function safeCall(object, method, ...)
    local fn = safeMember(object, method)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    if ok then return value end
    return nil
end

local function textureSummary(texture)
    if not texture then return "none" end
    return string.format("%s:%sx%s", safeText(safeCall(texture, "getName")),
        safeText(safeCall(texture, "getWidth")), safeText(safeCall(texture, "getHeight")))
end

local function playerAndManager()
    if type(getSpecificPlayer) ~= "function" then return nil, nil end
    local player = getSpecificPlayer(0)
    if not player or not ISSearchManager or type(ISSearchManager.getManager) ~= "function" then
        return player, nil
    end
    local ok, manager = pcall(ISSearchManager.getManager, player)
    return player, ok and manager or nil
end

local function nearReportOrigin(icon, maxDistance)
    local x = tonumber(safeMember(icon, "xCoord")) or tonumber(safeMember(icon, "x"))
    local y = tonumber(safeMember(icon, "yCoord")) or tonumber(safeMember(icon, "y"))
    if not finite(x) or not finite(y) then return true, nil end
    local dx, dy = x - (window and window.originX or 0), y - (window and window.originY or 0)
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance <= maxDistance, distance
end

function Calibration.retryNearbyPins(originX, originY)
    local player, manager = playerAndManager()
    if not manager then return false, "No se encontro el administrador de rebusque." end
    local VPF = ViewpointForaging
    if not VPF or type(VPF.eachIcon) ~= "function" or type(VPF.placePin) ~= "function" then
        return false, "La API de pines de Viewpoint no esta disponible."
    end
    local count, visibleNow, restoredTextures, errors = 0, 0, 0, 0
    local previousX, previousY = window and window.originX, window and window.originY
    if window then window.originX, window.originY = originX, originY end
    VPF.eachIcon(manager, function(icon)
        local close = nearReportOrigin(icon, 64)
        if close and safeCall(icon, "getIsSeen") and not safeMember(icon, "isBeingRemoved") then
            count = count + 1
            local missingItemSprite = safeMember(icon, "itemObj") and not safeMember(icon, "itemTexture")
            if missingItemSprite and type(safeMember(icon, "initItem")) == "function" then
                local ok = pcall(icon.initItem, icon)
                if ok and safeMember(icon, "itemTexture") then
                    restoredTextures = restoredTextures + 1
                elseif not ok or not safeMember(icon, "itemTexture") then
                    errors = errors + 1
                end
            end
            local ok = pcall(VPF.placePin, icon)
            if not ok then
                errors = errors + 1
            elseif icon.vpfOnScreen and safeCall(icon, "getIsVisible") then
                visibleNow = visibleNow + 1
            end
        end
    end)
    if window then window.originX, window.originY = previousX, previousY end
    return true, string.format("Reintento: %d pines cercanos; %d visibles ahora; %d texturas recuperadas; %d errores.",
        count, visibleNow, restoredTextures, errors)
end

function Calibration.reportMissingPin(originX, originY)
    local player, manager = playerAndManager()
    if type(getFileWriter) ~= "function" then
        return false, "No esta disponible el escritor de reportes Lua."
    end
    local viewpointActive = "unknown"
    if ViewpointForaging and type(ViewpointForaging.active) == "function" then
        local activeOk, activeValue = pcall(ViewpointForaging.active)
        if activeOk then viewpointActive = activeValue end
    end
    local paused = "unknown"
    if type(isGamePaused) == "function" then
        local pausedOk, pausedValue = pcall(isGamePaused)
        if pausedOk then paused = pausedValue end
    end
    local core = type(getCore) == "function" and getCore() or nil
    local ok, err = pcall(function()
        local writer = getFileWriter(REPORT_FILE, true, true)
        if not writer then error("getFileWriter returned nil") end
        writer:write("\n=== PIN_NOT_RENDERED_REPORT " .. os.date("%Y-%m-%d %H:%M:%S") .. " ===\n")
        writer:write("origin=" .. safeText(originX) .. "," .. safeText(originY)
            .. " player=" .. safeText(player and safeCall(player, "getX")) .. ","
            .. safeText(player and safeCall(player, "getY"))
            .. " viewpointActive=" .. safeText(viewpointActive)
            .. " paused=" .. safeText(paused)
            .. " screen=" .. safeText(safeCall(core, "getScreenWidth")) .. "x"
            .. safeText(safeCall(core, "getScreenHeight"))
            .. " manager=" .. safeText(manager ~= nil) .. "\n")
        local entries = {}
        local targetIcon = ViewpointForaging and ViewpointForaging.hud
            and ViewpointForaging.hud.target or nil
        if manager and ViewpointForaging and type(ViewpointForaging.eachIcon) == "function" then
            ViewpointForaging.eachIcon(manager, function(icon)
                local close, distance = nearReportOrigin(icon, 64)
                if close then
                    entries[#entries + 1] = { icon = icon, distance = distance or 999999 }
                end
            end)
        end
        table.sort(entries, function(a, b) return a.distance < b.distance end)
        writer:write("nearbyIcons=" .. tostring(#entries) .. " (max 64 tiles; first 40 logged)\n")
        for index = 1, math.min(#entries, 40) do
            local icon = entries[index].icon
            local item = safeMember(icon, "itemObj")
            local itemType = safeCall(item, "getFullType") or safeCall(item, "getName")
            local identified = safeCall(icon, "getIsIdentified")
            writer:write(string.format(
                "icon=%d distance=%.2f class=%s item=%s seen=%s removing=%s identified=%s renderItem=%s " ..
                "visible=%s target=%s onScreen=%s fade=%s screen=%s,%s depth=%s size=%s,%s zoom=%s " ..
                "baseTexture=%s itemTexture=%s\n",
                index, entries[index].distance, safeText(safeMember(icon, "iconClass")), safeText(itemType),
                safeText(safeCall(icon, "getIsSeen")), safeText(safeMember(icon, "isBeingRemoved")),
                safeText(identified or safeMember(icon, "identified")),
                safeText(safeMember(icon, "renderItemTexture")),
                safeText(safeCall(icon, "getIsVisible")), safeText(icon == targetIcon),
                safeText(safeMember(icon, "vpfOnScreen")),
                safeText(safeMember(icon, "vpfFade")), safeText(safeMember(icon, "vpfSX")),
                safeText(safeMember(icon, "vpfSY")), safeText(safeMember(icon, "vpfDepth")),
                safeText(safeMember(icon, "width")), safeText(safeMember(icon, "height")),
                safeText(safeMember(icon, "zoom")), textureSummary(safeMember(icon, "texture")),
                textureSummary(safeMember(icon, "itemTexture"))))
        end
        writer:write("=== END_PIN_NOT_RENDERED_REPORT ===\n")
        writer:close()
    end)
    if not ok then
        print(TAG .. "pin failure report could not be written: " .. safeText(err))
        return false, "No se pudo guardar el reporte: " .. safeText(err)
    end
    print(TAG .. "pin-not-rendered diagnostic appended to Lua/" .. REPORT_FILE)
    return true, "Reporte agregado a Lua/" .. REPORT_FILE .. " para la auditoria de Codex."
end

function Calibration.saveAt(x, y, offset, pinZoom, circleZoom, iconZoom)
    local anchorValue = normalizedAnchor(x, y, offset, pinZoom, circleZoom, iconZoom)
    if not anchorValue then
        return false, "Altura: -64 a 64; zoom de pin, circulo e icono: 0.25 a 4.00."
    end
    -- Pin scale is a shared calibration: preserve it on every saved anchor.
    -- Height offsets remain specific to each location.
    for _, anchor in ipairs(anchors) do
        anchor.pinZoom = anchorValue.pinZoom
        anchor.circleZoom = anchorValue.circleZoom
        anchor.iconZoom = anchorValue.iconZoom
    end
    globalVisualZoom = {
        pin = anchorValue.pinZoom,
        circle = anchorValue.circleZoom,
        icon = anchorValue.iconZoom,
    }
    local nearest = nil
    local nearestDistanceSquared = REPLACE_RADIUS * REPLACE_RADIUS
    for _, anchor in ipairs(anchors) do
        local dx = x - anchor.x
        local dy = y - anchor.y
        local distanceSquared = dx * dx + dy * dy
        if distanceSquared <= nearestDistanceSquared then
            nearest = anchor
            nearestDistanceSquared = distanceSquared
        end
    end
    if nearest then
        nearest.x = x
        nearest.y = y
        nearest.offset = anchorValue.offset
        nearest.pinZoom = anchorValue.pinZoom
        nearest.circleZoom = anchorValue.circleZoom
        nearest.iconZoom = anchorValue.iconZoom
        for index, anchor in ipairs(anchors) do
			if anchor == nearest then
				table.remove(anchors, index)
				break
			end
		end
		anchors[#anchors + 1] = nearest
    else
        anchors[#anchors + 1] = anchorValue
    end
    previewAnchor = nil
    local ok, err = saveConfig()
    if not ok then return false, "No se pudo guardar: " .. safeText(err) end
    return true
end

function Calibration.removeNearestAt(x, y)
    if not finite(x) or not finite(y) then return false, "Ubicacion no disponible." end
    local nearestIndex = nil
    local nearestDistanceSquared = RADIUS * RADIUS
    for index, anchor in ipairs(anchors) do
        local dx = x - anchor.x
        local dy = y - anchor.y
        local distanceSquared = dx * dx + dy * dy
        if distanceSquared <= nearestDistanceSquared then
            nearestIndex = index
            nearestDistanceSquared = distanceSquared
        end
    end
    if not nearestIndex then
        previewAnchor = nil
        return false, "No hay un ancla guardada en este radio."
    end
    table.remove(anchors, nearestIndex)
    previewAnchor = nil
    local ok, err = saveConfig()
    if not ok then return false, "No se pudo guardar: " .. safeText(err) end
    return true
end

local function normalizedEntryText(entry)
    if not entry or type(entry.getText) ~= "function" then return nil end
	local ok, value = pcall(entry.getText, entry)
	if not ok then return nil end
	local text = (tostring(value or ""):gsub(",", "."))
	return text
end

local function parseOffset(entry)
	local text = normalizedEntryText(entry)
	return text and clampOffset(tonumber(text)) or nil
end

local CalibrationWindow = ISPanel:derive("ChilaSeda_ViewpointForagingCalibrationWindow")

function CalibrationWindow:new(x, y, originX, originY, initialOffset)
    local width, height = 800, 430
    local core = getCore()
    local screenWidth = core and core:getScreenWidth() or width
    local screenHeight = core and core:getScreenHeight() or height
    local panelX = math.max(0, math.floor((screenWidth - width) / 2))
    local panelY = math.max(0, math.floor((screenHeight - height) / 2))
    if windowPosition and finite(windowPosition.x) and finite(windowPosition.y) then
        panelX = math.max(0, math.min(math.floor(windowPosition.x), screenWidth - width))
        panelY = math.max(0, math.min(math.floor(windowPosition.y), screenHeight - height))
    end
    local panel = ISPanel.new(self, panelX, panelY, width, height)
    panel.originX = originX
    panel.originY = originY
    panel.currentOffset = initialOffset or 0
    panel.currentPinZoom, panel.currentCircleZoom, panel.currentIconZoom =
        Calibration.getVisualAt(originX, originY)
    panel.currentVisualZoom = commonZoom(panel.currentPinZoom, panel.currentCircleZoom,
        panel.currentIconZoom)
    panel.statusText = "Ajusta, prueba y guarda esta ubicacion."
    panel.suppressInputChange = false
    panel.backgroundColor = { r = 0.04, g = 0.035, b = 0.025, a = 0.94 }
    panel.borderColor = { r = 0.95, g = 0.48, b = 0.12, a = 1 }
    panel.moveWithMouse = true
    panel.wantMouseEvents = true
    panel.forceCursorVisible = true
    panel.activeWhilePaused = true
    return panel
end

local function addButton(panel, x, y, width, title, callback)
    local function protectedCallback(target, ...)
        local ok, a, b, c, d = pcall(callback, target, ...)
        if not ok then
            if target then target.statusText = "La accion fallo; el panel sigue disponible." end
            print(TAG .. "button callback failed (" .. safeText(title) .. "): " .. safeText(a))
            return false
        end
        return a, b, c, d
    end
    local button = ISButton:new(x, y, width, 30, title, panel, protectedCallback)
    button:initialise()
    button.backgroundColor = { r = 0.20, g = 0.15, b = 0.10, a = 1 }
    button.backgroundColorMouseOver = { r = 0.42, g = 0.25, b = 0.12, a = 1 }
    button.textColor = { r = 1, g = 0.90, b = 0.72, a = 1 }
    button.borderColor = { r = 0.95, g = 0.48, b = 0.12, a = 1 }
    panel:addChild(button)
    return button
end

function CalibrationWindow:createChildren()
    self.offsetEntry = ISTextEntryBox:new(string.format("%.3f", self.currentOffset),
        228, 118, 120, 30)
    self.offsetEntry:initialise()
    self.offsetEntry.target = self
    self.offsetEntry.onTextChangeFunction = function(target, entry)
        target:onSettingChanged("offset", entry)
    end
    self.offsetEntry.font = UIFont.Medium
    self:addChild(self.offsetEntry)

    self.visualZoomEntry = ISTextEntryBox:new(string.format("%.2f", self.currentVisualZoom),
        228, 160, 90, 28)
    self.visualZoomEntry:initialise()
    self.visualZoomEntry.target = self
    self.visualZoomEntry.onTextChangeFunction = function(target, changedEntry)
        target:onSettingChanged("visualZoom", changedEntry)
    end
    self.visualZoomEntry.font = UIFont.Medium
    self:addChild(self.visualZoomEntry)

    addButton(self, 355, 118, 88, "- 5.0", CalibrationWindow.onLower)
    addButton(self, 452, 118, 88, "+ 5.0", CalibrationWindow.onRaise)
    addButton(self, 355, 160, 88, "- 5 pts", CalibrationWindow.onVisualLower)
    addButton(self, 452, 160, 88, "+ 5 pts", CalibrationWindow.onVisualRaise)
    if not Calibration.nativeIntegrated then
        addButton(self, 355, 274, 88, "Recargar pin", CalibrationWindow.onReloadPin)
        addButton(self, 452, 274, 88, "Registrar fallo", CalibrationWindow.onReportPinFailure)
    end

    addButton(self, 18, 356, 124, "Aplicar", CalibrationWindow.onApply)
    addButton(self, 150, 356, 124, "Guardar aqui", CalibrationWindow.onSave)
    addButton(self, 282, 356, 124, "Borrar ancla", CalibrationWindow.onDelete)
    addButton(self, 414, 356, 124, "Cerrar", CalibrationWindow.onClose)

	self.recentAnchorButtons = {}
	for rank = 1, 5 do
		local anchorRank = rank
		self.recentAnchorButtons[rank] = addButton(self, 574, 90 + (rank - 1) * 35,
			210, "Sin ancla guardada", function(target)
				target:onRecentAnchorSelected(anchorRank)
			end)
		self.recentAnchorButtons[rank]:setFont(UIFont.Small)
	end
	self.useRecentAnchorButton = addButton(self, 574, 270, 210,
		"Usar valores aqui", CalibrationWindow.onUseRecentAnchorHere)
	self.useRecentAnchorButton:setFont(UIFont.Small)
	self:refreshRecentAnchorButtons()
end

function CalibrationWindow:prerender()
    ISPanel.prerender(self)
    if not headerIconLoaded then
        headerIconLoaded = true
        local ok, texture = pcall(getTexture, HEADER_ICON_PATH)
        if ok then headerIcon = texture end
    end
    if headerIcon then
        self:drawTextureScaled(headerIcon, 14, 12, 24, 24, 1, 1, 1, 1)
    end
    self:drawText("Ajuste manual de pines de rebusque", 46, 14,
        1, 0.78, 0.47, 1, UIFont.Medium)
    self:drawText("Ajusta altura y escala; los valores se aplican en vivo en esta zona.",
        14, 44, 0.92, 0.90, 0.84, 1, UIFont.Small)
    self:drawText(string.format("Ubicacion: X %.2f   Y %.2f", self.originX, self.originY),
        14, 76, 0.86, 0.88, 0.90, 1, UIFont.Small)
    local _, info = Calibration.getOffsetAt(self.originX, self.originY)
    local anchorText
    if info then
        local anchorKind = info.kind == "preview" and "temporal"
            or info.kind == "interpolated" and "interpolada" or "guardada"
        anchorText = string.format("Ancla %s (%.2f, %.2f), distancia %.1f; ajuste %+.3f (%d puntos)",
            anchorKind, info.x, info.y, info.distance, info.offset, info.sampleCount or 1)
    else
        anchorText = "Sin ancla cercana; ajuste manual actual: 0.000"
    end
    self:drawText(anchorText, 14, 98, 0.86, 0.88, 0.90, 1, UIFont.Small)
    self:drawText("Altura extra:", 120, 124, 0.95, 0.95, 0.95, 1, UIFont.Small)
    self:drawText("Zoom conjunto:", 132, 166, 0.95, 0.95, 0.95, 1, UIFont.Small)
    self:drawText("Zoom 0.25-4.00; guardar aplica pin, circulo e icono a todas las anclas.", 14, 310,
        0.82, 0.84, 0.85, 1, UIFont.Small)
    self:drawText(self.statusText, 14, 332, 1, 0.78, 0.47, 1, UIFont.Small)
    self:drawText("Registrar fallo guarda un diagnostico Lua para la auditoria.",
        14, 398, 0.75, 0.78, 0.80, 1, UIFont.Small)
	self:drawText("Anclas recientes", 574, 48, 1, 0.78, 0.47, 1, UIFont.Medium)
	self:drawText("Pulsa una para calibrar esa zona.", 574, 69,
		0.82, 0.84, 0.85, 1, UIFont.Small)
end

function CalibrationWindow:refreshRecentAnchorButtons()
	for rank, button in ipairs(self.recentAnchorButtons or {}) do
		local anchor = Calibration.getRecentAnchor(rank)
		if anchor then
			button:setTitle(string.format("%d) %.1f, %.1f / %+.1f",
				rank, anchor.x, anchor.y, anchor.offset))
			button.enable = true
		else
			button:setTitle("Sin ancla guardada")
			button.enable = false
		end
	end
	if self.useRecentAnchorButton then
		self.useRecentAnchorButton.enable = self.selectedRecentAnchor ~= nil
	end
end

function CalibrationWindow:onRecentAnchorSelected(rank)
	local anchor = Calibration.getRecentAnchor(rank)
	if not anchor then
		self.statusText = "No hay ancla guardada en esa posicion."
		return
	end
	self.originX, self.originY = anchor.x, anchor.y
	self.selectedRecentAnchor = anchor
	if self.useRecentAnchorButton then self.useRecentAnchorButton.enable = true end
	self.currentOffset = anchor.offset
    self.currentPinZoom, self.currentCircleZoom, self.currentIconZoom =
        Calibration.getVisualAt(anchor.x, anchor.y)
    self.currentVisualZoom = commonZoom(self.currentPinZoom, self.currentCircleZoom,
        self.currentIconZoom)
	self:setEntryValue(anchor.offset)
	self:setVisualEntryValue(self.currentVisualZoom)
	Calibration.setPreview(self.originX, self.originY, anchor.offset,
		self.currentVisualZoom, self.currentVisualZoom, self.currentVisualZoom)
	local _, message = self:refreshPinsAfterAdjustment()
	self.statusText = string.format("Ancla reciente seleccionada: %.1f, %.1f. %s",
		anchor.x, anchor.y, message or "Ajusta y guarda.")
end

function CalibrationWindow:onUseRecentAnchorHere()
	local anchor = self.selectedRecentAnchor
	if not anchor then
		self.statusText = "Selecciona una ancla reciente primero."
		return
	end
	local player = type(getSpecificPlayer) == "function" and getSpecificPlayer(0) or nil
	if not player then
		self.statusText = "No se encontro la ubicacion actual del jugador."
		return
	end
	local ok, x, y = pcall(function() return player:getX(), player:getY() end)
	if not ok or not finite(x) or not finite(y) then
		self.statusText = "No se pudo leer la ubicacion actual del jugador."
		return
	end
	self.originX, self.originY = x, y
	self.currentOffset = anchor.offset
    self.currentPinZoom, self.currentCircleZoom, self.currentIconZoom =
        Calibration.getVisualAt(x, y)
    self.currentVisualZoom = commonZoom(self.currentPinZoom, self.currentCircleZoom,
        self.currentIconZoom)
	self:setEntryValue(anchor.offset)
	self:setVisualEntryValue(self.currentVisualZoom)
	Calibration.setPreview(x, y, anchor.offset,
		self.currentVisualZoom, self.currentVisualZoom, self.currentVisualZoom)
	local _, message = self:refreshPinsAfterAdjustment()
	self.statusText = string.format("Ajuste copiado al punto %.1f, %.1f; %s",
		x, y, message or "modifica y guarda.")
end

function CalibrationWindow:setEntryValue(value)
    self.suppressInputChange = true
    self.offsetEntry:setText(string.format("%.3f", value))
    self.suppressInputChange = false
end

local function entryNumber(entry, minValue, maxValue)
	local normalized = normalizedEntryText(entry)
	if not normalized then return nil end
    local value = tonumber(normalized)
    if not finite(value) then return nil end
    return math.max(minValue, math.min(maxValue, value))
end

function CalibrationWindow:readSettings()
    local offset = parseOffset(self.offsetEntry)
    local zoom = entryNumber(self.visualZoomEntry, MIN_ZOOM, MAX_ZOOM)
    if offset == nil or zoom == nil then
        return nil, "Altura: -64 a 64; zoom: 0.25 a 4.00."
    end
    return { offset = offset, visualZoom = zoom,
        pinZoom = zoom, circleZoom = zoom, iconZoom = zoom }
end

function CalibrationWindow:applySettings()
    local settings, err = self:readSettings()
    if not settings then self.statusText = err; return false end
    self.currentOffset = settings.offset
    self.currentPinZoom = settings.pinZoom
    self.currentCircleZoom = settings.circleZoom
    self.currentIconZoom = settings.iconZoom
    self.currentVisualZoom = settings.visualZoom
    -- Apply updates the runtime-wide scale immediately; Save persists it to Lua.
    globalVisualZoom = {
        pin = settings.pinZoom,
        circle = settings.circleZoom,
        icon = settings.iconZoom,
    }
    Calibration.setPreview(self.originX, self.originY, settings.offset,
        settings.pinZoom, settings.circleZoom, settings.iconZoom)
    return true, settings
end

function CalibrationWindow:onSettingChanged(_field, _entry)
    if self.suppressInputChange then return end
    local ok, settings = self:applySettings()
    if ok then
        local _, message = self:refreshPinsAfterAdjustment()
        self.statusText = string.format("Vista previa: altura %+.3f; zoom conjunto %.2fx; %s",
            settings.offset, settings.visualZoom, message or "visibilidad pendiente.")
    end
end

function CalibrationWindow:refreshPinsAfterAdjustment()
    if Calibration.nativeIntegrated then
        return true, "Viewpoint nativo aplica altura y escala en tiempo real."
    end
    local callOk, ok, message = pcall(Calibration.retryNearbyPins, self.originX, self.originY)
    if not callOk then
        print(TAG .. "manual adjustment pin refresh failed: " .. safeText(ok))
        return false, "No se pudo comprobar la visibilidad; revisa el registro Lua."
    end
    if not ok then
        return false, message or "No se pudo volver a proyectar los pines cercanos."
    end
    return true, message or "Pines cercanos re-proyectados."
end

function CalibrationWindow:onReloadPin()
	local _, message = self:refreshPinsAfterAdjustment()
	self.statusText = message or "Reintento terminado."
end

function CalibrationWindow:onReportPinFailure()
    local callOk, ok, message = pcall(Calibration.reportMissingPin, self.originX, self.originY)
    if not callOk then
        self.statusText = "Registrar fallo no pudo guardar; revisa el registro Lua."
        print(TAG .. "Registrar fallo failed: " .. safeText(ok))
        return
    end
    self.statusText = message or (ok and "Reporte guardado." or "No se pudo guardar el reporte.")
end

function CalibrationWindow:applyValue()
    local ok, settings = self:applySettings()
    if not ok then return false end
    local _, message = self:refreshPinsAfterAdjustment()
    self.statusText = string.format("Aplicado: altura %+.3f; zoom conjunto %.2fx; %s",
        settings.offset, settings.visualZoom, message or "visibilidad pendiente.")
    return true
end

function CalibrationWindow:onApply()
    self:applyValue()
end

function CalibrationWindow:onLower()
    local current = parseOffset(self.offsetEntry) or self.currentOffset or 0
    self:setEntryValue(math.max(-MAX_OFFSET, current - HEIGHT_NUDGE))
    self:applyValue()
end

function CalibrationWindow:onRaise()
    local current = parseOffset(self.offsetEntry) or self.currentOffset or 0
    self:setEntryValue(math.min(MAX_OFFSET, current + HEIGHT_NUDGE))
    self:applyValue()
end

function CalibrationWindow:setVisualEntryValue(zoom)
    self.suppressInputChange = true
    self.visualZoomEntry:setText(string.format("%.2f", zoom))
    self.suppressInputChange = false
end

function CalibrationWindow:adjustVisualScales(direction)
    local zoom = entryNumber(self.visualZoomEntry, MIN_ZOOM, MAX_ZOOM)
    if zoom == nil then
        self.statusText = "Corrige el zoom conjunto (0.25 a 4.00) antes de ajustarlo."
        return
    end
    local nextZoom = math.max(MIN_ZOOM, math.min(MAX_ZOOM,
        zoom + VISUAL_NUDGE * direction))
    self:setVisualEntryValue(nextZoom)
    if not self:applyValue() then return end
    self.statusText = string.format("Zoom conjunto de pin, circulo e icono: %.2fx.", nextZoom)
end

function CalibrationWindow:onVisualLower()
    self:adjustVisualScales(-1)
end

function CalibrationWindow:onVisualRaise()
    self:adjustVisualScales(1)
end

function CalibrationWindow:onSave()
    local settings, readError = self:readSettings()
    if not settings then self.statusText = readError; return end
    local ok, err = Calibration.saveAt(self.originX, self.originY, settings.offset,
        settings.pinZoom, settings.circleZoom, settings.iconZoom)
    if not ok then
        self.statusText = err
        return
    end
    self.currentOffset = settings.offset
    self.currentPinZoom, self.currentCircleZoom, self.currentIconZoom =
        settings.pinZoom, settings.circleZoom, settings.iconZoom
    self.currentVisualZoom = settings.visualZoom
    self.statusText = "Altura de esta zona y zoom global guardados."
	local _, message = self:refreshPinsAfterAdjustment()
	self.statusText = "Altura de esta zona y zoom global guardados; " .. (message or "visibilidad pendiente.")
	self.selectedRecentAnchor = Calibration.getRecentAnchor(1)
	self:refreshRecentAnchorButtons()
end

function CalibrationWindow:onDelete()
    local ok, err = Calibration.removeNearestAt(self.originX, self.originY)
    if not ok then
        self.statusText = err
        return
    end
    Calibration.clearPreview()
    local value = Calibration.getOffsetAt(self.originX, self.originY)
    self.currentOffset = value or 0
    self:setEntryValue(self.currentOffset)
    self.currentPinZoom, self.currentCircleZoom, self.currentIconZoom =
        Calibration.getVisualAt(self.originX, self.originY)
    self.currentVisualZoom = commonZoom(self.currentPinZoom, self.currentCircleZoom,
        self.currentIconZoom)
    self.selectedRecentAnchor = nil
    self.suppressInputChange = true
    self.visualZoomEntry:setText(string.format("%.2f", self.currentVisualZoom))
    self.suppressInputChange = false
	Calibration.setPreview(self.originX, self.originY, self.currentOffset,
		self.currentVisualZoom, self.currentVisualZoom, self.currentVisualZoom)
	local _, message = self:refreshPinsAfterAdjustment()
	self.statusText = "Ancla mas cercana borrada y configuracion guardada; "
		.. (message or "visibilidad pendiente.")
	self:refreshRecentAnchorButtons()
end

function CalibrationWindow:onClose()
    Calibration.saveWindowPosition(self:getX(), self:getY(), self.width, self.height)
    Calibration.clearPreview()
    self:setVisible(false)
    self:removeFromUIManager()
    if window == self then window = nil end
end

function CalibrationWindow:onMouseUp(x, y)
    local wasMoving = self.moving == true
    ISPanel.onMouseUp(self, x, y)
    if wasMoving then
        Calibration.saveWindowPosition(self:getX(), self:getY(), self.width, self.height)
    end
    return true
end

function CalibrationWindow:onMouseUpOutside(x, y)
    local wasMoving = self.moving == true
    ISPanel.onMouseUpOutside(self, x, y)
    if wasMoving then
        Calibration.saveWindowPosition(self:getX(), self:getY(), self.width, self.height)
    end
    return true
end

local function currentPlayerPosition()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local player = getSpecificPlayer(0)
    if not player then return nil end
    local ok, x, y = pcall(function() return player:getX(), player:getY() end)
    if not ok or not finite(x) or not finite(y) then return nil end
    return x, y
end

local function toggleWindow()
    if not Calibration.nativeIntegrated then
        print(TAG .. "integrated Viewpoint foraging API is unavailable")
        return
    end
    if window and window:getIsVisible() then
        window:onClose()
        return
    end
    local x, y = currentPlayerPosition()
    if not x or not y then
        print(TAG .. "cannot open calibration panel: player position unavailable")
        return
    end
    if not loaded then loadConfig() end
    local currentOffset = Calibration.getOffsetAt(x, y)
    window = CalibrationWindow:new(0, 0, x, y, currentOffset)
    window:initialise()
    window:instantiate()
    Calibration.setPreview(x, y, currentOffset, window.currentVisualZoom,
        window.currentVisualZoom, window.currentVisualZoom)
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
end

local function keyDown(key)
    if key == nil then return false end
    if Keyboard and type(Keyboard.isKeyDown) == "function" then
        local ok, down = pcall(Keyboard.isKeyDown, key)
        if ok then return down == true end
    end
    if type(isKeyDown) == "function" then
        local ok, down = pcall(isKeyDown, key)
        return ok and down == true
    end
    return false
end

local shortcutWasDown = false

local function shortcutDown()
    if not Keyboard then return false end
    local deleteKey = Keyboard.KEY_DELETE
    if deleteKey == nil then return false end
    local control = keyDown(Keyboard.KEY_LCONTROL) or keyDown(Keyboard.KEY_RCONTROL)
    local shift = keyDown(Keyboard.KEY_LSHIFT) or keyDown(Keyboard.KEY_RSHIFT)
    return control and shift and keyDown(deleteKey)
end

local function handleShortcut(source)
    if not Calibration.nativeIntegrated then
        shortcutWasDown = false
        return
    end
    local down = shortcutDown()
    if down and not shortcutWasDown then
        shortcutWasDown = true
        print(TAG .. "Ctrl+Shift+Delete detected via " .. source)
        local ok, err = pcall(toggleWindow)
        if not ok then print(TAG .. "panel toggle failed: " .. safeText(err)) end
    elseif not down then
        shortcutWasDown = false
    end
end

if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(function()
        if not loaded then loadConfig() end
    end)
end

if Events and Events.OnKeyPressed and type(Events.OnKeyPressed.Add) == "function" then
    Events.OnKeyPressed.Add(function(key)
        local deleteKey = Keyboard and Keyboard.KEY_DELETE
        if deleteKey ~= nil and key == deleteKey then handleShortcut("OnKeyPressed") end
    end)
end

-- Some Viewpoint input paths consume key events before the global key callback
-- sees Delete. Poll the held chord as a fallback and share the same edge latch
-- so one keypress can only open or close the panel once.
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(function() handleShortcut("OnTick") end)
end

-- OnTick stops while single-player is paused, which made the fallback shortcut
-- unavailable from the pause screen. Poll the same edge-triggered chord on the
-- event that continues ticking during pause as well.
if Events and Events.OnTickEvenPaused and type(Events.OnTickEvenPaused.Add) == "function" then
    Events.OnTickEvenPaused.Add(function() handleShortcut("OnTickEvenPaused") end)
end

loadConfig()
print(TAG .. "ready; Ctrl+Shift+Delete opens per-area pin height calibration (including while paused)")

return Calibration
