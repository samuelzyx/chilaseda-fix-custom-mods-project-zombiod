require "TimedActions/Fishing/TimedActions/ISPickupFishAction"

local TAG = "[ChilaSeda_ViewpointFishingHalo] "
local MAX_TRACE_LINES = 16
local traceCount = 0
local installLogged = false
local installFallbackLogged = false

if ChilaSedaViewpointFishingHaloTrace == nil then
    ChilaSedaViewpointFishingHaloTrace = true
end

local function trace(event, detail)
    if ChilaSedaViewpointFishingHaloTrace ~= true or traceCount >= MAX_TRACE_LINES then return end
    traceCount = traceCount + 1
    print(TAG .. "event=" .. tostring(event) .. " " .. tostring(detail or ""))
end

local function isLocalPlayer(player)
    if not player or type(getSpecificPlayer) ~= "function" then return false end
    local localPlayer = getSpecificPlayer(0)
    if player == localPlayer then return true end
    return type(player.getPlayerNum) == "function"
        and localPlayer ~= nil
        and type(localPlayer.getPlayerNum) == "function"
        and player:getPlayerNum() == localPlayer:getPlayerNum()
end

local function fishName(item)
    if not item or type(item.getName) ~= "function" then return nil end
    local ok, name = pcall(item.getName, item)
    if ok and type(name) == "string" and name ~= "" then return name end
    return nil
end

local function notifyFishCatch(action)
    if type(action) ~= "table" and type(action) ~= "userdata" then return end
    if action.isFish ~= true or action.chilaSedaFishHaloSent == true then return end
    action.chilaSedaFishHaloSent = true

    local player = action.character
    if not isLocalPlayer(player) then
        trace("fish-catch", "result=skip reason=not-local-player")
        return
    end

    local name = fishName(action.item)
    if not name then
        trace("fish-catch", "result=fallback reason=fish-name-unavailable")
        return
    end

    local notices = ChilaSeda_ViewpointHaloNotifications
    if type(notices) ~= "table" or type(notices.showProtected) ~= "function" then
        trace("fish-catch", "result=fallback reason=halo-notes-unavailable")
        return
    end

    local message = "+1 " .. name
    local ok, shown = pcall(notices.showProtected, message,
        { r = 1, g = 0.78, b = 0.32 },
        "media/ui/survival_guide_spiffo/category_fishing.png", nil, "Fishing.Catch")
    if ok and shown == true then
        trace("fish-catch", "result=shown source=ISPickupFishAction name=" .. name:gsub("[%r\n]", " "):sub(1, 96))
    else
        trace("fish-catch", "result=fallback reason=halo-notes-rejected")
    end
end

local function installFishingCatchHook()
    local action = ISPickupFishAction
    if type(action) ~= "table" or type(action.PickupFishUpdate) ~= "function" then
        if not installFallbackLogged then
            installFallbackLogged = true
            trace("install", "result=retry reason=ISPickupFishAction-unavailable")
        end
        return false
    end
    if action.chilaSedaFishingHaloInstalled == true then return true end

    local original = action.PickupFishUpdate
    action.PickupFishUpdate = function(self, ...)
        local wasInInventory = self and self.fishInInv == true
        local results = { n = 0 }
        local function pack(...)
            results.n = select("#", ...)
            for index = 1, results.n do results[index] = select(index, ...) end
        end
        pack(original(self, ...))

        if not wasInInventory and self and self.fishInInv == true then
            notifyFishCatch(self)
        end

        return unpack(results, 1, results.n)
    end
    action.chilaSedaFishingHaloInstalled = true
    if not installLogged then
        installLogged = true
        trace("install", "result=installed method=ISPickupFishAction.PickupFishUpdate")
    end
    return true
end

installFishingCatchHook()
if Events and Events.OnGameStart and type(Events.OnGameStart.Add) == "function" then
    Events.OnGameStart.Add(installFishingCatchHook)
end
if Events and Events.OnTick and type(Events.OnTick.Add) == "function" then
    local function retryFishingCatchHook()
        if installFishingCatchHook() and type(Events.OnTick.Remove) == "function" then
            Events.OnTick.Remove(retryFishingCatchHook)
        end
    end
    if not ISPickupFishAction or not ISPickupFishAction.chilaSedaFishingHaloInstalled then
        Events.OnTick.Add(retryFishingCatchHook)
    end
end
