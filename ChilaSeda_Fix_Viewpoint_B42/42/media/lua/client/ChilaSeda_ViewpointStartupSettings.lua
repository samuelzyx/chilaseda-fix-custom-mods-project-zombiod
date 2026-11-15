local initialized = false
local pending = false
local attempts = 0
local maxAttempts = 120

local initializeOnTick
local function removeTickListener()
    if Events and Events.OnTick and Events.OnTick.Remove then
        pcall(function() Events.OnTick.Remove(initializeOnTick) end)
    end
end

initializeOnTick = function()
    if not pending or initialized then return end
    attempts = attempts + 1

    -- Use the Java bridge already exposed by ZombieBuddy. luajava.bindClass is
    -- not available in this Lua runtime and cannot initialize itself here.
    local bridge = ChilaSedaViewpointFogJ
    if not bridge or type(bridge.initializeGraphicsSettings) ~= "function" then
        if attempts >= maxAttempts then
            pending = false
            removeTickListener()
            print("[ChilaSeda_ViewpointStartupSettings] early settings initialization failed after " .. tostring(maxAttempts) .. " ticks: ZombieBuddy graphics bridge unavailable")
        end
        return
    end

    local ok, result = pcall(bridge.initializeGraphicsSettings)

    if ok and result == 1 then
        initialized = true
        pending = false
        removeTickListener()
        print("[ChilaSeda_ViewpointStartupSettings] live graphics settings initialized at game start")
        return
    end

    if ok and result == 0 then
        pending = false
        removeTickListener()
        print("[ChilaSeda_ViewpointStartupSettings] graphics settings bridge connected but SettingsWindow.update failed")
        return
    end

    if attempts >= maxAttempts then
        pending = false
        removeTickListener()
        print("[ChilaSeda_ViewpointStartupSettings] Viewpoint SettingsWindow unavailable after " .. tostring(maxAttempts) .. " ticks")
    end
end

local function onGameStart()
    if initialized then return end
    pending = true
    attempts = 0

end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(onGameStart)
end
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(initializeOnTick)
end
