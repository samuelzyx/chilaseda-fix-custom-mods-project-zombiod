local forcedFishingDeviceState = false

local function fishingIsActive()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() or not FishingState or not FishingState.instance then
        return false
    end
    return player:getCurrentState() == FishingState.instance()
end

Events.OnTick.Add(function()
    local qol = rawget(_G, "ProjectViewpointQOL")
    local cache = qol and qol.uiStateCache
    if not qol or type(cache) ~= "table" then return end

    if fishingIsActive() then
        -- ProjectViewpointQOL caches device/window state. Keep its existing
        -- mouse-unlock path alive while the native fishing state owns input.
        cache[3] = true
        if type(getTimestampMs) == "function" then
            qol.deviceStateAt = getTimestampMs() + 60000
        end
        forcedFishingDeviceState = true
    elseif forcedFishingDeviceState then
        cache[3] = nil
        qol.deviceStateAt = 0
        forcedFishingDeviceState = false
    end
end)