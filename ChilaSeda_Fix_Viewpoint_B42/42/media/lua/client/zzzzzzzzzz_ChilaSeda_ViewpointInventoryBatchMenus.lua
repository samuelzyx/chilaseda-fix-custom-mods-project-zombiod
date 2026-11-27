local TRACE_ENABLED = true
local MAX_TRACE_LINES = 24
local traceLines = 0

local function trace(message)
    if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    print("[ChilaSeda_ViewpointInventoryBatch] " .. tostring(message))
end

local screen = rawget(_G, "ViewpointInvScreen")
local data = rawget(_G, "ViewpointInvData")
local actions = rawget(_G, "ViewpointInvActions")
local contextMenu = rawget(_G, "ISInventoryPaneContextMenu")

if not screen or type(screen.itemsOf) ~= "function"
        or not data or type(data.shown) ~= "function"
        or not actions or type(actions.menu) ~= "function"
        or not contextMenu or type(contextMenu.createMenu) ~= "function" then
    trace("install result=fallback reason=missing-viewpoint-or-vanilla-api")
    return
end

local function selectedStackGroups(self, grid)
    if not grid or type(grid.sections) ~= "table"
            or type(grid.lists) ~= "function" or type(grid.narrowed) ~= "function" then
        return nil
    end

    local result, seen = {}, {}
    local narrowed = grid:narrowed()
    for _, section in ipairs(grid.sections) do
        local selected = self.selected and self.selected[section.container]
        if selected and grid:lists(section) and (narrowed or not section.folded) then
            local shown = data.shown(section, grid.query, grid.order, grid.filter)
            for _, stack in ipairs(shown or {}) do
                local group = stack.group
                if selected[stack.key] or (group and selected[group.key]) then
                    local chosen = group and selected[group.key] and group or stack
                    if not seen[chosen] then
                        seen[chosen] = true
                        result[#result + 1] = chosen
                    end
                end
            end
        end
    end
    return result
end

local originalItemsOf = screen.itemsOf
screen.itemsOf = function(self, hit)
    local items = originalItemsOf(self, hit)
    if type(items) ~= "table" or not hit or hit.kind ~= "tile"
            or not hit.section or not hit.stack then
        return items
    end

    local selected = self.selected and self.selected[hit.section.container]
    local parent = hit.stack.group
    local isSelected = selected and (selected[hit.stack.key] or (parent and selected[parent.key]))
    local groups
    if isSelected then
        local grid = self.inventory
        for _, section in ipairs(self.nearby and self.nearby.sections or {}) do
            if section == hit.section then
                grid = self.nearby
                break
            end
        end
        groups = selectedStackGroups(self, grid)
    else
        groups = { hit.stack }
    end

    if groups and #groups > 0 then
        items.chilaSedaViewpointStackGroups = groups
    end
    return items
end

local originalCreateMenu = contextMenu.createMenu
local originalActionsMenu = actions.menu
local insideViewpointMenu = false

contextMenu.createMenu = function(player, isInPlayerInventory, items, ...)
    if insideViewpointMenu and type(items) == "table" then
        local groups = items.chilaSedaViewpointStackGroups
        local groupCount, largestGroup, validGroups = 0, 0, true
        if type(groups) == "table" then
            for _, group in ipairs(groups) do
                if type(group) ~= "table" or type(group.items) ~= "table" then
                    validGroups = false
                    break
                end
                groupCount = groupCount + 1
                largestGroup = math.max(largestGroup, #group.items)
            end
        end

        if validGroups and groupCount > 0 and largestGroup > 1 then
            local nativeItems = {}
            for _, group in ipairs(groups) do
                if #group.items > 1 then
                    nativeItems[#nativeItems + 1] = group
                else
                    nativeItems[#nativeItems + 1] = group.items[1]
                end
            end
            trace("menu result=stack-groups-restored flat-items=" .. tostring(#items)
                .. " groups=" .. tostring(groupCount) .. " largest=" .. tostring(largestGroup)
                .. " rows=" .. tostring(#nativeItems))
            return originalCreateMenu(player, isInPlayerInventory, nativeItems, ...)
        end

        trace("menu result=fallback reason=no-multi-item-stack flat-items=" .. tostring(#items))
    elseif insideViewpointMenu then
        trace("menu result=fallback reason=stack-metadata-missing")
    end
    return originalCreateMenu(player, isInPlayerInventory, items, ...)
end

actions.menu = function(items, x, y)
    local previousState = insideViewpointMenu
    insideViewpointMenu = true
    local ok, result = pcall(originalActionsMenu, items, x, y)
    insideViewpointMenu = previousState
    if not ok then error(result) end
    return result
end

trace("install result=wrapped viewpoint inventory context menu")
