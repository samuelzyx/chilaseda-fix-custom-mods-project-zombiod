print("[BF-VERSION] v2.4.16 loaded")
pcall(require, "ISUI/ISToolTipInv")
pcall(require, "Hotbar/ISHotbar")

-- Load localization module
local Locale = require("BetterFlashlights/Locale")
local BF_ContextGroup = require("BF_ContextGroup")

local TORCH_WEAPON_TYPES = {
    "Base.TorchArmy1",
    "Base.TorchArmy2",
    "Base.Torch7"
}

local TORCH_LIGHT_TYPES = {
    "Base.HandTorch_Army1",
    "Base.HandTorch_Army2",
    "Base.HandTorch_ManLite",
    "Base.HandTorch_CK_LED",
    "Base.Torch1", "Base.Torch2", "Base.Torch3",
    "Base.Torch4", "Base.Torch5", "Base.Torch6",
    "Base.BF_HeadLight",
    "Base.BF_EgenerexLite",
    "Base.BF_SpiffoLite",
    "Base.BF_OldFlashlight",
}
local BATTERY_FULL_TYPE = "Base.Battery"
local UPDATE_TICKS = 30
-- Battery drain is driven by IN-GAME time (Events.EveryOneMinute), never by
-- frame updates: OnPlayerUpdate runs ~60 times per second, so the old frame
-- based drain emptied a full battery in about a minute of real time.
-- One drainable use is spent every BF_MINUTES_PER_USE in-game minutes.
-- Measured in game with a temporary probe on Base.HandTorch (UseDelta 0.006):
-- vanilla spends exactly one drainable use every 10 in-game minutes
-- (100 -> 54.0 -> 53.4 -> 52.8 percent, 0.6 percent per step, 10 minutes apart).
local BF_MINUTES_PER_USE = 10
local BF_WEAPON_USE_DELTA = 0.007
local BF_WEAPON_DRAIN_PER_MINUTE = BF_WEAPON_USE_DELTA * 100.0 / BF_MINUTES_PER_USE
local BF_MIN_USABLE_CHARGE = 1.0   -- < 1%: батарея считается пустой (свет не горит, F не включает)
-- BF_DEAD_INSERT_MAX: порог "мёртвой" батареи при вставке.
-- Батарея с зарядом ≤ этому значению считается разряженной и вставляется как 0%.
local BF_DEAD_INSERT_MAX  = 1.0
-- Минимальный заряд извлечённой батареи (в %).
-- Движок PZ квантизует charge по UseDelta (0.007 = 0.7% = 1 use для Base.Battery).
-- Всё что ниже 1 use (0.7%) округляется до 0 uses и удаляется движком на тике/сейве.
-- Ставим 1.0% — гарантированно ≥ 1 use, переживает квантизацию и сохранение.
-- При повторной вставке: 1.0% ≤ BF_DEAD_INSERT_MAX (1.0) → treated as 0.
local BF_BATTERY_EPSILON = 1.0
-- IsoLightSource is radial, not a real TorchCone. Keep it compact and shifted
-- forward to imitate a cone without lighting a huge circle around the player.
local LIGHT_DISTANCE = 6
local LIGHT_STRENGTH = 0.35
local LIGHT_FORWARD_OFFSET = 1.0
-- Beam imitation: a few small radial sources chained along the facing direction
-- instead of one wide circle around the player (IsoLightSource has no cone).
local LIGHT_HALO_DISTANCE = 1      -- keep spill on the carrier's square faint
local LIGHT_BEAM_STEP = 2.0        -- tiles between the chained sources
local LIGHT_BEAM_RADII = { 3, 2 }  -- compact radius of each source ahead of the player
-- BASE_NAMES kept as emergency fallback only (if Locale fails completely)
local BASE_NAMES = {
    ["Base.TorchArmy1"] = "Military Flashlight",
    ["Base.TorchArmy2"] = "Military Flashlight",
    ["Base.Torch7"] = "Emergency Flashlight"
}
local BASE_MIN_DAMAGE = 0.65
local BASE_MAX_DAMAGE = 1.15

local tick = 0
local vanillaLightBindings = { "Equip/Turn On/Off Light Source" }
local disabledVanillaLightKeys = {}
local patchVanillaLightToggle


--- Mark weapon as broken: set flag and ensure condition ≥ 1 (engine must not destroy item)
-- Invariant: bfWeaponBroken == true ⇔ condition >= 1. Engine condition never reaches zero.
local function bfMarkBroken(item, md)
    if not item or not md then return end
    md.bfWeaponBroken = true
    md.isBroken = true
end

local function removeInventoryItem(inv, item)
    if not inv or not item then return false end
    local ok = false
    if inv.Remove then ok = pcall(inv.Remove, inv, item) end
    if not ok and inv.DoRemoveItem then ok = pcall(inv.DoRemoveItem, inv, item) end
    if not ok and inv.RemoveOneOf and item.getType then ok = pcall(inv.RemoveOneOf, inv, item:getType()) end
    if not ok and inv.RemoveOneOf then ok = pcall(inv.RemoveOneOf, inv, "Battery") end
    return ok == true
end

local function addInventoryItem(inv, fullType)
    if not inv or not inv.AddItem then return nil end
    local ok, result = pcall(inv.AddItem, inv, fullType)
    if ok then return result end
    ok, result = pcall(inv.AddItem, inv, "Battery")
    if ok then return result end
    print("[BetterFlashlights] ERROR: failed to add item " .. tostring(fullType) .. ": " .. tostring(result))
    return nil
end

local function safeCall(obj, method, ...)
    if not obj or not obj[method] then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    if ok then return value end
    return nil
end

local function isTorchWeapon(item)
    if not item then return false end
    local fullType = safeCall(item, "getFullType")
    if not fullType then return false end
    for _, weaponType in ipairs(TORCH_WEAPON_TYPES) do
        if fullType == weaponType then return true end
    end
    return false
end

local function isTorchLight(item)
    if not item then return false end
    local fullType = safeCall(item, "getFullType")
    if not fullType then return false end
    for _, t in ipairs(TORCH_LIGHT_TYPES) do
        if fullType == t then return true end
    end
    return false
end

local function getHeldTorchWeapon(player)
    if not player then return nil end
    local primary = player:getPrimaryHandItem()
    if isTorchWeapon(primary) then return primary end
    local secondary = player:getSecondaryHandItem()
    if isTorchWeapon(secondary) then return secondary end
    return nil
end

local function setVanillaLightBindingsDisabled(disabled)
    local core = getCore and getCore() or nil
    if not core then return end

    for _, bindingName in ipairs(vanillaLightBindings) do
        if disabled == true then
            local key = safeCall(core, "getKey", bindingName)
            if type(key) == "number" and key ~= 0 then
                if disabledVanillaLightKeys[bindingName] == nil then
                    disabledVanillaLightKeys[bindingName] = key
                end
                safeCall(core, "setKey", bindingName, 0)
            end
        else
            local oldKey = disabledVanillaLightKeys[bindingName]
            if type(oldKey) == "number" then
                safeCall(core, "setKey", bindingName, oldKey)
                disabledVanillaLightKeys[bindingName] = nil
            elseif disabledVanillaLightKeys[bindingName] == nil and bindingName == "Equip/Turn On/Off Light Source" then
                -- Heal a binding that an older mod version left zeroed in the
                -- config (this happened when the game was closed while a torch
                -- weapon was held). Runs at most once per session.
                local cur = safeCall(core, "getKey", bindingName)
                if type(cur) == "number" and cur == 0 then
                    safeCall(core, "setKey", bindingName, Keyboard and Keyboard.KEY_F or 33)
                end
                disabledVanillaLightKeys[bindingName] = false
            end
        end
    end
end

local function updateVanillaLightKeyBinding(player)
    -- Never rewrite the player's real key bindings. The vanilla toggle is
    -- suppressed inside the ItemBindingHandler.toggleLight patch instead, so
    -- whatever key the player bound keeps working for mod lights as well.
    setVanillaLightBindingsDisabled(false)
end

local function clampCharge(v)
    if type(v) ~= "number" then return 0 end
    if v < 0 then return 0 end
    if v > 100 then return 100 end
    return v
end

local function getDrainableCharge(item)
    if not item then return 0 end
    -- For DrainableComboItem, getCurrentUsesFloat()/getDelta() is the current
    -- charge (0..1), while getUsedDelta() is the script consumption step.
    -- Base.Battery has UseDelta=0.007, so reading getUsedDelta() first made
    -- every inserted battery look like 0.7% and BF_DEAD_INSERT_MAX treated it
    -- as empty. Prefer the current charge and keep getUsedDelta only as a
    -- last-resort compatibility fallback for odd modded drainables.
    local v = safeCall(item, "getCurrentUsesFloat")
    if type(v) ~= "number" then v = safeCall(item, "getDelta") end
    if type(v) ~= "number" then v = safeCall(item, "getUsedDelta") end
    if type(v) ~= "number" then return 0 end
    return clampCharge(v * 100.0)
end

local function setDrainableCharge(item, chargePercent)
    if not item then return end
    local delta = clampCharge(chargePercent or 0) / 100.0
    -- Do NOT call setUsedDelta() here: in PZ drainables it mutates the
    -- per-use drain step, not current charge. 2.4.5 accidentally wrote the
    -- remaining charge into UseDelta, so the next tick could drain almost the
    -- whole battery. Only update the current charge fields.
    safeCall(item, "setDelta", delta)
    safeCall(item, "setCurrentUsesFloat", delta)
    if item.transmitModData then pcall(item.transmitModData, item) end
end

local function getLocalizedBaseName(item)
    -- If no item provided, return generic weapon name from Locale (with fallback)
    if not item then
        return Locale.t("ui.TorchArmyWeaponName") or Locale.tr("TorchArmyWeaponName", "UI_Translation_TorchArmyWeaponName") or "Military Flashlight "
    end
    
    local fullType = safeCall(item, "getFullType")
    if fullType then
        -- Try to get localized name from JSON by fullType
        local name = Locale.getItemName(fullType)
        if name then return name end
    end
    
    -- Fallback: generic weapon name from Locale, then vanilla getText, then hardcoded
    return Locale.t("ui.TorchArmyWeaponName") or Locale.tr("TorchArmyWeaponName", "UI_Translation_TorchArmyWeaponName") or "Military Flashlight "
