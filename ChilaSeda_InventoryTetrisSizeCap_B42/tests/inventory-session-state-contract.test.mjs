import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_InventoryTetrisSessionState.lua",
);
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("collapsed container grids persist on their owner and restore after UI reconstruction", () => {
  const gameRoot = process.env.PZ_GAME_ROOT
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(gameRoot, "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), "Project Zomboid Java archive was not found: " + gameJar);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "tetris-session-state-"));
  try {
    const harness = path.join(modRoot, "tests/OverflowFloorDropKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = gameJar + ";" + tempDir;
    const fixture = String.raw`
local logs = {}
local nativePrint = print
function print(message)
    logs[#logs + 1] = tostring(message)
    __contractStage = "trace-print"
    nativePrint(tostring(message))
end
local function event()
    local result = {}
    function result.Add(callback) result.callback = callback end
    return result
end
Events = { OnGameBoot = event(), OnGameStart = event() }

local function makeItem(id, fullType, modData)
    local item = { id = id, fullType = fullType, modData = modData or {}, lightStrength = 0 }
    function item:getID() __contractStage = "item-getID"; return self.id end
    function item:getFullType() __contractStage = "item-getFullType"; return self.fullType end
    function item:getModData() __contractStage = "item-getModData"; return self.modData end
    function item:getLightStrength() __contractStage = "item-getLightStrength"; return self.lightStrength end
    function item:getContainer() __contractStage = "item-getContainer"; return self.container end
    function item:getInventory() __contractStage = "item-getInventory"; return self.inventory end
    return item
end

local player = { modData = {}, primary = nil, secondary = nil, playerNum = 0 }
local root = { items = {} }
function player:getInventory() __contractStage = "player-getInventory"; return root end
function player:getModData() return self.modData end
function player:getPlayerNum() return self.playerNum end
function player:getPrimaryHandItem() __contractStage = "player-getPrimaryHandItem"; return self.primary end
function player:getSecondaryHandItem() __contractStage = "player-getSecondaryHandItem"; return self.secondary end
function getSpecificPlayer(number) return player end

function root:getContainingItem() return nil end
function root:getParent() return player end
function root:getType() return "inventory" end
function root:getItems() return self.items end

local function makeContainer(owner, containerType)
    local container = { owner = owner, containerType = containerType or "inventory", carried = true, items = {} }
    function container:getContainingItem() return self.owner end
    function container:getParent() return nil end
    function container:getType() return self.containerType end
    function container:getItems() return self.items end
    function container:isInCharacterInventory(character) return self.carried end
    return container
end

local uiClass = {}
function uiClass:new(inventory, inventoryPane, playerNum)
    return setmetatable({
        inventory = inventory,
        inventoryPane = inventoryPane,
        playerNum = playerNum,
        player = player,
        isGridCollapsed = false,
    }, { __index = uiClass })
end
function uiClass:initialise()
    self.collapseButton = {
        title = "V",
        setTitle = function(button, title) button.title = title end,
    }
end
function uiClass:onCollapseButtonClick()
    self.isGridCollapsed = not self.isGridCollapsed
    self.collapseButton:setTitle(self.isGridCollapsed and ">" or "V")
    self.inventoryPane:refreshContainer()
end
function uiClass:applyScales() end
function require(name)
    assert(name == "InventoryTetris/UI/Container/ItemGridContainerUI", "unexpected module: " .. tostring(name))
    return uiClass
end

ISEquipWeaponAction = {}
function ISEquipWeaponAction:new(character, item)
    return setmetatable({ character = character, item = item }, { __index = ISEquipWeaponAction })
end
function ISEquipWeaponAction:complete()
    __contractStage = "original-equip-complete"
    self.character.primary = self.item
    return true
end
ISUnequipAction = {}
function ISUnequipAction:new(character, item, reason)
    return setmetatable({ character = character, item = item, reason = reason }, { __index = ISUnequipAction })
end
function ISUnequipAction:perform()
    if self.character.primary == self.item then self.character.primary = nil end
    if self.character.secondary == self.item then self.character.secondary = nil end
    return true
end
ISInventoryTransferAction = {}
function ISInventoryTransferAction:new(character, item, source, destination)
    return setmetatable({ character = character, item = item, srcContainer = source, destContainer = destination },
        { __index = ISInventoryTransferAction })
end
function ISInventoryTransferAction:isValid()
    return self.allowed ~= false
end
function ISInventoryTransferAction:perform()
    self.item.container = self.destContainer
    return true
end
function ISInventoryTransferAction:stop() return true end
local queued = {}
ISTimedActionQueue = {}
function ISTimedActionQueue.addAfter(previous, action)
    queued[#queued + 1] = action
    return {}, action
end
local sourceBag = makeItem(41, "Base.Bag", {})
local bagContainer = makeContainer(sourceBag)
sourceBag.inventory = bagContainer
sourceBag.container = root
root.items = { sourceBag }
local pane = { refreshTarget = nil, lastRebuilt = nil }
function pane:refreshContainer()
    if self.refreshTarget ~= nil then
        local target = self.refreshTarget
        self.refreshTarget = nil
        self.lastRebuilt = uiClass:new(target, self, 0)
        self.lastRebuilt:initialise()
    end
end
`;
    const scenario = String.raw`
local __ok, __error = pcall(function()
__contractStage = "first-grid"
local firstUi = uiClass:new(bagContainer, pane, 0)
firstUi:initialise()
assert(firstUi.isGridCollapsed == false, "new containers start expanded without saved state")
pane.refreshTarget = bagContainer
firstUi:onCollapseButtonClick()
assert(firstUi.isGridCollapsed == true, "collapse click changes grid state")
assert(pane.lastRebuilt and pane.lastRebuilt.isGridCollapsed == true,
    "state is saved before Tetris rebuilds the grid inside the click handler")
assert(sourceBag.modData.ChilaSedaInventoryTetrisSessionState.collapsed["grid:contained-item"] == true,
    "collapse state is stored on the containing item")

__contractStage = "reloaded-grid"
local reloadedBag = makeItem(41, "Base.Bag", sourceBag.modData)
local reloadedContainer = makeContainer(reloadedBag)
reloadedBag.inventory = reloadedContainer
root.items = { reloadedBag }
bagContainer = reloadedContainer
local restoredUi = uiClass:new(reloadedContainer, pane, 0)
restoredUi:initialise()
assert(restoredUi.isGridCollapsed == true, "saved state is restored after rebuilding the container UI")
assert(restoredUi.collapseButton.title == ">", "collapse button reflects restored state")
restoredUi:onCollapseButtonClick()
assert(reloadedBag.modData.ChilaSedaInventoryTetrisSessionState.collapsed["grid:contained-item"] == false,
    "expanding persists the open state too")

__contractStage = "root-grid"
local rootUi = uiClass:new(root, pane, 0)
rootUi:initialise()
rootUi:onCollapseButtonClick()
assert(player.modData.ChilaSedaInventoryTetrisSessionState.collapsed["grid:player-root"] == true,
    "player inventory state is stored on the character")

__contractStage = "equip-light"
local light = makeItem(900, "Base.HandTorch", {})
light.lightStrength = 1
light.container = reloadedContainer
__contractStage = "make-equip-action"
local equip = ISEquipWeaponAction:new(player, light, 10, true)
light.container = root -- vanilla transfers the item to the main inventory before the equip completes
__contractStage = "complete-equip-action"
assert(equip:complete() == true, "light equip completes")
__contractStage = "check-light-origin"
local savedOrigin = light.modData.ChilaSedaInventoryTetrisLightOrigin
assert(savedOrigin and savedOrigin.kind == "item" and savedOrigin.itemID == 41,
    "equip keeps a stable ID for the source container")

__contractStage = "unequip-light"
local unequip = ISUnequipAction:new(player, light)
assert(unequip:perform() == true, "light unequip completes")
assert(#queued == 1 and queued[1].destContainer == reloadedContainer,
    "unequip queues a validated transfer back to the source container")
__contractStage = "transfer-light"
queued[1]:perform()
assert(light.container == reloadedContainer, "successful transfer returns the light to its original bag")
assert(light.modData.ChilaSedaInventoryTetrisLightOrigin == nil, "successful return clears the saved origin")

__contractStage = "reload-origin"
local reloadedLight = makeItem(901, "Base.HandTorch", {
    ChilaSedaInventoryTetrisLightOrigin = savedOrigin,
})
reloadedLight.lightStrength = 1
reloadedLight.container = root
player.primary = reloadedLight
local secondUnequip = ISUnequipAction:new(player, reloadedLight)
secondUnequip:perform()
assert(#queued == 2 and queued[2].destContainer == reloadedContainer,
    "a saved source ID resolves after a simulated game reload")
queued[2].allowed = false
assert(queued[2]:isValid() == false, "an unavailable destination rejects the normal transfer")
assert(reloadedLight.modData.ChilaSedaInventoryTetrisLightOrigin ~= nil,
    "a rejected transfer preserves the source descriptor")

__contractStage = "missing-origin"
local missingLight = makeItem(902, "Base.HandTorch", {
    ChilaSedaInventoryTetrisLightOrigin = {
        kind = "item", itemID = 999, itemType = "Base.MissingBag", containerType = "inventory",
    },
})
missingLight.lightStrength = 1
missingLight.container = root
player.primary = missingLight
local missingUnequip = ISUnequipAction:new(player, missingLight)
missingUnequip:perform()
assert(#queued == 2, "unavailable origin does not enqueue a transfer to an unrelated container")
assert(missingLight.container == root, "unavailable origin leaves the item safely in main inventory")
assert(table.concat(logs, "\n"):find("origin-not-accessible", 1, true), "fallback reason is logged")
assert(table.concat(logs, "\n"):find("transfer-validation-failed", 1, true), "transfer validation fallback is logged")
end)
if not __ok then error("inventory session state contract stage=" .. tostring(__contractStage) .. ": " .. tostring(__error)) end
`;
    const fixturePath = path.join(tempDir, "inventory-session-state-contract.lua");
    fs.writeFileSync(fixturePath, fixture + fs.readFileSync(luaPath, "utf8") + "\n" + scenario, "utf8");
    let result;
    try {
      result = execFileSync(
        path.join(jdkBin, "java.exe"),
        ["-classpath", classpath, "OverflowFloorDropKahluaContract", fixturePath],
        { cwd: path.dirname(gameJar), encoding: "utf8" },
      );
    } catch (error) {
      if (error.stdout) process.stderr.write(error.stdout);
      if (error.stderr) process.stderr.write(error.stderr);
      throw error;
    }
    assert.match(result, /Inventory Tetris overflow Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("the local patch is ordered after Inventory Tetris and documented", () => {
  assert.match(modInfo, /^id=ChilaSeda_InventoryTetrisSizeCap_B42$/m);
  assert.match(modInfo, /^require=INVENTORY_TETRIS$/m);
  assert.match(modInfo, /^loadModAfter=INVENTORY_TETRIS,EQUIPMENT_UI,EQUIPMENT_UI_B42$/m);
  assert.match(modInfo, /^versionMin=42\.20$/m);
  assert.match(modInfo, /^modversion=1\.4\.9$/m);
  assert.match(readme, /Version 1\.4\.0/);
  assert.match(readme, /container grids.*collapsed/i);
  assert.match(readme, /source container/i);
});
