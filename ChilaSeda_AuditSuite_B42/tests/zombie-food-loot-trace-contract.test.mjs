import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/server/ChilaSeda_ZombieFoodLootTrace.lua",
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

test("server zombie food trace reads saved loot odds, post-hook food and enforces its line cap", () => {
  assert.match(modInfo, /^modversion=2\.1\.13$/m);
  assert.match(modInfo, /loadModAfter=.*MaDZombieLootB42/);
  assert.match(lua, /MAX_LOG_LINES = 64/);
  assert.match(lua, /MAX_OBSERVATIONS = 10000/);
  assert.match(lua, /event=hook result=ready/);
  assert.match(lua, /event=death sample=/);
  assert.match(lua, /foodItems=/);
  assert.match(lua, /item:IsFood\(\)/);
  assert.doesNotMatch(lua, /item:getFood\(\)/);
  assert.match(lua, /GlobalMultiplier/);
  assert.match(lua, /OtherFoodMultiplier/);
  assert.match(lua, /CannedFoodMultiplier/);

  assert.ok(fs.existsSync(gameJar), `Project Zomboid archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), `Kahlua compile helper not found: ${helper}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "zombie-food-loot-trace-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);
    const fixture = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
Events = { OnZombieDead = { Add = function(callback) Events.callback = callback end } }
SandboxVars = { AirbobbelzLoot = { GlobalMultiplier = 2, OtherFoodMultiplier = 100, CannedFoodMultiplier = 100 } }
local activated = { contains = function(_, id) return id == "MaDZombieLootB42" end }
function getActivatedMods() return activated end
function isClient() return false end
`;
    const checks = String.raw`
local function find(fragment)
  for _, line in ipairs(logs) do
    if string.find(line, fragment, 1, true) then return line end
  end
  return nil
end
local hook = find("event=hook result=ready")
assert(hook and string.find(hook, "global=2", 1, true), "saved global multiplier was not captured")
assert(string.find(hook, "modActive=1", 1, true), "MaD active state was not captured")
local snack = {
  getFullType = function() return "Base.ModFood" end,
  IsFood = function() return true end,
}
local knownSnack = { getFullType = function() return "Base.Peanuts" end }
local nonFood = {
  getFullType = function() return "Base.Bandage" end,
  IsFood = function() return false end,
}
local inventory = { getItems = function()
  return { size = function() return 3 end, get = function(_, index)
    if index == 0 then return snack end
    if index == 1 then return knownSnack end
    if index == 2 then return nonFood end
    return nil
  end }
end }
local zombie = { getInventory = function() return inventory end, getOutfitName = function() return "Survivalist" end }
for _ = 1, 100 do Events.callback(zombie) end
local foodLine = find("event=death sample=1")
assert(foodLine and string.find(foodLine, "foodItems=2", 1, true), "food in post-hook corpse inventory was missed")
assert(string.find(foodLine, "examples=Base.ModFood,Base.Peanuts", 1, true), "food item IDs were not recorded")
assert(not string.find(foodLine, "Base.Bandage", 1, true), "non-food inventory item was counted as food")
assert(#logs == 64, "trace did not stop at its 64-line cap")
assert(string.find(logs[#logs], "log=64", 1, true), "last trace line did not record the cap")
`;
    const fixturePath = path.join(tempDir, "ZombieFoodLootFixture.lua");
    fs.writeFileSync(fixturePath, `${fixture}\n${lua}\n${checks}`, "utf8");
    const classpath = `${gameJar};${tempDir}`;
    execFileSync(path.join(jdkBin, "java.exe"), [
      "-classpath", classpath, "LuaCompileContract", fixturePath,
    ], { cwd: path.dirname(gameJar), encoding: "utf8", stdio: "pipe" });
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
