import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const translateRoot = path.join(modRoot, "42/media/lua/shared/Translate/ES");
const manifest = JSON.parse(
  fs.readFileSync(path.join(modRoot, "tests/translation-catalogs-manifest.json"), "utf8"),
);
const catalogPath = catalog => path.join(translateRoot, `${catalog}.json`);

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

test("all audited translation catalogs parse and contain no duplicate keys", () => {
  for (const [catalog, keys] of Object.entries(manifest)) {
    const file = catalogPath(catalog);
    const text = fs.readFileSync(file, "utf8");
    assert.ok(!text.startsWith("\uFEFF"), `${catalog} must be UTF-8 without a BOM`);
    const values = JSON.parse(text);
    assert.deepEqual(duplicateKeys(text), [], `${catalog} has duplicate keys`);
    for (const key of keys) {
      assert.equal(typeof values[key], "string", `${catalog} is missing ${key}`);
      assert.ok(values[key].trim(), `${catalog}/${key} must not be empty`);
    }
  }
});

test("catalog coverage and corrected English labels are present", () => {
  const igUi = JSON.parse(fs.readFileSync(catalogPath("IG_UI"), "utf8"));
  const ui = JSON.parse(fs.readFileSync(catalogPath("UI"), "utf8"));
  const contextMenu = JSON.parse(fs.readFileSync(catalogPath("ContextMenu"), "utf8"));
  const language = JSON.parse(fs.readFileSync(catalogPath("language"), "utf8"));
  assert.equal(igUi.IGUI_SNT_DR_Yes, "Sí");
  assert.equal(igUi.IGUI_VehicleName86fordE150slide, "'86 Ford Econoline E-150 con puerta corrediza");
  assert.equal(ui.UI_equipment_options_clean_header, "Encabezado limpio");
  assert.equal(contextMenu.ContextMenu_MinimalDisplayBars_menu, "Menú");
  assert.equal(language.language_name, "Español");
});

test("Animal Remaster Canada goose egg has a Spanish ItemName entry", () => {
  const itemNames = JSON.parse(fs.readFileSync(catalogPath("ItemName"), "utf8"));
  assert.equal(itemNames["AMRBirds321.CanadaGooseEgg783"], "Huevo de ganso canadiense");
  assert.equal(
    Object.prototype.hasOwnProperty.call(itemNames, "ItemName_AMRBirds321.CanadaGooseEgg783"),
    false,
    "ItemName.json keys use the full type without the ItemName_ prefix",
  );
});

test("literal percent signs survive translation formatting", () => {
  const sandbox = JSON.parse(fs.readFileSync(catalogPath("Sandbox"), "utf8"));
  const igUi = JSON.parse(fs.readFileSync(catalogPath("IG_UI"), "utf8"));
  assert.match(sandbox.Sandbox_VMZ_VehiCond_tooltip, /100%%/);
  assert.match(sandbox.Sandbox_AnimalRemaster_RespectAnimalSpawnChance_tooltip, /5 %%/);
  assert.match(sandbox.Sandbox_AnimalRemaster_DomesticDuckChance, /%%/);
  for (const key of [
    "Sandbox_GydeTraitMags_SpawnHandy_tooltip",
    "Sandbox_UndeadSurvivor.StalkerChance",
    "Sandbox_UndeadSurvivor.NomadChance",
    "Sandbox_UndeadSurvivor.PrepperChance",
    "Sandbox_UndeadSurvivor.HeadhunterChance",
    "Sandbox_UndeadSurvivor.AmazonaChance",
  ]) {
    assert.ok(!sandbox[key].replace(/%%/g, "").includes("%"), `${key} must escape literal percent signs`);
  }
  for (const [key, value] of Object.entries(igUi)) {
    if (key.startsWith("IGUI_CheckAround_")) {
      assert.ok(!value.replace(/%%/g, "").includes("%"), `${key} must escape placeholders for Translator`);
    }
  }
  assert.match(igUi.IGUI_CheckAround_zombiesUpstairs1, /%%d %%s/);
});

test("cooking labels parse cleanly in Spanish and English without duplicate keys", () => {
  const expected = {
    IGUI_ChilaSeda_CookingRemainingShort: ["%d min restantes", "%d min remaining"],
    IGUI_ChilaSeda_BurningRemainingShort: ["%d min para quemarse", "%d min until burnt"],
    IGUI_ChilaSeda_CookingRemaining: ["Cocinando: %d min restantes", "Cooking: %d min remaining"],
    IGUI_ChilaSeda_CookingPaused: ["Pausado: %d min restantes", "Paused: %d min remaining"],
    IGUI_ChilaSeda_CookingReady: ["Listo para retirar", "Ready to take off heat"],
    IGUI_ChilaSeda_BurningRemaining: ["Quemándose: %d min para quemarse", "Burning: %d min until burnt"],
    IGUI_ChilaSeda_CookingBurnt: ["Quemado", "Burnt"],
  };
  for (const [language, index] of [["ES", 0], ["EN", 1]]) {
    const file = path.join(modRoot, `42/media/lua/shared/Translate/${language}/IG_UI.json`);
    const source = fs.readFileSync(file, "utf8");
    const catalog = JSON.parse(source);
    assert.deepEqual(duplicateKeys(source), [], `${language}/IG_UI.json has duplicate keys`);
    for (const [key, values] of Object.entries(expected)) {
      assert.equal(catalog[key], values[index], `${language}/${key}`);
    }
  }
});

test("translation mod version and order cover every audited source mod", () => {
  const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
  assert.match(modInfo, /^modversion=1\.5\.8$/m);
  const loadAfter = new Set(modInfo.match(/^loadModAfter=(.+)$/m)?.[1].split(",") ?? []);
  for (const id of [
    "isoContainers",
    "KI5campers",
    "HomemadeThings",
    "VoiceJillValentine",
    "MySpiffo",
    "MoatsB42",
    "MakeshiftRaft",
    "81deloreanDMC12",
    "Authentic Z - Current",
    "ExtendedVanillaWeapons",
    "92nissanGTR",
    "SentinelTurrets",
    "OldPoint",
    "Expanded_Belt_B42",
    "damnlib",
    "Lugli_Achievements",
    "MinimalDisplayBarsNutritionsB42",
    "EQUIPMENT_UI_B42",
    "XannyArmsGunPack",
    "LootTrackerB42",
    "SurvivorBriefing",
    "UndeadSuvivor",
  ]) {
    assert.ok(loadAfter.has(id), `translation mod must load after ${id}`);
  }
});
