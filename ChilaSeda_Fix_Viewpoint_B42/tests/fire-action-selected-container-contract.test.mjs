import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaRoot = path.join(modRoot, "42/media/lua/client");
const helperPath = path.join(luaRoot, "ChilaSeda_ViewpointFireTransfers.lua");
const selectedPath = path.join(luaRoot, "ChilaSeda_ViewpointSelectedContainer.lua");
const helper = fs.readFileSync(helperPath, "utf8");
const selected = fs.readFileSync(selectedPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("vanilla fire callbacks force external ingredients into root inventory", () => {
  assert.match(modInfo, /^modversion=2\.0\.128$/m);
  assert.match(selected, /fireTransfers\.callbackFor\(player, source, destination, main\)/);
  const transferBranch = selected.slice(
    selected.indexOf("local fireCallback = fireTransfersAvailable"),
    selected.indexOf("local pickupToPlayer =", selected.indexOf("local fireCallback = fireTransfersAvailable")),
  );
  assert.match(transferBranch, /originalTransferFactory\(player, item, source, main, time/);
  assert.doesNotMatch(transferBranch, /selected/);
  assert.match(helper, /MAX_TRACE_LINES = 32/);
  assert.match(helper, /fire-input-main callback=/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-fire-transfer-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const prelude = String.raw`
local logs = {}
print = function(line) logs[#logs + 1] = tostring(line) end
local function externalContainer(outermost)
    return { getOutermostContainer = function() return outermost end,
             getType = function() return "Campfire" end }
end
local main = {}
local nested = { getOutermostContainer = function() return main end }
local player = {}
local external = externalContainer(nil)
local calls = { literature = 0, kindle = 0, petrol = 0 }
local transferTargets = {}
local function vanillaTransfer(receivedPlayer, item, source, destination)
    transferTargets[#transferTargets + 1] = destination
end
ISInventoryTransferUtil = { newInventoryTransferAction = vanillaTransfer }
local function fireCallback(field)
    return function(receivedPlayer)
        calls[field] = calls[field] + 1
        local item = { getFullType = function() return "Base.Twigs" end }
        local destination = receivedPlayer.inventory
        local callback = FireTransfers.callbackFor(receivedPlayer, external, destination, main)
        if callback then
            FireTransfers.trace(callback, item, external)
            ISInventoryTransferUtil.newInventoryTransferAction(receivedPlayer, item, external, main)
        end
    end
end
player.inventory = main
ISCampingMenu = {
    onLightFromLiterature = fireCallback("literature"),
    onLightFromKindle = fireCallback("kindle"),
    onLightFromPetrol = fireCallback("petrol"),
}
`;
    const assertions = String.raw`
local wrapped = FireTransfers.install(ISCampingMenu)
assert(wrapped == 3, "all three vanilla fire callbacks should be wrapped")
assert(FireTransfers.install(ISCampingMenu) == 0, "wrapping should be idempotent")
ISCampingMenu.onLightFromLiterature(player)
ISCampingMenu.onLightFromKindle(player)
ISCampingMenu.onLightFromPetrol(player)
assert(calls.literature == 1 and calls.kindle == 1 and calls.petrol == 1,
    "all vanilla fire callbacks should remain callable")
assert(#transferTargets == 3 and transferTargets[1] == main
    and transferTargets[2] == main and transferTargets[3] == main,
    "fire ingredients should be transferred to the root inventory")
assert(FireTransfers.callbackFor(player, external, main, main) == nil,
    "the fire transfer context must end when the callback returns")
assert(FireTransfers.callbackFor(player, nested, main, main) == nil,
    "transfers from a nested player bag should keep vanilla routing")
assert(#logs == 3 and string.find(logs[1], "callback=onLightFromLiterature", 1, true),
    "each forced root transfer should produce a diagnostic entry")
`;
    const luaPath = path.join(tempDir, "fire-action-transfer-contract.lua");
    const moduleSource = `FireTransfers = (function()\n${helper}\nend)()`;
    fs.writeFileSync(luaPath, `${prelude}\n${moduleSource}\n${assertions}`, "utf8");
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
