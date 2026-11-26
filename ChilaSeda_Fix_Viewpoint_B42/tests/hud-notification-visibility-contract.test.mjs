import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ViewpointHaloNotifications.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");

test("HUD visibility helpers compile and gate overlays on vanilla HUD state", () => {
  const start = lua.indexOf("local function hudVisibilityState()");
  const end = lua.indexOf("ChilaSeda_ViewpointHaloNotifications = ", start);
  assert.ok(start >= 0 && end > start, "HUD visibility helpers must exist");
  const helpers = lua.slice(start, end);
  assert.match(helpers, /ISUIHandler\.allUIVisible/);
  assert.match(helpers, /overlay:setVisible\(shouldBeVisible\)/);
  assert.match(lua, /expireNotifications\(nowMs\(\)\)/);
  const fixture = `
local TAG = "[HaloTest] "
function print() end
function type(value)
  if value == nil then return "nil" end
  if value == true or value == false then return "boolean" end
  if value == 0 then return "number" end
  if value == "" then return "string" end
  return "table"
end
function tostring(value) return "" .. value end
function pcall(callback, ...)
  return true, callback(...)
end
local hudVisibilityTraceCount = 0
local lastHudVisibilityState = nil
local hudVisibilityFallbackLogged = false
local notifications = { { expiresAt = 200 } }
table = {
  remove = function(values, index)
    local removed = values[index]
    for current = index, #values - 1 do values[current] = values[current + 1] end
    values[#values] = nil
    return removed
  end,
  sort = function() end,
}
function ipairs(values)
  local index = 0
  return function()
    index = index + 1
    if values[index] ~= nil then return index, values[index] end
  end
end
local overlay = {
  visible = true,
  removed = false,
  setVisible = function(self, value) self.visible = value end,
  removeFromUIManager = function(self) self.removed = true end,
}
function nowMs() return 100 end
${helpers}
ISUIHandler = { allUIVisible = true }
assert(syncOverlayVisibility() == true and overlay.visible == true)
ISUIHandler.allUIVisible = false
assert(syncOverlayVisibility() == false and overlay.visible == false)
ISUIHandler.allUIVisible = true
assert(syncOverlayVisibility() == true and overlay.visible == true)
notifications[1].expiresAt = 99
expireNotifications(100)
assert(#notifications == 0)
assert(removeEmptyOverlay() == true and overlay == nil)
`;

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-hud-visibility-"));
  try {
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const harnessClasspath = `${gameJar};${tempDir}`;
    const fixturePath = path.join(tempDir, "hud-notification-visibility.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", harnessClasspath, "TraitHaloSemanticsKahluaContract", fixturePath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Viewpoint Lua compiled/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("inventory and trait notifications share the HUD-aware overlay lifecycle", () => {
  assert.match(lua, /function ChilaSeda_ViewpointHaloNotifications\.showFixed\([\s\S]*?createOverlay\(\)/);
  assert.match(lua, /local function onSkillLevelUp\([\s\S]*?addNotification\([\s\S]*?createOverlay\(\)/);
  assert.match(lua, /local function keepOverlayBehindUI\(\)[\s\S]*?syncOverlayVisibility\(\)/);
  assert.match(lua, /function ChilaSeda_ViewpointHaloNotifications:render\(\)[\s\S]*?syncOverlayVisibility\(\)/);
  assert.match(lua, /Events\.OnTick\.Add\(keepOverlayBehindUI\)/);
  assert.match(lua, /hud-visibility=/);
  assert.match(lua, /hudVisibilityTraceCount < 12/);
  assert.match(lua, /ISUIHandler\.allUIVisible/);
});
