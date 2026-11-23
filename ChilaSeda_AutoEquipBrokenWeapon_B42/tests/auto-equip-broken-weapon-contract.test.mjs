import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_AutoEquipBrokenWeapon.lua");
const luaSource = fs.readFileSync(luaPath, "utf8");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const gameJar = "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");

test("broken weapon replacement compiles and follows inventory, class, and strict chord contracts", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "broken-weapon-kahlua-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );

    const contractPath = path.join(tempDir, "broken-weapon-contract.lua");
    const contract = `
local output, traces, eaten, queued = {}, {}, {}, {}
print = function(value) traces[#traces + 1] = value end
local keyState = {}
Keyboard = {
  KEY_A = 30, KEY_S = 31, KEY_B = 48, KEY_V = 47,
  KEY_LCONTROL = 29, KEY_RCONTROL = 157,
  KEY_LMENU = 56, KEY_RMENU = 184, KEY_LSHIFT = 42, KEY_RSHIFT = 54,
  isKeyDown = function(key) return keyState[key] == true end,
  getKeyName = function(key) return ({ [30] = "A", [31] = "S", [48] = "B", [47] = "V" })[key] or tostring(key) end,
}
GameKeyboard = { eatKeyPress = function(key) eaten[#eaten + 1] = key end }
HaloTextHelper = { addText = function(player, message) output[#output + 1] = message end }
local function event()
  local result = { handlers = {} }
  result.Add = function(callback) result.handlers[#result.handlers + 1] = callback end
  return result
end
Events = {
  OnWeaponHitXp = event(), OnWeaponHitTree = event(), OnPlayerUpdate = event(),
  OnKeyStartPressed = event(), OnGameBoot = event(), OnGameStart = event(),
}
local options = {}
PZAPI = { ModOptions = { create = function(self, id, name)
  local page = {}
  function page:addTitle() end
  function page:addDescription() end
  function page:addKeyBind(id, label, key)
    local option = { key = key }
    function option:getValue() return self.key end
    options[id] = option
    return option
  end
  return page
end } }
local function list(values)
  return {
    values = values,
    size = function(self) return #self.values end,
    get = function(self, index) return self.values[index + 1] end,
    getItemByIndex = function(self, index) return self.values[index + 1] end,
  }
end
local function container(values)
  local result = { items = values or {} }
  function result:getItems() return list(self.items) end
  return result
end
local function weapon(fullType, perk, condition, ranged)
  local result = {
    fullType = fullType, perk = perk, condition = condition,
    isWeapon = true, ranged = ranged == true,
  }
  function result:getFullType() return self.fullType end
  function result:getPerk() return self.perk end
  function result:getCondition() return self.condition end
  function result:isBroken() return self.condition <= 0 end
  function result:isRanged() return self.ranged end
  function result:getDisplayName() return self.fullType end
  function result:getID() return self.fullType end
  function result:getContainer() return self.parent end
  function result:isTwoHandWeapon() return false end
  function result:isRequiresEquippedBothHands() return false end
  return result
end
local function bag(values)
  local result = { isContainer = true, inventory = container(values) }
  function result:getInventory() return self.inventory end
  return result
end
local broken = weapon("Base.KitchenKnife", "SmallBlade", 0)
local sameInBag = weapon("Base.KitchenKnife", "SmallBlade", 10)
local differentTypeSameClass = weapon("Base.HuntingKnife", "SmallBlade", 10)
local otherClassInWornBag = weapon("Base.HandAxe", "Axe", 10)
local ranged = weapon("Base.Pistol", "Aiming", 10, true)
local nestedBag = bag({ sameInBag })
local carriedRoot = container({ broken, nestedBag, differentTypeSameClass, ranged })
nestedBag.parent = carriedRoot
sameInBag.parent = nestedBag.inventory
local wornBag = bag({ otherClassInWornBag })
otherClassInWornBag.parent = wornBag.inventory
local worn = list({ wornBag })
local player = {
  inventory = carriedRoot, worn = worn, primary = broken, playerNum = 0,
}
function player:getInventory() return self.inventory end
function player:getWornItems() return self.worn end
function player:getPrimaryHandItem() return self.primary end
function player:getSecondaryHandItem() return nil end
function player:getPlayerNum() return self.playerNum end
getSpecificPlayer = function(number) return number == 0 and player or nil end
instanceof = function(item, class)
  if class == "HandWeapon" then return item.isWeapon == true end
  if class == "InventoryContainer" then return item.isContainer == true end
  return false
end
ISInventoryPaneContextMenu = {
  equipWeapon = function(item, primary, bothHands, playerNumber)
    queued[#queued + 1] = { item = item, primary = primary, bothHands = bothHands, playerNumber = playerNumber }
  end,
}

${luaSource}

local api = ChilaSedaAutoEquipBrokenWeapon
assert(api and api.findReplacement and api.onWeaponHit and api.onKeyStartPressed)
local pendingWeapon = weapon("Base.HuntingKnife", "SmallBlade", 8)
Events.OnWeaponHitXp.handlers[1](player, pendingWeapon)
Events.OnPlayerUpdate.handlers[1](player)
Events.OnPlayerUpdate.handlers[1](player)
assert(#output == 0, "a healthy weapon must not create a broken notice")

Events.OnWeaponHitXp.handlers[1](player, broken)
Events.OnPlayerUpdate.handlers[1](player)
assert(#output == 1 and output[1]:find("Ctrl+A", 1, true) and output[1]:find("Ctrl+S", 1, true),
  "a broken melee weapon must show the two configured choices")

keyState[Keyboard.KEY_LCONTROL] = true
api.onKeyStartPressed(Keyboard.KEY_A)
assert(eaten[#eaten] == Keyboard.KEY_A, "Ctrl+A must consume the base key press")
assert(queued[#queued] and queued[#queued].item == sameInBag, "same-type search must reach a carried backpack")
assert(queued[#queued].primary == true and queued[#queued].playerNumber == 0,
  "replacement must use vanilla primary-hand equip flow")

player.primary = broken
local anotherBroken = weapon("Base.KitchenKnife", "SmallBlade", 0)
Events.OnWeaponHitXp.handlers[1](player, anotherBroken)
Events.OnPlayerUpdate.handlers[1](player)
api.onKeyStartPressed(Keyboard.KEY_S)
assert(queued[#queued].item == otherClassInWornBag,
  "other-class search must skip another SmallBlade and include a worn backpack")

options.sameWeaponKey.key = Keyboard.KEY_B
options.otherClassKey.key = Keyboard.KEY_V
api.applyOptions()
keyState[Keyboard.KEY_LCONTROL] = false
local countBeforeUnmodified = #queued
api.onKeyStartPressed(Keyboard.KEY_B)
assert(#queued == countBeforeUnmodified and eaten[#eaten] == Keyboard.KEY_S,
  "an unmodified configured key must not activate or be consumed")
player.primary = anotherBroken
local thirdBroken = weapon("Base.HuntingKnife", "SmallBlade", 0)
Events.OnWeaponHitXp.handlers[1](player, thirdBroken)
Events.OnPlayerUpdate.handlers[1](player)
keyState[Keyboard.KEY_LCONTROL] = true
api.onKeyStartPressed(Keyboard.KEY_V)
assert(eaten[#eaten] == Keyboard.KEY_V, "reconfigured Ctrl+V must be consumed")
assert(queued[#queued].item == otherClassInWornBag, "reconfigured key must preserve replacement selection")

keyState[Keyboard.KEY_LSHIFT] = true
local countBeforeExtraModifier = #queued
api.onKeyStartPressed(Keyboard.KEY_B)
assert(#queued == countBeforeExtraModifier, "Ctrl+Shift must not masquerade as the exact Ctrl chord")

assert(traces[1]:find("settings result=ready", 1, true), "settings load must be traced")
assert(table.concat(traces, "\\n"):find("inventory-scan root=true worn=true", 1, true),
  "inventory search source and outcome must be traced")
`;
    fs.writeFileSync(contractPath, contract, "utf8");
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
