require "ISUI/ISInventoryPaneContextMenu"

local originalEquipWeapon = ISInventoryPaneContextMenu.equipWeapon
if type(originalEquipWeapon) ~= "function" then
    print("[ChilaSeda_ViewpointCorpseEquip] equipWeapon API unavailable; patch skipped.")
    return
end

local function isCorpseContainer(container)
    if not container then return false end
    local kind = container:getType()
    if kind == "inventorymale" or kind == "inventoryfemale" then return true end
    local parent = container:getParent()
    return parent ~= nil and instanceof(parent, "IsoDeadBody")
end

ISInventoryPaneContextMenu.equipWeapon = function(weapon, primary, twoHands, player, alwaysTurnOn)
    local container = weapon and weapon:getContainer()
    if not isCorpseContainer(container) then
        return originalEquipWeapon(weapon, primary, twoHands, player, alwaysTurnOn)
    end

    -- Viewpoint's corpse-loot destination patches normally route transfers to
    -- the selected bag. Vanilla's queued ISEquipWeaponAction validates the
    -- weapon by looking it up in the character's root inventory, so preserve
    -- the vanilla destination for this equip operation.
    local previous = ChilaSeda_EquipFromCorpse
    ChilaSeda_EquipFromCorpse = true
    local results = { pcall(originalEquipWeapon,
        weapon, primary, twoHands, player, alwaysTurnOn) }
    ChilaSeda_EquipFromCorpse = previous

    if not results[1] then error(results[2], 0) end
    local unpackValues = table.unpack or unpack
    return unpackValues(results, 2)
end

print("[ChilaSeda_ViewpointCorpseEquip] equips from corpse into the root inventory before hand attachment")
