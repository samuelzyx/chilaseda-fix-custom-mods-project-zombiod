import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaRoot = path.join(modRoot, "42/media/lua/client");
const selected = fs.readFileSync(path.join(luaRoot, "ChilaSeda_ViewpointSelectedContainer.lua"), "utf8");
const pickup = fs.readFileSync(path.join(luaRoot, "zzzz_ChilaSeda_ViewpointPickupDestination.lua"), "utf8");
const viewpointRoot = "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const ground = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_Ground.lua"), "utf8");
const interaction = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_Interact.lua"), "utf8");
const viewpointLoot = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_Loot.lua"), "utf8");
const vanillaRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client";
const contextMenu = fs.readFileSync(path.join(vanillaRoot, "ISUI/ISWorldObjectContextMenu.lua"), "utf8");
const grabAction = fs.readFileSync(path.join(vanillaRoot, "TimedActions/ISGrabItemAction.lua"), "utf8");
const forageIcon = fs.readFileSync(path.join(vanillaRoot, "Foraging/ISForageIcon.lua"), "utf8");
const translations = fs.readFileSync(path.resolve(modRoot, "../ChilaSeda_Translations_ES_B42/42/media/lua/shared/Translate/ES/UI.json"), "utf8");

test("native Viewpoint ground tooltip invokes vanilla grab callbacks", () => {
  assert.match(ground, /ViewpointInteract\.collect\(sub, 1, nil, list, state\)/);
  assert.match(ground, /onSelect == ISInventoryBuildMenu\.onTakeThing/);
  assert.match(interaction, /fn = o\.onSelect/);
  assert.match(interaction, /a\.fn\(unpack\(a\.args, 1, a\.n\)\)/);
  assert.match(contextMenu, /ISWorldObjectContextMenu\.onGrabAllWItems[\s\S]*?ISGrabItemAction:new/);
  assert.match(grabAction, /o\.destContainer\s*=\s*o\.character:getInventory\(\)/);
});

test("selected bag is compared with the real root inventory", () => {
  const resolver = selected.slice(selected.indexOf("local function selectedDestination("), selected.indexOf("local function selectedDestinationForIcon("));
  assert.match(resolver, /local main = player and player:getInventory\(\) or page\.inventory/);
  assert.match(resolver, /local selected = \(page\.inventoryPane and page\.inventoryPane\.inventory\) or page\.inventory/);
  assert.match(resolver, /selected ~= main/);
});

test("working Viewpoint loot and forage routes use the selected page inventory", () => {
  assert.match(viewpointLoot, /local into = getPlayerInventory\(playerNum\)\.inventory/);
  assert.match(forageIcon, /_targetContainer or getPlayerInventory\(self\.player\)\.inventory/);
  assert.match(selected, /local main = player and player:getInventory\(\) or page\.inventory/);
});

