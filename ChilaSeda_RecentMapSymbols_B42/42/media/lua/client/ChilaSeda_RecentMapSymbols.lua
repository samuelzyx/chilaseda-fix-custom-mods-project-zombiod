require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISPanelJoypad"
require "ISUI/Maps/ISWorldMapSymbols"

local MOD_DATA_KEY = "ChilaSeda_RecentMapSymbols"
local MAX_RECENT_SYMBOLS = 20
local MAX_SEARCH_RESULTS = 48
local RECENT_RETRY_INTERVAL_FRAMES = 60
local MAX_RECENT_RETRIES = 20
local RECENT_TAB_LABEL = "IGUI_ChilaSeda_RecentMapSymbols"
local SEARCH_TAB_LABEL = "IGUI_ChilaSeda_SearchMapSymbols"
local UI_BORDER_SPACING = 10
local persistentRecentByPlayer = {}

local function symbolDefinition(symbolId)
    if type(symbolId) ~= "string" then return nil end

    local ok, definition = pcall(function()
        return MapSymbolDefinitions.getInstance():getSymbolById(symbolId)
    end)
    if not ok or not definition then return nil end

    local okTexture, texturePath = pcall(function()
        return definition:getTexturePath()
    end)
    if not okTexture or type(texturePath) ~= "string" or texturePath == "" then
        return nil
    end
    return definition
end

local function characterModData(symbolsUI)
    local character = symbolsUI and symbolsUI.character
    if not character or type(character.getModData) ~= "function" then return nil end

    local ok, data = pcall(character.getModData, character)
    if ok and type(data) == "table" then return data end
    return nil
end

local function persistentFileName(symbolsUI)
    local character = symbolsUI and symbolsUI.character
    local identity
    if character and type(character.getDescriptor) == "function" then
        local ok, descriptor = pcall(character.getDescriptor, character)
        if ok and descriptor and type(descriptor.getID) == "function" then
            local got, value = pcall(descriptor.getID, descriptor)
            if got and value ~= nil then identity = tostring(value) end
        end
    end
    if not identity and character and type(character.getUsername) == "function" then
        local ok, value = pcall(character.getUsername, character)
        if ok and value ~= nil and tostring(value) ~= "" then identity = tostring(value) end
    end
    if not identity then identity = "player" .. tostring(symbolsUI and symbolsUI.playerNum or 0) end
    identity = identity:gsub("[^%w_-]", "_")
    return "ChilaSeda_RecentMapSymbols_" .. identity .. ".txt"
end

local function worldRecentData()
    if not ModData or type(ModData.getOrCreate) ~= "function" then return nil end
    local ok, data = pcall(ModData.getOrCreate, MOD_DATA_KEY)
    if ok and type(data) == "table" then return data end
    return nil
end

local function playerStorageKey(symbolsUI)
    return persistentFileName(symbolsUI):gsub("^ChilaSeda_RecentMapSymbols_", ""):gsub("%.txt$", "")
end

