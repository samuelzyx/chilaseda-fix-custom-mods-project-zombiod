-- Reapply MiniCompass's existing local position preference after player setup.
-- The Workshop original remains untouched; this patch runs after MiniCompass.
require "MiniCompass/MC_Main"

-- The Workshop mod exposes its API as the global `MC` (from MC_Constants.lua).
-- There is no `MiniCompass` global; binding that name made every restore return
-- at the first guard, leaving the HUD at its default position on each entry.
local compassMod = MC

-- The Workshop preference API prefers getClientUsername(), which can be the
-- Steam account name (for example "Bob") instead of the active save player
-- (for example "JillValentine"). Keep reads and drag-end writes keyed to the
-- player's own username so the position saved by HUD:finishDrag is the one
-- restored for that character on the next session.
if compassMod and compassMod.Preferences then
    local preferences = compassMod.Preferences
    local originalGetPlayerKey = preferences.getPlayerKey
    preferences.getPlayerKey = function(player)
        if player and type(player.getUsername) == "function" then
            local ok, username = pcall(player.getUsername, player)
            if ok and type(username) == "string" and username ~= "" then
                local safeUsername = username:gsub("[^%w%._%-]", "_")
                return "user_" .. safeUsername
            end
        end
        if type(originalGetPlayerKey) == "function" then
            return originalGetPlayerKey(player)
        end
        return "local_player_0"
    end
end

local restoredPlayer = nil
local loggedMissingForPlayer = nil

local function localPlayer()
    if type(getSpecificPlayer) == "function" then
        local player = getSpecificPlayer(0)
        if player then return player end
    end
    if type(getPlayer) == "function" then return getPlayer() end
    return nil
end

-- The Workshop HUD saves through ownerPlayer. Resolve that owner at the moment
-- the drag ends, when the live character is available, instead of trusting an
-- early player reference captured during startup.
if compassMod and compassMod.HUD and not compassMod.HUD.chilaSedaStableSave then
    local hudClass = compassMod.HUD
    hudClass.chilaSedaStableSave = true
    hudClass.savePosition = function(panel)
        local player = localPlayer()
        if player then panel.ownerPlayer = player end
        local owner = panel.ownerPlayer
        local preferences = compassMod.Preferences
        if not owner or not preferences or type(preferences.savePosition) ~= "function" then
            return false
        end
        return preferences.savePosition(owner, panel:getX(), panel:getY())
    end
end

local function restoreSavedPosition(player, source)
    if not player or not compassMod or not compassMod.Runtime or not compassMod.Preferences then return false end
    local panel = compassMod.Runtime.panel
    local loadPosition = compassMod.Preferences.loadPosition
    if not panel or type(loadPosition) ~= "function"
            or type(panel.setPositionClamped) ~= "function" then
        return false
    end

    local ok, x, y = pcall(loadPosition, player)
    if not ok then
        print("[ChilaSeda_MiniCompassPositionRestore] load failed via " .. tostring(source)
            .. ": " .. tostring(x))
        return false
    end
    if type(x) ~= "number" or type(y) ~= "number" then
        if loggedMissingForPlayer ~= player then
            local filename = "unknown"
            if type(compassMod.Preferences.getFilename) == "function" then
                local filenameOk, filenameValue = pcall(compassMod.Preferences.getFilename, player)
                if filenameOk and filenameValue then filename = filenameValue end
            end
            print("[ChilaSeda_MiniCompassPositionRestore] no saved position via "
                .. tostring(source) .. "; file=" .. tostring(filename))
            loggedMissingForPlayer = player
        end
        restoredPlayer = player
        return false
    end

    panel.ownerPlayer = player
    local restoredX, restoredY = panel:setPositionClamped(x, y)
    restoredPlayer = player
    loggedMissingForPlayer = nil
    print("[ChilaSeda_MiniCompassPositionRestore] restored via " .. tostring(source)
        .. " x=" .. tostring(restoredX or x) .. " y=" .. tostring(restoredY or y))
    return true
end

local function onCreatePlayer(playerIndex, player)
    if playerIndex ~= 0 then return end
    if restoreSavedPosition(player, "OnCreatePlayer") then return end
    -- The main mod may not have created its HUD yet; OnTick retries once ready.
    restoredPlayer = nil
end

local function onTick(source)
    local player = localPlayer()
    if not player or player == restoredPlayer then return end
    restoreSavedPosition(player, source or "OnTick")
end

if Events and Events.OnCreatePlayer and type(Events.OnCreatePlayer.Add) == "function" then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(function() onTick("OnTick") end)
end
-- OnTick may stop while the game is paused. The HUD can be created after
-- OnCreatePlayer, so retry on this paused-safe event until its panel is ready.
if Events and Events.OnTickEvenPaused and type(Events.OnTickEvenPaused.Add) == "function" then
    Events.OnTickEvenPaused.Add(function() onTick("OnTickEvenPaused") end)
end

print("[ChilaSeda_MiniCompassPositionRestore] ready")
