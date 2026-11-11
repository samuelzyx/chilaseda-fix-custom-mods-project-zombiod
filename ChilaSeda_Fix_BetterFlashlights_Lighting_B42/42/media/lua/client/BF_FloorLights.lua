-- Better Flashlights -- floor lights: our flashlights actually illuminate while lying on the ground.
--
-- WHY THIS FILE EXISTS
--   1) The engine only renders an item's LightStrength / LightDistance / TorchCone while the item is
--      CARRIED. An activated flashlight resting on a tile emits nothing at all, so somebody has to
--      create a real world light: we do it with IsoLightSource + getCell():addLamppost, the same
--      technique vanilla street lamps use and the only dynamic-floor-light API exposed to Lua.
--   2) Vanilla actively switches lights OFF when they leave your hands, in more than one place:
--      ISUnequipAction:start() line 49 and ISUnequipAction:complete() line 114 both call
--      setActivated(false), and start() also calls syncItemActivated() so the server agrees. Both the
--      plain "Drop" (ISInventoryPaneContextMenu.lua:3853, reason "drop") and the "Place Item" cursor
--      (ISPlace3DItemCursor.lua:28 and :39, reason "place") queue that unequip BEFORE the drop action.
--      Fighting that with a single hook lost the race, so the wish to stay lit is stored on the item as
--      md.bfFloorLit while it is still lit IN HAND. Vanilla never touches modData, so the intent
--      survives every unequip path and the scanner lights whatever carries it. (Same trick as the flLit
--      flag in El-Soplya's Lanterns on the Floor Fix.)
--   3) That mod recognises light sources by NAME from a hardcoded table of eight vanilla types, none of
--      which are ours (we use Base.Torch1..6, not Base.Torch), and the table is `local` so it cannot be
--      extended from outside. Base.HandTorch is the single overlap and is deliberately left to them, so
--      no tile ever gets two lights.
--   4) The three weapon flashlights (Base.Torch7, Base.TorchArmy1, Base.TorchArmy2) are base:weapon
--      items with no light fields in their script at all; their state lives in modData.isLightOn and
--      their floor radius is a constant here. NEVER call getScriptItem():getLightDistance() on them,
--      it throws on a Base.Weapon.
--
-- SCOPE: only the mod's own 17 item types. Anyone else's flashlight, lantern or candle is untouched.

pcall(require, "TimedActions/ISInventoryTransferAction")

local Locale = require("BetterFlashlights/Locale")

-- Drainable lights: one item whose isActivated() flips the light, charge lives in the drainable delta.
local FLOOR_DRAINABLE = {
    ["Base.HandTorch_Army1"]  = true,
    ["Base.HandTorch_Army2"]  = true,
    ["Base.HandTorch_CK_LED"] = true,
    ["Base.HandTorch_ManLite"] = true,
    ["Base.Torch1"] = true, ["Base.Torch2"] = true, ["Base.Torch3"] = true,
    ["Base.Torch4"] = true, ["Base.Torch5"] = true, ["Base.Torch6"] = true,
    ["Base.BF_HeadLight"]     = true,
    ["Base.BF_OldFlashlight"] = true,
    ["Base.BF_EgenerexLite"]  = true,
    ["Base.BF_SpiffoLite"]    = true,
}

-- Weapon flashlights: base:weapon, no light fields in the script, state in modData.isLightOn.
local FLOOR_WEAPON = {
    ["Base.Torch7"]     = true,
    ["Base.TorchArmy1"] = true,
    ["Base.TorchArmy2"] = true,
}

local SCAN_RADIUS      = 12     -- tiles around the player scanned for our floor lights
local SCAN_INTERVAL_MS = 1000   -- scanner cadence in real milliseconds
local TRACK_INTERVAL_MS = 400   -- how often the carried-intent tracker runs

-- RADIUS. An item's LightDistance is tuned for a forward CONE in the hands (ours run 8..40); reused
-- verbatim as a floor light it would flood a basement. Calibrated against a playtest observation: with
-- Lanterns on the Floor Fix the vanilla Base.Torch "lights the whole basement like the sun", and that is
-- LightDistance 25 times their 0.5 multiplier = 12 tiles. So 12 is what "far too bright" looks like, and
-- our cap is 7 with a 0.25 multiplier: a typical flashlight reaches 4-5 tiles.
local DEFAULT_RADIUS_MULT = 0.25
local MIN_FLOOR_RADIUS    = 3
local MAX_FLOOR_RADIUS    = 7
local WEAPON_FLOOR_RADIUS = 3    -- compact fixed radius for the three weapon torches