end

local function displayNameWithCharge(item, md, broken)
    local md = md or (item and item.getModData and item:getModData()) or {}
    -- locale FIRST: reads locale/<lang>.json items[fullType].name
    local baseName = getLocalizedBaseName(item)
    if not baseName or baseName == "" then baseName = md.bfBaseName end
    if not baseName or baseName == "" then baseName = item and item.getName and item:getName() end
    baseName = baseName or "Unknown"
    local charge = math.floor(clampCharge(md.batteryCharge or 0))
    return baseName .. " [" .. tostring(charge) .. "%]"
end

local function itemID(item)
    return safeCall(item, "getID") or 0
end

local function ensureModData(item)
    if not isTorchWeapon(item) or not item.getModData then return nil end
    local md = item:getModData()
    if not md then return nil end
    if type(md.batteryCharge) ~= "number" then md.batteryCharge = 100.0 else md.batteryCharge = clampCharge(md.batteryCharge) end
    if type(md.isLightOn) ~= "boolean" then md.isLightOn = false end
    if type(md.isBroken) ~= "boolean" then md.isBroken = false end
    if type(md.bfHasBattery) ~= "boolean" then md.bfHasBattery = (md.batteryCharge or 0) > 0 end
    -- Snap-latch: если charge > 0, батарея точно внутри — фиксируем флаг,
    -- чтобы после разряда до 0% пункт «Извлечь батарею» не пропадал.
    if (md.batteryCharge or 0) > 0 and md.bfHasBattery ~= true then
        md.bfHasBattery = true
    end
    if type(md.bfBatteryDelta) == "number" then md.batteryCharge = clampCharge(md.bfBatteryDelta * 100.0); md.bfBatteryDelta = nil end
    -- NOTE: bfWeaponBroken migration removed — bfWeaponBroken is the canonical "broken" flag.
    -- isBroken is kept for backward compat but is NOT the source of truth.
    
    local fullType = safeCall(item, "getFullType")
    -- Use localized name for bfBaseName cache (falls back to BASE_NAMES if Locale fails)
    local baseName = fullType and Locale.getItemName(fullType) or Locale.t("ui.TorchArmyWeaponName") or BASE_NAMES[fullType] or "Military Flashlight "
    md.bfBaseName = md.bfBaseName or baseName
    md.bfBaseMinDamage = md.bfBaseMinDamage or BASE_MIN_DAMAGE
    md.bfBaseMaxDamage = md.bfBaseMaxDamage or BASE_MAX_DAMAGE
    return md
end

local function transmit(item)
    if item and item.transmitModData then pcall(item.transmitModData, item) end
end

local function ensureModDataLight(item)
    if not item or not item.getModData then return nil end
    local md = item:getModData()
    if not md then return nil end
    if type(md.bfHasBattery) ~= "boolean" then md.bfHasBattery = false end
    -- FIX: если у фонаря есть заряд, батарея точно внутри — защёлкиваем флаг,
    -- чтобы после разряда до 0% пункт «Извлечь батарею» не пропадал.
    -- Без transmit: эта функция вызывается часто (render, onContext, updateAllPlayerLights),
    -- transmit вызывается только в путях insert/extract, что достаточно для MP-синхронизации.
    if (getDrainableCharge(item) or 0) > 0 and md.bfHasBattery ~= true then
        md.bfHasBattery = true
    end
    -- Vanilla-only path (2.4.11+): the mod no longer adds Insert/Extract
    -- Battery rows for drainable lights. The only way the battery leaves
    -- the flashlight now is the vanilla RemoveBattery recipe, which sets
    -- UsedDelta to 0. Snap bfHasBattery back to false on empty so the
    -- canonical flag never goes stale.
    if (getDrainableCharge(item) or 0) <= 0 and md.bfHasBattery == true then
        md.bfHasBattery = false
    end
    return md
end

-- MP: registry of light sources per player (replaces single activeLight*)
local torchLights = {}   -- [key] = { light=, cell=, x=, y=, z= }
local bfRemoteLightState = {}   -- [onlineID] = true/false, pushed by the owner client through the server

local function lightKey(player)
    local id = safeCall(player, "getOnlineID")
    if type(id) == "number" and id >= 0 then return "id:" .. id end
    return "pn:" .. tostring(safeCall(player, "getPlayerNum") or 0)
end

local function removePlayerLight(key)
    local rec = torchLights[key]
    if rec and rec.cell then
        local list = rec.lights or (rec.light and { rec.light }) or {}
        for i = 1, #list do
            local l = list[i]
            if l then
                if rec.cell.removeLamppost then pcall(rec.cell.removeLamppost, rec.cell, l)
                elseif rec.cell.removeLightSource then pcall(rec.cell.removeLightSource, rec.cell, l) end
            end
        end
    end
    torchLights[key] = nil
end

local function removeTorchLight()
    local me = getPlayer()
    if me then removePlayerLight(lightKey(me)) end
end

local function forward(player)
    local fd = safeCall(player, "getForwardDirection")
    local x = fd and (safeCall(fd, "getX") or fd.x)
    local y = fd and (safeCall(fd, "getY") or fd.y)
    if type(x) == "number" and type(y) == "number" and (x ~= 0 or y ~= 0) then
        -- Keep the world direction from IsoGameCharacter. Better Flashlights' own
        -- projection uses this vector directly; negating it points the chain behind Jill.
        return x, y
    end
    local dir = tostring(safeCall(player, "getDir") or "")
    x, y = 0, 0
    if dir:find("N") then y = -1 elseif dir:find("S") then y = 1 end
    if dir:find("W") then x = -1 elseif dir:find("E") then x = 1 end
    if x == 0 and y == 0 then y = 1 end
    return x, y
end

-- Stage 2 switch for the per-tick MP player light system (EXPERIMENTAL, enabled in 2.4.3)
local BF_ENABLE_MP_PLAYER_LIGHT = true   -- stage 2: EXPERIMENTAL (2.4.3), remote-player light in MP
-- Stage 1: the LOCAL player light is always allowed (SP and MP), client-side visual only.
-- Stage 2: remote player light requires BF_ENABLE_MP_PLAYER_LIGHT plus the distance, z level and count limits below.
local function bfPlayerLightAllowed(player)
    local me = getPlayer()
    if player and me and lightKey(player) == lightKey(me) then return true end
    if BF_ENABLE_MP_PLAYER_LIGHT then return true end
    return (not isClient()) and (not isServer())
end

