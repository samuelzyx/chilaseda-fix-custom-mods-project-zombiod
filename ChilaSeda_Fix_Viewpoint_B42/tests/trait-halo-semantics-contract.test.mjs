import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_ViewpointHaloNotifications.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

function section(source, start, end) {
  const from = source.indexOf(start);
  assert.notEqual(from, -1, `missing section start: ${start}`);
  const to = source.indexOf(end, from + start.length);
  assert.notEqual(to, -1, `missing section end: ${end}`);
  return source.slice(from, to);
}

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

test("installed B42 labels LessSleep as a beneficial reduction in sleep need", () => {
  const gameRoot = process.env.PZ_GAME_ROOT
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
  const uiPath = path.join(gameRoot, "media/lua/shared/Translate/ES_MX/UI.json");
  const traitsPath = path.join(gameRoot, "media/scripts/generated/characters/character_traits.txt");
  const ui = JSON.parse(fs.readFileSync(uiPath, "utf8"));
  const traits = fs.readFileSync(traitsPath, "utf8");
  const lessStart = traits.indexOf("character_trait_definition base:needslesssleep");
  const moreStart = traits.indexOf("character_trait_definition base:needsmoresleep");
  const nightOwlStart = traits.indexOf("character_trait_definition base:nightowl", moreStart);
  assert.ok(lessStart >= 0 && moreStart > lessStart && nightOwlStart > moreStart);

  assert.equal(ui.UI_trait_LessSleep, "Insomne");
  assert.equal(ui.UI_trait_LessSleepDesc, "Necesita dormir menos.");
  assert.equal(ui.UI_trait_MoreSleep, "Dormilón");
  assert.equal(ui.UI_trait_Insomniac, "Sueño inquieto");
  assert.match(traits.slice(lessStart, moreStart), /Cost\s*=\s*3/);
  assert.match(traits.slice(moreStart, nightOwlStart), /Cost\s*=\s*-4/);
});

test("sleep labels are localized and JSON catalogs have no duplicate keys", () => {
  for (const locale of ["EN", "ES", "ES_MX"]) {
    const file = path.join(
      modRoot,
      `42/media/lua/shared/Translate/${locale}/UI.json`,
    );
    const source = fs.readFileSync(file, "utf8");
    assertNoDuplicateObjectKeys(source);
    const catalog = JSON.parse(source);
    assert.ok(catalog.UI_ChilaSeda_ViewpointHalo_LessSleep.includes("("));
    assert.ok(catalog.UI_ChilaSeda_ViewpointHalo_MoreSleep.includes("("));
  }
  const esMx = JSON.parse(fs.readFileSync(
    path.join(modRoot, "42/media/lua/shared/Translate/ES_MX/UI.json"),
    "utf8",
  ));
  assert.equal(
    esMx.UI_ChilaSeda_ViewpointHalo_LessSleep,
    "Menor necesidad de sueño (menos duración al dormir)",
  );
  assert.equal(
    esMx.UI_ChilaSeda_ViewpointHalo_MoreSleep,
    "Mayor necesidad de sueño (más duración al dormir)",
  );
});