-- COLOUR. The script fields LightColorRed/Green/Blue have NO getter exposed to Lua: a scan of
-- projectzomboid.jar finds setLightColor and the field LightColour but zero getLightColor* methods on
-- InventoryItem or on the script Item, and vanilla Lua never reads them either. So the per-item colour is
-- mirrored here from our own media/scripts/BetterFlashlights_Items.txt - keep the two in sync by hand.
-- Items without a colour in the script get the same warm white BF_WeaponFlashlight.applyPlayerLight uses
-- for the carried beam, so a flashlight looks the same in hand and on the floor.
local DEFAULT_COLOR = { 1.00, 0.92, 0.75 }
local ITEM_COLOR = {
    ["Base.BF_OldFlashlight"] = { 1.00, 0.78, 0.42 },   -- script: warm incandescent yellow
    ["Base.HandTorch_CK_LED"] = { 0.40, 0.60, 1.00 },   -- script: cold blue LED
}

-- BRIGHTNESS. IsoLightSource has no intensity parameter, only r,g,b in 0..1, so the item's LightStrength
-- (getLightStrength IS available on InventoryItem) is folded into the colour. Our lights span 0.4
-- (BF_OldFlashlight) to 4.3 (BF_HeadLight), so a weak flashlight now reads as visibly dimmer instead of
-- every light looking identical.
local STRENGTH_REFERENCE = 2.5    -- LightStrength that maps to full brightness
local MIN_BRIGHTNESS     = 0.40
local WEAPON_STRENGTH    = 2.0    -- the weapon torches have no LightStrength in their script

-- DIRECTION. A single round blob looks wrong for an item that visibly points somewhere. IsoLightSource
-- cannot do a cone, so the beam is imitated the way BF_WeaponFlashlight does for the carried light: a
-- chain of sources along the item's facing, taken from getWorldZRotation() (present on InventoryItem and
-- IsoWorldInventoryObject) - the rotation the placement cursor gave the item.
--
-- ANGLE CALIBRATION. Which world direction 0 degrees points at is documented nowhere. The first guess
-- (0 = north, growing clockwise) came out BACKWARDS in the playtest: "the light comes from behind the
-- flashlight, not from the lens", so the offset is now 180. That fixes a pure reversal, but if the angle
-- model were wrong in some other way (a mirrored axis, say) then two of the four directions would look
-- right after the flip and two would still be wrong. So the debug log prints the raw angle together with
-- the direction it was turned into: drop a flashlight facing all four ways with BFFloorLights.debug on and
-- the mapping can be measured instead of guessed.
local BEAM_ANGLE_OFFSET = 180

-- BEAM SHAPE. The first version put a halo right on the item's own tile, and that is exactly what made
-- the light look like it shines out from UNDER the flashlight body. It is gone: the chain now starts one
-- tile ahead, so the ground in front is lit while the item itself sits in half-shadow.
--
-- HARD ENGINE LIMIT, not a tuning choice: IsoLightSource.new takes INTEGER tile coordinates and an
-- integer radius. There is no sub-tile precision anywhere in this API, so a light can only ever be
-- centred on a whole tile while the flashlight model occupies a small part of it. The offsets below hide
-- the worst of that mismatch; they cannot remove it.
local BEAM_STEPS = {              -- sources ahead of the item: distance in tiles, radius factor
    { dist = 1.0, factor = 1.00 },
    { dist = 2.2, factor = 0.75 },
    { dist = 3.4, factor = 0.50 },
}
-- A faint glow still has to sit on the item's tile, otherwise the flashlight itself is invisible in a
-- pitch-black room. Kept deliberately small so it reads as spill, not as the source.
local BEAM_SPILL_FACTOR = 0.28

-- FUEL. Vanilla drains a lit drainable by exactly ONE Use() every 10 in-game minutes, and
-- setCurrentUsesFloat works in delta space that the engine ROUNDS TO A WHOLE USE. Draining once per
-- in-game minute therefore wrote a change ten times smaller than one use and the engine quantised it
-- straight back to the old value - which is why the playtest saw a floor light burn without ever spending
-- the battery. So we fire on EveryTenMinutes and subtract one whole UseDelta, matching both vanilla and
-- the in-hand rate used everywhere else in this mod.
local BF_MIN_USABLE_CHARGE = 1.0
local BF_WEAPON_USE_DELTA  = 0.007
local BF_DEFAULT_USE_DELTA = 0.006

local function safeCall(obj, method, ...)
    if not obj or not obj[method] then return nil end
    local ok, value = pcall(obj[method], obj, ...)
    if ok then return value end
    return nil
end

local function tr(key, fallback)
    local ok, text = pcall(function() return Locale and Locale.t and Locale.t("ui." .. key) end)
    if ok and type(text) == "string" and text ~= "" then return text end
    return fallback
end

