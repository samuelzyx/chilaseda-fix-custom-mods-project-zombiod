import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const patchPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_LootTrackerLeftDaysFormatGuard.lua",
);
const installedMod = process.env.LOOT_TRACKER_B42_PATH
  ?? "J:/SteamLibrary/steamapps/workshop/content/108600/3823828778/mods/LootTracker/42";
const corePath = path.join(installedMod, "media/lua/shared/LootTracker/LT_Core.lua");
const vehiclesUiPath = path.join(installedMod, "media/lua/client/LootTracker/LT_VehiclesUI.lua");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Loot Tracker left-days format guard compiles and preserves the local formatter contract", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(corePath), `Installed Loot Tracker core not found: ${corePath}`);
  assert.ok(fs.existsSync(vehiclesUiPath), `Installed Loot Tracker vehicle UI not found: ${vehiclesUiPath}`);

  const core = fs.readFileSync(corePath, "utf8");
  const vehiclesUi = fs.readFileSync(vehiclesUiPath, "utf8");
  const patch = fs.readFileSync(patchPath, "utf8");
  const originalTextStart = core.indexOf("local textCache = {}");
  const originalTextEnd = core.indexOf("\nfunction LT.sandbox", originalTextStart);
  const formatterStart = vehiclesUi.indexOf("local function fmt(s, ...)");
  const formatterEnd = vehiclesUi.indexOf("\nend", formatterStart) + "\nend".length;
  assert.ok(originalTextStart >= 0 && originalTextEnd > originalTextStart);
  assert.ok(formatterStart >= 0 && formatterEnd > formatterStart);
  assert.match(patch, /pcall\(getTextOrNull, key, "%1"\)/);
  assert.match(patch, /MAX_TRACE_LINES = 8/);
  assert.match(patch, /LT\.TRACE_FORMAT_GUARD ~= true/);

  const originalText = core.slice(originalTextStart, originalTextEnd);
  const fmt = vehiclesUi.slice(formatterStart, formatterEnd);
  const luaPatch = patch;
  const successContract = [
    `local translatorCalls, noArgTargetCalls = 0, 0`,
    `require = function() return true end`,
    `LootTracker = {}`,
    `local LT = LootTracker`,
    `getTextOrNull = function(key, ...)`,
    `  translatorCalls = translatorCalls + 1`,
    `  if key == "IGUI_LootTracker_MyCar_LeftDays" then`,
    `    if select("#", ...) == 0 then noArgTargetCalls = noArgTargetCalls + 1; error("missing format argument") end`,
    `    assert(select(1, ...) == "%1", "guard must pass the placeholder as the format value")`,
    `    return "Aparcado aqui hace %1$s días"`,
    `  end`,
    `  return "Translated ordinary label"`,
    `end`,
    originalText,
    luaPatch,
    fmt,
    `local key = "IGUI_LootTracker_MyCar_LeftDays"`,
    `local raw = LT.text(key, "Left here %1 days ago")`,
    `assert(raw == "Aparcado aqui hace %1 días", "formatted Java placeholder should normalize to Loot Tracker placeholder")`,
    `assert(fmt(raw, 4) == "Aparcado aqui hace 4 días", "Loot Tracker's existing day formatter should replace %1")`,
    `assert(noArgTargetCalls == 0, "guard must never call Translator for the target key without arguments")`,
    `local beforeOther = translatorCalls`,
    `assert(LT.text("IGUI_LootTracker_MyCar_Sub", "My car") == "Translated ordinary label")`,
    `assert(translatorCalls == beforeOther + 1, "unrelated keys must delegate to the original Loot Tracker function")`,
    `LT.TRACE_FORMAT_GUARD = false`,
    `LT.text(key, "ignored fallback")`,
  ].join("\n");

  const failureContract = [
    `local calls, logs = 0, {}`,
    `print = function(message) logs[#logs + 1] = message end`,
    `require = function() return true end`,
    `LootTracker = {}`,
    `local LT = LootTracker`,
    `getTextOrNull = function(key, ...)`,
    `  calls = calls + 1`,
    `  assert(key == "IGUI_LootTracker_MyCar_LeftDays")`,
    `  assert(select("#", ...) == 1 and select(1, ...) == "%1")`,
    `  error("translation missing")`,
    `end`,
    originalText,
    luaPatch,
    `local key = "IGUI_LootTracker_MyCar_LeftDays"`,
    `assert(LootTracker.text(key, "Left here %1 days ago") == "Left here %1 days ago", "translation failure should use the caller fallback")`,
    `assert(calls == 1, "failed lookup should be cached and attempted once")`,
    `assert(LootTracker.text(key, "different fallback") == "Left here %1 days ago", "fallback should be stable for the resolved key")`,
    `assert(calls == 1, "cached fallback should not call Translator again")`,
    `assert(#logs == 2, "trace should record installation and fallback once")`,
    `assert(string.find(logs[2], "event=resolve detail=fallback", 1, true))`,
  ].join("\n");

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "loottracker-format-guard-"));
  try {
    const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);
    for (const [name, lua] of [["success", successContract], ["fallback", failureContract]]) {
      const contractPath = path.join(tempDir, `${name}-contract.lua`);
      fs.writeFileSync(contractPath, lua, "utf8");
      execFileSync(
        path.join(jdkBin, "java.exe"),
        ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
        { cwd: path.dirname(gameJar), encoding: "utf8" },
      );
    }
    const patchSyntaxPath = path.join(tempDir, "patch.lua");
    fs.writeFileSync(patchSyntaxPath, luaPatch, "utf8");
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", patchSyntaxPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
