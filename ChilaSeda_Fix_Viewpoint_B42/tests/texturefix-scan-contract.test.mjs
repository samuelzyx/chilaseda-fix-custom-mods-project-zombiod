import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const scanPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzzz_ChilaSeda_ViewpointTextureFixScan.lua",
);
const scan = fs.readFileSync(scanPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const bridgePath = path.join(modRoot, "Source/chilaseda/viewpointhalo/ViewpointTextureFixScanBridge.java");
const bridge = fs.readFileSync(bridgePath, "utf8");

test("local F10 replacement avoids the Kahlua getSimpleName failure and is bounded", () => {
  assert.match(scan, /ChilaSedaViewpointTextureFixScanJ/);
  assert.match(scan, /getObjectName/);
  assert.match(scan, /MAX_OBJECT_LINES = 64/);
  assert.match(scan, /binding=Ctrl\+Alt\+F10 plainF10=screenshot removedWorkshop=/);
  assert.match(scan, /event=scan-start/);
  assert.match(scan, /event=scan-end result=ok/);
  assert.match(scan, /Keyboard\.KEY_LCONTROL/);
  assert.match(scan, /Keyboard\.KEY_LMENU/);
  assert.match(scan, /warnOnce\("scan"/);
  assert.doesNotMatch(scan, /event\.callbacks/);
  assert.match(bridge, /LuaEventManager\.getEvents/);
  assert.match(bridge, /event\.callbacks\.remove\(index\)/);
  assert.doesNotMatch(scan, /getClass\s*\(|getSimpleName/);
  assert.match(modInfo, /modversion=2\.0\.159/);
  assert.match(modInfo, /javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.151\.jar/);
  assert.match(modInfo, /loadModAfter=.*ZombieBuddy,vpfix/);
});

test("Kahlua removes only the Workshop callback and safely scans capped object details", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-texturefix-scan-"));
  try {
    const harnessSource = path.join(modRoot, "tests/ViewpointTextureFixScanKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);

    const objects = Array.from({ length: 70 }, (_, index) => `makeObject(${index + 1}),`).join("\n");
    const prelude = `
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local function list(values)
    local result = values or {}
    function result:size() return #self end
    function result:get(index) return self[index + 1] end
    function result:remove(index) return table.remove(self, index + 1) end
    return result
end
local original = { prototype = { file = "media/lua/client/VPFixScan.lua", filename = "VPFixScan.lua" } }
local unrelated = { prototype = { file = "OtherMod.lua", filename = "OtherMod.lua" } }
local callbacks = list({ original, unrelated })
local keyEvent = {}
keyEvent.Add = function(callback) callbacks[#callbacks + 1] = callback end
keyEvent.Remove = function(callback)
    for index = callbacks:size() - 1, 0, -1 do
        if callbacks:get(index) == callback then callbacks:remove(index) end
    end
end
Events = { OnKeyPressed = keyEvent }
ChilaSedaViewpointTextureFixScanJ = {
    removeWorkshopScannerCallbacks = function()
        local removed = 0
        for index = callbacks:size() - 1, 0, -1 do
            local callback = callbacks:get(index)
            local prototype = callback and callback.prototype
            local source = prototype and (prototype.file or prototype.filename) or ""
            if string.lower(source):find("vpfixscan.lua", 1, true) then
                callbacks:remove(index)
                removed = removed + 1
            end
        end
        return removed
    end,
}
local downKeys = {}
Keyboard = {
    KEY_F10 = 68,
    KEY_LCONTROL = 29,
    KEY_RCONTROL = 157,
    KEY_LMENU = 56,
    KEY_RMENU = 184,
    isKeyDown = function(key) return downKeys[key] == true end,
}
isServer = function() return false end
local function makeObject(index)
    local spriteName = index == 70 and "floors_bathroom_01_0" or ("bathroom_01_" .. tostring(index))
    local sprite = { getName = function() return spriteName end }
    return {
        getObjectName = function() return "IsoObject" .. tostring(index) end,
        getSprite = function() return sprite end,
        getClass = function() error("getClass must not be called") end,
    }
end
local objects = list({
${objects}
})
local square = { getObjects = function() return objects end }
local cell = { getGridSquare = function(_, x, y, z)
    if x == 0 and y == 0 and z == 0 then return square end
    return nil
end }
getCell = function() return cell end
local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getDir = function() return "N" end,
}
getSpecificPlayer = function() return player end
`;
    const assertions = `
assert(callbacks:size() == 2, "the Workshop scanner should be replaced without removing unrelated callbacks")
assert(callbacks:get(0) == unrelated, "unrelated key callback should keep its order")
assert(keyEvent.callbacks == nil, "PZ event tables expose Add/Remove, not their Java callback list")
local removalLogged = false
for _, line in ipairs(logs) do
    if string.find(line, "binding=Ctrl+Alt+F10 plainF10=screenshot removedWorkshop=1", 1, true) then removalLogged = true end
end
assert(removalLogged, "replacement should log successful removal through the Java event bridge")
callbacks:get(1)(Keyboard.KEY_F10)
local plainF10StartedScan = false
for _, line in ipairs(logs) do
    if string.find(line, "event=scan-start", 1, true) then plainF10StartedScan = true end
end
assert(not plainF10StartedScan, "plain F10 must remain available for Project Zomboid screenshots")
downKeys[Keyboard.KEY_LCONTROL] = true
downKeys[Keyboard.KEY_LMENU] = true
callbacks:get(1)(Keyboard.KEY_F10)
local objectLines = 0
local sawInstall = false
local sawTruncation = false
local sawEnd = false
local sawScanStart = false
local sawScanResult = false
for _, line in ipairs(logs) do
    if string.find(line, " object=IsoObject", 1, true) then objectLines = objectLines + 1 end
    if string.find(line, "binding=Ctrl+Alt+F10 plainF10=screenshot removedWorkshop=1", 1, true) then sawInstall = true end
    if string.find(line, "truncated=5 object(s)", 1, true) then sawTruncation = true end
    if string.find(line, "end objects=69 printed=64", 1, true) then sawEnd = true end
    if string.find(line, "event=scan-start binding=Ctrl+Alt+F10", 1, true) then sawScanStart = true end
    if string.find(line, "event=scan-end result=ok", 1, true) then sawScanResult = true end
end
assert(objectLines == 64, "scanner output should stop at the configured cap")
assert(sawInstall, "installation and Workshop callback removal should be logged")
assert(sawTruncation and sawEnd, "scan summary should report skipped floor objects and capped rows")
assert(sawScanStart and sawScanResult, "the chord-triggered scan should log execution and outcome")
assert(#logs <= 70, "chord-triggered scan output should stay bounded")
`;
    const contractPath = path.join(tempDir, "texturefix-scan-contract.lua");
    fs.writeFileSync(contractPath, `${prelude}\n${scan}\n${assertions}`, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ViewpointTextureFixScanKahluaContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /TextureFix scan Kahlua contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("Java bridge removes only the Workshop scanner from the real PZ event registry", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const zombieBuddyJar = process.env.PZ_ZOMBIE_BUDDY_JAR
    ?? "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(zombieBuddyJar), `ZombieBuddy Java archive not found: ${zombieBuddyJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-texturefix-event-bridge-"));
  try {
    const contract = path.join(modRoot, "tests/ViewpointTextureFixScanBridgeContract.java");
    const classpath = `${gameJar};${zombieBuddyJar}`;
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", classpath, "-d", tempDir, bridgePath, contract,
    ]);
    const result = execFileSync(path.join(jdkBin, "java.exe"), [
      "-classpath", `${classpath};${tempDir}`, "chilaseda.viewpointhalo.ViewpointTextureFixScanBridgeContract",
    ], { encoding: "utf8" });
    assert.match(result, /TextureFix event bridge contracts passed: removed=2/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
