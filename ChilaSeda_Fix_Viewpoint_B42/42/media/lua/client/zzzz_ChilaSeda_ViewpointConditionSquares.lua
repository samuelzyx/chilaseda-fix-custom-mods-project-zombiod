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

local originalRows = L.rows
L.rows = function(grid, ui, section, stacks, top, bottomEdge, view)
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
                local side = math.max(5, math.min(8, math.floor((l.tile - round * 2) * 0.34 + 0.5)))
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