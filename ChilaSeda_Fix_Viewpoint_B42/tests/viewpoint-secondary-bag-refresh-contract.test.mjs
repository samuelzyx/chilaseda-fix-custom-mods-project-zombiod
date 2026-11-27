import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzz_ChilaSeda_ViewpointEquippedBagRefresh.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const viewpointRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const viewpointScreen = fs.readFileSync(
  path.join(viewpointRoot, "Viewpoint_InvScreen.lua"),
  "utf8",
);
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const vanillaPage = fs.readFileSync(
  path.join(gameRoot, "media/lua/client/ISUI/ISInventoryPage.lua"),
  "utf8",
);
const gameJar = path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("equipping a hand bag refreshes Viewpoint's native backpack list", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(modInfo, /^loadModAfter=.*Viewpoint/m);
  assert.match(viewpointScreen, /Events\.OnEquipSecondary\.Add\(changed\)/);
  assert.match(viewpointScreen, /self\.bags = D\.bags\(inventory\)/);
  assert.match(vanillaPage, /function ISInventoryPage:refreshBackpacks\(\)/);
  assert.match(vanillaPage, /item:getCategory\(\) == "Container" and playerObj:isEquipped\(item\)/);
  assert.match(lua, /Events\.OnEquipSecondary/);
  assert.match(lua, /page\.refreshBackpacks, page/);
  assert.match(lua, /secondary-container-not-listed/);
  assert.match(lua, /MAX_TRACE_LINES = 24/);

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-secondary-bag-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = `${tempDir};${gameJar}`;
    const java = path.join(jdkBin, "java.exe");
    execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar) },
    );

    const fixture = String.raw`
local function makeEvent()
    local event = { callbacks = {} }
    function event.Add(callback) table.insert(event.callbacks, callback) end
    return event
end
Events = {
    OnEquipPrimary = makeEvent(),
    OnEquipSecondary = makeEvent(),
    OnClothingUpdated = makeEvent(),
}
local logs = {}
print = function(message) table.insert(logs, tostring(message)) end
local bagInventory = {}
local bag = {}
function bag:IsInventoryContainer() return true end
function bag:getInventory() return bagInventory end
local player = {}
function player:getPlayerNum() return 0 end
function player:getSecondaryHandItem() return bag end
local page = { backpacks = {}, refreshCalls = 0 }
function page:refreshBackpacks()
    self.refreshCalls = self.refreshCalls + 1
    self.backpacks = { { inventory = bagInventory } }
end
getSpecificPlayer = function(playerNum) assert(playerNum == 0); return player end
getPlayerInventory = function(playerNum) assert(playerNum == 0); return page end
ViewpointInventory = {}
ViewpointInvScreen = { instance = { dirty = false } }
` + lua + String.raw`
assert(#Events.OnEquipSecondary.callbacks == 1)
assert(#Events.OnEquipPrimary.callbacks == 1)
assert(#Events.OnClothingUpdated.callbacks == 1)
Events.OnEquipSecondary.callbacks[1](player)
assert(page.refreshCalls == 1)
assert(ViewpointInvScreen.instance.dirty == true)
assert(page.backpacks[1].inventory == bagInventory)
assert(string.find(logs[1], "event=secondary result=refreshed secondary-container=listed", 1, true))
Events.OnEquipPrimary.callbacks[1](player)
Events.OnClothingUpdated.callbacks[1](player)
assert(page.refreshCalls == 3)
page.refreshBackpacks = function(self) self.backpacks = {} end
Events.OnEquipSecondary.callbacks[1](player)
assert(string.find(logs[#logs], "reason=secondary-container-not-listed", 1, true))
page.refreshBackpacks = nil
Events.OnEquipSecondary.callbacks[1](player)
assert(string.find(logs[#logs], "reason=refreshBackpacks-unavailable", 1, true))
print("secondary bag refresh fixture passed")
`;
    const fixturePath = path.join(tempDir, "ViewpointSecondaryBagRefreshFixture.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const output = execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
