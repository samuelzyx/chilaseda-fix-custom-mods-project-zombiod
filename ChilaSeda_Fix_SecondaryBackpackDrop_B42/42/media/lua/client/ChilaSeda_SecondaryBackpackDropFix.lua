require "TimedActions/ISEquipWeaponAction"

local MOD_ID = "ChilaSeda_Fix_SecondaryBackpackDrop_B42"
local originalComplete = ISEquipWeaponAction and ISEquipWeaponAction.complete

local function isFlashlight(item)
    if not item then return false end
    local ok, tags = pcall(function() return item:getTags() end)
    if not ok or not tags then return false end
    for _, tag in ipairs({ "base:flashlight", "bf:flashlight" }) do
        local containsOk, contains = pcall(function() return tags:contains(tag) end)
        if containsOk and contains then return true end
    end
    return false
end

local function heldContainerIsInInventory(character, item)
    if not character or not item or not instanceof(item, "InventoryContainer") then return false end
    local ok, inventory = pcall(function() return character:getInventory() end)
    if not ok or not inventory then return false end
    local containerOk, container = pcall(function() return item:getContainer() end)
    if not containerOk or container ~= inventory then return false end
    local containsOk, contains = pcall(function() return inventory:contains(item) end)
    return containsOk and contains == true
end

if type(originalComplete) == "function" then
    ISEquipWeaponAction.complete = function(self)
        if not self or self.primary ~= false or self.twoHands
            or not isFlashlight(self.item) or type(forceDropHeavyItems) ~= "function" then
            return originalComplete(self)
        end

        local character = self.character
        local secondary = character and character:getSecondaryHandItem()
        if not heldContainerIsInInventory(character, secondary) then
            return originalComplete(self)
        end

        -- Vanilla calls forceDropHeavyItems before replacing the secondary-hand
        -- item. Temporarily clear only this held backpack so the vanilla helper
        -- still processes the primary hand; the backpack remains in inventory
        -- and the original equip action then puts the flashlight in the free hand.
        local originalForceDrop = forceDropHeavyItems
        forceDropHeavyItems = function(target)
            if target == character and target:getSecondaryHandItem() == secondary then
                target:setSecondaryHandItem(nil)
            end
            return originalForceDrop(target)
        end

        local ok, result = pcall(originalComplete, self)
        forceDropHeavyItems = originalForceDrop
        if not ok then error(result) end
        return result
    end
    print("[" .. MOD_ID .. "] loaded v0.1.0")
else
    print("[" .. MOD_ID .. "] ISEquipWeaponAction.complete unavailable")
end
