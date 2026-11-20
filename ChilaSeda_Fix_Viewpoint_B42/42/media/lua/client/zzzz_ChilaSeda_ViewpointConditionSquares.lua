local loaded, loadError = pcall(require, "Viewpoint_InvList")
local S = ViewpointInvStyle
local L = ViewpointInvList
if not loaded or not S or not L or type(L.rows) ~= "function" or type(S.condition) ~= "function" or type(S.rect) ~= "function" then
    print("[ChilaSeda_ViewpointConditionSquares] Viewpoint inventory list unavailable; patch skipped: " .. tostring(loadError))
    return
end

if L.ChilaSedaConditionSquares then return end

local conditionColors = {}
for percent = 0, 79 do
    local color = S.condition(percent / 100, false)
    if color then conditionColors[color] = true end
end
local fineEdgeColor = S.condition(0.799, false)
if fineEdgeColor then conditionColors[fineEdgeColor] = true end
local brokenColor = S.condition(0, true)
if brokenColor then conditionColors[brokenColor] = true end

local originalScales = setmetatable({}, { __mode = "k" })
local function safeMethod(object, method)
    if not object then return nil end
    local ok, fn = pcall(function() return object[method] end)
    if not ok or type(fn) ~= "function" then return nil end
    local success, value = pcall(fn, object)
    return success and value or nil
end

local function isCorpseSection(section)
    local container = section and section.container
    if not container then return false end
    local kind = safeMethod(container, "getType")
    if kind == "inventorymale" or kind == "inventoryfemale" then return true end
    local parent = safeMethod(container, "getParent")
    if parent and type(instanceof) == "function" then
        local ok, result = pcall(instanceof, parent, "IsoDeadBody")
        if ok and result == true then return true end
    end
    return false
end

local function applyPanelScale(ui, scale)
    if not ui then return end
    local okX, setScaleX = pcall(function() return ui.setScaleX end)
    local okY, setScaleY = pcall(function() return ui.setScaleY end)
    if not okX or not okY or type(setScaleX) ~= "function" or type(setScaleY) ~= "function" then return end
    local state = originalScales[ui]
    if not state then
        local x, y = safeMethod(ui, "getScaleX"), safeMethod(ui, "getScaleY")
        if type(x) ~= "number" then
            local ok, value = pcall(function() return ui.scaleX end)
            if ok then x = value end
        end
        if type(y) ~= "number" then
            local ok, value = pcall(function() return ui.scaleY end)
            if ok then y = value end
        end
        state = { x = type(x) == "number" and x or 1, y = type(y) == "number" and y or 1 }
        originalScales[ui] = state
    end
    pcall(setScaleX, ui, state.x * scale)
    pcall(setScaleY, ui, state.y * scale)
end

local originalRows = L.rows
L.rows = function(grid, ui, section, stacks, top, bottomEdge, view)
    local corpseSection = isCorpseSection(section)
    local panelScale = corpseSection
        and (tonumber(ChilaSedaViewpointCorpsePanelScale) or 1.15) or 1
    applyPanelScale(ui, math.max(1, math.min(1.5, panelScale)))

    local originalRect = S.rect
    S.rect = function(target, x, y, w, h, color, alpha)
        if h <= 2 and conditionColors[color] then return end
        return originalRect(target, x, y, w, h, color, alpha)
    end

    local ok, height = pcall(originalRows, grid, ui, section, stacks, top, bottomEdge, view)
    S.rect = originalRect
    if not ok then error(height) end

    local m, l = grid.m, grid.lm
    if not m or not l or not l.tile or not l.row then return height end
    local selected = view and view.selected and view.selected[section.container] or {}
    local y, previousGroup = top + m.gap, nil
    for _, stack in ipairs(stacks) do
        if stack.group and stack.group ~= previousGroup then
            y = y + l.row
        end
        previousGroup = stack.group
        if y + l.row >= grid.bodyTop and y <= bottomEdge then
            local isSelected = selected[stack.key] or (stack.group and selected[stack.group.key])
            local look = stack.look
            local color = not isSelected and look and S.condition(look.condition, look.broken) or nil
            if color then
                local round = l.tileRound or 0
                local maxSide = math.max(5, math.floor(l.tile - round * 2 - 1))
                local requestedSide = corpseSection and
                    (tonumber(ChilaSedaViewpointConditionMarkSize) or 10)
                    or math.max(5, math.min(8, math.floor((l.tile - round * 2) * 0.34 + 0.5)))
                local side = math.max(5, math.min(maxSide, math.floor(requestedSide + 0.5)))
                local tx = l.tileX + (stack.group and m.pad or 0)
                local ty = y + l.tileIn
                local markX = math.min(tx + round, tx + l.tile - side - 1)
                local markY = math.min(ty + 2, ty + l.tile - side - 1)
                originalRect(ui, markX, markY, side, side, color)
            end
        end
        y = y + l.row
    end
    return height
end

L.ChilaSedaConditionSquares = true
print("[ChilaSeda_ViewpointConditionSquares] installed for Viewpoint inventory-list wear markers")
