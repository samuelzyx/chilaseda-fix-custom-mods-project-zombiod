require "ISUI/ISUIElement"

local viewpointLoaded = pcall(require, "Viewpoint_Loot")
if not viewpointLoaded or type(ViewpointLoot) ~= "table" then
    print("[ChilaSeda_ViewpointHaloNotifications] Viewpoint unavailable; patch skipped.")
    return
end

local TAG = "[ChilaSeda_ViewpointHaloNotifications] "
local MAX_NOTIFICATIONS = 3
local DISPLAY_MS = 6000
local LEVEL_UP_GREEN = { r = 0.35, g = 1, b = 0.48 }
local TRAIT_HARMFUL_RED = { r = 1, g = 0.38, b = 0.34 }
local XP_ICON_DEFAULT = "media/ui/SkillPanel/SkillUnit_fill.png"
local STRENGTH_ICON
local PERK_ICONS = {
	carpentry = "media/ui/Sidebar/48/Carpentry_On_48.png",
	woodwork = "media/ui/Sidebar/48/Carpentry_On_48.png",
	foraging = "media/ui/Sidebar/48/Search_On_48.png",
	plantscavenging = "media/ui/Sidebar/48/Search_On_48.png",
	fishing = "media/ui/survival_guide_spiffo/category_fishing.png",
	farming = "media/ui/survival_guide_spiffo/category_farming.png",
	cooking = "media/ui/survival_guide_spiffo/category_food_and_water.png",
	mechanics = "media/ui/survival_guide_spiffo/category_vehicles.png",
	firstaid = "media/ui/survival_guide_spiffo/mood_first_aid.png",
	tailoring = "media/ui/Traits/trait_tailor.png",
	trapping = "media/ui/survival_guide_spiffo/category_ranching.png",
	aiming = "media/ui/Reticle/aimCircle08.png",
	reloading = "media/ui/survival_guide_spiffo/category_combat.png",
	axe = "media/ui/survival_guide_spiffo/category_combat.png",
	longblade = "media/ui/survival_guide_spiffo/category_combat.png",
	longblunt = "media/ui/survival_guide_spiffo/category_combat.png",
	smallblade = "media/ui/survival_guide_spiffo/category_combat.png",
	smallblunt = "media/ui/survival_guide_spiffo/category_combat.png",
	spear = "media/ui/survival_guide_spiffo/category_combat.png",
	fitness = "media/ui/survival_guide_spiffo/category_movement.png",
	strength = "Base.DumbBell",
	lightfoot = "media/ui/survival_guide_spiffo/category_movement.png",
	nimble = "media/ui/survival_guide_spiffo/category_movement.png",
	sneak = "media/ui/survival_guide_spiffo/category_movement.png",
	sprinting = "media/ui/survival_guide_spiffo/category_movement.png",
	electricity = "media/ui/survival_guide_spiffo/category_crafting.png",
	maintenance = "media/ui/survival_guide_spiffo/category_crafting.png",
	metalwelding = "media/ui/survival_guide_spiffo/category_crafting.png",
}
local notifications = {}
local traitSemanticDiagnostics = {}
local genericTraitArrowDiagnostics = {}
local genericTraitArrowTraceCount = 0
local MAX_GENERIC_TRAIT_ARROW_TRACE_LINES = 12
local overlay
local hudVisibilityTraceCount = 0
local lastHudVisibilityState = nil
local hudVisibilityFallbackLogged = false

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

local function drawDirectionTriangle(self, x, y, size, pointsUp, color, alpha)
	local centerX = x + math.floor(size / 2)
	local r, g, b = color.r, color.g, color.b
	for row = 0, size - 1 do
		local progress = pointsUp and (row + 1) / size or (size - row) / size
		local rowWidth = math.max(1, math.floor(size * progress))
		self:drawRect(centerX - math.floor(rowWidth / 2), y + row,
			rowWidth, 1, alpha, r, g, b)
	end
end

local function drawInlineLine(self, line, y, font, color, icons, arrow, arrowColor, iconColor)
	local manager = getTextManager()
	local parts = {}
	if arrow ~= nil then
		parts[#parts + 1] = { direction = arrow, color = arrowColor or color }
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
		if part.icon or part.direction ~= nil then
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
					drawWidth, drawHeight, 1,
					iconColor and iconColor.r or 1,
					iconColor and iconColor.g or 1,
					iconColor and iconColor.b or 1)
			end
			x = x + part.width
		elseif part.direction ~= nil then
			drawDirectionTriangle(self, x + 1, y + 1, iconSize, part.direction,
				{ r = 0, g = 0, b = 0 }, 0.9)
			drawDirectionTriangle(self, x, y, iconSize, part.direction, part.color or color, 1)
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

