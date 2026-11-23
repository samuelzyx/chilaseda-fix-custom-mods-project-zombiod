import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const bridgePath = path.join(modRoot, "Source/chilaseda/viewpointhalo/ForageTuningBridge.java");
const adapterPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_ViewpointNativeForageCalibration.lua",
);
const panelPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ViewpointNativeForageHeightCalibration.lua",
);
const projectionPath = path.join(
  modRoot,
  "Source/chilaseda/viewpointhalo/ForagingArrowCameraProjection.java",
);
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const bridge = fs.readFileSync(bridgePath, "utf8");
const adapter = fs.readFileSync(adapterPath, "utf8");
const panel = fs.readFileSync(panelPath, "utf8");
const projection = fs.readFileSync(projectionPath, "utf8");

function configuredJars() {
  return {
    game: process.env.PZ_PROJECT_ZOMBOID_JAR
      ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar",
    viewpoint: "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/java/client/Viewpoint.jar",
    buddy: "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar",
  };
}

test("Viewpoint Java bridge reads and updates the installed native pin tuning safely", () => {
  const jars = configuredJars();
  for (const [name, file] of Object.entries(jars)) {
    assert.ok(fs.existsSync(file), `${name} archive not found: ${file}`);
  }

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-forage-tuning-"));
  try {
    const harness = path.join(modRoot, "tests/ForageTuningBridgeContract.java");
    const classpath = `${jars.game};${jars.viewpoint};${jars.buddy}`;
    execFileSync(
      path.join(jdkBin, "javac.exe"),
      ["-classpath", classpath, "-d", tempDir, bridgePath, harness],
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${classpath};${tempDir}`, "ForageTuningBridgeContract"],
      { cwd: path.dirname(jars.game), encoding: "utf8" },
    );
    assert.match(result, /Native forage tuning bridge contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("native calibration adapter uses the bridge and reports one bounded failure", () => {
  assert.match(bridge, /@Exposer\.LuaClass\(name = "ChilaSedaViewpointForageTuningJ"\)/);
  assert.match(bridge, /getDeclaredField\("findPinHeight"\)/);
  assert.match(bridge, /getDeclaredField\("findPinUp"\)/);
  assert.match(bridge, /public static boolean setNativePinTuning\(/);
  assert.match(bridge, /public static boolean setNativeGroundArrowOffset\(/);
  assert.match(bridge, /public static double nativeGroundArrowOffset\(/);
  assert.match(projection, /sceneLift\(lift, arrowX, arrowZ\)[\s\S]*?ForageTuningBridge\.nativeGroundArrowOffset\(\)/);
  assert.match(adapter, /ChilaSedaViewpointForageTuningJ/);
  assert.match(adapter, /Calibration\.ensureNativeTuning = function\(\)/);
  assert.match(adapter, /Calibration\.getGroundArrowOffsetAt\(x, y\)/);
  assert.match(adapter, /ground-arrow-offset=/);
  assert.match(adapter, /warnOnce\("native tuning bridge unavailable: /);
  assert.match(panel, /Calibration\.ensureNativeTuning/);
  assert.match(panel, /calibration panel unavailable:/);
  assert.match(panel, /groundArrowEntry = ISTextEntryBox:new/);
  assert.match(panel, /Calibration\.saveAt\([\s\S]*?settings\.groundArrowOffset/);
  assert.match(modInfo, /javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.122\.jar/);
});

test("Kahlua adapter connects, writes each changed calibration once, and retries when unavailable", () => {
  const jars = configuredJars();
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-forage-kahlua-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(
      path.join(jdkBin, "javac.exe"),
      ["-classpath", jars.game, "-d", tempDir, harness],
    );

    const prelude = `
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local function makeEvent()
    local event = { callbacks = {} }
    event.Add = function(callback) event.callbacks[#event.callbacks + 1] = callback end
    return event
end
Events = { OnGameStart = makeEvent(), OnTick = makeEvent(), OnTickEvenPaused = makeEvent() }
local writes = {}
local arrowWrites = {}
local groundArrowValue = 6
local calibration = {
    nativeTuningAvailable = false,
    getOffsetAt = function() return 3 end,
    getGroundArrowOffsetAt = function() return groundArrowValue, { kind = "preview", sampleCount = 1 } end,
    getVisualAt = function() return 2, 1.5, 0.5 end,
}
require = function(_) return calibration end
ViewpointForage = nil
ChilaSedaViewpointFogJ = nil
getSpecificPlayer = function()
    return { getX = function() return 4 end, getY = function() return 5 end }
end
ChilaSedaViewpointForageTuningJ = {
    isNativeTuningAvailable = function() return true end,
    nativeFindPinHeightBase = function() return 10 end,
    nativeFindPinUpBase = function() return 100 end,
    nativeTuningStatus = function() return "ready" end,
    setNativePinTuning = function(height, up)
        writes[#writes + 1] = { height = height, up = up }
        return true
    end,
    setNativeGroundArrowOffset = function(offset)
        arrowWrites[#arrowWrites + 1] = offset
        return true
    end,
}
`;
    const adapterAssertions = `
assert(calibration.nativeTuningAvailable == true, "bridge should enable calibration")
assert(calibration.ensureNativeTuning() == true, "F6 retry should reuse an available bridge")
assert(#writes == 1, "initial tuning should be written once")
assert(math.abs(writes[1].height - 13.3333333333) < 0.001, "pin scale should be applied")
assert(writes[1].up == 103, "height offset should be applied")
assert(calibration.nativeGroundArrowOffsetAvailable == true, "separate arrow-height setter should be detected")
assert(#arrowWrites == 1 and arrowWrites[1] == 6, "the saved/preview floor-arrow offset should be applied")
Events.OnTick.callbacks[1]()
assert(#writes == 1, "unchanged tuning should not be rewritten")
assert(#arrowWrites == 1, "unchanged arrow height should not be rewritten")
groundArrowValue = 9
Events.OnTick.callbacks[1]()
assert(#arrowWrites == 2 and arrowWrites[2] == 9, "a changed arrow height should apply live")
`;
    const successPath = path.join(tempDir, "adapter-success.lua");
    fs.writeFileSync(successPath, `${prelude}\n${adapter}\n${adapterAssertions}`, "utf8");
    const classpath = `${jars.game};${tempDir}`;
    const successResult = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "ForageCalibrationKahluaContract", successPath],
      { cwd: path.dirname(jars.game), encoding: "utf8" },
    );
    assert.match(successResult, /Viewpoint Kahlua contract passed/);

    const unavailablePrelude = prelude
      .replace("isNativeTuningAvailable = function() return true end", "isNativeTuningAvailable = function() return false end")
      .replace("nativeTuningStatus = function() return \"ready\" end", "nativeTuningStatus = function() return \"Viewpoint Tuning unavailable\" end")
      .replace("setNativePinTuning = function(height, up)\n        writes[#writes + 1] = { height = height, up = up }\n        return true\n    end", "setNativePinTuning = function() error(\"must not write while unavailable\") end");
    const unavailableAssertions = `
assert(calibration.nativeTuningAvailable == false, "unavailable bridge must keep panel disabled")
assert(calibration.ensureNativeTuning() == false, "retry must report unavailable bridge")
assert(calibration.nativeTuningStatus == "Viewpoint Tuning unavailable")
assert(#writes == 0, "unavailable bridge must not write fields")
local warningCount = 0
for _, line in ipairs(logs) do
    if string.find(line, "native tuning bridge unavailable:", 1, true) then warningCount = warningCount + 1 end
end
assert(warningCount == 1, "unavailable bridge warning should be bounded")
`;
    const unavailablePath = path.join(tempDir, "adapter-unavailable.lua");
    fs.writeFileSync(unavailablePath, `${unavailablePrelude}\n${adapter}\n${unavailableAssertions}`, "utf8");
    const unavailableResult = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "ForageCalibrationKahluaContract", unavailablePath],
      { cwd: path.dirname(jars.game), encoding: "utf8" },
    );
    assert.match(unavailableResult, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("F6 and Ctrl+F6 retry tuning before the panel refuses to open", () => {
  const keyHandler = panel.slice(
    panel.indexOf("if Events and Events.OnKeyPressed"),
    panel.indexOf("if Events and Events.OnKeyStartPressed"),
  );
  assert.match(keyHandler, /key == calibrationKey and not shortcutWasDown/);
  assert.doesNotMatch(keyHandler, /isKeyDown\(Keyboard\.KEY_LCONTROL|isKeyDown\(Keyboard\.KEY_RCONTROL/);
  assert.match(panel, /if not Calibration\.nativeTuningAvailable[\s\S]*?pcall\(Calibration\.ensureNativeTuning\)/);
});
