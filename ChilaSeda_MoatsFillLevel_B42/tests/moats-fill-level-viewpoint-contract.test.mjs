import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/zzzzzzzzzz_ChilaSeda_MoatsFillLevel.lua");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const lua = fs.readFileSync(luaPath, "utf8");
const viewpointRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const moatsRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3550032314/mods/Moats/42.22/media/lua";
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const viewpointInteract = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_Interact.lua"), "utf8");
const moatsShared = fs.readFileSync(path.join(moatsRoot, "shared/SharedMoats.lua"), "utf8");
const moatsFlooding = fs.readFileSync(path.join(moatsRoot, "server/SMoatsFlooding.lua"), "utf8");
const moatsCreation = fs.readFileSync(
  path.join(moatsRoot, "server/BuildingObjects/ISEmptyMoats.lua"),
  "utf8",
);
const gameJar = path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

function assertUniqueJsonKeys(filePath) {
  const source = fs.readFileSync(filePath, "utf8");
  JSON.parse(source);
  const keys = new Set();
  const keyPattern = /"((?:\\.|[^"\\])*)"\s*:/g;
  for (const match of source.matchAll(keyPattern)) {
    const key = JSON.parse(`"${match[1]}"`);
    assert.ok(!keys.has(key), `duplicate JSON key ${key} in ${filePath}`);
    keys.add(key);
  }
}