local function perkIconFor(perk)
	if perk and type(perk.getId) == "function" then
		local ok, perkId = pcall(perk.getId, perk)
		if ok and type(perkId) == "string" and perkId ~= "" then
			local key = perkId:lower():gsub("[%s_%-]", "")
			local icon = PERK_ICONS[key]
			if icon == "Base.DumbBell" then
				if not STRENGTH_ICON and ScriptManager and ScriptManager.instance then
					local okItem, item = pcall(function()
						return ScriptManager.instance:getItem(icon)
					end)
					if okItem and item then
						local okTexture, texture = pcall(function()
							local icon = item:getNormalTexture()
							local variants = item:getIconsForTexture()
							if variants and not variants:isEmpty() then icon = variants:get(0) end
							return icon
						end)
						if okTexture then STRENGTH_ICON = texture or false end
					end
				end
				if STRENGTH_ICON then
					return STRENGTH_ICON ~= false and STRENGTH_ICON or XP_ICON_DEFAULT
				end
			elseif icon then
				return icon
			end
		end
	end
	return XP_ICON_DEFAULT
end

local function translatedText(key)
	if type(getText) ~= "function" then return nil end
	local ok, value = pcall(getText, key)
	if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
	return nil
end

local function containsTranslatedName(normalized, key)
	local translated = translatedText(key)
	return translated and normalized:find(translated:lower(), 1, true) ~= nil
end

local function sleepTraitKind(text)
	local normalized = tostring(text or ""):lower()
	if normalized:find("insomne", 1, true)
			or normalized:find("wakeful", 1, true)
			or normalized:find("less sleep", 1, true)
			or normalized:find("menor necesidad de sueño", 1, true)
			or containsTranslatedName(normalized, "UI_trait_LessSleep") then
		return "lessSleep"
	end
	if normalized:find("dormil", 1, true)
			or normalized:find("sleepyhead", 1, true)
			or normalized:find("more sleep", 1, true)
			or normalized:find("mayor necesidad de sueño", 1, true)
			or containsTranslatedName(normalized, "UI_trait_MoreSleep") then
		return "moreSleep"
	end
	return nil
end

local function sleepTraitDisplay(kind)
	local key = kind == "lessSleep"
		and "UI_ChilaSeda_ViewpointHalo_LessSleep"
		or "UI_ChilaSeda_ViewpointHalo_MoreSleep"
	local fallback = kind == "lessSleep"
		and "Needs less sleep (shorter sleep duration)"
		or "Needs more sleep (longer sleep duration)"
	local translated = translatedText(key)
	return translated or fallback, translated and "translation" or "fallback"
end

local function sleepTraitDelta(kind, pointsUp)
	if type(pointsUp) ~= "boolean" then return nil, nil, nil end
	local beneficial
	if kind == "lessSleep" then
		beneficial = pointsUp
	elseif kind == "moreSleep" then
		beneficial = not pointsUp
	else
		return nil, nil, nil
	end
	return beneficial,
		beneficial and LEVEL_UP_GREEN or TRAIT_HARMFUL_RED,
		beneficial and "beneficial" or "harmful"
end

local function traitSemanticColor(text)
	local normalized = tostring(text or ""):lower()
	local beneficial = { "poca sed", "menos sed", "low thirst", "less thirsty", "less thirst" }
	local harmful = { "sanador lento", "propenso a enfermar", "slow healer", "prone to illness" }
	for _, phrase in ipairs(beneficial) do
		if normalized:find(phrase, 1, true) then return LEVEL_UP_GREEN end
	end
	for _, phrase in ipairs(harmful) do
		if normalized:find(phrase, 1, true) then return { r = 1, g = 0.34, b = 0.56 } end
	end
	return nil
end

local function traitArrowColor(pointsUp, semanticColor, inputColor)
	if semanticColor then return semanticColor, "semantic" end
	if pointsUp == false then return TRAIT_HARMFUL_RED, "direction-default" end
	return inputColor, "input"
end

