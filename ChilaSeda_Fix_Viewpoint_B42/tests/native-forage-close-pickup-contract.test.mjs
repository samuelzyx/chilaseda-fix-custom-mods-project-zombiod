import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const pickupPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_ViewpointNativeForagePickup.lua",
);
const pickup = fs.readFileSync(pickupPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const vanillaForageIcon = fs.readFileSync(
  "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/Foraging/ISForageIcon.lua",
  "utf8",
);
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Alt+G uses vanilla walkAdj for close and farther forage pins", () => {
  assert.doesNotMatch(pickup, /directCloseForagePickup/);
  assert.match(pickup, /local oldWalkAdj = utilities and utilities\.walkAdj/);
  assert.match(pickup, /walkAdjCalls=/);
  assert.match(pickup, /event=isValid result=/);
  assert.match(pickup, /forageActionAlreadyQueued\(icon\)/);
  assert.match(pickup, /for _, timedQueue in pairs\(queues\) do/);
  assert.match(pickup, /MAX_PICKUP_LIFECYCLE_TRACE_LINES = 16/);
  assert.match(pickup, /event=complete-result/);
  assert.match(vanillaForageIcon, /function ISForageIcon:doForage[\s\S]*?luautils\.walkAdj\(self\.character, targetSquare\)[\s\S]*?ISTimedActionQueue\.add\(ISForageAction:new/);
  assert.match(pickup, /reason=already-queued/);
  assert.match(pickup, /target\.closeFallback and "proximity" or "crosshair"/);
  assert.match(pickup, /mode=vanilla/);
  assert.match(pickup, /MAX_PICKUP_TRACE_LINES = 128/);
  assert.match(pickup, /MAX_PICKUP_INPUT_TRACE_LINES = 64/);
  assert.match(pickup, /result=modifier-rejected keyCode=/);
  assert.match(pickup, /rejectedProjection=/);
  assert.match(pickup, /rejectedScreenError=/);
  assert.match(modInfo, /modversion=2\.0\.159/);
  assert.match(modInfo, /javaJarFile=media\/java\/client\/ChilaSedaViewpointHalo-2\.0\.151\.jar/);

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-forage-close-"));
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
ISUIElement = {}
function ISUIElement:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = ISUIElement })
    return class
end
function ISUIElement.new(self)
    return setmetatable({}, self)
end
function ISUIElement:initialise() end
function ISUIElement:addToUIManager() end
function ISUIElement:removeFromUIManager() end
function ISUIElement:backMost() end
local calls = { doubleClick = 0, walkAdj = 0, queued = {}, actionData = nil }
local liveQueue = { queue = {} }
local item = {
    getFullType = function() return "Base.Twig" end,
    getPoisonPower = function() return 0 end,
    getPoisonDetectionLevel = function() return 0 end,
}
local itemList = {
    size = function() return 1 end,
    get = function(_, index) assert(index == 0); return item end,
}
local container = { isItemAllowed = function() return true end }
local character = { getInventory = function() return container end, getSquare = function() return {} end }
local player = {
    getVehicle = function() return nil end,
    getInventory = function() return container end,
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}
getSpecificPlayer = function() return player end
getPlayerInventory = function() return { inventory = container } end
isGamePaused = function() return false end
isCtrlKeyDown = function() return true end
getTexture = function(name) return name end
ChilaSedaViewpointNativeForagePickupKey = 71
local modifierMatches = true
ChilaSedaViewpointNativeActionModifierMatches = function() return modifierMatches end
GameKeyboard = { eatKeyPress = function() end }
ViewpointForage = { found = function()
    return { "vanilla-forage-pin", 10, 20, 0, "vanilla-texture", false, false, true, false }
end }
local icon = {
    iconClass = "forageIcon", iconID = 42, itemType = "Twig", itemObj = item,
    player = 0, character = character, itemList = itemList, square = {},
    xCoord = 100, yCoord = 100, zCoord = 0, distanceToPlayer = 1,
    identified = true, x = 0, y = 0,
    getIsSeen = function() return true end,
    getAlpha = function() return 1 end,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getWidth = function() return 24 end,
    getHeight = function() return 24 end,
    setX = function(self, value) self.x = value end,
    setY = function(self, value) self.y = value end,
}
luautils = { walkAdj = function(actionCharacter, square)
    calls.walkAdj = calls.walkAdj + 1
    assert(actionCharacter == character and square == icon.square,
        "vanilla walkAdj should receive the selected character and forage square")
    if icon.distanceToPlayer > 1.6 then
        ISTimedActionQueue.add({ Type = "ISWalkToTimedAction", character = character })
    end
    return icon.walkAdjResult ~= false
end }
icon.onMouseDoubleClick = function(self)
    calls.doubleClick = calls.doubleClick + 1
    if not container:isItemAllowed(self.itemObj) then return end
    if luautils.walkAdj(self.character, self.square) then
        local data = { { type = self.itemObj:getFullType(), poisonPower = 0,
            poisonDetectionLevel = 0 } }
        calls.actionData = data
        ISTimedActionQueue.add(ISForageAction:new(self.character, self.iconID, data,
            container, self.itemType))
    end
