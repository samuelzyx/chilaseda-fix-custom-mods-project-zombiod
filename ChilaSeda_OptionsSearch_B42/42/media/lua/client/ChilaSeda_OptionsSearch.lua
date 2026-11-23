require "OptionScreens/MainOptions"
require "ISUI/ISTextEntryBox"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "ISUI/ISPanelJoypad"

local TAG = "[ChilaSeda_OptionsSearch] "
local FILTER_HEIGHT, FILTER_TOP = 24, 5
local FILTER_WIDTH, FILTER_MARGIN = 360, 10
local CLEAR_SEARCH_WIDTH, CLEAR_SEARCH_GAP = 24, 4
local KEY_FILTER_WIDTH, CLEAR_KEY_WIDTH, KEY_FILTER_GAP = 230, 90, 8
local MIN_KEY_FILTER_WIDTH = 180
local NO_RESULTS_HEIGHT, FILTER_CONTENT_GAP = 18, 4

local function filterControlLayout(panelWidth, supportsKeyFilter)
	local availableWidth = math.max(0, panelWidth - FILTER_MARGIN * 2)
	local layout = {
		entryX = FILTER_MARGIN,
		entryY = FILTER_TOP,
		entryWidth = math.max(0, math.min(FILTER_WIDTH,
			availableWidth - CLEAR_SEARCH_WIDTH - CLEAR_SEARCH_GAP)),
		clearSearchX = FILTER_MARGIN + math.max(0, math.min(FILTER_WIDTH,
			availableWidth - CLEAR_SEARCH_WIDTH - CLEAR_SEARCH_GAP)) + CLEAR_SEARCH_GAP,
		clearSearchY = FILTER_TOP,
		buttonX = FILTER_MARGIN,
		buttonY = FILTER_TOP,
		buttonWidth = 0,
		clearButtonX = FILTER_MARGIN,
		clearButtonY = FILTER_TOP,
		clearButtonWidth = 0,
		noResultsY = FILTER_TOP + FILTER_HEIGHT + FILTER_CONTENT_GAP,
	}
	if supportsKeyFilter then
		layout.buttonY = FILTER_TOP + FILTER_HEIGHT + FILTER_CONTENT_GAP
		if availableWidth >= MIN_KEY_FILTER_WIDTH + KEY_FILTER_GAP + CLEAR_KEY_WIDTH then
			layout.buttonWidth = math.min(KEY_FILTER_WIDTH,
				availableWidth - CLEAR_KEY_WIDTH - KEY_FILTER_GAP)
			layout.clearButtonX = layout.buttonX + layout.buttonWidth + KEY_FILTER_GAP
			layout.clearButtonY = layout.buttonY
			layout.clearButtonWidth = CLEAR_KEY_WIDTH
			layout.noResultsY = layout.buttonY + FILTER_HEIGHT + FILTER_CONTENT_GAP
		else
			layout.buttonWidth = availableWidth
			layout.clearButtonY = layout.buttonY + FILTER_HEIGHT + FILTER_CONTENT_GAP
			layout.clearButtonWidth = availableWidth
			layout.noResultsY = layout.clearButtonY + FILTER_HEIGHT + FILTER_CONTENT_GAP
		end
	end
	layout.contentOffset = layout.noResultsY + NO_RESULTS_HEIGHT + FILTER_CONTENT_GAP
	return layout
end

local function safeField(element, field)
	local ok, value = pcall(function() return element[field] end)
	if ok then return value end
	return nil
end

local function normalized(value)
	local text = tostring(value or ""):lower()
	local replacements = {
		["\195\161"] = "a", ["\195\169"] = "e", ["\195\173"] = "i",
		["\195\179"] = "o", ["\195\186"] = "u", ["\195\188"] = "u", ["\195\177"] = "n",
		["\195\129"] = "a", ["\195\137"] = "e", ["\195\141"] = "i",
		["\195\147"] = "o", ["\195\154"] = "u", ["\195\156"] = "u", ["\195\145"] = "n",
	}
	for from, to in pairs(replacements) do text = text:gsub(from, to) end
	return text
