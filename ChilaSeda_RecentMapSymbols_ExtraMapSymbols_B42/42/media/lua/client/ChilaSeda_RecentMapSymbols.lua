require "ISUI/ISButton"
require "ISUI/ISTextEntryBox"
require "ISUI/ISPanelJoypad"
require "ISUI/Maps/ISWorldMapSymbols"

local MOD_DATA_KEY = "ChilaSeda_RecentMapSymbols"
local MAX_RECENT_SYMBOLS = 20
local MAX_SEARCH_RESULTS = 8
local SEARCH_ZOOM_LEVELS = { 1.0, 1.5, 2.0 }
local SYMBOL_UI_ZOOM_LEVELS = SEARCH_ZOOM_LEVELS
local RECENT_RETRY_INTERVAL_FRAMES = 60
local MAX_RECENT_RETRIES = 20
local RECENT_TAB_LABEL = "IGUI_ChilaSeda_RecentMapSymbols"
local SEARCH_TAB_LABEL = "IGUI_ChilaSeda_SearchMapSymbols"
local UI_BORDER_SPACING = 10
local persistentRecentByPlayer = {}
local applySymbolButtonLayout
local updateSymbolZoomControls
local refreshSearchTab

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

    if applySymbolButtonLayout then applySymbolButtonLayout(symbolsUI) end

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
    backpag="mochila", backpak="mochila", rucksack="mochila", duffel="mochila",
    duffle="mochila", pack="mochila",
    duffelbag="mochila", dufflebag="mochila", rucksacks="mochila",
    packs="mochila", satchel="mochila", satchels="mochila",
    bolsa="mochila", bolso="mochila", mochila="mochila",
    arrow="flecha", arrows="flecha", flecha="flecha", flechas="flecha",
    north="norte", south="sur", east="este", west="oeste",
}
local BACKPACK_SEARCH_PREFIXES = {
    "bag", "bags", "backpack", "backpacks", "backpag", "backpak",
    "rucksack", "rucksacks", "pack", "packs", "duffelbag", "dufflebag",
    "satchel", "satchels",
}
local EXTRA_SYMBOL_INFO = {
    book = { "Libro", "libro manual revista lectura" },
    sledge = { "Mazo", "mazo martillo herramienta romper" },
    pipeWrench = { "Llave grifa", "plomeria fontaneria tuberia herramienta" },
    sheriff = { "Insignia de sheriff", "policia sheriff estrella placa" },
    axe2 = { "Hacha", "hacha herramienta talar madera" },
    medic = { "Botiquin", "medicina medico salud curacion cruz" },
    shirt = { "Camisa", "ropa camiseta vestimenta" },
    helmet = { "Casco", "casco proteccion armadura cabeza" },
    ammo = { "Municion", "balas cartuchos arma disparos" },
    vhs = { "Videocasete", "vhs pelicula cinta video" },
    fuel = { "Combustible", "gasolina diesel carburante gasolinera" },
    fuel2 = { "Tanque de combustible", "gasolina diesel combustible deposito tanque" },
    water = { "Agua", "agua gota beber cantimplora" },
    car = { "Auto", "auto coche carro vehiculo transporte" },
    truck = { "Camion", "camion auto coche vehiculo transporte" },
    helicopter = { "Helicoptero", "helicoptero aeronave avion transporte" },
    parachute = { "Paracaidas", "paracaidas avion caida" },
    marine = { "Mar", "barco bote lancha agua marina" },
    loot = { "Botin", "botin saqueo objetos tesoro" },
    bed = { "Cama", "cama dormir descanso mueble" },
    meet = { "Punto de encuentro", "reunion encuentro grupo personas" },
    school = { "Escuela", "escuela colegio educacion" },
    warehouse = { "Almacen", "almacen bodega deposito industria" },
    cross = { "Cruz", "cruz primeros auxilios medicina" },
    line1 = { "Linea", "linea camino ruta sendero" },
    line2 = { "Linea doble", "linea camino ruta sendero" },
    line3 = { "Linea punteada", "linea camino ruta sendero" },
    line4 = { "Linea", "linea camino ruta sendero" },
    dot = { "Punto", "punto marca ubicacion circulo" },
    x_small = { "Marca pequena", "marca x cruz ubicacion" },
    trashpanda = { "Mapache", "mapache animal fauna basura" },
}
local SYMBOL_SEARCH_TERMS = {
    Apple = "comida alimento fruta manzana",
    Burger = "comida alimento hamburguesa",
    KnifeFork = "comida alimento cubiertos cocina restaurante",
    Fish = "comida alimento pesca pez",
    Egg = "comida alimento gallina huevo",
    Gun = "arma pistola rifle disparo defensa",
    Bullets = "arma balas municion cartuchos",
    CrossedSwords = "arma combate pelea espadas",
    Knife = "arma cuchillo combate",
    Axe = "arma herramienta hacha cortar madera",
    Wrench = "herramienta reparar llave inglesa",
    Hammer = "herramienta reparar martillo",
    Fuel = "combustible gasolina diesel gasolinera",
    Car = "vehiculo auto coche carro transporte",
    Tire = "vehiculo llanta neumatico rueda",
    SteeringWheel = "vehiculo volante manejar conduccion",
    Boat = "vehiculo barco bote lancha transporte",
    Helicopter = "vehiculo avion aeronave transporte",
    House = "edificio casa refugio hogar",
    Door = "edificio puerta entrada salida",
    Bed = "edificio cama dormir descanso",
    Tent = "edificio tienda campamento refugio",
    Skyscraper = "edificio ciudad torre rascacielos",
    Warehouse = "edificio almacen bodega deposito",
    Tree = "naturaleza arbol bosque madera",
    Leaf = "naturaleza hoja planta bosque",
    Flower = "naturaleza flor planta jardin",
    Pawprint = "animal huella rastro",
    Cow = "animal ganado vaca",
    Deer = "animal venado ciervo",
    Rabbit = "animal conejo",
    Chicken = "animal gallina pollo",
    Pig = "animal cerdo puerco",
    Sheep = "animal oveja",
    Bird = "animal pajaro ave",
    Raccoon = "animal mapache fauna",
    Skull = "peligro muerte zombi calavera",
    Radiation = "peligro toxico veneno contaminacion radiacion",
    Bomb = "peligro explosion bomba",
    Trap = "peligro trampa caza",
    Exclamation = "peligro alerta aviso cuidado",
    Question = "pregunta duda interrogacion",
    MedCross = "medicina salud hospital curacion",
    Pill = "medicina salud pastilla farmaco",
    Heart = "medicina salud vida corazon",
    Fire = "peligro fuego incendio fogata",
    Garbage = "basura residuos desperdicios",
    DollarSign = "dinero comercio valor precio",
    Book = "libro lectura manual",
    VHS = "video pelicula videocasete cinta",
    Lock = "cerradura candado llave seguridad",
    Key = "cerradura candado llave seguridad",
    Sun = "clima dia sol luz",
    Moon = "clima noche luna oscuridad",
    Snowflake = "clima frio invierno nieve",
    Waves = "agua mar rio olas inundacion",
    ArrowNorth = "direccion norte arriba",
    ArrowSouth = "direccion sur abajo",
    ArrowEast = "direccion este derecha",
    ArrowWest = "direccion oeste izquierda",
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
        local alias = SEARCH_ALIASES[token]
        if not alias and #token >= 2 then
            for _, prefix in ipairs(BACKPACK_SEARCH_PREFIXES) do
                if prefix:sub(1, #token) == token then
                    alias = "mochila"
                    break
                end
            end
        end
        token = alias or token
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

local function symbolDisplayName(symbolId)
    local baseId = tostring(symbolId or ""):gsub("//alt=.*$", "")
    local extraName = baseId:match("^extra:(.+)$")
    local extraInfo = extraName and EXTRA_SYMBOL_INFO[extraName] or nil
    if extraInfo then return extraInfo[1] end

    local translationKey = "IGUI_Map_Symbol_" .. baseId
    local translatedName = getText(translationKey)
    if translatedName and translatedName ~= translationKey then return translatedName end
    return humanizeSymbolId(baseId)
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
    local baseId = tostring(symbolId):gsub("//alt=.*$", "")
    local extraName = baseId:match("^extra:(.+)$")
    local extraInfo = extraName and EXTRA_SYMBOL_INFO[extraName] or nil
    local name = extraInfo and extraInfo[1] or humanizeSymbolId(baseId)
    local translationKey = "IGUI_Map_Symbol_" .. baseId
    local translatedName = getText(translationKey)
    if extraInfo then name = extraInfo[1]
    elseif translatedName and translatedName ~= translationKey then name = translatedName
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
        extraInfo and extraInfo[2] or "", SYMBOL_SEARCH_TERMS[baseId] or "",
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

refreshSearchTab = function(symbolsUI)
    local view = symbolsUI and symbolsUI.searchSymbolsView
    if not view then return end
    removeSearchButtons(symbolsUI)

    local searchText = view.searchEntry and view.searchEntry:getText() or ""
    local normalizedQuery = normalizeSearch(searchText)
    if normalizedQuery == "" then
        local suggestionRow = {}
        for _, button in ipairs(view.suggestionButtons or {}) do
            suggestionRow[#suggestionRow + 1] = button
            if #suggestionRow == 3 then
                view:insertNewListOfButtons(suggestionRow)
                suggestionRow = {}
            end
        end
        if #suggestionRow > 0 then view:insertNewListOfButtons(suggestionRow) end
    end
    if normalizedQuery == "" then
        view.searchMessage = nil
        if type(view.setScrollHeight) == "function" then
            pcall(view.setScrollHeight, view, view.height)
            if type(view.setYScroll) == "function" then pcall(view.setYScroll, view, 0) end
        end
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

    local searchHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local zoom = SEARCH_ZOOM_LEVELS[symbolsUI.symbolZoomIndex or 1] or 1.0
    local iconSize = math.floor(38 * zoom)
    local isGrid = view.searchLayout == "grid"
    local gap = isGrid and 6 or UI_BORDER_SPACING
    local x = UI_BORDER_SPACING + 1
    local suggestionsHeight = view.lastSearchText == "" and (view.suggestionRows or 0) or 0
    local y = UI_BORDER_SPACING + searchHeight + getTextManager():getFontHeight(UIFont.Small)
        + gap * 2 + suggestionsHeight + 1
    local resultsStartY = y
    local columns = 1
    local cardWidth = math.floor((view.width - UI_BORDER_SPACING * 2 - 2))
    local cardHeight = math.max(46, iconSize + 8)
    if isGrid then
        cardWidth = math.max(32, math.floor(42 * zoom))
        cardHeight = cardWidth
        local availableWidth = math.max(1, view.width - UI_BORDER_SPACING * 2 - 2)
        columns = math.max(1, math.floor((availableWidth + gap) / (cardWidth + gap)))
    end
    local displayLimit = MAX_SEARCH_RESULTS
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
    for index = 1, math.min(matchCount, displayLimit) do
        local match = matches[index]
        local symbolId, displayName = match.id, match.name
        local definition = symbolDefinition(symbolId)
        local texturePath = definition and definition:getTexturePath()
        if texturePath then
            local button = ISButton:new(
                x, y, cardWidth, cardHeight, "", symbolsUI, ISWorldMapSymbols.onButtonClick
            )
            button:initialise()
            button:instantiate()
            button.borderColor = { r = 0, g = 0, b = 0, a = 0 }
            button.backgroundColor = { r = 0.32, g = 0.32, b = 0.32, a = 1 }
            button.textureColor = {
                r = textureColor.r, g = textureColor.g, b = textureColor.b, a = textureColor.a
            }
            button.symbolTexture = getTexture(texturePath)
            button.symbolName = displayName
            button.image = nil
            button.tooltip = displayName
            local originalButtonRender = button.render
            button.render = function(self)
                originalButtonRender(self)
                if self.symbolTexture then
                    local iconSize = math.max(1, math.min(self.height - 8, math.floor(38 * zoom)))
                    local iconX = isGrid and math.floor((self.width - iconSize) / 2) or 4
                    self:drawTextureScaledAspect(self.symbolTexture, iconX,
                        math.floor((self.height - iconSize) / 2), iconSize, iconSize, 1,
                        self.textureColor.r, self.textureColor.g, self.textureColor.b)
                end
                if not isGrid then
                    local labelX = math.min(self.height + 5, math.floor(38 * zoom) + 9)
                    local maxTextWidth = self.width - labelX - 5
                    local label = self.symbolName or ""
                    local textManager = getTextManager()
                    while #label > 3 and textManager:MeasureStringX(UIFont.Small, label) > maxTextWidth do
                        label = label:sub(1, #label - 4) .. "..."
                    end
                    self:drawText(label, labelX,
                        math.floor((self.height - textManager:getFontHeight(UIFont.Small)) / 2),
                        1, 1, 1, 1, UIFont.Small)
                end
            end
            button.tex = symbolId
            button.symbol = true
            button.tab = "SearchSymbols"
            button.enable = symbolsUI:canWrite()
            if not button.enable then
                button.tooltip = displayName .. "\n" .. getText("Tooltip_Map_CantWrite")
            end

            view:addChild(button)
            symbolsUI.buttonList[#symbolsUI.buttonList + 1] = button
            symbolsUI.searchSymbolButtons[#symbolsUI.searchSymbolButtons + 1] = button
            row[#row + 1] = button
            column = column + 1
            if column == columns then
                view:insertNewListOfButtons(row)
                row = {}
                x = UI_BORDER_SPACING + 1
                y = y + cardHeight + gap
                column = 0
            else
                x = x + cardWidth + gap
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
    if type(view.setScrollHeight) == "function" then
        local rows = math.ceil(shown / columns)
        local contentBottom = resultsStartY + rows * (cardHeight + gap) + UI_BORDER_SPACING
        pcall(view.setScrollHeight, view, math.max(view.height, contentBottom))
        if type(view.setYScroll) == "function" then pcall(view.setYScroll, view, 0) end
    else
        print("[ChilaSedaMapSymbolsUI] event=search-layout fallback=no-scroll-height")
    end
    print("[ChilaSedaMapSymbolsUI] event=search-layout mode=" .. tostring(view.searchLayout or "list")
        .. " zoom=" .. tostring(zoom) .. " shown=" .. tostring(shown)
        .. " columns=" .. tostring(columns) .. " result=ready")
end

local function updateSymbolButtonTooltips(symbolsUI)
    for _, button in ipairs(symbolsUI and symbolsUI.buttonList or {}) do
        if button.symbol then
            local name = button.symbolName or symbolDisplayName(button.tex)
            button.symbolName = name
            if button.enable == false then
                button.tooltip = name .. "\n" .. getText("Tooltip_Map_CantWrite")
            else
                button.tooltip = name
            end
        end
    end
end

local function setSymbolZoom(symbolsUI, index)
    if not symbolsUI then return end
    symbolsUI.symbolZoomIndex = math.max(1, math.min(#SYMBOL_UI_ZOOM_LEVELS, index or 1))
    local percent = math.floor(SYMBOL_UI_ZOOM_LEVELS[symbolsUI.symbolZoomIndex] * 100)
    for _, label in ipairs(symbolsUI.symbolZoomLabels or {}) do
        if label and type(label.setTitle) == "function" then
            pcall(label.setTitle, label, tostring(percent) .. "%")
        end
    end
    if applySymbolButtonLayout then applySymbolButtonLayout(symbolsUI) end
    if refreshSearchTab then refreshSearchTab(symbolsUI) end
    print("[ChilaSedaMapSymbolsUI] event=zoom result=applied percent=" .. tostring(percent))
end

local function pinControlsAtTop(view, controls)
    view.chilaPinnedControls = view.chilaPinnedControls or {}
    for _, control in ipairs(controls or {}) do
        if control then
            control.chilaPinnedY = control.chilaPinnedY or control.y
            view.chilaPinnedControls[#view.chilaPinnedControls + 1] = control
        end
    end
    if view.chilaPinnedPrerender then return end

    local originalPrerender = view.prerender
    view.prerender = function(self, ...)
        if originalPrerender then originalPrerender(self, ...) end
        local scroll = 0
        if type(self.getYScroll) == "function" then
            local ok, value = pcall(self.getYScroll, self)
            if ok and type(value) == "number" then scroll = value end
        end
        for _, control in ipairs(self.chilaPinnedControls or {}) do
            if control and type(control.setY) == "function" then
                pcall(control.setY, control, control.chilaPinnedY - scroll)
            end
        end
    end
    view.chilaPinnedPrerender = true
end

local function addSymbolZoomToolbar(symbolsUI, view)
    if view.symbolZoomControls then return view.symbolZoomControls end
    local height = getTextManager():getFontHeight(UIFont.Small) + 6
    local minusWidth, labelWidth, plusWidth, gap = 22, 38, 22, 4
    local totalWidth = minusWidth + labelWidth + plusWidth + gap * 2
    local x = math.max(UI_BORDER_SPACING + 1, view.width - UI_BORDER_SPACING - totalWidth)
    local y = UI_BORDER_SPACING + 1
    local minus = ISButton:new(x, y, minusWidth, height, "-", view, function()
        setSymbolZoom(symbolsUI, (symbolsUI.symbolZoomIndex or 1) - 1)
    end)
    minus:initialise()
    minus:instantiate()
    minus.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomOutHint")
    view:addChild(minus)

    local label = ISButton:new(x + minusWidth + gap, y, labelWidth, height, "100%", view, function()
        setSymbolZoom(symbolsUI, 1)
    end)
    label:initialise()
    label:instantiate()
    label.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomResetHint")
    view:addChild(label)

    local plus = ISButton:new(x + minusWidth + gap + labelWidth + gap, y,
        plusWidth, height, "+", view, function()
            setSymbolZoom(symbolsUI, (symbolsUI.symbolZoomIndex or 1) + 1)
        end)
    plus:initialise()
    plus:instantiate()
    plus.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomHint")
    view:addChild(plus)

    view.symbolZoomControls = { minus = minus, label = label, plus = plus }
    pinControlsAtTop(view, { minus, label, plus })
    symbolsUI.symbolZoomLabels = symbolsUI.symbolZoomLabels or {}
    symbolsUI.symbolZoomLabels[#symbolsUI.symbolZoomLabels + 1] = label
    return view.symbolZoomControls
end

applySymbolButtonLayout = function(symbolsUI)
    if not symbolsUI or not symbolsUI.panel then return end
    local buttonsByView = {}
    for _, button in ipairs(symbolsUI.buttonList or {}) do
        local view = button.parent
        if button.symbol and button.tab ~= "SearchSymbols" and view and view.ID then
            buttonsByView[view] = buttonsByView[view] or {}
            buttonsByView[view][#buttonsByView[view] + 1] = button
        end
    end

    for view, buttons in pairs(buttonsByView) do
        local ok, errorMessage = pcall(function()
            local controls = addSymbolZoomToolbar(symbolsUI, view)
            local baseSize = getTextManager():getFontHeight(UIFont.Small) + 6
            local zoom = SYMBOL_UI_ZOOM_LEVELS[symbolsUI.symbolZoomIndex or 1] or 1.0
            local cellSize = math.max(baseSize, math.floor(baseSize * zoom))
            local gap = UI_BORDER_SPACING
            local left = UI_BORDER_SPACING + 1
            local availableWidth = math.max(1, view.width - UI_BORDER_SPACING * 2 - 2)
            local columns = math.max(1, math.min(8, math.floor((availableWidth + gap) / (cellSize + gap))))
            local y = UI_BORDER_SPACING + baseSize + gap + 1
            local x = left
            local column = 0
            local row = {}
            local rows = {}
            for _, button in ipairs(buttons) do
                button:setX(x)
                button:setY(y)
                button:setWidth(cellSize)
                button:setHeight(cellSize)
                button.forcedWidthImage = math.max(1, cellSize - 2)
                button.forcedHeightImage = math.max(1, cellSize - 2)
                button.symbolName = button.symbolName or symbolDisplayName(button.tex)
                if button.enable == false then
                    button.tooltip = button.symbolName .. "\n" .. getText("Tooltip_Map_CantWrite")
                else
                    button.tooltip = button.symbolName
                end
                row[#row + 1] = button
                column = column + 1
                if column == columns then
                    rows[#rows + 1] = row
                    row = {}
                    column = 0
                    x = left
                    y = y + cellSize + gap
                else
                    x = x + cellSize + gap
                end
            end
            if #row > 0 then rows[#rows + 1] = row end

            view:clearJoypadButtonsList()
            view:insertNewListOfButtons({ controls.minus, controls.label, controls.plus })
            for _, buttonRow in ipairs(rows) do view:insertNewListOfButtons(buttonRow) end
            local contentBottom = y + (column > 0 and cellSize or 0) + UI_BORDER_SPACING
            if type(view.setScrollHeight) ~= "function" then
                error("scroll height is unavailable")
            end
            view:setScrollHeight(math.max(view.height, contentBottom))
            if type(view.setYScroll) == "function" then view:setYScroll(0) end
            print("[ChilaSedaMapSymbolsUI] event=layout tab=" .. tostring(view.ID)
                .. " zoom=" .. tostring(zoom) .. " buttons=" .. tostring(#buttons)
                .. " columns=" .. tostring(columns) .. " result=ready")
        end)
        if not ok then
            print("[ChilaSedaMapSymbolsUI] event=layout tab=" .. tostring(view.ID)
                .. " result=fallback reason=" .. tostring(errorMessage))
        end
    end
end

local SEARCH_SUGGESTIONS = {
    { label = "IGUI_ChilaSeda_MapSuggestionFood", query = "comida" },
    { label = "IGUI_ChilaSeda_MapSuggestionVehicle", query = "vehiculo" },
    { label = "IGUI_ChilaSeda_MapSuggestionHealth", query = "medicina" },
    { label = "IGUI_ChilaSeda_MapSuggestionWeapons", query = "armas" },
    { label = "IGUI_ChilaSeda_MapSuggestionHome", query = "hogar" },
    { label = "IGUI_ChilaSeda_MapSuggestionDanger", query = "peligro" },
    { label = "IGUI_ChilaSeda_MapSuggestionAnimals", query = "animal" },
    { label = "IGUI_ChilaSeda_MapSuggestionNature", query = "naturaleza" },
    { label = "IGUI_ChilaSeda_MapSuggestionSupplies", query = "recursos" },
}

local function refreshSearchSuggestions(symbolsUI)
    local view = symbolsUI.searchSymbolsView
    if not view then return end
    for _, button in ipairs(view.suggestionButtons or {}) do view:removeChild(button) end
    view.suggestionButtons = {}
    local query = view.searchEntry and view.searchEntry:getText() or ""
    if query ~= "" then
        view.suggestionRows = 0
        return
    end

    local columns = 3
    local gap = 4
    local buttonWidth = math.floor((view.width - UI_BORDER_SPACING * 2 - gap * (columns - 1)) / columns)
    local buttonHeight = getTextManager():getFontHeight(UIFont.Small) + 6
    local startY = UI_BORDER_SPACING + view.searchEntry.height + 5
    local row = {}
    for index, suggestion in ipairs(SEARCH_SUGGESTIONS) do
        local column = (index - 1) % columns
        local line = math.floor((index - 1) / columns)
        local suggestionQuery = suggestion.query
        local button = ISButton:new(UI_BORDER_SPACING + 1 + column * (buttonWidth + gap),
            startY + line * (buttonHeight + gap), buttonWidth, buttonHeight,
            getText(suggestion.label), view, function(self)
                view.searchEntry:setText(suggestionQuery)
                view.lastSearchText = suggestionQuery
                refreshSearchSuggestions(symbolsUI)
                refreshSearchTab(symbolsUI)
            end)
        button:initialise()
        button:instantiate()
        button.backgroundColor = { r = 0.28, g = 0.28, b = 0.28, a = 1 }
        button.borderColor = { r = 0.55, g = 0.55, b = 0.55, a = 1 }
        view:addChild(button)
        view.suggestionButtons[#view.suggestionButtons + 1] = button
        row[#row + 1] = button
        if column == columns - 1 or index == #SEARCH_SUGGESTIONS then row = {} end
    end
    view.suggestionRows = math.ceil(#SEARCH_SUGGESTIONS / columns) * (buttonHeight + gap)
end

local pendingSearchRefreshes = setmetatable({}, { __mode = "k" })
local function flushPendingSearchRefreshes()
    for view, symbolsUI in pairs(pendingSearchRefreshes) do
        local entry = view.searchEntry
        if not entry then
            pendingSearchRefreshes[view] = nil
        else
            local query = entry:getText() or ""
            if query ~= view.lastSearchText then
                view.lastSearchText = query
                refreshSearchSuggestions(symbolsUI)
                refreshSearchTab(symbolsUI)
                pendingSearchRefreshes[view] = nil
            else
                -- ISTextEntryBox can raise onTextChange before Java commits the
                -- new text. Retry on the next tick, including while paused.
                local retries = (pendingSearchRefreshes[view] or 0) + 1
                if retries >= 3 then
                    pendingSearchRefreshes[view] = nil
                else
                    pendingSearchRefreshes[view] = retries
                end
            end
        end
    end
end

if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(flushPendingSearchRefreshes)
end
if Events and Events.OnTickEvenPaused and type(Events.OnTickEvenPaused.Add) == "function" then
    Events.OnTickEvenPaused.Add(flushPendingSearchRefreshes)
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

    local zoomButtonWidth = 22
    local zoomLabelWidth = 38
    local zoomOutWidth = 22
    local viewModeButtonWidth = 54
    local zoomY = UI_BORDER_SPACING + 1
    local zoomX = view.width - UI_BORDER_SPACING - zoomOutWidth - zoomLabelWidth
        - zoomButtonWidth - viewModeButtonWidth - 18
    local searchX = UI_BORDER_SPACING + 1
    local clearSearchWidth = 24
    local searchEntryWidth = math.max(1, zoomX - 8 - clearSearchWidth - 4 - searchX)
    local searchEntry = ISTextEntryBox:new("", searchX, zoomY,
        searchEntryWidth, buttonHeight)
    searchEntry:initialise()
    searchEntry:instantiate()
    searchEntry:setPlaceholderText(getText("IGUI_ChilaSeda_SearchMapSymbols"))
    searchEntry.target = symbolsUI
    view.lastSearchText = searchEntry:getText() or ""
    searchEntry.onTextChangeFunction = function()
        pendingSearchRefreshes[view] = 0
    end
    -- Read the committed Java text after each UI input update. This avoids the
    -- one-character delay caused by onTextChange firing before getText changes.
    local originalSearchEntryUpdate = searchEntry.update
    searchEntry.update = function(self, ...)
        if originalSearchEntryUpdate then originalSearchEntryUpdate(self, ...) end
        local query = self:getText() or ""
        if query ~= view.lastSearchText then
            view.lastSearchText = query
            refreshSearchSuggestions(symbolsUI)
            refreshSearchTab(symbolsUI)
        end
    end
    view:addChild(searchEntry)
    view.searchEntry = searchEntry
    view.searchMessage = nil
    local clearSearchButton = ISButton:new(searchX + searchEntryWidth + 4, zoomY,
        clearSearchWidth, buttonHeight, "X", view, function()
            searchEntry:setText("")
            view.lastSearchText = ""
            refreshSearchSuggestions(symbolsUI)
            refreshSearchTab(symbolsUI)
        end)
    clearSearchButton:initialise()
    clearSearchButton:instantiate()
    view:addChild(clearSearchButton)
    view.searchEntryClearButton = clearSearchButton
    symbolsUI.symbolZoomIndex = symbolsUI.symbolZoomIndex or 1
    local zoomLabel
    zoomLabel = ISButton:new(zoomX + zoomOutWidth + 4, zoomY, zoomLabelWidth, buttonHeight, "100%", view,
        function()
            setSymbolZoom(symbolsUI, 1)
        end)
    zoomLabel:initialise()
    zoomLabel:instantiate()
    zoomLabel.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomResetHint")
    view:addChild(zoomLabel)
    symbolsUI.symbolZoomLabels = symbolsUI.symbolZoomLabels or {}
    symbolsUI.symbolZoomLabels[#symbolsUI.symbolZoomLabels + 1] = zoomLabel
    local zoomOutButton = ISButton:new(zoomX, zoomY, zoomOutWidth, buttonHeight, "-", view, function()
        setSymbolZoom(symbolsUI, (symbolsUI.symbolZoomIndex or 1) - 1)
    end)
    zoomOutButton:initialise()
    zoomOutButton:instantiate()
    zoomOutButton.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomOutHint")
    view:addChild(zoomOutButton)
    local zoomButton = ISButton:new(zoomX + zoomOutWidth + 4 + zoomLabelWidth + 4, zoomY,
        zoomButtonWidth, buttonHeight, "+", view, function()
            setSymbolZoom(symbolsUI, (symbolsUI.symbolZoomIndex or 1) + 1)
        end)
    zoomButton:initialise()
    zoomButton:instantiate()
    zoomButton.tooltip = getText("IGUI_ChilaSeda_MapSearchZoomHint")
    view:addChild(zoomButton)
    view.searchLayout = "grid"
    local modeX = zoomX + zoomOutWidth + 4 + zoomLabelWidth + 4 + zoomButtonWidth + 4
    local searchLayoutButton
    searchLayoutButton = ISButton:new(modeX, zoomY, viewModeButtonWidth, buttonHeight,
        getText("IGUI_ChilaSeda_MapSearchList"), view, function()
            view.searchLayout = view.searchLayout == "grid" and "list" or "grid"
            if view.searchLayout == "grid" then
                searchLayoutButton:setTitle(getText("IGUI_ChilaSeda_MapSearchList"))
                searchLayoutButton.tooltip = getText("IGUI_ChilaSeda_MapSearchShowList")
            else
                searchLayoutButton:setTitle(getText("IGUI_ChilaSeda_MapSearchGrid"))
                searchLayoutButton.tooltip = getText("IGUI_ChilaSeda_MapSearchShowGrid")
            end
            refreshSearchTab(symbolsUI)
        end)
    searchLayoutButton:initialise()
    searchLayoutButton:instantiate()
    searchLayoutButton.tooltip = getText("IGUI_ChilaSeda_MapSearchShowList")
    view:addChild(searchLayoutButton)
    view.searchLayoutButton = searchLayoutButton
    pinControlsAtTop(view, { searchEntry, clearSearchButton, zoomOutButton,
        zoomLabel, zoomButton, searchLayoutButton })
    print("[ChilaSedaMapSymbolsUI] event=search-view result=ready mode=grid")
    local originalRender = view.render
    view.render = function(self)
        originalRender(self)
        if self.searchMessage then
            self:drawText(self.searchMessage, UI_BORDER_SPACING + 2,
                UI_BORDER_SPACING + searchEntry.height + UI_BORDER_SPACING + 4,
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
    refreshSearchSuggestions(symbolsUI)
    refreshSearchTab(symbolsUI)
end

local originalCreateChildren = ISWorldMapSymbols.createChildren
ISWorldMapSymbols.createChildren = function(symbolsUI, ...)
    originalCreateChildren(symbolsUI, ...)
    addRecentTab(symbolsUI)
    addSearchTab(symbolsUI)
    applySymbolButtonLayout(symbolsUI)
    updateSymbolButtonTooltips(symbolsUI)
end

local originalCheckInventory = ISWorldMapSymbols.checkInventory
if type(originalCheckInventory) == "function" then
    ISWorldMapSymbols.checkInventory = function(symbolsUI, ...)
        local results = { originalCheckInventory(symbolsUI, ...) }
        updateSymbolButtonTooltips(symbolsUI)
        return unpack(results)
    end
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
