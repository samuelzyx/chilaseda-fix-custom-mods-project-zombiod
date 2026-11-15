local TAG = "[ChilaSeda_ViewpointCameraWindowCleanup] "
local TETRIS_WINDOW_MANAGER = "InventoryTetris/UI/Windows/TetrisWindowManager"
local TETRIS_GRID_WINDOW = "InventoryTetris/UI/Windows/ItemGridWindow"

local bindAttempts = 0
local bindFailureLogged = false
local previousActive
local MAX_BIND_ATTEMPTS = 120

local function eachValue(collection, callback)
    if type(collection) == "table" then
        for _, value in ipairs(collection) do callback(value) end
        return
    end

    local ok, count = pcall(function() return collection:size() end)
    if not ok or not tonumber(count) then return end
    for index = 0, count - 1 do
        local gotValue, value = pcall(function() return collection:get(index) end)
        if gotValue then callback(value) end
    end
end

local function addWindow(window, windows, seen)
    if type(window) ~= "table" or seen[window] then return end
    seen[window] = true

    local isWindow = type(window.close) == "function"
        and (window.closeButton ~= nil or window.pinButton ~= nil
            or window.collapseButton ~= nil or window.titlebarbkg ~= nil)
    if isWindow then windows[#windows + 1] = window end

    local children = window.childWindows
    if type(children) == "table" then
        for _, child in ipairs(children) do
            addWindow(child, windows, seen)
        end
    end
end

local function collectWindows()
    local windows, seen = {}, {}

    if UIManager and type(UIManager.getUI) == "function" then
        local ok, rootWindows = pcall(UIManager.getUI)
        if ok and rootWindows then
            eachValue(rootWindows, function(window)
                addWindow(window, windows, seen)
            end)
        end
    end

    -- Inventory Tetris keeps some popup windows in its manager instead of the
    -- UI root list. Include those instances without changing Workshop code.
    local okManagers, managerClass = pcall(require, TETRIS_WINDOW_MANAGER)
    if okManagers and type(managerClass) == "table"
            and type(managerClass._instances) == "table" then
        for manager in pairs(managerClass._instances) do
            if type(manager) == "table" and type(manager.childWindows) == "table" then
                eachValue(manager.childWindows, function(window)
                    addWindow(window, windows, seen)
                end)
            end
        end
    end

    local okGrid, gridClass = pcall(require, TETRIS_GRID_WINDOW)
    if okGrid and type(gridClass) == "table"
            and type(gridClass._globalInstances) == "table" then
        eachValue(gridClass._globalInstances, function(window)
            addWindow(window, windows, seen)
        end)
    end

    return windows
end

local function isVisible(window)
    if type(window.getIsVisible) == "function" then
        local ok, visible = pcall(window.getIsVisible, window)
        if ok then return visible == true end
    end
    if type(window.isVisible) == "function" then
        local ok, visible = pcall(window.isVisible, window)
        if ok then return visible == true end
    end
    return window.visible ~= false
end

local function isPinned(window)
    return window.pin == true or window.pinned == true
end

local function hasPinnedChild(children)
    if type(children) ~= "table" then return false end
    for _, child in ipairs(children) do
        if isPinned(child) or hasPinnedChild(child.childWindows) then
            return true
        end
    end
    return false
end

local function ownsPinnedTetrisWindow(window)
    local pane = window.inventoryPane
    local manager = pane and pane.tetrisWindowManager
    return manager ~= nil and hasPinnedChild(manager.childWindows)
end

local function installClickToExpand(window)
    if window.cameraCleanupExpandHooked then return end

    local methodName
    if type(window.onMouseDown_preWindowManager) == "function" then
        methodName = "onMouseDown_preWindowManager"
    elseif type(window.onMouseDown) == "function" then
        methodName = "onMouseDown"
    end
    if not methodName then return end

    local original = window[methodName]
    window[methodName] = function(self, ...)
        if self.isCollapsed then
            self.isCollapsed = false
            if type(self.clearMaxDrawHeight) == "function" then
                pcall(self.clearMaxDrawHeight, self)
            end
        end
        return original(self, ...)
    end
    window.cameraCleanupExpandHooked = true
end

local function collapseWindow(window)
    -- Keep the pin flag intact. ISInventoryPage, ISCollapsableWindow, and
    -- Inventory Tetris windows all use this collapsed/max-draw-height state.
    -- Set it directly because Inventory Tetris may hook collapseNow() to close
    -- its child popups, including pinned ones.
    if window.isCollapsed == nil then return false end
    if type(window.uncollapse) ~= "function" then
        installClickToExpand(window)
    end
    window.isCollapsed = true

    if type(window.setMaxDrawHeight) == "function" then
        local height = 24
        if type(window.titleBarHeight) == "function" then
            local ok, value = pcall(window.titleBarHeight, window)
            if ok and tonumber(value) then height = tonumber(value) end
        end
        pcall(window.setMaxDrawHeight, window, height)
    end
    return true
end

local function closeWindow(window)
    if type(window.close) == "function" then
        local ok = pcall(window.close, window)
        if ok then return true end
    end
    if type(window.setVisible) == "function" then
        return pcall(window.setVisible, window, false)
    end
    return false
end

local function clearWindows()
    local windows = collectWindows()
    local closed, collapsed, leftOpen = 0, 0, 0

    for _, window in ipairs(windows) do
        if isVisible(window) then
            if isPinned(window) or ownsPinnedTetrisWindow(window) then
                if collapseWindow(window) then
                    collapsed = collapsed + 1
                else
                    leftOpen = leftOpen + 1
                end
            elseif closeWindow(window) then
                closed = closed + 1
            else
                leftOpen = leftOpen + 1
            end
        end
    end

    print(TAG .. "camera activated; closed " .. tostring(closed)
        .. ", collapsed " .. tostring(collapsed)
        .. ", could not dismiss " .. tostring(leftOpen) .. " window(s)")
end

local function onTick()
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.movableCameraState) ~= "function" then
        bindAttempts = bindAttempts + 1
        if bindAttempts >= MAX_BIND_ATTEMPTS and not bindFailureLogged then
            print(TAG .. "could not access Viewpoint movable-camera state: ZombieBuddy Java bridge unavailable")
            bindFailureLogged = true
        end
        return
    end

    local ok, state = pcall(bridge.movableCameraState)
    if not ok or type(state) ~= "number" or state < 0 then
        bindAttempts = bindAttempts + 1
        if bindAttempts >= MAX_BIND_ATTEMPTS and not bindFailureLogged then
            print(TAG .. "could not access Viewpoint movable-camera state: FreeCam reflection failed")
            bindFailureLogged = true
        end
        return
    end

    bindAttempts = 0
    bindFailureLogged = false
    local active = state == 1

    if active and previousActive ~= true then
        clearWindows()
    end
    previousActive = active
end

if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(onTick)
else
    print(TAG .. "OnTick unavailable; patch skipped")
end