local function readPersistentRecent(symbolsUI)
    local fileName = persistentFileName(symbolsUI)
    local cached = persistentRecentByPlayer[fileName]
    if cached and #cached > 0 then return cached end

    local result = {}
    local seen = {}
    local worldData = worldRecentData()
    local worldStored = worldData and worldData[playerStorageKey(symbolsUI)]
    for _, line in ipairs(type(worldStored) == "table" and worldStored or {}) do
        if type(line) == "string" and line ~= "" and not seen[line] then
            seen[line] = true
            result[#result + 1] = line
            if #result >= MAX_RECENT_SYMBOLS then break end
        end
    end
    if type(getFileReader) == "function" then
        local ok, reader = pcall(getFileReader, fileName, false)
        if ok and reader then
            while true do
                local readOk, line = pcall(reader.readLine, reader)
                if not readOk or line == nil then break end
                if type(line) == "string" and line ~= "" and not seen[line] then
                    seen[line] = true
                    result[#result + 1] = line
                    if #result >= MAX_RECENT_SYMBOLS then break end
                end
            end
            pcall(reader.close, reader)
        end
    end
    -- Do not cache an empty read: the map panel can be constructed before
    -- character/world ModData or the Lua file becomes available after loading.
    if #result > 0 then persistentRecentByPlayer[fileName] = result end
    return result
end

local function writePersistentRecent(symbolsUI, symbols)
    local fileName = persistentFileName(symbolsUI)
    persistentRecentByPlayer[fileName] = symbols
    local worldData = worldRecentData()
    if worldData then
        local copy = {}
        for index, symbolId in ipairs(symbols) do copy[index] = symbolId end
        worldData[playerStorageKey(symbolsUI)] = copy
        if ModData and type(ModData.transmit) == "function" then
            pcall(ModData.transmit, MOD_DATA_KEY)
        end
    end
    if type(getFileWriter) ~= "function" then return worldData ~= nil end

    local ok, writer = pcall(getFileWriter, fileName, true, false)
    if not ok or not writer then return false end
    for _, symbolId in ipairs(symbols) do
        local writeOk = pcall(writer.write, writer, symbolId .. "\n")
        if not writeOk then
            pcall(writer.close, writer)
            return false
        end
    end
    pcall(writer.close, writer)
    return true
end

local function getRecentSymbols(symbolsUI)
    local modData = characterModData(symbolsUI)
    local stored = modData and modData[MOD_DATA_KEY]
    local result = {}
    local seen = {}

    local function append(source)
        for _, symbolId in ipairs(source or {}) do
            if type(symbolId) == "string" and symbolId ~= "" and not seen[symbolId] then
                seen[symbolId] = true
                result[#result + 1] = symbolId
                if #result >= MAX_RECENT_SYMBOLS then return false end
            end
        end
        return true
    end

    if type(stored) == "table" then append(stored) end
    local fromFile = readPersistentRecent(symbolsUI)
    if #result < MAX_RECENT_SYMBOLS then append(fromFile) end
    if modData then modData[MOD_DATA_KEY] = result end
    if #fromFile == 0 and #result > 0 then writePersistentRecent(symbolsUI, result) end
    return result
end

local function recordRecentSymbol(symbolsUI, symbolId)
    if not symbolDefinition(symbolId) then return false end

    local updated = { symbolId }
    for _, existingId in ipairs(getRecentSymbols(symbolsUI)) do
        if existingId ~= symbolId and #updated < MAX_RECENT_SYMBOLS then
            updated[#updated + 1] = existingId
        end
    end

    local modData = characterModData(symbolsUI)
    if modData then modData[MOD_DATA_KEY] = updated end
    writePersistentRecent(symbolsUI, updated)
    return true
end

local function removeRecentButtons(symbolsUI)
    local view = symbolsUI.recentSymbolsView
    for _, button in ipairs(symbolsUI.recentSymbolButtons or {}) do
        if view then view:removeChild(button) end
        for index = #symbolsUI.buttonList, 1, -1 do
            if symbolsUI.buttonList[index] == button then
                table.remove(symbolsUI.buttonList, index)
            end
        end
    end

    symbolsUI.recentSymbolButtons = {}
    if view then
        view.joypadButtonsY = {}
        view.allJoypadButtons = {}
        view.joypadButtons = {}
        view.joypadIndexY = 1
        view.joypadIndex = 1
    end
end

local function refreshRecentTab(symbolsUI)
    local view = symbolsUI and symbolsUI.recentSymbolsView
    if not view then return end

    removeRecentButtons(symbolsUI)

    local currentColor = symbolsUI.currentColor
    local textureColor = { r = 0, g = 0, b = 0, a = 1 }
    if currentColor then
        local ok, r, g, b = pcall(function()
            return currentColor:getR(), currentColor:getG(), currentColor:getB()
        end)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            textureColor = { r = r, g = g, b = b, a = 1 }
        end
    end

    local buttonHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local buttonPad = UI_BORDER_SPACING
    local columns = 8
    local x = UI_BORDER_SPACING + 1
    local y = UI_BORDER_SPACING + 1
    local column = 0
    local row = {}

    local recentSymbols = getRecentSymbols(symbolsUI)
    local unresolvedDefinitions = 0
    for _, symbolId in ipairs(recentSymbols) do
        local definition = symbolDefinition(symbolId)
        if definition then
            local button = ISButton:new(
                x, y, buttonHeight, buttonHeight, "",
                symbolsUI, ISWorldMapSymbols.onButtonClick
            )
            button:initialise()
            button:instantiate()
            button.borderColor = { r = 0, g = 0, b = 0, a = 0 }
            button.backgroundColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
            button.textureColor = {
                r = textureColor.r, g = textureColor.g, b = textureColor.b, a = textureColor.a
            }
            button.image = getTexture(definition:getTexturePath())
            button.tex = symbolId
            button.symbol = true
            button.tab = "RecentSymbols"
            button.enable = symbolsUI:canWrite()
            if not button.enable then
                button.tooltip = getText("Tooltip_Map_CantWrite")
            end

            view:addChild(button)
            symbolsUI.buttonList[#symbolsUI.buttonList + 1] = button
            symbolsUI.recentSymbolButtons[#symbolsUI.recentSymbolButtons + 1] = button
            row[#row + 1] = button

            column = column + 1
            if column == columns then
                view:insertNewListOfButtons(row)
                row = {}
                x = UI_BORDER_SPACING + 1
                y = y + buttonHeight + buttonPad
                column = 0
            else
                x = x + buttonHeight + buttonPad
            end
        else
            unresolvedDefinitions = unresolvedDefinitions + 1
        end
    end

    if #row > 0 then view:insertNewListOfButtons(row) end

    local rowCount = #view.joypadButtonsY
    if rowCount > 0 then
        view.joypadIndexY = math.max(1, math.floor(rowCount / 2))
        view.joypadButtons = view.joypadButtonsY[view.joypadIndexY]
        view.joypadIndex = math.max(1, math.ceil(#view.joypadButtons / 2))
    end

    local retryCount = view.chilaSedaRecentRetryCount or 0
    view.chilaSedaRecentNeedsRefresh = (#recentSymbols == 0 or unresolvedDefinitions > 0)
        and retryCount < MAX_RECENT_RETRIES
end

local function addRecentTab(symbolsUI)
    if symbolsUI.recentSymbolsView or not symbolsUI.panel then return end

    local panel = symbolsUI.panel
    local buttonHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local view = ISPanelJoypad:new(
        0, 0, panel.width, panel.height - buttonHeight
    )
    view.onGainJoypadFocus = function(self, joypadData)
        ISPanelJoypad.onGainJoypadFocus(self, joypadData)
        self:restoreJoypadFocus(joypadData)
    end
    view.onLoseJoypadFocus = function(self, joypadData)
        ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
        self:clearJoypadFocus(joypadData)
    end
    view.onJoypadDown = function(self, button, joypadData)
        if button == Joypad.BButton then
            setJoypadFocus(joypadData.player, self.parent.parent)
            return
        end
        if button == Joypad.LBumper or button == Joypad.RBumper then
            self.parent:onJoypadDown(button, joypadData)
            return
        end
        ISPanelJoypad.onJoypadDown(self, button, joypadData)
    end
    view:initialise()

    panel:addView(getText(RECENT_TAB_LABEL), view)
    local recentViewObject = table.remove(panel.viewList)
    table.insert(panel.viewList, 1, recentViewObject)

    panel.maxLength = 0
    for index, viewObject in ipairs(panel.viewList) do
        viewObject.id = index
        panel.maxLength = math.max(panel.maxLength, viewObject.tabWidth)
    end

    if panel.activeView and panel.activeView.view then
        panel.activeView.view:setVisible(false)
    end
    panel.activeView = recentViewObject
    recentViewObject.view:setVisible(true)
    panel.scrollX = 0
    panel.smoothScrollX = 0
    panel:ensureVisible(1)

    symbolsUI.recentSymbolsView = view
    view.ID = "RecentSymbols"
    symbolsUI.recentSymbolButtons = {}
    refreshRecentTab(symbolsUI)

    local originalPrerender = view.prerender
    view.prerender = function(self, ...)
        if self.chilaSedaRecentNeedsRefresh then
            self.chilaSedaRecentRetryFrames = (self.chilaSedaRecentRetryFrames or 0) + 1
            if self.chilaSedaRecentRetryFrames >= RECENT_RETRY_INTERVAL_FRAMES then
                self.chilaSedaRecentRetryFrames = 0
                self.chilaSedaRecentRetryCount = (self.chilaSedaRecentRetryCount or 0) + 1
                refreshRecentTab(symbolsUI)
            end
        end
        if originalPrerender then return originalPrerender(self, ...) end
    end

    local function refreshAfterActivation(panel)
        if panel.activeView and panel.activeView.view == symbolsUI.recentSymbolsView then
            view.chilaSedaRecentRetryCount = 0
            view.chilaSedaRecentRetryFrames = 0
            refreshRecentTab(symbolsUI)
        end
    end
    if not panel.chilaSedaRecentActivationRefreshInstalled then
        panel.chilaSedaRecentActivationRefreshInstalled = true
        local originalActivateView = panel.activateView
        if type(originalActivateView) == "function" then
            panel.activateView = function(self, ...)
                local results = { originalActivateView(self, ...) }
                refreshAfterActivation(self)
                return unpack(results)
            end
        end
        local originalActivateViewById = panel.activateViewById
        if type(originalActivateViewById) == "function" then
            panel.activateViewById = function(self, ...)
                local results = { originalActivateViewById(self, ...) }
                refreshAfterActivation(self)
                return unpack(results)
            end
        end
    end
end

local ACCENTS = {
    ["á"]="a", ["é"]="e", ["í"]="i", ["ó"]="o", ["ú"]="u", ["ü"]="u", ["ñ"]="n",
    ["Á"]="a", ["É"]="e", ["Í"]="i", ["Ó"]="o", ["Ú"]="u", ["Ü"]="u", ["Ñ"]="n",
}
local SEARCH_ALIASES = {
    bag="mochila", bags="mochila", backpack="mochila", backpacks="mochila",
    backpag="mochila", backpak="mochila", rucksack="mochila", pack="mochila",
    bolsa="mochila", bolso="mochila", mochila="mochila",
    arrow="flecha", arrows="flecha", flecha="flecha", flechas="flecha",
    north="norte", south="sur", east="este", west="oeste",
}
local SEARCH_STOP_WORDS = { de=true, del=true, la=true, las=true, el=true, los=true, un=true, una=true, the=true, of=true, ["and"]=true }

local function foldSearchText(value)
    local text = tostring(value or "")
    for source, replacement in pairs(ACCENTS) do text = text:gsub(source, replacement) end
    return string.lower(text)
end

local function searchTokens(value)
    local result = {}
    for token in foldSearchText(value):gmatch("[%w]+") do
        token = SEARCH_ALIASES[token] or token
        if #token > 0 and not SEARCH_STOP_WORDS[token] then result[#result + 1] = token end
    end
    return result
end

local function normalizeSearch(value)
    return table.concat(searchTokens(value), " ")
end

local function humanizeSymbolId(symbolId)
    local value = tostring(symbolId or "")
    value = value:gsub("([a-z])([A-Z])", "%1 %2")
    value = value:gsub("[_%-]+", " ")
    return value
end

local function symbolSearchMatches(symbolId, searchText)
    local query = searchTokens(searchText)
    if #query == 0 then return false end
    local definition = symbolDefinition(symbolId)
    if not definition then return false end

    local tab, texturePath
    pcall(function()
        tab = definition:getTab()
        texturePath = definition:getTexturePath()
    end)
    local name = humanizeSymbolId(symbolId)
    local translationKey = "IGUI_Map_Symbol_" .. tostring(symbolId)
    local translatedName = getText(translationKey)
    if translatedName and translatedName ~= translationKey then name = translatedName
    else
        local tokens = {}
        for token in name:gmatch("[^%s]+") do
            local folded = foldSearchText(token)
            local spanish = {
                arrow="Flecha", north="Norte", south="Sur", east="Este", west="Oeste",
                bag="Mochila", backpack="Mochila", garbage="Basura",
                house="Casa", tree="Árbol", fish="Pez", fire="Fuego", food="Comida",
                heart="Corazón", star="Estrella", skull="Calavera", tent="Tienda de campaña",
            }
            tokens[#tokens + 1] = spanish[folded] or token
        end
        name = table.concat(tokens, " ")
    end
    local translatedTab = tab and getText("IGUI_Map_Tab" .. tostring(tab)) or ""
    local fields = table.concat({
        tostring(symbolId), name, tostring(texturePath or ""), tostring(tab or ""),
        tostring(translatedName or ""), tostring(translatedTab or ""),
    }, " ")
    local candidates = {}
    for token in foldSearchText(fields):gmatch("[%w]+") do
        token = SEARCH_ALIASES[token] or token
        candidates[token] = true
    end
    local score = 0
    for _, token in ipairs(query) do
        local bestMatch = 0
        for candidate in pairs(candidates) do
            if candidate == token then
                bestMatch = math.max(bestMatch, 60)
            elseif candidate:sub(1, #token) == token then
                bestMatch = math.max(bestMatch, 35)
            elseif candidate:find(token, 1, true) then
                bestMatch = math.max(bestMatch, 20)
            elseif #token >= 4 and token:find(candidate, 1, true) then
                bestMatch = math.max(bestMatch, 8)
            end
        end
        if bestMatch == 0 then return false, name, 0 end
        score = score + bestMatch
    end
    return true, name, score
end

local function removeSearchButtons(symbolsUI)
    local view = symbolsUI.searchSymbolsView
    for _, button in ipairs(symbolsUI.searchSymbolButtons or {}) do
        if view then view:removeChild(button) end
        for index = #symbolsUI.buttonList, 1, -1 do
            if symbolsUI.buttonList[index] == button then
                table.remove(symbolsUI.buttonList, index)
            end
        end
    end

    symbolsUI.searchSymbolButtons = {}
    if view then
        view.joypadButtonsY = {}
        view.allJoypadButtons = {}
        view.joypadButtons = {}
        view.joypadIndexY = 1
        view.joypadIndex = 1
    end
end

local function refreshSearchTab(symbolsUI)
    local view = symbolsUI and symbolsUI.searchSymbolsView
    if not view then return end
    removeSearchButtons(symbolsUI)

    local searchText = view.searchEntry and view.searchEntry:getText() or ""
    local normalizedQuery = normalizeSearch(searchText)
    if normalizedQuery == "" then
        view.searchMessage = getText("IGUI_ChilaSeda_SearchMapSymbolsHint")
        return
    end

    local currentColor = symbolsUI.currentColor
    local textureColor = { r = 0, g = 0, b = 0, a = 1 }
    if currentColor then
        local ok, r, g, b = pcall(function()
            return currentColor:getR(), currentColor:getG(), currentColor:getB()
        end)
        if ok and type(r) == "number" and type(g) == "number" and type(b) == "number" then
            textureColor = { r = r, g = g, b = b, a = 1 }
        end
    end

    local buttonHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local x = UI_BORDER_SPACING + 1
    local y = UI_BORDER_SPACING + buttonHeight + UI_BORDER_SPACING + 1
    local columns = 8
    local column = 0
    local row = {}
    local matches = {}
    for _, symbolId in ipairs(symbolsUI.symbolList or {}) do
        local matched, displayName, score = symbolSearchMatches(symbolId, searchText)
        if matched then matches[#matches + 1] = { id = symbolId, name = displayName, score = score } end
    end
    table.sort(matches, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    local matchCount = #matches
    for index = 1, math.min(matchCount, MAX_SEARCH_RESULTS) do
        local match = matches[index]
        local symbolId, displayName = match.id, match.name
        local definition = symbolDefinition(symbolId)
        local texturePath = definition and definition:getTexturePath()
        if texturePath then
                    local button = ISButton:new(
                        x, y, buttonHeight, buttonHeight, "",
                        symbolsUI, ISWorldMapSymbols.onButtonClick
                    )
                    button:initialise()
                    button:instantiate()
                    button.borderColor = { r = 0, g = 0, b = 0, a = 0 }
                    button.backgroundColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 }
                    button.textureColor = {
                        r = textureColor.r, g = textureColor.g, b = textureColor.b, a = textureColor.a
                    }
                    button.image = getTexture(texturePath)
                    button.tex = symbolId
                    button.symbol = true
                    button.tab = "SearchSymbols"
                    button.tooltip = displayName .. " (" .. tostring(symbolId) .. ")"
                    button.enable = symbolsUI:canWrite()
                    if not button.enable then button.tooltip = getText("Tooltip_Map_CantWrite") end

                    view:addChild(button)
                    symbolsUI.buttonList[#symbolsUI.buttonList + 1] = button
                    symbolsUI.searchSymbolButtons[#symbolsUI.searchSymbolButtons + 1] = button
                    row[#row + 1] = button
                    column = column + 1
                    if column == columns then
                        view:insertNewListOfButtons(row)
                        row = {}
                        x = UI_BORDER_SPACING + 1
                        y = y + buttonHeight + UI_BORDER_SPACING
                        column = 0
                    else
                        x = x + buttonHeight + UI_BORDER_SPACING
                    end
        end
    end
    if #row > 0 then view:insertNewListOfButtons(row) end

    local shown = #symbolsUI.searchSymbolButtons
    if matchCount == 0 then
        view.searchMessage = getText("IGUI_ChilaSeda_SearchMapSymbolsNoResults")
    elseif matchCount > shown then
        view.searchMessage = getText("IGUI_ChilaSeda_SearchMapSymbolsLimit")
    else
        view.searchMessage = nil
    end

    local rowCount = #view.joypadButtonsY
    if rowCount > 0 then
        view.joypadIndexY = math.max(1, math.floor(rowCount / 2))
        view.joypadButtons = view.joypadButtonsY[view.joypadIndexY]
        view.joypadIndex = math.max(1, math.ceil(#view.joypadButtons / 2))
    end
end

local function addSearchTab(symbolsUI)
    if symbolsUI.searchSymbolsView or not symbolsUI.panel then return end

    local panel = symbolsUI.panel
    local buttonHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local view = ISPanelJoypad:new(0, 0, panel.width, panel.height - buttonHeight)
    view.ID = "SearchSymbols"
    view.onGainJoypadFocus = function(self, joypadData)
        ISPanelJoypad.onGainJoypadFocus(self, joypadData)
        self:restoreJoypadFocus(joypadData)
    end
    view.onLoseJoypadFocus = function(self, joypadData)
        ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
        self:clearJoypadFocus(joypadData)
    end
    view.onJoypadDown = function(self, button, joypadData)
        if button == Joypad.BButton then
            setJoypadFocus(joypadData.player, self.parent.parent)
            return
        end
        if button == Joypad.LBumper or button == Joypad.RBumper then
            self.parent:onJoypadDown(button, joypadData)
            return
        end
        ISPanelJoypad.onJoypadDown(self, button, joypadData)
    end
    view:initialise()

    local searchEntry = ISTextEntryBox:new("", UI_BORDER_SPACING + 1,
        UI_BORDER_SPACING + 1, view.width - UI_BORDER_SPACING * 2 - 2, buttonHeight)
    searchEntry:initialise()
    searchEntry.target = symbolsUI
    searchEntry.onTextChangeFunction = function(target)
        refreshSearchTab(target)
    end
    searchEntry.tooltip = getText("IGUI_ChilaSeda_SearchMapSymbolsHint")
    view:addChild(searchEntry)
    view.searchEntry = searchEntry
    view.searchMessage = getText("IGUI_ChilaSeda_SearchMapSymbolsHint")
    local originalRender = view.render
    view.render = function(self)
        originalRender(self)
        if self.searchMessage then
            self:drawText(self.searchMessage, UI_BORDER_SPACING + 2,
                UI_BORDER_SPACING + buttonHeight + UI_BORDER_SPACING + 4,
                0.85, 0.85, 0.85, 1, UIFont.Small)
        end
    end

    panel:addView(getText(SEARCH_TAB_LABEL), view)
    local searchViewObject = table.remove(panel.viewList)
    table.insert(panel.viewList, 2, searchViewObject)
    panel.maxLength = 0
    for index, viewObject in ipairs(panel.viewList) do
        viewObject.id = index
        panel.maxLength = math.max(panel.maxLength, viewObject.tabWidth)
    end
    panel.scrollX = 0
    panel.smoothScrollX = 0

    symbolsUI.searchSymbolsView = view
    symbolsUI.searchSymbolButtons = {}
    refreshSearchTab(symbolsUI)
end

local originalCreateChildren = ISWorldMapSymbols.createChildren
ISWorldMapSymbols.createChildren = function(symbolsUI, ...)
    originalCreateChildren(symbolsUI, ...)
    addRecentTab(symbolsUI)
    addSearchTab(symbolsUI)
end

-- Vanilla restores the previous camera when reopening the map. For the normal
-- player-map shortcut, recenter on the current character after that restore;
-- preserve an explicit center supplied by map links or other callers.
local originalShowWorldMap = ISWorldMap.ShowWorldMap
ISWorldMap.ShowWorldMap = function(playerNum, centerX, centerY, zoom, ...)
    local results = { originalShowWorldMap(playerNum, centerX, centerY, zoom, ...) }
    if centerX == nil or centerY == nil then
        local map = ISWorldMap_instance
        local character = map and map.character or getSpecificPlayer(playerNum)
        if map and map.mapAPI and character
                and (not map.isVisible or map:isVisible()) then
            local ok, x, y = pcall(function()
                return character:getX(), character:getY()
            end)
            if ok and type(x) == "number" and type(y) == "number" then
                pcall(map.mapAPI.centerOn, map.mapAPI, x, y)
            end
        end
    end
    return unpack(results)
end

local originalPlaceSymbol = ISWorldMapSymbolTool_AddSymbol.addSymbol
ISWorldMapSymbolTool_AddSymbol.addSymbol = function(tool, x, y, ...)
    local symbolsUI = tool and tool.symbolsUI
    local selectedSymbol = symbolsUI and symbolsUI.selectedSymbol
    local symbolId = selectedSymbol and selectedSymbol.tex

    local result = originalPlaceSymbol(tool, x, y, ...)
    if symbolId and recordRecentSymbol(symbolsUI, symbolId) then
        refreshRecentTab(symbolsUI)
    end
    return result
end