local function traitIconForMessage(text)
	local normalized = tostring(text):lower()
	if normalized:find("sed", 1, true) or normalized:find("thirst", 1, true) then
		return "media/ui/Moodles/32/Status_Thirst.png"
	end
	if normalized:find("sanador lento", 1, true) or normalized:find("slow healer", 1, true) then
		return "media/ui/Moodles/32/Status_InjuredMinor.png"
	end
	if normalized:find("propenso a enfermar", 1, true)
			or normalized:find("prone to illness", 1, true) then
		return "media/ui/Moodles/32/Mood_Ill.png"
	end
	if sleepTraitKind(text) or normalized:find("insomn", 1, true)
			or normalized:find("sleep", 1, true) or normalized:find("sueño", 1, true)
			or normalized:find("sueno", 1, true) or normalized:find("dormir", 1, true)
			or normalized:find("fatig", 1, true) or normalized:find("cansad", 1, true) then
		return "media/ui/Moodles/32/Mood_Sleepy.png"
	end
	return nil
end

local function addNotification(text, color, arrow, arrowColor, icon, traitStyle, iconColor)
	if type(text) ~= "string" or text == "" then return false end
	if traitStyle and not icon then icon = traitIconForMessage(text) end
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
		iconColor = iconColor,
		expiresAt = nowMs() + DISPLAY_MS,
	}
	while #notifications > MAX_NOTIFICATIONS do table.remove(notifications, 1) end
	return true
end

local function hudVisibilityState()
	local handler = ISUIHandler
	if type(handler) == "table" and type(handler.allUIVisible) == "boolean" then
		return handler.allUIVisible, "ISUIHandler.allUIVisible"
	end
	return true, "fallback-visible"
end

