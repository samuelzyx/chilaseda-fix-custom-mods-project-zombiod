import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const scriptPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_SmartRadialNativeOptions_B42.lua",
);
const script = fs.readFileSync(scriptPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const vanillaPath =
  "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISInventoryPaneContextMenu.lua";
const vanilla = fs.readFileSync(vanillaPath, "utf8");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("radial drink keeps the vanilla callback and traces the mask/action queue", () => {
  assert.match(modInfo, /modversion=1\.1\.15/);
  assert.match(script, /DRINK_TRACE_MAX = 48/);
  assert.match(script, /drink-trace event=/);
  assert.match(script, /queue-reset-cancel/);
  assert.match(script, /is-invalid/);
  assert.match(script, /originalCommand\(arg1, arg2, arg3, arg4, arg5, arg6\)/);
  assert.match(vanilla, /onDrinkFluid = function\(item, percent, playerObj, openingRecipe, realItem\)/);
  assert.match(vanilla, /getEatingMask\(playerObj, true\)[\s\S]*?ISDrinkFluidAction:new\(playerObj, item, percent\)[\s\S]*?ISWearClothing:new\(playerObj, mask, 50\)/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "smart-radial-drink-diagnostics-"));
  try {
    const harness = path.join(modRoot, "../ChilaSeda_Fix_Viewpoint_B42/tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);

    const prelude = String.raw`
local logs = {}
print = function(line) logs[#logs + 1] = tostring(line) end
_G = {}
debug = { getinfo = function() return { name = "test-reset-caller" } end }
local function makeEvent()
    local event = { callbacks = {} }
    event.Add = function(callback) event.callbacks[#event.callbacks + 1] = callback end
    return event
end
Events = { OnGameBoot = makeEvent(), OnGameStart = makeEvent() }
local mask = { getFullType = function() return "Base.Hat_GasMask" end }
local item = { getFullType = function() return "Base.PopBottle" end }
local player = {
    getPlayerNum = function() return 0 end,
    getWornItem = function() return mask end,
}
getSpecificPlayer = function(number) assert(number == 0); return player end
local queueState = { queue = {} }
ISTimedActionQueue = {
    add = function(action) queueState.queue[#queueState.queue + 1] = action end,
    onCompleted = function(self, action) end,
    resetQueue = function(self) self.queue = {} end,
    getTimedActionQueue = function(receivedPlayer) assert(receivedPlayer == player); return queueState end,
}
ISDrinkFluidAction = { isValid = function(action) return false end }
ISInventoryPaneContextMenu = {
    doDrinkFluidMenu = function() end,
    getEatingMask = function(receivedPlayer, removeMask) assert(receivedPlayer == player); return mask end,
}
SRMRadialMenu = { scannedItems = { [0] = {} } }
SRMMenuObject = {
    addSlice = function(self, text, texture, command, item, itemCount,
        extraTooltipText, craftingTooltipForced, arg1, arg2, arg3, arg4, arg5, arg6)
        local slice = { text = text, texture = texture,
            command = { command, arg1, arg2, arg3, arg4, arg5, arg6 }, item = item }
        self.slices[#self.slices + 1] = slice
        return slice
    end,
}
require = function() return {} end
`;
    const luaAssertions = String.raw`
local install = Events.OnGameBoot.callbacks[1]
assert(type(install) == "function", "the local radial patch should register its installer")
install()
local calls = 0
local menu = {
    playerNum = 0,
    slices = {},
    setSliceText = function(self, index, text) self.slices[index].text = text end,
    setSliceTexture = function(self, index, texture) self.slices[index].texture = texture end,
}
SRMMenuObject.addSlice(menu, "Drink", nil, function() end, item)
SRMMenuObject.addSlice(menu, "Drink Smart 80%\n(500 mL)", nil, function()
    calls = calls + 1
    ISTimedActionQueue.add({ Type = "ISUnequipAction", item = mask })
    ISTimedActionQueue.add({ Type = "ISDrinkFluidAction", item = item })
    ISTimedActionQueue.add({ Type = "ISWearClothing", item = mask })
end, item)
assert(menu.slices[1].text:find("Drink Smart") == nil
    and menu.slices[1].text:find("80%%") ~= nil,
    "the promoted Drink Smart slice should remain visible at index one")
menu.slices[1].command[1]()
assert(calls == 1, "radial dispatch should preserve the original Drink Smart callback")
assert(#queueState.queue == 3 and queueState.queue[2].Type == "ISDrinkFluidAction",
    "the callback should queue mask removal, drink, and mask restoration in order")
local drinkAction = queueState.queue[2]
assert(ISDrinkFluidAction.isValid(drinkAction) == false,
    "the harness should exercise the invalid-action diagnostic")
local resetQueue = ISTimedActionQueue.resetQueue
resetQueue(queueState)
local dispatch, queued, invalid, cancelled = false, false, false, false
for _, line in ipairs(logs) do
    if line:find("event=dispatch-start", 1, true) then dispatch = true end
    if line:find("event=queue-add", 1, true) and line:find("action=ISDrinkFluidAction", 1, true) then queued = true end
    if line:find("event=is-invalid", 1, true) then invalid = true end
    if line:find("event=queue-reset-cancel", 1, true) and line:find("action=ISDrinkFluidAction", 1, true) then cancelled = true end
end
assert(dispatch and queued and invalid and cancelled,
    "bounded traces should capture dispatch, queueing, invalidation, and cancellation")
local callerLogged = false
for _, line in ipairs(logs) do
    if line:find("caller=test-reset-caller", 1, true) then callerLogged = true end
end
assert(callerLogged, "drink cancellation trace should identify the queue reset caller")
assert(#logs <= 48, "drink diagnostics should be bounded per session")
`;
    const luaPath = path.join(tempDir, "drink-smart-radial-diagnostics.lua");
    fs.writeFileSync(luaPath, `${prelude}\n${script}\n${luaAssertions}`, "utf8");
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