local function applyPlayerLight(player, on)
    if not bfPlayerLightAllowed(player) then return end
    local key = lightKey(player)
    if not on then removePlayerLight(key); return end
    local cell = getCell()
    if not cell or not IsoLightSource then return end
    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local lz = math.floor(player:getZ())
    local fx, fy = forward(player)

    local pSquare = cell.getGridSquare and cell:getGridSquare(px, py, lz) or nil
    local pRoom = nil
    if pSquare then
        local okp, rid = pcall(function() return pSquare:getRoomID() end)
        if okp then pRoom = rid end
    end

    -- Do not tear down and recreate the light chain on every third tick. Keep it while the player
    -- stays on the same tile and faces the same direction; repeated remove/add cycles were visible
    -- as a strobe in Viewpoint's asynchronous lighting render.
    local old = torchLights[key]
    local qx = math.floor(fx * 100 + 0.5)
    local qy = math.floor(fy * 100 + 0.5)
    if old and old.cell == cell and old.x == px and old.y == py and old.z == lz
        and old.qx == qx and old.qy == qy then
        return
    end
    removePlayerLight(key)

    local lights = {}
    local function addSource(sx, sy, radius)
        local ok, light = pcall(IsoLightSource.new, sx, sy, lz, 1.0, 0.92, 0.75, radius)
        if ok and light then
            if cell.addLamppost then pcall(cell.addLamppost, cell, light)
            elseif cell.addLightSource then pcall(cell.addLightSource, cell, light) end
            lights[#lights+1] = light
        end
    end

    -- small halo so the carrier does not stand in the dark
    addSource(px, py, LIGHT_HALO_DISTANCE)

    -- chained sources ahead imitate a beam instead of one big circle; the chain
    -- stops at the first missing square or room change, so it never lights through walls
    for i = 1, #LIGHT_BEAM_RADII do
        local d = LIGHT_FORWARD_OFFSET + LIGHT_BEAM_STEP * i
        local bx = math.floor(player:getX() + fx * d)
        local by = math.floor(player:getY() + fy * d)
        local sq = cell.getGridSquare and cell:getGridSquare(bx, by, lz) or nil
        if not sq then break end
        local okf, fRoom = pcall(function() return sq:getRoomID() end)
        if not okf or fRoom ~= pRoom then break end
        addSource(bx, by, LIGHT_BEAM_RADII[i])
    end

    if #lights > 0 then
        torchLights[key] = {
            lights = lights, cell = cell, x = px, y = py, z = lz, qx = qx, qy = qy,
        }
    end
end

-- weapon light for any player (replicated item in hand)
local function getHeldTorchWeaponAny(player)
    local p = safeCall(player, "getPrimaryHandItem")
    if isTorchWeapon(p) then return p end
    local s = safeCall(player, "getSecondaryHandItem")
    if isTorchWeapon(s) then return s end
    return nil
end

local function weaponLightOn(item)
    if not item or not item.getModData then return false end
    local md = item:getModData()
    return md and md.isLightOn == true and md.bfWeaponBroken ~= true and (md.batteryCharge or 0) >= BF_MIN_USABLE_CHARGE
end

-- active belt-attached torch light for other players
local function getActiveBeltTorchLight(player)
    local attached = safeCall(player, "getAttachedItems")
    if not attached or not attached.size then return nil end
    for i = 0, attached:size() - 1 do
        local ai = safeCall(attached, "getItemByIndex", i)
        if not ai and attached.get then ai = safeCall(attached, "get", i) end
        if isTorchLight(ai) and safeCall(ai, "isActivated") == true then return ai end
    end
    return nil
end


-- Per-item drain step (fraction 0..1) taken from the item script's UseDelta,
-- so each flashlight drains at its own designed rate (BF_OldFlashlight 0.0001,
-- HandTorch 0.006, etc.). Falls back to a sane default if the script value is missing.
local BF_DEFAULT_USE_DELTA = 0.006
local function getItemUseDelta(item)
    local ud = safeCall(item, "getUseDelta")
    if type(ud) ~= "number" or ud <= 0 then
        local script = safeCall(item, "getScriptItem")
        ud = script and safeCall(script, "getUseDelta") or nil
    end
    if type(ud) ~= "number" or ud <= 0 then ud = BF_DEFAULT_USE_DELTA end
    return ud
end

-- Fix (Lancer report): drain belt/holster-attached activated flashlights.
-- The vanilla engine only ticks DrainableComboItem drain while the light is held
-- in a hand (ticksPerEquipUse), so a torch attached to the belt stays charged
-- forever. Mirror vanilla by applying the item's own UseDelta once per
-- UPDATE_TICKS (matches the default ticksPerEquipUse = 30 equip-use interval).
-- Only the LOCAL player's attached items are drained, to avoid double-drain in MP
-- (every client would otherwise drain the same remote item).
local function drainBeltLights(player)
    if not player then return end
    local me = getPlayer()
    if me and player ~= me then return end
    -- A torch held in hand is drained by the vanilla engine already; only
    -- belt/holster-attached items are handled here (getAttachedItems excludes hands).
    local attached = safeCall(player, "getAttachedItems")
    if not attached or not attached.size then return end
    for i = 0, attached:size() - 1 do
        local ai = safeCall(attached, "getItemByIndex", i)
        if not ai and attached.get then ai = safeCall(attached, "get", i) end
        if isTorchLight(ai) and safeCall(ai, "isActivated") == true then
            local charge = getDrainableCharge(ai)   -- remaining %, 0..100
            if charge > 0 then
                local drainPercent = getItemUseDelta(ai) * 100.0 / BF_MINUTES_PER_USE
                local newCharge = clampCharge(charge - drainPercent)
                setDrainableCharge(ai, newCharge)    -- writes delta + transmitModData
                if newCharge <= 0 then
                    -- Dead battery: turn the light off so it stops projecting
                    -- and stops being reported as an active belt light.
                    safeCall(ai, "setActivated", false)
                    local md = ensureModDataLight(ai)
                    if md then md.bfBatteryDelta = 0 end
                    if ai.transmitModData then pcall(ai.transmitModData, ai) end
                end
            end
        end
    end
end

local function syncState(item)
    local md = ensureModData(item)
    if not md then return end
    if isClient() then
        sendClientCommand("BetterFlashlights", "SyncTorchArmyWeaponState", {
            itemID = itemID(item), batteryCharge = md.batteryCharge,
            -- bfWeaponBroken is the canonical broken flag; md.isBroken is a legacy
            -- field kept only for backward compat. Sending the legacy one made the
            -- server mark healthy torches as broken and switch the light off again.
            isLightOn = md.isLightOn == true and 1 or 0, isBroken = md.bfWeaponBroken == true and 1 or 0,
            condition = safeCall(item, "getCondition") or 0,
        })
    else
        transmit(item)
    end
end

local function setDamage(item, minD, maxD)
    safeCall(item, "setMinDamage", minD)
    safeCall(item, "setMaxDamage", maxD)
    local script = safeCall(item, "getScriptItem")
    safeCall(script, "setMinDamage", minD)
    safeCall(script, "setMaxDamage", maxD)
end

local function applyBroken(item, md)
    safeCall(item, "setName", displayNameWithCharge(item, md, true))
    safeCall(item, "setDisplayCategory", "Junk")
    setDamage(item, 0, 0)
    safeCall(item, "setBroken", true)
end

local function applyRepaired(item, md)
    safeCall(item, "setName", displayNameWithCharge(item, md, false))
    safeCall(item, "setDisplayCategory", "Weapon")
    setDamage(item, md.bfBaseMinDamage or BASE_MIN_DAMAGE, md.bfBaseMaxDamage or BASE_MAX_DAMAGE)
end

-- Public: rewrite the "[NN%]" part of a weapon torch's name from its current modData.
--
-- WHY IT IS EXPORTED: the percentage lives in the item NAME, and the name is only rewritten from
-- updateBrokenState, which runs for the torch in the player's HANDS. A torch burning on the ground is
-- drained by BF_FloorLights (and by BF_ServerCommands in MP), so its charge dropped while the label kept
-- the old number - visible in the "floor" container, where the item name is on screen. Picking it up
-- rebuilt the name and it looked correct again, which is exactly what the playtest reported. The floor
-- light code calls this right after each drain.
--
-- 2.4.13: ALL FOUR battery branches (insert/extract, SP/MP) also route through this
-- instead of calling applyRepaired directly. Two reasons: the SP extract branch used to
-- leave the stale "[100%]" label on a battery-less torch until the next equip, and the
-- inventory STACKS items with equal names, so two identical torches with stale labels
-- merged into one slot; and applyRepaired on a BROKEN torch flipped it back to the
-- Weapon category and restored its damage until the next equip - this wrapper keeps a
-- broken torch in Junk instead.
function BF_RefreshWeaponFlashlightName(item)
    if not isTorchWeapon(item) then return false end
    local md = ensureModData(item)
    if not md then return false end
    if md.bfWeaponBroken == true then applyBroken(item, md) else applyRepaired(item, md) end
    return true
end

local function updateBrokenState(item, doSync)
    local md = ensureModData(item)
    if not md then return end
    local condition = safeCall(item, "getCondition") or 0
    local nativeBroken = safeCall(item, "isBroken") == true
    if (nativeBroken or condition <= 0) and md.bfWeaponBroken ~= true then
        -- Grace period: skip re-break right after ApplyRepair
        if md.bfRepairGraceUntil and tick < md.bfRepairGraceUntil then
            return
        end
        bfMarkBroken(item, md)
        md.isLightOn = false
        applyBroken(item, md)
        removeTorchLight()
        transmit(item)
        syncState(item)
    elseif md.bfWeaponBroken == true then
        applyBroken(item, md)
    else
        applyRepaired(item, md)
    end
end

local function toggleTorch(player)
    if not player then return end
    updateVanillaLightKeyBinding(player)
    if patchVanillaLightToggle then patchVanillaLightToggle() end
    local item = getHeldTorchWeapon(player)
    if not isTorchWeapon(item) then return end
    local md = ensureModData(item)
    updateBrokenState(item, true)
    if md.bfWeaponBroken == true or md.batteryCharge < BF_MIN_USABLE_CHARGE then
        md.isLightOn = false
        safeCall(player, "playSound", "FlashlightOff")
        removeTorchLight()
        syncState(item)
        return
    end
    md.isLightOn = not md.isLightOn
    safeCall(player, "playSound", md.isLightOn and "FlashlightOn" or "FlashlightOff")
    transmit(item)
    syncState(item)
    -- immediate light update for instant feedback
    applyPlayerLight(player, weaponLightOn(item))
end

local BF_LIGHT_BINDING = "Equip/Turn On/Off Light Source"

-- Follow the player's own key binding instead of a hardcoded F.
local function isLightToggleKey(key)
    local core = getCore and getCore() or nil
    if core then
        local ok, res = pcall(function() return core:isKey(BF_LIGHT_BINDING, key) end)
        if ok and type(res) == "boolean" then return res end
        local ok2, bound = pcall(function() return core:getKey(BF_LIGHT_BINDING) end)
        if ok2 and type(bound) == "number" and bound ~= 0 then return key == bound end
    end
    local fKey = Keyboard and Keyboard.KEY_F or 33
    return key == fKey
end

local function onKeyPressed(key)
    if isLightToggleKey(key) then toggleTorch(getPlayer()) end
end

local function resolve(entry)
    if not entry then return nil end
    if type(entry) ~= "table" then return entry end
    local ok, sub = pcall(function() return entry.items and entry.items[1] end)
    if ok and sub then return sub end
    return entry
end

-- 2.4.13 (animecentral suggestion): when several batteries are carried, insert
-- the one with the MOST charge instead of whichever the inventory hands back
-- first. getFirstTypeRecurse has no "best" variant, so the inventory is
-- walked by hand. RECURSIVE since the follow-up playtest: getItems() lists
-- only the items of ONE container, so the first version never saw a battery
-- inside a bag or backpack (its "including bags" comment was wrong) - and the
-- weapon branch requestInsert had just been switched onto it, silently
-- losing the batteries carried in a backpack. Bags are opened through
-- instanceof(item, "InventoryContainer") + getInventory(), the same pair
-- vanilla uses for recursive container walks (e.g. Vehicles.lua). Depth is
-- capped (a bag in a bag in a backpack is enough for anyone) and every
-- engine call goes through pcall/safeCall as everywhere in this file.
local BF_BATTERY_SEARCH_DEPTH = 4
local function findBestBatteryIn(inv, depth)
    if not inv or not inv.getItems or depth > BF_BATTERY_SEARCH_DEPTH then return nil, -1 end
    local okItems, items = pcall(inv.getItems, inv)
    if not okItems or not items then return nil, -1 end
    local best, bestCharge = nil, -1
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            local fullType = safeCall(it, "getFullType")
            if fullType == BATTERY_FULL_TYPE then
                local charge = getDrainableCharge(it)
                if type(charge) == "number" and charge > bestCharge then
                    best, bestCharge = it, charge
                end
            end
            if depth < BF_BATTERY_SEARCH_DEPTH then
                local okInst, isBag = pcall(instanceof, it, "InventoryContainer")
                if okInst and isBag == true then
                    local sub = safeCall(it, "getInventory")
                    if sub then
                        local subBest, subCharge = findBestBatteryIn(sub, depth + 1)
                        if subBest and subCharge > bestCharge then
                            best, bestCharge = subBest, subCharge
                        end
                    end
                end
            end
        end
    end
    return best, bestCharge
end

local function findBestBattery(inv)
    local best = findBestBatteryIn(inv, 0)
    return best
end

-- 2.4.13: findBestBattery can return a battery from INSIDE a bag, so it can
-- no longer be removed with removeInventoryItem(playerInv, ...) - that only
-- deletes from the root inventory. Take the battery's own container and
-- remove it there, mirroring how vanilla takes recipe inputs out of bags.
local function removeBatteryItem(battery)
    if not battery then return false end
    local cont = safeCall(battery, "getContainer")
    if not cont then return false end
    local ok = false
    if cont.Remove then ok = pcall(cont.Remove, cont, battery) end
    if not ok and cont.DoRemoveItem then ok = pcall(cont.DoRemoveItem, cont, battery) end
    return ok == true
end

local function requestInsert(player, item)
    if not isTorchWeapon(item) then return end
    -- MP: inventory is client-authoritative — remove battery on CLIENT,
    -- then send command for server status sync only.
    if isClient() then
        local inv = player:getInventory()
        local battery = findBestBattery(inv)
        if not battery then return end
        local insertedCharge = getDrainableCharge(battery)
        if insertedCharge <= BF_DEAD_INSERT_MAX then insertedCharge = 0 end
        removeBatteryItem(battery)
        -- Apply the inserted charge locally at once: in MP the client owns the
        -- item it holds and drains it (see bfEveryOneMinute), so stale local
        -- modData means the flashlight never drains after a battery swap.
        local mdLocal = ensureModData(item)
        if mdLocal then
            mdLocal.batteryCharge = insertedCharge
            mdLocal.isLightOn = false
            mdLocal.bfHasBattery = true
            -- Rebuild the "[NN%]" label through the wrapper: a BROKEN torch
            -- must stay in Junk instead of being "repaired" by a battery swap.
            BF_RefreshWeaponFlashlightName(item)
        end
        sendClientCommand("BetterFlashlights", "InsertTorchArmyWeaponBattery", {
            itemID = itemID(item),
            charge = insertedCharge,
        })
        return
    end
    local inv = player:getInventory()
    local battery = findBestBattery(inv)
    if not battery then return end
    local insertedCharge = getDrainableCharge(battery)
    if insertedCharge <= BF_DEAD_INSERT_MAX then insertedCharge = 0 end
    removeBatteryItem(battery)
    local md = ensureModData(item)
    md.batteryCharge = insertedCharge; md.isLightOn = false; md.bfHasBattery = true
    BF_RefreshWeaponFlashlightName(item)
    transmit(item)
end

local function requestExtract(player, item)
    if not isTorchWeapon(item) then return end
    local md = ensureModData(item)
    if not (md and (md.bfHasBattery == true or md.batteryCharge > 0)) then return end
    local extractedCharge = clampCharge(md.batteryCharge)
    if isClient() then
        -- MP: server creates battery (authoritative) and transmits to client.
        -- Client only sends charge so server knows what to put on the battery.
        -- Mirror the removal locally at once: the client owns the charge of the
        -- torch it holds, so it must not wait for a server push to show 0%.
        md.batteryCharge = 0
        md.isLightOn = false
        md.bfHasBattery = false
        removeTorchLight()
        BF_RefreshWeaponFlashlightName(item)
        transmit(item)
        sendClientCommand("BetterFlashlights", "ExtractTorchArmyWeaponBattery", {
            itemID = itemID(item),
            charge = extractedCharge,
        })
        return
    end
    -- SP: local mutation + create battery directly
    md.batteryCharge = 0; md.isLightOn = false; md.bfHasBattery = false
    removeTorchLight()
    -- 2.4.13: rebuild the name HERE. The old SP branch was the only one of the
    -- four battery paths that never refreshed the label, so "[100%]" survived on
    -- a battery-less torch until the next equip - and since the inventory stacks
    -- items with equal names, two identical torches with stale labels merged
    -- into one slot (playtest find, 2026-09-13).
    BF_RefreshWeaponFlashlightName(item)
    transmit(item)
    local inv = player:getInventory()
    local battery = inv and addInventoryItem(inv, BATTERY_FULL_TYPE)
    if battery then
        setDrainableCharge(battery, math.max(extractedCharge, BF_BATTERY_EPSILON))
    end
end

-- 2.4.13: runs for drainable lights through the redirected vanilla
-- InsertBattery row (see redirectVanillaInsertBattery below). Picks the
-- FULLEST battery via findBestBattery (recursive into bags) - the vanilla
-- HandcraftLogic takes whichever battery its input scan finds first.
local function requestInsertLight(player, item)
    if not isTorchLight(item) then return end
    local md = ensureModDataLight(item)
    if not md then return end
    -- Vanilla parity: the InsertBattery recipe only accepts an EMPTY
    -- flashlight (flags[IsEmpty] on its input line).
    if md.bfHasBattery == true then return end
    local inv = player:getInventory()
    local battery = findBestBattery(inv)
    if not battery then return end
    local insertedCharge = getDrainableCharge(battery)
    if insertedCharge <= BF_DEAD_INSERT_MAX then insertedCharge = 0 end
    if isClient() then
        -- MP: inventory is client-authoritative — remove battery on CLIENT,
        -- then send command for server status sync only.
        removeBatteryItem(battery)
        sendClientCommand("BetterFlashlights", "InsertTorchLightBattery", {
            itemID = itemID(item),
            charge = insertedCharge,
        })
        return
    end
    -- SP: local mutation
    removeBatteryItem(battery)
    md.bfHasBattery   = true
    md.bfBatteryDelta = insertedCharge / 100.0
    setDrainableCharge(item, insertedCharge)
    if item.transmitModData then pcall(item.transmitModData, item) end
end

local function requestExtractLight(player, item)
    if not isTorchLight(item) then return end
    local md = ensureModDataLight(item)
    if not md then return end
    local extractedCharge = getDrainableCharge(item)
    if type(extractedCharge) ~= "number" then extractedCharge = (md.bfBatteryDelta or 0) * 100.0 end
    extractedCharge = clampCharge(extractedCharge)
    if isClient() then
        -- MP: server creates battery (authoritative) and transmits to client.
        -- Client only sends charge so server knows what to put on the battery.
        sendClientCommand("BetterFlashlights", "ExtractTorchLightBattery", {
            itemID = itemID(item),
            charge = extractedCharge,
        })
        return
    end
    -- SP: local mutation + create battery directly
    md.bfHasBattery = false
    md.bfBatteryDelta = nil
    setDrainableCharge(item, 0)
    if item.transmitModData then pcall(item.transmitModData, item) end
    local inv = player:getInventory()
    local battery = inv and addInventoryItem(inv, BATTERY_FULL_TYPE)
    if battery then
        setDrainableCharge(battery, math.max(extractedCharge, BF_BATTERY_EPSILON))
    end
end

-- Dismantle light-type flashlight: consumes flashlight + screwdriver, outputs ElectronicsScrap
-- (screwdriver is kept, only flashlight is destroyed)
local BF_DismantleAction = ISBaseTimedAction:derive("BF_DismantleAction")

function BF_DismantleAction:isValid()
    return self.item ~= nil and (isTorchLight(self.item) or isTorchWeapon(self.item))
end

function BF_DismantleAction:waitToStart()
    return false
end

function BF_DismantleAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function BF_DismantleAction:getDuration()
    return 150
end

function BF_DismantleAction:start()
    self.item:setJobType(Locale.tr("BF_DismantleFlashlight", "UI_Translation_BF_DismantleFlashlight") or "Dismantle Flashlight")
    self:setActionAnim("Craft")
    self:setOverrideHandModels(nil, nil)
end

function BF_DismantleAction:stop()
    ISBaseTimedAction.stop(self)
    if self.item then self.item:setJobDelta(0.0) end
end

function BF_DismantleAction:perform()
    if self.item then self.item:setJobDelta(0.0) end
    local inv = self.character:getInventory()
    -- Mirror the recipe BF_DismantleTorchWeapon OnCreate
    -- (BetterFlashlights_recipecode.lua:337) for the mod row: if the
    -- weapon had a battery inside, return it with the saved charge.
    -- Always also drop the recipe's electronics scrap, and award the
    -- 2 XP Electricity the recipe's xpAward specifies.
    local function bfLocalDismantle()
        if not inv then return end
        local md = isTorchWeapon(self.item) and ensureModData(self.item) or nil
        -- Battery return only when one was installed.
        if md and md.bfHasBattery == true then
            local charge = clampCharge(type(md.batteryCharge) == "number" and md.batteryCharge or 0)
            local battery = addInventoryItem(inv, BATTERY_FULL_TYPE)
            if battery and charge > 0 then
                setDrainableCharge(battery, charge)
            end
            -- Wipe the modData so a stacked dismantle never reads the
            -- old charge on the next craft.
            md.bfHasBattery = nil
            md.batteryCharge = nil
            md.isLightOn = nil
            if self.item.transmitModData then pcall(self.item.transmitModData, self.item) end
        end
        -- Scrap and XP are unconditional: the recipe BF_DismantleTorchWeapon
        -- lists ElectronicsScrap in its outputs and carries
        -- xpAward = Electricity:2, neither of which depends on a battery
        -- being inside. Keeping the AddXP call inside the battery branch
        -- (as it was before) meant an empty torch gave scrap but no XP.
        addInventoryItem(inv, "Base.ElectronicsScrap")
        local perk = Perks and Perks.Electricity
        local xpObj = self.character and self.character.getXp and self.character:getXp() or nil
        if perk and xpObj and xpObj.AddXP then pcall(xpObj.AddXP, xpObj, perk, 2) end
        local cont = (self.item and self.item.getContainer and self.item:getContainer()) or inv
        if cont and cont.Remove then pcall(cont.Remove, cont, self.item) end
    end

    if isClient() then
        -- MP: the dismantle must be performed by the server. Removing
        -- the flashlight and creating the scrap on the client produces
        -- an item the server does not know about, so it cannot be
        -- dropped or moved until a relog resyncs the inventory. The
        -- server path also returns the battery and grants the XP.
        sendClientCommand(self.character, "BetterFlashlights", "DismantleFlashlight", {
            itemID = safeCall(self.item, "getID"),
            fullType = safeCall(self.item, "getFullType"),
        })
    else
        bfLocalDismantle()
    end
    ISBaseTimedAction.perform(self)
end

function BF_DismantleAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 150
    o.useProgressBar = true
    return o
end

local BF_BatteryAction = ISBaseTimedAction:derive("BF_BatteryAction")

function BF_BatteryAction:isValid()
    return self.item ~= nil and (isTorchWeapon(self.item) or isTorchLight(self.item))
end

function BF_BatteryAction:waitToStart()
    return false
end

function BF_BatteryAction:update()
    self.character:setMetabolicTarget(Metabolics.LightDomestic)
    if self.item then
        self.item:setJobDelta(self:getJobDelta())   -- радиалка на иконке
    end
end

function BF_BatteryAction:getDuration()
    return self.maxTime
end

function BF_BatteryAction:start()
    if self.item then
        if self.mode == "extract" then
            self.item:setJobType(Locale.tr("TorchExtractBattery", "UI_Translation_TorchExtractBattery") or "Extract Battery")
        else
            self.item:setJobType(Locale.tr("TorchInsertBattery", "UI_Translation_TorchInsertBattery") or "Insert Battery")
        end
    end
    self:setActionAnim("Craft")
    self:setOverrideHandModels(self.item, nil)
end

function BF_BatteryAction:stop()
    ISBaseTimedAction.stop(self)
    if self.item then
        self.item:setJobDelta(0.0)
    end
end

function BF_BatteryAction:perform()
    if self.item then self.item:setJobDelta(0.0) end
    if isTorchWeapon(self.item) then
        if self.mode == "extract" then requestExtract(self.character, self.item)
        else requestInsert(self.character, self.item) end
    else
        if self.mode == "extract" then requestExtractLight(self.character, self.item)
        else requestInsertLight(self.character, self.item) end
    end
    ISBaseTimedAction.perform(self)
end

function BF_BatteryAction:new(character, item, mode)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.mode = mode
    o.stopOnWalk = true
    o.stopOnRun = true
    -- Drainable rows follow the vanilla recipe timing (InsertBattery and
    -- RemoveBattery both carry time = 30); the weapon rows keep the mod's
    -- own pace of 120.
    if isTorchLight(item) then o.maxTime = 30 else o.maxTime = 120 end
    o.useProgressBar = true
    return o
end

local function queueWithEquip(p, item, action)
    if p:getPrimaryHandItem() ~= item then
        p:setPrimaryHandItem(item)  -- instant equip: no delay, no empty-hand animation
    end
    ISTimedActionQueue.add(action)
end

-- Filter vanilla "Remove Battery" / "Insert Battery" / "Dismantle simple
-- electronic item" recipe rows for all our light types.  In B42.20 getText
-- does NOT consult the Recipes.json table, so the rows cannot be found by
-- key lookup.  Locale.recipeName resolves the localized recipe titles (the
-- only path that consults Recipes.json in B42.20); matching against those
-- titles is language-safe.
--
-- Removing a row must keep ISContextMenu:calcHeight in sync: addOption
-- increments numOptions, so dropping the element from context.options alone
-- leaves a stranded empty slot at the bottom of the menu.  The three-step
-- shutdown (table.remove + numOptions-1 + calcHeight) lives in
-- BF_ContextGroup.removeOptionFromContext, mirroring vanilla
-- ISContextMenu:removeLastOption.
local function filterVanillaBatteryEntries(context, item)
    if not context or not context.options then return end
    -- Drainable lights are vanilla-only as of 2.4.11: the mod adds no rows
    -- for them, so nothing has to be filtered out of their menu. Only the
    -- three weapon lights get mod rows, and only their vanilla duplicates
    -- are suppressed here.
    local isWeapon = isTorchWeapon(item)
    if not isWeapon then return end

    -- Resolve the localized titles of the vanilla recipes once per menu build.
    -- For weapon lights the mod also suppresses the recipe
    -- BF_DismantleTorchWeapon's context-menu row and supplies its own
    -- (the recipe itself is kept for the crafting window and batch-craft).
    -- Drainable lights keep all vanilla rows because the mod does not
    -- add anything for them.
    local names = {}
    local namesCount = 0
    if Locale and Locale.recipeName then
        local keys
        if isWeapon then
            keys = { "InsertBattery", "RemoveBattery", "DismantleElectronics", "BF_DismantleTorchWeapon" }
        else
            keys = { "InsertBattery", "RemoveBattery", "DismantleElectronics" }
        end
        for _, key in ipairs(keys) do
            local n = Locale.recipeName(key)
            if n and n ~= "" then names[n] = true; namesCount = namesCount + 1 end
        end
    end
    if namesCount == 0 then names = nil end  -- early load: fall back to substring match

    for i = #context.options, 1, -1 do
        local opt = context.options[i]
        local name = opt and (opt.name or (type(opt) == "string" and opt) or "") or ""
        local hit = false
        if names then
            hit = name ~= "" and names[name]
        else
            local ln = string.lower(name)
            hit = ln:find("remove battery") or ln:find("insert battery")
                or ln:find("извлечь батаре") or ln:find("установить батаре")
                or ln:find("batterie entfernen") or ln:find("batterie einlegen")
                or ln:find("extraer bater") or ln:find("insertar bater")
                or ln:find("extraer la piles") or ln:find("insérer piles")
                or (ln:find("dismantle") and ln:find("electron"))
        end
        if hit then
            BF_ContextGroup.removeOptionFromContext(context, i)
        end
    end
end

-- Cached icon for the battery row, matching the vanilla submenu on
-- drainable lights (Slobodskoy confirmed 2026-09-01 that vanilla
-- addNewCraftingDynamicalContextMenu shows the battery icon for both
-- InsertBattery and RemoveBattery; the recipe has Base.Battery in its
-- outputs, so logic:getResultTexture() resolves to it).
-- We are not going through a craftRecipe here, so we look up the icon
-- ourselves: cache the result of instanceItem("Base.Battery") and read
-- getTex() from it. Falls back to the flashlight icon so the row is
-- never blank, the same way ISInventoryPaneContextMenu.lua:3390-3393
-- falls back to selectedItem:getTexture() when getResultTexture misses.
local bfBatteryIconCache = nil
local function getHandTorchIcon()
    local okManager, manager = pcall(getScriptManager)
    if not okManager or not manager then return nil end
    local okItem, scriptItem = pcall(manager.FindItem, manager, "Base.HandTorch")
    if not okItem or not scriptItem then return nil end
    local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
    return okTexture and texture or nil
end

local function getBatteryIcon()
    if bfBatteryIconCache ~= nil then return bfBatteryIconCache end
    if instanceItem then
        local ok, inst = pcall(instanceItem, "Base.Battery")
        if ok and inst and inst.getTex then
            local okT, tex = pcall(inst.getTex, inst)
            if okT and tex then
                bfBatteryIconCache = tex
                return tex
            end
        end
    end
    bfBatteryIconCache = false  -- sentinel: do not retry every right-click
    return nil
end

--- Screwdriver detection (sync with BF_RepairContextMenu.lua:hasScrewdriver).
--- Recursive via getFirstTypeRecurse for bags/backpacks.
local function hasScrewdriver(player)
    if not player then return false end
    local inv = player:getInventory()
    if not inv then return false end
    local ok, sd = pcall(function()
        return inv:getFirstTypeRecurse("Base.Screwdriver")
            or inv:getFirstTypeRecurse("Base.Screwdriver_Old")
            or inv:getFirstTypeRecurse("Base.Screwdriver_Improvised")
    end)
    return ok and sd ~= nil
end

-- 2.4.13: repaint the icons of the vanilla battery rows ("Insert Battery"
-- and "Remove Battery") on the drainable lights.  Vanilla picks the row icon
-- in ISInventoryPaneContextMenu.lua:3390 as
--     logic:getResultTexture() or selectedItem:getTexture()
-- RemoveBattery: the recipe outputs Base.Battery, but the crafting logic
-- occasionally hands back no texture for it and the row falls back to the
-- icon of the flashlight that was right-clicked (reported by Slobodskoy
-- 2026-09-03 for all 14 drainable lights, BF_HeadLight included).
-- InsertBattery: that vanilla recipe has an EMPTY outputs block
-- (media/scripts/generated/recipes/recipes_electrical.txt), so there is no
-- result texture AT ALL and the row icon comes from a tag-resolved input
-- item - the first modded item registered for base:flashlight is
-- BF_HeadLight (BetterFlashlights_HeadLight.txt sorts before
-- BetterFlashlights_Items.txt). Result: EVERY drainable flashlight showed
-- the mining-helmet light icon on its "Insert Battery" row (reported by
-- Slobodskoy 2026-09-12 in the 2.4.13 playtest).
--
-- Only the icon is reassigned: no row is added, removed or reordered, so
-- context.numOptions and calcHeight stay consistent.  That is the whole
-- reason this is safe to do from a late hook - the three failed attempts
-- in 2.4.11 all broke on mutating the option array instead.
--
-- The row is matched by its localized name through Locale.recipeName, the
-- only path that resolves Recipes.json in B42.20, so the match works in
-- every language.  Vanilla wraps the rows in an item-name submenu when
-- more than one recipe applies (ISInventoryPaneContextMenu.lua:3374), so
-- the row can sit one level down in context.instanceMap.
local BF_BATTERY_ICON_ROWS = { "InsertBattery", "RemoveBattery" }

local function repaintBatteryRowIcons(context, item)
    if not context or not context.options then return end
    local tex = getBatteryIcon()
    if not tex then return end

    local names = {}
    local namesCount = 0
    if Locale and Locale.recipeName then
        for _, key in ipairs(BF_BATTERY_ICON_ROWS) do
            local n = Locale.recipeName(key)
            if n and n ~= "" then names[n] = true; namesCount = namesCount + 1 end
        end
    end
    -- Kahlua has no next(), so the emptiness check is a counter (the same
    -- trap that crashed filterVanillaBatteryEntries in 2.4.11).
    if namesCount == 0 then return end

    local function repaint(ctx, depth)
        if not ctx or not ctx.options then return end
        for i = 1, #ctx.options do
            local opt = ctx.options[i]
            if type(opt) == "table" and opt.name and names[opt.name] then
                opt.iconTexture = tex
            end
        end
        if depth < 2 and type(ctx.instanceMap) == "table" then
            for _, child in pairs(ctx.instanceMap) do
                repaint(child, depth + 1)
            end
        end
    end
    repaint(context, 0)
end

-- 2.4.13: the vanilla InsertBattery row on drainable lights runs the whole
-- vanilla HandcraftLogic, whose input scan takes whichever battery it finds
-- FIRST - not the fullest one (reported by Slobodskoy 2026-09-12). Rebind
-- ONLY the option's onSelect callback to the mod's BF_BatteryAction so
-- findBestBattery picks the best battery; the row keeps its vanilla label,
-- tooltip, icon and position. Nothing is added, removed or reordered, so
-- context.numOptions and calcHeight stay consistent - the lesson of the
-- three failed 2.4.11 attempts is precisely to never mutate the option array.
--
-- Guard: only rows whose onSelect is still the vanilla
-- ISInventoryPaneContextMenu.OnNewCraft are rebound - if another mod has
-- already replaced the callback, we leave that row alone.
local function redirectVanillaInsertBattery(context, item, player)
    if not context or not context.options then return end
    if not isTorchLight(item) then return end
    if not player then return end
    local insertLabel = Locale and Locale.recipeName and Locale.recipeName("InsertBattery") or nil
    if not insertLabel or insertLabel == "" then return end
    local vanillaOnNewCraft = ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.OnNewCraft or nil
    if type(vanillaOnNewCraft) ~= "function" then return end

    local function redirect(ctx, depth)
        if not ctx or not ctx.options then return end
        for i = 1, #ctx.options do
            local opt = ctx.options[i]
            if type(opt) == "table" and opt.name == insertLabel
                and opt.onSelect == vanillaOnNewCraft then
                opt.onSelect = function()
                    -- BF_BatteryAction uses the vanilla recipe timing for
                    -- drainable lights (30 ticks, InsertBattery time = 30).
                    ISTimedActionQueue.add(BF_BatteryAction:new(player, item, "insert"))
                end
            end
        end
        if depth < 2 and type(ctx.instanceMap) == "table" then
            for _, child in pairs(ctx.instanceMap) do
                redirect(child, depth + 1)
            end
        end
    end
    redirect(context, 0)
end

local function onContextInner(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    local item = items and resolve(items[1]) or nil
    if not player or not context then return end

    -- Only weapon lights need the vanilla-row filter; see the comment in
    -- filterVanillaBatteryEntries for the reasoning.
    if isTorchWeapon(item) then
        filterVanillaBatteryEntries(context, item)
    end

    -- Drainable lights stay vanilla-driven: the mod only repaints the icons
    -- of the battery rows and redirects the Insert Battery click, so the
    -- FULLEST battery is taken instead of the first one the vanilla crafting
    -- logic happens to find.
    if isTorchLight(item) then
        repaintBatteryRowIcons(context, item)
        redirectVanillaInsertBattery(context, item, player)
    end


    -- Drainable lights are fully vanilla-driven as of 2.4.11:
    --   * RemoveBattery / InsertBattery / DismantleElectronics match the
    --     base:flashlight tag, and when more than one recipe applies
    --     ISInventoryPaneContextMenu.lua:3374 wraps them in a vanilla
    --     item-name submenu. The mod used to add its own "BF_DismantleFlashlight"
    --     row and its own Insert/Extract Battery rows, which doubled the
    --     submenu header. We now keep the mod submenu only for the three
    --     weapon flashlights (Torch7, TorchArmy1, TorchArmy2), whose
    --     bf:flashlight tag does not match the vanilla recipes.

    if isTorchWeapon(item) then
        local md = ensureModData(item)
        if not md then return end
        local isBroken = (md.bfWeaponBroken == true) or (md.isBroken == true)
        -- Group battery rows under the iconed submenu; fall back to the
        -- plain menu when the group cannot be built (early load / exotic context).
        local sub = BF_ContextGroup.get(context, item)
        local targetMenu = sub or context
        local insertLabel = Locale.recipeName("InsertBattery")
            or Locale.tr("TorchInsertBattery", "UI_Translation_TorchInsertBattery") or "Insert Battery"
        local extractLabel = Locale.recipeName("RemoveBattery")
            or Locale.tr("TorchExtractBattery", "UI_Translation_TorchExtractBattery") or "Extract Battery"
        -- Battery icon for both rows (vanilla parity with drainable
        -- submenu). Fallback to the flashlight icon so the row is never
        -- blank if the cached instance failed to produce a texture.
        local batteryTex = getBatteryIcon()
        local tex = batteryTex
        if not tex and item and item.getTex then
            local okT, texVal = pcall(item.getTex, item)
            if okT then tex = texVal end
        end
        -- 2.4.11+: the recipe BF_DismantleTorchWeapon is kept for the
        -- crafting window and batch-craft, but its context-menu row is
        -- suppressed in filterVanillaBatteryEntries and replaced here
        -- with the mod's own row. The mod row is the only dismantle
        -- path in the inventory context menu; the timed action
        -- (BF_DismantleAction:perform) returns the battery and grants
        -- 2 XP Electricity, matching the recipe's outputs. The same
        -- row is added for whole, worn, and broken weapon lights —
        -- vanilla's CraftRecipeManager drops the recipe on broken items,
        -- so a mod row is the only way to keep the option in that state.
        local dismantleLabel = Locale.recipeName("BF_DismantleTorchWeapon")
            or Locale.tr("BF_DismantleTorchWeapon", "UI_Translation_BF_DismantleTorchWeapon")
            or "Dismantle Military Flashlight"
        -- Reuse the vanilla B42 hand-torch icon for dismantling; the battery
        -- rows keep the vanilla battery icon returned above.
        local dismantleTex = getHandTorchIcon()
        if hasScrewdriver(player) then
            BF_ContextGroup.addOptionWithIcon(targetMenu, dismantleLabel, dismantleTex, player, function(p)
                ISTimedActionQueue.add(BF_DismantleAction:new(p, item))
            end)
        else
            local dRow = targetMenu:addOption(dismantleLabel, player, function() end)
            if dRow then
                dRow.notAvailable = true
                if dismantleTex then dRow.iconTexture = dismantleTex end
                if ISToolTip and ISToolTip.new then
                    local tip = ISToolTip:new()
                    if tip then
                        tip:initialise()
                        tip:setName(dismantleLabel)
                        tip:setDescription(Locale.tr("BF_NeedScrewdriver", "UI_Translation_BF_NeedScrewdriver") or "Requires a screwdriver.")
                        dRow.toolTip = tip
                    end
                end
            end
        end
        if isBroken then
            -- broken: только Extract (Repair из BF_RepairContextMenu.lua)
            if md.bfHasBattery == true or (md.batteryCharge or 0) > 0 then
                BF_ContextGroup.addOptionWithIcon(targetMenu, extractLabel, tex, player, function(p)
                    ISTimedActionQueue.add(BF_BatteryAction:new(p, item, "extract"))
                end)
            end
        else
            local inv = player:getInventory()
            if md.bfHasBattery ~= true and inv and inv:getFirstTypeRecurse("Battery") then
                BF_ContextGroup.addOptionWithIcon(targetMenu, insertLabel, tex, player, function(p)
                    ISTimedActionQueue.add(BF_BatteryAction:new(p, item, "insert"))
                end)
            end
            if md.bfHasBattery == true or (md.batteryCharge or 0) > 0 then
                BF_ContextGroup.addOptionWithIcon(targetMenu, extractLabel, tex, player, function(p)
                    ISTimedActionQueue.add(BF_BatteryAction:new(p, item, "extract"))
                end)
            end
        end
    end
end

-- An error thrown while the inventory context menu is being built aborts the
-- whole vanilla menu, which players report as a crash on right click.
local function onContext(playerNum, context, items)
    local ok, err = pcall(onContextInner, playerNum, context, items)
    if not ok then
        print("[BetterFlashlights] context menu error: " .. tostring(err))
    end
end

local function onUpdate(player)
    if not player or player:isDead() then return end
    tick = tick + 1
    if patchVanillaLightToggle then patchVanillaLightToggle() end
    updateVanillaLightKeyBinding(player)
    -- Battery drain runs on the in-game clock, see bfEveryOneMinute below.
    local item = getHeldTorchWeapon(player)
    if not isTorchWeapon(item) then return end
    ensureModData(item)
    updateBrokenState(item, true)
    if tick % UPDATE_TICKS ~= 0 then return end
    local md = ensureModData(item)
    if md.isLightOn == true and (md.bfWeaponBroken == true or md.batteryCharge < BF_MIN_USABLE_CHARGE) then md.isLightOn = false; syncState(item) end
    -- Drain happens in bfEveryOneMinute; this path only refreshes name/damage.
    if md.bfWeaponBroken == true then applyBroken(item, md) else applyRepaired(item, md) end
    -- light rendering handled by updateAllPlayerLights
end

local function addTooltip(tooltip, item)
    if not tooltip or not isTorchWeapon(item) then return end
    local md = ensureModData(item)
    if not md then return end
    if md.bfWeaponBroken == true then pcall(tooltip.addLine, tooltip, Locale.tr("TorchBroken", "UI_Translation_TorchBroken") or "Broken", 1, 0.1, 0.1) end
    pcall(tooltip.addLine, tooltip, (Locale.tr("TorchBattery", "UI_Translation_TorchBattery") or "Battery: ") .. tostring(math.floor(clampCharge(md.batteryCharge))) .. "%", 0.85, 0.85, 0.55)
end

local function renderTorchTooltip(self)
    if not self or not self.tooltip or not self.item then return false end
    local mx = getMouseX() + 24
    local my = getMouseY() + 24
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
        if self.anchorBottomLeft then
            mx = self.anchorBottomLeft.x
            my = self.anchorBottomLeft.y
        end
    end

    self.tooltip:setX(mx)
    self.tooltip:setY(my)
    self.tooltip:setWidth(50)
    self.tooltip:setMeasureOnly(true)
    if self.item then
        self.item:DoTooltip(self.tooltip)
        addTooltip(self.tooltip, self.item)
    end
    self.tooltip:setMeasureOnly(false)

    local core = getCore()
    local maxX = core:getScreenWidth()
    local maxY = core:getScreenHeight()
    local tw = self.tooltip:getWidth()
    local th = self.tooltip:getHeight()
    if type(tw) ~= "number" or type(th) ~= "number" then return false end
    self.tooltip:setX(math.max(0, math.min(mx, maxX - tw - 1)))
    self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)))
    self:setX(self.tooltip:getX())
    self:setY(self.tooltip:getY())
    self:setWidth(tw)
    self:setHeight(th)
    if self.followMouse and (self.contextMenu == nil) then
        self:adjustPositionToAvoidOverlap({ x = mx - 48, y = my - 48, width = 48, height = 48 })
    end
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    if self.item then
        self.item:DoTooltip(self.tooltip)
        addTooltip(self.tooltip, self.item)
    end
    return true
