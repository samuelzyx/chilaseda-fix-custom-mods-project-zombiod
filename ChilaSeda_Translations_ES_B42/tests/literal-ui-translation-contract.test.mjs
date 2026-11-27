import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_LiteralUiSpanish.lua");
const catalogPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/UI.json");
const contractPath = path.join(modRoot, "tests/LiteralUiTranslationKahluaContract.java");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const catalogText = fs.readFileSync(catalogPath, "utf8");

function duplicateKeys(text) {
  const seen = new Set();
  const duplicates = new Set();
  for (const match of text.matchAll(/^\s*"((?:[^"\\]|\\.)+)"\s*:/gm)) {
    const key = JSON.parse(`"${match[1]}"`);
    if (seen.has(key)) duplicates.add(key);
    seen.add(key);
  }
  return [...duplicates];
}

test("literal UI catalog parses, has no duplicates, and contains all new labels", () => {
  const catalog = JSON.parse(catalogText);
  assert.deepEqual(duplicateKeys(catalogText), []);
  for (const key of [
    "UI_MiniHealthPanel_NoActionAvailable",
    "UI_HunterExpansion_OpenJournal",
    "UI_HunterExpansion_FeederZoneInfo",
    "UI_HunterExpansion_FeederFillPrefix",
    "UI_HunterExpansion_FeederTooltip",
    "UI_Viewpoint_MenuFramerate",
  ]) {
    assert.equal(typeof catalog[key], "string", `missing ${key}`);
    assert.ok(catalog[key].trim(), `${key} must not be empty`);
  }
  assert.equal(catalog.UI_HunterExpansion_FeederFillPrefix, "Llenar con ");
  assert.match(catalog.UI_HunterExpansion_FeederTooltip, /%s/);
});

test("translation mod version and load order cover the patched Workshop mods", () => {
  assert.match(modInfo, /^modversion=1\.5\.8$/m);
  const loadAfter = modInfo.match(/^loadModAfter=(.+)$/m)?.[1].split(",") ?? [];
  for (const id of ["MiniHealthPanel", "HunterExpansion", "Viewpoint"]) {
    assert.ok(loadAfter.includes(id), `translation mod must load after ${id}`);
  }
});

test("literal context labels, feeder tooltip, fallback, and Viewpoint label work in Kahlua", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "literal-ui-translation-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, contractPath]);
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LiteralUiTranslationKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Literal UI translation Kahlua contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
