import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/shared/ChilaSeda_VanillaWeightFix.lua",
);
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("saved-weight pass waits for accessible inventory and loot containers", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const lua = fs.readFileSync(luaPath, "utf8");
  const onPlayerUpdate = lua.slice(lua.indexOf("local function onPlayerUpdate"), lua.indexOf("local function onSleepingTick"));
  assert.match(lua, /local nestedChanged, nestedScanned = rebalanceContainer\(nested, visited\)/);
  assert.match(lua, /local containerChanged, containerScanned = rebalanceContainer\(containers:get\(i\), visited\)/);
  assert.match(onPlayerUpdate, /local ok, changed, scanned = pcall\(rebalanceAccessiblePlayer/);
  assert.match(onPlayerUpdate, /result=waiting accessible_items=0/);
  assert.match(onPlayerUpdate, /retry_ticks=/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "weight-rebalance-syntax-"));
  try {
    const harness = path.join(modRoot, "..", "ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua syntax compile passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
