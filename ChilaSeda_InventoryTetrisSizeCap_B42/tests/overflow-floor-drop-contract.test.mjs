import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_InventoryTetrisOverflowFloorDrop.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("overflow drags forward movement and outside-release to the owning Tetris grid", () => {
  assert.match(lua, /renderer\.onMouseMove = function\(self, dx, dy\)/);
  assert.match(lua, /self\.gridUi:onMouseMove\(dx, dy\)/);
  assert.match(lua, /renderer\.onMouseMoveOutside = function\(self, dx, dy\)/);
  assert.match(lua, /self\.gridUi:onMouseMoveOutside\(dx, dy\)/);
  assert.match(lua, /renderer\.onMouseUpOutside = function\(self, x, y\)/);
  assert.match(lua, /self\.gridUi:onMouseUpOutside\(gridX, gridY\)/);
  assert.match(lua, /dragAndDrop\.isDragOwner, self\.gridUi/);
});

test("overflow floor drop matches stack IDs, ignores stale IDs and preserves normal-grid fallback", () => {
  assert.match(lua, /local function findOverflowStackByItem\(containerGrid, item\)/);
  assert.match(lua, /stack\.itemIDs\[itemId\]/);
  assert.match(lua, /local function liveOverflowItems\(inventory, stack\)/);
  assert.match(lua, /inventory\.getItemWithID, inventory, itemId/);
  assert.match(lua, /staleIds = staleIds \+ 1/);
  assert.match(lua, /if self\.grid:findStackByItem\(item\) then\s*return originalCancelDragDropItem\(self\)/);
  assert.match(lua, /ISInventoryPaneContextMenu\.dropItem, overflowItem, self\.playerNum/);
  assert.match(lua, /floor-drop source=overflow items=/);
  assert.match(lua, /floor-drop fallback=stack-not-in-overflow/);
  assert.match(lua, /floor-drop skipped=cursor-over-UI/);
  assert.match(lua, /MAX_TRACE_LINES = 32/);
});

