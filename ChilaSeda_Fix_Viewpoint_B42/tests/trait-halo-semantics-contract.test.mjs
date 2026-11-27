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
const optionsLuaPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_ViewpointNativeFogOptions.lua",
);
const optionsLua = fs.readFileSync(
  optionsLuaPath,
  "utf8",
);
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
  const expected = {
    EN: {
      less: "You rest well while sleeping less",
      more: "Needs more sleep",
      xp: "Experience messages",
      xpTooltip: "Show or hide experience messages in Halo Notes.",
    },
    ES: {
      less: "Descansas bien durmiendo menos",
      more: "Necesitas dormir mas",
      xp: "Mensajes de experiencia",
      xpTooltip: "Muestra u oculta los mensajes de experiencia en Halo Notes.",
    },
    ES_MX: {
      less: "Descansas bien durmiendo menos",
      more: "Necesitas dormir mas",
      xp: "Mensajes de experiencia",
      xpTooltip: "Muestra u oculta los mensajes de experiencia en Halo Notes.",
    },
  };
  for (const locale of ["EN", "ES", "ES_MX"]) {
    const file = path.join(
      modRoot,
      `42/media/lua/shared/Translate/${locale}/UI.json`,
    );
    const source = fs.readFileSync(file, "utf8");
    assertNoDuplicateObjectKeys(source);
    const catalog = JSON.parse(source);
    assert.equal(catalog.UI_ChilaSeda_ViewpointHalo_LessSleep, expected[locale].less);
    assert.equal(catalog.UI_ChilaSeda_ViewpointHalo_MoreSleep, expected[locale].more);
    assert.equal(catalog.UI_ChilaSeda_ViewpointFix_HaloXPEnabled, expected[locale].xp);
    assert.equal(catalog.UI_ChilaSeda_ViewpointFix_HaloXPEnabledTooltip, expected[locale].xpTooltip);
  }
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
  UI_ChilaSeda_ViewpointHalo_LessSleep = "Necesitas dormir menos",
  UI_ChilaSeda_ViewpointHalo_MoreSleep = "Necesitas dormir mÃ¡s",
}
function getText(key) return translations[key] or key end
${helpers}
local kind = sleepTraitKind("Insomne")
assert(kind == "lessSleep")
assert(sleepTraitKind("Wakeful") == "lessSleep")
assert(sleepTraitKind("Dormilón") == "moreSleep")
assert(sleepTraitKind("Sleepyhead") == "moreSleep")
assert(sleepTraitKind("SueÃ±o inquieto") == nil)
local lessLabel, lessSource = sleepTraitDisplay("lessSleep", true)
assert(lessLabel == translations.UI_ChilaSeda_ViewpointHalo_LessSleep)
assert(lessSource == "translation")
local moreLabel, moreSource = sleepTraitDisplay("moreSleep", true)
assert(moreLabel == translations.UI_ChilaSeda_ViewpointHalo_MoreSleep)
assert(moreSource == "translation")
assert(sleepTraitDisplay("lessSleep", false) == translations.UI_ChilaSeda_ViewpointHalo_MoreSleep,
  "removing Insomne must report that Jill needs more sleep")
assert(sleepTraitDisplay("moreSleep", false) == translations.UI_ChilaSeda_ViewpointHalo_LessSleep,
  "removing DormilÃ³n must report that Jill needs less sleep")
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
local fallback, labelSource = sleepTraitDisplay("lessSleep", true)
assert(fallback == "Needs less sleep")
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
    const optionsCompileResult = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", harnessClasspath, "TraitHaloSemanticsKahluaContract", optionsLuaPath, "--compile-only"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(optionsCompileResult, /Viewpoint Lua compiled/);
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
  assert.match(lua, /message, labelSource, sleepNeed = sleepTraitDisplay\(sleepKind, arrow\)/);
  assert.match(lua, /arrow, semanticColor, effect = sleepTraitDelta\(sleepKind, inputArrow\)/);
  assert.match(lua, /traitSemanticDiagnostics\[diagnosticKey\]/);
  assert.match(lua, /label-source=/);
  assert.match(lua, /addNotification\(message, color, arrow, arrowColor, icon, traitStyle,/);
});