end
local ratIcon = {
    iconID = "rat-world-pin", itemType = "Base.Dung_Rat", itemTexture = {},
    identified = true, renderItemTexture = true, texture = "rat-pin-texture",
    xCoord = 100, yCoord = 100, zCoord = 0,
    getIsSeen = function() return true end,
}
local unrelatedWorldIcon = {
    iconID = "unrelated-world-item", itemType = "Base.Twig", xCoord = 100, yCoord = 100, zCoord = 0,
    getIsSeen = function() return true end,
}
local ratIconOnOtherFloor = {
    iconID = "rat-on-other-floor", itemType = "Base.Dung_Rat", xCoord = 100, yCoord = 100, zCoord = 1,
    getIsSeen = function() return true end,
}
local manager = {
    isSearchMode = true,
    iconCategories = { forageIcon = true, worldObjectIcons = true },
    forageIcon = { icon },
    activeIcons = { [42] = icon },
    worldObjectIcons = { ratIcon, unrelatedWorldIcon, ratIconOnOtherFloor },
}
ISSearchManager = { getManager = function() return manager end }
local bridge = {
    active = function() return true end,
    prepareNativeForagePins = function() return true end,
    projectNativeForagePin = function() return true end,
    nativeForagePinScreenWidth = function() return 1600 end,
    nativeForagePinScreenHeight = function() return 900 end,
    nativeForagePinScreenX = function() return 800 end,
    nativeForagePinScreenY = function() return 450 end,
}
ChilaSedaViewpointFogJ = bridge
ISTimedActionQueue = {
    queues = {},
    add = function(action)
        calls.queued[#calls.queued + 1] = action
        liveQueue.queue[#liveQueue.queue + 1] = action
    end,
}
liveQueue.character = character
ISTimedActionQueue.queues[{}] = liveQueue
ISForageAction = {
    new = function(_, actionCharacter, _, itemData, targetContainer, _)
        calls.actionData = itemData
        assert(targetContainer == container, "selected inventory container should be used")
        return {
            Type = "ISForageAction", iconID = 42, character = actionCharacter,
            isValid = function() return true end,
            start = function() return true end,
            complete = function() return true end,
            perform = function() return true end,
            stop = function() return true end,
        }
    end,
}
instanceof = function(value, typeName) return value == item and typeName == "Food" end
require = function() return {} end
UIFont = { Small = "small" }
`;
    const assertions = String.raw`
assert(ViewpointForage.chilaSedaRatDroppingsPinsWrapped == true,
    "the local patch should wrap Viewpoint's native pin provider")
local nativePins = ViewpointForage.found(player, 8)
assert(#nativePins == 18 and nativePins[1] == "vanilla-forage-pin",
    "native forage results must remain intact while the rat-dropping pin is appended")
assert(nativePins[10] == "rat-world-pin" and nativePins[11] == 100
        and nativePins[12] == 100 and nativePins[13] == 0,
    "seen Base.Dung_Rat world objects should enter Viewpoint's nine-field pin rows")
assert(nativePins[14] == "rat-pin-texture" and nativePins[17] == true
        and nativePins[18] == false,
    "the rat pin should retain its known texture and same-floor visible state")
for index = 1, #nativePins, 9 do
    assert(nativePins[index] ~= "unrelated-world-item",
        "unrelated world objects must not be added to Viewpoint's native pins")
    assert(nativePins[index] ~= "rat-on-other-floor",
        "unpointed rat droppings outside the visible floor and reach must stay hidden")
end
local keyHandler = Events.OnKeyStartPressed.callbacks[1]
assert(type(keyHandler) == "function", "Alt+G key handler should register")
keyHandler(71)
local sawAcceptedInput = false
for _, line in ipairs(logs) do
    if string.find(line, "result=accepted keyCode=71", 1, true) then sawAcceptedInput = true end
end
assert(sawAcceptedInput, "accepted Alt+G input should be recorded before pin selection")
assert(calls.doubleClick == 1 and calls.walkAdj == 1,
    "close pin should use the vanilla callback and walkAdj check")
assert(#calls.queued == 1 and calls.queued[1].Type == "ISForageAction",
    "close pin should queue the forage action through vanilla walkAdj")
assert(calls.actionData[1].type == "Base.Twig", "vanilla item data should be preserved")
assert(calls.actionData[1].poisonPower == 0 and calls.actionData[1].poisonDetectionLevel == 0,
    "food poison metadata should be preserved")
assert(string.find(logs[#logs], "result=queued mode=vanilla", 1, true)
        and string.find(logs[#logs], "walkAdjCalls=1 walkAdj=true", 1, true),
    "close pickup should log the vanilla adjacency result")
local firstCloseAction = liveQueue.queue[1]
firstCloseAction.isValid(firstCloseAction)
firstCloseAction.start(firstCloseAction)
assert(firstCloseAction.complete(firstCloseAction) == true,
    "the instrumented vanilla completion method should preserve its return value")
local sawValid, sawCloseStart, sawCloseCompletion = false, false, false
for _, line in ipairs(logs) do
    if string.find(line, "event=isValid result=true mode=vanilla", 1, true) then sawValid = true end
    if string.find(line, "event=start mode=vanilla", 1, true) then sawCloseStart = true end
    if string.find(line, "event=complete-result result=true mode=vanilla", 1, true) then
        sawCloseCompletion = true
    end
end
assert(sawValid and sawCloseStart and sawCloseCompletion,
    "the bounded trace should distinguish validity, start, and successful completion")
keyHandler(71)
assert(calls.doubleClick == 1 and #calls.queued == 1,
    "repeating Alt+G must not enqueue the same close pin while its forage action is active")
assert(liveQueue.queue[1] == firstCloseAction,
    "the active close forage action must remain in the timed-action queue")
assert(string.find(logs[#logs], "result=suppressed reason=already-queued", 1, true),
    "a repeated close-pin shortcut should report the active-action guard")

icon.distanceToPlayer = 4
liveQueue.queue = {}
keyHandler(71)
assert(calls.doubleClick == 2 and calls.walkAdj == 2,
    "far pin should use the vanilla walkAdj callback")
assert(#calls.queued == 3 and calls.queued[3].Type == "ISForageAction"
        and calls.queued[2].Type == "ISWalkToTimedAction",
    "far pin should queue its vanilla walk action before ISForageAction")
assert(string.find(logs[#logs], "result=queued mode=vanilla", 1, true),
    "vanilla pickup outcome should be visible in bounded trace")
local firstVanillaAction = liveQueue.queue[2]
keyHandler(71)
assert(calls.doubleClick == 2 and #calls.queued == 3,
    "repeating Alt+G must not enqueue the same far pin while its forage action is active")
assert(liveQueue.queue[2] == firstVanillaAction,
    "the active vanilla forage action must remain in the timed-action queue")

icon.distanceToPlayer = 1
liveQueue.queue = {}
bridge.projectNativeForagePin = function() return false end
keyHandler(71)
assert(calls.doubleClick == 3 and calls.walkAdj == 3,
    "very close pin under Jill should not require a forward projection")
assert(#calls.queued == 4 and calls.queued[4].Type == "ISForageAction",
    "close pin outside the view should still pass through vanilla walkAdj")
assert(string.find(logs[#logs], "targeting=proximity", 1, true),
    "close fallback should log proximity target selection")

icon.walkAdjResult = false
liveQueue.queue = {}
local queueBeforeBlockedPath = #calls.queued
keyHandler(71)
assert(calls.doubleClick == 4 and calls.walkAdj == 4,
    "a close pin that vanilla cannot reach should still be checked by walkAdj")
assert(#calls.queued == queueBeforeBlockedPath,
    "an unreachable pin must not queue ISForageAction")
assert(string.find(logs[#logs], "result=not-queued mode=vanilla", 1, true)
        and string.find(logs[#logs], "walkAdj=false", 1, true),
    "an unreachable pin should record vanilla's failed adjacency result")
icon.walkAdjResult = nil

icon.distanceToPlayer = 4
liveQueue.queue = {}
bridge.projectNativeForagePin = function() return false end
keyHandler(71)
assert(string.find(logs[#logs], "result=no-target mode=aimed reason=no-pin-passed-target-filters", 1, true),
    "a pin rejected by projection should report a no-target result")
assert(string.find(logs[#logs], "rejectedProjection=1", 1, true),
    "the no-target summary should include projection rejection counts")
icon.distanceToPlayer = 1

for index = 1, 40 do keyHandler(71) end
local queuedBeforeRejectedModifier = #calls.queued
modifierMatches = false
keyHandler(71)
assert(#calls.queued == queuedBeforeRejectedModifier,
    "a mismatched modifier must not dispatch a forage action")
local sawModifierReject = false
for _, line in ipairs(logs) do
    if string.find(line, "result=modifier-rejected keyCode=71", 1, true) then
        sawModifierReject = true
    end
end
assert(sawModifierReject, "a rejected Alt+G chord should be recorded")
modifierMatches = true
manager.isSearchMode = false
keyHandler(71)
assert(string.find(logs[#logs], "result=no-target mode=aimed reason=search-mode-inactive", 1, true),
    "a valid shortcut outside search mode should report why it had no target")
assert(#logs <= 230, "input, attempt, world-pin and lifecycle diagnostics must stay bounded")
`;
    const luaPath = path.join(tempDir, "native-forage-close-contract.lua");
    fs.writeFileSync(luaPath, `${prelude}\n${pickup}\n${assertions}`, "utf8");
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ForageCalibrationKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