-------------------------------------------------------------------------------- sandbox options
-- Read through pcall with hardcoded fallbacks: this file loads before SandboxVars is populated on the
-- client, and a save started before this version has no BFFloorLights page at all.
local function sandbox(name, default)
    local ok, value = pcall(function()
        local sv = SandboxVars and SandboxVars.BFFloorLights
        if type(sv) ~= "table" then return nil end
        return sv[name]
    end)
    if ok and value ~= nil then return value end
    return default
end

local function optEnabled()      return sandbox("enabled", true) ~= false end
local function optWeaponLights() return sandbox("weaponLights", true) ~= false end
local function optDrainFuel()    return sandbox("drainFuel", true) ~= false end
local function optDebug()        return sandbox("debug", false) == true end
local function optDirectional()  return sandbox("directional", true) ~= false end
local function optRadiusMult()
    local v = sandbox("radiusMult", DEFAULT_RADIUS_MULT)
    if type(v) ~= "number" or v <= 0 then return DEFAULT_RADIUS_MULT end
    return v
end

-- Diagnostics print on state changes only, never per tick, so console.txt stays readable.
local function dbg(fmt, ...)
    if not optDebug() then return end
    local ok, text = pcall(string.format, fmt, ...)
    print("[BF-FloorLights] " .. (ok and text or tostring(fmt)))
end

-------------------------------------------------------------------------------- item predicates
local function isDrainableLight(item)
    if not item then return false end
    local ft = safeCall(item, "getFullType")
    return ft ~= nil and FLOOR_DRAINABLE[ft] == true
end

local function isWeaponLight(item)
    if not item then return false end
    local ft = safeCall(item, "getFullType")
    return ft ~= nil and FLOOR_WEAPON[ft] == true
end

local function isOurLight(item)
    return isDrainableLight(item) or isWeaponLight(item)
end

local function modData(item)
    return safeCall(item, "getModData")
end

-- Remaining charge in percent, 0..100, for both item families.
local function chargeOf(item)
    if isWeaponLight(item) then
        local md = modData(item)
        local c = md and md.batteryCharge
        if type(c) ~= "number" then return 0 end
        return math.max(0, math.min(100, c))
    end
    local v = safeCall(item, "getCurrentUsesFloat")
    if type(v) ~= "number" then v = safeCall(item, "getDelta") end
    if type(v) ~= "number" then return 0 end
    return math.max(0, math.min(100, v * 100.0))
end

local function hasCharge(item)
    return chargeOf(item) >= BF_MIN_USABLE_CHARGE
end

-- Is the switch of this item in the ON position, whatever family it belongs to?
local function isSwitchedOn(item)
    if isWeaponLight(item) then
        local md = modData(item)
        return md ~= nil and md.isLightOn == true and md.bfWeaponBroken ~= true
    end
    return safeCall(item, "isActivated") == true
end

-------------------------------------------------------------------------------- the intent flag
-- md.bfFloorLit records "the player wants this light on". Written while the item is still lit in hand, so
-- it survives every vanilla unequip path, and trusted by the scanner. Vanilla only ever writes
-- isActivated, never modData.
local function setIntent(item, on)
    local md = modData(item)
    if not md then return false end
    local want = on and true or nil
    if md.bfFloorLit == want then return false end
    md.bfFloorLit = want
    if item.transmitModData then pcall(item.transmitModData, item) end
    return true
end

local function hasIntent(item)
    local md = modData(item)
    return md ~= nil and md.bfFloorLit == true
end

-- Mirror the switch state of the local player's carried lights into the intent flag. Cheap (inventory
-- plus belt, a few times a second) and covers every way a light can be switched on: the key binding, the
-- radial menu, the context menu, another mod.
local function trackCarriedIntent(player)
    local seen = {}

    local function track(item)
        if not item or not isOurLight(item) or seen[item] then return end
        seen[item] = true
        -- Only while NOT on the ground: a floor light's flag belongs to the scanner and the menu.
        if safeCall(item, "getWorldItem") ~= nil then return end
        if isSwitchedOn(item) then
            if setIntent(item, true) then
                dbg("intent set on carried %s", tostring(safeCall(item, "getFullType")))
            end
        elseif hasIntent(item) then
            setIntent(item, false)
            dbg("intent cleared on carried %s", tostring(safeCall(item, "getFullType")))
        end
    end

    local inv = safeCall(player, "getInventory")
    local items = inv and safeCall(inv, "getItems")
    for i = 0, (items and items:size() or 0) - 1 do
        track(items:get(i))
    end

    local attached = safeCall(player, "getAttachedItems")
    if attached and attached.size then
        for i = 0, attached:size() - 1 do
            local ai = safeCall(attached, "getItemByIndex", i)
            if not ai and attached.get then ai = safeCall(attached, "get", i) end
            track(ai)
        end
    end