test("Halo Notes captures zombie speech with its original text color", () => {
  assert.match(lua, /local function isZombieCharacter\(character\)/);
  assert.match(lua, /pcall\(instanceof, character, "IsoZombie"\)/);
  assert.match(lua, /isLocalPlayer\(player\) or zombieCharacter/);
  assert.match(lua, /local color = colorSelector\(args\)/);
  assert.match(lua, /HaloTextHelper\.zombie\." \.\. tostring\(name\)/);
  assert.match(lua, /local priority = zombieCharacter and "transient" or "protected"/);
  assert.match(lua, /addNotification\(message, color, arrow, arrowColor, icon, traitStyle/);
});

test("Halo notice diagnostics include bounded source, RGB, and text", () => {
  const traceSource = section(
    lua,
    "local function traceNotice(event, entry)",
    "wrapText = function(text, maxChars)",
  );
  assert.match(traceSource, /MAX_NOTICE_TRACE_LINES/);
  assert.match(traceSource, /rgb=/);
  assert.match(traceSource, /component\(color\.r\).*component\(color\.g\).*component\(color\.b\)/s);
  assert.match(traceSource, /text=" \.\. text/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-halo-trace-"));
  try {
    const fixture = `
local TAG = "[HaloTrace] "
local noticeTraceCount = 0
local MAX_NOTICE_TRACE_LINES = 1
local notifications = {}
local printed = {}
print = function(message) printed[#printed + 1] = message end
${traceSource}
traceNotice("queued", { priority = "transient", source = "HaloTextHelper.zombie.addText",
  durationMs = 6000, text = "HEY!", color = { r = 0.25, g = 0.5, b = 1 } })
traceNotice("evicted", { priority = "transient", source = "second", durationMs = 6000,
  text = "must be bounded", color = { r = 1, g = 1, b = 1 } })
assert(#printed == 1, "notice trace must stop at its configured bound")
assert(printed[1]:find("source=HaloTextHelper.zombie.addText", 1, true), "trace must name the original helper")
assert(printed[1]:find("rgb=0.250,0.500,1.000 text=HEY!", 1, true), "trace must retain exact normalized RGB and text")
`;
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "halo-trace-contract.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "TraitHaloSemanticsKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Trait Halo Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("grouped notice traces stay available after the regular notice trace limit", () => {
  const traceSource = section(
    lua,
    "local function traceNotice(event, entry)",
    "wrapText = function(text, maxChars)",
  );
  const fixture = `
local TAG = "[HaloTrace] "
local noticeTraceCount = 0
local groupedNoticeTraceCount = 10
local MAX_NOTICE_TRACE_LINES = 1
local notifications = {}
local printed = {}
print = function(message) printed[#printed + 1] = message end
${traceSource}
local entry = { priority = "transient", source = "HaloTextHelper.addText",
  durationMs = 6000, text = "Soltado (x2)", color = { r = 1, g = 1, b = 1 } }
traceNotice("queued", entry)
traceNotice("queued", entry)
traceNotice("grouped", entry)
entry.text = "Soltado (x3)"
traceNotice("grouped", entry)
entry.text = "Soltado (x4)"
traceNotice("grouped", entry)
assert(#printed == 3, "grouped notices must have an independent bounded trace allowance")
assert(printed[1]:find("event=queued", 1, true), "the normal trace allowance must remain available")
assert(printed[2]:find("event=grouped", 1, true) and printed[2]:find("Soltado (x2)", 1, true),
  "group trace must report its event and repeat count")
assert(printed[3]:find("Soltado (x3)", 1, true), "group trace must stop at its own limit")
`;

  assert.match(traceSource, /groupedNoticeTraceCount >= 12/);
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-halo-group-trace-"));
  try {
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "halo-group-trace-contract.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "TraitHaloSemanticsKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Trait Halo Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
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
  assert.match(modInfo, /^modversion=2\.0\.159$/m);
  assert.match(readme, /^# ChilaSeda Fix - Viewpoint Workshop Fixes \(B42\) 2\.0\.159$/m);
  assert.match(readme, /Necesitas dormir menos|Needs less sleep/);
});

test("identical Halo notices group with a repeat count inside a sliding short window", () => {
  const queueSource = section(
    lua,
    "local function notificationLifetime(priority, requestedDurationMs)",
    "wrapText = function(text, maxChars)",
  );
  const fixture = `
local notifications = {}
local MAX_TRANSIENT_NOTIFICATIONS = 3
local DISPLAY_MS = 6000
local PROTECTED_DISPLAY_MS = 15000
local REPEAT_GROUP_WINDOW_MS = 750
local wrapText = function(text) return { text } end
${queueSource}

local first = { priority = "transient", source = "butchering", text = "Soltado: carne en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 1000, sequence = 1,
  durationMs = 6000, expiresAt = 7000 }
assert(enqueueNotification(first) == true)
local duplicate = { priority = "transient", source = "another-caller", text = "Soltado: carne en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 1400, sequence = 2,
  durationMs = 6000, expiresAt = 7400 }
local queued, evicted, grouped = enqueueNotification(duplicate)
assert(queued and evicted == nil and grouped == first)
assert(#notifications == 1 and first.repeatCount == 2
    and first.text == "Soltado: carne en el piso (x2)",
  "identical notices from different callers must render once with their repeat count")
assert(first.expiresAt == 7400, "a grouped notice must remain visible for the latest occurrence")

local third = { priority = "transient", text = "Soltado: carne en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 2100, sequence = 3,
  durationMs = 6000, expiresAt = 8100 }
local _, _, groupedThird = enqueueNotification(third)
assert(groupedThird == first and first.repeatCount == 3 and first.text:find("%(x3%)$"),
  "the grouping window must slide forward for a continuing burst")

local late = { priority = "transient", text = "Soltado: carne en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 2851, sequence = 4,
  durationMs = 6000, expiresAt = 8851 }
local queuedLate, _, groupedLate = enqueueNotification(late)
assert(queuedLate and groupedLate == nil and #notifications == 2,
  "an identical notice after 750 ms must start a separate entry")

local differentText = { priority = "transient", text = "Soltado: huesos en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 2900, sequence = 5,
  durationMs = 6000, expiresAt = 8900 }
local _, _, groupedText = enqueueNotification(differentText)
assert(groupedText == nil and #notifications == 3,
  "different item notices must not be merged")

local differentColor = { priority = "transient", text = "Soltado: carne en el piso",
  color = { r = 1, g = 0, b = 0 }, icons = {}, createdAt = 2901, sequence = 6,
  durationMs = 6000, expiresAt = 8901 }
local _, _, groupedColor = enqueueNotification(differentColor)
assert(groupedColor == nil,
  "visually different notices must keep separate queue entries")

local differentPriority = { priority = "protected", text = "Soltado: carne en el piso",
  color = { r = 1, g = 1, b = 1 }, icons = {}, createdAt = 2902, sequence = 7,
  durationMs = 15000, expiresAt = 17902 }
local _, _, groupedPriority = enqueueNotification(differentPriority)
assert(groupedPriority == nil,
  "protected and transient notices must keep separate queue entries")
`;

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-halo-repeat-"));
  try {
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "halo-repeat-contract.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "TraitHaloSemanticsKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Trait Halo Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("protected Halo notices stay above transient XP until their own expiry", () => {
  const queueSource = section(
    lua,
    "local function notificationLifetime(priority, requestedDurationMs)",
    "wrapText = function(text, maxChars)",
  );
  const fixture = `
local notifications = {}
local MAX_TRANSIENT_NOTIFICATIONS = 2
local DISPLAY_MS = 6000
local PROTECTED_DISPLAY_MS = 15000
local REPEAT_GROUP_WINDOW_MS = 750
local wrapText = function(text) return { text } end
${queueSource}

assert(notificationLifetime("transient") == 6000)
assert(notificationLifetime("protected") == 15000)
assert(notificationLifetime("protected", 20000) == 20000)

local weapon = { priority = "protected", source = "weapon", text = "Weapon dropped", createdAt = 0, sequence = 1,
  expiresAt = 15000 }
enqueueNotification(weapon)
local xp1 = { priority = "transient", source = "xp-1", text = "Carpentry +25", createdAt = 1, sequence = 2,
  expiresAt = 6001 }
local xp2 = { priority = "transient", source = "xp-2", text = "Cooking +25", createdAt = 2, sequence = 3,
  expiresAt = 6002 }
local xp3 = { priority = "transient", source = "xp-3", text = "Aiming +25", createdAt = 3, sequence = 4,
  expiresAt = 6003 }
enqueueNotification(xp1)
enqueueNotification(xp2)
enqueueNotification(xp3)
assert(#notifications == 3 and notifications[1] == weapon,
  "transient overflow must evict XP only and keep the weapon prompt on top")
assert(weapon.expiresAt == 15000 and xp1.expiresAt == 6001,
  "queue sorting and XP arrivals must not reset existing expiration times")

local level = { priority = "protected", source = "level", text = "Level up", createdAt = 4, sequence = 5,
  expiresAt = 15004 }
local trait = { priority = "protected", source = "trait", text = "Trait changed", createdAt = 5, sequence = 6,
  expiresAt = 15005 }
enqueueNotification(level)
enqueueNotification(trait)
assert(#notifications == 5 and notifications[1] == weapon
    and notifications[2] == level and notifications[3] == trait,
  "XP must not evict or cover protected level and trait notices")
assert(weapon.expiresAt == 15000 and level.expiresAt == 15004 and trait.expiresAt == 15005,
  "each protected notice must retain its own expiration time")

expireNotifications(6003)
assert(#notifications == 3 and notifications[1] == weapon and notifications[2] == level
    and notifications[3] == trait,
  "expired XP must be removed without deleting active protected notices")
expireNotifications(15000)
assert(#notifications == 2 and notifications[1] == level and notifications[2] == trait,
  "protected notices must expire independently at their own deadlines")
`;

  assert.match(lua, /MAX_TRANSIENT_NOTIFICATIONS = 3/);
  assert.match(lua, /PROTECTED_DISPLAY_MS = 15000/);
  assert.match(lua, /local noticePriority = priority == "protected" and "protected" or "transient"/);
  assert.match(lua, /priority = noticePriority/);
  assert.match(lua, /local priority = zombieCharacter and "transient" or "protected"/);
  assert.match(lua, /"protected", "LevelPerk"/);
  assert.match(lua, /source == "RuneExp" and ChilaSedaViewpointHaloXPEnabled == false/);
  assert.match(optionsLua, /HALO_XP_OPTION_ID = "haloXPEnabled"/);
  assert.match(optionsLua, /ChilaSedaViewpointHaloXPEnabled = haloXpEnabled/);
  assert.match(optionsLua, /addTickBox, page, HALO_XP_OPTION_ID/);
  assert.match(lua, /showProtected\(text, color, icon, durationMs, source\)/);
  assert.match(lua, /notice event=/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-halo-priority-"));
  try {
    const harness = path.join(modRoot, "tests/TraitHaloSemanticsKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "halo-priority-contract.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "TraitHaloSemanticsKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Trait Halo Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
