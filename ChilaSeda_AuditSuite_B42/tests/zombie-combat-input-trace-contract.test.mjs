import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ZombieCombatInputTrace.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");

test("combat input trace captures bounded read-only right mouse, Ctrl, Shift, and melee transitions", () => {
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
  assert.match(lua, /MAX_ATTEMPTS_PER_SESSION = 24/);
  assert.match(lua, /MAX_TRACE_LINES = 768/);
  assert.match(lua, /MAX_SAMPLES_PER_ATTEMPT = 10/);
  assert.match(lua, /MAX_MOUSE_HOLDS_PER_SESSION = 24/);
  assert.match(lua, /MAX_MOUSE_SAMPLES_PER_HOLD = 10/);
  assert.match(lua, /MOUSE_SAMPLE_INTERVAL_MS = 250/);
  assert.match(lua, /readOnly=1/);
  assert.match(lua, /attackStarted=/);
  assert.match(lua, /pathTarget=/);
  assert.match(lua, /targetFloor=/);
  assert.match(lua, /queueCurrent=/);
  assert.match(lua, /right-button phase=/);
  assert.match(lua, /guarding=/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "zombie-combat-input-trace-"));
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
Events = {
    OnMouseDown = event(), OnPlayerUpdate = event(), OnHitZombie = event(),
    OnGameStart = event(), OnMainMenuEnter = event(),
}
local now = 1000
function getTimestampMs() return now end
local heldKeys, buttons = {}, {}
Keyboard = {
    KEY_LSHIFT = 42, KEY_RSHIFT = 54,
    KEY_LCONTROL = 29, KEY_RCONTROL = 157,
    isKeyDown = function(key) return heldKeys[key] == true end,
}
function isMouseButtonDown(button) return buttons[button] == true end
local player = {
    x = 10, y = 20, running = false, aiming = true, attacking = false,
    attackStarted = false, pathRunning = true, state = "walk", attackOutcome = "none",
}
local attackSquare = {
    getX = function() return 11 end, getY = function() return 20 end, getZ = function() return 0 end,
}
function getSpecificPlayer(index) return index == 0 and player or nil end
function player:isLocalPlayer() return true end
function player:getPlayerNum() return 0 end
function player:getX() return self.x end
function player:getY() return self.y end
function player:getTarget() return target end
function player:getActionStateName() return self.state end
function player:isRunning() return self.running end
function player:isAiming() return self.aiming end
function player:isAttacking() return self.attacking end
function player:isAttackStarted() return self.attackStarted end
function player:isPerformingAttackAnimation() return self.attackStarted end
function player:getAttackOutcome() return self.attackOutcome end
function player:getAttackDidDamage() return self.attackOutcome == "hit" end
function player:isPathfindRunning() return self.pathRunning end
function player:getPathTargetX() return 11 end
function player:getPathTargetY() return 20 end
function player:getPathTargetZ() return 0 end
function player:getAttackTargetSquare() return attackSquare end
target = {
    kind = "IsoZombie", id = 77, x = 11, y = 20, floor = false, crawling = false,
    state = "staggerback", reaction = "HitSpear", health = 80,
}
function target:getOnlineID() return self.id end
function target:getX() return self.x end
function target:getY() return self.y end
function target:isOnFloor() return self.floor end
function target:isCrawling() return self.crawling end
function target:getActionStateName() return self.state end
function target:getHitReaction() return self.reaction end
function target:getHealth() return self.health end
local direction = { getX = function() return 1 end, getY = function() return 0 end }
function target:getForwardDirection() return direction end
function instanceof(object, name) return object and object.kind == name end
ISTimedActionQueue = { queues = {} }
local queue = {
    character = player,
    current = { Type = "ISWalkToTimedAction" },
    queue = { { Type = "ISWalkToTimedAction" } },
}
ISTimedActionQueue.queues[player] = queue
`;
    const checks = String.raw`
local function find(fragment)
    for _, line in ipairs(logs) do
        if string.find(line, fragment, 1, true) then return line end
    end
    return nil
end
Events.OnGameStart.callbacks[1]()
buttons[1] = true
Events.OnPlayerUpdate.callbacks[1](player)
local rightDown = find("right-button phase=down hold=1")
assert(rightDown and string.find(rightDown, "mouse1=1", 1, true),
    "held right-button transition was not captured")
assert(string.find(rightDown, "aiming=1", 1, true)
    and string.find(rightDown, "targetType=IsoZombie targetId=77", 1, true),
    "aim and zombie state were not captured at right-button down")
now = now + 300
player.x, player.state, player.pathRunning = 10.4, "walk", true
Events.OnPlayerUpdate.callbacks[1](player)
local rightHeld = find("right-button phase=held hold=1 sample=1")
assert(rightHeld and string.find(rightHeld, "pathRunning=1", 1, true),
    "walking/path state during held right-button was not sampled")
heldKeys[29] = true
now = now + 300
Events.OnPlayerUpdate.callbacks[1](player)
assert(find("modifier phase=control-change ctrl=1 mouse1=1"),
    "Ctrl transition while right-button is held was not captured")
buttons[1] = false
now = now + 100
Events.OnPlayerUpdate.callbacks[1](player)
assert(find("right-button phase=up hold=1"), "right-button release was not captured")
heldKeys[29] = nil

Events.OnGameStart.callbacks[1]()
heldKeys[42] = true
buttons[1] = true
local inputBefore = #logs
Events.OnMouseDown.callbacks[1](1)
local approach = find("phase=mouse-down sample=0")
assert(approach and string.find(approach, "shift=1", 1, true), "Shift+right-click input was not captured")
assert(string.find(approach, "mouse1=1", 1, true), "right-button state was not captured")
assert(string.find(approach, "targetType=IsoZombie targetId=77", 1, true), "zombie target was not captured")
assert(string.find(approach, "queueCurrent=ISWalkToTimedAction", 1, true), "movement queue state was not captured")
now = now + 100
player.x, player.running, player.state = 12.2, true, "run"
buttons[1] = false
Events.OnPlayerUpdate.callbacks[1](player)
local running = find("phase=update sample=1")
assert(running and string.find(running, "running=1", 1, true), "run-through state transition was not captured")
assert(string.find(running, "targetDistance=1.20", 1, true), "distance transition was not captured")

heldKeys[42] = nil
buttons[0] = true
target.floor, target.state, target.reaction = true, "falldown", "FallOnFront"
player.running, player.state, player.attackStarted = false, "attack", true
Events.OnMouseDown.callbacks[1](0)
local proneClick = find("attempt=2 phase=mouse-down sample=0")
assert(proneClick and string.find(proneClick, "shift=0", 1, true), "unmodified prone-zombie click was not captured")
assert(string.find(proneClick, "mouse0=1", 1, true) and string.find(proneClick, "targetFloor=1", 1, true),
    "left-button and prone state were not captured")
now = now + 100
Events.OnPlayerUpdate.callbacks[1](player)
Events.OnHitZombie.callbacks[1](target, player, "Head", { Type = "Base.Spear" })
assert(find("melee-hit inputAttempt=2 targetId=77"), "successful melee hit was not linked to its input attempt")
assert(player.x == 12.2 and target.health == 80 and target.floor == true,
    "input tracing must not change movement, zombie health, or prone state")

Events.OnGameStart.callbacks[1]()
heldKeys[42], buttons[1], buttons[0] = true, true, false
local capStart = #logs + 1
for index = 1, 28 do Events.OnMouseDown.callbacks[1](1) end
local attempts, capLines = 0, 0
for index = capStart, #logs do
    local line = logs[index]
    if string.find(line, "phase=mouse-down", 1, true) then attempts = attempts + 1 end
    if string.find(line, "capped=1 maxAttempts=24", 1, true) then capLines = capLines + 1 end
end
assert(attempts == 24 and capLines == 1, "input-attempt cap should stop at 24 and report once")
assert(find("session=ready readOnly=1"), "read-only startup diagnostic was not emitted")
`;
    const contractPath = path.join(tempDir, "zombie-combat-input-trace.lua");
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
