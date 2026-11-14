-- Viewpoint 0.1.7's GPU live-pose path bypasses Blood FX's cut-limb visibility on living zombies.
-- Use Viewpoint's CPU pose fallback for this session whenever Blood FX is loaded.
local active = false
local warned = false

local function applyCompatibility()
    if active or not luajava or type(luajava.bindClass) ~= "function" then return active end

    local okGore = pcall(function() return luajava.bindClass("bloodfx.Gore") end)
    if not okGore then return false end

    local ok, err = pcall(function()
        local livePoses = luajava.bindClass("viewpoint.models.LivePoses")
        local field = livePoses:getDeclaredField("ON")
        field:setAccessible(true)
        local option = field:get(nil)
        if not option then error("Viewpoint LivePoses toggle unavailable") end

        local enabled = option:get()
        if enabled then option:set(false) end
        active = true
        print("[ChilaSeda_BloodFXCorpseLimbs] v0.1.2 compatibility fallback active; Viewpoint GPU live poses disabled for this session")
    end)

    if not ok and not warned then
        warned = true
        print("[ChilaSeda_BloodFXCorpseLimbs] could not enable live dismemberment compatibility fallback: " .. tostring(err))
    end
    return active
end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(applyCompatibility)
end
if Events and Events.OnMainMenuEnter and Events.OnMainMenuEnter.Add then
    Events.OnMainMenuEnter.Add(applyCompatibility)
end