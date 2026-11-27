local TRACE_LIMIT = 16
local TRACE_PREFIX = "[ChilaSeda_ViewpointCookingTime]"
local traceCount = 0
local tracedItems = setmetatable({}, { __mode = "k" })

ChilaSedaViewpointCookingTimeTrace = ChilaSedaViewpointCookingTimeTrace == true

local function trace(event, detail)
    if ChilaSedaViewpointCookingTimeTrace ~= true or traceCount >= TRACE_LIMIT then return end
    traceCount = traceCount + 1
    print(TRACE_PREFIX .. " event=" .. tostring(event) .. " " .. tostring(detail or ""))
end

local function read(item, method)
    if item == nil then return nil end
    local ok, fn = pcall(function() return item[method] end)
    if not ok or type(fn) ~= "function" then return nil end
    local callOk, value = pcall(fn, item)
    if not callOk then return nil end
    return value
end

local function number(item, method)
    local value = read(item, method)
    if type(value) ~= "number" or value ~= value or math.abs(value) > 1000000 then return nil end
    return value
end

local function clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

local function cookingState(item)
    if item == nil or type(instanceof) ~= "function" or not instanceof(item, "Food") then
        return nil, "not-food"
    end

    if read(item, "isIsCookable") ~= true then return nil, "not-cookable" end

    local elapsed = number(item, "getCookingTime")
    local cookAt = number(item, "getMinutesToCook")
    local burnAt = number(item, "getMinutesToBurn")
    local heat = number(item, "getHeat")
    if elapsed == nil or cookAt == nil or cookAt <= 0 or burnAt == nil or heat == nil then
        return nil, "cooking-data-unavailable"
    end

    local burnt = read(item, "isBurnt") == true or burnAt > 0 and elapsed >= burnAt
    if burnt then
        return { name = "burnt", fraction = 1, remaining = 0 }, "burnt"
    end

    local cooked = read(item, "isCooked") == true or elapsed >= cookAt
    if cooked then
        if elapsed > cookAt and burnAt > cookAt then
            local fraction = clamp((elapsed - cookAt) / (burnAt - cookAt), 0, 1)
            return { name = "burning", fraction = fraction, remaining = math.max(0, math.ceil(burnAt - elapsed)) }, "burning"
        end
        return { name = "ready", fraction = 1, remaining = 0 }, "ready"
    end

    local fraction = clamp(elapsed / cookAt, 0, 1)
    local remaining = math.max(0, math.ceil(cookAt - elapsed - 0.0001))
    if heat > 1.6 and read(item, "isFrozen") ~= true then
        return { name = "cooking", fraction = fraction, remaining = remaining }, "cooking"
    end
    if elapsed > 0 then
        return { name = "paused", fraction = fraction, remaining = remaining }, "paused"
    end
    return nil, "not-started"
end

local function traceItem(item, state, reason)
    if ChilaSedaViewpointCookingTimeTrace ~= true or item == nil then return end
    local elapsed = number(item, "getCookingTime")
    local cookAt = number(item, "getMinutesToCook")
    local remaining = state and state.remaining or "na"
    local name = state and state.name or reason
    local signature = tostring(name) .. ":" .. tostring(remaining) .. ":" .. tostring(elapsed)
    if tracedItems[item] == signature then return end
    tracedItems[item] = signature
    trace("item", "type=" .. tostring(read(item, "getFullType")) .. " state=" .. tostring(name)
        .. " elapsed=" .. tostring(elapsed) .. " cookAt=" .. tostring(cookAt) .. " remaining=" .. tostring(remaining))
end

local function formattedText(baseGetText, key, value, fallback)
    local template = baseGetText(key)
    if type(template) ~= "string" or template == key then return fallback end
    local ok, result = pcall(string.format, template, value)
    if ok and type(result) == "string" then return result end
    return fallback
end

local function nativeRowText(baseGetText, key, state)
    if state == nil then return baseGetText(key) end
    local base = baseGetText(key)
    if state.name == "ready" and key == "IGUI_invpanel_Cooking" then
        return getText("IGUI_ChilaSeda_CookingReady")
    end

    local suffixKey, fallback
    if state.name == "cooking" and key == "IGUI_invpanel_Cooking" then
        suffixKey, fallback = "IGUI_ChilaSeda_CookingRemainingShort", tostring(state.remaining) .. " min restantes"
    elseif state.name == "burning" and key == "IGUI_invpanel_Burning" then
        suffixKey, fallback = "IGUI_ChilaSeda_BurningRemainingShort", tostring(state.remaining) .. " min para quemarse"
    else
        return base
    end
    return base .. " (" .. formattedText(baseGetText, suffixKey, state.remaining, fallback) .. ")"
end

