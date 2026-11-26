import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_AutoEquipBrokenWeapon.lua");
const luaSource = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const gameJar = "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");

test("broken weapon replacement compiles and applies persisted delete/keep choice without changing Ctrl chords", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.match(modInfo, /^modversion=1\.0\.3$/m);
  assert.match(readme, /^# ChilaSeda - Reemplazo rapido de armas rotas \(Build 42\) 1\.0\.3$/m);
  assert.match(readme, /cola protegida de Viewpoint Fix/);
  assert.match(luaSource, /viewpointHalo\.showProtected/);
  assert.match(luaSource, /fallback protected-halo route=HaloTextHelper\.addText/);
  assert.match(readme, /Eliminar el arma melee rota al cambiar/);
  assert.match(luaSource, /DELETE_BROKEN_OPTION_ID = "deleteBrokenWeapon"/);
  assert.match(luaSource, /local deleteBrokenWeapon = true/);
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
local output, traces, eaten, queued, protectedNotices = {}, {}, {}, {}, {}
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
ChilaSeda_ViewpointHaloNotifications = {
  showProtected = function(text, color, icon, duration, source)
    protectedNotices[#protectedNotices + 1] = {
      text = text, color = color, icon = icon, duration = duration, source = source,
    }
    return true
  end,
}
local function event()
  local result = { handlers = {} }
  result.Add = function(callback) result.handlers[#result.handlers + 1] = callback end
  return result
end
Events = {
  OnWeaponHitXp = event(), OnWeaponHitTree = event(), OnPlayerUpdate = event(),
  OnKeyStartPressed = event(), OnGameBoot = event(), OnGameStart = event(), OnTick = event(),
}
local options = {}
PZAPI = { ModOptions = { create = function(self, id, name)
  local page = {}
  function page:addTitle() end
  function page:addDescription() end
    function page:addTickBox(id, label, default, tooltip)
      local option = { key = default, label = label, tooltip = tooltip }
      function option:getValue() return self.key end
      options[id] = option
      return option
    end
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
  for _, item in ipairs(result.items) do item.parent = result end
  function result:getItems() return list(self.items) end
  function result:contains(item)
    for _, candidate in ipairs(self.items) do if candidate == item then return true end end
    return false
  end
  function result:AddItem(item)
    self.items[#self.items + 1] = item
    item.parent = self
    return item
  end
  function result:Remove(item)
    for index = #self.items, 1, -1 do
      if self.items[index] == item then
        table.remove(self.items, index)
        item.parent = nil
      end
    end
  end
  return result
end
local nextWeaponId = 0
local function weapon(fullType, perk, condition, ranged)
  nextWeaponId = nextWeaponId + 1
  local result = {
    fullType = fullType, perk = perk, condition = condition,
    id = nextWeaponId, isWeapon = true, ranged = ranged == true,
  }
  function result:getFullType() return self.fullType end
  function result:getPerk() return self.perk end
  function result:getCondition() return self.condition end
  function result:isBroken() return self.condition <= 0 end
  function result:isRanged() return self.ranged end
  function result:getDisplayName() return self.fullType end
  function result:getID() return self.id end
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
function player:isDead() return false end
function player:isAttacking() return false end
getSpecificPlayer = function(number) return number == 0 and player or nil end
instanceof = function(item, class)
  if class == "HandWeapon" then return item.isWeapon == true end
  if class == "InventoryContainer" then return item.isContainer == true end
  return false
end
local queues = {}
ISTimedActionQueue = {
  add = function(action)
    local queue = queues[action.character]
    if not queue then queue = { character = action.character, queue = {} }; queues[action.character] = queue end
    queue.queue[#queue.queue + 1] = action
    queued[#queued + 1] = action
  end,
  resetQueue = function(queue) queue.queue = {} end,
  getTimedActionQueue = function(character) return queues[character] end,
}
require = function(name)
  if name == "TimedActions/ISTimedActionQueue" then return ISTimedActionQueue end
  return {}
end
ISInventoryPaneContextMenu = {
  equipWeapon = function(item, primary, bothHands, playerNumber)
    local action = {
      character = player, item = item, primary = primary,
      bothHands = bothHands, playerNumber = playerNumber,
      stopOnWalk = false, stopOnRun = true, stopOnAim = false,
    }
    ISTimedActionQueue.add(action)
  end,
}

${luaSource}

local api = ChilaSedaAutoEquipBrokenWeapon
assert(api and api.findReplacement and api.onWeaponHit and api.onKeyStartPressed)
assert(options.deleteBrokenWeapon and options.deleteBrokenWeapon:getValue() == true,
  "broken melee deletion should be enabled in Mod Options by default")
local pendingWeapon = weapon("Base.HuntingKnife", "SmallBlade", 8)
Events.OnWeaponHitXp.handlers[1](player, pendingWeapon)
Events.OnPlayerUpdate.handlers[1](player)
Events.OnPlayerUpdate.handlers[1](player)
assert(#output == 0 and #protectedNotices == 0, "a healthy weapon must not create a broken notice")

Events.OnWeaponHitXp.handlers[1](player, broken)
Events.OnPlayerUpdate.handlers[1](player)
assert(#protectedNotices == 1 and #output == 0
    and protectedNotices[1].text:find("Ctrl+A", 1, true)
    and protectedNotices[1].text:find("Ctrl+S", 1, true),
  "a broken melee weapon must show the two configured choices")
assert(protectedNotices[1].source == "AutoEquipBrokenWeapon"
    and protectedNotices[1].color.r == 1
    and protectedNotices[1].color.g > 0.85 and protectedNotices[1].color.g < 0.88,
  "the broken-weapon prompt must use the protected Viewpoint Halo route and keep its color")

keyState[Keyboard.KEY_LCONTROL] = true
api.onKeyStartPressed(Keyboard.KEY_A)
assert(eaten[#eaten] == Keyboard.KEY_A, "Ctrl+A must consume the base key press")
assert(queued[#queued] and queued[#queued].item == sameInBag, "same-type search must reach a carried backpack")
assert(queued[#queued].primary == true and queued[#queued].playerNumber == 0,
  "replacement must use vanilla primary-hand equip flow")
assert(queued[#queued].stopOnRun == false,
  "running must not cancel the queued replacement equip action")
assert(carriedRoot:contains(broken) and broken.parent == carriedRoot,
  "the broken weapon must stay in inventory until the replacement is equipped")
local firstQueue = queues[player]
local queuedBeforeRepeat = #queued
api.onKeyStartPressed(Keyboard.KEY_A)
assert(#queued == queuedBeforeRepeat,
  "repeated Ctrl+A must not enqueue duplicate replacement actions")
ISTimedActionQueue.resetQueue(firstQueue)
Events.OnTick.handlers[1]()
assert(#queued == queuedBeforeRepeat,
  "the queue reset must wait one tick before resuming")
Events.OnTick.handlers[1]()
assert(#queued == queuedBeforeRepeat + 1 and queued[#queued].item == sameInBag,
  "an interrupted same-type replacement must be automatically re-queued")
player.primary = sameInBag
firstQueue.queue = {}
Events.OnTick.handlers[1]()
assert(not carriedRoot:contains(broken) and broken.parent == nil,
  "the broken weapon should only be removed after the replacement reaches a hand")
assert(api.pendingEquipRequests[player] == nil,
  "successful completion must clear the pending replacement request")
assert(table.concat(traces, "\\n"):find("broken-weapon result=removed", 1, true),
  "successful deletion should be logged")

local anotherBroken = weapon("Base.KitchenKnife", "SmallBlade", 0)
carriedRoot:AddItem(anotherBroken)
player.primary = anotherBroken
options.deleteBrokenWeapon.key = false
api.applyOptions()
assert(options.deleteBrokenWeapon:getValue() == false,
  "the Mod Options value should remain false when settings are reapplied")
Events.OnGameStart.handlers[1]()
assert(options.deleteBrokenWeapon:getValue() == false,
  "a game-start settings reload should preserve the saved false tickbox")
Events.OnWeaponHitXp.handlers[1](player, anotherBroken)
Events.OnPlayerUpdate.handlers[1](player)
api.onKeyStartPressed(Keyboard.KEY_S)
assert(queued[#queued].item == otherClassInWornBag,
  "other-class search must skip another SmallBlade and include a worn backpack")
assert(carriedRoot:contains(anotherBroken),
  "the disabled option must keep the broken melee item while Ctrl+S replacement is pending")
player.primary = otherClassInWornBag
queues[player].queue = {}
Events.OnTick.handlers[1]()
assert(carriedRoot:contains(anotherBroken),
  "the disabled option must preserve the broken weapon after equip completion")
assert(table.concat(traces, "\\n"):find("broken-weapon result=retained reason=option-disabled", 1, true),
  "retaining the broken item should be logged after equip completion")

options.sameWeaponKey.key = Keyboard.KEY_B
options.otherClassKey.key = Keyboard.KEY_V
options.deleteBrokenWeapon.key = true
api.applyOptions()
keyState[Keyboard.KEY_LCONTROL] = false
local countBeforeUnmodified = #queued
api.onKeyStartPressed(Keyboard.KEY_B)
assert(#queued == countBeforeUnmodified and eaten[#eaten] == Keyboard.KEY_S,
  "an unmodified configured key must not activate or be consumed")
player.primary = anotherBroken
local thirdBroken = weapon("Base.HuntingKnife", "SmallBlade", 0)
carriedRoot:AddItem(thirdBroken)
Events.OnWeaponHitXp.handlers[1](player, thirdBroken)
Events.OnPlayerUpdate.handlers[1](player)
keyState[Keyboard.KEY_LCONTROL] = true
api.onKeyStartPressed(Keyboard.KEY_V)
assert(eaten[#eaten] == Keyboard.KEY_V, "reconfigured Ctrl+V must be consumed")
assert(queued[#queued].item == otherClassInWornBag, "reconfigured key must preserve replacement selection")
assert(carriedRoot:contains(thirdBroken),
  "the broken weapon must stay in inventory while the reconfigured replacement is pending")
player.primary = otherClassInWornBag
queues[player].queue = {}
Events.OnTick.handlers[1]()
assert(not carriedRoot:contains(thirdBroken),
  "re-enabling the delete option must remove the next broken weapon after equip completion")

keyState[Keyboard.KEY_LSHIFT] = true
local countBeforeExtraModifier = #queued
api.onKeyStartPressed(Keyboard.KEY_B)
assert(#queued == countBeforeExtraModifier, "Ctrl+Shift must not masquerade as the exact Ctrl chord")

assert(traces[1]:find("settings result=ready", 1, true), "settings load must be traced")
assert(table.concat(traces, "\\n"):find("inventory-scan root=true worn=true", 1, true),
  "inventory search source and outcome must be traced")

ChilaSeda_ViewpointHaloNotifications = nil
local fallbackBroken = weapon("Base.Axe", "Axe", 0)
Events.OnWeaponHitXp.handlers[1](player, fallbackBroken)
assert(output[#output] and output[#output]:find("Ctrl+B", 1, true),
  "the broken-weapon prompt must fall back to native Halo when Viewpoint is unavailable")
assert(table.concat(traces, "\\n"):find(
    "fallback protected-halo route=HaloTextHelper.addText reason=viewpoint-api-unavailable", 1, true),
  "the optional Viewpoint integration fallback must be traced")
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
