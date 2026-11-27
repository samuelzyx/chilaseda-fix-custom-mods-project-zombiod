import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzzzzz_ChilaSeda_ViewpointInventoryBatchMenus.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const viewpointRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const viewpointInput = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvInput.lua"), "utf8");
const viewpointData = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvData.lua"), "utf8");
const daao = fs.readFileSync(
  "J:/SteamLibrary/steamapps/workshop/content/108600/3761218629/mods/DismantleAllAtOnce/42/media/lua/client/DismantleAllAtOnce_ContextMenu.lua",
  "utf8",
);

test("Viewpoint keeps grouped stacks for native batch context-menu callbacks", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(modInfo, /^loadModAfter=.*Viewpoint/m);
  assert.match(modInfo, /^loadModAfter=.*ChilaSeda_AccessibleActions_B42/m);
  assert.match(viewpointInput, /return D\.items\(\{ h\.stack \}\)/);
  assert.match(viewpointData, /function D\.items\(stacks\)/);
  assert.match(viewpointData, /table\.insert\(list, item\)/);
  assert.match(daao, /if #group >= 2 then/);
  assert.match(lua, /chilaSedaViewpointStackGroups/);
  assert.match(lua, /result=stack-groups-restored/);
  assert.match(lua, /result=fallback reason=/);
  assert.match(lua, /MAX_TRACE_LINES = 24/);

  const gameJar = path.join(gameRoot, "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-inventory-batch-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);

    const java = path.join(jdkBin, "java.exe");
    const classpath = `${tempDir};${gameJar}`;
    execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", luaPath, "--compile-only"],
      { cwd: gameRoot },
    );

    const fixture = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local container = {}
local otherContainer = {}
local player = {}
function container:isInCharacterInventory(value) return value == player end
function otherContainer:isInCharacterInventory(value) return value == player end
function player:getInventory() return container end
getSpecificPlayer = function(index) assert(index == 0); return player end

local function makeItem(id, itemContainer)
  local item = { id = id, container = itemContainer or container }
  function item:getContainer() return self.container end
  return item
end

local a, b, c, d = makeItem("a"), makeItem("b"), makeItem("c"), makeItem("d")
local e = makeItem("e", otherContainer)
local stackA = { key = "A", name = "A", items = { a, b }, count = 2 }
local stackB = { key = "B", name = "B", items = { c, d }, count = 2 }
local section = { container = container, folded = false, visible = { stackA, stackB } }
local singleStack = { key = "single", name = "single", items = { e }, count = 1 }
local otherSection = { container = otherContainer, folded = false, visible = { singleStack } }
local grid = { sections = { section, otherSection }, query = "", order = {}, filter = nil }
function grid:lists(value) return value == section or value == otherSection end
function grid:narrowed() return false end

ViewpointInvData = {
  shown = function(value) return value.visible end,
}
ViewpointInvScreen = {
  itemsOf = function(self, hit)
    local selected = self.selected[container]
    if selected and (selected[hit.stack.key]
        or hit.stack.group and selected[hit.stack.group.key]) then
      return self.selectedFlat or { a, b, c, d }
    end
    local items = {}
    for _, item in ipairs(hit.stack.items) do items[#items + 1] = item end
    return items
  end,
}
local receivedItems
ISInventoryPaneContextMenu = {
  createMenu = function(playerNum, inInventory, items)
    assert(playerNum == 0 and inInventory == true)
    receivedItems = items
    return { items = items }
  end,
}
ViewpointInvActions = {
  menu = function(items, x, y)
    return ISInventoryPaneContextMenu.createMenu(0,
      items[1]:getContainer():isInCharacterInventory(player), items, x, y)
  end,
}
` + lua + String.raw`
local view = { selected = {}, inventory = grid, nearby = { sections = {} } }
local hit = { kind = "tile", stack = stackA, section = section }

local flat = ViewpointInvScreen.itemsOf(view, hit)
assert(#flat == 2 and flat[1] == a and flat[2] == b)
assert(flat.chilaSedaViewpointStackGroups[1] == stackA)
ViewpointInvActions.menu(flat, 1, 2)
assert(#receivedItems == 1 and receivedItems[1] == stackA,
  "a collapsed Viewpoint stack must reach vanilla as one grouped row")

local stackOne = { key = "one", name = "one", items = { a }, count = 1 }
section.visible = { stackOne }
local single = ViewpointInvScreen.itemsOf(view,
  { kind = "tile", stack = stackOne, section = section })
ViewpointInvActions.menu(single, 1, 2)
assert(receivedItems == single and receivedItems[1] == a,
  "single-item menus should keep their ordinary flat input")

local childA = { key = "A#a", name = "A", items = { a }, count = 1, group = stackA }
local childB = { key = "A#b", name = "A", items = { b }, count = 1, group = stackA }
section.visible = { childA, childB }
view.selected[container] = { A = true }
view.selectedFlat = { a, b }
local selectedParent = ViewpointInvScreen.itemsOf(view,
  { kind = "tile", stack = childA, section = section })
assert(#selectedParent.chilaSedaViewpointStackGroups == 1
    and selectedParent.chilaSedaViewpointStackGroups[1] == stackA,
  "selecting an expanded parent stack should restore its original group")
ViewpointInvActions.menu(selectedParent, 1, 2)
assert(#receivedItems == 1 and receivedItems[1] == stackA)

section.visible = { stackA, stackB }
view.selected[container] = { A = true, B = true }
view.selectedFlat = { a, b, c, d }
local multiple = ViewpointInvScreen.itemsOf(view, hit)
ViewpointInvActions.menu(multiple, 1, 2)
assert(#receivedItems == 2 and receivedItems[1] == stackA and receivedItems[2] == stackB,
  "selected stacks should stay separate for batch processing")

view.selected[container] = { A = true }
view.selected[otherContainer] = { single = true }
view.selectedFlat = { a, b, e }
local mixed = ViewpointInvScreen.itemsOf(view, hit)
ViewpointInvActions.menu(mixed, 1, 2)
assert(#receivedItems == 2 and receivedItems[1] == stackA and receivedItems[2] == e,
  "a multi-item stack should stay grouped while a singleton from another container stays flat")
assert(#logs <= 24, "inventory menu diagnostics must remain bounded")
assert(logs[1]:find("install result=wrapped", 1, true), logs[1])
assert(logs[2]:find("stack-groups-restored", 1, true), logs[2])
`;
    const fixturePath = path.join(tempDir, "viewpoint-inventory-batch.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const output = execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", fixturePath],
      { cwd: gameRoot, encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
