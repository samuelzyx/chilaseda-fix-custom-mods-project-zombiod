local loaded, loadError = pcall(require, "Viewpoint_InvList")
local loadedGrid, gridLoadError = pcall(require, "Viewpoint_InvGrid")
local loadedData, dataLoadError = pcall(require, "Viewpoint_InvData")
local S = ViewpointInvStyle
local L = ViewpointInvList
local G = ViewpointInvGrid
local D = ViewpointInvData
if not loaded or not loadedGrid or not loadedData or not S or not L or not G or not D
        or type(L.rows) ~= "function" or type(L.layout) ~= "function" or type(L.height) ~= "function"
        or type(G.contentHeight) ~= "function" or type(D.shown) ~= "function"
        or type(S.condition) ~= "function" or type(S.rect) ~= "function" then
    print("[ChilaSeda_ViewpointConditionSquares] Viewpoint inventory list unavailable; patch skipped: "
        .. tostring(loadError or gridLoadError or dataLoadError))
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

local scaleDiagnostics = setmetatable({}, { __mode = "k" })
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

local function panelScaleForCorpse(grid, requested)
    local metrics = {}
    for key, value in pairs(grid.m or {}) do
        metrics[key] = type(value) == "number" and value * requested or value
    end
    local scaled = setmetatable({ m = metrics, x = grid.x, w = grid.w }, { __index = grid })
    local ok, result = pcall(L.layout, scaled)
    if not ok or type(scaled.lm) ~= "table" then
        print("[ChilaSeda_ViewpointConditionSquares] panel-scale layout failed: " .. tostring(result))
        return grid
    end

    local previous = scaleDiagnostics[grid]
    local style = tostring(ChilaSedaViewpointCorpseWearStyle or "BAR")
    if not previous or previous.scale ~= requested or previous.style ~= style then
        print("[ChilaSeda_ViewpointConditionSquares] panel-scale section=corpse source=grid-metrics"
            .. " configured=" .. string.format("%.2f", requested)
            .. " applied=" .. string.format("%.2f", requested)
            .. " style=" .. style
            .. " width=" .. tostring(grid.w)
            .. " font=" .. tostring(grid.m and grid.m.font) .. "->" .. tostring(metrics.font)
            .. " row=" .. tostring(grid.lm and grid.lm.row) .. "->" .. tostring(scaled.lm.row)
            .. " tile=" .. tostring(grid.lm and grid.lm.tile) .. "->" .. tostring(scaled.lm.tile))
        scaleDiagnostics[grid] = { scale = requested, style = style }
    end
    return scaled
end

local originalContentHeight = G.contentHeight
G.contentHeight = function(grid)
    local height = originalContentHeight(grid)
    local scale = math.max(1, math.min(2,
        tonumber(ChilaSedaViewpointCorpsePanelScale) or 1.5))
    if scale <= 1 or not grid.list then return height end

    local extra = 0
    local narrowed = type(grid.narrowed) == "function" and grid:narrowed() or false
    for _, section in ipairs(grid.sections or {}) do
        local listed = false
        if type(grid.lists) == "function" then
            local ok, result = pcall(grid.lists, grid, section)
            listed = ok and result == true
        end
        if listed and isCorpseSection(section) and (narrowed or not section.folded) then
            local ok, shown = pcall(D.shown, section, grid.query, grid.order, grid.filter)
            if ok and type(shown) == "table" and (not narrowed or #shown > 0) then
                local scaled = panelScaleForCorpse(grid, scale)
                local baseOk, baseHeight = pcall(L.height, grid, shown)
                local scaledOk, scaledHeight = pcall(L.height, scaled, shown)
                if baseOk and scaledOk and type(baseHeight) == "number" and type(scaledHeight) == "number" then
                    extra = extra + math.max(0, scaledHeight - baseHeight)
                end
            end
        end
    end
    return height + extra
end

local originalRows = L.rows
L.rows = function(grid, ui, section, stacks, top, bottomEdge, view)
    local corpseSection = isCorpseSection(section)
    local panelScale = corpseSection
        and math.max(1, math.min(2, tonumber(ChilaSedaViewpointCorpsePanelScale) or 1.5) or 1) or 1
    local rowGrid = corpseSection and panelScale > 1 and panelScaleForCorpse(grid, panelScale) or grid
    local wearStyle = corpseSection and tostring(ChilaSedaViewpointCorpseWearStyle or "BAR") or "BAR"

    local originalRect = S.rect
    S.rect = function(target, x, y, w, h, color, alpha)
        if corpseSection and wearStyle == "FRAME" and h <= 2 and conditionColors[color] then return end
        return originalRect(target, x, y, w, h, color, alpha)
    end

    local originalText, originalTextRight, originalFit = S.text, S.textRight, S.fit
    if corpseSection then
        S.text = function(target, str, x, y, color, alpha, font)
            return originalText(target, str, x, y, color, alpha, font or UIFont.Medium)
        end
        S.textRight = function(target, str, x, y, color, alpha, font)
            return originalTextRight(target, str, x, y, color, alpha, font or UIFont.Medium)
        end
        S.fit = function(str, width, font)
            return originalFit(str, width, font or UIFont.Medium)
        end
    end
    local ok, height = pcall(originalRows, rowGrid, ui, section, stacks, top, bottomEdge, view)
    S.rect = originalRect
    S.text, S.textRight, S.fit = originalText, originalTextRight, originalFit
    if not ok then error(height) end

    local m, l = rowGrid.m, rowGrid.lm
    if not m or not l or not l.tile or not l.row then return height end
    local sectionHit = rowGrid.hits
    if type(sectionHit) == "table" then
        for index = #sectionHit, 1, -1 do
            local entry = sectionHit[index]
            local target = entry and entry.target
            if target and target.kind == "section" and target.section == section then
                entry.h = height
                break
            end
        end
    end
    if wearStyle ~= "FRAME" then return height end

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
                local thickness = math.max(1, math.min(4, math.floor(m.font * 0.1)))
                local tx = l.tileX + (stack.group and m.pad or 0)
                local ty = y + l.tileIn
                originalRect(ui, tx, ty, l.tile, thickness, color)
                originalRect(ui, tx, ty + l.tile - thickness, l.tile, thickness, color)
                originalRect(ui, tx, ty + thickness, thickness, l.tile - thickness * 2, color)
                originalRect(ui, tx + l.tile - thickness, ty + thickness,
                    thickness, l.tile - thickness * 2, color)
            end
        end
        y = y + l.row
    end
    return height
end

L.ChilaSedaConditionSquares = true
print("[ChilaSeda_ViewpointConditionSquares] installed: corpse list rows scale with content height and support bar/frame wear indicators")
