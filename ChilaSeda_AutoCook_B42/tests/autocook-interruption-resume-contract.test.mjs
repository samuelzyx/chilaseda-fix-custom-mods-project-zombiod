import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const mobilityPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_AutoCookMobility.lua",
);
const mobilityLua = fs.readFileSync(mobilityPath, "utf8");

test("AutoCook resumes its recipe after a timed-action queue interruption", () => {
  assert.match(mobilityLua, /action\.stopOnRun = false/);
  assert.match(mobilityLua, /AutoCook paused for another action; it will resume automatically/);
  assert.match(mobilityLua, /resuming the original recipe after the other action/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const harness = path.resolve(
    modRoot,
    "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
  );
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "autocook-interruption-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", gameJar, "-d", tempDir, harness,
    ]);

    const fixture = String.raw`
local traces = {}
print = function(value) traces[#traces + 1] = tostring(value) end
local function event()
  local value = { callbacks = {} }
  function value.Add(callback) value.callbacks[#value.callbacks + 1] = callback end
  return value
end
local player = {}
function player:isDead() return false end
function player:isAttacking() return false end
local queue = { character = player, queue = {} }
ISTimedActionQueue = {
  add = function(action) queue.queue[#queue.queue + 1] = action end,
  resetQueue = function(value) value.queue = {} end,
  getTimedActionQueue = function() return queue end,
}
ISInventoryTransferAction = {
  perform = function() end,
  new = function() return {} end,
}
ISAddItemInRecipe = { complete = function() end }
AutoCook = {
  continue = function(job)
    job.continueCount = (job.continueCount or 0) + 1
    local action = {
      character = job.playerObj,
      stopOnWalk = true,
      stopOnRun = true,
      stopOnAim = true,
    }
    job.lastAction = action
    ISTimedActionQueue.add(action)
  end,
  stopAutoCook = function(job) job.finished = true end,
  queueAddItem = function() end,
}
require = function(name)
  if name == "AutoCook" then return AutoCook end
  if name == "TimedActions/ISTimedActionQueue" then return ISTimedActionQueue end
  if name == "TimedActions/ISInventoryTransferAction" then return ISInventoryTransferAction end
  if name == "TimedActions/ISAddItemInRecipe" then return ISAddItemInRecipe end
  return {}
end
Keyboard = { KEY_ESCAPE = 1, isKeyDown = function() return false end }
Events = {
  OnTick = event(),
  OnKeyStartPressed = event(),
  OnFillInventoryObjectContextMenu = event(),
}
isClient = function() return true end
instanceof = function() return false end
getText = function(key) return key end
` + mobilityLua + String.raw`

local job = { playerObj = player, continueCount = 0 }
function job:continue() return AutoCook.continue(self) end
function job:stopAutoCook() return AutoCook.stopAutoCook(self) end

job:continue()
assert(job.continueCount == 1 and #queue.queue == 1, "the first recipe action must enter the queue")
assert(queue.queue[1].stopOnRun == false and queue.queue[1].stopOnWalk == false,
  "running or walking must not cancel AutoCook's own timed action")

ISTimedActionQueue.resetQueue(queue)
assert(job.ChilaSedaPendingResume == true,
  "an interrupted active AutoCook job must be marked for automatic resume")
Events.OnTick.callbacks[1]()
assert(job.continueCount == 2 and #queue.queue == 1,
  "AutoCook must continue the same recipe after the interrupting queue drains")
assert(queue.queue[1].ChilaSedaAutoCookJob == job,
  "the resumed timed action must remain attached to its original AutoCook job")

ISTimedActionQueue.resetQueue(queue)
Events.OnTick.callbacks[1]()
assert(job.continueCount == 3 and #queue.queue == 1,
  "repeated interruptions must resume the recipe again")
queue.queue = {}
job:stopAutoCook()
Events.OnTick.callbacks[1]()
assert(job.finished == true and job.continueCount == 3,
  "a completed AutoCook job must not be queued again")
assert(table.concat(traces, "\n"):find("AutoCook paused for another action", 1, true),
  "the interruption must leave a diagnostic marker")
assert(table.concat(traces, "\n"):find("resuming the original recipe after the other action", 1, true),
  "the retry must leave a diagnostic marker")
`;
    const fixturePath = path.join(tempDir, "autocook-interruption-resume.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
