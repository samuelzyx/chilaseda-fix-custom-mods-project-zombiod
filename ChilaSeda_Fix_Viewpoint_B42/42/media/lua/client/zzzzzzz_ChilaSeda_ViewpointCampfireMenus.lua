local TAG = "[ChilaSeda_ViewpointCampfireMenus] "
local TRACE_ENABLED = true
local MAX_TRACE_LINES = 32
local traceLines = 0
local TENT_TAG = "[ChilaSeda_ViewpointTentMenus] "
local TENT_TRACE_ENABLED = true
local MAX_TENT_TRACE_LINES = 16
local tentTraceLines = 0
local tracedFuelSections = {}
local tracedFuelTooltips = {}

local function trace(message)
    if not TRACE_ENABLED or traceLines >= MAX_TRACE_LINES then return end
    traceLines = traceLines + 1
    if type(print) == "function" then pcall(print, TAG .. message) end
end

local function traceTent(message)
    if not TENT_TRACE_ENABLED or tentTraceLines >= MAX_TENT_TRACE_LINES then return end
    tentTraceLines = tentTraceLines + 1
    if type(print) == "function" then pcall(print, TENT_TAG .. message) end
end

local VANILLA_TENT_SPRITES = {
    TileIndieStoneTentFrontLeft = true,
    TileIndieStoneTentBackLeft = true,
    TileIndieStoneTentFrontRight = true,
    TileIndieStoneTentBackRight = true,
    camping_01_3 = true,
    camping_01_2 = true,
    camping_01_0 = true,
    camping_01_1 = true,
}

local function looksLikeTentObject(object)
    if not object then return false end
    local okSprite, sprite = pcall(function() return object:getSprite() end)
    if okSprite and sprite then
        local okName, name = pcall(function() return sprite:getName() end)
        if okName and name and VANILLA_TENT_SPRITES[name] then return true end
    end
    local okProperties, properties = pcall(function() return object:getProperties() end)
    if not okProperties or not properties then return false end
    local okHas, hasCustomName = pcall(function() return properties:has("CustomName") end)
    if not okHas or not hasCustomName then return false end
    local okName, name = pcall(function() return properties:get("CustomName") end)
    return okName and (name == "Tent" or name == "Shelter")
end

