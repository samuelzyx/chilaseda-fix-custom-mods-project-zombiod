import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzz_ChilaSeda_ViewpointCampfireMenus.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const viewpointRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const interactionSource = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_Interact.lua"), "utf8");
const inputSource = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvInput.lua"), "utf8");
const gridSource = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvGrid.lua"), "utf8");
const campingSource = fs.readFileSync(
  path.join(gameRoot, "media/lua/shared/Camping/ISCampingMenu.lua"),
  "utf8",
);
const gameJar = path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint routes world and section fire menus through the native camping builder", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(modInfo, /^loadModAfter=.*Viewpoint/m);
  assert.match(interactionSource, /function ViewpointInteract\.build\(playerNum, worldobjects, sq\)/);
  assert.match(inputSource, /function Screen:onRightMouseUp\(x, y\)/);
  assert.match(gridSource, /hit\(self, x, y, w, m\.header, \{ kind = "header", section = s \}\)/);
  assert.match(campingSource, /ISCampingMenu\.doCampingMenu = function\(player, context, worldobjects, test\)/);
  assert.match(campingSource, /IGUI_BBQ_FuelAmount/);
  assert.match(lua, /ISCampingMenu\.doCampingMenu/);
  assert.match(lua, /fuel-title result=shown/);
  assert.match(lua, /row-menu result=opened/);
  assert.match(lua, /MAX_TRACE_LINES = 32/);

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-campfire-menu-"));
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
local logs = {}
print = function(message) table.insert(logs, tostring(message)) end
local campfireCalls = 0
local menuOptions = {}
local fireObject = {}
local square = {}
local campfire = { fuelAmt = 90, isLit = false }
function fireObject:getSquare() return square end
function fireObject:getTileName() return "Campfire" end
function campfire:getIsoObject() return fireObject end
local fuelInfo = function() end
local submenu = { numOptions = 2, options = {} }
local function newMenu()
    local menu = { numOptions = 1, options = {} }
    function menu:getSubMenu(index) assert(index == 1); return submenu end
    return menu
end
local worldMenu = newMenu()
local openedMenu = nil
local function addVanillaOptions(playerNum, context, objects, test)
    assert(playerNum == 0 and objects[1] == fireObject and test == false)
    campfireCalls = campfireCalls + 1
    context.options[1] = { name = "Campfire", subOption = 1 }
    context.numOptions = 2
    submenu.options[1] = { onSelect = ISCampingMenu.onDisplayInfo }
    return true
end
ISCampingMenu = {
    onDisplayInfo = fuelInfo,
    timeString = function(minutes) return tostring(minutes) .. " min" end,
    doCampingMenu = addVanillaOptions,
}
CCampfireSystem = {
    instance = {
        getLuaObjectOnSquare = function(self, value) assert(value == square); return campfire end,
    },
}
getText = function(key, value) return "ES:" .. key .. (value and (" " .. tostring(value)) or "") end
ISToolTip = {}
function ISToolTip:new()
    local tip = {}
    function tip:initialise() end
    function tip:setVisible(value) self.visible = value end
    return tip
end
ViewpointInteract = {
    build = function(playerNum, objects, targetSquare)
        assert(playerNum == 0 and objects[1] == fireObject and targetSquare == square)
        return true, worldMenu
    end,
}
ViewpointInvGrid = {
    header = function(self, ui, section) self.renderedTitle = section.title end,
}
ViewpointInvScreen = {
    track = function(self) self:noteTip(nil); return "tracked" end,
    onRightMouseUp = function(self) self.originalCalls = (self.originalCalls or 0) + 1; return "original" end,
}
ISContextMenu = {
    get = function(playerNum, x, y)
        assert(playerNum == 0)
        openedMenu = newMenu()
        openedMenu.x, openedMenu.y = x, y
        return openedMenu
    end,
}
` + lua + String.raw`
local ok, context = ViewpointInteract.build(0, { fireObject }, square)
assert(ok and context == worldMenu)
assert(campfireCalls == 1, "world menu should add the native camping actions")
assert(worldMenu.options[1].name == "Campfire")
assert(submenu.options[1].toolTip.description == "ES:IGUI_BBQ_FuelAmount 90 min (ES:IGUI_Fireplace_Unlit)")
assert(string.find(logs[#logs], "fuel-tooltip result=attached target=world-menu", 1, true))

ViewpointInteract.build(0, { fireObject }, square)
assert(campfireCalls == 1, "an existing native fire submenu must not be duplicated")

local section = { title = "Hoguera", container = { getParent = function() return fireObject end } }
local grid = {}
ViewpointInvGrid.header(grid, nil, section, {}, 0, 0, 100, {})
assert(grid.renderedTitle == "Hoguera (90 min)", "the section title should show fuel time")
assert(section.title == "Hoguera", "the shared section title must be restored after drawing")

local screen = {
    up = true,
    hit = function() return { kind = "header", section = section } end,
    getAbsoluteX = function() return 100 end,
    getAbsoluteY = function() return 200 end,
    noteTip = function(self, text) self.note = text end,
    hover = { kind = "header", section = section },
}
assert(ViewpointInvScreen.track(screen) == "tracked")
assert(string.find(screen.note, "90 min", 1, true), "the hovered row tooltip should show remaining fuel")
assert(string.find(screen.note, "Unlit", 1, true), "the tooltip should show whether the fire is lit")
assert(string.find(logs[#logs], "fuel-tooltip result=shown target=inventory-row", 1, true))

assert(ViewpointInvScreen.onRightMouseUp(screen, 10, 20) == true)
assert(campfireCalls == 2, "right-clicking the row should build the vanilla fire menu")
assert(openedMenu.x == 110 and openedMenu.y == 220, "the menu should open at the row's screen position")
assert(openedMenu.options[1].name == "Campfire")
assert(screen.originalCalls == nil, "the native row menu should consume a campfire right-click")

screen.hit = function() return { kind = "tile" } end
assert(ViewpointInvScreen.onRightMouseUp(screen, 10, 20) == "original")
assert(screen.originalCalls == 1, "non-section clicks should keep Viewpoint's original input path")
assert(#logs <= 32, "campfire traces should stay bounded")
print("campfire menus and fuel display fixture passed")
`;
    const fixturePath = path.join(tempDir, "ViewpointCampfireMenuFixture.lua");
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
