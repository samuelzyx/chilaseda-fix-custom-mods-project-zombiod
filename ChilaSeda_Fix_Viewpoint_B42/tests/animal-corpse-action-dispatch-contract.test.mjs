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

test("corpse shortcut traces modifier, target search, walkAdj and action queue with bounded logging", () => {
  assert.match(script, /MAX_ACTION_TRACE_LINES = 256/);
  assert.match(script, /MAX_MODIFIER_REJECT_TRACE_LINES = 24/);
  assert.match(script, /input=accepted action=/);
  assert.match(script, /input=modifier-rejected action=/);
  assert.match(script, /searchReason=matched/);
  assert.match(script, /nearestScreenDistance=/);
  assert.match(script, /projectionRejected=/);
  assert.match(script, /cacheSamePlayerNum=/);
  assert.match(script, /target=prompt-cache/);
  assert.match(script, /walkAdjCalls=/);
  assert.match(script, /queued=/);
  assert.match(script, /local PROMPT_GAP = 84/);
  assert.match(script, /for _, timedQueue in pairs\(queues\) do/);
  assert.match(script, /getObjectIDAsLong/);
  assert.match(script, /reason=already-queued/);
  assert.match(script, /MAX_BUTCHER_TRACE_LINES = 96/);
  assert.match(script, /butcherTrace=/);
  assert.match(script, /phase=callback-before/);
  assert.match(script, /phase=restore-queue-after route=world-context-equip/);
  assert.match(script, /" phase=after result="/);
  assert.match(script, /lifecycle=butcher method=complete phase=route-after/);
  assert.match(modInfo, /modversion=2\.0\.151/);
  assert.match(modInfo, /javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.151\.jar/);
  assert.match(script, /require "TimedActions\/ISInventoryTransferAction"/);
  assert.doesNotMatch(script, /ISDropItemAction/);
  assert.match(script, /feature=floor-notice action=ISInventoryTransferAction\.perform/);
  assert.match(vanilla, /AnimalContextMenu\.onButcherAnimal = function\(body, chr, knife\)/);
  assert.match(vanilla, /ISWorldObjectContextMenu\.equip\(chr, chr:getPrimaryHandItem\(\), knife, true\)/);
  assert.match(vanilla, /ISButcherAnimal:new\(chr, body\)/);
  const vanillaTransfer = fs.readFileSync(
    "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/TimedActions/ISInventoryTransferAction.lua",
    "utf8",
  );
  assert.match(vanillaTransfer, /function ISInventoryTransferAction:perform\(\)/);
  assert.match(vanillaTransfer, /self:transferItem\(item\)/);

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
local calls = { butcher = 0, bones = 0, queued = {}, equipActions = {}, consumed = 0, walkAdj = 0 }
local skipWorldEquipQueue = false
local worldEquipCallCount = 0
local produceButcherOutput = false
local outputItem
local floorContainer = { getType = function() return "floor" end }
local bagItem = { getFullType = function() return "Base.Bag_Schoolbag" end }
local selectedBackpack = {
    getType = function() return "inventory" end,
    getContainingItem = function() return bagItem end,
    isItemAllowed = function() return true end,
    hasRoomFor = function() return false end,
}
local floorNotifications, floorDropActions = {}, {}
local knife = { id = "knife", getID = function() return 41 end,
    getFullType = function() return "Base.HuntingKnife" end }
local primaryWeapon = {
    id = "Base.TwoHandedWeapon",
    getID = function() return 77 end,
    getFullType = function() return "Base.TwoHandedWeapon" end,
    isTwoHandWeapon = function() return true end,
}
local inventoryItems = { values = {} }
inventoryItems.size = function(self) return #self.values end
inventoryItems.get = function(self, index) return self.values[index + 1] end
local inventory = {
    getFirstTagEvalRecurse = function() return knife end,
    getType = function() return "inventory" end,
    getItems = function() return inventoryItems end,
    AddItem = function(self, item)
        inventoryItems.values[#inventoryItems.values + 1] = item
        item.container = self
    end,
}
local player
getPlayerInventory = function() return { inventoryPane = { inventory = selectedBackpack } } end
HaloTextHelper = { addText = function(_, message) floorNotifications[#floorNotifications + 1] = message end }
ISInventoryPaneContextMenu = {
    dropItem = function(item, playerNum)
        assert(playerNum == 0)
        local action = { item = item, character = player, destContainer = floorContainer }
        floorDropActions[#floorDropActions + 1] = action
        return action
    end,
}
ISInventoryTransferAction = {
    perform = function(action)
        action.item.container = action.destContainer
        return "vanilla-transfer-result"
    end,
}
local body
local equippedPrimary = primaryWeapon
primaryWeapon.getContainer = function() return inventory end
knife.getContainer = function() return inventory end
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
    getPrimaryHandItem = function() return equippedPrimary end,
    getSecondaryHandItem = function() return nil end,
    getVehicle = function() return nil end,
}
inventory.getParent = function() return player end
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
instanceof = function(value, className)
    return (value == body and className == "IsoDeadBody")
        or (value == bagItem and className == "InventoryContainer")
end
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
        if action.Type == "ISEquipWeaponAction" then
            calls.equipActions[#calls.equipActions + 1] = action
        else
            calls.queued[#calls.queued + 1] = action
        end
        liveQueue.queue[#liveQueue.queue + 1] = action
    end,
}
liveQueue.character = player
ISTimedActionQueue.queues[{}] = liveQueue
ISEquipWeaponAction = {
    new = function(_, receivedPlayer, item, duration, primary, twoHands)
        return setmetatable({ Type = "ISEquipWeaponAction", character = receivedPlayer, item = item,
            duration = duration, primary = primary, twoHands = twoHands }, ISEquipWeaponAction)
    end,
    isValid = function(action) return action.character ~= nil end,
    start = function(action) action.started = true end,
    perform = function(action)
        if action.primary then equippedPrimary = action.item end
    end,
    complete = function(action) action.completed = true; return true end,
    stop = function(action) action.stopped = true end,
}
ISEquipWeaponAction.__index = ISEquipWeaponAction
ISButcherAnimal = {
    isValid = function(action) return action.character ~= nil end,
    start = function(action) action.started = true end,
    perform = function(action) action.performed = true end,
    complete = function(action)
        action.completed = true
        if produceButcherOutput then
            outputItem = {
                container = nil,
                getContainer = function(item) return item.container end,
                getDisplayName = function() return "Rabbit meat" end,
                getFullType = function() return "Base.Rabbitmeat" end,
                getID = function() return 91 end,
                getTexture = function() return "meat-icon" end,
            }
            inventory:AddItem(outputItem)
        end
        return true
    end,
    stop = function(action) action.stopped = true end,
}
ISButcherAnimal.__index = ISButcherAnimal
ISWorldObjectContextMenu = {
    equip = function(receivedPlayer, handItem, item, primary, twoHands)
        assert(receivedPlayer == player)
        worldEquipCallCount = worldEquipCallCount + 1
        local action = setmetatable({ Type = "ISEquipWeaponAction", character = receivedPlayer,
            handItem = handItem, item = item, primary = primary, twoHands = twoHands }, ISEquipWeaponAction)
        if not skipWorldEquipQueue or worldEquipCallCount == 1 then
            ISTimedActionQueue.add(action)
        end
        return item
    end,
}
AnimalContextMenu = {
    onButcherAnimal = function(receivedBody, receivedPlayer, receivedKnife)
        calls.butcher = calls.butcher + 1
        assert(receivedBody == body and receivedPlayer == player and receivedKnife == knife,
            "vanilla butcher callback arguments should be body, player, knife")
        if luautils.walkAdj(receivedPlayer, receivedBody:getSquare()) then
            ISWorldObjectContextMenu.equip(receivedPlayer,
                receivedPlayer:getPrimaryHandItem(), receivedKnife, true, false)
            ISTimedActionQueue.add(setmetatable({ Type = "ISButcherAnimal",
                body = receivedBody, character = receivedPlayer }, ISButcherAnimal))
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
assert(#liveQueue.queue == 3 and liveQueue.queue[1].item == knife
        and liveQueue.queue[2].Type == "ISButcherAnimal"
        and liveQueue.queue[3].item == primaryWeapon,
    "the previous primary weapon should be queued after the butcher action")
assert(calls.equipActions[2].primary == true and calls.equipActions[2].twoHands == true,
    "the original two-handed primary weapon should restore to both hands")
local sawQueueResult = false
for _, line in ipairs(logs) do
    if string.find(line, "queued=1", 1, true) then sawQueueResult = true end
end
assert(sawQueueResult, "queue result should be traced")
local sawCached = false
for _, line in ipairs(logs) do
    if string.find(line, "target=prompt-cache", 1, true) then sawCached = true end
end
assert(sawCached, "the visible prompt target should be used as a safe fallback")
local sawAcceptedInput, sawProjectionReason = false, false
for _, line in ipairs(logs) do
    if string.find(line, "input=accepted action=butcher", 1, true) then sawAcceptedInput = true end
    if string.find(line, "searchReason=camera-projection-rejected", 1, true) then
        sawProjectionReason = true
    end
end
assert(sawAcceptedInput, "accepted Alt+D input should be recorded with its action")
assert(sawProjectionReason, "failed live projection should be recorded before using the prompt cache")
assert(#liveQueue.queue == 3, "the butcher, knife equip, and primary restore should be queued")
assert(liveQueue.queue[2]:isValid() == true, "butcher validation should preserve its vanilla result")
liveQueue.queue[2]:start()
liveQueue.queue[2]:perform()
assert(liveQueue.queue[2]:complete() == true, "butcher completion should still return its vanilla result")
assert(liveQueue.queue[3]:isValid() == true, "weapon restore validation should preserve its vanilla result")
liveQueue.queue[3]:start()
liveQueue.queue[3]:perform()
assert(liveQueue.queue[3]:complete() == true, "weapon restore completion should preserve its vanilla result")
assert(equippedPrimary == primaryWeapon, "the simulated restore action should equip the previous primary")
local sawHandsAndLifecycle = false
local sawContainerDetail = false
for _, line in ipairs(logs) do
    if string.find(line, "lifecycle=restore method=perform phase=after", 1, true)
            and string.find(line, "Base.TwoHandedWeapon", 1, true)
            and string.find(line, "hands{primary{type=Base.TwoHandedWeapon", 1, true) then
        sawHandsAndLifecycle = true
    end
    if string.find(line, "type=Base.TwoHandedWeapon,id=77,container=inventory", 1, true) then
        sawContainerDetail = true
    end
end
assert(sawHandsAndLifecycle, "restore lifecycle should trace the final primary and secondary hands")
assert(sawContainerDetail, "restore trace should include the expected weapon ID and container")

local firstButcher = calls.queued[1]
local firstWalkCount = calls.walkAdj
keyHandler(32)
assert(calls.butcher == 1 and calls.walkAdj == firstWalkCount,
    "repeating Alt+D while this corpse is queued must not call vanilla walkAdj and clear the queue")
assert(liveQueue.queue[2] == firstButcher,
    "the already-running butcher action must remain in the timed-action queue")
assert(string.find(logs[#logs], "action=butcher result=suppressed reason=already-queued", 1, true),
    "duplicate butcher input should report the active-action fallback")

ChilaSedaViewpointFogJ.projectNativeForagePin = function() return true end
local cachedPromptTarget = promptElement.target
promptElement.target = nil
ChilaSedaViewpointFogJ.projectNativeForagePin = function() return false end
keyHandler(32)
assert(calls.butcher == 1, "a failed live target search without a cached target must not dispatch")
assert(string.find(logs[#logs], "target=none reason=camera-projection-rejected", 1, true),
    "a key attempt with a rejected camera projection should report its specific cause")
assert(string.find(logs[#logs], "animalCorpses=1", 1, true)
        and string.find(logs[#logs], "projectionRejected=1", 1, true),
    "the failed search should report the nearby corpse and projection result")
promptElement.target = cachedPromptTarget
ChilaSedaViewpointFogJ.projectNativeForagePin = function() return true end
liveQueue.queue = {}
walkResult = false
keyHandler(32)
assert(calls.butcher == 2 and #calls.queued == 1,
    "vanilla walkAdj failure should not be reported as a successful queued action")
assert(#calls.equipActions == 2 and #liveQueue.queue == 0,
    "a rejected butcher action must not enqueue the previous-weapon restoration")
assert(string.find(logs[#logs], "walkAdj=false", 1, true), "walkAdj rejection should be traced")
assert(string.find(logs[#logs], "queued=0", 1, true), "missing butcher action should be traced")

walkResult = true
keyHandler(32)
assert(calls.butcher == 3 and #calls.queued == 2,
    "successful vanilla walkAdj should preserve the butcher action")
local queuedBeforeFallback = #calls.queued
local equipBeforeFallback = #calls.equipActions
skipWorldEquipQueue = true
worldEquipCallCount = 0
liveQueue.queue = {}
keyHandler(32)
skipWorldEquipQueue = false
assert(calls.butcher == 4 and #calls.queued == queuedBeforeFallback + 1,
    "the butcher action should still enqueue when the world-context equip route skips restoration")
assert(#calls.equipActions == equipBeforeFallback + 2
        and liveQueue.queue[3].item == primaryWeapon,
    "a missing world-context equip action should fall back to a direct primary-weapon action")
local sawDirectRestoreFallback = false
for _, line in ipairs(logs) do
    if string.find(line, "fallback=direct-action reason=world-context-action-not-queued", 1, true)
            then sawDirectRestoreFallback = true end
    if string.find(line, "result=queued", 1, true)
            and string.find(line, "path=direct-action", 1, true) then
        sawDirectRestoreFallback = true
    end
end
assert(sawDirectRestoreFallback,
    "the missing world-context action and direct-queue fallback should be traced")
local directRestore = liveQueue.queue[3]
directRestore:stop()
local sawStoppedRestore = false
for _, line in ipairs(logs) do
    if string.find(line, "lifecycle=restore method=stop phase=after", 1, true)
            and string.find(line, "result=nil", 1, true) then
        sawStoppedRestore = true
    end
end
assert(sawStoppedRestore, "a cancelled direct restore should be visible with its hand state")
modifierMatches = false
keyHandler(32)
assert(calls.butcher == 4, "a mismatched modifier must not invoke butchering")
local sawModifierReject = false
for _, line in ipairs(logs) do
    if string.find(line, "input=modifier-rejected action=butcher", 1, true) then
        sawModifierReject = true
    end
end
assert(sawModifierReject, "a key without its configured modifier should be visible in the trace")
assert(calls.consumed == 6,
    "accepted Alt+D attempts should consume the key even when target projection fails")

modifierMatches = true
isSkeleton = true
liveQueue.queue = {}
ChilaSedaViewpointAnimalCorpseBonesKey = 35
keyHandler(35)
assert(calls.bones == 1 and #calls.queued == 4,
    "the skeleton bones shortcut should queue ISGetAnimalBones")
local firstBones = calls.queued[#calls.queued]
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
assert(calls.bones == 2 and #calls.queued == 4,
    "a failed bones walkAdj must not enqueue an action")
assert(string.find(logs[#logs], "walkAdj=false", 1, true),
    "bones walkAdj rejection should be traced")
produceButcherOutput = true
assert(ISButcherAnimal.complete({ character = player }) == true,
    "vanilla butcher completion should preserve its result while routing overflow")
assert(#floorDropActions == 1,
    "butcher overflow should schedule a floor transfer when the selected backpack is full")
local floorTransferResult = ISInventoryTransferAction.perform(floorDropActions[1])
assert(floorTransferResult == "vanilla-transfer-result",
    "the floor transfer hook should preserve the vanilla action result")
assert(outputItem:getContainer() == floorContainer and #floorNotifications == 1,
    "the output item should trigger its Halo only after reaching the floor")
assert(floorNotifications[1] == "Soltado: Rabbit meat en el piso",
    "the floor Halo should name the butcher output")
local sawFloorTransfer = false
for _, line in ipairs(logs) do
    if string.find(line, "floor-notice transfer=perform result=delivered", 1, true) then
        sawFloorTransfer = true
    end
end
assert(sawFloorTransfer, "successful butcher overflow should be recorded")
assert(#logs <= 256, "action diagnostics should stop at the configured per-session limit")
local butcherTraceCount = 0
for _, line in ipairs(logs) do
    if string.find(line, "butcherTrace=", 1, true) then butcherTraceCount = butcherTraceCount + 1 end
end
assert(butcherTraceCount <= 96, "butchering diagnostics should remain bounded separately")
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
