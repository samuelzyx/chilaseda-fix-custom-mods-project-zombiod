-- DGVFlags provides fabric flags and hanging banners, not poles or hardware.
-- A common 3x5 ft polyester flag weighs about 0.14-0.15 kg; use 0.15 kg for
-- both variants after True Weight has applied its own item rules.

local TARGET_MODULE = "DGVFlags"
local TARGET_WEIGHT = 0.15

local function rebalanceFlags()
    if not ScriptManager or not ScriptManager.instance then
        print("[ChilaSeda_DGVFlagsWeightFix] ScriptManager unavailable; flag weights unchanged")
        return
    end

    local allItems = ScriptManager.instance:getAllItems()
    if not allItems then
        print("[ChilaSeda_DGVFlagsWeightFix] item registry unavailable; flag weights unchanged")
        return
    end

    local changed = 0
    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if item and item:getModuleName() == TARGET_MODULE then
            local name = item:getName() or ""
            if string.sub(name, 1, 5) == "Flag_"
                or string.sub(name, 1, 7) == "Banner_" then
                item:setActualWeight(TARGET_WEIGHT)
                changed = changed + 1
            end
        end
    end

    print("[ChilaSeda_DGVFlagsWeightFix] set " .. tostring(changed)
        .. " DGVFlags flag/banner item(s) to " .. tostring(TARGET_WEIGHT) .. " kg")
end

Events.OnLoadedTileDefinitions.Add(rebalanceFlags)
