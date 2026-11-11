require "ISUI/ISUIElement"

local viewpointLoaded = pcall(require, "Viewpoint_Loot")
if not viewpointLoaded or type(ViewpointLoot) ~= "table" then
    print("[ChilaSeda_ViewpointHaloNotifications] Viewpoint unavailable; patch skipped.")
    return
end

local TAG = "[ChilaSeda_ViewpointHaloNotifications] "
local MAX_NOTIFICATIONS = 3
local DISPLAY_MS = 6000
local TRAIT_ICON_DEFAULT = "media/ui/Moodles/32/Mood_Concentrating.png"
local LEVEL_UP_GREEN = { r = 0.35, g = 1, b = 0.48 }
local notifications = {}
local overlay

local function nowMs()
	if type(getTimestampMs) == "function" then return getTimestampMs() end
	return math.floor(os.clock() * 1000)
end

local function wrapText(text, maxChars)
	local lines = {}
	local line = ""
	for word in tostring(text):gmatch("%S+") do
		if line ~= "" and #line + #word + 1 > maxChars then
			lines[#lines + 1] = line
			line = word
		else
			line = line == "" and word or (line .. " " .. word)
		end
	end
	if line ~= "" then lines[#lines + 1] = line end
	if #lines > 2 then
		lines[2] = lines[2]:sub(1, maxChars - 3) .. "..."
		while #lines > 2 do table.remove(lines) end
	end
	return lines
end

local function drawInlineLine(self, line, y, font, color, icons, arrow, arrowColor)
	local manager = getTextManager()
	local parts = {}
	if arrow ~= nil then
		parts[#parts + 1] = {
			text = arrow and "+ " or "- ",
			color = arrowColor or color,
		}
	end
	local cursor = 1
	while true do
		local startAt, endAt, iconIndex = line:find("%[ICON:(%d+)%]", cursor)
		if not startAt then
			if cursor <= #line then
				parts[#parts + 1] = { text = line:sub(cursor) }
			end
			break
		end
		if startAt > cursor then
			parts[#parts + 1] = { text = line:sub(cursor, startAt - 1) }
		end
		parts[#parts + 1] = { icon = icons[tonumber(iconIndex)] }
		cursor = endAt + 1
	end

	local iconSize = manager:getFontHeight(font)
	local totalWidth = 0
	for _, part in ipairs(parts) do
		if part.icon then
			part.width = iconSize
		else
			part.width = manager:MeasureStringX(font, part.text)
		end
		totalWidth = totalWidth + part.width
	end

	local x = (self.width - totalWidth) / 2
	for _, part in ipairs(parts) do
		if part.icon then
			local texture = part.icon
			if type(texture) == "string" then
				local texturePath = texture:gsub("\\", "/")
				if not texturePath:match("%.[%w]+$") then texturePath = texturePath .. ".png" end
				texture = getTexture(texturePath)
			end
			if texture then
				local textureWidth = texture:getWidth()
				local textureHeight = texture:getHeight()
				local scale = iconSize / math.max(textureWidth, textureHeight)
				local drawWidth = textureWidth * scale
				local drawHeight = textureHeight * scale
				self:drawTextureScaled(texture, x, y + (iconSize - drawHeight) / 2,
					drawWidth, drawHeight, 1)
			end
			x = x + part.width
		else
			local partColor = part.color or color
			self:drawText(part.text, x + 1, y + 1, 0, 0, 0, 0.9, font)
			self:drawText(part.text, x, y,
				partColor.r, partColor.g, partColor.b, 1, font)
			x = x + part.width
		end
	end
end

local function isLocalPlayer(player)
	if not player then return false end
	if type(getSpecificPlayer) ~= "function" then return false end
	local localPlayer = getSpecificPlayer(0)
	if player == localPlayer then return true end
	return type(player.getPlayerNum) == "function"
		and localPlayer and type(localPlayer.getPlayerNum) == "function"
		and player:getPlayerNum() == localPlayer:getPlayerNum()
end

local function traitSemanticColor(text)
	local normalized = tostring(text or ""):lower()
	local beneficial = { "poca sed", "menos sed", "low thirst", "less thirsty", "less thirst" }
	local harmful = { "sanador lento", "propenso a enfermar", "slow healer", "prone to illness" }
	for _, phrase in ipairs(beneficial) do
		if normalized:find(phrase, 1, true) then return LEVEL_UP_GREEN end
	end
	for _, phrase in ipairs(harmful) do
		if normalized:find(phrase, 1, true) then return { r = 1, g = 0.38, b = 0.34 } end
	end
	return nil
end

local function traitIconForMessage(text)
	local normalized = tostring(text):lower()
	if normalized:find("sed", 1, true) or normalized:find("thirst", 1, true) then
		return "media/ui/Moodles/32/Status_Thirst.png"
	end
	if normalized:find("insomn", 1, true) or normalized:find("sleep", 1, true)
			or normalized:find("fatig", 1, true) or normalized:find("cansad", 1, true) then
		return "media/ui/Moodles/32/Mood_Sleepy.png"
	end
	if normalized:find("rasgo", 1, true) or normalized:find("trait", 1, true) then
		return TRAIT_ICON_DEFAULT
	end
	return nil
end

local function addNotification(text, color, arrow, arrowColor, icon, traitStyle)
	if type(text) ~= "string" or text == "" then return false end
	if traitStyle and not icon then icon = traitIconForMessage(text) or TRAIT_ICON_DEFAULT end
	local icons = {}
	if type(icon) == "string" and icon:match("%S") and not text:find("[img=", 1, true) then
		text = "[img=" .. icon .. "] " .. text
	elseif icon and not text:find("[img=", 1, true) and not text:find("[ICON:", 1, true) then
		icons[1] = icon
		text = "[ICON:1] " .. text
	end
	text = text:gsub("%[img=([^%]]+)%]", function(texturePath)
		icons[#icons + 1] = texturePath
		return " [ICON:" .. #icons .. "] "
	end)
	text = text:gsub("^%s*(.-)%s*$", "%1")
	if text == "" then return false end
	notifications[#notifications + 1] = {
		text = text,
		lines = wrapText(text, 68),
		icons = icons,
		color = color or { r = 1, g = 1, b = 1 },
		arrow = arrow,
		arrowColor = arrowColor,
		expiresAt = nowMs() + DISPLAY_MS,
	}
	while #notifications > MAX_NOTIFICATIONS do table.remove(notifications, 1) end
	return true
end

ChilaSeda_ViewpointHaloNotifications = ISUIElement:derive("ChilaSeda_ViewpointHaloNotifications")

function ChilaSeda_ViewpointHaloNotifications:render()
	local current = nowMs()
	while #notifications > 0 and notifications[1].expiresAt <= current do
		table.remove(notifications, 1)
	end
	if #notifications == 0 then
		self:removeFromUIManager()
		if overlay == self then overlay = nil end
		return
	end

	local font = UIFont.Medium
	local textHeight = getTextManager():getFontHeight(font)
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()
	local width = math.min(screenWidth * 0.76, 1120)
	local lineStep = textHeight + 3
	local totalHeight = 0
	for index, entry in ipairs(notifications) do
		totalHeight = totalHeight + #entry.lines * lineStep
		if index < #notifications then totalHeight = totalHeight + 8 end
	end
	local top = screenHeight * 0.235
	self:setX((screenWidth - width) / 2)
	self:setY(top)
	self:setWidth(width)
	self:setHeight(totalHeight)
	local y = 0
	for _, entry in ipairs(notifications) do
		local entryHeight = #entry.lines * lineStep
		for lineIndex, line in ipairs(entry.lines) do
			local lineY = y + (lineIndex - 1) * lineStep
			local arrow
			if lineIndex == 1 then arrow = entry.arrow end
			drawInlineLine(self, line, lineY, font, entry.color, entry.icons,
				arrow, entry.arrowColor)
		end
		y = y + entryHeight + 8
	end
end

local function createOverlay()
	if overlay then return end
	overlay = ChilaSeda_ViewpointHaloNotifications:new(0, 0, 1, 1)
	overlay.wantMouseEvents = false
	overlay:initialise()
	overlay:addToUIManager()
	overlay:setCapture(false)
	overlay.javaObject:setConsumeMouseEvents(false)

	-- Insert the text overlay immediately below the top-level inventory pages.
	-- AddToUIManager normally appends it above windows that are already open.
	local ok, ui = pcall(function() return UIManager.getUI() end)
	if ok and ui and type(getPlayerLoot) == "function" then
		local firstInventoryIndex = nil
		for playerNum = 0, 3 do
			local gotLoot, playerLoot = pcall(getPlayerLoot, playerNum)
			local page = gotLoot and playerLoot and playerLoot.inventoryPane
				and playerLoot.inventoryPane.inventoryPage or nil
			local inventoryUI = page and page.javaObject or nil
			if inventoryUI then
				local gotIndex, index = pcall(function() return ui:indexOf(inventoryUI) end)
				if gotIndex and type(index) == "number" and index >= 0
						and (firstInventoryIndex == nil or index < firstInventoryIndex) then
					firstInventoryIndex = index
				end
			end
		end
		if firstInventoryIndex ~= nil then
			local gotOverlayIndex, overlayIndex = pcall(function() return ui:indexOf(overlay.javaObject) end)
			if gotOverlayIndex and type(overlayIndex) == "number" and overlayIndex >= 0
					and overlayIndex > firstInventoryIndex then
				pcall(function()
					ui:remove(overlay.javaObject)
					ui:add(firstInventoryIndex, overlay.javaObject)
				end)
			end
		end
	end
end

function ChilaSeda_ViewpointHaloNotifications.showFixed(text, color, icon)
	if not addNotification(text, color, nil, nil, icon) then return false end
	createOverlay()
	return true
end

local function onSkillLevelUp(player, perk, level, gainedLevel)
	if gainedLevel ~= true or not isLocalPlayer(player) or not perk
			or type(perk.getName) ~= "function" then return end
	local ok, perkName = pcall(perk.getName, perk)
	if not ok or type(perkName) ~= "string" or perkName == "" then return end
	ChilaSeda_ViewpointHaloNotifications.showFixed(
		"+1 " .. perkName, LEVEL_UP_GREEN, "media/ui/ArrowUp.png")
end

if Events and Events.LevelPerk then Events.LevelPerk.Add(onSkillLevelUp) end

-- Rune Exp owns the actual XP-drop callback (including fractional gains).
-- Route those same gains into the fixed Halo overlay without altering its bar.
local runeExpHookInstalled = false
local function installRuneExpHaloHook()
	local expBar = ISExpBar
	if runeExpHookInstalled or not expBar or type(expBar.expDrop) ~= "function" then return false end
	local original = expBar.expDrop
	expBar.expDrop = function(self, perk, amount, ...)
		if tonumber(amount) and tonumber(amount) ~= 0 and perk
				and type(perk.getName) == "function" then
			local ok, name = pcall(perk.getName, perk)
			if ok and type(name) == "string" and name ~= "" then
				local xp = tonumber(amount)
				local sign = xp > 0 and "+" or ""
				ChilaSeda_ViewpointHaloNotifications.showFixed(
					sign .. string.format("%.2f XP %s", xp, name),
					{ r = 1, g = 0.78, b = 0.32 })
			end
		end
		return original(self, perk, amount, ...)
	end
	runeExpHookInstalled = true
	print(TAG .. "Rune Exp gains routed to fixed Halo notes")
	return true
end

installRuneExpHaloHook()
if Events and Events.OnGameStart then Events.OnGameStart.Add(installRuneExpHaloHook) end
if Events and Events.OnTick and not runeExpHookInstalled then
	local function retryRuneExpHaloHook()
		if installRuneExpHaloHook() then Events.OnTick.Remove(retryRuneExpHaloHook) end
	end
	Events.OnTick.Add(retryRuneExpHaloHook)
end

function ChilaSeda_ViewpointHaloNotifications:new(x, y, width, height)
	local object = ISUIElement.new(self, x, y, width, height)
	setmetatable(object, self)
	self.__index = self
	return object
end

local javaHelper
local proxy
local function installHaloTextHelperHook()
	local helper = HaloTextHelper
	if helper == nil or helper == proxy then return false end
	javaHelper = helper
	proxy = setmetatable({}, { __index = function(_, key) return javaHelper[key] end })

	local function wrapMethod(name, colorSelector, arrowSelector, arrowColorSelector, iconSelector)
		local original = javaHelper[name]
		if original == nil then return end
		proxy[name] = function(...)
			local args = { ... }
			local player, message = args[1], args[2]
			if isLocalPlayer(player) and type(message) == "string" then
				if message == "Zombies nearby - slowing down" and type(getText) == "function" then
					local translated = getText("UI_ChilaSeda_ZombiesNearbySlowingDown")
					if translated and translated ~= "UI_ChilaSeda_ZombiesNearbySlowingDown" then
						message = translated
					end
				end
				local color = colorSelector(args)
				local arrow, arrowColor
				if arrowSelector then arrow = arrowSelector(args) end
				if arrowColorSelector then arrowColor = arrowColorSelector(args, color) end
				local semanticColor = traitSemanticColor(message)
				if semanticColor then
					color = semanticColor
					if arrow ~= nil then arrowColor = semanticColor end
				end
				local icon = iconSelector and iconSelector(args) or nil
				local traitStyle = name == "addTextWithArrow"
					or (name == "addText" and traitIconForMessage(message) ~= nil)
				addNotification(message, color, arrow, arrowColor, icon, traitStyle)
				createOverlay()
				return
			end
			return original(...)
		end
	end

	local white = { r = 1, g = 1, b = 1 }
	local green = { r = 0.35, g = 1, b = 0.48 }
	local red = { r = 1, g = 0.38, b = 0.34 }
	local function fixed(color) return function() return color end end
	local function colorComponent(color, field, getter)
		local ok, value = pcall(function() return color[field] end)
		if ok and type(value) == "number" then return value end
		local okGetter, method = pcall(function() return color[getter] end)
		if okGetter and type(method) == "function" then
			local okValue, result = pcall(method, color)
			if okValue and type(result) == "number" then return result end
		end
		return nil
	end
	local function normalizedColor(r, g, b)
		if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return white end
		if r > 1 or g > 1 or b > 1 then
			r, g, b = r / 255, g / 255, b / 255
		end
		return { r = r, g = g, b = b }
	end
	local function rgb(args, first)
		if type(args[first]) == "number" then
			return normalizedColor(args[first], args[first + 1], args[first + 2])
		end
		local color = args[first]
		if color then
			local r = colorComponent(color, "r", "getR")
			local g = colorComponent(color, "g", "getG")
			local b = colorComponent(color, "b", "getB")
			if r and g and b then return normalizedColor(r, g, b) end
		end
		return white
	end
	local function arrowColor(args, arrowIndex, textColor)
		local textColorIndex = arrowIndex + 1
		local separateColorIndex = textColorIndex + (type(args[textColorIndex]) == "number" and 3 or 1)
		if args[separateColorIndex] ~= nil then return rgb(args, separateColorIndex) end
		return textColor
	end

	wrapMethod("addText", function(args)
		local message = args[2]
		if type(message) == "string" and message:find("[img=", 1, true) then return green end
		return args[3] and rgb(args, 4) or white
	end, nil, nil, function(args) return args[3] end)
	wrapMethod("addGoodText", fixed(green))
	wrapMethod("addBadText", fixed(red))
	wrapMethod("addTextWithArrow", function(args)
		local arrowIndex = type(args[3]) == "boolean" and 3 or 4
		return rgb(args, arrowIndex + 1)
	end, function(args)
		local arrowIndex = type(args[3]) == "boolean" and 3 or 4
		if type(args[arrowIndex]) == "boolean" then return args[arrowIndex] end
		return nil
	end, function(args)
		local arrowIndex = type(args[3]) == "boolean" and 3 or 4
		return arrowColor(args, arrowIndex, rgb(args, arrowIndex + 1))
	end)
	proxy.forceNextAddText = function() end
	HaloTextHelper = proxy
	print(TAG .. "all local HaloTextHelper notices routed to fixed screen UI")
	return true
end

installHaloTextHelperHook()
if Events and Events.OnGameStart then Events.OnGameStart.Add(installHaloTextHelperHook) end

