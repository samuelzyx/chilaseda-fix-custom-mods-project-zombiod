import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_ConfirmItemDelete_B42.lua");
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("fresh-food deletion batches mixed selected item types and removes only the confirmed selection", () => {
  assert.match(modInfo, /^modversion=1\.0\.54$/m);
  assert.match(readme, /^# ChilaSeda - Acciones Accesibles \(Build 42\) 1\.0\.54$/m);
  assert.match(lua, /local TRACE_FOOD_DELETE = true/);
  assert.match(lua, /MAX_FOOD_DELETE_TRACE_LINES = 32/);
  assert.match(lua, /reason=" \.\. tostring\(reason or "-"\)/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "accessible-food-delete-"));
  try {
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixture = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local callbacks = { inventory = {}, floor = {}, tick = {} }
require = function(name)
  if name == "ChilaSeda_ConfirmationDialogKeys_B42" then return { attach = function() end } end
  if name == "ChilaSeda_FoodMenuOrder_B42" then
    ChilaSedaFoodMenuOrder = { move = function() end }
    return ChilaSedaFoodMenuOrder
  end
  return {}
end
instanceof = function(value, className)
  if not value then return false end
  if className == "InventoryItem" then return value.inventoryItem == true end
  if className == "Food" then return value.food == true end
  if className == "InventoryContainer" then return value.inventoryContainer == true end
  if className == "IsoWorldInventoryObject" then return value.worldObject == true end
  return false
end
getTexture = function() return nil end
local scriptManager = {}
function scriptManager:FindItem(fullType)
  return {
    getDisplayName = function() return fullType end,
    getNormalTexture = function() return nil end,
  }
end
getScriptManager = function() return scriptManager end
getText = function(key, count)
  if key == "UI_ChilaSeda_DeleteItem_OptionMany" then return "Delete " .. tostring(count) .. " items" end
  if key == "UI_ChilaSeda_DeleteFood_OptionFresh" then return "Delete fresh (" .. tostring(count) .. ")" end
  if key == "UI_ChilaSeda_DeleteFood_OptionRotten" then return "Delete rotten (" .. tostring(count) .. ")" end
  if key == "UI_ChilaSeda_DeleteFood_OptionStale" then return "Delete stale (" .. tostring(count) .. ")" end
  if key == "UI_ChilaSeda_DeleteFood_OptionBurnt" then return "Delete burnt (" .. tostring(count) .. ")" end
  return key
end
local currentPlayer
getSpecificPlayer = function() return currentPlayer end
getCore = function()
  return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end }
end
triggerEvent = function() end
sendRemoveItemFromContainer = function() end
isClient = function() return true end
lastDialog = nil
ISModalDialog = {}
function ISModalDialog:new(x, y, width, height, text, yesNo, target, callback, playerIndex)
  local dialog = { target = target, callback = callback, text = text }
  function dialog:initialise() end
  function dialog:addToUIManager() end
  function dialog:setAlwaysOnTop() end
  function dialog:bringToTop() end
  lastDialog = dialog
  return dialog
end
Events = {
  OnTick = { Add = function(callback) callbacks.tick[#callbacks.tick + 1] = callback end },
  OnFillInventoryObjectContextMenu = {
    Add = function(callback) callbacks.inventory[#callbacks.inventory + 1] = callback end,
  },
  OnPreFillWorldObjectContextMenu = {
    Add = function(callback) callbacks.floor[#callbacks.floor + 1] = callback end,
  },
}
` + lua + String.raw`
local function makeContainer(kind)
  local container = { kind = kind, items = {}, inventoryContainer = true }
  function container:getType() return self.kind end
  function container:getContainingItem() return nil end
  function container:contains(item)
    for _, candidate in ipairs(self.items) do if candidate == item then return true end end
    return false
  end
  function container:DoRemoveItem(item)
    for index = #self.items, 1, -1 do
      if self.items[index] == item then table.remove(self.items, index); break end
    end
    item.container = nil
  end
  return container
end
local function makeFood(container, name, fullType, state)
  local item = {
    inventoryItem = true, food = true, name = name, fullType = fullType,
    fresh = state == "fresh", rotten = state == "rotten", burnt = state == "burnt",
    container = container,
  }
  function item:getContainer() return self.container end
  function item:getFullType() return self.fullType end
  function item:getName() return self.name end
  function item:getTexture() return nil end
  function item:isBurnt() return self.burnt end
  function item:isRotten() return self.rotten end
  function item:isFresh() return self.fresh end
  function item:getWorldItem() return self.worldItem end
  function item:setWorldItem(value) self.worldItem = value end
  container.items[#container.items + 1] = item
  return item
end
local function makeNormalItem(container, name, fullType)
  local item = {
    inventoryItem = true, food = false, name = name, fullType = fullType,
    container = container,
  }
  function item:getContainer() return self.container end
  function item:getFullType() return self.fullType end
  function item:getName() return self.name end
  function item:getTexture() return nil end
  function item:getWorldItem() return self.worldItem end
  function item:setWorldItem(value) self.worldItem = value end
  container.items[#container.items + 1] = item
  return item
end
local function setPlayerInventory(container)
  currentPlayer = { inventory = container }
  function currentPlayer:getInventory() return self.inventory end
  function currentPlayer:removeAttachedItem() end
  function currentPlayer:isEquipped() return false end
  function currentPlayer:removeFromHands() end
  function currentPlayer:removeWornItem() end
end
local function makeContext()
  local context = { options = {} }
  function context:addOption(label, target, callback, ...)
    local option = { name = label, target = target, callback = callback, args = { ... } }
    self.options[#self.options + 1] = option
    return option
  end
  return context
end
local function optionsFor(context, category)
  local result = {}
  for _, option in ipairs(context.options) do
    if option.chilaSedaDeleteFoodCategory == category then result[#result + 1] = option end
  end
  return result
end
local function selectOption(context, category)
  local matches = optionsFor(context, category)
  assert(#matches == 1, "expected exactly one " .. category .. " option, got " .. tostring(#matches))
  return matches[1]
end
local function confirm(option, answer)
  lastDialog = nil
  option.callback(option.target, option.args[1], option.args[2])
  assert(lastDialog and type(lastDialog.callback) == "function", "the option must request confirmation")
  lastDialog.callback(lastDialog.target, { internal = answer or "YES" })
end
local function confirmGeneric(option)
  lastDialog = nil
  option.callback(option.target, option.args[1])
  assert(lastDialog and type(lastDialog.callback) == "function", "generic delete must request confirmation")
  lastDialog.callback(lastDialog.target, { internal = "YES" })
end

local inv = makeContainer("inventory")
setPlayerInventory(inv)
local brain = makeFood(inv, "Animal brain", "Base.AnimalBrain", "fresh")
local porkChop = makeFood(inv, "Pork chop", "Base.PorkChop", "fresh")
local unselectedBrain = makeFood(inv, "Unselected brain", "Base.AnimalBrain", "fresh")
local context = makeContext()
local selection = { { items = { brain, porkChop } } }
callbacks.inventory[1](0, context, selection)
callbacks.inventory[2](0, context, selection)
local fresh = selectOption(context, "fresh")
assert(fresh.name == "Delete fresh (2)", "mixed selected types must share one selected-count option")
assert(#fresh.args[2] == 2, "the option must capture the two selected items only")
confirm(fresh)
assert(brain.container == nil and porkChop.container == nil, "confirmation must remove both selected fresh foods")
assert(unselectedBrain.container == inv, "same-type unselected items must remain in the inventory")
assert(logs[#logs - 1]:find("food-delete event=menu category=fresh selected=2", 1, true))
assert(logs[#logs]:find("food-delete event=result category=fresh selected=2 removed=2", 1, true))

local mixed = makeContainer("inventory")
setPlayerInventory(mixed)
local freshBrain = makeFood(mixed, "Fresh brain", "Base.AnimalBrain", "fresh")
local normalSkull = makeNormalItem(mixed, "Cow skull", "Base.Cow_Skull")
local mixedContext = makeContext()
local mixedSelection = { freshBrain, normalSkull }
callbacks.inventory[1](0, mixedContext, mixedSelection)
callbacks.inventory[2](0, mixedContext, mixedSelection)
assert(#optionsFor(mixedContext, "fresh") == 1 and #optionsFor(mixedContext, "rotten") == 0,
  "the normal skull must not be counted as food in any freshness batch")
local oneFresh = selectOption(mixedContext, "fresh")
assert(oneFresh.name == "Delete fresh (1)",
  "the fresh option count must include only the genuinely fresh brain")
confirm(oneFresh)
assert(freshBrain.container == nil and normalSkull.container == mixed,
  "fresh cleanup must remove the brain and leave the non-food skull untouched")

local genericContainer = makeContainer("inventory")
setPlayerInventory(genericContainer)
local genericFresh = makeFood(genericContainer, "Fresh brain", "Base.AnimalBrain", "fresh")
local genericSkull = makeNormalItem(genericContainer, "Cow skull", "Base.Cow_Skull")
local genericContext = makeContext()
local genericSelection = { { items = { genericFresh, genericSkull } } }
callbacks.inventory[1](0, genericContext, genericSelection)
callbacks.inventory[2](0, genericContext, genericSelection)
local genericOption
for _, option in ipairs(genericContext.options) do
  if option.chilaSedaDeleteObject then genericOption = option end
end
assert(genericOption and genericOption.name == "Delete 2 items",
  "the general delete option must count both selected objects without freshness filtering")
confirmGeneric(genericOption)
assert(genericFresh.container == nil and genericSkull.container == nil,
  "the general delete option must remove both the brain and normal skull")

local changed = makeContainer("inventory")
setPlayerInventory(changed)
local changedItem = makeFood(changed, "Changing food", "Base.Food", "fresh")
local changedContext = makeContext()
local changedSelection = { { items = { changedItem } } }
callbacks.inventory[1](0, changedContext, changedSelection)
callbacks.inventory[2](0, changedContext, changedSelection)
local changedOption = selectOption(changedContext, "fresh")
changedOption.callback(changedOption.target, changedOption.args[1], changedOption.args[2])
changedItem.fresh = false
lastDialog.callback(lastDialog.target, { internal = "YES" })
assert(changedItem.container == changed,
  "the confirmation must recheck freshness and skip an item whose state changed")
assert(logs[#logs]:find("reason=skipped=1", 1, true))

local left = makeContainer("inventory")
local right = makeContainer("inventory")
setPlayerInventory(left)
local leftFood = makeFood(left, "Left", "Base.AnimalBrain", "fresh")
local rightFood = makeFood(right, "Right", "Base.Cow_Skull", "fresh")
local splitContext = makeContext()
local splitSelection = { { items = { leftFood, rightFood } } }
callbacks.inventory[1](0, splitContext, splitSelection)
callbacks.inventory[2](0, splitContext, splitSelection)
assert(#optionsFor(splitContext, "fresh") == 0,
  "mixed-container selections must not offer a misleading partial freshness batch")
assert(logs[#logs]:find("reason=mixed-containers-or-empty-selection", 1, true))

local floor = makeContainer("floor")
setPlayerInventory(makeContainer("inventory"))
local floorBrain = makeFood(floor, "Floor brain", "Base.AnimalBrain", "fresh")
local floorSkull = makeNormalItem(floor, "Floor skull", "Base.DeerStag_Skull")
local square = { transmitRemoveItemFromSquare = function() end }
local function makeWorldItem(item)
  local worldItem = { worldObject = true, item = item, square = square }
  function worldItem:getItem() return self.item end
  function worldItem:getSquare() return self.square end
  function worldItem:removeFromWorld() self.removed = true end
  function worldItem:removeFromSquare() self.removedFromSquare = true end
  function worldItem:setSquare(value) self.square = value end
  item.worldItem = worldItem
  return worldItem
end
local floorBrainWorld = makeWorldItem(floorBrain)
local floorSkullWorld = makeWorldItem(floorSkull)
local floorContext = makeContext()
callbacks.floor[1](0, floorContext, { floorBrainWorld, floorSkullWorld }, false)
local floorFresh = selectOption(floorContext, "fresh")
assert(floorFresh.name == "Delete fresh (1)", "floor freshness count must exclude the normal skull")
confirm(floorFresh)
assert(floorBrain.container == nil and floorSkull.container == floor,
  "floor freshness cleanup must remove the fresh brain and leave the normal skull")
assert(floorBrainWorld.removed and not floorSkullWorld.removed,
  "only the fresh brain world object must be removed by the freshness option")

local cancelContainer = makeContainer("inventory")
setPlayerInventory(cancelContainer)
local cancelItem = makeFood(cancelContainer, "Cancel me", "Base.Food", "fresh")
local cancelContext = makeContext()
local cancelSelection = { { items = { cancelItem } } }
callbacks.inventory[1](0, cancelContext, cancelSelection)
callbacks.inventory[2](0, cancelContext, cancelSelection)
confirm(selectOption(cancelContext, "fresh"), "NO")
assert(cancelItem.container == cancelContainer, "canceling the confirmation must preserve every item")

local traceContainer = makeContainer("inventory")
local traceItem = makeFood(traceContainer, "Trace food", "Base.Food", "fresh")
for _ = 1, 64 do
  callbacks.inventory[2](0, makeContext(), { { items = { traceItem } } })
end
assert(#logs == 33, "food-delete traces must stop at 32 lines plus the one load message")
`;
    const fixturePath = path.join(tempDir, "food-delete-selected-batch.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
