import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const panelPath = path.join(
  modRoot,
  "42/media/lua/client/zzzz_ChilaSeda_ViewpointConditionSquares.lua",
);
const optionsPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_ViewpointNativeFogOptions.lua",
);
const promptPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzz_ChilaSeda_ViewpointAnimalCorpsePrompt.lua",
);
const translationPath = path.resolve(
  modRoot,
  "../ChilaSeda_Translations_ES_B42/42/media/lua/shared/Translate/ES/UI.json",
);
const panelLua = fs.readFileSync(panelPath, "utf8");
const optionsLua = fs.readFileSync(optionsPath, "utf8");
const promptLua = fs.readFileSync(promptPath, "utf8");
const translationSource = fs.readFileSync(translationPath, "utf8");
const translationInfo = fs.readFileSync(
  path.resolve(modRoot, "../ChilaSeda_Translations_ES_B42/42/mod.info"),
  "utf8",
);

function assertNoDuplicateObjectKeys(source) {
  let at = 0;
  const skipSpace = () => {
    while (/\s/.test(source[at] ?? "")) at += 1;
  };
  const parseString = () => {
    const start = at;
    at += 1;
    while (at < source.length) {
      if (source[at] === "\\") {
        at += 2;
        continue;
      }
      if (source[at++] === '"') break;
    }
    return JSON.parse(source.slice(start, at));
  };
  const parseValue = () => {
    skipSpace();
    if (source[at] === "{") {
      at += 1;
      const keys = new Set();
      skipSpace();
      if (source[at] === "}") {
        at += 1;
        return;
      }
      while (at < source.length) {
        skipSpace();
        const key = parseString();
        assert.ok(!keys.has(key), `duplicate JSON object key: ${key}`);
        keys.add(key);
        skipSpace();
        assert.equal(source[at++], ":", `expected colon after ${key}`);
        parseValue();
        skipSpace();
        const delimiter = source[at++];
        if (delimiter === "}") return;
        assert.equal(delimiter, ",", `expected comma after ${key}`);
      }
      assert.fail("unterminated JSON object");
    }
    if (source[at] === "[") {
      at += 1;
      skipSpace();
      if (source[at] === "]") {
        at += 1;
        return;
      }
      while (at < source.length) {
        parseValue();
        skipSpace();
        const delimiter = source[at++];
        if (delimiter === "]") return;
        assert.equal(delimiter, ",", "expected comma in JSON array");
      }
      assert.fail("unterminated JSON array");
    }
    if (source[at] === '"') {
      parseString();
      return;
    }
    while (at < source.length && !/[\s,}\]]/.test(source[at])) at += 1;
    assert.ok(at > 0, "expected a JSON value");
  };

  parseValue();
  skipSpace();
  assert.equal(at, source.length, "unexpected trailing data after JSON value");
}

test("corpse options expose an independent shortcut selector and wear indicator", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-corpse-panel-"));
  try {
    const harness = path.join(modRoot, "tests/CorpsePanelOptionsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "CorpsePanelOptionsKahluaContract", panelPath, optionsPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Corpse panel options Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("animal corpse prompt reads and displays its own modifier", () => {
  assert.match(optionsLua, /ANIMAL_CORPSE_MODIFIER_OPTION_ID\s*=\s*"animalCorpseActionModifier"/);
  assert.match(optionsLua, /UI_ChilaSeda_ViewpointFix_ForagePickupTitle", "Hallazgos con pin de rebusqueda"/);
  assert.match(promptLua, /ChilaSedaViewpointAnimalCorpseActionModifierMatches/);
  assert.match(promptLua, /ChilaSedaViewpointFormatAnimalCorpseActionKey/);
  assert.match(panelLua, /panel-scale section=corpse/);
  assert.match(panelLua, /originalContentHeight/);
});

test("Spanish UI catalog parses without duplicate keys and includes the new labels", () => {
  assertNoDuplicateObjectKeys(translationSource);
  assert.match(translationInfo, /^modversion=1\.4\.95$/m);
  const catalog = JSON.parse(translationSource);
  assert.equal(catalog.UI_ChilaSeda_ViewpointFix_ForagePickupTitle, "Hallazgos con pin de rebusqueda");
  assert.ok(catalog.UI_ChilaSeda_ViewpointFix_AnimalCorpseActionModifier);
  assert.equal(catalog.UI_ChilaSeda_ViewpointFix_CorpseWearStyleBar, "Barra de desgaste");
  assert.equal(catalog.UI_ChilaSeda_ViewpointFix_CorpseWearStyleFrame, "Marco de color");
});
