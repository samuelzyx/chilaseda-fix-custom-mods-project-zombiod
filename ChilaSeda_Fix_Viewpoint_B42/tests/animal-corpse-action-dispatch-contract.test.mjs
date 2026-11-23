import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const scriptPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzz_ChilaSeda_ViewpointAnimalCorpsePrompt.lua",
);
const script = fs.readFileSync(scriptPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const vanillaPath =
  "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/Animal/ISAnimalContextMenu.lua";
const vanilla = fs.readFileSync(vanillaPath, "utf8");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("corpse shortcut traces modifier, target, walkAdj and action queue without unbounded logging", () => {
  assert.match(script, /MAX_ACTION_TRACE_LINES = 48/);
  assert.match(script, /key=matched code=/);
  assert.match(script, /target=prompt-cache/);
  assert.match(script, /walkAdjCalls=/);
  assert.match(script, /queued=/);
  assert.match(script, /local PROMPT_GAP = 84/);
  assert.match(script, /for _, timedQueue in pairs\(queues\) do/);
  assert.match(script, /getObjectIDAsLong/);
  assert.match(script, /reason=already-queued/);
  assert.match(modInfo, /modversion=2\.0\.128/);
  assert.match(modInfo, /javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.122\.jar/);
  assert.match(vanilla, /AnimalContextMenu\.onButcherAnimal = function\(body, chr, knife\)/);
  assert.match(vanilla, /ISButcherAnimal:new\(chr, body\)/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-corpse-action-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const prelude = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local function makeEvent()
    local event = { callbacks = {} }
    event.Add = function(callback) event.callbacks[#event.callbacks + 1] = callback end
    return event
end
Events = { OnKeyStartPressed = makeEvent(), OnGameStart = makeEvent() }
local promptElement
ISUIElement = {}
function ISUIElement:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = ISUIElement })
    return class
end
function ISUIElement.new(self) return setmetatable({}, self) end
function ISUIElement:initialise() end
function ISUIElement:addToUIManager()
    if self.Type == "ChilaSedaViewpointAnimalCorpsePrompt" then promptElement = self end
end
function ISUIElement:removeFromUIManager() end
function ISUIElement:backMost() end
local modifierMatches = true
local walkResult = true
local calls = { butcher = 0, bones = 0, queued = {}, consumed = 0, walkAdj = 0 }
local knife = { id = "knife" }
local inventory = {
    getFirstTagEvalRecurse = function() return knife end,
}
local player
local body
local isSkeleton = false
local liveQueue = { queue = {} }
local objects = {
    size = function() return 1 end,
    get = function(_, index) assert(index == 0); return body end,
}
local square = {
    getStaticMovingObjects = function() return objects end,
}
local cell = {
    getGridSquare = function(_, x, y, z)
        if x == 10 and y == 10 and z == 0 then return square end
        return nil
    end,
}
player = {
    getPlayerNum = function() return 0 end,
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getCell = function() return cell end,
    getInventory = function() return inventory end,
    getVehicle = function() return nil end,
}
body = {
    isAnimal = function() return true end,
    isAnimalSkeleton = function() return isSkeleton end,
    hasAnimalParts = function() return true end,
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getObjectIDAsLong = function() return 7001 end,
    getCustomName = function() return "Rabbit corpse" end,
    getDisplayName = function() return "Rabbit corpse" end,
    getSquare = function() return square end,
}
getSpecificPlayer = function() return player end
getCell = function() return cell end
getTimestampMs = function() return 100 end
instanceof = function(value, className) return value == body and className == "IsoDeadBody" end
ItemTag = { BUTCHER_ANIMAL = "ButcherAnimal" }
ChilaSedaViewpointNativeActionModifier = "CTRL"
ChilaSedaViewpointNativeActionModifierMatches = function() return modifierMatches end
ChilaSedaViewpointAnimalCorpseActionModifier = "CTRL"
ChilaSedaViewpointAnimalCorpseActionModifierMatches = function() return modifierMatches end
ChilaSedaViewpointAnimalCorpseButcherKey = 32
ChilaSedaViewpointAnimalCorpsePickupKey = nil
ChilaSedaViewpointAnimalCorpseBonesKey = nil
GameKeyboard = { eatKeyPress = function() calls.consumed = calls.consumed + 1 end }
ChilaSedaViewpointFogJ = {
    active = function() return true end,
    prepareNativeForagePins = function() return true end,
    projectNativeForagePin = function() return true end,
    nativeForagePinScreenWidth = function() return 1600 end,
    nativeForagePinScreenHeight = function() return 900 end,
    nativeForagePinScreenX = function() return 800 end,
    nativeForagePinScreenY = function() return 450 end,
}
luautils = { walkAdj = function() return walkResult end }
ISTimedActionQueue = {
    queues = {},
    add = function(action)
        calls.queued[#calls.queued + 1] = action
        liveQueue.queue[#liveQueue.queue + 1] = action
    end,
}
liveQueue.character = player
ISTimedActionQueue.queues[{}] = liveQueue
AnimalContextMenu = {
    onButcherAnimal = function(receivedBody, receivedPlayer, receivedKnife)
        calls.butcher = calls.butcher + 1
        assert(receivedBody == body and receivedPlayer == player and receivedKnife == knife,
            "vanilla butcher callback arguments should be body, player, knife")
        if luautils.walkAdj(receivedPlayer, receivedBody:getSquare()) then
            ISTimedActionQueue.add({ Type = "ISButcherAnimal",
                body = { getObjectIDAsLong = function() return 7001 end },
                character = { getPlayerNum = function() return 0 end } })
        end
    end,
    onGetAnimalBones = function(receivedBody, receivedPlayer)
        calls.bones = calls.bones + 1
        assert(receivedBody == body and receivedPlayer == player,
            "vanilla bones callback arguments should be body and player")
        if luautils.walkAdj(receivedPlayer, receivedBody:getSquare()) then
            ISTimedActionQueue.add({ Type = "ISGetAnimalBones",
                body = { getObjectIDAsLong = function() return 7001 end },
                character = { getPlayerNum = function() return 0 end } })
        end
    end,
}
luautils = {
    walkAdj = function()
        calls.walkAdj = calls.walkAdj + 1
        liveQueue.queue = {}
        return walkResult
    end,
}
require = function() return {} end
`;
    const assertions = String.raw`
assert(promptElement ~= nil, "animal corpse prompt should be installed")
promptElement:prerender()
assert(promptElement.target and promptElement.target.body == body,
    "prompt should resolve the visible animal corpse")

local keyHandler = Events.OnKeyStartPressed.callbacks[1]
assert(type(keyHandler) == "function", "corpse shortcut handler should register")
ChilaSedaViewpointFogJ.projectNativeForagePin = function() return false end
keyHandler(32)
assert(calls.butcher == 1 and #calls.queued == 1,
    "the shown prompt target should still dispatch if reprojection fails at key time")
assert(string.find(logs[#logs], "queued=1", 1, true), "queue result should be traced")
local sawCached = false
for _, line in ipairs(logs) do
    if string.find(line, "target=prompt-cache", 1, true) then sawCached = true end
end
assert(sawCached, "the visible prompt target should be used as a safe fallback")

local firstButcher = liveQueue.queue[1]
local firstWalkCount = calls.walkAdj
keyHandler(32)
assert(calls.butcher == 1 and calls.walkAdj == firstWalkCount,
    "repeating Ctrl+D while this corpse is queued must not call vanilla walkAdj and clear the queue")
assert(liveQueue.queue[1] == firstButcher,
    "the already-running butcher action must remain in the timed-action queue")
assert(string.find(logs[#logs], "action=butcher result=suppressed reason=already-queued", 1, true),
    "duplicate butcher input should report the active-action fallback")

ChilaSedaViewpointFogJ.projectNativeForagePin = function() return true end
liveQueue.queue = {}
walkResult = false
keyHandler(32)
assert(calls.butcher == 2 and #calls.queued == 1,
    "vanilla walkAdj failure should not be reported as a successful queued action")
assert(string.find(logs[#logs], "walkAdj=false", 1, true), "walkAdj rejection should be traced")
assert(string.find(logs[#logs], "queued=0", 1, true), "missing butcher action should be traced")

walkResult = true
keyHandler(32)
assert(calls.butcher == 3 and #calls.queued == 2,
    "successful vanilla walkAdj should preserve the butcher action")
modifierMatches = false
keyHandler(32)
assert(calls.butcher == 3, "a mismatched modifier must not invoke butchering")
assert(calls.consumed == 4, "matching initial, duplicate, and failed attempts should consume the key")

modifierMatches = true
isSkeleton = true
ChilaSedaViewpointAnimalCorpseBonesKey = 35
keyHandler(35)
assert(calls.bones == 1 and #calls.queued == 3,
    "the skeleton bones shortcut should queue ISGetAnimalBones")
local firstBones = liveQueue.queue[1]
local bonesWalkCount = calls.walkAdj
keyHandler(35)
assert(calls.bones == 1 and calls.walkAdj == bonesWalkCount,
    "repeating the bones shortcut while queued must not clear or restart the action")
assert(liveQueue.queue[1] == firstBones,
    "the already-running bones action must remain in the timed-action queue")
assert(string.find(logs[#logs], "action=bones result=suppressed reason=already-queued", 1, true),
    "duplicate bones input should report the active-action fallback")

liveQueue.queue = {}
walkResult = false
keyHandler(35)
assert(calls.bones == 2 and #calls.queued == 3,
    "a failed bones walkAdj must not enqueue an action")
assert(string.find(logs[#logs], "walkAdj=false", 1, true),
    "bones walkAdj rejection should be traced")
assert(#logs <= 48, "action diagnostics should stop at the configured per-session limit")
`;
    const luaPath = path.join(tempDir, "animal-corpse-action-contract.lua");
    fs.writeFileSync(luaPath, `${prelude}\n${script}\n${assertions}`, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
