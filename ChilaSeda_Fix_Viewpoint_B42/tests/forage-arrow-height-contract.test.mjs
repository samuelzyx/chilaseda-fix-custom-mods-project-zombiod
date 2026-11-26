import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const panelPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ViewpointNativeForageHeightCalibration.lua",
);
const panel = fs.readFileSync(panelPath, "utf8");
const projection = fs.readFileSync(
  path.join(modRoot, "Source/chilaseda/viewpointhalo/ForagingArrowCameraProjection.java"),
  "utf8",
);

test("floor arrow height is an independent saved and live calibration", () => {
  assert.match(projection, /float localSceneLift = sceneLift\(lift, arrowX, arrowZ\)[\s\S]*?nativeGroundArrowOffset\(\)[\s\S]*?float arrowY = playerHeight \+ localSceneLift \+ groundArrowOffset/);
  assert.match(projection, /event=projected pinIndex=[\s\S]*?arrowOffset=[\s\S]*?arrowY=/);
  assert.match(projection, /event=fallback reason=/);
  assert.match(projection, /integrated-forage-disabled/);
  assert.match(projection, /camera-projection-singular/);
  assert.match(projection, /MAX_PROJECTION_TRACES = 32/);
  assert.match(panel, /groundArrowEntry = ISTextEntryBox:new/);
  assert.match(panel, /CalibrationWindow:onGroundArrowLower/);
  assert.match(panel, /CalibrationWindow:onGroundArrowRaise/);
  assert.match(panel, /groundArrowOffset = arrowHeight/);
  assert.match(panel, /writer:write\("# Viewpoint Foraging manual pin settings v3/);
  assert.match(panel, /anchor,%.4f,%.4f,%.4f,%.3f,%.3f,%.3f,%.3f/);
  assert.match(panel, /setPreview\(self\.originX, self\.originY, settings\.offset,[\s\S]*?settings\.groundArrowOffset/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-arrow-height-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const moduleBody = panel.replace(/\s*return Calibration\s*$/, "\nreturn Calibration");
    assert.notEqual(moduleBody, panel, "the real calibration module should export its API");
    const fixture = `
local savedConfig = ""
local function makeEvent() return { Add = function() end } end
Events = { OnGameStart = makeEvent(), OnTick = makeEvent(), OnTickEvenPaused = makeEvent() }
require = function() return true end
ISPanel = {
    derive = function() return {} end,
    new = function() return {} end,
    prerender = function() end,
    onMouseUp = function() end,
    onMouseUpOutside = function() end,
}
getFileReader = function()
    if savedConfig == "" then return nil end
    local lines, index = {}, 0
    for line in string.gmatch(savedConfig, "[^\\n]+") do lines[#lines + 1] = line end
    return {
        readLine = function()
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end
getFileWriter = function()
    savedConfig = ""
    return {
        write = function(_, value) savedConfig = savedConfig .. value end,
        close = function() end,
    }
end
local function loadCalibrationModule()
${moduleBody}
end

local first = loadCalibrationModule()
assert(first.getGroundArrowOffsetAt(0, 0) == 0, "unanchored floor arrows should use zero offset")
assert(first.saveAt(0, 0, 3, 1, 1, 1, 4), "first area should save")
assert(first.saveAt(20, 0, 5, 1, 1, 1, 14), "second area should save")
assert(string.find(savedConfig, "manual pin settings v3", 1, true), "new config should use v3")
assert(string.find(savedConfig, "anchor,0.0000,0.0000,3.0000,1.000,1.000,1.000,4.000", 1, true),
    "the arrow offset should be stored separately after pin zoom values")

local loaded = loadCalibrationModule()
local exact = loaded.getGroundArrowOffsetAt(0, 0)
assert(exact == 4, "saved arrow offset should survive reload")
local middle = loaded.getGroundArrowOffsetAt(10, 0)
assert(math.abs(middle - 9) < 0.001, "separate area offsets should interpolate")
local pinMiddle = loaded.getOffsetAt(10, 0)
assert(math.abs(pinMiddle - 4) < 0.001, "the existing pin height should remain independent")

assert(loaded.setPreview(100, 100, 0, 1, 1, 1, -12), "live preview should accept a bounded arrow offset")
assert(loaded.getGroundArrowOffsetAt(100, 100) == -12, "preview should move only the floor arrow setting")
loaded.clearPreview()
assert(loaded.getGroundArrowOffsetAt(100, 100) == 0, "clearing preview should restore the unanchored default")

assert(loaded.saveAt(40, 0, 0, 1, 1, 1, 100), "out-of-range input should be safely clamped")
assert(loaded.getGroundArrowOffsetAt(40, 0) == 64, "floor arrow offset should clamp to its upper bound")

savedConfig = "# legacy settings\\nglobal,1.000,1.000,1.000\\nanchor,2.0000,3.0000,4.0000,1.000,1.000,1.000\\n"
local legacy = loadCalibrationModule()
assert(legacy.getGroundArrowOffsetAt(2, 3) == 0, "legacy anchors should migrate with a neutral arrow offset")
`;
    const fixturePath = path.join(tempDir, "arrow-height.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
