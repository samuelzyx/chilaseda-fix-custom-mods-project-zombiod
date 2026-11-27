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
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
const gameRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const gameJar = path.join(gameRoot, "projectzomboid.jar");
const tentSource = fs.readFileSync(
  path.join(gameRoot, "media/lua/server/Camping/camping_tent.lua"),
  "utf8",
);
const viewpointModInfo = fs.readFileSync(
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/common/mod.info",
  "utf8",
);
const viewpointSource = fs.readFileSync(
  "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint/42/media/lua/client/Viewpoint_Interact.lua",
  "utf8",
);
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint passes the complete vanilla tent grid into its native menu builder", () => {
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(modInfo, /^loadModAfter=.*Viewpoint/m);
  assert.match(viewpointModInfo, /^modversion=0\.1\.7$/m);
  assert.match(readme, /Rest, Sleep and Pick Up Tent actions/);
  assert.match(lua, /local function includeTentGridObjects\(worldobjects\)/);
  assert.match(lua, /campingApi\.isTentObject/);
  assert.match(lua, /campingApi\.getTentObjects/);
  assert.match(lua, /table\.insert\(worldobjects, part\)/);
  assert.match(lua, /traceTent\("native-menu result=" \.\. tentResult/);
  assert.match(lua, /native-menu result=fallback reason=/);
  assert.match(lua, /MAX_TENT_TRACE_LINES = 16/);

  assert.match(tentSource, /function camping\.isTentObject\(object\)/);
  assert.match(tentSource, /function camping\.getTentObjects\(tent\)/);
  const clientGuard = tentSource.indexOf("if isClient() then return end");
  assert.ok(clientGuard > tentSource.indexOf("function camping.isTentObject(object)"));
  assert.ok(clientGuard > tentSource.indexOf("function camping.getTentObjects(tent)"));
  assert.match(viewpointSource, /local worldobjects = \{ object \}/);
  assert.match(viewpointSource, /local state = ViewpointInteract\.state\(object, worldobjects, player\)/);
  assert.match(viewpointSource, /v ~= state\.worldobjects/);
  assert.match(viewpointSource, /if other then return false end\s*return nil/);
  assert.match(viewpointSource, /mine == nil and depth > 0/);
  assert.match(viewpointSource, /collect\(context, 0, nil, list, state\)/);

  assert.ok(fs.existsSync(gameJar), `PZ archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-tent-menu-"));
  try {
    const harness = path.join(modRoot, "tests/ForageCalibrationKahluaContract.java");
    const javac = path.join(jdkBin, "javac.exe");
    const java = path.join(jdkBin, "java.exe");
    execFileSync(javac, ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = `${tempDir};${gameJar}`;
    execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", luaPath, "--compile-only"],
      { cwd: gameRoot },
    );

    const fixture = String.raw`
local logs = {}
print = function(message) table.insert(logs, tostring(message)) end
local front, back, ordinary = {}, {}, {}
local activeObjects = nil
local function vanillaMenu(objects)
    local complete = #objects == 2 and objects[1] == front and objects[2] == back
    local options = complete and { "Descansar", "Dormir", "Recoger tienda" } or {}
    return { options = options }
end
ViewpointInteract = {
    build = function(playerNum, objects, square)
        assert(playerNum == 0 and square == "square")
        activeObjects = objects
        return true, vanillaMenu(objects)
    end,
}
camping = {
    isTentObject = function(object) return object == front or object == back end,
    getTentObjects = function(object)
        assert(object == front or object == back)
        return { front, back }
    end,
}
` + lua + String.raw`
local objects = { front }
local ok, menu = ViewpointInteract.build(0, objects, "square")
assert(ok and activeObjects == objects)
assert(#objects == 2 and objects[1] == front and objects[2] == back)
assert(#menu.options == 3, "the vanilla builder should receive both tent pieces")
assert(menu.options[1] == "Descansar" and menu.options[2] == "Dormir")
assert(menu.options[3] == "Recoger tienda")
assert(string.find(table.concat(logs, "\n"), "native-menu result=expanded parts=2", 1, true))

local complete = { front, back }
ViewpointInteract.build(0, complete, "square")
assert(#complete == 2, "an already complete tent group must not duplicate its object")

camping = { isTentObject = function() return false end, getTentObjects = function() return {} end }
local unrelated = { ordinary }
ViewpointInteract.build(0, unrelated, "square")
assert(#unrelated == 1 and unrelated[1] == ordinary, "non-tent worldobjects must stay untouched")

camping = { isTentObject = function(object) return object == front end }
local fallbackObjects = { front }
ViewpointInteract.build(0, fallbackObjects, "square")
assert(#fallbackObjects == 1, "missing vanilla grid API must preserve the original route")
assert(string.find(table.concat(logs, "\n"), "native-menu result=fallback reason=vanilla-tent-grid-api-unavailable", 1, true))
assert(#logs <= 32, "the tent trace must remain bounded")
print("Viewpoint tent menu fixture passed")
`;
    const fixturePath = path.join(tempDir, "ViewpointTentMenuFixture.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const output = execFileSync(
      java,
      ["-classpath", classpath, "ForageCalibrationKahluaContract", fixturePath],
      { cwd: gameRoot, encoding: "utf8" },
    );
    assert.match(output, /Viewpoint Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
