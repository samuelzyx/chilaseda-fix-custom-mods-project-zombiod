import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ZombieProneFacingTrace.lua",
);

test("melee knockdown trace records bounded read-only state and facing samples", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const helper = path.resolve(modRoot, "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), `Kahlua contract helper not found: ${helper}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "zombie-prone-trace-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);

    const fixture = String.raw`
local logs = {}
function print(message) logs[#logs + 1] = tostring(message) end
local function event()
    local result = { callbacks = {} }
    function result.Add(callback) result.callbacks[#result.callbacks + 1] = callback end
    return result
end
Events = { OnHitZombie = event(), OnTick = event(), OnGameStart = event(), OnMainMenuEnter = event() }
local now = 1000
function getTimestampMs() return now end
local player = { kind = "IsoPlayer", x = 10, y = 20 }
function getSpecificPlayer(index) return index == 0 and player or nil end
function instanceof(object, name) return object and object.kind == name end
local direction = { x = 1, y = 0 }
function direction:getX() return self.x end
function direction:getY() return self.y end
local victim = {
    kind = "IsoZombie", state = "staggerback", reaction = "HitSpear", dead = false,
    floor = false, crawling = false, behind = false, fallFront = false,
    x = 11, y = 20, health = 80,
}
function victim:getOnlineID() return 77 end
function victim:getActionStateName() return self.state end
function victim:getHitReaction() return self.reaction end
function victim:isDead() return self.dead end
function victim:isOnFloor() return self.floor end
function victim:isCrawling() return self.crawling end
function victim:isHitFromBehind() return self.behind end
function victim:getVariableBoolean(name)
    if name == "FromBehind" then return self.behind end
    if name == "FallOnFront" then return self.fallFront end
end
function victim:getForwardDirection() return direction end
function victim:getX() return self.x end
function victim:getY() return self.y end
function player:isLocalPlayer() return true end
function player:getX() return self.x end
function player:getY() return self.y end
local spear = { melee = true }
function spear:isMelee() return self.melee end
function spear:getFullType() return "Base.Spear" end
`;

    const checks = String.raw`
local function find(fragment)
    for _, line in ipairs(logs) do
        if string.find(line, fragment, 1, true) then return line end
    end
    return nil
end
Events.OnGameStart.callbacks[1]()
Events.OnHitZombie.callbacks[1](victim, player, "Head", spear)
assert(find("event=hit weapon=Base.Spear part=Head"), "local spear hit was not logged")
Events.OnTick.callbacks[1]()
assert(find("sample=0") and find("state=staggerback"), "initial state was not sampled")
assert(find("reaction=HitSpear") and find("forward=1,0"), "reaction or facing was not sampled")
victim.state, victim.floor, victim.fallFront = "falldown", true, true
direction.x, direction.y = -1, 0
now = now + 16
Events.OnTick.callbacks[1]()
local changed = find("sample=1")
assert(changed and string.find(changed, "state=falldown", 1, true), "post-hit state change was not captured")
assert(string.find(changed, "floor=1", 1, true) and string.find(changed, "fallFrontVar=1", 1, true), "floor/fall flags were not captured")
assert(string.find(changed, "forward=-1,0", 1, true), "facing change was not captured")
assert(direction.x == -1 and victim.health == 80, "trace modified combat or facing state")
local before = 0
for _, line in ipairs(logs) do if string.find(line, "event=hit", 1, true) then before = before + 1 end end
local remote = { isLocalPlayer = function() return false end }
local nonMelee = { melee = false, isMelee = function(self) return self.melee end }
Events.OnHitZombie.callbacks[1](victim, remote, "Head", spear)
Events.OnHitZombie.callbacks[1](victim, player, "Head", nonMelee)
assert(before == 1, "remote or ranged hits should be ignored")
Events.OnGameStart.callbacks[1]()
for i = 1, 20 do Events.OnHitZombie.callbacks[1](victim, player, "Torso", spear) end
local count = 0
for _, line in ipairs(logs) do if string.find(line, "event=hit", 1, true) then count = count + 1 end end
assert(count == 17, "per-session hit cap was not enforced")
assert(find("capped=1 maxHits=16"), "cap reason was not logged")
assert(find("readOnly=1"), "read-only startup trace was not announced")
`;

    const contractPath = path.join(tempDir, "zombie-prone-facing-trace.lua");
    fs.writeFileSync(contractPath, fixture + fs.readFileSync(luaPath, "utf8") + checks, "utf8");
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