end

local function patchTooltip()
    if not ISToolTipInv or ISToolTipInv.bfTorchArmyWeaponTooltipPatched then return end
    local vanilla = ISToolTipInv.render
    function ISToolTipInv:render()
        local ctx = ISContextMenu and ISContextMenu.instance or nil
        if self and self.item and isTorchWeapon(self.item) and (not ctx or not ctx.visibleCheck) then
            local ok, drawn = pcall(renderTorchTooltip, self)
            if ok and drawn then return end
        end
        if type(vanilla) == "function" then vanilla(self) end
    end
    ISToolTipInv.bfTorchArmyWeaponTooltipPatched = true
end

local function onServerCommand(module, command, args)
    if module ~= "BetterFlashlights" then return end
    local player = getPlayer()
    if not args then return end

    if command == "BFRemoteLight" then
        local rid = tonumber(args.id)
        if rid then bfRemoteLightState[rid] = (args.on == 1 or args.on == true) end
        return
    end

    if command == "TorchLightState" then
        -- Server sent authoritative state for light flashlight
        local inv = player:getInventory()
        if not inv then return end
        local item = inv.getItemById and inv:getItemById(args.itemID) or nil
        if not item or not isTorchLight(item) then
            -- Try primary/secondary hand
            local primary = player:getPrimaryHandItem()
            local secondary = player:getSecondaryHandItem()
            item = (isTorchLight(primary) and primary) or (isTorchLight(secondary) and secondary)
            if not item or itemID(item) ~= args.itemID then
                return
            end
        end
        local md = ensureModDataLight(item)
        if not md then return end
        -- Apply server state
        md.bfHasBattery = (args.bfHasBattery == 1 or args.bfHasBattery == true)
        md.bfBatteryDelta = args.charge and (args.charge / 100.0) or nil
        setDrainableCharge(item, args.charge or 0)
        if item.transmitModData then pcall(item.transmitModData, item) end
        return
    end

    if command == "TorchArmyWeaponState" then
        local inv = player:getInventory()
        local item = inv and inv.getItemById and inv:getItemById(args.itemID) or nil
        if not item or not isTorchWeapon(item) then
            item = getHeldTorchWeapon(player)
        end
        if not isTorchWeapon(item) or itemID(item) ~= args.itemID then return end
        local md = ensureModData(item)
        -- Charge ownership: the client HOLDING the torch is the one draining it
        -- (bfEveryOneMinute), so it must not take charge or light state back from
        -- the server. Both copies used to overwrite each other, which looked like
        -- a flashlight that stalls, then suddenly snaps to a stale server charge.
        local heldByMe = getHeldTorchWeapon(player) == item
        if type(args.batteryCharge) == "number" and not heldByMe then md.batteryCharge = clampCharge(args.batteryCharge) end
        -- Grace period: ignore stale server state while grace is active
        local inGrace = md.bfRepairGraceUntil and tick < md.bfRepairGraceUntil
        if args.bfHasBattery ~= nil and not inGrace then md.bfHasBattery = (args.bfHasBattery == 1 or args.bfHasBattery == true) end
        if args.isLightOn ~= nil and not inGrace and not heldByMe then md.isLightOn = (args.isLightOn == 1 or args.isLightOn == true) end
        if args.isBroken ~= nil and not inGrace then
            -- do NOT apply md.bfWeaponBroken from stale server state
        end
        -- Sync native condition from server BEFORE updateBrokenState so it
        -- does not re-overwrite bfWeaponBroken back based on stale local value
        if type(args.condition) == "number" and args.condition >= 0 and args.condition <= 100 and not inGrace then
            -- Monotonic guard: only LOWER condition from server, never raise
            local curCond = item.getCondition and item:getCondition() or 100
            if args.condition < curCond and item.setCondition then
                pcall(item.setCondition, item, args.condition)
            end
        end
        updateBrokenState(item, false)
        if md.bfWeaponBroken == true then applyBroken(item, md) else applyRepaired(item, md) end
        transmit(item)
        return
    end

    if command == "ApplyRepair" then
        -- Sync condition (mirror of server setCondition)
        local inv = player:getInventory()
        local item = inv and inv.getItemById and inv:getItemById(args.itemID) or nil
        local matched = false
        if not item or not isTorchWeapon(item) then
            item = getHeldTorchWeapon(player)
        end
        if isTorchWeapon(item) then
            matched = itemID(item) == args.itemID
        end
        if isTorchWeapon(item) and matched then
            if type(args.condition) == "number" and args.condition >= 0 and args.condition <= 100 then
                pcall(item.setCondition, item, args.condition)
            end
            -- Clear broken flags immediately to prevent 1-tick flash of "Broken" state
            local md = ensureModData(item)
            if md then
                md.bfWeaponBroken = false
                md.isBroken = false
            end
            -- Native broken must be cleared AFTER condition restored (conditionMax resets it,
            -- but explicit setBroken(false) is our safety net for future changes in engine)
            safeCall(item, "setBroken", false)
            -- Grace period: suppress re-break for ~15 ticks after repair
            local md2 = ensureModData(item)
            if md2 then md2.bfRepairGraceUntil = tick + 15 end

            -- Push repaired condition to server so its monitor doesn't re-break
            syncState(item)
        end
        -- Remove consumed materials from client inventory (server already removed its copy)
        local pinv = player and player:getInventory()
        if pinv then
            local function consumeByType(container, fullType, count)
                for _ = 1, (count or 0) do
                    local it = container:getFirstTypeRecurse(fullType)
                    if not it then break end
                    local cont = it:getContainer() or container
                    cont:Remove(it)
                end
            end
            consumeByType(pinv, "Base.ElectronicsScrap", args.scrap or 2)
            if pinv:getFirstTypeRecurse("Base.ElectricWire") then
                consumeByType(pinv, "Base.ElectricWire", args.wire or 1)
            else
                consumeByType(pinv, "Base.Wire", args.wire or 1)
            end
        end
        return
    end

    -- PickupBattery: server spawned a world battery on floor, client grabs it.
    -- Retry polling (up to 60 ticks ~1s) waiting for world item replication,
    -- then ISGrabItemAction with time=0 (no animation, network pickup preserves registration).
    -- Match by InventoryItem:getID() (synced server↔client) with fullType fallback.
    if command == "PickupBattery" then
        local wID  = args and args.worldBatteryID
        local iID  = args and args.itemID
        local ftype = args and args.fullType
        if not wID and not iID then return end
        local attempts = 0
        local tryPickup
        tryPickup = function()
            attempts = attempts + 1
            local pl = getSpecificPlayer(0)
            local sq = pl and pl:getCurrentSquare()
            local wItem = nil
            if sq then
                local items = sq:getWorldObjects()
                local n = items and items:size() or 0
                -- 1) match by InventoryItem ID (synced server↔client)
                for i = 0, n - 1 do
                    local wi = items:get(i)
                    local it = wi and wi.getItem and wi:getItem() or nil
                    if it and iID and it.getID and it:getID() == iID then
                        wItem = wi; break
                    end
                end
                -- 2) fallback: match by fullType
                if not wItem and ftype then
                    for i = 0, n - 1 do
                        local wi = items:get(i)
                        local it = wi and wi.getItem and wi:getItem() or nil
                        if it and it.getFullType and it:getFullType() == ftype then
                            wItem = wi; break
                        end
                    end
                end
            end
            if wItem and pl then
                ISTimedActionQueue.add(ISGrabItemAction:new(pl, wItem, 0))
                Events.OnTick.Remove(tryPickup)
            elseif attempts >= 60 then
                Events.OnTick.Remove(tryPickup)
            end
        end
        Events.OnTick.Add(tryPickup)
        return
    end
