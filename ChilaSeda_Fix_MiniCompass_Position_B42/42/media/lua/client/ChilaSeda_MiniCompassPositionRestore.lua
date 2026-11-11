-- Reapply MiniCompass's existing local position preference after player setup.
-- The Workshop original remains untouched; this patch runs after MiniCompass.
require "MiniCompass/MC_Main"

-- The Workshop mod exposes its API as the global `MC` (from MC_Constants.lua).
-- There is no `MiniCompass` global; binding that name made every restore return
-- at the first guard, leaving the HUD at its default position on each entry.
local compassMod = MC
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

local function onTick()
    local player = localPlayer()
    if not player or player == restoredPlayer then return end
    restoreSavedPosition(player, "OnTick")
end

if Events and Events.OnCreatePlayer and type(Events.OnCreatePlayer.Add) == "function" then
    Events.OnCreatePlayer.Add(onCreatePlayer)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    Events.OnTick.Add(onTick)
end

print("[ChilaSeda_MiniCompassPositionRestore] ready")
