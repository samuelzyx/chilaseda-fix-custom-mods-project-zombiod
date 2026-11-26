import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_InventoryItemDropTrace.lua");
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");

test("floor transfer trace records pickup/drop counts without changing transfer results", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const helper = path.resolve(
    modRoot,
    "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
  );
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), "Kahlua contract helper was not found");
  assert.match(modInfo, /^modversion=2\.1\.13$/m);
  assert.match(lua, /MAX_TRACE_LINES = 192/);
  assert.match(lua, /MAX_CARRIED_ITEMS = 2000/);
  assert.match(lua, /readOnly=1/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "inventory-item-drop-trace-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);
    const fixture = String.raw`
local logs = {}
local queuedItem
local outputPrint = print
function print(message) logs[#logs + 1] = tostring(message) end
local function event()
    local result = {}
    function result.Add(callback) result.callback = callback end
    return result
end
Events = { OnGameBoot = event(), OnGameStart = event() }
local luaStackFrames = {
    "ChilaSeda_InventoryItemDropTrace.lua:140",
    "ISInventoryPaneContextMenu.lua:2867",
    "ISWearClothing.lua:101",
}
luajava = { bindClass = function(name)
    assert(name == "zombie.Lua.LuaManager", "trace binds the verified public game stack API")
    return { getLuaStackTraceStrings = function(coroutine)
        assert(coroutine == nil, "LuaManager selects the current coroutine")
        return luaStackFrames
    end }
end }
local function container(kind)
    local result = { kind = kind, items = {} }
    function result:getType() return self.kind end
    function result:getItems() return self.items end
    return result
end
local function item(id, fullType, contents)
    local result = { id = id, fullType = fullType, childContainer = contents }
    function result:getID() return self.id end
    function result:getFullType() return self.fullType end
    function result:getContainer() return self.container end
    function result:getItemContainer() return self.childContainer end
    return result
end
local main = container("inventory")
local backpack = container("bag")
local floor = container("floor")
local knife = item(2, "Base.HuntingKnife")
local bag = item(1, "Base.Bag_Satchel", backpack)
local apple = item(3, "Base.Apple")
bag.container = main
knife.container = backpack
apple.container = floor
main.items[1] = bag
backpack.items[1] = knife
floor.items[1] = apple
local player = { inventory = main }
function player:getInventory() return self.inventory end
function getSpecificPlayer(index) return index == 0 and player or nil end
ISTransferAction = {
    transferItem = function(self, playerObj, movedItem, source, destination)
        for index, value in ipairs(source.items) do
            if value == movedItem then table.remove(source.items, index); break end
        end
        destination.items[#destination.items + 1] = movedItem
        movedItem.container = destination
        return "moved", 7
    end,
}
ISInventoryPaneContextMenu = {
    dropItem = function(movedItem, playerNum)
        queuedItem = movedItem
        return "queued", playerNum
    end,
}
ISDropItemAction = {
    perform = function(self)
        local result, marker = ISTransferAction.transferItem(
            ISTransferAction, self.character, self.item, self.item:getContainer(), floor)
        return "performed", result, marker
    end,
}
function require(name)
    if name == "TimedActions/ISTransferAction" then return ISTransferAction end
    if name == "TimedActions/ISDropItemAction" then return ISDropItemAction end
    if name == "ISUI/ISInventoryPaneContextMenu" then return ISInventoryPaneContextMenu end
    return true
end
`;
    const checks = String.raw`
local function runContract()
assert(ISTransferAction.__ChilaSedaInventoryItemDropTrace == true, "low-level transfer hook installed")
assert(ISDropItemAction.__ChilaSedaInventoryItemDropTrace == true, "drop action hook installed")
assert(ISInventoryPaneContextMenu.__ChilaSedaInventoryItemDropTrace == true, "drop request hook installed")
local beforePickup, pickupMarker = ISTransferAction.transferItem(
    ISTransferAction, player, apple, floor, main)
assert(beforePickup == "moved" and pickupMarker == 7, "pickup return values are preserved")
assert(#main.items == 2 and #backpack.items == 1 and #floor.items == 0,
    "pickup behavior and carried inventory are unchanged")
local actionResult, transferResult, actionMarker = ISDropItemAction:perform()
assert(actionResult == "performed" and transferResult == "moved" and actionMarker == 7,
    "drop action return values are preserved")
assert(#main.items == 2 and #backpack.items == 0 and #floor.items == 1,
    "drop action behavior is unchanged")
local function find(fragment)
    for _, line in ipairs(logs) do
        if string.find(line, fragment, 1, true) then return line end
    end
end
assert(find("transfer phase=before direction=pickup item=Base.Apple id=3 source=floor destination=inventory carriedItems=2"),
    "pickup source and carried count are logged")
assert(find("transfer phase=after direction=pickup item=Base.Apple id=3 source=floor destination=inventory carriedBefore=2 carriedAfter=3"),
    "pickup count delta is logged")
assert(find("drop-action phase=before item=Base.HuntingKnife id=2 source=bag carriedItems=3"),
    "drop action and pre-drop count are logged")
assert(find("transfer phase=before direction=drop item=Base.HuntingKnife id=2 source=bag destination=floor carriedItems=3"),
    "floor drop source and count are logged")
assert(find("drop-action phase=after item=Base.HuntingKnife id=2 carriedBefore=3 carriedAfter=2 itemContainerAfter=floor"),
    "post-drop count and destination are logged")
local request, requestPlayer = ISInventoryPaneContextMenu.dropItem(knife, 0)
assert(request == "queued" and requestPlayer == 0 and queuedItem == knife,
    "drop request return values are preserved")
local requestTrace = find("drop-request phase=queue item=Base.HuntingKnife id=2 source=floor playerNum=0 carriedItems=2")
assert(requestTrace, "drop request and caller are logged")
assert(string.find(requestTrace, "caller=LuaManager:ISInventoryPaneContextMenu.lua:2867>ISWearClothing.lua:101", 1, true),
    "drop caller frames come from the verified LuaManager API")
for _ = 1, 220 do ISInventoryPaneContextMenu.dropItem(knife, 0) end
local traceLines, capLines = 0, 0
for _, line in ipairs(logs) do
    if string.find(line, "[ChilaSeda_InventoryItemDropTrace]", 1, true) then traceLines = traceLines + 1 end
    if string.find(line, "capped=1 lines=192", 1, true) then capLines = capLines + 1 end
end
assert(traceLines == 194 and capLines == 1, "diagnostic output must stop at 192 lines plus startup and one cap marker")
end
local contractOk, contractError = pcall(runContract)
if not contractOk then outputPrint("CONTRACT_FAILURE:" .. tostring(contractError)) end
`;
    const contractPath = path.join(tempDir, "inventory-item-drop-trace.lua");
    fs.writeFileSync(contractPath, fixture + lua + "\n" + checks, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
    assert.doesNotMatch(result, /CONTRACT_FAILURE:/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