test("Kahlua dispatches overflow events and drops only live items through vanilla", () => {
  const gameRoot = process.env.PZ_GAME_ROOT
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(gameRoot, "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "tetris-overflow-drop-"));
  try {
    const harness = path.join(modRoot, "tests/OverflowFloorDropKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = `${gameJar};${tempDir}`;
    const compile = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "OverflowFloorDropKahluaContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(compile, /Inventory Tetris Lua compiled/);

    const fixture = String.raw`
local logs = {}
local dropped = {}
local draggedStack
local currentOwner
local mouseOverUi = false
local inVehicle = false
function print(message) logs[#logs + 1] = tostring(message) end
local function event()
  local entry = {}
  entry.Add = function(callback) entry.callback = callback end
  return entry
end
Events = { OnGameBoot = event(), OnGameStart = event() }
ISUIElement = { isMouseOverAnyUI = function() return mouseOverUi end }
ISInventoryPaneContextMenu = {
  dropItem = function(item, playerNum) dropped[#dropped + 1] = { item = item, playerNum = playerNum } end,
}
local player = { getVehicle = function() return inVehicle and {} or nil end }
function getSpecificPlayer() return player end
GridOverflowRenderer = {}
local originalCancelCount = 0
ItemGridUI = {
  cancelDragDropItem = function(self) originalCancelCount = originalCancelCount + 1 end,
}
DragAndDrop = {
  isDragOwner = function(owner) return owner == currentOwner end,
  getDraggedStack = function() return draggedStack end,
}
local modules = {
  ["InventoryTetris/UI/Container/GridOverflowRenderer"] = GridOverflowRenderer,
  ["InventoryTetris/UI/Grid/ItemGridUI"] = ItemGridUI,
  ["InventoryTetris/System/DragAndDrop"] = DragAndDrop,
}
function require(name) return modules[name] or true end
`;
    const scenario = String.raw`
assert(GridOverflowRenderer.ChilaSedaOverflowFloorDropInstalled == true, "patch installation")
local gridUi = {
  getAbsoluteX = function() return 10 end,
  getAbsoluteY = function() return 20 end,
  onMouseMove = function(self, dx, dy) self.lastMove = { dx, dy }; return true end,
  onMouseMoveOutside = function(self, dx, dy) self.lastMoveOutside = { dx, dy }; return true end,
  onMouseUpOutside = function(self, x, y) self.lastReleaseOutside = { x, y }; return true end,
}
local overflowUi = {
  gridUi = gridUi,
  getAbsoluteX = function() return 100 end,
  getAbsoluteY = function() return 200 end,
}
currentOwner = gridUi
assert(GridOverflowRenderer.onMouseMove(overflowUi, 3, 4) == true, "move event forwarded")
assert(gridUi.lastMove[1] == 3 and gridUi.lastMove[2] == 4, "move deltas preserved")
assert(GridOverflowRenderer.onMouseMoveOutside(overflowUi, -2, 5) == true, "outside move forwarded")
assert(gridUi.lastMoveOutside[1] == -2 and gridUi.lastMoveOutside[2] == 5, "outside deltas preserved")
assert(GridOverflowRenderer.onMouseUpOutside(overflowUi, 5, 6) == true, "outside release forwarded")
assert(gridUi.lastReleaseOutside[1] == 95 and gridUi.lastReleaseOutside[2] == 186, "release coordinates translated")

local first = { id = 101, getID = function(self) return self.id end }
local second = { id = 102, getID = function(self) return self.id end }
local live = { [101] = first, [102] = second }
local inventory = { getItemWithID = function(self, id) return live[id] end }
local grid = { inventory = inventory, findStackByItem = function() return nil end }
local overflowStack = { itemIDs = { [101] = true, [102] = true, [999] = true } }
local containerGrid = { overflow = { overflowStack } }
local itemGrid = { playerNum = 0, grid = grid, containerGrid = containerGrid }
draggedStack = { items = { first } }
ItemGridUI.cancelDragDropItem(itemGrid)
assert(#dropped == 2, "live overflow items dropped")
assert(dropped[1].playerNum == 0 and dropped[2].playerNum == 0)
local sawStaleTrace = false
for _, line in ipairs(logs) do
  if line:find("floor-drop source=overflow items=2 drop-calls=2 stale-ids=1", 1, true) then sawStaleTrace = true end
end
assert(sawStaleTrace, "stale IDs traced")

grid.findStackByItem = function() return { itemIDs = { [101] = true } } end
ItemGridUI.cancelDragDropItem(itemGrid)
assert(originalCancelCount == 1, "normal grid cancellation preserved")

grid.findStackByItem = function() return nil end
containerGrid.overflow = {}
ItemGridUI.cancelDragDropItem(itemGrid)
assert(originalCancelCount == 2, "non-overflow cancellation fallback preserved")

containerGrid.overflow = { overflowStack }
mouseOverUi = true
ItemGridUI.cancelDragDropItem(itemGrid)
assert(#dropped == 2, "cursor over UI must not drop to floor")
local sawUiFallback = false
for _, line in ipairs(logs) do
  if line:find("floor-drop skipped=cursor-over-UI", 1, true) then sawUiFallback = true end
end
assert(sawUiFallback, "cursor fallback traced")
`;
    const fixturePath = path.join(tempDir, "overflow-floor-drop.lua");
    fs.writeFileSync(fixturePath, `${fixture}${lua}\n${scenario}`, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "OverflowFloorDropKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Inventory Tetris overflow Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("local patch retains its Tetris dependency and Jill load order", () => {
  assert.match(modInfo, /^id=ChilaSeda_InventoryTetrisSizeCap_B42$/m);
  assert.match(modInfo, /^require=INVENTORY_TETRIS$/m);
  assert.match(modInfo, /^loadModAfter=INVENTORY_TETRIS$/m);
  assert.match(modInfo, /^versionMin=42\.20$/m);
  assert.match(modInfo, /^modversion=1\.3\.8$/m);
  assert.match(readme, /Version 1\.3\.7/);
});
