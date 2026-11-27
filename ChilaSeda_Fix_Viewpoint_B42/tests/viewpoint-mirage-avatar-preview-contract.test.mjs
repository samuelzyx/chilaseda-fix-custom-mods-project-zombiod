import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzz_ChilaSeda_ViewpointMirageAvatarPreview.lua",
);
const viewpointRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client";
const mirageRoot =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3770186452/mods/MirageWardrobe/42.0/media/lua/client";
const viewpointScreen = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvScreen.lua"), "utf8");
const viewpointGear = fs.readFileSync(path.join(viewpointRoot, "Viewpoint_InvGear.lua"), "utf8");
const mirageCore = fs.readFileSync(path.join(mirageRoot, "MirageWardrobeCore.lua"), "utf8");
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const gameJar = path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint avatar previews use Mirage's detached snapshot and refresh after equipment events", () => {
  const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
  const lua = fs.readFileSync(luaPath, "utf8");
  assert.match(modInfo, /^loadModAfter=.*MirageWardrobe42/m);
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(viewpointScreen, /function Screen:prerender\(\)[\s\S]*?self\.avatar:bind\(player\)/);
  assert.match(viewpointScreen, /local function dressed\(player\)[\s\S]*?Screen\.instance\.redress = true/);
  assert.match(viewpointScreen, /Events\.OnEquipPrimary\.Add\(changed\)/);
  assert.match(viewpointScreen, /Events\.OnEquipSecondary\.Add\(changed\)/);
  assert.match(viewpointGear, /function ViewpointInvAvatar:bind\(player\)[\s\S]*?self:setCharacter\(player\)/);
  assert.match(mirageCore, /MirageWardrobeCore\.isCleanAppearanceEnabled = function \(player\)/);
  assert.match(mirageCore, /MirageWardrobeCore\.setAppearancePreviewCharacter = function \(avatarPanel, player/);
  assert.match(mirageCore, /avatarPanel\.mirageWardrobeAppearanceSnapshot = snapshot/);
  assert.match(lua, /core\.setAppearancePreviewCharacter, avatar, player, cleanAppearance, nil/);
  assert.match(lua, /Events\.OnPreUIDraw\.Add\(flushRefresh\)/);
  assert.match(lua, /MAX_TRACE_LINES = 24/);
  assert.match(lua, /traceState\.enabled ~= true/);

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-mirage-avatar-"));
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
require = function() return true end
local logs = {}
print = function(message) table.insert(logs, tostring(message)) end
Events = {
    OnClothingUpdated = makeEvent(),
    OnEquipPrimary = makeEvent(),
    OnEquipSecondary = makeEvent(),
    OnPreUIDraw = makeEvent(),
}
IsoDirections = { S = "south" }
ViewpointInventory = {}
local cleanEnabled = true
local forcePreviewFailure = false
local previewCalls = {}
local localPlayer = { clean = true }
local otherPlayer = {}
getSpecificPlayer = function(playerNum) assert(playerNum == 0); return localPlayer end
ViewpointInvAvatar = {}
local nativeBindCalls = 0
local setCharacterCalls = 0
function ViewpointInvAvatar:setState(state) self.state = state end
function ViewpointInvAvatar:setDirection(direction) self.direction = direction end
function ViewpointInvAvatar:setIsometric(value) self.isometric = value end
function ViewpointInvAvatar:setCharacter(player) self.player = player; setCharacterCalls = setCharacterCalls + 1 end
function ViewpointInvAvatar:bind(player)
    nativeBindCalls = nativeBindCalls + 1
    self:setState("idle")
    self:setDirection("south")
    self:setIsometric(false)
    self:setCharacter(player)
end
local isUp = true
ViewpointInvScreen = { isUp = function() return isUp end }
MirageWardrobeCore = {
    isCleanAppearanceEnabled = function(player) return cleanEnabled end,
    setAppearancePreviewCharacter = function(avatar, player, clean, state)
        table.insert(previewCalls, { clean = clean, state = state, player = player })
        if forcePreviewFailure then return false, "preview-busy" end
        avatar:setCharacter(player)
        avatar.mirageWardrobeAppearanceSnapshot = {}
        return true
    end,
}
local avatar = setmetatable({}, { __index = ViewpointInvAvatar })
local screen = { avatar = avatar, dirty = false, redress = true }
ViewpointInvScreen.instance = screen
` + fs.readFileSync(luaPath, "utf8") + String.raw`
assert(#Events.OnPreUIDraw.callbacks == 1)
assert(#Events.OnClothingUpdated.callbacks == 1)
assert(#Events.OnEquipPrimary.callbacks == 1)
assert(#Events.OnEquipSecondary.callbacks == 1)
local bound, mode = avatar:bind(localPlayer)
assert(bound == true and mode == "mirage-preview")
assert(nativeBindCalls == 0, "successful Mirage preview should bypass the raw Viewpoint bind")
assert(#previewCalls == 1 and previewCalls[1].clean == true and previewCalls[1].state == nil)
assert(avatar.state == "idle" and avatar.direction == "south" and avatar.isometric == false)
assert(setCharacterCalls == 1 and type(screen.avatar.mirageWardrobeAppearanceSnapshot) == "table")
cleanEnabled = false
local _, disabledMode = avatar:bind(localPlayer)
assert(disabledMode == "mirage-preview" and previewCalls[2].clean == false,
    "the preview bridge must respect Mirage Clean Appearance being disabled")
cleanEnabled = true
screen.redress = false
Events.OnEquipPrimary.callbacks[1](localPlayer, {})
assert(screen.redress == false, "hand events should not depend on Viewpoint's clothing-only redress flag")
Events.OnPreUIDraw.callbacks[1]()
assert(#previewCalls == 3 and screen.redress == false and screen.dirty == true)
assert(string.find(logs[#logs], "event=refresh result=updated source=primary-hand mode=mirage-preview", 1, true))
Events.OnEquipSecondary.callbacks[1](localPlayer, {})
screen.redress = true
Events.OnClothingUpdated.callbacks[1](localPlayer)
Events.OnPreUIDraw.callbacks[1]()
assert(#previewCalls == 4, "equipment events in one UI frame should coalesce to one preview refresh")
local beforeOther = #previewCalls
Events.OnEquipPrimary.callbacks[1](otherPlayer, {})
Events.OnPreUIDraw.callbacks[1]()
assert(#previewCalls == beforeOther, "remote players must not refresh Jill's avatar")
isUp = false
Events.OnClothingUpdated.callbacks[1](localPlayer)
Events.OnPreUIDraw.callbacks[1]()
assert(#previewCalls == beforeOther, "closed Viewpoint UI must not bind an avatar")
assert(string.find(logs[#logs], "reason=screen-not-up", 1, true))
isUp = true
forcePreviewFailure = true
Events.OnClothingUpdated.callbacks[1](localPlayer)
Events.OnPreUIDraw.callbacks[1]()
assert(nativeBindCalls == 1, "failed Mirage snapshot should fall back to Viewpoint's original bind")
assert(string.find(logs[#logs], "reason=vanilla-preview", 1, true))
local traceState = ViewpointInventory.chilaSedaMirageAvatarPreviewTrace
local beforeDisabledTrace = #logs
traceState.enabled = false
avatar:bind(localPlayer)
assert(#logs == beforeDisabledTrace, "the diagnostic trace should be runtime-toggleable")
traceState.enabled = true
for _ = 1, 40 do avatar:bind(localPlayer) end
assert(#logs == 24, "preview tracing must stop at the 24-line cap")
print("Mirage avatar preview fixture passed")
`;
    const fixturePath = path.join(tempDir, "ViewpointMirageAvatarPreviewFixture.lua");
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
