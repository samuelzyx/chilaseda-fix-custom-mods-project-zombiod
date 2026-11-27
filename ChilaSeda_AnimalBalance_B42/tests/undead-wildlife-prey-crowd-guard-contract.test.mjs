import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const localPath = path.join(modRoot, "42/media/lua/client/UndeadWildlife_PredationVisuals.lua");
const workshopRoot = "J:/SteamLibrary/steamapps/workshop/content/108600/3781571720/mods/UndeadWildlife/42";
const upstreamPath = path.join(workshopRoot, "media/lua/client/UndeadWildlife_PredationVisuals.lua");
const upstreamInfoPath = path.join(workshopRoot, "mod.info");
const local = fs.readFileSync(localPath, "utf8");
const upstream = fs.readFileSync(upstreamPath, "utf8");
const upstreamInfo = fs.readFileSync(upstreamInfoPath, "utf8");
const localInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
const pzRoot = "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const pzModOptions = fs.readFileSync(path.join(pzRoot, "media/lua/client/PZAPI/ModOptions.lua"), "utf8");
const pzMainOptions = fs.readFileSync(path.join(pzRoot, "media/lua/client/OptionScreens/MainOptions.lua"), "utf8");

function readUniqueCatalog(relativePath) {
  const text = fs.readFileSync(path.join(modRoot, "42/media/lua/shared/Translate", relativePath), "utf8");
  const parsed = JSON.parse(text);
  const counts = new Map();
  for (const match of text.matchAll(/"((?:\\.|[^"\\])*)"\s*:/g)) {
    const key = JSON.parse(`"${match[1]}"`);
    counts.set(key, (counts.get(key) || 0) + 1);
  }
  assert.deepEqual([...counts].filter(([, count]) => count > 1), [], `duplicate keys in ${relativePath}`);
  return parsed;
}

function section(source, start, end) {
  const from = source.indexOf(start);
  assert.notEqual(from, -1, `missing section start: ${start}`);
  const to = source.indexOf(end, from + start.length);
  assert.notEqual(to, -1, `missing section end: ${end}`);
  return source.slice(from, to);
}

test("local override stays pinned to installed Undead Wildlife 1.1.0", () => {
  const upstreamHash = crypto.createHash("sha256").update(upstream).digest("hex").toUpperCase();
  assert.equal(upstreamHash, "FFE22914D69558B192E23E87403EA45F00E4A2D4A26B0E99EDD69E40D208737B");
  assert.match(upstreamInfo, /id=UndeadWildlife/);
  assert.match(upstreamInfo, /modversion=1\.1\.0/);
  assert.match(localInfo, /loadModAfter=[^\r\n]*UndeadWildlife/);
  assert.match(localInfo, /modversion=2\.3\.8/);
  assert.notEqual(local, upstream, "local override must contain the crowd guard");
});