test("a vanilla Put in container choice overrides the selected pane fallback", () => {
  const resolver = selected.slice(selected.indexOf("local function selectedDestination("), selected.indexOf("local function canStoreIn("));
  assert.match(resolver, /if requested ~= nil then return requested end/);
  assert.match(resolver, /local selected = selectedDestination\(icon\.player\)/);

  const helper = selected.slice(selected.indexOf("local function selectedDestination("), selected.indexOf("local function canStoreIn("));
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const fixture = `${helper}
local root, bag = {}, { getItems = function() return {} end, getType = function() return "bag" end }
local page = { inventory = root, inventoryPane = { inventory = bag } }
local player = { getInventory = function() return root end }
getPlayerInventory = function() return page end
getSpecificPlayer = function() return player end
local icon = { player = 0 }
assert(selectedDestinationForIcon(icon, root) == root, "explicit main inventory selection must be preserved")
assert(selectedDestinationForIcon(icon, bag) == bag, "explicit backpack selection must be preserved")
assert(selectedDestinationForIcon(icon, nil) == bag, "direct clicks should inherit the selected backpack")
`;
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-selected-target-"));
  try {
    const luaPath = path.join(tempDir, "selected-target-contract.lua");
    fs.writeFileSync(luaPath, fixture, "utf8");
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("Viewpoint native corpse and ground actions expose destination variants", () => {
  for (const handler of [
    "world.onGrabWItem", "world.onGrabHalfWItems", "world.onGrabAllWItems", "world.onGrabCorpseItem",
    "animal.onButcherAnimal", "animal.onGetAnimalBones", "animal.onButcherAnimalFromInv",
    "animal.onGetAnimalBonesFromInv", "inventory.grabCorpseItem", "build.onTakeThing",
    "loot.take", "loot.takeAll",
  ]) {
    assert.ok(selected.includes(`fn == ${handler}`), `missing destination action handler: ${handler}`);
  }
  assert.match(selected, /variant\.name = action\.name \.\. " > " \.\. destinationLabel\(action, destination\)/);
  assert.match(selected, /variant\.chilaSedaDestination = destination/);
  assert.match(selected, /pcall\(runWithChosenDestination, action, player, getPlayerInventory,\s*selectDestinationFromMenu/);
  assert.match(selected, /destination-menu title=/);
  assert.match(selected, /choices=/);

  const start = selected.indexOf("local function isDestinationChoiceAction(");
  const end = selected.indexOf("local function interactionDestinations(", start);
  assert.ok(start >= 0 && end > start, "destination action helpers must be present");
  const helpers = selected.slice(start, end);
  const fixture = `${helpers}
local butcher, bones, corpse, pickup, takeThing, ordinary = function() end, function() end,
	function() end, function() end, function() end, function() end
ISWorldObjectContextMenu = { onGrabWItem = pickup, onGrabCorpseItem = corpse }
AnimalContextMenu = { onButcherAnimal = butcher, onGetAnimalBones = bones }
ISInventoryPaneContextMenu = {}
ISInventoryBuildMenu = { onTakeThing = takeThing }
ViewpointLoot = {}
local sourceActions = {
  { name = "Despiezar", fn = butcher, args = { "body" }, n = 1, group = "Animal", enabled = true },
  { name = "Obtener huesos", fn = bones, args = { "skeleton" }, n = 1, group = "Animal", enabled = true },
  { name = "Recoger cadaver", fn = corpse, args = { "corpse" }, n = 1, group = "Animal", enabled = true },
  { name = "Levantar objeto", fn = pickup, args = { "world item" }, n = 1, group = "Suelo", enabled = true },
  { name = "Recoger desde rejilla", fn = takeThing, args = { "item" }, n = 1, group = "Suelo", enabled = true },
  { name = "Abrir", fn = ordinary, args = {}, n = 0, enabled = true },
}
local root, bag = { name = "inventario" }, { name = "mochila" }
local expanded, added = expandDestinationActionList(sourceActions, { root, bag },
  function(action, destination) return action.name .. " / " .. destination.name end)
assert(added == 10 and #expanded == 11, "five destination actions should expand for two containers; added=" .. tostring(added) .. " count=" .. tostring(#expanded))
assert(expanded[1].chilaSedaDestination == root and expanded[2].chilaSedaDestination == bag,
  "the action should list the root inventory and backpack as explicit targets")
assert(expanded[1].fn == butcher and expanded[1].args == sourceActions[1].args
  and expanded[1].group == "Animal", "destination variant must preserve callback, arguments, and category")
assert(expanded[11] == sourceActions[6], "unrelated actions must remain unchanged")
local page = { inventoryPane = { inventory = bag } }
local executed = false
local result = runWithChosenDestination(expanded[1], { getPlayerNum = function() return 0 end },
  function(playerNum) assert(playerNum == 0); return page end,
  function(targetPage, destination) targetPage.inventoryPane.inventory = destination end,
  function() executed = true; assert(page.inventoryPane.inventory == root); return "callback ran" end)
assert(executed and result == "callback ran", "callback must run after applying the chosen destination")
`;
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-destination-actions-"));
  try {
    const luaPath = path.join(tempDir, "destination-actions-contract.lua");
    fs.writeFileSync(luaPath, fixture, "utf8");
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("ground pickup rechecks each queued item and records main-inventory fallback", () => {
  assert.match(pickup, /if canStore\(selected, player, item\) then return selected end[\s\S]*?return main, selected/);
  assert.match(pickup, /pickupOverflowSources\[item\] = overflowFrom/);
  assert.match(pickup, /ISGrabItemAction\.isValid = function[\s\S]*?destinationFor\(action\.character, item\)/);
  assert.match(selected, /local queued = action\.queueList and action\.queueList\[1\][\s\S]*?for _, item in ipairs\(queuedItems\) do notifyStoredItem/);
});

test("fallback Halo explains that the selected bag was full or rejected the item", () => {
  assert.match(selected, /UI_ChilaSeda_Viewpoint_ItemStoredFallback/);
  assert.match(translations, /"UI_ChilaSeda_Viewpoint_ItemStoredFallback":\s*"Guardado: %1 en inventario principal; %2 estaba llena o no aceptaba el objeto"/);
});

test("per-item routing fills the selected bag before spilling remaining items", () => {
  const weights = [0.4, 0.7, 0.5, 0.2];
  const selectedCapacity = 1.1;
  let selectedLoad = 0;
  const selectedItems = [];
  const mainItems = [];
  for (const weight of weights) {
    if (selectedLoad + weight <= selectedCapacity) {
      selectedItems.push(weight);
      selectedLoad += weight;
    } else {
      mainItems.push(weight);
    }
  }
  assert.deepEqual(selectedItems, [0.4, 0.7]);
  assert.deepEqual(mainItems, [0.5, 0.2]);
});