local function drawViewpointDetails(self, baseRender, ui, metrics, rect, hover)
    baseRender(self, ui, metrics, rect, hover)
    local item = self.item
    local state, reason = cookingState(item)
    traceItem(item, state, reason)
    if not state then return end

    local style = ViewpointInvStyle
    if not (style and type(style.text) == "function" and type(style.bar) == "function") then
        trace("fallback", "reason=viewpoint-style-unavailable")
        return
    end

    local pad = metrics.pad or 4
    local font = metrics.font or 14
    local gap = metrics.gap or 3
    local barHeight = metrics.bar or 4
    local y = rect.y + pad + math.floor(math.min(rect.w * 0.3, metrics.unit * 2.2)) + pad
    local needed = pad + math.floor(math.min(rect.w * 0.3, metrics.unit * 2.2)) + pad + font + gap + barHeight + pad
    if rect.h < needed then
        trace("fallback", "reason=details-panel-too-short height=" .. tostring(rect.h) .. " needed=" .. tostring(needed))
        return
    end

    local labelKey
    if state.name == "cooking" then
        labelKey = "IGUI_ChilaSeda_CookingRemaining"
    elseif state.name == "paused" then
        labelKey = "IGUI_ChilaSeda_CookingPaused"
    elseif state.name == "ready" then
        labelKey = "IGUI_ChilaSeda_CookingReady"
    elseif state.name == "burning" then
        labelKey = "IGUI_ChilaSeda_BurningRemaining"
    else
        labelKey = "IGUI_ChilaSeda_CookingBurnt"
    end

    local label
    if state.name == "cooking" then
        label = formattedText(getText, labelKey, state.remaining, "Cocinando: " .. state.remaining .. " min restantes")
    elseif state.name == "paused" then
        label = formattedText(getText, labelKey, state.remaining, "Pausado: " .. state.remaining .. " min restantes")
    elseif state.name == "burning" then
        label = formattedText(getText, labelKey, state.remaining, "Quemándose: " .. state.remaining .. " min para quemarse")
    else
        label = getText(labelKey)
        if label == labelKey then label = state.name == "ready" and "Listo para retirar" or "Quemado" end
    end

    local color = style.good
    if state.name == "burning" or state.name == "burnt" then color = style.bad end
    style.text(ui, label, rect.x + pad, y, color)
    style.bar(ui, rect.x + pad, y + font + gap, rect.w - pad * 2, barHeight, state.fraction,
        color)
end

local function install()
    local installed, missing = {}, {}

    if type(require) == "function" then
        pcall(require, "ISUI/ISInventoryPane")
        pcall(require, "Viewpoint_InvDetails")
    end

    local pane = ISInventoryPane
    if pane and type(pane.drawItemDetails) == "function" then
        if not pane.chilaSedaCookingTimeWrapped then
            local base = pane.drawItemDetails
            pane.drawItemDetails = function(self, item, y, xoff, yoff, red)
                local state, reason = cookingState(item)
                traceItem(item, state, reason)
                if not state then return base(self, item, y, xoff, yoff, red) end

                local baseGetText = getText
                if type(baseGetText) ~= "function" then
                    trace("fallback", "reason=getText-unavailable")
                    return base(self, item, y, xoff, yoff, red)
                end

                getText = function(key, ...)
                    if key == "IGUI_invpanel_Cooking" or key == "IGUI_invpanel_Burning" then
                        return nativeRowText(baseGetText, key, state)
                    end
                    return baseGetText(key, ...)
                end
                local ok, err = pcall(base, self, item, y, xoff, yoff, red)
                getText = baseGetText
                if not ok then error(err, 0) end
            end
            pane.chilaSedaCookingTimeWrapped = true
        end
        installed[#installed + 1] = "ISInventoryPane.drawItemDetails"
    else
        missing[#missing + 1] = "ISInventoryPane.drawItemDetails"
    end

    local details = ViewpointInvDetails
    if details and type(details.render) == "function" then
        if not details.chilaSedaCookingTimeWrapped then
            local base = details.render
            details.render = function(self, ui, metrics, rect, hover)
                return drawViewpointDetails(self, base, ui, metrics, rect, hover)
            end
            details.chilaSedaCookingTimeWrapped = true
        end
        installed[#installed + 1] = "ViewpointInvDetails.render"
    else
        missing[#missing + 1] = "ViewpointInvDetails.render"
    end

    if #missing == 0 then
        trace("install", "result=installed methods=" .. table.concat(installed, ","))
        if Events and Events.OnGameStart and Events.OnGameStart.Remove then
            Events.OnGameStart.Remove(install)
        end
        return true
    end
    trace("install", "result=partial missing=" .. table.concat(missing, ","))
    return false
end

ChilaSedaViewpointCookingTimeStateForTests = cookingState

if not install() and Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(install)
end