end

local function onWeaponHit(owner, target, weapon)
    if isTorchWeapon(weapon) then
        local md = ensureModData(weapon)
        if md and md.bfWeaponBroken == true then setDamage(weapon, 0, 0) end
    end
end

patchVanillaLightToggle = function()
    if not ItemBindingHandler or ItemBindingHandler.bfTorchArmyWeaponTogglePatched then return end
    local vanillaToggleLight = ItemBindingHandler.toggleLight
    if type(vanillaToggleLight) ~= "function" then return end

    function ItemBindingHandler.toggleLight(key)
        local playerObj = getSpecificPlayer and getSpecificPlayer(0) or getPlayer()
        if getHeldTorchWeapon(playerObj) then return end
        -- FIX: snap bfHasBattery for light-type flashlights at toggle time.
        -- If charge > 0 the battery is definitely inside — lock the flag so that
        -- "Extract Battery" remains visible after discharge to 0%.
        if playerObj then
            local primary   = playerObj:getPrimaryHandItem()
            local secondary = playerObj:getSecondaryHandItem()
            local item = (isTorchLight(primary) and primary) or (isTorchLight(secondary) and secondary)
            if item then
                local md = ensureModDataLight(item)
                if md then
                    local charge = getDrainableCharge(item) or 0
                    if charge > 0 and md.bfHasBattery ~= true then
                        md.bfHasBattery = true
                        if item.transmitModData then pcall(item.transmitModData, item) end
                    elseif charge <= 0 and md.bfHasBattery == true then
                        md.bfHasBattery = false
                        if item.transmitModData then pcall(item.transmitModData, item) end
                    end
                end
            end
        end
        return vanillaToggleLight(key)
    end

    ItemBindingHandler.bfTorchArmyWeaponTogglePatched = true
