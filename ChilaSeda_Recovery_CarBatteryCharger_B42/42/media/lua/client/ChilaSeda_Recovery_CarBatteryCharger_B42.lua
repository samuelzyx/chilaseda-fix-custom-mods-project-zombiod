local MOD_ID = "ChilaSeda_Recovery_CarBatteryCharger_B42"
local PLAYER_FLAG = MOD_ID .. "_done"
local ITEM_TYPE = "Base.CarBatteryCharger"

local function onCreatePlayer(playerNum, player)
    if isClient() or playerNum ~= 0 then return end
    if not player then player = getSpecificPlayer(playerNum) end
    if not player then return end

    local playerData = player:getModData()
    if playerData[PLAYER_FLAG] == true then return end

    local item = instanceItem(ITEM_TYPE)
    if not item then
        print("[" .. MOD_ID .. "] Could not create " .. ITEM_TYPE)
        return
    end

    local added = player:getInventory():AddItem(item)
    if not added then
        print("[" .. MOD_ID .. "] Could not add " .. ITEM_TYPE .. " to Jill's inventory")
        return
    end

    playerData[PLAYER_FLAG] = true
    print("[" .. MOD_ID .. "] Recovered one " .. ITEM_TYPE .. " into Jill's inventory")
end

Events.OnCreatePlayer.Add(onCreatePlayer)
