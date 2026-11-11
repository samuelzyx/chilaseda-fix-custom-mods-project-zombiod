require "LugliAchievements/Window"

local M = LugliAchievements
local PANEL_ID = "ChilaSedaLugliLogrosRecientes"
local WIDTH, HEIGHT, GAP = 310, 256, 8
local MARGIN = 8
local MAX_ROWS = 6
local panel
local attachedWindow

-- Lugli's F7 window can occupy 94% of the screen, leaving no room for a side panel.
-- Save its user geometry unchanged, while reserving a column for this panel at runtime.
local rememberWindow = M.rememberWindow
if type(rememberWindow) == "function" then
    M.rememberWindow = function(win)
        local original = win and win._chilaRecentOriginalGeometry
        if original == nil then return rememberWindow(win) end
        local x, y, w, h = win:getX(), win:getY(), win:getWidth(), win:getHeight()
        win:setX(original.x)
        win:setY(original.y)
        win:setWidth(original.w)
        win:setHeight(original.h)
        if type(win.reflow) == "function" then win:reflow() end
        rememberWindow(win)
        win:setWidth(w)
        win:setHeight(h)
        if type(win.reflow) == "function" then win:reflow() end
        win:setX(x)
        win:setY(y)
    end
end

local function getRecent()
    local playerNum = attachedWindow and attachedWindow.playerNum or 0
    local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
    local data
    if type(M.isPerCharacter) == "function" and M.isPerCharacter() then
        data = type(M.getCharData) == "function" and M.getCharData(player) or nil
    else
        data = type(M.getSaveData) == "function" and M.getSaveData() or nil
    end
    if type(data) ~= "table" or type(data.unlockedAt) ~= "table" then return {} end

    local defs = type(M.getAllDefinitions) == "function" and M.getAllDefinitions() or {}
    local rows = {}
    for i = 1, #defs do
        local def = defs[i]
        local unlocked = type(data.unlocked) == "table" and data.unlocked[def.id] == true
        if unlocked and type(data.unlockedAt[def.id]) == "number" then
            rows[#rows + 1] = { def = def, hour = data.unlockedAt[def.id] }
        end
    end
    table.sort(rows, function(a, b)
        if a.hour == b.hour then return a.def.id < b.def.id end
        return a.hour > b.hour
    end)
    while #rows > MAX_ROWS do table.remove(rows) end
    return rows
end

local function ensurePanel()
    if panel ~= nil then return panel end
    if type(ISPanel) ~= "table" or type(ISPanel.derive) ~= "function" then return nil end
    local RecentPanel = ISPanel:derive(PANEL_ID)
    function RecentPanel:new()
        local o = ISPanel.new(self, 0, 0, WIDTH, HEIGHT)
        o.background = true
        o.backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.94 }
        o.border = true
        o.borderColor = { r = 0.78, g = 0.59, b = 0.31, a = 0.9 }
        return o
    end
    function RecentPanel:render()
        self:drawText("Logros recientes", 12, 10, 0.95, 0.78, 0.48, 1, UIFont.Medium)
        local rows = getRecent()
        if #rows == 0 then
            self:drawText("Aún no hay logros desbloqueados.", 12, 48, 0.82, 0.80, 0.76, 1, UIFont.Small)
            return
        end
        for i = 1, #rows do
            local row = rows[i]
            local name = M.text(row.def.name, row.def.id)
            name = M.neat and M.neat.fit and M.neat.fit(name, WIDTH - 24, UIFont.Small) or name
            local y = 40 + (i - 1) * 34
            self:drawText(tostring(i) .. ". " .. name, 12, y, 0.92, 0.90, 0.86, 1, UIFont.Small)
            local day = math.floor(row.hour / 24) + 1
            self:drawText("Día " .. tostring(day), WIDTH - 66, y, 0.66, 0.64, 0.60, 1, UIFont.Small)
        end
    end
    panel = RecentPanel:new()
    panel:initialise()
    panel:addToUIManager()
    return panel
end

local function findAchievementWindow()
    if UIManager == nil or type(UIManager.getUI) ~= "function" then return nil end
    local ok, uis = pcall(UIManager.getUI)
    if not ok or uis == nil then return nil end
    for i = uis:size() - 1, 0, -1 do
        local ui = uis:get(i)
        if ui ~= nil and ui.Type == "LugliAchWindow" and ui:isVisible() then return ui end
    end
    return nil
end

local function positionPanel()
    local win = findAchievementWindow()
    if win == nil then
        if panel ~= nil then panel:setVisible(false) end
        attachedWindow = nil
        return
    end
    attachedWindow = win
    local p = ensurePanel()
    if p == nil then return end
    local core = getCore()
    local sx, sy = core:getScreenWidth(), core:getScreenHeight()
    local original = win._chilaRecentOriginalGeometry
    if original == nil then
        original = {
            x = win:getX(), y = win:getY(),
            w = win:getWidth(), h = win:getHeight(),
        }
        win._chilaRecentOriginalGeometry = original
    elseif original.appliedWidth ~= nil then
        if win:getWidth() ~= original.appliedWidth
            or win:getX() ~= original.appliedX
            or win:getY() ~= original.appliedY then
            original.x, original.y = win:getX(), win:getY()
            original.w, original.h = win:getWidth(), win:getHeight()
        end
    end

    local maxWindowWidth = sx - WIDTH - GAP - MARGIN * 2
    local targetWidth = math.min(original.w, maxWindowWidth)
    if targetWidth < (win.minimumWidth or 0) then
        p:setVisible(false)
        return
    end
    if win:getWidth() ~= targetWidth then
        win:setWidth(targetWidth)
        if type(win.reflow) == "function" then win:reflow() end
    end
    local windowX = MARGIN
    if win:getX() ~= windowX then win:setX(windowX) end
    original.appliedWidth = targetWidth
    original.appliedX = windowX
    original.appliedY = win:getY()

    p:setVisible(true)
    local x = win:getX() + win:getWidth() + GAP
    local y = math.max(0, math.min(win:getY(), sy - HEIGHT))
    p:setX(x)
    p:setY(y)
end

if Events ~= nil and Events.OnTick ~= nil then
    Events.OnTick.Add(positionPanel)
end

print("[ChilaSeda LugliAchievementsRecent] v1.0.1 loaded")
