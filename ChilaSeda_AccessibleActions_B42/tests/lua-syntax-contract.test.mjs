import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_AccessibleWashing.lua",
);

test("Accessible Washing passes Kahlua syntax and defensive water-menu API contracts", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fsExists(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const tempDir = fsMkdtemp(path.join(os.tmpdir(), "accessible-actions-kahlua-"));
  try {
    const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );

    const washing = fs.readFileSync(luaPath, "utf8");
    const safeCallStart = washing.indexOf("local function safeCall(");
    const safeCallEnd = washing.indexOf("local function isFillableWithWater(", safeCallStart);
    const containersStart = washing.indexOf("local accessibleContainersDiagnosticLogged = false");
    const containersEnd = washing.indexOf("local function collectAccessibleItems(", containersStart);
    const washApiStart = washing.indexOf("local washWaterApiWarnings = {}");
    const washApiEnd = washing.indexOf("local function collectWashableItems(", washApiStart);
    const refreshStart = washing.indexOf("local inventoryPaneRefreshWarnings = {}");
    const refreshEnd = washing.indexOf("local function extendFillContainerSearch(", refreshStart);
    assert.ok(safeCallStart >= 0 && safeCallEnd > safeCallStart);
    assert.ok(containersStart >= 0 && containersEnd > containersStart);
    assert.ok(washApiStart >= 0 && washApiEnd > washApiStart);
    assert.ok(refreshStart >= 0 && refreshEnd > refreshStart);

    const contractPath = path.join(tempDir, "inventory-pane-contract.lua");
    const contract = `local warnings = {}\nprint = function(message) warnings[#warnings + 1] = message end\n`
      + washing.slice(containersStart, containersEnd)
      + `ISInventoryPaneContextMenu = {}\n`
      + `assert(getAccessibleContainers({}) == nil, "missing getContainers must skip the scan")\n`
      + `assert(getAccessibleContainers({}) == nil, "missing getContainers must remain safe")\n`
      + `assert(#warnings == 1, "missing getContainers should log once")\n`
      + `local containers = { marker = true }\n`
      + `ISInventoryPaneContextMenu = { getContainers = function(player) return player.containers end }\n`
      + `assert(getAccessibleContainers({ containers = containers }) == containers, "available getContainers should run")\n`
      + washing.slice(washApiStart, washApiEnd)
      + `assert(getWashRequiredWater({}, {}, "clothing") == nil, "missing wash API must be skipped safely")\n`
      + `assert(getWashRequiredWater({}, {}, "clothing") == nil, "missing wash API must remain safe")\n`
      + `local brokenApi = { GetRequiredWater = function() error("simulated API failure") end }\n`
      + `assert(getWashRequiredWater(brokenApi, {}, "self") == nil, "failing wash API must be caught")\n`
      + `local washApi = { GetRequiredWater = function(item) return item.water end }\n`
      + `assert(getWashRequiredWater(washApi, { water = 6 }, "test") == 6, "available wash API should return water")\n`
      + `assert(#warnings == 3, "each unavailable API path should log at most once")\n`
      + `local warningBaseline = #warnings\n`
      + washing.slice(safeCallStart, safeCallEnd)
      + washing.slice(refreshStart, refreshEnd)
      + `local missingPane = {}\n`
      + `refreshInventoryPaneMethod(missingPane, "updateMainListbox")\n`
      + `refreshInventoryPaneMethod(missingPane, "updateMainListbox")\n`
      + `assert(#warnings == warningBaseline + 1, "missing inventory-pane method should log once")\n`
      + `assert(string.find(warnings[warningBaseline + 1], "method=updateMainListbox", 1, true))\n`
      + `local refreshed = 0\n`
      + `local pane = { updateMainListbox = function(self) refreshed = refreshed + 1 end }\n`
      + `refreshInventoryPaneMethod(pane, "updateMainListbox")\n`
      + `assert(refreshed == 1, "available inventory-pane method should run")\n`
      + `local lookupFailure = setmetatable({}, { __index = function() error("lookup failure") end })\n`
      + `refreshInventoryPaneMethod(lookupFailure, "refreshContainer")\n`
      + `refreshInventoryPaneMethod(lookupFailure, "refreshContainer")\n`
      + `assert(#warnings == warningBaseline + 2, "method lookup failure should be caught and logged once")\n`;
    fs.writeFileSync(contractPath, contract, "utf8");
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fsRm(tempDir);
  }
});

function fsExists(target) {
  return fs.existsSync(target);
}

function fsMkdtemp(prefix) {
  return fs.mkdtempSync(prefix);
}

function fsRm(target) {
  fs.rmSync(target, { recursive: true, force: true });
}
