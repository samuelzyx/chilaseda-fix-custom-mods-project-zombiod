import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_InventoryTetrisEquipmentDropGuard.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("deferred slot cancellation retains the item captured at mouse-up", () => {
  assert.match(lua, /local item = itemInSlot\(self\)/);
  assert.match(lua, /currentSlot ~= originSlot or itemInSlot\(currentSlot\) ~= item/);
  assert.match(lua, /cancel skipped=slot-item-changed/);
  assert.match(lua, /equipmentSlot\.doDropOrUnequip\(callbackOwner, item\)/);
  assert.match(lua, /pcall\(owner\.getTopSlot, owner\)/);
  assert.match(lua, /currentSlot ~= originSlot/);
  assert.match(lua, /MAX_TRACE_LINES = 24/);
});

test("Kahlua discards stale Equipment UI drops and preserves unchanged-slot behavior", () => {
  const gameRoot = process.env.PZ_GAME_ROOT
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(gameRoot, "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "tetris-equipment-drop-"));
  try {
    const harness = path.join(modRoot, "tests/EquipmentDropGuardKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = `${gameJar};${tempDir}`;
    const compile = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "EquipmentDropGuardKahluaContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(compile, /Inventory Tetris Lua compiled/);

    const fixture = String.raw`
local logs, pending, drops = {}, {}, {}
function print(message) logs[#logs + 1] = tostring(message) end
local Settings = { InventoryTetris = true }
local DragAndDrop = {
  cancelDrag = function(owner, callback) pending[#pending + 1] = { owner = owner, callback = callback } end,
  endDrag = function() end,
}
local EquipmentSlot = {
  doDropOrUnequip = function(owner, item) drops[#drops + 1] = { owner = owner, item = item } end,
  onMouseUpOutside = function() error("patched EquipmentSlot handler was bypassed") end,
}
local EquipmentSuperSlot = {
  onMouseUpOutside = function() error("patched EquipmentSuperSlot handler was bypassed") end,
}
local modules = {
  ["EquipmentUI/Settings"] = Settings,
  ["EquipmentUI/DragAndDrop"] = DragAndDrop,
  ["EquipmentUI/UI/Slots/EquipmentSlot"] = EquipmentSlot,
  ["EquipmentUI/UI/Slots/EquipmentSuperSlot"] = EquipmentSuperSlot,
}
function require(name) return modules[name] or true end
`;
    const scenario = String.raw`
local oldItem = { getFullType = function() return "Base.Bag_Satchel" end }
local newItem = { getFullType = function() return "Base.Bag_Field" end }
local slot = { item = oldItem }
EquipmentSlot.onMouseUpOutside(slot, 0, 0)
assert(#pending == 1, "equipment slot cancellation queued")
slot.item = newItem
pending[1].callback(slot)
assert(#drops == 0, "stale callback must not drop the replacement item")

local stableItem = { getFullType = function() return "Base.WristWatch_Left_DigitalBlack" end }
local stableSlot = { item = stableItem }
EquipmentSlot.onMouseUpOutside(stableSlot, 0, 0)
pending[2].callback(stableSlot)
assert(#drops == 1 and drops[1].item == stableItem, "unchanged slot keeps normal release behavior")

local oldTop = { item = oldItem }
local newTop = { item = newItem }
local superSlot = { getTopSlot = function(self) return self.top end, top = oldTop }
EquipmentSuperSlot.onMouseUpOutside(superSlot, 0, 0)
assert(#pending == 3, "super-slot cancellation queued")
superSlot.top = newTop
pending[3].callback(superSlot)
assert(#drops == 1, "stale super-slot callback must not drop its replacement")

local stableTop = { item = stableItem }
local stableSuperSlot = { getTopSlot = function(self) return self.top end, top = stableTop }
EquipmentSuperSlot.onMouseUpOutside(stableSuperSlot, 0, 0)
pending[4].callback(stableSuperSlot)
assert(#drops == 2 and drops[2].item == stableItem, "unchanged super-slot keeps normal release behavior")

local traceCount = 0
for _, line in ipairs(logs) do
  if line:find("[ChilaSeda_InventoryTetrisEquipmentDropGuard]", 1, true) then traceCount = traceCount + 1 end
end
assert(traceCount <= 24, "diagnostic output stays bounded")
local sawStaleTrace = false
for _, line in ipairs(logs) do
  if line:find("cancel skipped=slot-item-changed item=Base.Bag_Satchel", 1, true) then sawStaleTrace = true end
end
assert(sawStaleTrace, "stale cancellation is traceable")
`;
    const fixturePath = path.join(tempDir, "equipment-drop-guard.lua");
    fs.writeFileSync(fixturePath, `${fixture}${lua}\n${scenario}`, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "EquipmentDropGuardKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Inventory Tetris equipment-drop Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("patch loads after both supported UI mods and documents its deferred-drop guard", () => {
  assert.match(modInfo, /^id=ChilaSeda_InventoryTetrisSizeCap_B42$/m);
  assert.match(modInfo, /^loadModAfter=.*INVENTORY_TETRIS.*EQUIPMENT_UI.*EQUIPMENT_UI_B42$/m);
  assert.match(modInfo, /^versionMin=42\.20$/m);
  assert.match(modInfo, /^modversion=1\.4\.9$/m);
  assert.match(readme, /Version 1\.4\.4/);
  assert.match(readme, /Equipment UI schedules its deferred release/);
});