local function includeTentGridObjects(worldobjects)
    if type(worldobjects) ~= "table" then return "fallback", "worldobjects-not-table" end
    local campingApi = camping
    if type(campingApi) ~= "table" or type(campingApi.isTentObject) ~= "function" then
        for _, object in ipairs(worldobjects) do
            if looksLikeTentObject(object) then return "unavailable", "vanilla-tent-detection-api-unavailable" end
        end
        return "not-tent", nil
    end

    local seen = {}
    for _, object in ipairs(worldobjects) do
        if object then seen[object] = true end
    end

    local foundTent = false
    local added = 0
    local fallbackReason = nil
    local originalCount = #worldobjects
    for index = 1, originalCount do
        local object = worldobjects[index]
        local okTent, isTent = pcall(campingApi.isTentObject, object)
        if not okTent then
            fallbackReason = fallbackReason or "tent-detection-failed"
        elseif isTent then
            foundTent = true
            if type(campingApi.getTentObjects) ~= "function" then
                fallbackReason = fallbackReason or "vanilla-tent-grid-api-unavailable"
            else
                local okParts, parts = pcall(campingApi.getTentObjects, object)
                if not okParts or type(parts) ~= "table" then
                    fallbackReason = fallbackReason or "tent-grid-lookup-failed"
                else
                    for _, part in ipairs(parts) do
                        if part and not seen[part] then
                            seen[part] = true
                            table.insert(worldobjects, part)
                            added = added + 1
                        end
                    end
                end
            end
        end
    end

    if not foundTent then return "not-tent", nil end
    if fallbackReason then return "fallback", fallbackReason end
    if added > 0 then return "expanded", tostring(added + originalCount) end
    return "complete", tostring(#worldobjects)
end

local function campfireAtObject(object)
    if not object or not CCampfireSystem or not CCampfireSystem.instance then return nil end
    local okSquare, square = pcall(function() return object:getSquare() end)
    if not okSquare or not square then return nil end
    local okFire, campfire = pcall(function()
        return CCampfireSystem.instance:getLuaObjectOnSquare(square)
    end)
    return okFire and campfire or nil
end

local function firstCampfire(worldobjects)
    for _, object in ipairs(worldobjects or {}) do
        local campfire = campfireAtObject(object)
        if campfire then
            local okObject, fireObject = pcall(function() return campfire:getIsoObject() end)
            return okObject and fireObject or object, campfire
        end
    end
    return nil, nil
end

local function campfireForSection(section)
    local container = section and section.container
    if not container then return nil, nil end
    local okObject, object = pcall(function() return container:getParent() end)
    if not okObject or not object then return nil, nil end
    local campfire = campfireAtObject(object)
    if not campfire then return nil, nil end
    return object, campfire
end

local function fuelDisplay(campfire)
    if not campfire then return nil, nil end
    local minutes = tonumber(campfire.fuelAmt) or 0
    local duration = tostring(minutes)
    if ISCampingMenu and type(ISCampingMenu.timeString) == "function" then
        local ok, result = pcall(ISCampingMenu.timeString, minutes)
        if ok and result then duration = tostring(result) end
    end
    local stateKey = campfire.isLit and "IGUI_Fireplace_Burning" or "IGUI_Fireplace_Unlit"
    local state = type(getText) == "function" and getText(stateKey) or stateKey
    local fuel = type(getText) == "function"
        and getText("IGUI_BBQ_FuelAmount", duration)
        or ("Fuel: " .. duration)
    return duration, tostring(fuel) .. " (" .. tostring(state) .. ")"
end

local function menuHasCampfireRoot(menu, object)
    local okName, tileName = pcall(function() return object:getTileName() end)
    if not okName or not tileName or not menu or type(menu.options) ~= "table" then return false end
    local count = type(menu.numOptions) == "number" and menu.numOptions - 1 or #menu.options
    for i = 1, count do
        local option = menu.options[i]
        if option and option.subOption and option.name == tileName then return true end
    end
    return false
end

local function optionCount(menu)
    if type(menu and menu.numOptions) == "number" then return math.max(0, menu.numOptions - 1) end
    return type(menu and menu.options) == "table" and #menu.options or 0
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

local function attachFuelTooltips(menu, campfire, depth)
    if not menu or depth > 5 or type(menu.options) ~= "table" then return 0 end
    local _, description = fuelDisplay(campfire)
    if not description then return 0 end
    local count = type(menu.numOptions) == "number" and menu.numOptions - 1 or #menu.options
    local attached = 0
    for i = 1, count do
        local option = menu.options[i]
        if option then
            local isFuelInfo = ISCampingMenu and option.onSelect == ISCampingMenu.onDisplayInfo
                or ISBBQMenu and option.onSelect == ISBBQMenu.onDisplayInfo
            if isFuelInfo then
                local tooltip = makeTooltip(description)
                if tooltip then
                    option.toolTip = tooltip
                    attached = attached + 1
                    trace("fuel-tooltip result=attached target=world-menu")
                else
                    trace("fuel-tooltip result=fallback reason=ISToolTip-unavailable")
                end
            end
            if option.subOption and type(menu.getSubMenu) == "function" then
                local okSub, submenu = pcall(menu.getSubMenu, menu, option.subOption)
                if okSub and submenu then attached = attached + attachFuelTooltips(submenu, campfire, depth + 1) end
            end
        end
    end
    if depth == 0 and attached == 0 then trace("fuel-tooltip result=fallback reason=native-info-option-not-found") end
    return attached
end

local function addCampfireOptions(playerNum, context, worldobjects)
    local object, campfire = firstCampfire(worldobjects)
    if not object or not campfire or not context then return false end

    if not menuHasCampfireRoot(context, object) then
        if not ISCampingMenu or type(ISCampingMenu.doCampingMenu) ~= "function" then
            trace("menu result=fallback reason=ISCampingMenu.doCampingMenu-unavailable")
            return false
        end
        local before = optionCount(context)
        local ok, err = pcall(ISCampingMenu.doCampingMenu, playerNum, context, worldobjects, false)
        if not ok then
            trace("menu result=fallback reason=native-builder-failed error=" .. tostring(err))
            return false
        end
        if optionCount(context) <= before then
            trace("menu result=fallback reason=native-builder-produced-no-options")
            return false
        end
        trace("menu result=added source=ISCampingMenu.doCampingMenu")
    else
        trace("menu result=kept source=native-fire-submenu")
    end

    attachFuelTooltips(context, campfire, 0)
    return true
end

local function wrapWorldMenu()
    local interaction = ViewpointInteract
    if type(interaction) ~= "table" or type(interaction.build) ~= "function" then
        trace("world-hook result=fallback reason=ViewpointInteract.build-unavailable")
        return
    end
    if interaction.chilaSedaCampfireBuildWrapped then return end
    interaction.chilaSedaCampfireBuildWrapped = true
    local original = interaction.build
    interaction.build = function(playerNum, worldobjects, square)
        local tentResult, tentDetail = includeTentGridObjects(worldobjects)
        local ok, context = original(playerNum, worldobjects, square)
        if ok and context then addCampfireOptions(playerNum, context, worldobjects) end
        if tentResult == "expanded" or tentResult == "complete" then
            traceTent("native-menu result=" .. tentResult .. " parts=" .. tostring(tentDetail))
        elseif tentResult == "fallback" or tentResult == "unavailable" then
            traceTent("native-menu result=fallback reason=" .. tostring(tentDetail))
        end
        return ok, context
    end
    trace("world-hook result=installed")
end

local function wrapFuelHeader()
    local grid = ViewpointInvGrid
    if type(grid) ~= "table" or type(grid.header) ~= "function" then
        trace("fuel-title result=fallback reason=ViewpointInvGrid.header-unavailable")
        return
    end
    if grid.chilaSedaCampfireHeaderWrapped then return end
    grid.chilaSedaCampfireHeaderWrapped = true
    local original = grid.header
    grid.header = function(self, ui, section, shown, x, y, w, view)
        local _, campfire = campfireForSection(section)
        if not campfire then return original(self, ui, section, shown, x, y, w, view) end
        local duration = fuelDisplay(campfire)
        local oldTitle = section.title
        section.title = tostring(oldTitle or "") .. " (" .. tostring(duration) .. ")"
        local ok, err = pcall(original, self, ui, section, shown, x, y, w, view)
        section.title = oldTitle
        if not tracedFuelSections[section.container] then
            tracedFuelSections[section.container] = true
            trace("fuel-title result=shown duration=" .. tostring(duration)
                .. " lit=" .. tostring(campfire.isLit == true))
        end
        if not ok then
            trace("fuel-title result=fallback reason=header-draw-failed error=" .. tostring(err))
            return original(self, ui, section, shown, x, y, w, view)
        end
    end
    trace("fuel-title result=installed")
end

local function wrapFuelTooltip()
    local screen = ViewpointInvScreen
    if type(screen) ~= "table" or type(screen.track) ~= "function" then
        trace("fuel-tooltip result=fallback reason=ViewpointInvScreen.track-unavailable")
        return
    end
    if screen.chilaSedaCampfireTrackWrapped then return end
    screen.chilaSedaCampfireTrackWrapped = true
    local original = screen.track
    screen.track = function(self, ...)
        local result = original(self, ...)
        local hover = self.hover
        if hover and hover.kind == "header" then
            local _, campfire = campfireForSection(hover.section)
            local _, description = fuelDisplay(campfire)
            if description and type(self.noteTip) == "function" then
                local okTip, errTip = pcall(self.noteTip, self, description)
                local container = hover.section and hover.section.container
                if okTip then
                    if container and not tracedFuelTooltips[container] then
                        tracedFuelTooltips[container] = true
                        trace("fuel-tooltip result=shown target=inventory-row")
                    end
                else
                    trace("fuel-tooltip result=fallback target=inventory-row error=" .. tostring(errTip))
                end
            end
        end
        return result
    end
    trace("fuel-tooltip result=installed")
end

local function showSectionMenu(screen, x, y, object, campfire)
    if not ISContextMenu or type(ISContextMenu.get) ~= "function"
            or not ISCampingMenu or type(ISCampingMenu.doCampingMenu) ~= "function" then
        trace("row-menu result=fallback reason=native-context-api-unavailable")
        return false
    end
    local playerNum = 0
    local okMenu, menu = pcall(ISContextMenu.get, playerNum,
        screen:getAbsoluteX() + x, screen:getAbsoluteY() + y)
    if not okMenu or not menu then
        trace("row-menu result=fallback reason=context-menu-create-failed")
        return false
    end
    local objectOk, worldObject = pcall(function() return campfire:getIsoObject() end)
    if not objectOk or not worldObject then worldObject = object end
    local objects = { worldObject }
    if not addCampfireOptions(playerNum, menu, objects) then
        trace("row-menu result=fallback reason=no-vanilla-options")
        return false
    end
    trace("row-menu result=opened source=ISCampingMenu.doCampingMenu")
    return true
end

local function wrapRowMenu()
    local screen = ViewpointInvScreen
    if type(screen) ~= "table" or type(screen.onRightMouseUp) ~= "function" then
        trace("row-menu result=fallback reason=ViewpointInvScreen.onRightMouseUp-unavailable")
        return
    end
    if screen.chilaSedaCampfireRightClickWrapped then return end
    screen.chilaSedaCampfireRightClickWrapped = true
    local original = screen.onRightMouseUp
    screen.onRightMouseUp = function(self, x, y)
        if self.up and not self.drag then
            local okHit, hit = pcall(self.hit, self, x, y)
            if okHit and hit and hit.kind == "header" then
                local object, campfire = campfireForSection(hit.section)
                if object and campfire and showSectionMenu(self, x, y, object, campfire) then return true end
            end
        end
        return original(self, x, y)
    end
    trace("row-menu result=installed")
end

wrapWorldMenu()
wrapFuelHeader()
wrapFuelTooltip()
wrapRowMenu()
