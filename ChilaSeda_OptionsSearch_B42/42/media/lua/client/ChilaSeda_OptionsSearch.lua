require "OptionScreens/MainOptions"
require "ISUI/ISTextEntryBox"
require "ISUI/ISLabel"
require "ISUI/ISButton"

local TAG = "[ChilaSeda_OptionsSearch] "
local FILTER_HEIGHT, FILTER_TOP, FILTER_OFFSET = 24, 5, 34
local FILTER_WIDTH, FILTER_MARGIN = 360, 10

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

local function addText(parts, value)
	if type(value) == "string" and value ~= "" then
		parts[#parts + 1] = value
		if type(getText) == "function" then
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

local function readRows(panel)
	local children = {}
	for _, child in ipairs(panel.children or {}) do
		local y = safeField(child, "y")
		if child ~= panel.vscroll and child ~= panel.hscroll and type(y) == "number" then
			children[#children + 1] = {
				element = child,
				baseY = y,
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
			row = { baseY = childInfo.baseY, children = {}, text = "", category = "" }
			rows[#rows + 1] = row
		end
		row.children[#row.children + 1] = childInfo
		row.text = row.text .. " " .. childInfo.text
	end
	return rows
end

local function setScrollHeight(panel, height)
	local setter = safeField(panel, "setScrollHeight")
	if type(setter) == "function" then pcall(setter, panel, height)
	else pcall(function() panel.scrollHeight = height end) end
end

local function applyFilter(state, queryText)
	local query = normalized(queryText)
	local visibleCount = 0
	for _, row in ipairs(state.rows) do
		local textMatches = matchesQuery(row.text, query)
		if row.category ~= "" and matchesQuery(row.category, query) then textMatches = true end
		local keyMatches = state.keyFilter == ""
		if not keyMatches then
			for _, childInfo in ipairs(row.children) do
				local child = childInfo.element
				local isAssignedKey = safeField(child, "isModBind") == true
					or type(safeField(child, "internal")) == "string"
				local keyName = isAssignedKey and normalized(safeField(child, "title") or "") or ""
				local lastKey = keyName:match("([^%+]+)$") or keyName
				if normalized(lastKey) == normalized(state.keyFilter) then keyMatches = true break end
			end
		end
		for _, childInfo in ipairs(row.children) do
			local visible = childInfo.baseVisible and textMatches and keyMatches
			setChildVisible(childInfo.element, visible)
			if visible then visibleCount = visibleCount + 1 end
		end
	end
	local searching = query ~= "" or state.keyFilter ~= ""
	setChildVisible(state.noResults, searching and visibleCount == 0)
	if not searching then
		for _, row in ipairs(state.rows) do
			for _, childInfo in ipairs(row.children) do setChildY(childInfo.element, childInfo.baseY + FILTER_OFFSET) end
		end
		setScrollHeight(state.panel, state.originalScrollHeight + FILTER_OFFSET)
	end
end

local function translated(key, fallback)
	if type(getTextOrNull) == "function" then
		local ok, value = pcall(getTextOrNull, key)
		if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
	end
	return fallback
end

local function categoryLabels()
	local result = {}
	local data = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.Data
	for _, options in ipairs(data or {}) do
		local label = type(getText) == "function" and getText(options.name) or options.name
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

local function attachSearch(self, panel, pageName, categories, supportsKeyFilter)
	if not panel or panel.chilaSedaOptionsSearch then return end
	panel.chilaSedaOptionsSearch = true
	local rows = readRows(panel)
	local scrollHeight = tonumber(panel.scrollHeight) or tonumber(panel.height) or 0
	applyCategories(rows, categories)

	local entry = ISTextEntryBox:new("", FILTER_MARGIN, FILTER_TOP,
		math.max(120, math.min(FILTER_WIDTH, panel:getWidth() - FILTER_MARGIN * 2)), FILTER_HEIGHT)
	entry:initialise()
	entry:setPlaceholderText(translated("UI_ChilaSeda_OptionsSearch_Placeholder", "Buscar en esta pestana..."))
	entry:setTooltip(translated("UI_ChilaSeda_OptionsSearch_Tooltip",
		"Filtra por nombre, categoria, descripcion, accion o tecla asignada."))
	panel:addChild(entry)

	local noResults = ISLabel:new(FILTER_MARGIN, FILTER_TOP + FILTER_HEIGHT + 4, 18,
		translated("UI_ChilaSeda_OptionsSearch_NoResults", "Sin coincidencias"),
		1, 1, 1, 1, UIFont.Small)
	noResults:initialise()
	noResults:setVisible(false)
	panel:addChild(noResults)

	local keyFilterButton
	if supportsKeyFilter then
		keyFilterButton = ISButton:new(FILTER_MARGIN + FILTER_WIDTH + 8, FILTER_TOP,
			230, FILTER_HEIGHT, translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla"),
			self, MainOptions.onChilaSedaBeginKeyFilter)
		keyFilterButton:initialise()
		panel:addChild(keyFilterButton)
	end

	local state = {
		panel = panel,
		rows = rows,
		noResults = noResults,
		originalScrollHeight = scrollHeight,
		keyFilter = "",
		keyFilterButton = keyFilterButton,
	}
	for _, row in ipairs(rows) do
		for _, childInfo in ipairs(row.children) do setChildY(childInfo.element, childInfo.baseY + FILTER_OFFSET) end
	end
	setScrollHeight(panel, scrollHeight + FILTER_OFFSET)
	entry.onTextChangeFunction = function(_, box) applyFilter(state, box:getText()) end
	panel.chilaSedaOptionsSearchEntry = entry
	panel.chilaSedaOptionsSearchState = state
	if supportsKeyFilter then self.chilaSedaOptionsKeySearchState = state end
	print(TAG .. "search installed on " .. tostring(pageName))
end

function MainOptions:onChilaSedaBeginKeyFilter()
	local state = self.chilaSedaOptionsKeySearchState
	if not state then return end
	self.chilaSedaOptionsKeyCaptureActive = true
	if state.keyFilterButton then
		state.keyFilterButton:setTitle(translated("UI_ChilaSeda_OptionsSearch_KeyWaiting", "Presiona una tecla (Esc borra)"))
	end
end

local originalKeyRelease = MainOptions.onKeyRelease
MainOptions.onKeyRelease = function(self, key, ...)
	if self.chilaSedaOptionsKeyCaptureActive then
		self.chilaSedaOptionsKeyCaptureActive = false
		local state = self.chilaSedaOptionsKeySearchState
		if state then
			state.keyFilter = key == Keyboard.KEY_ESCAPE and "" or (getKeyName(key) or "")
			if state.keyFilterButton then
				local title
				if state.keyFilter == "" then
					title = translated("UI_ChilaSeda_OptionsSearch_KeyFilter", "Filtrar al presionar una tecla")
				else
					title = translated("UI_ChilaSeda_OptionsSearch_KeySelected", "Tecla: %1 (clic para cambiar)")
					title = title:gsub("%%1", state.keyFilter)
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

local function sortedModOptionsData()
	local data = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.Data
	if type(data) ~= "table" then return nil end
	local original = {}
	for index, options in ipairs(data) do original[index] = options end
	table.sort(data, function(a, b)
		local aName = normalized(type(getText) == "function" and getText(a.name) or a.name)
		local bName = normalized(type(getText) == "function" and getText(b.name) or b.name)
		if aName == bName then return tostring(a.modOptionsID or "") < tostring(b.modOptionsID or "") end
		return aName < bName
	end)
	return original
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
			self.chilaSedaOptionsKeySearchState = nil
			local originalData, categories
			if methodName == "addModOptionsPanel" then
				if PZAPI and PZAPI.ModOptions and type(PZAPI.ModOptions.load) == "function" then
					pcall(PZAPI.ModOptions.load, PZAPI.ModOptions)
				end
				originalData = sortedModOptionsData()
				categories = categoryLabels()
			end
			local ok, result = pcall(original, self, ...)
			if originalData then
				local data = PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.Data
				if type(data) == "table" then
					for index = #data, 1, -1 do data[index] = nil end
					for index, options in ipairs(originalData) do data[index] = options end
				end
			end
			if not ok then error(result) end
			local panel = self.chilaSedaOptionsSearchPanel or self.mainPanel
			local supportsKeyFilter = methodName == "addKeybindingPanel" or methodName == "addModOptionsPanel"
			attachSearch(self, panel, self.chilaSedaOptionsSearchPageName or methodName,
				categories, supportsKeyFilter)
			return result
		end
	end
end

print(TAG .. "search enabled on all Options tabs; Mod Options categories are alphabetical")
