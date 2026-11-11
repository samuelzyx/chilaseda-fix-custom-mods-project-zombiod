require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISInventoryPaneContextMenu"
require "PZAPI/ui/organisms/PrintMedia"

local RevealSystem = require("ChilaSeda_ArchiveRevealSystem")

local ARCHIVE_KEY = "ChilaSedaPersonalReadingArchive"
local ITEM_TYPE = "ChilaSeda_PersonalReadingArchive.PersonalReadingArchive"

local CATEGORIES = {
	{ id = "index", label = "UI_ReadingArchive_MainIndex", order = 1 },
	{ id = "magazines", label = "UI_ReadingArchive_Magazines", order = 2 },
	{ id = "newspapers", label = "UI_ReadingArchive_Newspapers", order = 3 },
	{ id = "maps", label = "UI_ReadingArchive_AnnotatedMaps", order = 4 },
	{ id = "ids", label = "UI_ReadingArchive_Identifications", order = 5 },
}

local function call(method, object, ...)
	if not object or type(object[method]) ~= "function" then return nil end
	local ok, result = pcall(object[method], object, ...)
	if ok then return result end
	return nil
end

local function getMediaCategory(record)
	if not record then return "magazines" end
	local fullType = record.fullType or ""
	local textKey = record.textKey or ""

	if string.find(fullType, "Newspaper") or string.find(textKey, "Newspaper") then
		return "newspapers"
	elseif string.find(textKey, "Map") then
		return "maps"
	elseif string.find(fullType, "ID") or string.find(textKey, "Identification") then
		return "ids"
	end
	return "magazines"
end

local function getArchive(player)
	local data = call("getModData", player)
	if not data then return nil end
	local archive = data[ARCHIVE_KEY]
	if type(archive) ~= "table" then
		archive = { version = 2, records = {}, discovered = {} }
		data[ARCHIVE_KEY] = archive
	end
	if type(archive.records) ~= "table" then archive.records = {} end
	if type(archive.discovered) ~= "table" then archive.discovered = {} end
	return archive
end

local function copyRecord(media, item)
	if type(media) ~= "table" or type(media.id) ~= "string" then return nil end
	local name = item and call("getName", item) or nil
	local category = getMediaCategory({ fullType = item and call("getFullType", item) or "" })
	return {
		id = media.id,
		infoKey = media.info,
		titleKey = media.title,
		textKey = media.text,
		itemName = name and tostring(name) or nil,
		fullType = item and call("getFullType", item) or nil,
		category = category,
	}
end

local function storeRecord(player, media, item)
	local record = copyRecord(media, item)
	if not record then return end
	local archive = getArchive(player)
	if not archive then return end

	local old = archive.records[record.id]
	if old then
		if not old.infoKey then old.infoKey = record.infoKey end
		if not old.titleKey then old.titleKey = record.titleKey end
		if not old.textKey then old.textKey = record.textKey end
		if not old.itemName then old.itemName = record.itemName end
		if not old.fullType then old.fullType = record.fullType end
		if not old.category then old.category = record.category end
	else
		archive.records[record.id] = record
	end

	archive.discovered[record.id] = true
end

local function translated(key)
	if type(key) ~= "string" or key == "" then return nil end
	local value = getTextOrNull and getTextOrNull(key) or nil
	if value and value ~= "" then return tostring(value) end
	return tostring(key)
end

local function recordTitle(record)
	return translated(record.titleKey) or record.itemName or tostring(record.id)
end

local function openNativeMedia(record, playerNum)
	if not record or not PZAPI or not PZAPI.UI or not PZAPI.UI.PrintMedia then return end
	local win = PZAPI.UI.PrintMedia({ x = 20, y = 20 })
	if not win or not win.children or not win.children.bar then return end

	local title = translated(record.titleKey) or record.itemName or tostring(record.id)
	win.media_id = record.id
	win.data = translated(record.infoKey) or ""
	win.children.bar.children.name.text = title
	win.textTitle = title
	win.textData = string.gsub(translated(record.textKey) or "", "\\n", "\n")
	win:instantiate()
	if win.javaObj then win.javaObj:setAlwaysOnTop(false) end
	win:centerOnScreen(playerNum)

	if getJoypadData(playerNum) then
		require "ISUI/ISAtomUIJoypad"
		ISAtomUIJoypad.Apply(win)
		win.close = function(self)
			UIManager.RemoveElement(self.javaObj)
			if getJoypadData(self.playerNum) then
				setJoypadFocus(self.playerNum, self.prevFocus)
			end
		end
		win.children.bar.children.closeButton.onLeftClick = function(button)
			getSoundManager():playUISound(button.sounds.activate)
			button.parent.parent:close()
		end
		win.playerNum = playerNum
		win.prevFocus = getJoypadData(playerNum).focus
		win.onJoypadDown = function(self, button)
			if button == Joypad.BButton then
				self.children.bar.children.closeButton:onLeftClick()
			elseif button == Joypad.XButton then
				self:onClickNewspaperButton()
			elseif button == Joypad.YButton then
				self:onClickMapButton()
				self.children.bar.children.closeButton:onLeftClick()
			end
		end
		setJoypadFocus(playerNum, win)
	end
end

local GFX_PATH = "media/gfx/"
local FRONT_COVER_TEXTURE = "media/textures/ChilaSeda_Album_FrontCover.png"
local BACK_COVER_TEXTURE = "media/textures/ChilaSeda_Album_BackCover.png"

local BACKGROUND_TEXTURES = {
	index = GFX_PATH .. "index_background.png",
	magazines = GFX_PATH .. "album_cover_base.png",
	newspapers = GFX_PATH .. "album_cover_base.png",
	maps = GFX_PATH .. "map_background.png",
	ids = GFX_PATH .. "id_card_template.png",
}

local CATEGORY_ICONS = {
	magazines = GFX_PATH .. "category_icon_magazines.png",
	newspapers = GFX_PATH .. "category_icon_newspapers.png",
	maps = GFX_PATH .. "category_icon_maps.png",
	ids = GFX_PATH .. "category_icon_ids.png",
}

local HERALD_TEST_ID = "KentuckyHerald_July16"
local HERALD_MEDIA_INFO_KEY = "Print_Media_KentuckyHerald_July16_info"
local HERALD_MEDIA_TITLE_KEY = "Print_Media_KentuckyHerald_July16_title"
local HERALD_TEXT_KEY = "Print_Text_KentuckyHerald_July16_info"
local FASHIONABELLE_MEDIA_ID = "fashionabelle"
local FASHIONABELLE_MEDIA_INFO_KEY = "Print_Media_FashionaBelle_info"
local FASHIONABELLE_MEDIA_TITLE_KEY = "Print_Media_FashionaBelle_title"
local FASHIONABELLE_TEXT_KEY = "Print_Text_FashionaBelle_info"