test("Moats fill status is read-only and exposed through Viewpoint's hoverable interaction row", () => {
  assert.match(modInfo, /^id=ChilaSeda_MoatsFillLevel_B42$/m);
  assert.match(modInfo, /^versionMin=42\.22$/m);
  assert.match(modInfo, /^modversion=0\.1\.1$/m);
  assert.match(modInfo, /^loadModAfter=MoatsB42,Viewpoint,ChilaSeda_Fix_Viewpoint_B42$/m);
  assert.match(viewpointInteract, /function ViewpointInteract\.build\(playerNum, worldobjects, sq\)/);
  assert.match(viewpointInteract, /enabled = not o\.notAvailable and not o\.isDisabled/);
  assert.match(viewpointInteract, /tip = o\.toolTip/);
  assert.match(lua, /option\.isDisabled = true/);
  assert.match(lua, /option\.toolTip = tooltip/);
  assert.match(lua, /amount=" \.\. amountText \.\. "\/" \.\. capacityText/);
  assert.match(lua, /MAX_TRACE_LINES = 24/);
  assert.match(moatsShared, /Moats\.WestSprite/);
  assert.match(moatsFlooding, /isoObject:getFluidAmount\(\)/);
  assert.match(moatsCreation, /waterMax=RainCollectorBarrel\.largeWaterMax/);

  const esJson = path.join(modRoot, "42/media/lua/shared/Translate/ES/IG_UI.json");
  const esMxJson = path.join(modRoot, "42/media/lua/shared/Translate/ES_MX/IG_UI.json");
  const enJson = path.join(modRoot, "42/media/lua/shared/Translate/EN/IG_UI.json");
  assertUniqueJsonKeys(esJson);
  assertUniqueJsonKeys(esMxJson);
  assertUniqueJsonKeys(enJson);
  for (const localePath of [esJson, esMxJson]) {
    const catalog = JSON.parse(fs.readFileSync(localePath, "utf8"));
    assert.equal(catalog.IGUI_ChilaSeda_Moats_FillLabel, "Agua de zanja");
    assert.equal(catalog.IGUI_ChilaSeda_Moats_FillMissing, "Faltan {missing}");
    assert.match(catalog.IGUI_ChilaSeda_Moats_FillMissingTooltip, /se convierta en agua normal/);
  }
  const enCatalog = JSON.parse(fs.readFileSync(enJson, "utf8"));
  assert.equal(enCatalog.IGUI_ChilaSeda_Moats_FillLabel, "Trench water");
  assert.equal(enCatalog.IGUI_ChilaSeda_Moats_FillMissing, "{missing} remaining");

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const api = execFileSync(
    path.join(jdkBin, "javap.exe"),
    ["-classpath", gameJar, "zombie.iso.IsoObject", "zombie.iso.sprite.IsoSprite", "zombie.iso.IsoGridSquare"],
    { encoding: "utf8" },
  );
  assert.match(api, /getFluidAmount\(\)/);
  assert.match(api, /getModData\(\)/);
  assert.match(api, /getSprite\(\)/);
  assert.match(api, /getName\(\)/);
  assert.match(api, /getFloor\(\)/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "moats-fill-level-"));
  try {
    const harness = path.resolve(modRoot, "../ChilaSeda_Fix_Viewpoint_B42/tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = `${tempDir};${gameJar}`;
    const java = path.join(jdkBin, "java.exe");
    execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar) },
    );

    const fixturePrelude = String.raw`
local logs = {}
print = function(message) table.insert(logs, tostring(message)) end
local nativeError = error
assert = function(condition, message)
    if not condition then nativeError("TEST_ASSERT: " .. tostring(message or "no-message")) end
    return condition
end
local noop = function() end
Moats = {
    WestSprite = "location_community_cemetary_01_16",
    LongitudeSprite = "location_community_cemetary_01_17",
    EastSprite = "location_community_cemetary_01_18",
    SouthSprite = "location_community_cemetary_01_19",
    LatitudeSprite = "location_community_cemetary_01_20",
    NorthSprite = "location_community_cemetary_01_21",
}
RainCollectorBarrel = { largeWaterMax = 400 }
getText = function(key)
    if key == "IGUI_ChilaSeda_Moats_FillLabel" then return "Agua de zanja" end
    if key == "IGUI_ChilaSeda_Moats_FillTooltip" then return "Cantidad actual frente a capacidad total." end
    if key == "IGUI_ChilaSeda_Moats_FillMissing" then return "Faltan {missing}" end
    if key == "IGUI_ChilaSeda_Moats_FillMissingTooltip" then return "Cantidad que falta para que esta zanja se convierta en agua normal." end
    return key
end
ISToolTip = {}
function ISToolTip:new()
    local tooltip = {}
    function tooltip:initialise() end
    function tooltip:setVisible(value) self.visible = value end
    function tooltip:doLayout()
        self.descriptionPanel = { lines = {}, rgb = {}, fonts = {}, orient = {}, images = {} }
        self.width, self.height = 240, 80
    end
    return tooltip
end
local spriteName = Moats.WestSprite
local sprite = { getName = function() return spriteName end }
local amount = 172
local moat = {
    getSprite = function() return sprite end,
    getFluidAmount = function() return amount end,
    getModData = function() return {} end,
}
local square = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getFloor = function() return moat end,
    getObjects = function() return { size = function() return 0 end } end,
}
local function newContext()
    local menu = { numOptions = 1, options = {} }
    function menu:addOption(name, target, callback)
        local option = { name = name, target = target, onSelect = callback }
        self.options[self.numOptions] = option
        self.numOptions = self.numOptions + 1
        return option
    end
    return menu
end
ViewpointInteract = {
    build = function(playerNum, worldobjects, targetSquare)
        assert(playerNum == 0 and worldobjects[1] ~= nil and targetSquare == square, "stub-build-args")
        return true, newContext()
    end,
    collect = function(menu, depth, prefix, out, state)
        for index = 1, menu.numOptions - 1 do
            local option = menu.options[index]
            if option and option.onSelect and option.target == state.object then
                table.insert(out, {
                    enabled = not option.notAvailable and not option.isDisabled,
                    tip = option.toolTip,
                })
            end
        end
    end,
}
`;
    const fixturePostlude = String.raw`

local ok, context = ViewpointInteract.build(0, { moat }, square)
assert(ok and context and context.numOptions == 2, "a moat should add one status option")
local option = context.options[1]
assert(option.name == "Agua de zanja: 172 / 400 (43%; Faltan 228)", option.name)
assert(option.isDisabled == true, "status must be informational, not executable")
assert(option.target == moat, "Viewpoint must recognize the row as belonging to the selected target")
assert(option.toolTip.description == "Cantidad actual frente a capacidad total.<LINE>Cantidad que falta para que esta zanja se convierta en agua normal.<LINE>Agua de zanja: 172 / 400 (43%; Faltan 228)",
    "tooltip content must include the measured level")

local actions = {}
ViewpointInteract.collect(context, 0, nil, actions, {
    seen = 0, skip = {}, own = {}, object = moat, worldobjects = { moat }, lockedWord = "",
})
assert(#actions == 1, "Viewpoint's collector contract must expose the informational row")
assert(actions[1].enabled == false and actions[1].tip == option.toolTip,
    "the row must be disabled and retain its hover tooltip in Viewpoint")
amount = 400
local _, fullContext = ViewpointInteract.build(0, { moat }, square)
assert(fullContext.options[1].name == "Agua de zanja: 400 / 400 (100%; Faltan 0)", "full tile has no missing water")

spriteName = "floors_exterior_natural_01_0"
local _, ordinaryContext = ViewpointInteract.build(0, { moat }, square)
assert(ordinaryContext.numOptions == 1, "unrelated ground must not get a Moats status row")
assert(#logs <= 24, "diagnostic trace must remain bounded")
print("Moats fill status Viewpoint fixture passed")
`;
    const fixture = fixturePrelude + lua + "\n" + fixturePostlude;
    const fixturePath = path.join(tempDir, "MoatsFillLevelFixture.lua");
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