local function syncOverlayVisibility()
	if not overlay then return false end
	local hudVisible, source = hudVisibilityState()
	if source ~= "ISUIHandler.allUIVisible" and not hudVisibilityFallbackLogged then
		hudVisibilityFallbackLogged = true
		print(TAG .. "hud-visibility state unavailable; fallback=visible")
	end
	if lastHudVisibilityState ~= hudVisible then
		lastHudVisibilityState = hudVisible
		if hudVisibilityTraceCount < 12 then
			hudVisibilityTraceCount = hudVisibilityTraceCount + 1
			print(TAG .. "hud-visibility=" .. (hudVisible and "visible" or "hidden")
				.. " source=" .. source .. " notices=" .. tostring(#notifications))
		end
	end
	local shouldBeVisible = hudVisible and #notifications > 0
	if overlay.visible ~= shouldBeVisible then
		local ok, err = pcall(function() overlay:setVisible(shouldBeVisible) end)
		if not ok then
			if hudVisibilityTraceCount < 12 then
				hudVisibilityTraceCount = hudVisibilityTraceCount + 1
				local detail = tostring(err):gsub("[\\r\\n]", " ")
				print(TAG .. "hud-visibility apply-failed=" .. detail)
			end
			return false
		end
		if hudVisibilityTraceCount < 12 then
			hudVisibilityTraceCount = hudVisibilityTraceCount + 1
			print(TAG .. "hud-visibility overlay=" .. (shouldBeVisible and "shown" or "hidden"))
		end
	end
	return shouldBeVisible
end

local function expireNotifications(current)
	while #notifications > 0 and notifications[1].expiresAt <= current do
		table.remove(notifications, 1)
	end
end

local function removeEmptyOverlay()
	if #notifications > 0 or not overlay then return false end
	local current = overlay
	pcall(function() current:setVisible(false) end)
	pcall(function() current:removeFromUIManager() end)
	if overlay == current then overlay = nil end
	return true
end

ChilaSeda_ViewpointHaloNotifications = ISUIElement:derive("ChilaSeda_ViewpointHaloNotifications")

function ChilaSeda_ViewpointHaloNotifications:render()
	expireNotifications(nowMs())
	if #notifications == 0 then
		removeEmptyOverlay()
		return
	end
	if not syncOverlayVisibility() then return end

	-- Keep every fixed Halo notice at the same compact size as the action-bar label.
	local font = UIFont.Small
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
				arrow, entry.arrowColor, entry.iconColor)
		end
		y = y + entryHeight + 8
	end
end

local function keepOverlayBehindUI()
	if not overlay then return end
	expireNotifications(nowMs())
	if #notifications == 0 then
		removeEmptyOverlay()
		return
	end
	if not syncOverlayVisibility() or not overlay.javaObject then return end
	local ok, ui = pcall(function() return UIManager.getUI() end)
	if not ok or not ui then return end
	local gotIndex, index = pcall(function() return ui:indexOf(overlay.javaObject) end)
	if not gotIndex or type(index) ~= "number" then return end
	if index > 0 then
		pcall(function()
			ui:remove(overlay.javaObject)
			ui:add(0, overlay.javaObject)
		end)
	elseif index < 0 then
		pcall(function() ui:add(0, overlay.javaObject) end)
	end
end

local function createOverlay()
	if overlay then
		syncOverlayVisibility()
		keepOverlayBehindUI()
		return
	end
	overlay = ChilaSeda_ViewpointHaloNotifications:new(0, 0, 1, 1)
	overlay.wantMouseEvents = false
	overlay:initialise()
	overlay:addToUIManager()
	overlay:setCapture(false)
	overlay.javaObject:setConsumeMouseEvents(false)
	syncOverlayVisibility()
	keepOverlayBehindUI()
end

if Events and Events.OnTick then Events.OnTick.Add(keepOverlayBehindUI) end
if Events and Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(keepOverlayBehindUI) end
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
	-- Keep the native level-up indicator and the +1 text; no extra skill icon.
	if addNotification(getText("UI_ChilaSeda_ViewpointHalo_LevelUp", perkName),
			LEVEL_UP_GREEN, nil, nil, "media/ui/ArrowUp.png", nil, LEVEL_UP_GREEN) then
		createOverlay()
	end
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
					 getText("UI_ChilaSeda_ViewpointHalo_XP", sign .. string.format("%.2f", xp), name),
					{ r = 1, g = 0.78, b = 0.32 }, perkIconFor(perk))
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
				local normalizedMessage = message:lower():gsub("%s+", " ")
				if normalizedMessage:find("zombies nearby", 1, true)
						and normalizedMessage:find("slowing down", 1, true) then
					local key = "UI_ChilaSeda_ZombiesNearbySlowingDown"
					local translated
					if type(getText) == "function" then
						local ok, value = pcall(getText, key)
						if ok and type(value) == "string" and value ~= "" and value ~= key
								and not value:lower():find("zombies nearby", 1, true) then
							translated = value
						end
					end
					message = translated or message
				end
				local color = colorSelector(args)
				local arrow, arrowColor
				if arrowSelector then arrow = arrowSelector(args) end
				if arrowColorSelector then arrowColor = arrowColorSelector(args, color) end
				local sleepKind = sleepTraitKind(message)
				local labelSource
				if sleepKind then message, labelSource = sleepTraitDisplay(sleepKind) end
				local semanticColor
				if sleepKind and arrow ~= nil then
					local inputArrow = arrow
					local effect
					arrow, semanticColor, effect = sleepTraitDelta(sleepKind, inputArrow)
					local diagnosticKey = sleepKind .. ":" .. tostring(inputArrow)
					if not traitSemanticDiagnostics[diagnosticKey] then
						traitSemanticDiagnostics[diagnosticKey] = true
						local inputDirection = inputArrow and "up" or "down"
						local displayDirection = arrow and "up" or "down"
						local colorName = effect == "beneficial" and "green" or "red"
						print(TAG .. "sleep-trait kind=" .. sleepKind
							.. " input=" .. inputDirection .. " display=" .. displayDirection
							.. " effect=" .. tostring(effect) .. " color=" .. colorName
							.. " label-source=" .. tostring(labelSource))
					end
				else
					semanticColor = traitSemanticColor(message)
				end
				if semanticColor then
					color = semanticColor
				end
				local icon = iconSelector and iconSelector(args) or nil
				local traitStyle = name == "addTextWithArrow"
					or (name == "addText" and traitIconForMessage(message) ~= nil)
				if traitStyle and arrow ~= nil then
					local arrowColorSource
					arrowColor, arrowColorSource = traitArrowColor(arrow, semanticColor, arrowColor)
					if arrowColorSource == "direction-default" then
						local diagnosticKey = tostring(message):lower()
						if genericTraitArrowTraceCount < MAX_GENERIC_TRAIT_ARROW_TRACE_LINES
								and not genericTraitArrowDiagnostics[diagnosticKey] then
							genericTraitArrowDiagnostics[diagnosticKey] = true
							genericTraitArrowTraceCount = genericTraitArrowTraceCount + 1
							print(TAG .. "generic-trait-arrow name=" .. tostring(message):gsub("[%s]+", " ")
								.. " direction=down color=red source=direction-default")
						end
					end
				end
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