local function archiveRecordsFor(player)
	local archive = getArchive(player)
	local records = {}
	for _, record in pairs(archive and archive.records or {}) do
		if record.infoKey and record.titleKey and record.textKey
			and record.id ~= HERALD_TEST_ID and record.id ~= FASHIONABELLE_MEDIA_ID then
			records[#records + 1] = record
		end
	end
	table.sort(records, function(a, b)
		return string.lower(recordTitle(a)) < string.lower(recordTitle(b))
	end)
	return records
end

local CategoryWindow = ISPanel:derive("ChilaSedaReadingArchiveCategoryWindow")

local ArchiveBookWindow = ISPanel:derive("ChilaSedaReadingArchiveBookWindow")
local ArchiveBookControls = ISPanel:derive("ChilaSedaReadingArchiveBookControls")

-- Handles the parent/text/texture elements used by this print-media layout.
-- Abort on unknown element types instead of drawing an incomplete original.
local function parseHeraldLayout(markup)
	local width, height
	local children = {}
	local index = 0

	for header, value in string.gmatch(markup or "", "<([^>]*)>([^<]*)") do
		local properties = {}
		for field in string.gmatch(header, "[^,]+") do
			local key, fieldValue = string.match(field, "^%s*([^:]+):%s*(.-)%s*$")
			if key and fieldValue then properties[key] = fieldValue end
		end

		local kind = properties.type
		if kind == "parent" then
			width = tonumber(properties.width)
			height = tonumber(properties.height)
		elseif kind == "text" or kind == "texture" then
			index = index + 1
			local element = kind == "text" and PZAPI.UI.Text{} or PZAPI.UI.Texture{}
			for key, fieldValue in pairs(properties) do
				if key ~= "type" then
					if key == "font" then
						element[key] = UIFont.FromString(fieldValue)
					elseif key == "texture" then
						element[key] = getTexture(fieldValue)
					else
						element[key] = tonumber(fieldValue) or fieldValue
					end
				end
			end
			if kind == "text" then
				element.text = string.gsub(value, "%^", "\n")
			end
			children[index] = element
		elseif kind then
			return nil
		end
	end

	if not width or not height or index == 0 then return nil end
	return width, height, children
end

local function makeHeraldRenderer(window)
	local ok, markup = pcall(function()
		-- Match ISReadABook:displayPrintMedia(), which resolves the media layout
		-- through the active language's print-media translations.
		return getText(HERALD_MEDIA_INFO_KEY)
	end)
	if not ok or not markup or markup == "" or markup == HERALD_MEDIA_INFO_KEY then
		print("[P-002.2 diagnostic] media layout lookup failed; key=" ..
			HERALD_MEDIA_INFO_KEY .. " ok=" .. tostring(ok) ..
			" valueType=" .. type(markup))
		return nil
	end
	local canvasWidth, canvasHeight, visualChildren = parseHeraldLayout(markup)
	if not canvasWidth then
		print("[P-002.2 diagnostic] media layout parsed no drawable children; key=" ..
			HERALD_MEDIA_INFO_KEY .. " markupLength=" .. tostring(#markup))
		return nil
	end
	-- Vanilla supplies getText(val.title) and getText(val.text) to PrintMedia.
	-- getTextOrNull() does not follow the print-media lookup used by that UI.
	local titleValue = getText(HERALD_MEDIA_TITLE_KEY)
	local articleValue = getText(HERALD_TEXT_KEY)
	print("[P-002.2 diagnostic] source loaded; canvas=" .. canvasWidth .. "x" ..
		canvasHeight .. " visualChildren=" .. #visualChildren ..
		" titleResolved=" .. tostring(titleValue and titleValue ~= HERALD_MEDIA_TITLE_KEY) ..
		" textResolved=" .. tostring(articleValue and articleValue ~= HERALD_TEXT_KEY) ..
		" textLength=" .. tostring(articleValue and #articleValue or 0))

	local visual = PZAPI.UI.Node{
		width = canvasWidth,
		height = canvasHeight,
		pivotX = 0,
		pivotY = 0,
		children = visualChildren,
		onLeftDrag = function(self, data, dx, dy)
			self:setX(self.x + dx)
			self:setY(self.y + dy)
			return true
		end,
	}
	local leftClip = PZAPI.UI.Node{
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = { composition = visual },
		onMouseWheel = function(self, delta)
			local root = self.parent
			local zoom = math.max(0.25, math.min(4, root.documentZoom - delta * 0.1))
			root.documentZoom = zoom
			local scale = root.fitScale * zoom
			self.children.composition:setScaleX(scale)
			self.children.composition:setScaleY(scale)
			return true
		end,
	}

	local title = PZAPI.UI.Text{
		x = 16, y = 14,
		font = UIFont.SdfOldBold,
		scaleX = 0.62, scaleY = 0.62,
		r = 0.20, g = 0.13, b = 0.08, a = 1,
		text = titleValue,
	}
	local rule = PZAPI.UI.Texture{
		x = 16, y = 54,
		width = math.max(1, window.pageWidth - 48), height = 2,
		r = 0.38, g = 0.27, b = 0.16, a = 0.65,
	}
	local articleText = string.gsub(articleValue, "\\n", "\n")
	local body = PZAPI.UI.Text{
		x = 16, y = 70,
		scaleX = 0.46, scaleY = 0.46,
		r = 0.15, g = 0.12, b = 0.08, a = 1,
		text = articleText,
	}
	local scrollbar
	local textContainer = PZAPI.UI.Node{
		x = 8, y = 8,
		width = math.max(1, window.pageWidth - 34),
		height = window.pageHeight - 16,
		children = { title = title, rule = rule, text = body },
		onScroll = function(self, percent)
			if scrollbar then scrollbar:updateBar(percent) end
		end,
	}
	local rightClip = PZAPI.UI.Node{
		x = window.pageWidth + window.pageGutter,
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = {
			container = textContainer,
			scrollBar = PZAPI.UI.ScrollBarVertical{
				x = math.max(0, window.pageWidth - 20), y = 8,
				width = 11, height = math.max(1, window.pageHeight - 16),
			},
		},
	}
	scrollbar = rightClip.children.scrollBar
	textContainer.init = function(self)
		scrollbar.container = self
	end

	return PZAPI.UI.Node{
		x = window.leftPageX,
		y = window.pageY,
		width = window.pageWidth * 2 + window.pageGutter,
		height = window.pageHeight,
		documentId = HERALD_TEST_ID,
		documentZoom = 1,
		fitScale = 1,
		children = { leftClip = leftClip, rightClip = rightClip },
	}
end

-- P-002.5: dedicated layout for the vanilla FashionaBelle brochure.
-- It reuses the native translated markup parser, but keeps document-specific
-- keys and state separate from the Kentucky Herald opening.
local function makeFashionaBelleRenderer(window)
	local ok, markup = pcall(function()
		return getText(FASHIONABELLE_MEDIA_INFO_KEY)
	end)
	if not ok or not markup or markup == "" or
			markup == FASHIONABELLE_MEDIA_INFO_KEY then
		print("[P-002.5] FashionaBelle layout lookup failed")
		return nil
	end
	local canvasWidth, canvasHeight, visualChildren = parseHeraldLayout(markup)
	if not canvasWidth then
		print("[P-002.5] FashionaBelle layout did not parse")
		return nil
	end
	local titleValue = getText(FASHIONABELLE_MEDIA_TITLE_KEY)
	local textValue = getText(FASHIONABELLE_TEXT_KEY)
	if not titleValue or titleValue == FASHIONABELLE_MEDIA_TITLE_KEY or
			not textValue or textValue == FASHIONABELLE_TEXT_KEY then
		print("[P-002.5] FashionaBelle title/text translation lookup failed")
		return nil
	end

	local visual = PZAPI.UI.Node{
		width = canvasWidth,
		height = canvasHeight,
		pivotX = 0,
		pivotY = 0,
		children = visualChildren,
		onLeftDrag = function(self, data, dx, dy)
			self:setX(self.x + dx)
			self:setY(self.y + dy)
			return true
		end,
	}
	local leftClip = PZAPI.UI.Node{
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = { composition = visual },
		onMouseWheel = function(self, delta)
			local root = self.parent
			local zoom = math.max(0.25, math.min(4,
				root.documentZoom - delta * 0.1))
			root.documentZoom = zoom
			local scale = root.fitScale * zoom
			self.children.composition:setScaleX(scale)
			self.children.composition:setScaleY(scale)
			return true
		end,
	}
	local title = PZAPI.UI.Text{
		x = 16, y = 14,
		font = UIFont.SdfOldBold,
		scaleX = 0.62, scaleY = 0.62,
		r = 0.20, g = 0.13, b = 0.08, a = 1,
		text = titleValue,
	}
	local rule = PZAPI.UI.Texture{
		x = 16, y = 54,
		width = math.max(1, window.pageWidth - 48), height = 2,
		r = 0.38, g = 0.27, b = 0.16, a = 0.65,
	}
	local body = PZAPI.UI.Text{
		x = 16, y = 70,
		scaleX = 0.46, scaleY = 0.46,
		r = 0.15, g = 0.12, b = 0.08, a = 1,
		text = string.gsub(textValue, "\\n", "\n"),
	}
	local scrollbar
	local textContainer = PZAPI.UI.Node{
		x = 8, y = 8,
		width = math.max(1, window.pageWidth - 34),
		height = window.pageHeight - 16,
		children = {
			title = title,
			rule = rule,
			text = body,
			nativeMap = PZAPI.UI.ImageButton{
				width = 30, height = 30,
				texture = getTexture("media/textures/Item_Map.png"),
				onLeftClick = function()
					openNativeMedia({
						id = FASHIONABELLE_MEDIA_ID,
						infoKey = FASHIONABELLE_MEDIA_INFO_KEY,
						titleKey = FASHIONABELLE_MEDIA_TITLE_KEY,
						textKey = FASHIONABELLE_TEXT_KEY,
					}, window.playerNum)
					return true
				end,
			},
		},
		onScroll = function(self, percent)
			if scrollbar then scrollbar:updateBar(percent) end
		end,
	}
	local rightClip = PZAPI.UI.Node{
		x = window.pageWidth + window.pageGutter,
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = {
			container = textContainer,
			scrollBar = PZAPI.UI.ScrollBarVertical{
				x = math.max(0, window.pageWidth - 20), y = 8,
				width = 11, height = math.max(1, window.pageHeight - 16),
			},
		},
	}
	scrollbar = rightClip.children.scrollBar
	textContainer.init = function(self) scrollbar.container = self end

	return PZAPI.UI.Node{
		x = window.leftPageX,
		y = window.pageY,
		width = window.pageWidth * 2 + window.pageGutter,
		height = window.pageHeight,
		documentId = FASHIONABELLE_MEDIA_ID,
		documentZoom = 1,
		fitScale = 1,
		children = { leftClip = leftClip, rightClip = rightClip },
	}
end

local function mediaItemIcon(record)
	local manager = type(getScriptManager) == "function" and getScriptManager()
	local fullType = record and record.fullType
	local scriptItem = manager and fullType and call("FindItem", manager, fullType)
	local texture = call("getNormalTexture", scriptItem)
	if not texture and manager then
		local fallbackType = record and record.category == "maps" and "Base.Map" or "Base.Brochure"
		scriptItem = call("FindItem", manager, fallbackType)
		texture = call("getNormalTexture", scriptItem)
	end
	return texture
end

local function makeArchiveRecordRenderer(window, record)
	if not record then return nil end
	local markup = record.infoKey and translated(record.infoKey) or nil
	local canvasWidth, canvasHeight, visualChildren
	if markup and markup ~= record.infoKey then
		canvasWidth, canvasHeight, visualChildren = parseHeraldLayout(markup)
	end
	if not canvasWidth then
		local icon = mediaItemIcon(record)
		if not icon then
			print("[P-002.5A] media has no composition or item icon: " .. tostring(record.id))
			return nil
		end
		canvasWidth, canvasHeight = 256, 320
		visualChildren = {
			PZAPI.UI.Texture{
				x = 0, y = 32, width = 256, height = 256,
				texture = icon,
			},
		}
	end

	local visual = PZAPI.UI.Node{
		width = canvasWidth,
		height = canvasHeight,
		pivotX = 0,
		pivotY = 0,
		children = visualChildren,
		onLeftDrag = function(self, data, dx, dy)
			self:setX(self.x + dx)
			self:setY(self.y + dy)
			return true
		end,
	}
	local leftClip = PZAPI.UI.Node{
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = { composition = visual },
		onMouseWheel = function(self, delta)
			local root = self.parent
			local zoom = math.max(0.25, math.min(4, root.documentZoom - delta * 0.1))
			root.documentZoom = zoom
			local scale = root.fitScale * zoom
			self.children.composition:setScaleX(scale)
			self.children.composition:setScaleY(scale)
			return true
		end,
	}
	local titleValue = recordTitle(record)
	local textValue = translated(record.textKey) or ""
	local title = PZAPI.UI.Text{
		x = 16, y = 14, font = UIFont.SdfOldBold,
		scaleX = 0.62, scaleY = 0.62,
		r = 0.20, g = 0.13, b = 0.08, a = 1,
		text = titleValue,
	}
	local rule = PZAPI.UI.Texture{
		x = 16, y = 54, width = math.max(1, window.pageWidth - 48), height = 2,
		r = 0.38, g = 0.27, b = 0.16, a = 0.65,
	}
	local body = PZAPI.UI.Text{
		x = 16, y = 70, scaleX = 0.46, scaleY = 0.46,
		r = 0.15, g = 0.12, b = 0.08, a = 1,
		text = string.gsub(textValue, "\\n", "\n"),
	}
	local scrollbar
	local textContainer = PZAPI.UI.Node{
		x = 8, y = 8,
		width = math.max(1, window.pageWidth - 34),
		height = window.pageHeight - 16,
		children = { title = title, rule = rule, text = body },
		onScroll = function(self, percent)
			if scrollbar then scrollbar:updateBar(percent) end
		end,
	}
	local rightClip = PZAPI.UI.Node{
		x = window.pageWidth + window.pageGutter,
		width = window.pageWidth,
		height = window.pageHeight,
		isStencil = true,
		children = {
			container = textContainer,
			scrollBar = PZAPI.UI.ScrollBarVertical{
				x = math.max(0, window.pageWidth - 20), y = 8,
				width = 11, height = math.max(1, window.pageHeight - 16),
			},
		},
	}
	scrollbar = rightClip.children.scrollBar
	textContainer.init = function(self) scrollbar.container = self end
	return PZAPI.UI.Node{
		x = window.leftPageX,
		y = window.pageY,
		width = window.pageWidth * 2 + window.pageGutter,
		height = window.pageHeight,
		documentId = record.id,
		documentZoom = 1,
		fitScale = 1,
		recordId = record.id,
		children = { leftClip = leftClip, rightClip = rightClip },
	}
end

function ArchiveBookControls:new()
	local controls = ISPanel.new(self, 0, 0,
		getCore():getScreenWidth(), getCore():getScreenHeight())
	controls.background = false
	controls.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
	controls.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	controls.moveWithMouse = false
	controls.activeWhilePaused = true
	return controls
end

function ArchiveBookControls:onFocus(x, y)
	ISPanel.onFocus(self, x, y)
	self:bringToTop()
end

function ArchiveBookControls:onKeyPress(key)
	if self.archiveWindow then
		self.archiveWindow:onKeyPress(key)
	end
end

function ArchiveBookControls:prerender()
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()
	if self.width ~= screenWidth then self:setWidth(screenWidth) end
	if self.height ~= screenHeight then self:setHeight(screenHeight) end
end

function ArchiveBookWindow:new(playerNum)
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()
	local window = ISPanel.new(self, 0, 0, screenWidth, screenHeight)
	window.playerNum = playerNum
	window.currentPage = 1
	window.archiveRecords = {}
	window.backgroundColor = { r = 0.03, g = 0.025, b = 0.02, a = 0.72 }
	window.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	window.activeWhilePaused = true
	return window
end

function ArchiveBookWindow:getMaxPage()
	return 5 + #(self.archiveRecords or {})
end

function ArchiveBookWindow:initialise()
	ISPanel.initialise(self)
end

function ArchiveBookWindow:raiseControls()
	if self.controlsLayer and self.controlsLayer:getIsVisible() then
		self.controlsLayer:bringToTop()
	end
end

function ArchiveBookWindow:createChildren()
	self.previousButton = ISButton:new(0, 0, 124, 32,
		"Pagina anterior", self, ArchiveBookWindow.onPreviousPage)
	self.previousButton:initialise()

	self.nextButton = ISButton:new(0, 0, 124, 32,
		"Pagina siguiente", self, ArchiveBookWindow.onNextPage)
	self.nextButton:initialise()

	self.closeButton = ISButton:new(0, 0, 124, 32,
		"Cerrar album", self, ArchiveBookWindow.onClose)
	self.closeButton:initialise()
	for _, button in ipairs({ self.previousButton, self.nextButton,
			self.closeButton }) do
		button.backgroundColor = { r = 0.78, g = 0.68, b = 0.50, a = 1 }
		button.backgroundColorMouseOver = { r = 0.90, g = 0.80, b = 0.62, a = 1 }
		button.textColor = { r = 0.14, g = 0.10, b = 0.06, a = 1 }
		button.borderColor = { r = 0.14, g = 0.10, b = 0.06, a = 1 }
	end
	self:layoutBook()
end

function ArchiveBookWindow:layoutBook()
	local screenWidth = getCore():getScreenWidth()
	local screenHeight = getCore():getScreenHeight()
	self:setWidth(screenWidth)
	self:setHeight(screenHeight)
	local edge = 12
	local availableWidth = math.max(1, screenWidth - edge * 2)
	local availableHeight = math.max(1, screenHeight - edge * 2)
	local scale = math.min(availableWidth / 1000, availableHeight / 700)
	self.bookScale = scale
	self.bookWidth = 1000 * scale
	self.bookHeight = 700 * scale
	self.bookX = (screenWidth - self.bookWidth) / 2
	self.bookY = (screenHeight - self.bookHeight) / 2
	local margin = 34 * scale
	local gutter = 18 * scale
	self.pageY = self.bookY + 50 * scale
	self.pageHeight = self.bookHeight - 140 * scale
	self.pageWidth = (self.bookWidth - margin * 2 - gutter) / 2
	self.leftPageX = self.bookX + margin
	self.rightPageX = self.leftPageX + self.pageWidth + gutter
	self.pageGutter = gutter

	local buttonMargin = 34 * scale
	local buttonGap = 24 * scale
	local buttonWidth = (self.bookWidth - buttonMargin * 2 - buttonGap * 2) / 3
	local buttonHeight = 56 * scale
	local buttonX = self.bookX + buttonMargin
	local buttonY = self.bookY + self.bookHeight - 80 * scale
	for index, button in ipairs({ self.previousButton, self.nextButton,
			self.closeButton }) do
		if button then
			button:setFont(scale < 0.75 and UIFont.Small or UIFont.Medium)
			button:setX(buttonX + (index - 1) * (buttonWidth + buttonGap))
			button:setY(buttonY)
			button:setWidth(buttonWidth)
			button:setHeight(buttonHeight)
		end
	end
	if self.newspaperRenderer then self:layoutNewspaperRenderer() end
	if self.fashionaBelleRenderer then self:layoutFashionaBelleRenderer() end
	if self.archiveRecordRenderer then self:layoutArchiveRecordRenderer() end
end

function ArchiveBookWindow:layoutNewspaperRenderer()
	local renderer = self.newspaperRenderer
	if not renderer then return end

	renderer:setX(self.leftPageX)
	renderer:setY(self.pageY)
	renderer:setWidth(self.pageWidth * 2 + self.pageGutter)
	renderer:setHeight(self.pageHeight)
	local left = renderer.children.leftClip
	local right = renderer.children.rightClip
	left:setWidth(self.pageWidth)
	left:setHeight(self.pageHeight)
	right:setX(self.pageWidth + self.pageGutter)
	right:setWidth(self.pageWidth)
	right:setHeight(self.pageHeight)

	local visual = left.children.composition
	local fit = math.min(self.pageWidth / visual.width,
		self.pageHeight / visual.height)
	renderer.fitScale = fit
	local zoomScale = fit * renderer.documentZoom
	visual:setScaleX(zoomScale)
	visual:setScaleY(zoomScale)
	visual:setX((self.pageWidth - visual.width * zoomScale) / 2)
	visual:setY((self.pageHeight - visual.height * zoomScale) / 2)

	local content = right.children.container
	local scrollBar = right.children.scrollBar
	content:setWidth(math.max(1, self.pageWidth - 34))
	content:setHeight(math.max(1, self.pageHeight - 16))
	content.children.title.javaObj:setAutoWidth(
		(content.width - 20) / content.children.title.scaleX)
	content.children.text.javaObj:setAutoWidth(
		(content.width - 20) / content.children.text.scaleX)
	local titleHeight = content.children.title.javaObj:getTextHeight() *
		content.children.title.scaleY
	content.children.rule:setY(14 + titleHeight + 12)
	content.children.rule:setWidth(math.max(1, content.width - 28))
	content.children.text:setY(14 + titleHeight + 28)
	local textHeight = content.children.text.javaObj:getTextHeight() *
		content.children.text.scaleY
	content:setHeight(content.children.text.y + textHeight + 20)
	scrollBar:setX(math.max(0, self.pageWidth - 20))
	scrollBar:setHeight(math.max(1, self.pageHeight - 16))
	scrollBar.container = content
	scrollBar:setBarSize((self.pageHeight - 16) / content.height)
	scrollBar:updateBar(0)
end

function ArchiveBookWindow:layoutFashionaBelleRenderer()
	local renderer = self.fashionaBelleRenderer
	if not renderer then return end
	renderer:setX(self.leftPageX)
	renderer:setY(self.pageY)
	renderer:setWidth(self.pageWidth * 2 + self.pageGutter)
	renderer:setHeight(self.pageHeight)
	local left = renderer.children.leftClip
	local right = renderer.children.rightClip
	left:setWidth(self.pageWidth)
	left:setHeight(self.pageHeight)
	right:setX(self.pageWidth + self.pageGutter)
	right:setWidth(self.pageWidth)
	right:setHeight(self.pageHeight)
	local visual = left.children.composition
	local fit = math.min(self.pageWidth / visual.width,
		self.pageHeight / visual.height)
	renderer.fitScale = fit
	local zoomScale = fit * renderer.documentZoom
	visual:setScaleX(zoomScale)
	visual:setScaleY(zoomScale)
	visual:setX((self.pageWidth - visual.width * zoomScale) / 2)
	visual:setY((self.pageHeight - visual.height * zoomScale) / 2)
	local content = right.children.container
	local scrollBar = right.children.scrollBar
	content:setWidth(math.max(1, self.pageWidth - 34))
	content:setHeight(math.max(1, self.pageHeight - 16))
	content.children.title.javaObj:setAutoWidth(
		(content.width - 20) / content.children.title.scaleX)
	content.children.text.javaObj:setAutoWidth(
		(content.width - 20) / content.children.text.scaleX)
	local titleHeight = content.children.title.javaObj:getTextHeight() *
		content.children.title.scaleY
	content.children.rule:setY(14 + titleHeight + 12)
	content.children.rule:setWidth(math.max(1, content.width - 28))
	content.children.text:setY(14 + titleHeight + 28)
	local textHeight = content.children.text.javaObj:getTextHeight() *
		content.children.text.scaleY
	local mapButton = content.children.nativeMap
	mapButton:setX(math.max(0, content.width - 42))
	mapButton:setY(content.children.text.y + textHeight + 12)
	content:setHeight(math.max(self.pageHeight - 16, mapButton.y + 38))
	scrollBar:setX(math.max(0, self.pageWidth - 20))
	scrollBar:setHeight(math.max(1, self.pageHeight - 16))
	scrollBar.container = content
	scrollBar:setBarSize((self.pageHeight - 16) / content.height)
	scrollBar:updateBar(0)
end

function ArchiveBookWindow:layoutArchiveRecordRenderer()
	local renderer = self.archiveRecordRenderer
	if not renderer then return end
	renderer:setX(self.leftPageX)
	renderer:setY(self.pageY)
	renderer:setWidth(self.pageWidth * 2 + self.pageGutter)
	renderer:setHeight(self.pageHeight)
	local left = renderer.children.leftClip
	local right = renderer.children.rightClip
	left:setWidth(self.pageWidth)
	left:setHeight(self.pageHeight)
	right:setX(self.pageWidth + self.pageGutter)
	right:setWidth(self.pageWidth)
	right:setHeight(self.pageHeight)
	local visual = left.children.composition
	local fit = math.min(self.pageWidth / visual.width, self.pageHeight / visual.height)
	renderer.fitScale = fit
	local zoomScale = fit * renderer.documentZoom
	visual:setScaleX(zoomScale)
	visual:setScaleY(zoomScale)
	visual:setX((self.pageWidth - visual.width * zoomScale) / 2)
	visual:setY((self.pageHeight - visual.height * zoomScale) / 2)
	local content = right.children.container
	local scrollBar = right.children.scrollBar
	content:setWidth(math.max(1, self.pageWidth - 34))
	content:setHeight(math.max(1, self.pageHeight - 16))
	content.children.title.javaObj:setAutoWidth(
		(content.width - 20) / content.children.title.scaleX)
	content.children.text.javaObj:setAutoWidth(
		(content.width - 20) / content.children.text.scaleX)
	local titleHeight = content.children.title.javaObj:getTextHeight() *
		content.children.title.scaleY
	content.children.rule:setY(14 + titleHeight + 12)
	content.children.rule:setWidth(math.max(1, content.width - 28))
	content.children.text:setY(14 + titleHeight + 28)
	local textHeight = content.children.text.javaObj:getTextHeight() *
		content.children.text.scaleY
	content:setHeight(content.children.text.y + textHeight + 20)
	scrollBar:setX(math.max(0, self.pageWidth - 20))
	scrollBar:setHeight(math.max(1, self.pageHeight - 16))
	scrollBar.container = content
	scrollBar:setBarSize((self.pageHeight - 16) / content.height)
	scrollBar:updateBar(0)
end

function ArchiveBookWindow:showNewspaperRenderer()
	local created = false
	if self.currentPage == 3 and not self.newspaperRenderer then
		self.newspaperRenderer = makeHeraldRenderer(self)
		if self.newspaperRenderer then
			self.newspaperRenderer:instantiate()
			created = true
		end
	end
	if self.newspaperRenderer then
		self:layoutNewspaperRenderer()
		self.newspaperRenderer:setVisible(self.currentPage == 3)
		self.newspaperRenderer:setAlwaysOnTop(self.currentPage == 3)
		if self.currentPage == 3 then
			local renderer = self.newspaperRenderer
			print("[P-002.2 diagnostic] page=3 renderer=" ..
				tostring(renderer.javaObj ~= nil) .. " created=" .. tostring(created) ..
				" visible=" .. tostring(renderer.visible) ..
				" alwaysOnTop=" .. tostring(renderer.alwaysOnTop) ..
				" bounds=" .. tostring(renderer.x) .. "," .. tostring(renderer.y) ..
				" " .. tostring(renderer.width) .. "x" .. tostring(renderer.height) ..
				" clips=" .. tostring(renderer.children.leftClip.width) .. "x" ..
				tostring(renderer.children.leftClip.height) .. "," ..
				tostring(renderer.children.rightClip.width) .. "x" ..
				tostring(renderer.children.rightClip.height))
		end
	end
end

function ArchiveBookWindow:showFashionaBelleRenderer()
	if self.currentPage == 4 and not self.fashionaBelleRenderer then
		self.fashionaBelleRenderer = makeFashionaBelleRenderer(self)
		if self.fashionaBelleRenderer then
			self.fashionaBelleRenderer:instantiate()
		end
	end
	if self.fashionaBelleRenderer then
		self:layoutFashionaBelleRenderer()
		self.fashionaBelleRenderer:setVisible(self.currentPage == 4)
		self.fashionaBelleRenderer:setAlwaysOnTop(self.currentPage == 4)
	end
end

function ArchiveBookWindow:showArchiveRecordRenderer()
	local recordIndex = self.currentPage - 4
	local record = recordIndex >= 1 and self.archiveRecords[recordIndex] or nil
	local renderer = self.archiveRecordRenderer
	if not record then
		if renderer and renderer.javaObj then UIManager.RemoveElement(renderer.javaObj) end
		self.archiveRecordRenderer = nil
		return
	end
	if renderer and renderer.recordId ~= record.id then
		if renderer.javaObj then UIManager.RemoveElement(renderer.javaObj) end
		self.archiveRecordRenderer = nil
		renderer = nil
	end
	if not renderer then
		renderer = makeArchiveRecordRenderer(self, record)
		if not renderer then return end
		self.archiveRecordRenderer = renderer
		renderer:instantiate()
	end
	self:layoutArchiveRecordRenderer()
	renderer:setVisible(true)
	renderer:setAlwaysOnTop(true)
end

function ArchiveBookWindow:showPrintOpenings()
	self:showNewspaperRenderer()
	self:showFashionaBelleRenderer()
	self:showArchiveRecordRenderer()
end

function ArchiveBookWindow:onResolutionChange(oldWidth, oldHeight,
		newWidth, newHeight)
	self:layoutBook()
	self:showPrintOpenings()
end

function ArchiveBookWindow:prerender()
	ISPanel.prerender(self)
	if self.width ~= getCore():getScreenWidth() or
			self.height ~= getCore():getScreenHeight() then
		self:layoutBook()
	end
end

local function drawBookText(panel, text, centreX, y, red, green, blue,
		font)
	local scale = panel.bookScale or 1
	local width = getTextManager():MeasureStringX(font, text) * scale
	panel:drawTextZoomed(text, centreX - width / 2, y, scale,
		red, green, blue, 1, font)
end

local function drawCoverInPage(panel, texturePath, pageX, pageY,
		pageWidth, pageHeight, scale)
	local texture = getTexture(texturePath)
	if not texture then return end
	local inset = 10 * scale
	local availableWidth = math.max(1, pageWidth - inset * 2)
	local availableHeight = math.max(1, pageHeight - inset * 2)
	local textureWidth = texture:getWidth()
	local textureHeight = texture:getHeight()
	if textureWidth <= 0 or textureHeight <= 0 then return end
	local fit = math.min(availableWidth / textureWidth,
		availableHeight / textureHeight)
	local width = textureWidth * fit
	local height = textureHeight * fit
	panel:drawTextureScaled(texture,
		pageX + (pageWidth - width) / 2,
		pageY + (pageHeight - height) / 2,
		width, height, 1, 1, 1, 1)
end


function ArchiveBookWindow:render()
	ISPanel.render(self)
	local scale = self.bookScale or 1
	local pageInset = 12 * scale
	self:drawRect(self.bookX, self.bookY, self.bookWidth, self.bookHeight,
		0.96, 0.19, 0.12, 0.075)
	self:drawRectBorder(self.bookX, self.bookY, self.bookWidth,
		self.bookHeight, 1, 0.62, 0.43, 0.24)
	self:drawRect(self.leftPageX, self.pageY, self.pageWidth,
		self.pageHeight, 1, 0.88, 0.82, 0.68)
	self:drawRect(self.rightPageX, self.pageY, self.pageWidth,
		self.pageHeight, 1, 0.94, 0.89, 0.77)
	self:drawRectBorder(self.leftPageX, self.pageY, self.pageWidth,
		self.pageHeight, 1, 0.55, 0.43, 0.29)
	self:drawRectBorder(self.rightPageX, self.pageY, self.pageWidth,
		self.pageHeight, 1, 0.55, 0.43, 0.29)
	self:drawRect(self.leftPageX + self.pageWidth,
		self.pageY + pageInset, 2 * scale,
		self.pageHeight - pageInset * 2, 0.55, 0.23, 0.15, 0.09)

	local leftCentre = self.leftPageX + self.pageWidth / 2
	local rightCentre = self.rightPageX + self.pageWidth / 2
	local titleY = self.pageY + 48 * scale
	local bodyY = titleY + 66 * scale
	local font = UIFont.Medium
	local smallFont = UIFont.Small
	if self.currentPage == 1 then
		drawCoverInPage(self, FRONT_COVER_TEXTURE, self.rightPageX,
			self.pageY, self.pageWidth, self.pageHeight, scale)
	elseif self.currentPage == 2 then
		drawBookText(self, "ÍNDICE GENERAL", leftCentre, titleY,
			0.28, 0.18, 0.10, font)
		local indexLines = { "Revistas", "Periódicos", "Mapas",
			"Identificaciones" }
		for index, line in ipairs(indexLines) do
			drawBookText(self, line, leftCentre,
				bodyY + (index - 1) * 34 * scale,
				0.35, 0.27, 0.18, smallFont)
		end
		drawBookText(self, "PÁGINA DE PRUEBA", rightCentre, titleY,
			0.28, 0.18, 0.10, font)
		drawBookText(self, "El índice definitivo se integrará", rightCentre,
			bodyY, 0.35, 0.27, 0.18, smallFont)
		drawBookText(self, "en una siguiente iteración.", rightCentre,
			bodyY + 26 * scale, 0.35, 0.27, 0.18, smallFont)
	elseif self.currentPage == self:getMaxPage() then
		drawCoverInPage(self, BACK_COVER_TEXTURE, self.leftPageX,
			self.pageY, self.pageWidth, self.pageHeight, scale)
	end
end
function ArchiveBookWindow:onPreviousPage()
	self.currentPage = math.max(1, self.currentPage - 1)
	self:raiseControls()
	self:showPrintOpenings()
end

function ArchiveBookWindow:onNextPage()
	self.currentPage = math.min(self:getMaxPage(), self.currentPage + 1)
	self:raiseControls()
	self:showPrintOpenings()
end

function ArchiveBookWindow:onClose()
	if self.closed then return end
	self.closed = true
	if self.newspaperRenderer and self.newspaperRenderer.javaObj then
		UIManager.RemoveElement(self.newspaperRenderer.javaObj)
		self.newspaperRenderer = nil
	end
	if self.fashionaBelleRenderer and self.fashionaBelleRenderer.javaObj then
		UIManager.RemoveElement(self.fashionaBelleRenderer.javaObj)
		self.fashionaBelleRenderer = nil
	end
	if self.archiveRecordRenderer and self.archiveRecordRenderer.javaObj then
		UIManager.RemoveElement(self.archiveRecordRenderer.javaObj)
		self.archiveRecordRenderer = nil
	end
	if self.javaObject then
		self.javaObject:setForceCursorVisible(false)
	end
	self:setVisible(false)
	self:removeFromUIManager()
	if self.controlsLayer then
		self.controlsLayer:setVisible(false)
		self.controlsLayer:removeFromUIManager()
	end
	for _, button in ipairs({ self.previousButton, self.nextButton,
			self.closeButton }) do
		if button then
			button:setVisible(false)
		end
	end
	if self.player and self.originalMovementBlock ~= nil then
		call("setBlockMovement", self.player, self.originalMovementBlock)
		self.originalMovementBlock = nil
	end
	if self.originalGameSpeed ~= nil then
		setGameSpeed(self.originalGameSpeed)
		self.originalGameSpeed = nil
	end
end

function ArchiveBookWindow:onKeyPress(key)
	if key == Keyboard.KEY_ESCAPE then
		if GameKeyboard and GameKeyboard.eatKeyPress then
			GameKeyboard.eatKeyPress(key)
		end
		self:onClose()
	end
end

local function openArchiveBookWindow(playerNum)
	local window = ArchiveBookWindow:new(playerNum)
	window.player = getSpecificPlayer(playerNum)
	if window.player then
		if type(syncReadHistory) == "function" then syncReadHistory(window.player) end
		if type(recoverPrintMediaItems) == "function" then
			recoverPrintMediaItems(window.player, call("getInventory", window.player), 0)
		end
		window.archiveRecords = archiveRecordsFor(window.player)
	end
	local mainScreen = MainScreen and MainScreen.instance
	local multiplayerClient = type(isClient) == "function" and isClient()
	local multiplayerServer = type(isServer) == "function" and isServer()
	if mainScreen and mainScreen.inGame and not multiplayerClient and not multiplayerServer
		and type(setGameSpeed) == "function" then
		local speedControls = UIManager and UIManager.getSpeedControls and UIManager.getSpeedControls()
		if speedControls and speedControls.getCurrentGameSpeed then
			window.originalGameSpeed = speedControls:getCurrentGameSpeed()
			setGameSpeed(0)
		end
	end
	if window.player then
		local wasMovementBlocked = call("isBlockMovement", window.player)
		if wasMovementBlocked ~= nil then
			window.originalMovementBlock = wasMovementBlocked
			call("setBlockMovement", window.player, true)
		end
	end
	window:initialise()
	window:setWantMouseEvents(true)
	window:setWantKeyEvents(true)
	window:instantiate()
	window.javaObject:setForceCursorVisible(true)
	window:addToUIManager()
	window:setVisible(true)
	window:bringToTop()
	local controls = ArchiveBookControls:new()
	controls:initialise()
	controls:setWantMouseEvents(true)
	controls:setWantKeyEvents(true)
	controls:instantiate()
	window.controlsLayer = controls
	controls.archiveWindow = window
	for _, button in ipairs({ window.previousButton, window.nextButton,
			window.closeButton }) do
		controls:addChild(button)
		button:setVisible(true)
	end
	controls:addToUIManager()
	controls:setVisible(true)
	controls:bringToTop()
end

function CategoryWindow:new(playerNum, categoryId, records)
	local width, height = 800, 600
	local x = (getCore():getScreenWidth() - width) / 2
	local y = (getCore():getScreenHeight() - height) / 2
	local window = ISPanel.new(self, x, y, width, height)
	window.playerNum = playerNum
	window.categoryId = categoryId
	window.records = records or {}
	window.backgroundColor = { r = 0.08, g = 0.07, b = 0.06, a = 0.96 }
	window.borderColor = { r = 0.75, g = 0.59, b = 0.35, a = 1 }
	window.backgroundTexture = BACKGROUND_TEXTURES[categoryId] or BACKGROUND_TEXTURES.index
	return window
end

function CategoryWindow:initialise()
	ISPanel.initialise(self)
end

function CategoryWindow:render()
	ISPanel.render(self)
	if self.backgroundTexture then
		local texture = getTexture(self.backgroundTexture)
		if texture then
			self:drawTextureScaled(texture, 0, 0, self.width, self.height, 0.3)
		end
	end
end

function CategoryWindow:createChildren()
	local margin = 18
	local categoryLabel = getText("UI_ReadingArchive_" .. (self.categoryId == "index" and "MainIndex" or self.categoryId))

	self.titleLabel = ISLabel:new(margin, 14, 26, categoryLabel, 0.95, 0.82, 0.57, 1, UIFont.Medium, false)
	self.titleLabel:initialise()
	self:addChild(self.titleLabel)

	self.list = ISScrollingListBox:new(margin, 52, self.width - margin * 2, self.height - 116)
	self.list:initialise()
	self.list:instantiate()
	self.list.itemheight = 42
	self.list.font = UIFont.Medium
	self.list.drawBorder = true
	self:addChild(self.list)

	if self.categoryId == "index" then
		for _, cat in ipairs(CATEGORIES) do
			if cat.id ~= "index" then
				self.list:addItem(getText(cat.label), cat)
			end
		end
	else
		for _, record in ipairs(self.records) do
			self.list:addItem(recordTitle(record), record)
		end
	end

	if #self.records == 0 and self.categoryId ~= "index" then
		self.emptyLabel = ISLabel:new(margin + 14, 86, 22, getText("UI_ReadingArchive_Empty"), 0.82, 0.82, 0.82, 1, UIFont.Small, false)
		self.emptyLabel:initialise()
		self:addChild(self.emptyLabel)
	end

	local discovered = #self.records
	if discovered > 0 and self.categoryId ~= "index" then
		local percentage = math.floor((discovered / math.max(discovered, 1)) * 100)
		self.progressLabel = ISLabel:new(margin, self.height - 70, 18, string.format("Coleccionados: %d (%d%%)", discovered, percentage), 0.82, 0.82, 0.82, 1, UIFont.Small, false)
		self.progressLabel:initialise()
		self:addChild(self.progressLabel)
	end

	self.galleryButton = ISButton:new(self.width - 420, self.height - 52, 150, 32, "Ver Galeria Panini", self, CategoryWindow.onViewGallery)
	self.galleryButton:initialise()
	if self.categoryId == "index" then
		self.galleryButton:setVisible(false)
	end
	self:addChild(self.galleryButton)

	self.openButton = ISButton:new(self.width - 252, self.height - 52, 150, 32, getText("UI_ReadingArchive_Open"), self, CategoryWindow.onOpenSelected)
	self.openButton:initialise()
	self:addChild(self.openButton)

	self.closeButton = ISButton:new(self.width - 92, self.height - 52, 74, 32, getText("UI_ReadingArchive_Close"), self, CategoryWindow.onClose)
	self.closeButton:initialise()
	self:addChild(self.closeButton)
end

function CategoryWindow:onOpenSelected()
	local row = self.list and self.list.items and self.list.items[self.list.selected]
	local item = row and row.item
	if not item then return end

	if item.id and item.label then
		openCategoryWindow(self.playerNum, item.id)
	else
		openNativeMedia(item, self.playerNum)
	end
end

function CategoryWindow:onViewGallery()
	if RevealSystem and RevealSystem.openRevealGallery then
		RevealSystem.openRevealGallery(self.playerNum, self.categoryId, self.records)
	end
end

function CategoryWindow:onClose()
	self:setVisible(false)
	self:removeFromUIManager()
end

function openCategoryWindow(playerNum, categoryId)
	local player = getSpecificPlayer(playerNum)
	if not player then return end
	syncReadHistory(player)
	recoverPrintMediaItems(player, call("getInventory", player), 0)

	local archive = getArchive(player)
	local records = {}

	for _, record in pairs(archive and archive.records or {}) do
		if record.infoKey and record.titleKey and record.textKey then
			if categoryId == "index" or getMediaCategory(record) == categoryId then
				table.insert(records, record)
			end
		end
	end

	table.sort(records, function(a, b)
		return string.lower(recordTitle(a)) < string.lower(recordTitle(b))
	end)

	local window = CategoryWindow:new(playerNum, categoryId, records)
	window:initialise()
	window:addToUIManager()
	window:setVisible(true)
	window:bringToTop()
end

local function resolvePreviouslyReadMedia(mediaID)
	if not ResourceLocation or not ResourceLocation.of then return nil end
	local ok, resource = pcall(ResourceLocation.of, tostring(mediaID))
	if not ok or not resource then return nil end

	local candidates = { "Brochure", "Flier" }
	for _, className in ipairs(candidates) do
		local class = _G[className]
		local value = nil
		if class and type(class.get) == "function" then
			local valueOK, resolved = pcall(class.get, resource)
			if valueOK then value = resolved end
		end
		if value then
			local infoKey = call("getTranslationInfoKey", value)
			local titleKey = call("getTranslationKey", value)
			local textKey = call("getTranslationTextKey", value)
			if infoKey and titleKey and textKey then
				return {
					id = tostring(mediaID),
					infoKey = tostring(infoKey),
					titleKey = tostring(titleKey),
					textKey = tostring(textKey),
					itemName = nil,
					fullType = nil,
				}
			end
		end
	end

	if Newspaper then
		local paperNames = {
			"KentuckyHerald",
			"KnoxKnews",
			"LouisvilleSunTimes",
			"NationalDispatch",
		}
		local idLower = string.lower(tostring(mediaID))
		for _, paperName in ipairs(paperNames) do
			local paperResourceOK, paperResource = pcall(ResourceLocation.of, paperName)
			local paper = nil
			if paperResourceOK and type(Newspaper.get) == "function" then
				local paperOK, resolved = pcall(Newspaper.get, paperResource)
				if paperOK then paper = resolved end
			end
			local issues = call("getIssues", paper)
			if issues then
				for i = 0, issues:size() - 1 do
					local issue = tostring(issues:get(i))
					if issue ~= "" and string.find(idLower, string.lower(issue), 1, true) then
						local infoKey = call("getTranslationInfoKey", paper, issue)
						local textKey = call("getTranslationTextKey", paper, issue)
						local titleKey = call("getTitle", paper, issue)
						if infoKey and textKey and titleKey then
							return {
								id = tostring(mediaID),
								infoKey = tostring(infoKey),
								titleKey = tostring(titleKey),
								textKey = tostring(textKey),
								itemName = nil,
								fullType = nil,
							}
						end
					end
				end
			end
		end
	end
	return nil
end

function syncReadHistory(player)
	local archive = getArchive(player)
	local readIDs = call("getReadPrintMedia", player)
	if not archive or not readIDs or not ArrayList then return end
	local ok, list = pcall(ArrayList.new, readIDs)
	if not ok or not list then return end

	for i = 0, list:size() - 1 do
		local mediaID = tostring(list:get(i))
		if not archive.records[mediaID] then
			local record = resolvePreviouslyReadMedia(mediaID)
			if record then
				record.category = getMediaCategory(record)
				archive.records[mediaID] = record
				archive.discovered[mediaID] = true
			end
		end
	end
end

function recoverPrintMediaItems(player, container, depth)
	if not container or depth > 6 then return end
	local items = call("getItems", container)
	if not items or type(items.size) ~= "function" then return end
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		if item and item.hasModData and item:hasModData() then
			local data = item:getModData()
			local media = data and data.printMedia
			if media and media.id then
				storeRecord(player, media, item)
			end
		end
		local nested = call("getInventory", item) or call("getItemContainer", item)
		if nested and nested ~= container then
			recoverPrintMediaItems(player, nested, depth + 1)
		end
	end
end

local function archiveCompletedRead(action)
	local item = action and action.item
	local player = action and action.character
	if not item or not player or not item.hasModData or not item:hasModData() then return end
	local data = item:getModData()
	if data and data.printMedia then storeRecord(player, data.printMedia, item) end
end

local ARCHIVE_ICON_TEXTURE = "media/textures/Item_ChilaSeda_Album_InventoryIcon.png"

local function getSelectedArchive(items)
	local actualItems = ISInventoryPane.getActualUniqueItems(items)
	if #actualItems ~= 1 then return nil end
	local item = actualItems[1]
	if item and item:getFullType() == ITEM_TYPE then return item end
	return nil
end

local function archivePlayerNum(player)
	if type(player) == "number" then return player end
	if player and type(player.getPlayerNum) == "function" then
		return player:getPlayerNum()
	end
	return 0
end

local function setArchiveOption(option, playerNum, item)
	option.name = getText("ContextMenu_ReadingArchive_Open")
	option.target = nil
	option.onSelect = function() openArchiveBookWindow(playerNum) end
	for index = 1, 10 do option["param" .. index] = nil end
	local okManager, manager = pcall(getScriptManager)
	local texture
	if okManager and manager then
		local okBook, book = pcall(manager.FindItem, manager, "Base.Book")
		if okBook and book then
			local okTexture, value = pcall(book.getNormalTexture, book)
			if okTexture then texture = value end
		end
	end
	option.iconTexture = texture
	option.itemForTexture = item
	option.notAvailable = nil
	option.isDisabled = nil
	option.toolTip = nil
	return option
end

local function addArchiveOpenOption(context, playerNum, item)
	local optionText = getText("ContextMenu_ReadingArchive_Open")
	local option
	for _, existing in ipairs(context.options or {}) do
		if existing.name == optionText then
			option = existing
			break
		end
	end
	if not option then
		local previousOption = nil
		local preferredOptions = {
			[getText("ContextMenu_Equip_Secondary")] = true,
			[getText("ContextMenu_Equip_Primary")] = true,
			[getText("ContextMenu_Equip_Two_Hands")] = true,
			[getText("ContextMenu_Recipes")] = true,
			[getText("ContextMenu_Craft")] = true,
		}
		for _, existing in ipairs(context.options or {}) do
			if preferredOptions[existing.name] then previousOption = existing.name end
		end
		if not previousOption and context.options and context.options[1] then
			previousOption = context.options[1].name
		end
		if previousOption and type(context.insertOptionAfter) == "function" then
			option = context:insertOptionAfter(previousOption, optionText, nil,
				function() openArchiveBookWindow(playerNum) end)
		else
			option = context:addOption(optionText, nil,
				function() openArchiveBookWindow(playerNum) end)
		end
	end
	if option then setArchiveOption(option, playerNum, item) end
end

local function isArchiveReadOption(name)
	if name == getText("ContextMenu_ReadingArchive_Open") then return true end
	for _, key in ipairs({
		"ContextMenu_Read",
		"ContextMenu_ReRead",
		"ContextMenu_Look_at_picture",
		"ContextMenu_ReLook_at_picture",
		"ContextMenu_Look_at_pictures",
		"ContextMenu_ReLook_at_pictures",
	}) do
		if name == getText(key) then return true end
	end
	return false
end

-- Keep vanilla literature handling for every other item. For this album only,
-- replace its timed read action at the point where Build 42 creates that option.
if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doLiteratureMenu
	and not ISInventoryPaneContextMenu._ChilaSedaArchiveLiteratureWrapped then
	local originalDoLiteratureMenu = ISInventoryPaneContextMenu.doLiteratureMenu
	ISInventoryPaneContextMenu.doLiteratureMenu = function(context, items, playerNum)
		local item = getSelectedArchive(items)
		if item then
			addArchiveOpenOption(context, playerNum, item)
			return
		end
		return originalDoLiteratureMenu(context, items, playerNum)
	end
	ISInventoryPaneContextMenu._ChilaSedaArchiveLiteratureWrapped = true
end

local function installArchiveReadRedirect()
	local menu = ISInventoryPaneContextMenu
	if not menu then return end
	if type(menu.doLiteratureMenu) == "function"
		and menu._ChilaSedaArchiveDoLiteratureWrapper ~= menu.doLiteratureMenu then
		local original = menu.doLiteratureMenu
		local wrapper = function(context, items, playerNum)
			local item = getSelectedArchive(items)
			if item then
				addArchiveOpenOption(context, playerNum, item)
				return
			end
			return original(context, items, playerNum)
		end
		menu._ChilaSedaArchiveOriginalDoLiteratureMenu = original
		menu._ChilaSedaArchiveDoLiteratureWrapper = wrapper
		menu.doLiteratureMenu = wrapper
	end
	if type(menu.onLiteratureItems) == "function"
		and menu._ChilaSedaArchiveOnLiteratureWrapper ~= menu.onLiteratureItems then
		local original = menu.onLiteratureItems
		local wrapper = function(items, playerNum)
			if getSelectedArchive(items) then
				openArchiveBookWindow(playerNum)
				return
			end
			return original(items, playerNum)
		end
		menu._ChilaSedaArchiveOriginalOnLiteratureItems = original
		menu._ChilaSedaArchiveOnLiteratureWrapper = wrapper
		menu.onLiteratureItems = wrapper
	end
	-- This is the final vanilla step before ISReadABook is queued. Keep this
	-- guard even if another mod restores the vanilla context-menu callback.
	if type(menu.readItem) == "function"
		and menu._ChilaSedaArchiveReadItemWrapper ~= menu.readItem then
		local original = menu.readItem
		local wrapper = function(item, playerNum, ...)
			if item and item:getFullType() == ITEM_TYPE then
				openArchiveBookWindow(playerNum)
				return
			end
			return original(item, playerNum, ...)
		end
		menu._ChilaSedaArchiveOriginalReadItem = original
		menu._ChilaSedaArchiveReadItemWrapper = wrapper
		menu.readItem = wrapper
	end
end

installArchiveReadRedirect()

local function containsArchiveItem(container, depth, visited)
	if not container or depth > 6 or visited[container] then return false end
	visited[container] = true
	local items = call("getItems", container)
	if not items or type(items.size) ~= "function" then return false end
	local okSize, size = pcall(items.size, items)
	if not okSize or type(size) ~= "number" then return false end
	for index = 0, size - 1 do
		local okItem, item = pcall(items.get, items, index)
		if okItem and item then
			if call("getFullType", item) == ITEM_TYPE then return true end
			local nested = call("getInventory", item) or call("getItemContainer", item)
			if nested and containsArchiveItem(nested, depth + 1, visited) then return true end
		end
	end
	return false
end

local function ensureArchiveItem(player)
	if not player then return end
	local archive = getArchive(player)
	if not archive then return end
	local inventory = call("getInventory", player)
	if not inventory then return end
	if containsArchiveItem(inventory, 0, {}) then
		archive.itemGranted = true
		return
	end

	-- The archive's records live in player ModData, so restoring its access item
	-- does not replace or reset those records when the physical item is missing.
	local ok, item = pcall(inventory.AddItem, inventory, ITEM_TYPE)
	if ok and item then archive.itemGranted = true end
end

Events.OnCreatePlayer.Add(function(_, player)
	ensureArchiveItem(player)
end)

Events.OnGameStart.Add(function()
	ensureArchiveItem(type(getPlayer) == "function" and getPlayer() or nil)
	installArchiveReadRedirect()
	require "TimedActions/ISReadABook"
	if not ISReadABook or ISReadABook._ChilaSedaReadingArchiveWrapped then return end
	local originalComplete = ISReadABook.complete
	ISReadABook.complete = function(action, ...)
		local results = { originalComplete(action, ...) }
		archiveCompletedRead(action)
		return unpack(results)
	end
	ISReadABook._ChilaSedaReadingArchiveWrapped = true
end)

Events.OnGameBoot.Add(installArchiveReadRedirect)

Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items)
	installArchiveReadRedirect()
	playerNum = archivePlayerNum(playerNum)
	local actualItems = ISInventoryPane.getActualItems(items)
	if #actualItems ~= 1 or not actualItems[1] then return end
	local item = actualItems[1]
	if item:getFullType() ~= ITEM_TYPE then return end

	for _, existing in ipairs(context.options or {}) do
		if isArchiveReadOption(existing.name) then
			setArchiveOption(existing, playerNum, item)
			if type(context.calcHeight) == "function" then context:calcHeight() end
			if type(context.calcWidth) == "function" and type(context.setWidth) == "function" then
				context:setWidth(context:calcWidth())
			end
			return
		end
	end
	addArchiveOpenOption(context, playerNum, item)
end)

print("[ChilaSeda_AlbumDelSuperviviente] v0.4.0 menu hooks loaded")