test("trait deltas point up when beneficial and down when harmful", () => {
  const start = lua.indexOf("local function translatedText(");
  const end = lua.indexOf("local function traitIconForMessage(", start);
  assert.ok(start >= 0 && end > start, "sleep trait helper block must exist");
  const helpers = lua.slice(start, end);
  const fixture = `
local LEVEL_UP_GREEN = { r = 0.35, g = 1, b = 0.48 }
local TRAIT_HARMFUL_RED = { r = 1, g = 0.38, b = 0.34 }
local translations = {
  UI_trait_LessSleep = "Insomne",
  UI_trait_MoreSleep = "Dormilón",
  UI_ChilaSeda_ViewpointHalo_LessSleep = "Menor necesidad de sueño (menos duración al dormir)",
  UI_ChilaSeda_ViewpointHalo_MoreSleep = "Mayor necesidad de sueño (más duración al dormir)",
}
function getText(key) return translations[key] or key end
${helpers}
local kind = sleepTraitKind("Insomne")
assert(kind == "lessSleep")
assert(sleepTraitKind("Wakeful") == "lessSleep")
assert(sleepTraitKind("Dormilón") == "moreSleep")
assert(sleepTraitKind("Sleepyhead") == "moreSleep")
assert(sleepTraitKind("Sueño inquieto") == nil)
local lessLabel, lessSource = sleepTraitDisplay("lessSleep")
assert(lessLabel == translations.UI_ChilaSeda_ViewpointHalo_LessSleep)
assert(lessSource == "translation")
local moreLabel = sleepTraitDisplay("moreSleep")
assert(moreLabel == translations.UI_ChilaSeda_ViewpointHalo_MoreSleep)
local up, color, effect = sleepTraitDelta("lessSleep", true)
assert(up == true and effect == "beneficial" and color.g == 1 and color.r < 0.5)
local down, color, effect = sleepTraitDelta("lessSleep", false)
assert(down == false and effect == "harmful" and color.r == 1 and color.g < 0.5)
local down, color, effect = sleepTraitDelta("moreSleep", true)
assert(down == false and effect == "harmful" and color.r == 1 and color.g < 0.5)
local up, color, effect = sleepTraitDelta("moreSleep", false)
assert(up == true and effect == "beneficial" and color.g == 1 and color.r < 0.5)
local white = { r = 1, g = 1, b = 1 }
local downColor, downSource = traitArrowColor(false, nil, white)
assert(downSource == "direction-default" and downColor == TRAIT_HARMFUL_RED,
  "unclassified downward trait arrows should use the harmful red")
local beneficialColor = { r = 0.35, g = 1, b = 0.48 }
local semanticColor, semanticSource = traitArrowColor(false, beneficialColor, white)
assert(semanticSource == "semantic" and semanticColor == beneficialColor,
  "explicit beneficial trait semantics should take precedence over the downward fallback")
local unchangedColor, unchangedSource = traitArrowColor(true, nil, white)
assert(unchangedSource == "input" and unchangedColor == white,
  "the downward fallback must leave unclassified upward arrows unchanged")
translations.UI_ChilaSeda_ViewpointHalo_LessSleep = nil
local fallback, labelSource = sleepTraitDisplay("lessSleep")
assert(fallback == "Needs less sleep (shorter sleep duration)")
assert(labelSource == "fallback")
`;

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-trait-halo-"));
  try {
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const harnessClasspath = `${gameJar};${tempDir}`;
    const compileResult = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", harnessClasspath, "TraitHaloSemanticsKahluaContract", luaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(compileResult, /Viewpoint Lua compiled/);
    const fixturePath = path.join(tempDir, "trait-halo-semantics.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", harnessClasspath, "TraitHaloSemanticsKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Trait Halo Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("Halo wraps sleep trait labels, directs arrows by benefit, and bounds diagnostics", () => {
  assert.match(lua, /local sleepKind = sleepTraitKind\(message\)/);
  assert.match(lua, /message, labelSource = sleepTraitDisplay\(sleepKind\)/);
  assert.match(lua, /arrow, semanticColor, effect = sleepTraitDelta\(sleepKind, inputArrow\)/);
  assert.match(lua, /traitSemanticDiagnostics\[diagnosticKey\]/);
  assert.match(lua, /label-source=/);
  assert.match(lua, /addNotification\(message, color, arrow, arrowColor, icon, traitStyle\)/);
});

test("generic downward trait arrows use red and keep diagnostics bounded", () => {
  assert.match(lua, /traitArrowColor\(pointsUp, semanticColor, inputColor\)/);
  assert.match(lua, /arrowColor, arrowColorSource = traitArrowColor\(arrow, semanticColor, arrowColor\)/);
  assert.match(lua, /if traitStyle and arrow ~= nil then/);
  assert.match(lua, /MAX_GENERIC_TRAIT_ARROW_TRACE_LINES = 12/);
  assert.match(lua, /print\(TAG \.\. "generic-trait-arrow name="/);
  assert.match(lua, /direction=down color=red source=direction-default/);
});

test("mod version and release notes describe the sleep trait Halo fix", () => {
  assert.match(modInfo, /^modversion=2\.0\.128$/m);
  assert.match(readme, /^# ChilaSeda Fix - Viewpoint Workshop Fixes \(B42\) 2\.0\.128$/m);
  assert.match(readme, /Menor necesidad de sueño|sleep duration/);
});
