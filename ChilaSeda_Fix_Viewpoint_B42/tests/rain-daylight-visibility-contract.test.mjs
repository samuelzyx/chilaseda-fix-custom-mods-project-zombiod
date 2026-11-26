import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const rainPath = path.join(
  modRoot,
  "42/media/lua/client/zzzz_ChilaSeda_ViewpointRainDaylightVisibility.lua",
);
const rainLua = fs.readFileSync(rainPath, "utf8");

test("daylight rain tint changes only active raindrops and reports bounded fallbacks", () => {
  assert.match(rainLua, /daylight < 0\.35[\s\S]*?event=skipped reason=low-daylight/);
  assert.match(rainLua, /event=adjusted daylight=[\s\S]*?drops=/);
  assert.match(rainLua, /event=fallback reason=/);
  assert.match(rainLua, /TRACE_LIMIT = 16/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-rain-daylight-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixture = `
local logs = {}
print = function(message) logs[#logs + 1] = message end
local callback
Events = { OnTickEvenPaused = { Add = function(fn) callback = fn end } }
local now = 1000
getTimestampMs = function() return now end
local daylight = 0.8
ClimateManager = { getInstance = function()
    return { getDayLightStrength = function() return daylight end }
end }
local intensity = 0.7
local dropCount = 2
local changed = 0
local drops = {}
local function makeDrop()
    return { ChangeTintMod = function(self, tint) self.tint = tint; changed = changed + 1 end }
end
drops[1], drops[2] = makeDrop(), makeDrop()
local stack = {
    size = function() return dropCount end,
    get = function(self, index) return drops[index + 1] end,
}
local base = { r = 0.4, g = 0.5, b = 0.7, a = 0.37 }
function base:getR() return self.r end
function base:getG() return self.g end
function base:getB() return self.b end
function base:getA() return self.a end
local RainManager = {
    getRainIntensity = function() return intensity end,
    raindropStack = stack,
    raindropTintMod = base,
}
local ColorInfo = { new = function(r, g, b, a)
    local value = { r = r, g = g, b = b, a = a }
    function value:getR() return self.r end
    function value:getG() return self.g end
    function value:getB() return self.b end
    function value:getA() return self.a end
    return value
end }
luajava = { bindClass = function(name)
    if name == "zombie.iso.objects.RainManager" then return RainManager end
    if name == "zombie.core.textures.ColorInfo" then return ColorInfo end
    error("unexpected class " .. tostring(name))
end }
${rainLua}
assert(type(callback) == "function", "rain updater should register on paused ticks")
callback()
assert(changed == 2, "both active drops should receive daylight tint")
assert(math.abs(drops[1].tint:getR() - 0.64) < 0.0001, "red tint should use the daylight boost")
assert(math.abs(drops[1].tint:getG() - 0.8) < 0.0001, "green tint should use the daylight boost")
assert(drops[1].tint:getB() == 1, "blue tint should clamp at one")
assert(drops[1].tint:getA() == 0.37, "alpha should remain unchanged")
assert(string.find(table.concat(logs, "\\n"), "event=adjusted", 1, true), "success should be traced")

local firstCount = changed
now = now + 500
callback()
assert(changed == firstCount, "updates should be throttled to one second")

daylight = 0.1
now = now + 1000
callback()
assert(changed == firstCount, "nighttime should leave vanilla drop tint unchanged")
assert(string.find(table.concat(logs, "\\n"), "reason=low-daylight", 1, true), "night skip should be traced")

daylight, intensity = 0.9, 0
now = now + 1000
callback()
assert(changed == firstCount, "no rain should leave drops untouched")
assert(string.find(table.concat(logs, "\\n"), "reason=no-rain", 1, true), "no-rain skip should be traced")

intensity, dropCount = 0.7, 0
now = now + 1000
callback()
assert(changed == firstCount, "an empty particle stack should not be touched")
assert(string.find(table.concat(logs, "\\n"), "reason=no-raindrops", 1, true), "empty stack should be traced")

dropCount = 1
drops[1].ChangeTintMod = function() error("fixture failure") end
now = now + 1000
callback()
assert(string.find(table.concat(logs, "\\n"), "event=fallback reason=runtime-error", 1, true),
    "runtime failures should report the safe fallback")

for i = 1, 40 do now = now + 1000; callback() end
assert(#logs <= 17, "runtime trace should stop after the configured bound")
`;
    const fixturePath = path.join(tempDir, "rain-daylight.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
