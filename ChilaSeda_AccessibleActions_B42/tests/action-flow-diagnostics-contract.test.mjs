import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzz_ChilaSeda_AccessibleActionFlowTrace.lua",
);
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");

test("action traces correlate lifecycle events and aggregate repeated water-fill checks", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.match(modInfo, /^modversion=1\.0\.54$/m);
  assert.match(fs.readFileSync(luaPath, "utf8"), /getLuaStackTraceStrings/);
  assert.match(fs.readFileSync(luaPath, "utf8"), /TRACE_WEAR_FLOW = true/);
  assert.match(fs.readFileSync(luaPath, "utf8"), /local TRACE_WATER_DIAGNOSTICS = true/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "accessible-action-trace-"));
  try {
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);

    const fixture = String.raw`
local logs = {}
function print(message) logs[#logs + 1] = tostring(message) end
function require(name) end
local function event()
    local result = { callbacks = {} }
    function result.Add(callback) result.callbacks[#result.callbacks + 1] = callback end
    return result
end
Events = { OnKeyStartPressed = event(), OnTick = event() }
Keyboard = { KEY_CAPITAL = 58 }
local now = 1000
function getTimestampMs() return now end
local callsiteFrames = {
    "zzzz_ChilaSeda_AccessibleActionFlowTrace.lua:500",
    "media/lua/client/ISInventoryPaneContextMenu.lua:456",
    "EquipmentUI/UI/Slots/EquipmentSuperSlot.lua:462",
    "TimedActions/ISWearClothing.lua:99",
}
local luaManagerApi = {
    getLuaStackTraceStrings = function(coroutine)
        assert(coroutine == nil, "LuaManager stack API should select the current coroutine")
        return callsiteFrames
    end,
}
luajava = { bindClass = function(name)
    assert(name == "zombie.Lua.LuaManager", "trace must bind the verified game stack API")
    return luaManagerApi
end }
function getLuaStackTrace() return { "WrongStack.lua:1" } end
debug = { traceback = function()
    return "stack traceback:\n\tEquipmentUI/DragAndDrop.lua:180: in function 'processCancelation'\n"
        .. "\tISInventoryPaneContextMenu.lua:302: in function 'onWearItems'"
end }
local camera = 0
ChilaSedaViewpointFogJ = { movableCameraState = function() return camera end }
local window = {
    Type = "ISInventoryPage",
    visible = true,
    getUIName = function(self) return "Inventory" end,
    isVisible = function(self) return self.visible end,
}
local uiWindows = { window }
UIManager = { getUI = function() return uiWindows end }
local player = { playerNum = 0, worn = {} }
function player:getPlayerNum() return self.playerNum end
function player:getWornItem(slot) return self.worn[slot] end
function getSpecificPlayer(index) return player end
ISTimedActionQueue = { queues = {}, __ChilaSedaAccessibleActionTrace = false }
function ISTimedActionQueue.add(action)
    local queue = ISTimedActionQueue.queues[action.character]
    if not queue then queue = { queue = {} }; ISTimedActionQueue.queues[action.character] = queue end
    queue.queue[#queue.queue + 1] = action
    return queue
end
function ISTimedActionQueue.onCompleted(self, action) return true end
function ISTimedActionQueue.resetQueue(self) self.queue = {}; return true end
ISInventoryTransferAction = { transferItem = function(self, item) return item end }
ISTransferAction = { transferItem = function(self, playerObj, movedItem, source, destination)
    movedItem.container = destination
    return movedItem
end }
ISHandcraftAction = {}
local wearFloor = { getType = function() return "floor" end }
local wearInventory = { getType = function() return "inventory" end }
local previousBackpack = {
    getFullType = function() return "Base.Bag_Old" end,
    getID = function() return 8999 end,
}
local wearable = {
    id = 9001,
    container = wearFloor,
    getFullType = function() return "Base.Bag_Satchel" end,
    getID = function(self) return self.id end,
    getContainer = function(self) return self.container end,
    canBeEquipped = function() return "Back" end,
    getBodyLocation = function() return "" end,
}
player.worn.Back = previousBackpack
ISWearClothing = {}
function ISWearClothing.start(self) return "started" end
function ISWearClothing.complete(self)
    self.character.worn.Back = self.item
    return true
end
function ISWearClothing.perform(self) return "performed" end
function ISWearClothing.stop(self) return "stopped" end
local waterSource = {
    amount = 4,
    getObjectName = function() return "Sink" end,
    getFluidAmount = function(self) return self.amount end,
    isTaintedWater = function() return false end,
}
local bottleFluid = {
    amount = 0,
    getAmount = function(self) return self.amount end,
    getCapacity = function() return 2 end,
}
local bottleContainer = { getType = function() return "inventory" end }
local bottle = {
    beingFilled = false,
    getFullType = function() return "Base.WaterBottleEmpty" end,
    getContainer = function() return bottleContainer end,
    getFluidContainer = function() return bottleFluid end,
    isBeingFilled = function(self) return self.beingFilled end,
}
ISTakeWaterAction = {
    isValid = function(self) return self.waterObject.amount > 0 end,
    start = function(self) self.item.beingFilled = true end,
    transferFluid = function(self, amount)
        bottleFluid.amount = bottleFluid.amount + amount
        self.waterObject.amount = self.waterObject.amount - amount
        return true
    end,
    complete = function(self) self:transferFluid(1); return true end,
    perform = function(self) self.item.beingFilled = false; return true end,
    stop = function(self) self.item.beingFilled = false; return true end,
}
ISWorldObjectContextMenu = {
    onTakeWater = function(_, source, items, item, playerIndex)
        local selected = items and items[1] or item
        local action = {
            Type = "ISTakeWaterAction",
            character = player,
            item = selected,
            waterObject = source,
            waterUnit = 1,
            startUsedAmount = 0,
            endUsedAmount = 2,
            maxTime = 230,
        }
        setmetatable(action, { __index = ISTakeWaterAction })
        ISTimedActionQueue.add(action)
        return true
    end,
}
ISInventoryPane = { getActualUniqueItems = function(items) return items end }
local pamphletContainer = {
    getType = function() return "floor" end,
    getContainingItem = function() return nil end,
    getParent = function() return nil end,
}
local pamphlet = {
    getFullType = function() return "Base.Pamphlet" end,
    getName = function() return "Pamphlet" end,
    getContainer = function() return pamphletContainer end,
    getModData = function() return { printMedia = { info = "pamphlet" } } end,
}
ISReadABook = {
    start = function(self) return "started" end,
    perform = function(self) return "performed" end,
    stop = function(self) return "stopped" end,
    complete = function(self) return "completed" end,
}
ISInventoryPaneContextMenu = {
    readItem = function(item, playerIndex)
        ISTimedActionQueue.add({ Type = "ISReadABook", item = item, character = player })
        return true
    end,
    wearItem = function(item, playerIndex)
        ISTimedActionQueue.add({
            Type = "ISInventoryTransferAction", character = player, item = item,
            srcContainer = wearFloor, destContainer = wearInventory,
        })
        local action = { Type = "ISWearClothing", character = player, item = item }
        ISTimedActionQueue.add(action)
        return "wear-requested", playerIndex
    end,
}
function ISInventoryPaneContextMenu.onLiteratureItems(items, playerIndex)
    for _, item in ipairs(items) do ISInventoryPaneContextMenu.readItem(item, playerIndex) end
    return true
end
`;
    const checks = String.raw`
local function contains(value)
    for _, line in ipairs(logs) do
        if string.find(line, value, 1, true) then return true end
    end
    return false
end
ISInventoryPaneContextMenu.onLiteratureItems({ pamphlet }, 0)
assert(contains("LITERATURE_INSPECT_BEGIN"), "Inspect selection was not logged")
assert(contains("Base.Pamphlet"), "pamphlet type was not logged")
assert(contains("LITERATURE_READ_ITEM_BEGIN"), "vanilla read callback was not logged")
local queue = ISTimedActionQueue.queues[player]
assert(queue and #queue.queue == 1, "read action did not enter the queue")
local action = queue.queue[1]
ISReadABook.start(action)
assert(contains("READBOOK_START_BEGIN"), "read action lifecycle was not logged")
Events.OnKeyStartPressed.callbacks[1](58)
assert(contains("CAPSLOCK_PRESSED"), "Caps Lock was not logged")
camera = 1
window.visible = false
now = now + 201
Events.OnTick.callbacks[1]()
assert(contains("CAPSLOCK_CAMERA_STATE"), "Viewpoint camera transition was not logged")
assert(contains("CAPSLOCK_WINDOW_HIDDEN"), "hidden inventory window was not logged: " .. table.concat(logs, "\n"))
ISTimedActionQueue.resetQueue(queue)
assert(contains("QUEUE_RESET_CANCEL"), "action queue reset was not logged")
assert(contains("capsLockAgeMs="), "queue reset was not correlated to Caps Lock")
ISWorldObjectContextMenu.onTakeWater({}, waterSource, { bottle }, nil, 0)
local waterQueue = ISTimedActionQueue.queues[player]
local waterAction = waterQueue.queue[#waterQueue.queue]
assert(waterAction and waterAction.Type == "ISTakeWaterAction", "water menu callback queued the fill action")
assert(contains("WATER_FILL_CALLBACK_BEGIN") and contains("selected=Base.WaterBottleEmpty"),
    "water menu callback logs the selected container")
assert(contains("WATER_ACTION_QUEUED") and contains("waterSource=Sink"),
    "queued fill action logs its source")
assert(ISTakeWaterAction.isValid(waterAction) == true, "water action remains valid")
for index = 1, 110 do
    assert(ISTakeWaterAction.isValid(waterAction) == true, "repeated water validity check remains true")
    ISTakeWaterAction.transferFluid(waterAction, 0)
end
ISTakeWaterAction.start(waterAction)
ISTakeWaterAction.complete(waterAction)
assert(bottleFluid.amount == 1 and waterSource.amount == 3, "fill action transfers water")
assert(contains("WATER_TRANSFERFLUID_END"), "first fluid transfer sample is logged")
assert(contains("WATER_COMPLETE ") and contains("plannedVolume=1")
        and contains("isValidCalls=111") and contains("transferFluidCalls=111")
        and contains("transferFluidRequestedTotal=1") and contains("itemFluid=1")
        and contains("sourceAmount=3"),
    "terminal completion reports planned volume, repeated-call totals, and final quantities")
local waterTraceLines = 0
for _, line in ipairs(logs) do
    if line:find("] WATER_", 1, true) then waterTraceLines = waterTraceLines + 1 end
end
assert(waterTraceLines < 96 and not contains("WATER_TRACE_LIMIT"),
    "110 repeated validity and transfer cycles do not consume the water trace limit")
ISTakeWaterAction.perform(waterAction)
assert(contains("WATER_COMPLETE_END") and contains("WATER_PERFORM_END"),
    "water action completion and animation cleanup are logged")
waterQueue.queue = {}
ISWorldObjectContextMenu.onTakeWater({}, waterSource, { bottle }, nil, 0)
local stoppedAction = waterQueue.queue[#waterQueue.queue]
ISTakeWaterAction.start(stoppedAction)
ISTakeWaterAction.stop(stoppedAction)
assert(contains("WATER_STOP ") and contains("beingFilled=false") and contains("result=true"),
    "stop event records the interruption result and cleaned container state")
waterQueue.queue = { stoppedAction }
ISTimedActionQueue.resetQueue(waterQueue)
assert(contains("WATER_ACTION_QUEUE_RESET_CANCEL") and contains("result=resetQueue"),
    "queue reset records a cancelled water action and its result")

local sourceContainer = { getType = function() return "inventory" end }
local destinationContainer = { getType = function() return "Bag_Satchel" end }
local trousers = {
    getFullType = function() return "Base.Trousers_CamoTigerStripe" end,
    getContainer = function() return sourceContainer end,
    IsClothing = function() return true end,
}
ISTimedActionQueue.add({
    Type = "ISInventoryTransferAction",
    character = player,
    item = trousers,
    srcContainer = sourceContainer,
    destContainer = destinationContainer,
})
local clothingCallsiteLog
local clothingCallsitePrefix = "[ChilaSeda_AccessibleActionTrace] TRANSFER_CALLSITE "
for index = 1, #logs do
    local line = logs[index]
    if string.sub(line, 1, #clothingCallsitePrefix) == clothingCallsitePrefix then
        clothingCallsiteLog = line
        break
    end
end
assert(clothingCallsiteLog and string.sub(clothingCallsiteLog, 1, #clothingCallsitePrefix) == clothingCallsitePrefix
    and string.find(clothingCallsiteLog, "item=Base.Trousers_CamoTigerStripe", 1, true),
    "clothing transfer callsite is logged")
local expectedCaller = "caller=ISInventoryPaneContextMenu.lua:456>EquipmentSuperSlot.lua:462>ISWearClothing.lua:99"
assert(string.sub(clothingCallsiteLog, -#expectedCaller) == expectedCaller,
    "Lua stack frames are compacted to caller file and line")

getLuaStackTrace = nil
luaManagerApi.getLuaStackTraceStrings = function() return {} end
local fallbackClothing = {
    getFullType = function() return "Base.Socks_Ankle" end,
    getContainer = function() return sourceContainer end,
    IsClothing = function() return true end,
}
ISTimedActionQueue.add({
    Type = "ISInventoryTransferAction",
    character = player,
    item = fallbackClothing,
    srcContainer = sourceContainer,
    destContainer = destinationContainer,
})
local fallbackExpectedCaller = "caller=DragAndDrop.lua:180>ISInventoryPaneContextMenu.lua:302"
local fallbackCallerFound = false
for index = 1, #logs do
    if string.sub(logs[index], -#fallbackExpectedCaller) == fallbackExpectedCaller then
        fallbackCallerFound = true
        break
    end
end
assert(fallbackCallerFound,
    "debug traceback is used when the game Lua stack API is unavailable")

luaManagerApi.getLuaStackTraceStrings = function(coroutine)
    assert(coroutine == nil, "LuaManager stack API should select the current coroutine")
    return callsiteFrames
end
getLuaStackTrace = function() return { "WrongStack.lua:1" } end
local wearResult, wearPlayer = ISInventoryPaneContextMenu.wearItem(wearable, 0)
assert(wearResult == "wear-requested" and wearPlayer == 0,
    "right-click Wear callback return values are preserved")
local wearQueue = ISTimedActionQueue.queues[player]
local wearAction = wearQueue.queue[#wearQueue.queue]
assert(wearAction and wearAction.Type == "ISWearClothing", "wear callback queues vanilla wear action")
assert(ISWearClothing.start(wearAction) == "started", "wear start result is preserved")
assert(ISWearClothing.complete(wearAction) == true and player.worn.Back == wearable,
    "wear completion still equips the selected backpack")
assert(ISWearClothing.perform(wearAction) == "performed", "wear perform result is preserved")
local floorDrop = {
    Type = "ISInventoryTransferAction", character = player, item = wearable,
    srcContainer = wearInventory, destContainer = wearFloor,
}
ISTimedActionQueue.add(floorDrop)
assert(ISTransferAction.transferItem(ISTransferAction, player, wearable, wearInventory, wearFloor) == wearable,
    "low-level floor transfer return value is preserved")
local wearTracePrefix = "[ChilaSeda_AccessibleActionTrace] WEAR_FLOW_"
local wearTraceText = table.concat(logs, "\n")
assert(string.find(wearTraceText, wearTracePrefix .. "REQUEST", 1, true)
    and string.find(wearTraceText, "seq=1 item=Base.Bag_Satchel id=9001", 1, true),
    "right-click Wear request is correlated by item ID")
assert(string.find(wearTraceText, "WEAR_FLOW_QUEUE_ADD", 1, true)
    and string.find(wearTraceText, "type=ISWearClothing selectedItem=true", 1, true),
    "wear action queue entry is correlated with the click")
assert(string.find(wearTraceText, "WEAR_FLOW_ACTION_COMPLETE_BEGIN", 1, true)
    and string.find(wearTraceText, "wornBefore=Base.Bag_Old", 1, true)
    and string.find(wearTraceText, "wornAfter=Base.Bag_Satchel", 1, true),
    "worn slot before and after completing wear are recorded")
assert(string.find(wearTraceText, "WEAR_FLOW_QUEUE_ADD", 1, true)
    and string.find(wearTraceText, "destination=floor", 1, true),
    "floor-bound transfer request is correlated after Wear")
assert(string.find(wearTraceText, "WEAR_FLOW_TRANSFER_BEGIN", 1, true)
    and string.find(wearTraceText, "WEAR_FLOW_TRANSFER_END", 1, true),
    "actual floor transfer is bracketed by the Wear sequence")
assert(string.find(wearTraceText, "callerApi=LuaManager", 1, true)
    and not string.find(wearTraceText, "caller=WrongStack.lua:1", 1, true),
    "verified LuaManager stack frames are preferred over unrelated fallbacks")
for _ = 1, 140 do
    ISTimedActionQueue.add({
        Type = "ISInventoryTransferAction", character = player, item = wearable,
        srcContainer = wearInventory, destContainer = wearFloor,
    })
end
local wearFlowLines, wearFlowLimitLines = 0, 0
for _, line in ipairs(logs) do
    if string.find(line, "WEAR_FLOW_", 1, true) then wearFlowLines = wearFlowLines + 1 end
    if string.find(line, "WEAR_FLOW_LIMIT", 1, true) then wearFlowLimitLines = wearFlowLimitLines + 1 end
end
assert(wearFlowLines == 129 and wearFlowLimitLines == 1,
    "wear flow trace stops at 128 events and emits one limit marker")
now = now + 11001

local food = {
    getFullType = function() return "Base.CuredRabbit" end,
    getContainer = function() return sourceContainer end,
    IsClothing = function() return false end,
}
ISTimedActionQueue.add({
    Type = "ISInventoryTransferAction",
    character = player,
    item = food,
    srcContainer = sourceContainer,
    destContainer = destinationContainer,
})
assert(not contains("TRANSFER_CALLSITE item=Base.CuredRabbit"),
    "non-clothing transfers do not add callsite noise")

getLuaStackTrace = function() return callsiteFrames end
for index = 1, 40 do
    ISTimedActionQueue.add({
        Type = "ISInventoryTransferAction",
        character = player,
        item = trousers,
        srcContainer = sourceContainer,
        destContainer = destinationContainer,
    })
end
local callerTraceCount = 0
for index = 1, #logs do
    local line = logs[index]
    if string.sub(line, 1, #clothingCallsitePrefix) == clothingCallsitePrefix then
        callerTraceCount = callerTraceCount + 1
    end
end
assert(callerTraceCount == 32, "clothing callsite traces are capped at 32 per session")
local callsiteLimitPrefix = "[ChilaSeda_AccessibleActionTrace] TRANSFER_CALLSITE_LIMIT "
local callsiteLimitFound = false
for index = 1, #logs do
    local line = logs[index]
    if string.sub(line, 1, #callsiteLimitPrefix) == callsiteLimitPrefix
        and string.sub(line, -#"limit=32") == "limit=32" then
        callsiteLimitFound = true
        break
    end
end
assert(callsiteLimitFound,
    "callsite trace limit is recorded once")
`;

    const contractPath = path.join(tempDir, "action-flow-diagnostics.lua");
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