end

-- 2.4.13 (belt experiment rolled back): patchHotbarAttachMenu stays
-- removed. The three weapon flashlights carry no AttachmentType again - the
-- belt offsets cut through the character's body in the playtest, so the
-- belt mount was reverted. ISHotbar's "Attach" menu never offers an item
-- without an AttachmentType, so there is nothing left for the old patch to
-- swallow.

patchTooltip()
patchVanillaLightToggle()
-- In-game-time battery drain: one drainable use per BF_MINUTES_PER_USE minutes,
-- for weapon torches and for belt attached lights.
local function bfEveryOneMinute()
    local player = getPlayer()
    if not player or player:isDead() then return end
    pcall(drainBeltLights, player)
    local item = getHeldTorchWeapon(player)
    if not isTorchWeapon(item) then return end
    local md = ensureModData(item)
    if not md then return end
    if md.isLightOn ~= true or md.bfWeaponBroken == true then return end
    if md.batteryCharge < BF_MIN_USABLE_CHARGE then return end
    md.batteryCharge = clampCharge(md.batteryCharge - BF_WEAPON_DRAIN_PER_MINUTE)
    if md.batteryCharge < BF_MIN_USABLE_CHARGE then
        md.batteryCharge = 0
        md.isLightOn = false
        removeTorchLight()
    end
    applyRepaired(item, md)
    transmit(item)
    syncState(item)
