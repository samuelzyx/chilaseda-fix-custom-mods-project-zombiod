import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzzzz_ChilaSeda_ViewpointVehicleEntry.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const helper = path.resolve(
  modRoot,
  "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
);

test("Viewpoint promotes vehicle entry and falls back from a mechanics part to an available seat", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(lua, /getBestSeat/);
  assert.match(lua, /seatReason=/);
  assert.match(lua, /TRACE_LIMIT = 32/);
  assert.match(lua, /getGITDCPlan/);
  assert.match(lua, /GITDC_Approach/);
  assert.ok(fs.existsSync(gameJar), `Project Zomboid archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), `Kahlua compile helper not found: ${helper}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-vehicle-entry-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);
    const fixture = String.raw`
local logs, entered = {}, nil
print = function(message) logs[#logs + 1] = tostring(message) end
Events = { OnGameStart = { Add = function(callback) Events.onGameStart = callback end } }
local mechanicsPart = { getDoor = function() return nil end, getId = function() return "Engine" end }
local player = { getVehicle = function() return nil end, isDead = function() return false end }
local vehicle = {
  getUseablePart = function() return mechanicsPart end,
  getBestSeat = function() return 0 end,
  getMaxPassengers = function() return 1 end,
}
ISVehicleMenu = { onEnter = function(_, _, seat) entered = seat end }
ViewpointInteractOrder = { sort = function(list) return list end, vehicleRanks = function() return {} end }
ViewpointInteractIcons = { of = function() return "native-icon" end }
ViewpointInteract = { target = { vehicle = vehicle } }
function ViewpointInteract.harvestVehicle()
  ViewpointInteract.actions = {{ name = "Mechanics", fn = function() end, args = {}, n = 0 }}
  return { labels = { "Mechanics" }, enabled = { true }, deliberate = { false }, tips = {}, icons = {} }
end
function getText(key) return key end
function getTexture(path) return path end
`;
    const checks = String.raw`
local result = ViewpointInteract.harvestVehicle(player, vehicle)
assert(result.labels[1] == "IGUI_EnterVehicle", "vehicle entry was not promoted to the first row")
assert(ViewpointInteract.actions[1].args[3] == 0, "best-seat fallback was not captured")
ViewpointInteract.actions[1].fn(unpack(ViewpointInteract.actions[1].args, 1, ViewpointInteract.actions[1].n))
assert(entered == 0, "entry action did not use the selected vanilla seat")
assert(string.find(table.concat(logs, "\n"), "seatReason=best-seat-fallback", 1, true), "fallback path was not traced")
`;
    const fixturePath = path.join(tempDir, "VehicleEntryFixture.lua");
    fs.writeFileSync(fixturePath, `${fixture}\n${lua}\n${checks}`, "utf8");
    execFileSync(path.join(jdkBin, "java.exe"), [
      "-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixturePath,
    ], { cwd: path.dirname(gameJar), encoding: "utf8", stdio: "pipe" });
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
