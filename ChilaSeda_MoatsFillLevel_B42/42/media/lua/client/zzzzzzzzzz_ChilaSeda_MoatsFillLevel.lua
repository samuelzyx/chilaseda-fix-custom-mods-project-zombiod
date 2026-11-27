local TAG = "[ChilaSeda_MoatsFillLevel] "
local TRACE_ENABLED = true
local MAX_TRACE_LINES = 24
local traceLines = 0
local tracedStates = {}
local tracedFallbacks = {}

local function trace(message, key)
    if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
    if key and tracedStates[key] then return end
    if key then tracedStates[key] = true end
    traceLines = traceLines + 1
    if type(print) == "function" then pcall(print, TAG .. message) end
end

local function fallback(reason)
    if tracedFallbacks[reason] then return end
    tracedFallbacks[reason] = true
    trace("status result=fallback reason=" .. tostring(reason))
end

local function safeRead(object, method)
    if not object then return nil end
    local ok, value = pcall(function() return object[method](object) end)
    return ok and value or nil
end

local function isMoatSpriteName(name)
    if type(name) ~= "string" or type(Moats) ~= "table" then return false end
    return name == Moats.WestSprite
        or name == Moats.LongitudeSprite
        or name == Moats.EastSprite
        or name == Moats.SouthSprite
        or name == Moats.LatitudeSprite
        or name == Moats.NorthSprite
end

local function isMoatObject(object)
    local sprite = safeRead(object, "getSprite")
    local name = safeRead(sprite, "getName")
    return isMoatSpriteName(name)
end

local function moatOnSquare(square, worldobjects)
    for _, object in ipairs(worldobjects or {}) do
        if isMoatObject(object) then return object end
    end

    local floor = safeRead(square, "getFloor")
    if isMoatObject(floor) then return floor end

    local objects = safeRead(square, "getObjects")
    local okSize, size = pcall(function() return objects:size() end)
    if okSize and type(size) == "number" then
        for index = 0, size - 1 do
            local okObject, object = pcall(function() return objects:get(index) end)
            if okObject and isMoatObject(object) then return object end
        end
    end
    return nil
end

local function finiteNumber(value)
    local number = tonumber(value)
    if not number or number ~= number or number == math.huge or number == -math.huge then return nil end
    return number
end

local function waterLevel(object)
    local modData = safeRead(object, "getModData")
    local amount = finiteNumber(safeRead(object, "getFluidAmount"))
    if amount == nil and modData then amount = finiteNumber(modData.waterAmount) end

    local capacity = modData and finiteNumber(modData.waterMax) or nil
    if capacity == nil and RainCollectorBarrel then
        capacity = finiteNumber(RainCollectorBarrel.largeWaterMax)
    end
    if amount == nil then return nil, nil, "amount-unavailable" end
    if capacity == nil or capacity <= 0 then return nil, nil, "capacity-unavailable" end

    amount = math.max(0, math.min(amount, capacity))
    return amount, capacity, nil
end

local function integer(value)
    return tostring(math.floor(value + 0.5))
end

local function translated(key, fallbackText)
    if type(getText) == "function" then
        local ok, value = pcall(getText, key)
        if ok and type(value) == "string" and value ~= "" and value ~= key then return value end
    end
    return fallbackText
end

local function makeTooltip(description)
    if not ISToolTip or type(ISToolTip.new) ~= "function" then return nil end
    local ok, tooltip = pcall(function()
        local value = ISToolTip:new()
        value:initialise()
        value:setVisible(false)
        value.description = description
        return value
    end)
    return ok and tooltip or nil
end

local function addFillStatus(context, square, worldobjects)
    local moat = moatOnSquare(square, worldobjects)
    if not moat then return end

    local amount, capacity, reason = waterLevel(moat)
    if reason then
        fallback(reason)
        return
    end

    if not context or type(context.addOption) ~= "function" then
        fallback("context-addOption-unavailable")
        return
    end

    local amountText = integer(amount)
    local capacityText = integer(capacity)
    local missingText = integer(math.max(0, capacity - amount))
    local percentage = math.floor((amount / capacity) * 100 + 0.5)
    local missingLabel = translated("IGUI_ChilaSeda_Moats_FillMissing", "Missing {missing}")
    missingLabel = string.gsub(missingLabel, "{missing}", missingText)
    local label = translated("IGUI_ChilaSeda_Moats_FillLabel", "Trench water")
        .. ": " .. amountText .. " / " .. capacityText .. " (" .. tostring(percentage)
        .. "%; " .. missingLabel .. ")"
    local help = translated("IGUI_ChilaSeda_Moats_FillTooltip",
        "Current water amount compared with the tile's total capacity.")
    local missingHelp = translated("IGUI_ChilaSeda_Moats_FillMissingTooltip",
        "Amount missing before the trench converts to normal water.")
    local tooltip = makeTooltip(help .. "<LINE>" .. missingHelp .. "<LINE>" .. label)

    local ok, option = pcall(function()
        return context:addOption(label, moat, function() end)
    end)
    if not ok or not option then
        fallback("context-option-create-failed")
        return
    end

    option.isDisabled = true
    option.toolTip = tooltip
    option.chilaSedaMoatsFillStatus = true
    local result = tooltip and "added" or "added-tooltip-fallback"
    trace("status result=" .. result .. " amount=" .. amountText .. "/" .. capacityText
        .. " missing=" .. missingText .. " percent=" .. tostring(percentage), label)
end

local function install()
    local interaction = ViewpointInteract
    if type(interaction) ~= "table" or type(interaction.build) ~= "function" then
        fallback("ViewpointInteract.build-unavailable")
        if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
            Events.OnGameStart.Add(install)
        end
        return false
    end
    if interaction.chilaSedaMoatsFillLevelWrapped then return true end

    interaction.chilaSedaMoatsFillLevelWrapped = true
    local original = interaction.build
    interaction.build = function(playerNum, worldobjects, square)
        local ok, context = original(playerNum, worldobjects, square)
        if ok and context then addFillStatus(context, square, worldobjects) end
        return ok, context
    end
    trace("hook result=installed target=ViewpointInteract.build")
    return true
end

install()