end

if Events.EveryOneMinute then Events.EveryOneMinute.Add(bfEveryOneMinute) end

Events.OnKeyPressed.Add(onKeyPressed)
Events.OnPlayerUpdate.Add(onUpdate)
Events.OnFillInventoryObjectContextMenu.Add(onContext)
Events.OnServerCommand.Add(onServerCommand)
if Events.OnWeaponHitCharacter then Events.OnWeaponHitCharacter.Add(onWeaponHit) end
if Events.OnWeaponHitTree then Events.OnWeaponHitTree.Add(onWeaponHit) end
if Events.OnWeaponHitXp then Events.OnWeaponHitXp.Add(onWeaponHit) end

-- MP: per-tick driver that renders light for ALL visible players
-- Stage 2 (EXPERIMENTAL): remote-player lights are limited to players near the local
-- player, and the number of simultaneous remote light sources is capped.
local BF_MP_LIGHT_RADIUS = 20
local BF_MP_LIGHT_MAX = 8
local function bfRemoteLightAllowed(me, p)
    if not me or not p then return false end
    local ok, near = pcall(function()
        if math.floor(p:getZ()) ~= math.floor(me:getZ()) then return false end
        local dx = p:getX() - me:getX()
        local dy = p:getY() - me:getY()
        return (dx * dx + dy * dy) <= (BF_MP_LIGHT_RADIUS * BF_MP_LIGHT_RADIUS)
    end)
    return ok and near == true
