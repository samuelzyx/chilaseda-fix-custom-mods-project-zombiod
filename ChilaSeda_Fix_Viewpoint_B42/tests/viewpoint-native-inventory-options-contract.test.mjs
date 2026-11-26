import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzz_ChilaSeda_ViewpointNativeInventoryOptions.lua",
);
const bridgePath = path.join(
  modRoot,
  "Source/chilaseda/viewpointhalo/ViewpointInventoryOptionsBridge.java",
);
const modInfoPath = path.join(modRoot, "42/mod.info");
const translationPath = path.resolve(
  modRoot,
  "../ChilaSeda_Translations_ES_B42/42/media/lua/shared/Translate/ES/UI.json",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(modInfoPath, "utf8");
const catalog = JSON.parse(fs.readFileSync(translationPath, "utf8"));

const settingsLabels = [
  "UI/Inventory screen",
  "Viewpoint UI",
  "Inventory keys open vanilla UI",
  "Opens on",
  "Character",
  "Last tab",
  "Panel opacity",
  "World darkening",
  "Item tile size (times)",
  "Accent colour",
  "Items listed by",
  "Name",
  "Category",
  "Weight",
  "Vicinity as a list",
  "Inventory as a list",
  "Border items by condition",
  "Colour items by type",
  "Type colour strength",
  "Weapons colour",
  "Ammunition colour",
  "Equipment colour",
  "Medical colour",
  "Food and drink colour",
  "Tools colour",
  "Materials colour",
  "Books and maps colour",
  "Junk colour",
  "Show the 3D character",
  "Columns as tall as their items",
  "Vicinity on the right",
  "Show the chosen container alone",
  "Show the mouse controls",
  "Keep searches between openings",
  "Close while using an item",
  "Reopen after a cancelled use",
  "Junk items",
];

const descriptions = [
  "In first and third person, the inventory key, Tab and the sidebar's bag and heart open Viewpoint's inventory screen and its character tabs. Off: the game's own inventory, loot and character windows, with the cursor freed for them, for a mod that changes those windows.",
  "With Viewpoint UI off, in first and third person: the inventory key and Tab open the game's own inventory and loot windows and free the cursor for them. Off: Viewpoint leaves the inventory key to the game and to other mods, for a mod with an inventory of its own, and Tab opens nothing. The Cursor free or locked key then frees the cursor for what opens.",
  "The tab the screen shows as it opens: the character, or the one shown when it last closed.",
  "How dark the screen's columns and panels are. Lower shows more of the world through them; under 0.6 the words cast a shadow to stay readable.",
  "How much the world behind the screen darkens while it is open. 0 leaves it as it is.",
  "How large the item tiles in Vicinity and your inventory are, against the size the game's font gives them. The columns, the equipment and the hands keep their size.",
  "The colour of what is chosen and marked: the selection, the Take All buttons, the container items go across to, the split's slider.",
  "How a column lists its items when the screen first opens and after this changes; the button beside each search switches it.",
  "Lists what is around you as rows, with each item's name, category and weight, as the game's own inventory list does. Off: a grid of tiles. The two buttons beside its search switch it too.",
  "Lists your inventory as rows, with each item's name, category and weight. Off: a grid of tiles. The two buttons beside its search switch it too.",
  "Colours the border of an item's tile by its condition, here and in the loot menu: green while whole, turning yellow, orange and then red as it wears down to ruined. Weapons and clothing always show it, anything else once it is damaged. Off: every border alike.",
  "Colours each item's tile by what kind of thing it is (weapons, ammunition, equipment, medical, food and drink, tools, materials, books and maps), as Tarkov colours its grid, each in the colour chosen below, and your junk in its own whatever its kind. Other things stay plain. Its condition shows on the border.",
  "How strongly the type colours fill the tiles. Lower keeps them a hint behind the icons.",
  "Shows your character's 3D model on the Character tab. Off saves drawing it; dropping clothes in its place still wears them.",
  "Vicinity and the inventory are only as tall as what they list, and grow with it. Off: they always reach the bottom of the screen.",
  "Puts Vicinity, what is around you, on the right of the screen and your equipment and inventory on the left. Off: Vicinity on the left, as DayZ has it.",
  "Your column lists only the container chosen with the icons at its top right (your inventory, a bag, a key ring), as the game's inventory window shows the one chosen. Off: it lists every container you carry, the chosen one framed.",
  "Shows the mouse's controls as keys at the screen's bottom left, the most used first (drag, Ctrl+click, double-click and the rest), and every one of them on hovering its ?. Off: that corner is left empty. A controller's button prompts show either way.",
  "Keeps what you typed in each column's search when the screen closes and opens again.",
  "While you eat, drink, take a pill, bandage or treat a wound, read or put on make-up, the screen closes so you watch it, and comes back as it was when you are done. Opened again meanwhile, it stays. Off: the screen stays.",
  "The screen comes back even when the use stops before it is done: you ran, were hit or cancelled it. Off: it comes back only after a use you finished, so the view stays yours when you have to move.",
  "The items you count as junk, by name, with a comma between two (Receipt, Sheet of Paper; any case): every item of that name, worn, bloody, empty or renamed alike, whatever mod it comes from; berries and mushrooms by the name you know them by. An item's right-click menu on the screen adds it or takes it off. A name no item has stays, named under the box. A column's Filter lists them under Junk, and only there. It starts with what the game files under its own Junk category (cigarettes, receipts, tin cans and the like): take off what you use. Apart from the game's own Set Unwanted.",
  "The colour your junk's tiles take (Junk items, below), whatever kind of thing each is. None leaves them plain.",
  "The colour tiles of this type take (Weapons). None leaves them plain.",
  "The colour tiles of this type take (Ammunition). None leaves them plain.",
  "The colour tiles of this type take (Equipment). None leaves them plain.",
  "The colour tiles of this type take (Medical). None leaves them plain.",
  "The colour tiles of this type take (Food and drink). None leaves them plain.",
  "The colour tiles of this type take (Tools). None leaves them plain.",
  "The colour tiles of this type take (Materials). None leaves them plain.",
  "The colour tiles of this type take (Books and maps). None leaves them plain.",
  "The colour tiles of this type take (Junk). None leaves them plain.",
];

function compileAndRunKahlua(fixture, prefix) {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  try {
    const fixtureFile = path.join(tempDir, "inventory-options-contract.lua");
    fs.writeFileSync(fixtureFile, fixture, "utf8");
    const harness = path.resolve(
      modRoot,
      "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
    );
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    return execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixtureFile, "--execute"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
}

test("all native Viewpoint inventory settings, descriptions and choices are translated", () => {
  for (const text of settingsLabels) {
    const value = catalog[`IGUI_ES_PZAPI_Viewpoint_${text}`];
    assert.ok(value, `missing Spanish label or choice: ${text}`);
    assert.notEqual(value, text, `label or choice remains English: ${text}`);
  }
  for (const text of descriptions) {
    const value = catalog[`IGUI_ES_PZAPI_Viewpoint_${text}`];
    assert.ok(value, `missing Spanish description: ${text}`);
    assert.notEqual(value, text, `description remains English: ${text}`);
  }
  assert.equal(catalog.UI_ChilaSeda_ViewpointNativeInventory_Title, "Inventario integrado de Viewpoint");
  assert.equal(catalog.UI_ChilaSeda_ViewpointNativeInventory_Enabled, "Usar la interfaz de inventario de Viewpoint");
  assert.ok(catalog.UI_ChilaSeda_ViewpointNativeInventory_EnabledTooltip);
});

test("Mod Options applies the native UI through PZAPI's actual onChangeApply flow", () => {
  assert.match(modInfo, /^modversion=2\.0\.151$/m);
  assert.match(modInfo, /^javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.151\.jar$/m);
  assert.match(lua, /option\.onChangeApply = function\(_, enabled\)/);
  assert.match(lua, /PZAPI\.ModOptions\.load = function\(self, \.\.\.\)/);
  assert.doesNotMatch(lua, /page\.apply = applyOptions/);
  assert.match(fs.readFileSync(bridgePath, "utf8"), /setIntegratedInventoryEnabled\(boolean enabled\)/);

  const fixture = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local native = { enabled = true, saveResult = 1 }
function native.integratedInventoryEnabled() return native.enabled and 1 or 0 end
function native.setIntegratedInventoryEnabled(enabled)
  if native.saveResult ~= 1 then return native.saveResult end
  native.enabled = enabled
  return 1
end
ChilaSedaViewpointInventoryOptionsJ = native
local events = {}
local function event(name)
  return { Add = function(callback) events[name] = callback end }
end
Events = { OnGameBoot = event("boot"), OnGameStart = event("start") }
getTextOrNull = function(key)
  local translations = {
    UI_ChilaSeda_ViewpointNativeInventory_Title = "Inventario integrado de Viewpoint",
    UI_ChilaSeda_ViewpointNativeInventory_Enabled = "Usar la interfaz de inventario de Viewpoint",
    UI_ChilaSeda_ViewpointNativeInventory_EnabledTooltip = "En primera o tercera persona, abre el inventario integrado.",
  }
  return translations[key]
end
local registered = {}
local page = { data = {}, dict = {} }
function page:addTitle(title) self.title = title end
function page:addTickBox(id, name, value, tooltip)
  local option = { id = id, name = name, value = value, tooltip = tooltip, isEnabled = true }
  function option:getValue() return self.value end
  function option:setValue(nextValue)
    self.value = nextValue
    if self.element then self.element:setSelected(1, nextValue) end
  end
  function option:setEnabled(enabled) self.isEnabled = enabled end
  self.dict[id] = option
  registered[id] = option
  return option
end
PZAPI = { ModOptions = { Dict = {}, Data = {} } }
function PZAPI.ModOptions:create(id, name)
  self.Dict[id] = page
  self.Data[#self.Data + 1] = page
  page.id, page.name = id, name
  return page
end
function PZAPI.ModOptions:load()
  registered.integratedInventoryUI.value = false
  return "loaded-stale-value"
end
`;
  const assertions = String.raw`
assert(page.id == "ChilaSeda_ViewpointNativeInventory", "page must register under a stable Mod Options id")
assert(page.name == "Viewpoint", "page must appear as Viewpoint in Options > Mods")
assert(page.title == "Inventario integrado de Viewpoint", "page title must be translated")
local option = registered.integratedInventoryUI
assert(option and option.value == true and option.isEnabled, "initial checkbox must match the native setting")
assert(option.name == "Usar la interfaz de inventario de Viewpoint", "checkbox must be translated")
assert(string.find(option.tooltip, "En primera", 1, true), "tooltip must be translated")
assert(type(option.onChangeApply) == "function" and page.apply == nil,
  "native changes must use PZAPI's per-option apply callback")

local checkbox = { selected = true }
function checkbox:setSelected(_, selected) self.selected = selected end
function checkbox:isSelected(_) return self.selected end
option.element = checkbox
local loaded = PZAPI.ModOptions:load()
assert(loaded == "loaded-stale-value", "wrapper must preserve the original loader return")
assert(option.value == true and checkbox.selected == true,
  "native state must override stale ModOptions.ini values after loading")

checkbox:setSelected(1, false)
option:onChangeApply(false)
option.value = checkbox:isSelected(1)
assert(native.enabled == false and option.value == false,
  "Apply must persist the selected value through the native bridge")
native.saveResult = 0
checkbox:setSelected(1, true)
option:onChangeApply(true)
option.value = checkbox:isSelected(1)
assert(native.enabled == false and option.value == false and checkbox.selected == false,
  "failed persistence must restore both the native state and checkbox")

ChilaSedaViewpointInventoryOptionsJ = nil
events.start()
assert(not option.isEnabled, "missing native bridge must disable the option")
ChilaSedaViewpointInventoryOptionsJ = native
native.saveResult = 1
native.enabled = true
events.start()
assert(option.isEnabled and option.value == true, "availability retry must resync and enable the option")
local joined = table.concat(logs, "\n")
assert(string.find(joined, "event=page-registered", 1, true), "page registration must be traced")
assert(string.find(joined, "event=load-sync", 1, true), "native-state resync must be traced")
assert(string.find(joined, "event=apply-result result=saved", 1, true), "successful Apply must be traced")
assert(string.find(joined, "event=apply-fallback", 1, true), "failed save must be traced")
assert(string.find(joined, "event=native-setting-fallback", 1, true), "unavailable bridge must be traced")
`;
  const result = compileAndRunKahlua(`${fixture}\n${lua}\n${assertions}`, "viewpoint-inventory-options-");
  assert.match(result, /Kahlua contract passed/);
});

test("Java bridge reads, saves and restores Viewpoint's native UI setting", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const zombieBuddyJar = process.env.ZOMBIE_BUDDY_JAR
    ?? "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";
  assert.ok(fs.existsSync(zombieBuddyJar), `ZombieBuddy archive not found: ${zombieBuddyJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-inventory-bridge-"));
  try {
    const stubRoot = path.join(modRoot, "tests/bridge-stubs");
    const harness = path.join(modRoot, "tests/ViewpointInventoryOptionsBridgeContract.java");
    const stubs = [
      path.join(stubRoot, "viewpoint/platform/LiveSettings.java"),
      path.join(stubRoot, "viewpoint/interact/InventorySettings.java"),
    ];
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", zombieBuddyJar,
      "-d", tempDir,
      ...stubs,
      bridgePath,
      harness,
    ]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${tempDir};${zombieBuddyJar}`, "ViewpointInventoryOptionsBridgeContract"],
      { encoding: "utf8" },
    );
    assert.match(result, /Viewpoint inventory bridge contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
