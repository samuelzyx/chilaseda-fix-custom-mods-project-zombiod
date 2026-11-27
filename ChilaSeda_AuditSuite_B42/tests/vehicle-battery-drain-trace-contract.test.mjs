import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_VehicleBatteryDrainTrace.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("nearby Spiffo and towing partner battery trace is bounded and read-only", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const helper = path.resolve(
    modRoot,
    "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
  );
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), `Kahlua contract helper not found: ${helper}`);
  assert.match(modInfo, /^modversion=2\.1\.14$/m);
  assert.match(lua, /TARGET_SCRIPT = "Base\.VanSpiffo"/);
  assert.match(lua, /MAX_SAMPLES_PER_SESSION = 180/);
  assert.match(lua, /MAX_VEHICLES_PER_SAMPLE = 8/);
  assert.match(lua, /readOnly=1/);
  assert.match(lua, /getVehicleTowing/);
  assert.match(lua, /getVehicleTowedBy/);
  assert.match(lua, /getBatteryCharge/);
  assert.match(lua, /getHeadlightsOn/);
  assert.match(lua, /getIsTurnedOn/);
  assert.match(readme, /Vehicle Battery Drain Trace/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "vehicle-battery-trace-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);
    const fixture = String.raw`
local logs, fileLines = {}, {}
function print(message) logs[#logs + 1] = tostring(message) end
local function makeFileWriter(name, append, create)
    assert(name == "ChilaSeda_VehicleBatteryTrace.log" and append == true and create == true)
    return {
        write = function(self, line) fileLines[#fileLines + 1] = line end,
        close = function() end,
    }
end
getFileWriter = makeFileWriter
local function event()
    local result = { callbacks = {} }
    function result.Add(callback) result.callbacks[#result.callbacks + 1] = callback end
    return result
end
Events = { OnTick = event() }
local batteryItem = {
    getFullType = function() return "Base.CarBattery" end,
    getCondition = function() return 73 end,
}
local batteryPart = {
    getId = function() return "Battery" end,
    getCondition = function() return 70 end,
    getInventoryItem = function() return batteryItem end,
    getModData = function() return {} end,
}
local radioDevice = { getIsTurnedOn = function() return true end }
local radioPart = {
    getId = function() return "Radio" end,
    getCondition = function() return 90 end,
    getInventoryItem = function() return nil end,
    getDeviceData = function() return radioDevice end,
    getModData = function() return { active = false } end,
}
local trailerBattery = {
    getId = function() return "Battery" end,
    getCondition = function() return 55 end,
    getInventoryItem = function() return nil end,
    getModData = function() return {} end,
}
local function makeVehicle(id, script, x, y, charge, parts)
    local value = { id = id, script = script, x = x, y = y, charge = charge, parts = parts or {} }
    function value:getId() return self.id end
    function value:getScriptName() return self.script end
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getBatteryCharge() return self.charge end
    function value:hasLiveBattery() return self.charge > 0 end
    function value:getPartById(partId)
        for _, part in ipairs(self.parts) do if part:getId() == partId then return part end end
        return nil
    end
    function value:getBattery() return self:getPartById("Battery") end
    function value:getPartCount() return #self.parts end
    function value:getPartByIndex(index) return self.parts[index + 1] end
    function value:isEngineRunning() return self.engineRunning or false end
    function value:isEngineStarted() return false end
    function value:isKeysInIgnition() return self.keysInIgnition or false end
    function value:getEngineSpeed() return 0 end
    function value:getEngineCondition() return 91 end
    function value:getCurrentSpeedKmHour() return 0 end
    function value:getHeadlightsOn() return self.headlights or false end
    function value:getWindowLightsOn() return false end
    function value:getLightbarLightsMode() return 0 end
    function value:getLightbarSirenMode() return 0 end
    function value:getVehicleTowing() return self.towing end
    function value:getVehicleTowedBy() return self.towedBy end
    return value
end
local van = makeVehicle(41, "Base.VanSpiffo", 11, 20, 0.80, { batteryPart, radioPart })
local trailer = makeVehicle(42, "Base.TrailerAdvert", 13, 20, 0.64, { trailerBattery })
van.towing, trailer.towedBy = trailer, van
local list = { van, trailer }
local cell = {
    getVehicles = function()
        return { iterator = function()
            local index = 0
            return {
                hasNext = function() return index < #list end,
                next = function() index = index + 1; return list[index] end,
            }
        end }
    end,
}
function getCell() return cell end
local player = { x = 10, y = 20 }
function player:getX() return self.x end
function player:getY() return self.y end
function getSpecificPlayer(index) return index == 0 and player or nil end
`;
    const checks = String.raw`
local function find(fragment)
    for _, line in ipairs(logs) do
        if string.find(line, fragment, 1, true) then return line end
    end
    return nil
end
Events.OnTick.callbacks[1]()
local sample1 = find("event=sample readOnly=1 sample=1")
assert(sample1, "first Spiffo battery sample was not emitted")
assert(string.find(sample1, "batteryCharge=0.8", 1, true), "van battery charge missing")
assert(string.find(sample1, "batteryPartCondition=70", 1, true), "battery part condition missing")
assert(string.find(sample1, "batteryItem=Base.CarBattery", 1, true), "battery item identity missing")
assert(string.find(sample1, "deviceOn=1", 1, true), "radio load state missing")
assert(string.find(sample1, "headlights=0", 1, true), "headlight state missing")
assert(string.find(sample1, "towing=42", 1, true), "tow partner id missing")
assert(string.find(sample1, "role=spiffo_towing", 1, true), "trailer relationship missing")
assert(string.find(sample1, "batteryCharge=0.64", 1, true), "trailer battery sample missing")
assert(string.find(sample1, "engineRunning=0", 1, true), "engine state missing")
assert(#fileLines == #logs, "every trace line should also be saved to the dedicated log")

van.charge = 0.79
for _ = 1, 299 do Events.OnTick.callbacks[1]() end
local sample2 = find("event=sample readOnly=1 sample=2")
assert(sample2 and string.find(sample2, "batteryCharge=0.79", 1, true),
    "spaced sample did not retain the changed battery charge")
assert(van.charge == 0.79 and trailer.charge == 0.64,
    "trace must not mutate battery charge")

getFileWriter = nil
list = {}
for _ = 1, 300 do Events.OnTick.callbacks[1]() end
assert(find("event=file-fallback destination=DebugLog"),
    "missing dedicated-file writer should report its DebugLog fallback once")
assert(find("event=target-set readOnly=1 nearbySpiffo=0 linkedVehicles=0 vehicles=none"),
    "target disappearance should be recorded in DebugLog")
getFileWriter = makeFileWriter
list = { van, trailer }
for _ = 1, 300 do Events.OnTick.callbacks[1]() end

for _ = 1, (180 * 300) do Events.OnTick.callbacks[1]() end
local sampleCount, capCount = 0, 0
for _, line in ipairs(logs) do
    if string.find(line, "event=sample readOnly=1", 1, true) then sampleCount = sampleCount + 1 end
    if string.find(line, "event=cap reached=1 maxSamples=180", 1, true) then capCount = capCount + 1 end
end
assert(sampleCount == 180 and capCount == 1, "trace sample cap should stop and report once")
local logCount = #logs
for _ = 1, 600 do Events.OnTick.callbacks[1]() end
assert(#logs == logCount, "capped trace must stop emitting lines")
assert(find("event=loaded readOnly=1 target=Base.VanSpiffo"), "read-only activation diagnostic missing")
assert(find("event=cap reached=1 maxSamples=180 readOnly=1"), "sample cap should explain its stop/fallback")
`;
    const contractPath = path.join(tempDir, "vehicle-battery-trace.lua");
    fs.writeFileSync(contractPath, fixture + fs.readFileSync(luaPath, "utf8") + checks, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