end

-- MP light exchange: every client reports its OWN light state (weapon torch in hand or
-- an active belt-mounted torch) and renders the state the server relays for other players.
local function bfRemoteLightOn(p)
    local id = safeCall(p, "getOnlineID")
    if type(id) ~= "number" then return false end
    return bfRemoteLightState[id] == true
end

-- MP light exchange (2.4.9): report only on state change, plus a slow background
-- heartbeat controlled by the sandbox option BFLightState.heartbeatSeconds.
-- Previous behaviour sent an update every ~3 s regardless of change and let
-- the server re-broadcast it to every client, which on a 30-48 player
-- dedicated server pushed BFLightState to 68-71% of all Lua ClientCommands
-- (report by hajmer on 2026-08-28 against 2.4.8). The 60-tick cadence
-- bfReportTick counter is removed; timing now uses real-world seconds.
local BF_DEFAULT_HEARTBEAT_SECONDS = 30
local BF_RECOVERY_HEARTBEAT_SECONDS = 3
local function bfGetHeartbeatSeconds()
    local ok, v = pcall(function()
        local sv = SandboxVars and SandboxVars.BFLightState
        if type(sv) ~= "table" then return nil end
        local n = sv.heartbeatSeconds
        if type(n) ~= "number" then return nil end
        return n
    end)
    if ok and type(v) == "number" and v >= 0 then return v end
    return BF_DEFAULT_HEARTBEAT_SECONDS
end

local function bfNowSeconds()
    -- 2.4.14: real wall-clock seconds from os.time() as the PRIMARY source.
    -- The 2.4.9 version asked GameTime for getRealWorldSecondsSinceStart /
    -- getTimeInMillis, but client Lua exposes neither (proven by the
    -- BF_HeartbeatProbe HOST MP run 2026-09-14: pcall swallowed the nil, so
    -- the heartbeat and the recovery heartbeat never fired even once since
    -- 2.4.9 - only real on/off switches were announced). os.time() is
    -- available (the probe's os.date stamps printed fine); the GameTime
    -- getters stay as fallbacks in case a future build exposes them.
    -- All comparisons here are differences (now - last), so the epoch
    -- offset of os.time() does not matter.
    local ok, v = pcall(function() return os.time() end)
    if ok and type(v) == "number" then return v end
    ok, v = pcall(function()
        local gt = getGameTime and getGameTime()
        if not gt then return nil end
        if gt.getRealWorldSecondsSinceStart then
            return gt:getRealWorldSecondsSinceStart()
        end
        if gt.getTimeInMillis then
            return gt:getTimeInMillis() / 1000.0
        end
        return nil
    end)
    if ok and type(v) == "number" then return v end
    return nil
end

local bfLastReportedLight = nil
local bfLastSentAt = nil    -- real-world seconds of the last BFLightState send
local bfPlayerReadyAt = nil -- first time we saw a real local player, for the recovery heartbeat
local bfRecoverySent = false -- 2.4.14: one-shot latch for the single recovery heartbeat
local function bfOwnLightOn(me)
    if not me then return false end
    local w = getHeldTorchWeaponAny(me)
    if w and weaponLightOn(w) then return true end
    if getActiveBeltTorchLight(me) then return true end
    return false
end

local function bfReportOwnLight(me)
    if not me then return end
    if (not isClient()) and (not isServer()) then return end   -- pure SP: nobody to tell
    local now = bfNowSeconds()
    local on = bfOwnLightOn(me)
    if bfPlayerReadyAt == nil and now then bfPlayerReadyAt = now end
    local interval = bfGetHeartbeatSeconds()
    local dueToStateChange = (on ~= bfLastReportedLight)
    -- 2.4.14: one-shot latch. The recovery heartbeat is a SINGLE re-announce
    -- BF_RECOVERY_HEARTBEAT_SECONDS after the first live player, so a client
    -- that missed the original state change announcement catches up. Without
    -- the latch the (now - bfPlayerReadyAt) >= 3 comparison stayed true for
    -- the rest of the session and fired a send on EVERY driver call (~every
    -- 3rd OnTick), which made the heartbeatSeconds sandbox option dead and
    -- flooded the server worse than the 2.4.8 spam hajmer reported.
    local dueToRecovery = (not bfRecoverySent)
        and (now and bfPlayerReadyAt and (now - bfPlayerReadyAt) >= BF_RECOVERY_HEARTBEAT_SECONDS)
    local dueToHeartbeat = false
    if interval > 0 and now and bfLastSentAt then
        dueToHeartbeat = (now - bfLastSentAt) >= interval
    end
    if dueToStateChange or dueToRecovery or dueToHeartbeat then
        if dueToRecovery then bfRecoverySent = true end
        bfLastReportedLight = on
        bfLastSentAt = now or bfLastSentAt
        pcall(sendClientCommand, "BetterFlashlights", "BFLightState", { on = on and 1 or 0 })
    end
end

local lightTick = 0
local function updateAllPlayerLights()
    if isServer() then return end   -- свет считаем только на клиенте; per-player отсев — в applyPlayerLight
    lightTick = lightTick + 1
    if lightTick % 3 ~= 0 then return end   -- once every 3 ticks (≈ smooth, 3x less load)

    local me = getPlayer()
    local meKey = me and lightKey(me) or nil
    bfReportOwnLight(me)

    local list = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil   -- MP
    if players and players:size() > 0 then
        for i = 0, players:size() - 1 do list[#list+1] = players:get(i) end
    elseif me then
        list[1] = me                                                 -- SP / fallback
    end

    local seen = {}
    local remoteLights = 0
    for _, p in ipairs(list) do
        local isRemote = (p ~= nil) and (lightKey(p) ~= meKey)
        if p and safeCall(p, "isDead") ~= true and ((not isRemote) or (remoteLights < BF_MP_LIGHT_MAX and bfRemoteLightAllowed(me, p))) then
            local key = lightKey(p)
            local on = false
            if isRemote then
                on = bfRemoteLightOn(p)          -- authoritative state relayed by the server
            else
                local w = getHeldTorchWeaponAny(p)
                if w then on = weaponLightOn(w) end
            end
            if on then seen[key] = true; applyPlayerLight(p, true); if isRemote then remoteLights = remoteLights + 1 end end
        end
    end
    for key in pairs(torchLights) do
        if not seen[key] then removePlayerLight(key) end
    end
end
Events.OnTick.Add(updateAllPlayerLights)  -- SP-only через bfPlayerLightAllowed()

-- Refresh locale when game settings are loaded (language may change after require)
if Events.OnGameBoot then Events.OnGameBoot.Add(function() if Locale and Locale.refresh then Locale.refresh() end end) end
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(function() if Locale and Locale.refresh then Locale.refresh() end end) end
if Events.OnGameStart then Events.OnGameStart.Add(function() if Locale and Locale.refresh then Locale.refresh() end end) end

-- Debug: log missing translations for current language
if Locale and Locale.debugMissing then
    Locale.debugMissing()
end

print("[BetterFlashlights] BF_WeaponFlashlight.lua loaded: single-item weapon flashlight runtime")