end

-------------------------------------------------------------------------------- floor light state
local function isFloorLightOn(item)
    if not item then return false end
    if isWeaponLight(item) and not optWeaponLights() then return false end
    if not isOurLight(item) then return false end
    if not (isSwitchedOn(item) or hasIntent(item)) then return false end
    return hasCharge(item)
end

local function isFloorLightOff(item)
    if not item then return false end
    if isWeaponLight(item) then
        if not optWeaponLights() then return false end
        local md = modData(item)
        if md and md.bfWeaponBroken == true then return false end
    elseif not isDrainableLight(item) then
        return false
    end
    return not (isSwitchedOn(item) or hasIntent(item))
end

-------------------------------------------------------------------------------- light parameters
local function strengthOf(item)
    if isWeaponLight(item) then return WEAPON_STRENGTH end
    local s = safeCall(item, "getLightStrength")
    if type(s) ~= "number" or s <= 0 then return 1.5 end
    return s
end

-- Returns r, g, b already scaled by the item's brightness.
local function colorOf(item)
    local ft = safeCall(item, "getFullType")
    local base = (ft and ITEM_COLOR[ft]) or DEFAULT_COLOR
    local brightness = strengthOf(item) / STRENGTH_REFERENCE
    if brightness > 1.0 then brightness = 1.0 end
    if brightness < MIN_BRIGHTNESS then brightness = MIN_BRIGHTNESS end
    return base[1] * brightness, base[2] * brightness, base[3] * brightness
end

-- Radius in tiles for one lit floor item.
local function radiusOf(item)
    if isWeaponLight(item) then
        -- Never query the script for a base:weapon: getScriptItem():getLightDistance() throws.
        return WEAPON_FLOOR_RADIUS
    end
    local raw = safeCall(item, "getLightDistance")
    if type(raw) ~= "number" or raw <= 0 then
        local script = safeCall(item, "getScriptItem")
        raw = script and safeCall(script, "getLightDistance") or nil
    end
    if type(raw) ~= "number" or raw <= 0 then raw = 15 end
    local r = math.floor(raw * optRadiusMult() + 0.5)
    if r < MIN_FLOOR_RADIUS then r = MIN_FLOOR_RADIUS end
    if r > MAX_FLOOR_RADIUS then r = MAX_FLOOR_RADIUS end
    return r
end

-- Facing of a dropped item as a unit vector plus the raw angle it came from (the raw value is returned so
-- the debug log can show what the engine reported next to what we turned it into - see ANGLE CALIBRATION).
-- Returns nil when the item has no usable rotation.
local function facingOf(item, wo)
    local deg = safeCall(wo, "getWorldZRotation")
    if type(deg) ~= "number" then deg = safeCall(item, "getWorldZRotation") end
    if type(deg) ~= "number" then return nil end
    local rad = math.rad(deg + BEAM_ANGLE_OFFSET)
    return math.sin(rad), -math.cos(rad), deg
end

-- Human-readable compass label for a direction vector, so the calibration log is readable at a glance.
local function compassOf(fx, fy)
    if math.abs(fx) > math.abs(fy) then
        return fx > 0 and "east" or "west"
    end
    return fy > 0 and "south" or "north"
end

-------------------------------------------------------------------------------- light registry
-- Each lit tile owns a SET of IsoLightSource objects (the beam chain plus a faint spill on the item's own
-- tile), keyed by the item's tile so the scanner can mark-and-sweep: whatever is not seen in a pass
-- (picked up, switched off, drained, out of range, chunk unloaded) is removed, bounding the lamppost count.
-- `sig` describes the lights we built; while it does not change we leave them alone, otherwise a static
-- flashlight would be removed and re-added every second and visibly flicker.
local active = {}   -- "x,y,z" -> { lights = { IsoLightSource, ... }, sig = "..." }

local function keyOf(x, y, z) return x .. "," .. y .. "," .. z end

local function dropLight(key)
    local entry = active[key]
    if not entry then return end
    pcall(function()
        local cell = getCell()
        if not cell then return end
        for _, light in ipairs(entry.lights) do
            if cell.removeLamppost then cell:removeLamppost(light)
            elseif cell.removeLightSource then cell:removeLightSource(light) end
        end
    end)
    active[key] = nil
    dbg("light removed at %s", key)
end

