import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzzzzz_ChilaSeda_ViewpointFishingHalo.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gameRoot = process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR ?? path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint preserves successful local fishing catches in Halo Notes exactly once", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(modInfo, /loadModAfter=.*Viewpoint/);
  assert.match(lua, /MAX_TRACE_LINES = 16/);
  assert.match(lua, /ChilaSedaViewpointFishingHaloTrace ~= true/);
  assert.match(lua, /result=installed method=ISPickupFishAction\.PickupFishUpdate/);
  assert.match(lua, /source=ISPickupFishAction/);
  assert.match(lua, /"Fishing\.Catch"/);
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const prelude = String.raw`
require = function() return true end
local function event()
  local callbacks = {}
  return {
    callbacks = callbacks,
    Add = function(callback) callbacks[#callbacks + 1] = callback end,
    Remove = function(callback)
      for i = #callbacks, 1, -1 do
        if callbacks[i] == callback then table.remove(callbacks, i) end
      end
    end,
  }
end
Events = { OnGameStart = event(), OnTick = event() }
TestLog = {}
print = function(value) TestLog[#TestLog + 1] = tostring(value) end
local localPlayer = { getPlayerNum = function() return 0 end }
getSpecificPlayer = function(playerNum) if playerNum == 0 then return localPlayer end end
TestNotices = {}
ChilaSeda_ViewpointHaloNotifications = {
  showProtected = function(text, color, icon, duration, source)
    TestNotices[#TestNotices + 1] = {
      text = text, color = color, icon = icon, duration = duration, source = source,
    }
    return true
  end,
}
ISPickupFishAction = {
  PickupFishUpdate = function(self)
    self.vanillaCalls = (self.vanillaCalls or 0) + 1
    if self.shouldAddFish then self.fishInInv = true end
    return "vanilla-result", self.vanillaCalls
  end,
}
`;
  const assertions = String.raw`
assert(ISPickupFishAction.chilaSedaFishingHaloInstalled == true)
local fish = {
  getName = function()
    return "Pequeno Perca sol verde - 11cm (fresco, crudo)"
  end,
}
local action = {
  character = localPlayer, item = fish, isFish = true,
  shouldAddFish = true, fishInInv = false,
}
local first, second = ISPickupFishAction.PickupFishUpdate(action)
assert(first == "vanilla-result" and second == 1, "wrapper must preserve vanilla returns")
assert(#TestNotices == 1, "one notice is emitted for a successful fish pickup")
assert(TestNotices[1].text == "+1 Pequeno Perca sol verde - 11cm (fresco, crudo)")
assert(TestNotices[1].source == "Fishing.Catch")
assert(TestNotices[1].icon == "media/ui/survival_guide_spiffo/category_fishing.png")
ISPickupFishAction.PickupFishUpdate(action)
assert(#TestNotices == 1, "subsequent update frames must not duplicate the catch")

local trash = {
  character = localPlayer, item = fish, isFish = false,
  shouldAddFish = true, fishInInv = false,
}
ISPickupFishAction.PickupFishUpdate(trash)
assert(#TestNotices == 1, "fishing trash must not be reported as a fish")

local remotePlayer = { getPlayerNum = function() return 1 end }
local remoteCatch = {
  character = remotePlayer, item = fish, isFish = true,
  shouldAddFish = true, fishInInv = false,
}
ISPickupFishAction.PickupFishUpdate(remoteCatch)
assert(#TestNotices == 1, "non-local players must not create a local Halo Note")

local nameless = {
  character = localPlayer, item = {}, isFish = true,
  shouldAddFish = true, fishInInv = false,
}
ISPickupFishAction.PickupFishUpdate(nameless)
assert(#TestNotices == 1, "a missing fish display name must not create a broken notice")
`;
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-fishing-halo-"));
  try {
    const harness = path.join(modRoot, "tests/ViewpointFishingHaloKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "viewpoint-fishing-halo.lua");
    fs.writeFileSync(
      fixturePath,
      `${prelude}\nlocal loadOk, loadError = pcall(function()\n${lua}\nend)\nif not loadOk then CONTRACT_RESULT = false; CONTRACT_ERROR = "load: " .. tostring(loadError) else\nlocal contractOk, contractError = pcall(function()\n${assertions}\nend)\nCONTRACT_RESULT = contractOk\nCONTRACT_ERROR = contractError and tostring(contractError) or ""\nend\nCONTRACT_DIAGNOSTICS = table.concat(TestLog, "\\n")`,
      "utf8",
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ViewpointFishingHaloKahluaContract", fixturePath],
      { cwd: gameRoot, encoding: "utf8" },
    );
    assert.match(result, /Fishing Halo Kahlua contract passed/);
    assert.match(result, /event=install result=installed/);
    assert.match(result, /event=fish-catch result=shown source=ISPickupFishAction/);
    assert.match(result, /result=skip reason=not-local-player/);
    assert.match(result, /result=fallback reason=fish-name-unavailable/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
