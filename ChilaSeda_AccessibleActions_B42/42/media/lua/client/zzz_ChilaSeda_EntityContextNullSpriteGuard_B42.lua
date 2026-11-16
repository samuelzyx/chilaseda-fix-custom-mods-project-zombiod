require "Entity/ISEntityUI"

local entityUI = ISEntityUI
if not entityUI or entityUI.ChilaSedaNullSpriteGuardInstalled then return end

local originalCanOpenWindowFor = entityUI.CanOpenWindowFor
if type(originalCanOpenWindowFor) ~= "function" then
    print("[ChilaSeda_AccessibleActions] Could not install null-sprite entity context guard")
    return
end

entityUI.CanOpenWindowFor = function(player, entity)
    if entity == nil then return false end

    local ok, sprite = pcall(function()
        return entity:getSprite()
    end)
    if not ok or sprite == nil then return false end

    return originalCanOpenWindowFor(player, entity)
end

entityUI.ChilaSedaNullSpriteGuardInstalled = true
print("[ChilaSeda_AccessibleActions] Installed null-sprite entity context guard")