-- spec = { x, y, z, radius, r, g, b, fx, fy, deg }; fx/fy nil means a plain round light.
local function ensureLight(spec)
    local key = keyOf(spec.x, spec.y, spec.z)
    local sig = string.format("%d|%.2f,%.2f,%.2f|%s",
        spec.radius, spec.r, spec.g, spec.b,
        spec.fx and string.format("%.2f,%.2f", spec.fx, spec.fy) or "-")

    local entry = active[key]
    if entry and entry.sig == sig then return key end
    if entry then dropLight(key) end

    local cell = getCell()
    if not cell or not IsoLightSource then return nil end

    local lights = {}
    local function add(x, y, radius)
        if radius < 1 then radius = 1 end
        pcall(function()
            local light = IsoLightSource.new(x, y, spec.z, spec.r, spec.g, spec.b, radius)
            if not light then return end
            if cell.addLamppost then cell:addLamppost(light)
            elseif cell.addLightSource then cell:addLightSource(light) end
            lights[#lights + 1] = light
        end)
    end

    if spec.fx then
        -- Directed: the bright sources sit AHEAD of the item, and only a faint spill on its own tile, so
        -- the light no longer looks like it comes out from under the flashlight body. The chain stops at
        -- the first missing square or room change, so the beam never shines through a wall.
        add(spec.x, spec.y, math.floor(spec.radius * BEAM_SPILL_FACTOR + 0.5))
        local originSq = cell:getGridSquare(spec.x, spec.y, spec.z)
        local originRoom = originSq and safeCall(originSq, "getRoomID") or nil
        for _, step in ipairs(BEAM_STEPS) do
            local bx = math.floor(spec.x + spec.fx * step.dist + 0.5)
            local by = math.floor(spec.y + spec.fy * step.dist + 0.5)
            local sq = cell:getGridSquare(bx, by, spec.z)
            if not sq then break end
            if originRoom ~= nil and safeCall(sq, "getRoomID") ~= originRoom then break end
            add(bx, by, math.floor(spec.radius * step.factor + 0.5))
        end
    else
        add(spec.x, spec.y, spec.radius)
    end

    if #lights == 0 then
        dbg("FAILED to create light at %s", key)
        return nil
    end
    active[key] = { lights = lights, sig = sig }
    if spec.fx then
        -- The raw angle is logged next to the direction it produced: that is the calibration data for
        -- BEAM_ANGLE_OFFSET. Drop a flashlight facing all four ways and compare "beam <compass>" with
        -- where the model actually points.
        dbg("light at %s radius=%d sources=%d rot=%s beam %s (%.2f,%.2f)",
            key, spec.radius, #lights, tostring(spec.deg),
            compassOf(spec.fx, spec.fy), spec.fx, spec.fy)
    else
        dbg("light at %s radius=%d sources=%d round", key, spec.radius, #lights)
    end
    return key
end

local function dropLightAtSquare(sq)
    if not sq then return end
    dropLight(keyOf(sq:getX(), sq:getY(), sq:getZ()))
end

-------------------------------------------------------------------------------- switching on the floor
-- Flip a floor light and, in MP, tell everyone else about the INTENT. We never remove and re-add the
-- world item: doing that from a non-authoritative client duplicates it into an unremovable ghost on a
-- dedicated server. Plain field writes are safe on every side.
local function applyLocalState(item, on)
    if isWeaponLight(item) then
        local md = modData(item)
        if md then md.isLightOn = on == true end
    else
        safeCall(item, "setActivated", on == true)
    end
    setIntent(item, on)
    if item and item.transmitModData then pcall(item.transmitModData, item) end
end

local function setFloorLight(item, sq, on)
    if not item then return end
    applyLocalState(item, on)
    if not on then dropLightAtSquare(sq) end
    if sq and isClient() then
        local payload = {
            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
            ft = safeCall(item, "getFullType"),
            on = on and 1 or 0,
        }
        if isServer() then
            -- Host process: authoritative already, just tell the other clients.
            pcall(sendServerCommand, "BetterFlashlights", "BFFloorLightState", payload)
        else
            pcall(sendClientCommand, "BetterFlashlights", "BFFloorLightToggle", payload)
        end
    end
    pcall(function() if sq then sq:playSound(on and "FlashlightOn" or "FlashlightOff") end end)
end

local lastScanMs = 0

-- Public entry point for BF_DropKeepLit.lua: safety net for an item switched on and put down inside the
-- same tick, before the carried tracker ever saw it.
function BF_FloorLights_keepLit(item, sq)
    if not item or not isOurLight(item) then return false end
    if not optEnabled() or not hasCharge(item) then return false end
    dbg("keepLit called for %s", tostring(safeCall(item, "getFullType")))
    setFloorLight(item, sq, true)
    lastScanMs = 0
    return true
end

-- Receiver for the broadcast above: every client flips its own copy and re-lights on the next pass. The
-- intent is synced rather than the item because an in-place item transmit does not reliably carry
-- isActivated to clients that already know the item.
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "BetterFlashlights" or command ~= "BFFloorLightState" or not args then return end
    local cell = getCell(); if not cell then return end
    local sq = cell:getGridSquare(args.x, args.y, args.z); if not sq then return end
    local on = (args.on == 1 or args.on == true)
    local wobs = sq:getWorldObjects()
    for i = 0, (wobs and wobs:size() or 0) - 1 do
        local wo = wobs:get(i)
        local item = wo and safeCall(wo, "getItem")
        if item and isOurLight(item) and safeCall(item, "getFullType") == args.ft then
            applyLocalState(item, on)
            break
        end
    end
    if not on then dropLightAtSquare(sq) end
    lastScanMs = 0
end)

-------------------------------------------------------------------------------- fuel drain
local function useDeltaOf(item)
    local ud = safeCall(item, "getUseDelta")
    if type(ud) ~= "number" or ud <= 0 then
        local script = safeCall(item, "getScriptItem")
        ud = script and safeCall(script, "getUseDelta") or nil
    end
    if type(ud) ~= "number" or ud <= 0 then ud = BF_DEFAULT_USE_DELTA end
    return ud
end

-- The "[NN%]" label of a weapon torch lives in its item NAME, and the name is only rebuilt for the torch
-- in the player's HANDS (BF_WeaponFlashlight.updateBrokenState). Draining one on the ground moved the
-- charge but left the old number on screen in the floor container until it was picked up - exactly the
-- playtest report. BF_WeaponFlashlight exports the rebuild for us.
--
-- The rebuild is driven from the CLIENT only, never from BF_ServerCommands: that file states as a rule
-- that the server does not call setName, because the name is client-authoritative and localised per
-- client. Doing it here also covers MP for free - the server sends the new charge in modData and the
-- scanner relabels using the local language.
--
-- Called from the scanner as well as after a drain, so it only rewrites when the label is actually stale:
-- a torch lying on the floor must not get a setName every single second.
local function refreshWeaponLabel(item)
    if not BF_RefreshWeaponFlashlightName then return end
    local expected = "[" .. tostring(math.floor(chargeOf(item))) .. "%]"
    local name = safeCall(item, "getName")
    if type(name) == "string" and string.find(name, expected, 1, true) then return end
    pcall(BF_RefreshWeaponFlashlightName, item)
end

-- One vanilla Use() of burn. Returns true when the item just went dark.
local function drainFloorItem(item)
    if isWeaponLight(item) then
        local md = modData(item)
        if not md then return false end
        local charge = math.max(0, math.min(100, md.batteryCharge or 0)) - BF_WEAPON_USE_DELTA * 100.0
        if charge < BF_MIN_USABLE_CHARGE then
            md.batteryCharge = 0
            md.isLightOn = false
            md.bfFloorLit = nil
            refreshWeaponLabel(item)
            if item.transmitModData then pcall(item.transmitModData, item) end
            return true
        end
        md.batteryCharge = charge
        refreshWeaponLabel(item)
        if item.transmitModData then pcall(item.transmitModData, item) end
        return false
    end
    -- Subtract exactly one whole use: anything smaller is rounded away by setCurrentUsesFloat.
    local delta = (safeCall(item, "getCurrentUsesFloat") or 0) - useDeltaOf(item)
    if delta * 100.0 < BF_MIN_USABLE_CHARGE then
        safeCall(item, "setCurrentUsesFloat", 0)
        safeCall(item, "setDelta", 0)
        safeCall(item, "setActivated", false)
        local md = modData(item)
        if md then md.bfFloorLit = nil end
        if item.transmitModData then pcall(item.transmitModData, item) end
        return true
    end
    safeCall(item, "setCurrentUsesFloat", delta)
    safeCall(item, "setDelta", delta)
    if item.transmitModData then pcall(item.transmitModData, item) end
    return false
end

-------------------------------------------------------------------------------- scanner
local function forEachFloorItem(cx, cy, cz, radius, fn)
    local cell = getCell(); if not cell then return end
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = cell:getGridSquare(cx + dx, cy + dy, cz)
            local wobs = sq and sq:getWorldObjects()
            local n = wobs and wobs:size() or 0
            if n > 0 then
                for i = 0, n - 1 do
                    local wo = wobs:get(i)
                    local item = wo and safeCall(wo, "getItem")
                    if item and isOurLight(item) then fn(sq, wo, item) end
                end
            end
        end
    end
end

local lastSeenCount = -1

local function scan()
    if not optEnabled() then
        for key in pairs(active) do dropLight(key) end
        return
    end
    local player = getPlayer();               if not player then return end
    local sq0 = player:getCurrentSquare();    if not sq0 then return end

    local seen = {}
    local best = {}   -- key -> spec of the brightest light on that tile
    local found, lit = 0, 0

    forEachFloorItem(sq0:getX(), sq0:getY(), sq0:getZ(), SCAN_RADIUS, function(sq, wo, item)
        found = found + 1
        if not isFloorLightOn(item) then return end
        lit = lit + 1
        -- Keep the dropped model rendering as "on" for an item that is only flag-lit.
        if not isSwitchedOn(item) then
            if isWeaponLight(item) then
                local md = modData(item)
                if md then md.isLightOn = true end
            else
                safeCall(item, "setActivated", true)
            end
        end
        -- Keep the "[NN%]" label of a weapon torch honest while it lies there: in MP the charge arrives
        -- from the server's drain, so relabelling only inside our own drain would miss this client's copy.
        if isWeaponLight(item) then refreshWeaponLabel(item) end
        local radius = radiusOf(item)
        local r, g, b = colorOf(item)
        local fx, fy, deg
        if optDirectional() then fx, fy, deg = facingOf(item, wo) end
        local key = keyOf(sq:getX(), sq:getY(), sq:getZ())
        local cur = best[key]
        if not cur or radius > cur.radius or (r + g + b) > (cur.r + cur.g + cur.b) then
            best[key] = {
                x = sq:getX(), y = sq:getY(), z = sq:getZ(),
                radius = radius, r = r, g = g, b = b, fx = fx, fy = fy, deg = deg,
            }
        end
    end)

    if found ~= lastSeenCount then
        lastSeenCount = found
        dbg("scan: %d of our items on nearby floor, %d lit", found, lit)
    end

    for _, spec in pairs(best) do
        local key = ensureLight(spec)
        if key then seen[key] = true end
    end
    for key in pairs(active) do
        if not seen[key] then dropLight(key) end
    end
end

local lastTrackMs = 0

Events.OnTick.Add(function()
    if isServer() and not isClient() then return end   -- the world light is a client-side render
    local now = getTimestampMs()

    if now - lastTrackMs >= TRACK_INTERVAL_MS then
        lastTrackMs = now
        local player = getPlayer()
        if player then pcall(trackCarriedIntent, player) end
    end

    if now - lastScanMs < SCAN_INTERVAL_MS then return end
    lastScanMs = now
    pcall(scan)
end)

-- Fuel burn for floor lights, SINGLEPLAYER ONLY, on EveryTenMinutes because that is vanilla's cadence of
-- one Use() per 10 in-game minutes (see the FUEL note at the top).
-- In any multiplayer shape the drain belongs to the server: BF_ServerCommands.bfDrainFloorLights owns it,
-- because only the server sees every loaded world item and only one machine may spend the charge. An MP
-- host has isClient() AND isServer() both true, so a `not isServer()` guard here would let the host drain
-- in parallel with its own server thread and burn batteries at double rate. Pure SP has both flags false,
-- and there the server file's handler bails instead.
local function drainFloorLights()
    if not optEnabled() or not optDrainFuel() then return end
    if isClient() or isServer() then return end
    local player = getPlayer();            if not player then return end
    local sq0 = player:getCurrentSquare(); if not sq0 then return end
    local dark = {}
    forEachFloorItem(sq0:getX(), sq0:getY(), sq0:getZ(), SCAN_RADIUS, function(sq, wo, item)
        if not isFloorLightOn(item) then return end
        if drainFloorItem(item) then
            dark[#dark + 1] = sq
            dbg("floor light ran out of charge at %d,%d,%d", sq:getX(), sq:getY(), sq:getZ())
        end
    end)
    -- SP only, so no broadcast is needed: dropping the local light is the whole job.
    for _, sq in ipairs(dark) do dropLightAtSquare(sq) end
    if #dark > 0 then lastScanMs = 0 end
end

if Events.EveryTenMinutes then
    Events.EveryTenMinutes.Add(function() pcall(drainFloorLights) end)
end

-------------------------------------------------------------------------------- context menu
local function onToggleFloorLight(playerNum, wo, sq, on)
    local player = getSpecificPlayer(playerNum); if not player then return end
    local item = wo and safeCall(wo, "getItem"); if not item then return end
    -- Best-effort stroll over to the item, but never gate the toggle on it: walkAdj returns false when
    -- the player already stands on the item's tile, and gating there would make the menu do nothing.
    pcall(function() luautils.walkAdj(player, sq) end)
    setFloorLight(item, sq, on == true)
    lastScanMs = 0
end

local function vanillaHandTorchIcon()
    local okManager, manager = pcall(getScriptManager)
    if not okManager or not manager then return nil end
    local okItem, scriptItem = pcall(manager.FindItem, manager, "Base.HandTorch")
    if not okItem or not scriptItem then return nil end
    local okTexture, texture = pcall(scriptItem.getNormalTexture, scriptItem)
    return okTexture and texture or nil
end

local function moveAfterWorldAction(context, option)
    local options = context and context.options
    if type(options) ~= "table" or not option then return end
    local nativeLabels = {
        [getText("ContextMenu_Take")] = true,
        [getText("ContextMenu_PickUp")] = true,
        [getText("ContextMenu_Grab")] = true,
    }
    local optionIndex, insertAfter
    for index, entry in ipairs(options) do
        if entry == option then optionIndex = index end
        if entry ~= option and nativeLabels[entry.name] then insertAfter = index end
    end
    if not optionIndex then return end
    table.remove(options, optionIndex)
    insertAfter = insertAfter or math.min(1, #options)
    table.insert(options, (insertAfter > 0 and insertAfter + 1 or 1), option)
    for index, entry in ipairs(options) do entry.id = index end
    pcall(function()
        if context.calcHeight then context:calcHeight() end
        if context.calcWidth and context.setWidth then context:setWidth(context:calcWidth()) end
    end)
end

local function addGreyOption(context, label, reason)
    local opt = context:addOptionOnTop(label, nil, nil)
    if not opt then return end
    opt.notAvailable = true
    opt.iconTexture = vanillaHandTorchIcon()
    moveAfterWorldAction(context, opt)
    pcall(function()
        local tt = ISWorldObjectContextMenu.addToolTip()
        tt.description = reason
        opt.toolTip = tt
    end)
end

local function addOptionsFor(context, player, wo, sq)
    if not instanceof(wo, "IsoWorldInventoryObject") then return false end
    local item = safeCall(wo, "getItem"); if not item then return false end
    if not isOurLight(item) then return false end
    local playerNum = player:getPlayerNum()

    if isFloorLightOn(item) then
        local opt = context:addOptionOnTop(tr("FloorTurnOff", "Turn off"), playerNum,
            onToggleFloorLight, wo, sq, false)
        if opt then opt.iconTexture = vanillaHandTorchIcon(); moveAfterWorldAction(context, opt) end
        return true
    end
    if isFloorLightOff(item) then
        local label = tr("FloorTurnOn", "Turn on")
        if not hasCharge(item) then
            addGreyOption(context, label, tr("FloorNoCharge", "No charge left."))
        else
            local opt = context:addOptionOnTop(label, playerNum, onToggleFloorLight, wo, sq, true)
            if opt then opt.iconTexture = vanillaHandTorchIcon(); moveAfterWorldAction(context, opt) end
        end
        return true
    end
    return false
end

-- Dropped items live in sq:getWorldObjects(), NOT in the `worldobjects` list the menu hands us (that is
-- sq:getObjects()), so the clicked tile has to be walked explicitly.
local function fillFloorLightMenu(playerNum, context, worldobjects, test)
    if test then return end
    if not optEnabled() then return end
    local player = getSpecificPlayer(playerNum); if not player then return end
    pcall(function()
        local squares, seen = {}, {}
        local function addSquare(sq)
            if not sq then return end
            local k = keyOf(sq:getX(), sq:getY(), sq:getZ())
            if seen[k] then return end
            seen[k] = true
            squares[#squares + 1] = sq
        end

        if worldobjects then
            if worldobjects.size then
                for i = 0, worldobjects:size() - 1 do addSquare(safeCall(worldobjects:get(i), "getSquare")) end
            else
                for _, o in ipairs(worldobjects) do addSquare(safeCall(o, "getSquare")) end
            end
        end
        if #squares == 0 then addSquare(player:getCurrentSquare()) end

        for _, sq in ipairs(squares) do
            local wobs = sq:getWorldObjects()
            for i = 0, (wobs and wobs:size() or 0) - 1 do
                addOptionsFor(context, player, wobs:get(i), sq)
            end
        end
    end)
end

Events.OnFillWorldObjectContextMenu.Add(fillFloorLightMenu)

-------------------------------------------------------------------------------- pickup
-- Drop the light the moment a lit flashlight leaves the floor, so no spot lingers until the next pass.
-- The intent flag is left alone: the item goes back to the player's hands still switched on, and the
-- carried tracker takes ownership of the flag again.
if ISInventoryTransferAction then
    local _origPerform = ISInventoryTransferAction.perform
    function ISInventoryTransferAction:perform()
        pcall(function()
            local item = self.item
            if not item or not isOurLight(item) then return end
            if not (self.srcContainer and self.srcContainer:getType() == "floor") then return end
            local wo = safeCall(item, "getWorldItem")
            dropLightAtSquare(wo and safeCall(wo, "getSquare"))
            lastScanMs = 0
        end)
        return _origPerform(self)
    end
end

print("[BetterFlashlights] BF_FloorLights.lua loaded: our flashlights light the ground they lie on")