test("Build 42 Mod Options exposes and persists the three tuning controls", () => {
  assert.match(pzModOptions, /function Options:addSlider\(/);
  assert.match(pzModOptions, /function PZAPI\.ModOptions:create\(/);
  assert.match(pzModOptions, /function PZAPI\.ModOptions:load\(/);
  assert.match(pzModOptions, /function PZAPI\.ModOptions:save\(/);
  assert.match(pzMainOptions, /PZAPI\.ModOptions:load\(\)/);
  assert.match(pzMainOptions, /PZAPI\.ModOptions:save\(\)/);
  assert.match(local, /api:create\(SETTINGS_ID, "UI_ChilaSeda_AnimalBalance_PredationOptions"\)/);
  assert.match(local, /MaxHuntersPerAnimal[\s\S]*?minimum = 1, maximum = 20, default = 2/);
  assert.match(local, /StallTimeoutSeconds[\s\S]*?minimum = 5, maximum = 300, default = 20/);
  assert.match(local, /UnreachablePreySeconds[\s\S]*?minimum = 0, maximum = 600, default = 60/);
  assert.match(local, /Events\.OnGameStart\.Add\(loadSavedSettings\)/);
  assert.match(local, /pcall\(api\.load, api\)/);
  assert.match(local, /settingsGroup\.apply = function[\s\S]*?refreshSettings\("options-applied"\)/);
  assert.match(local, /math\.max\(setting\.minimum, math\.min\(setting\.maximum, math\.floor\(value \+ 0\.5\)\)\)/);
  assert.match(local, /stallTimeoutMs = readIntegerSetting\(SETTING_LIMITS\.stallTimeoutSeconds\) \* 1000/);
  assert.match(local, /unreachablePreyMs = readIntegerSetting\(SETTING_LIMITS\.unreachablePreySeconds\) \* 1000/);
  assert.match(local, /read result=fallback setting=/);
  assert.match(localInfo, /modversion=2\.3\.8/);
  assert.match(readme, /Opciones > Mods > Interaccion zombies vs animales/);
});

test("Spanish and English options catalogs parse and contain unique labels", () => {
  const keys = [
    "UI_ChilaSeda_AnimalBalance_PredationOptions",
    "UI_ChilaSeda_AnimalBalance_PredationDescription",
    "UI_ChilaSeda_AnimalBalance_MaxHunters",
    "UI_ChilaSeda_AnimalBalance_MaxHuntersTooltip",
    "UI_ChilaSeda_AnimalBalance_StallTimeout",
    "UI_ChilaSeda_AnimalBalance_StallTimeoutTooltip",
    "UI_ChilaSeda_AnimalBalance_UnreachablePrey",
    "UI_ChilaSeda_AnimalBalance_UnreachablePreyTooltip",
  ];
  for (const locale of ["EN/UI.json", "ES/UI.json", "ES_MX/UI.json"]) {
    const catalog = readUniqueCatalog(locale);
    for (const key of keys) assert.equal(typeof catalog[key], "string", `${locale}: ${key}`);
    const expectedCategory = locale === "EN/UI.json"
      ? "Zombie vs. Animal Interaction"
      : "Interaccion zombies vs animales";
    assert.equal(catalog.UI_ChilaSeda_AnimalBalance_PredationOptions, expectedCategory, locale);
    assert.match(catalog.UI_ChilaSeda_AnimalBalance_PredationDescription, /normal animal|animales normales/i);
  }
});

test("configured hunter limit caps claims made during each scan", () => {
  assert.match(local, /local activeSettings = \{/);
  const nearest = section(local, "local function findNearest(", "local function engage(");
  assert.match(nearest, /\(targetCounts\[animal\] or 0\) < activeSettings\.maxHuntersPerAnimal/);
  assert.match(nearest, /return nearest, capacityBlocked/);
  assert.match(nearest, /capacityBlocked = capacityBlocked \+ 1/);
  const scan = section(local, "local function scan()", "local function onTick()");
  assert.match(scan, /local targetCounts = countActiveTargets\(\)/);
  assert.match(scan, /targetCounts\[animal\] = \(targetCounts\[animal\] or 0\) \+ 1/);
  assert.match(scan, /capacityRejectedZombies = capacityRejectedZombies \+ 1/);
  assert.match(scan, /clearTarget\(zombie\)[\s\S]*?clearedAnimalTargets = clearedAnimalTargets \+ 1/);
  assert.match(scan, /maxHuntersPerAnimal=" \..*activeSettings\.maxHuntersPerAnimal/);
  const enforce = section(local, "local function enforceHunterLimit(", "local function scan()");
  assert.match(enforce, /#hunters > activeSettings\.maxHuntersPerAnimal/);
  assert.match(enforce, /release\(hunters\[index\]\.zombie, "capacity-reduced", STALL_COOLDOWN_MS\)/);
  assert.match(scan, /capacityReleasedZombies=" \..*capacityReleasedZombies/);
});

test("shoreline movement does not reset route-stall detection", () => {
  assert.match(local, /stallTimeoutSeconds = \{ id = "StallTimeoutSeconds", minimum = 5, maximum = 300, default = 20 \}/);
  assert.match(local, /local DISTANCE_PROGRESS_MIN = 0\.35/);
  const update = section(local, "local function updateZombie(", "local function countActiveTargets(");
  assert.match(update, /distance <= \(state\.bestDistance or distance\) - DISTANCE_PROGRESS_MIN/);
  assert.match(update, /now - \(state\.lastProgressAt or now\) >= activeSettings\.stallTimeoutMs/);
  assert.doesNotMatch(update, /lastMovedAt|movedX|movedY/);
  const collision = section(local, "local function onCollide(", "local function onZombieUpdate(");
  assert.match(collision, /state\.lastProgressAt = now/);
  assert.match(collision, /state\.bestDistance = zombie:DistTo\(animal\)/);
});

test("a stalled prey releases all hunters and resumes if it escapes", () => {
  assert.match(local, /unreachablePreySeconds = \{ id = "UnreachablePreySeconds", minimum = 0, maximum = 600, default = 60 \}/);
  const block = section(local, "local function blockUnreachablePrey(", "local function updateZombie(");
  assert.match(block, /blockedAnimals\[animal\] = \{[\s\S]*?blockedAt = now/);
  assert.match(block, /cooldownMs=" \..*activeSettings\.unreachablePreyMs/);
  assert.match(block, /if hunterState\.animal == animal then[\s\S]*?release\(hunter, "prey-route-stalled", STALL_COOLDOWN_MS\)/);
  const blocked = section(local, "local function isPreyTemporarilyBlocked(", "local function eligible(");
  assert.match(blocked, /now >= entry\.blockedAt \+ activeSettings\.unreachablePreyMs or moved/);
  assert.match(blocked, /dx \* dx \+ dy \* dy >= 4/);
  assert.match(local, /prey-temporarily-ignored/);
  assert.match(local, /prey-unblocked/);
});

test("diagnostic output remains gated by PredationDebug and bounded by scan summaries", () => {
  assert.match(local, /if UndeadWildlife\.getOption\("PredationDebug", false\) then[\s\S]*?print\("\[UndeadWildlife Predation Client\] " \..*?end/s);
  assert.match(local, /if settingsTraceLines >= 12 then return end/);
  assert.match(local, /scanReports >= 10/);
  assert.match(local, /route-stalled/);
  assert.match(local, /maxHuntersPerAnimal=/);
});