end

local TRANSLATION_KEY_PREFIXES = {
	"IGUI_", "UI_", "ContextMenu_", "Tooltip_", "ItemName_", "DisplayName_",
	"Sandbox_", "Recipe_", "Recipes_", "Moodles_", "Farming_", "Challenge_",
	"NewGame_", "Options_", "Option_", "Server_", "Vehicle_", "Radio_",
	"Tutorial_", "SurvivalGuide_", "Character_",
}

local function isTranslationKey(value)
	if type(value) ~= "string" or value:find("%s") or value:find("%", 1, true) then return false end
	for _, prefix in ipairs(TRANSLATION_KEY_PREFIXES) do
		if value:sub(1, #prefix) == prefix and value:match("^[%w_]+$") then return true end
	end
	return false
end

local function addText(parts, value)
	if type(value) == "string" and value ~= "" then
		parts[#parts + 1] = value
		if type(getText) == "function" and isTranslationKey(value) then
			local ok, translated = pcall(getText, value)
			if ok and type(translated) == "string" and translated ~= value then parts[#parts + 1] = translated end
		end
	elseif type(value) == "number" then
		parts[#parts + 1] = tostring(value)
	end
end

local function searchableText(element)
	local parts = {}
	for _, field in ipairs({ "name", "title", "text", "tooltip", "description", "internal", "id", "value", "translation" }) do
		addText(parts, safeField(element, field))
	end
	for _, methodName in ipairs({ "getName", "getText", "getTitle", "getInternalText" }) do
		local method = safeField(element, methodName)
		if type(method) == "function" then
			local ok, value = pcall(method, element)
			if ok then addText(parts, value) end
		end
	end
	local options = safeField(element, "options")
	if type(options) == "table" then
		for _, option in ipairs(options) do
			if type(option) == "table" then
				addText(parts, option.name)
				addText(parts, option.text)
				addText(parts, option.value)
			else
				addText(parts, option)
			end
		end
	end
	return normalized(table.concat(parts, " "))
end

local function matchesQuery(text, query)
	if query == "" then return true end
	for term in query:gmatch("%S+") do
		if not text:find(term, 1, true) then return false end
	end
	return true
end

local function matchesKeyName(value, selectedKey)
	local candidateTokens, queryTokens = {}, {}
	for token in normalized(value):gmatch("[%w_]+") do
		candidateTokens[#candidateTokens + 1] = token
	end
	for token in normalized(selectedKey):gmatch("[%w_]+") do
		queryTokens[#queryTokens + 1] = token
	end
	if #queryTokens == 0 then
		return normalized(value):find(normalized(selectedKey), 1, true) ~= nil
	end
	local candidateIndex = 1
	for _, queryToken in ipairs(queryTokens) do
		while candidateTokens[candidateIndex] and candidateTokens[candidateIndex] ~= queryToken do
			candidateIndex = candidateIndex + 1
		end
		if not candidateTokens[candidateIndex] then return false end
		candidateIndex = candidateIndex + 1
	end
	return true
end

local function setChildVisible(child, visible)
	local setter = safeField(child, "setVisible")
	if type(setter) == "function" then pcall(setter, child, visible)
	else pcall(function() child.visible = visible end) end
end

local function setChildY(child, y)
	local setter = safeField(child, "setY")
	if type(setter) == "function" then pcall(setter, child, y)
	else pcall(function() child.y = y end) end
end

local function elementHeight(element)
	local height = safeField(element, "height")
	if type(height) ~= "number" then
		local getter = safeField(element, "getHeight")
		if type(getter) == "function" then
			local ok, value = pcall(getter, element)
			if ok then height = value end
		end
	end
	return type(height) == "number" and math.max(0, height) or 0
end

local function readRows(panel)
	local children = {}
	local childList = panel:getChildren() or panel.children or {}
	-- ISUIElement stores children under globally assigned IDs, not 1..n array keys.
	for _, child in pairs(childList) do
		local y = safeField(child, "y")
		if child ~= panel.vscroll and child ~= panel.hscroll and type(y) == "number" then
			children[#children + 1] = {
				element = child,
				baseY = y,
				height = elementHeight(child),
				baseVisible = safeField(child, "visible") ~= false,
				text = searchableText(child),
			}
		end
	end
	table.sort(children, function(a, b) return a.baseY < b.baseY end)
	local rows = {}
	for _, childInfo in ipairs(children) do
		local row = rows[#rows]
		if not row or childInfo.baseY - row.baseY > 10 then
			row = { baseY = childInfo.baseY, bottomY = childInfo.baseY,
				children = {}, text = "", category = "" }
			rows[#rows + 1] = row
		end
		row.children[#row.children + 1] = childInfo
		row.text = row.text .. " " .. childInfo.text
		row.bottomY = math.max(row.bottomY, childInfo.baseY + childInfo.height)
	end
	for _, row in ipairs(rows) do row.height = math.max(1, row.bottomY - row.baseY) end
	return rows
end

local function setScrollHeight(panel, height)
	local setter = safeField(panel, "setScrollHeight")
	if type(setter) == "function" then pcall(setter, panel, height)
	else pcall(function() panel.scrollHeight = height end) end
end

local function applyFilter(state, queryText)
	local query = normalized(queryText)
	local visibleRows = 0
	local visibleResultRows = 0
	local compactY = state.searchStartY
	local previousVisibleRow
	local compactBottom = compactY
	local searching = query ~= "" or state.keyFilter ~= ""
	local rowMatches, categoryHasMatches = {}, {}
	for index, row in ipairs(state.rows) do
		local textMatches = matchesQuery(row.text, query)
		if row.category ~= "" and matchesQuery(row.category, query) then textMatches = true end
		local keyMatches = state.keyFilter == ""
		if not keyMatches then
			for _, childInfo in ipairs(row.children) do
				local child = childInfo.element
				local isAssignedKey = safeField(child, "isModBind") == true
					or type(safeField(child, "internal")) == "string"
				if isAssignedKey then
					for _, field in ipairs({ "title", "text", "value", "key" }) do
						local value = safeField(child, field)
						if value ~= nil then
							if matchesKeyName(value, state.keyFilter) then
								keyMatches = true
								break
							end
						if keyMatches then break end
					end
				end
				if keyMatches then break end
			end
		end
		end
		local rowVisible = textMatches and keyMatches
		if rowVisible then
			local hasBaseVisibleChild = false
			for _, childInfo in ipairs(row.children) do
				if childInfo.baseVisible then hasBaseVisibleChild = true; break end
			end
			rowVisible = hasBaseVisibleChild
		end
		rowMatches[index] = rowVisible
		if rowVisible and not row.isCategoryHeader and row.category ~= "" then
			categoryHasMatches[row.category] = true
		end
	end
	for index, row in ipairs(state.rows) do
		local rowVisible = rowMatches[index]
		if row.isCategoryHeader then
			rowVisible = categoryHasMatches[row.category] == true
			if rowVisible then
				local hasBaseVisibleChild = false
				for _, childInfo in ipairs(row.children) do
					if childInfo.baseVisible then hasBaseVisibleChild = true; break end
				end
				rowVisible = hasBaseVisibleChild
			end
		end
		if searching and rowVisible then
			if previousVisibleRow then
				local originalGap = row.baseY - previousVisibleRow.bottomY
				compactY = compactY + math.min(16, math.max(0, originalGap))
			end
			for _, childInfo in ipairs(row.children) do
				local child = childInfo.element
				setChildVisible(child, childInfo.baseVisible)
				setChildY(child, compactY + childInfo.baseY - row.baseY)
			end
			compactBottom = compactY + row.height
			compactY = compactBottom
			previousVisibleRow = row
			visibleRows = visibleRows + 1
			if not row.isCategoryHeader then visibleResultRows = visibleResultRows + 1 end
		elseif searching then
			for _, childInfo in ipairs(row.children) do
				setChildVisible(childInfo.element, false)
			end
		else
			for _, childInfo in ipairs(row.children) do
				setChildVisible(childInfo.element, childInfo.baseVisible)
				setChildY(childInfo.element, childInfo.baseY)
			end
		end
	end
	setChildVisible(state.noResults, searching and visibleResultRows == 0)
	if searching then
		local contentBottom = visibleRows > 0 and compactBottom or 0
		setScrollHeight(state.panel, math.max(state.panel:getHeight(),
			contentBottom + state.bottomPadding))
	else
		setScrollHeight(state.panel, state.originalScrollHeight)
	end
	pcall(function() state.panel:setYScroll(0) end)
end

local function translated(key, fallback, ...)
	if type(getTextOrNull) == "function" then
		local ok, value = pcall(getTextOrNull, key, ...)
		if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
	end
	local args = { ... }
	if fallback and args[1] ~= nil then return (fallback:gsub("%%1", tostring(args[1]))) end
	return fallback
end

local function categoryLabels()
	local result = {}
	local data = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.Data
	for _, options in ipairs(data or {}) do
		local label = options.name
		if type(getText) == "function" and isTranslationKey(options.name) then
			local ok, value = pcall(getText, options.name)
			if ok and type(value) == "string" and value ~= "" then label = value end
		end
		result[#result + 1] = normalized(label)
	end
	return result
end

local function applyCategories(rows, categories)
	if not categories or #categories == 0 then return end
	local activeCategory, categoryIndex = "", 1
	for _, row in ipairs(rows) do
		local candidate = categories[categoryIndex]
		if candidate and row.text:find(candidate, 1, true) then
			activeCategory = candidate
			categoryIndex = categoryIndex + 1
		end
		row.category = activeCategory
	end
end

local function keybindingCategoryLabel(value)
	local rawCategory = type(value) == "string" and value:match("^%[(.-)%]$")
	if not rawCategory then return nil end
	local label = "UI_optionscreen_binding_" .. rawCategory
	if type(getText) == "function" then
		local ok, translated = pcall(getText, label)
		if ok and type(translated) == "string" and translated ~= "" and translated ~= label then
			label = translated
		else
			label = rawCategory
		end
	else
		label = rawCategory
	end
	return normalized(label)
end

local function annotateKeyBindingCategories(rows, entries)
	local rowByElement = {}
	for _, row in ipairs(rows) do
		row.category = ""
		row.isCategoryHeader = false
		for _, childInfo in ipairs(row.children) do
			rowByElement[childInfo.element] = row
		end
	end
	local activeCategory, headerCursor = "", -math.huge
	local headersMapped, bindingsMapped = 0, 0
	for _, entry in ipairs(entries or {}) do
		if type(entry.value) == "string" and entry.value:match("^%[.+%]$") then
			activeCategory = keybindingCategoryLabel(entry.value) or ""
			if activeCategory ~= "" then
				for _, row in ipairs(rows) do
					if not row.isCategoryHeader and row.baseY >= headerCursor
						and row.text:find(activeCategory, 1, true) then
						row.isCategoryHeader = true
						row.category = activeCategory
						headerCursor = row.baseY + 0.001
						headersMapped = headersMapped + 1
						break
					end
				end
			end
		elseif activeCategory ~= "" then
			local row = rowByElement[entry.txt] or rowByElement[entry.btn]
			if row then
				row.category = activeCategory
				bindingsMapped = bindingsMapped + 1
			end
		end
	end
	return headersMapped, bindingsMapped
end

local function refreshSearchOverlays(self, tabs)
	if not self or not tabs or not self.chilaSedaOptionsSearchPageSpecs then return end
	local activePanel = tabs:getActiveView()
	for _, spec in ipairs(self.chilaSedaOptionsSearchPageSpecs) do
		if spec.overlay then spec.overlay:setVisible(spec.panel == activePanel) end
	end
end

local function attachSearch(self, panel, pageName, categories, supportsKeyFilter, keyBindingEntries)
	if not panel or panel.chilaSedaOptionsSearch then return end
	local rows = readRows(panel)
	local originalContentBottom = 0
	for _, row in ipairs(rows) do originalContentBottom = math.max(originalContentBottom, row.bottomY) end
	applyCategories(rows, categories)
	if keyBindingEntries then
		local headersMapped, bindingsMapped = annotateKeyBindingCategories(rows, keyBindingEntries)
		print(TAG .. "keybinding categories mapped headers=" .. tostring(headersMapped)
			.. " bindings=" .. tostring(bindingsMapped))
	end
	local controls = filterControlLayout(panel:getWidth(), supportsKeyFilter)
	if controls.entryWidth <= 0 then return end

	local originalPanelHeight = panel:getHeight()
	local originalPanelY = panel:getY()
	local originalScrollHeight = 0
	local getScrollHeight = safeField(panel, "getScrollHeight")
	if type(getScrollHeight) == "function" then
		local ok, value = pcall(getScrollHeight, panel)
		if ok and type(value) == "number" then originalScrollHeight = value end
	end
	local viewportHeight = math.max(0, originalPanelHeight - controls.contentOffset)
	-- Measure the actual option rows before shrinking the scroll viewport.
	local contentHeight = math.max(viewportHeight, originalContentBottom,
		originalScrollHeight > originalPanelHeight and originalScrollHeight or 0)
	local bottomPadding = math.max(0, contentHeight - originalContentBottom)

	local overlay = ISPanelJoypad:new(panel:getX(), originalPanelY,
		panel:getWidth(), controls.contentOffset)
	overlay:initialise()
	overlay:instantiate()
	overlay:noBackground()
	overlay.borderColor = { r = 0, g = 0, b = 0, a = 0 }
	overlay:setAnchorLeft(true)
	overlay:setAnchorRight(true)
	overlay:setAnchorTop(true)
	overlay:setAnchorBottom(false)
	overlay:setVisible(false)
	self.tabs:addChild(overlay)

	panel:setY(originalPanelY + controls.contentOffset)
	panel:setHeight(viewportHeight)
	setScrollHeight(panel, contentHeight)
	panel.chilaSedaOptionsSearch = true

	local entry = ISTextEntryBox:new("", controls.entryX, controls.entryY,
		controls.entryWidth, FILTER_HEIGHT)
	entry:initialise()
	-- ISTextEntryBox:getText() dereferences its Java UITextBox2. The vanilla
	-- control is not usable until instantiate() creates that object.
	entry:instantiate()
	entry:setPlaceholderText(translated("UI_ChilaSeda_OptionsSearch_Placeholder", "Buscar en esta pestana..."))
	overlay:addChild(entry)
	local clearSearchButton = ISButton:new(controls.clearSearchX, controls.clearSearchY,
		CLEAR_SEARCH_WIDTH, FILTER_HEIGHT, "X", self, MainOptions.onChilaSedaClearTextFilter)
	clearSearchButton:initialise()
	clearSearchButton:instantiate()
	overlay:addChild(clearSearchButton)

	local noResults = ISLabel:new(FILTER_MARGIN, controls.noResultsY, NO_RESULTS_HEIGHT,
		translated("UI_ChilaSeda_OptionsSearch_NoResults", "Sin coincidencias"),
		1, 1, 1, 1, UIFont.Small, true)
	noResults:initialise()
	noResults:setVisible(false)
	overlay:addChild(noResults)

	local keyFilterButton, clearKeyButton
	if supportsKeyFilter then
		keyFilterButton = ISButton:new(controls.buttonX, controls.buttonY,
			controls.buttonWidth, FILTER_HEIGHT, translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla"),
			self, MainOptions.onChilaSedaBeginKeyFilter)
		keyFilterButton:initialise()
		overlay:addChild(keyFilterButton)
		clearKeyButton = ISButton:new(controls.clearButtonX, controls.clearButtonY,
			controls.clearButtonWidth, FILTER_HEIGHT,
			translated("UI_ChilaSeda_OptionsSearch_ClearKey", "Limpiar tecla"),
			self, MainOptions.onChilaSedaClearKeyFilter)
		clearKeyButton:initialise()
		overlay:addChild(clearKeyButton)
	end

	local state = {
		panel = panel,
		overlay = overlay,
		rows = rows,
		noResults = noResults,
		originalScrollHeight = contentHeight,
		searchStartY = rows[1] and rows[1].baseY or 0,
		noResultsY = controls.noResultsY,
		bottomPadding = bottomPadding,
		keyFilter = "",
		keyFilterButton = keyFilterButton,
		clearKeyButton = clearKeyButton,
		clearSearchButton = clearSearchButton,
		lastQuery = entry:getText() or "",
	}
	clearSearchButton.chilaSedaOptionsSearchState = state
	if clearKeyButton then clearKeyButton.chilaSedaOptionsKeySearchState = state end
	local function applyCommittedText()
		if panel.chilaSedaOptionsSearchEntry ~= entry then return end
		local query = entry:getText() or ""
		if query ~= state.lastQuery then
			state.lastQuery = query
			applyFilter(state, query)
		end
	end
	local function deferCommittedText()
		if state.pendingTextRefresh then return end
		state.pendingTextRefresh = true
		local tickEvent = Events and (Events.OnTickEvenPaused or Events.OnTick)
		if tickEvent then
			local function refreshOnTick()
				tickEvent.Remove(refreshOnTick)
				state.pendingTextRefresh = false
				applyCommittedText()
			end
			tickEvent.Add(refreshOnTick)
		else
			state.pendingTextRefresh = false
		end
	end
	entry.onTextChangeFunction = function()
		applyCommittedText()
		deferCommittedText()
	end
	panel.chilaSedaOptionsSearchEntry = entry
	panel.chilaSedaOptionsSearchState = state
	if supportsKeyFilter then keyFilterButton.chilaSedaOptionsKeySearchState = state end
	print(TAG .. "search installed on " .. tostring(pageName))
	return overlay
end

function MainOptions:onChilaSedaClearTextFilter(button)
	local state = button and button.chilaSedaOptionsSearchState
	if not state then return end
	local entry = state.panel.chilaSedaOptionsSearchEntry
	if not entry then return end
	entry:setText("")
	state.lastQuery = ""
	applyFilter(state, "")
end

function MainOptions:onChilaSedaBeginKeyFilter(button)
	local state = button and button.chilaSedaOptionsKeySearchState
	if not state then return end
	self.chilaSedaOptionsKeyCaptureActive = true
	self.chilaSedaOptionsKeyCaptureState = state
	if state.keyFilterButton then
		state.keyFilterButton:setTitle(translated("UI_ChilaSeda_OptionsSearch_KeyWaiting", "Presiona una tecla; Esc tambien se puede filtrar"))
	end
end

function MainOptions:onChilaSedaClearKeyFilter(button)
	local state = button and button.chilaSedaOptionsKeySearchState
	if not state then return end
	self.chilaSedaOptionsKeyCaptureActive = false
	self.chilaSedaOptionsKeyCaptureState = nil
	state.keyFilter = ""
	if state.keyFilterButton then
		state.keyFilterButton:setTitle(translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla"))
	end
	local entry = state.panel.chilaSedaOptionsSearchEntry
	applyFilter(state, entry and entry:getText() or "")
end

local originalKeyRelease = MainOptions.onKeyRelease
MainOptions.onKeyRelease = function(self, key, ...)
	if self.chilaSedaOptionsCapturedKey == key then
		self.chilaSedaOptionsCapturedKey = nil
		self.chilaSedaOptionsKeyCaptureState = nil
		return
	end
	if self.chilaSedaOptionsKeyCaptureActive then
		self.chilaSedaOptionsKeyCaptureActive = false
		local state = self.chilaSedaOptionsKeyCaptureState
		self.chilaSedaOptionsKeyCaptureState = nil
		if state then
			state.keyFilter = getKeyName(key) or tostring(key)
			if state.keyFilterButton then
				local title
				if state.keyFilter == "" then
					title = translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla")
				else
					title = translated("UI_ChilaSeda_OptionsSearch_KeySelected",
						"Tecla: %1 (clic para cambiar)", state.keyFilter)
				end
				state.keyFilterButton:setTitle(title)
			end
			local entry = state.panel.chilaSedaOptionsSearchEntry
			applyFilter(state, entry and entry:getText() or "")
		end
		return
	end
	return originalKeyRelease(self, key, ...)
end

if Events and Events.OnKeyPressed then
	Events.OnKeyPressed.Add(function(key)
		local instance = MainOptions.instance
		if not instance or not instance.chilaSedaOptionsKeyCaptureActive then return end
		instance.chilaSedaOptionsCapturedKey = key
		instance.chilaSedaOptionsKeyCaptureActive = false
		local state = instance.chilaSedaOptionsKeyCaptureState
		if not state then return end
		state.keyFilter = getKeyName(key) or tostring(key)
		if state.keyFilterButton then
			local title
			if state.keyFilter == "" then
				title = translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla")
			else
				title = translated("UI_ChilaSeda_OptionsSearch_KeySelected",
					"Tecla: %1 (clic para cambiar)", state.keyFilter)
			end
			state.keyFilterButton:setTitle(title)
		end
		local entry = state.panel.chilaSedaOptionsSearchEntry
		applyFilter(state, entry and entry:getText() or "")
	end)
end

local originalAddPage = MainOptions.addPage
MainOptions.addPage = function(self, name, ...)
	local panel = originalAddPage(self, name, ...)
	self.chilaSedaOptionsSearchPanel = panel
	self.chilaSedaOptionsSearchPageName = name
	return panel
end

local pageBuilders = {
	"addDisplayPanel", "addUIPanel", "addSoundPanel", "addKeybindingPanel",
	"addAccessibilityPanel", "addControllerPanel", "addMultiplayerPanel", "addModOptionsPanel",
}

for _, methodName in ipairs(pageBuilders) do
	local original = MainOptions[methodName]
	if type(original) == "function" then
		MainOptions[methodName] = function(self, ...)
			self.chilaSedaOptionsSearchPanel = nil
			self.chilaSedaOptionsSearchPageName = nil
			local categories
			if methodName == "addModOptionsPanel" then
				if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
					pcall(PZAPI.ModOptions.load, PZAPI.ModOptions)
				end
				categories = categoryLabels()
			end
			local ok, result = pcall(original, self, ...)
			if not ok then error(result) end
			local panel = self.chilaSedaOptionsSearchPanel or self.mainPanel
			local supportsKeyFilter = methodName == "addKeybindingPanel" or methodName == "addModOptionsPanel"
			local keyBindingEntries
			if methodName == "addKeybindingPanel" then
				keyBindingEntries = {}
				for _, entry in ipairs(MainOptions.keyText or {}) do
					keyBindingEntries[#keyBindingEntries + 1] = entry
				end
			end
			self.chilaSedaOptionsSearchPageSpecs = self.chilaSedaOptionsSearchPageSpecs or {}
			self.chilaSedaOptionsSearchPageSpecs[#self.chilaSedaOptionsSearchPageSpecs + 1] = {
				panel = panel,
				pageName = self.chilaSedaOptionsSearchPageName or methodName,
				categories = categories,
				supportsKeyFilter = supportsKeyFilter,
				keyBindingEntries = keyBindingEntries,
			}
			return result
		end
	end
end

local originalCreate = MainOptions.create
MainOptions.create = function(self, ...)
	self.chilaSedaOptionsSearchPageSpecs = {}
	local result = originalCreate(self, ...)
	-- Vanilla centers several tab contents after building every page. Add our
	-- controls only after that pass so they cannot change the native centering.
	for _, spec in ipairs(self.chilaSedaOptionsSearchPageSpecs) do
		spec.overlay = attachSearch(self, spec.panel, spec.pageName, spec.categories,
			spec.supportsKeyFilter, spec.keyBindingEntries)
	end
	refreshSearchOverlays(self, self.tabs)
	return result
end

local originalTabsActivateView = MainOptions.onTabsActivateView
MainOptions.onTabsActivateView = function(self, tabs, ...)
	local result
	if originalTabsActivateView then result = originalTabsActivateView(self, tabs, ...) end
	refreshSearchOverlays(self, tabs)
	return result
end

print(TAG .. "search enabled on Options tabs; native Mod Options order preserved")
