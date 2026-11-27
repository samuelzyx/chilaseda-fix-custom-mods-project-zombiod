import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const catalogPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/IG_UI.json");
const catalogText = fs.readFileSync(catalogPath, "utf8");
const contextMenuPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/ContextMenu.json");
const contextMenuText = fs.readFileSync(contextMenuPath, "utf8");
const spanishUiPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/UI.json");
const spanishUiText = fs.readFileSync(spanishUiPath, "utf8");
const legacyUiPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/IG_UI_ES.txt");
const legacyUiText = fs.readFileSync(legacyUiPath, "utf8");
const legacyContextMenuPath = path.join(
  modRoot,
  "42/media/lua/shared/Translate/ES/ContextMenu_ES.txt",
);
const legacyContextMenuText = fs.readFileSync(legacyContextMenuPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const viewpointRoot = process.env.PZ_VIEWPOINT_ROOT
  ?? "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint";
const viewpointEnglishPath = path.join(
  viewpointRoot,
  "42/media/lua/shared/Translate/EN/IG_UI.json",
);

const translations = {
  IGUI_Viewpoint_AddJunk: "Marcar como basura",
  IGUI_Viewpoint_CancelAction: "Cancelar acción",
  IGUI_Viewpoint_Choose: "Elegir",
  IGUI_Viewpoint_Click: "Clic",
  IGUI_Viewpoint_CloseDetails: "Cerrar detalles",
  IGUI_Viewpoint_CtlAcross: "Transferir",
  IGUI_Viewpoint_CtlActions: "Acciones",
  IGUI_Viewpoint_CtlAdd: "Agregar a la selección",
  IGUI_Viewpoint_CtlEquip: "Equipar",
  IGUI_Viewpoint_CtlMove: "Mover",
  IGUI_Viewpoint_CtlSplit: "Dividir",
  IGUI_Viewpoint_CtlTitle: "Controles del mouse",
  IGUI_Viewpoint_CtlUse: "Usar",
  IGUI_Viewpoint_CtlWorn: "Siguiente prenda de la ranura",
  IGUI_Viewpoint_DoubleClick: "Doble clic",
  IGUI_Viewpoint_Drag: "Arrastrar",
  IGUI_Viewpoint_Equipment: "Equipo",
  IGUI_Viewpoint_Equipped: "Equipado",
  IGUI_Viewpoint_Filter: "Filtrar",
  IGUI_Viewpoint_FilterCount: "Filtrar (%1)",
  IGUI_Viewpoint_Fold: "Plegar",
  IGUI_Viewpoint_Hands: "Manos",
  IGUI_Viewpoint_Items: "%1 objetos",
  IGUI_Viewpoint_Junk: "Basura",
  IGUI_Viewpoint_KeyAlt: "Alt",
  IGUI_Viewpoint_KeyCtrl: "Ctrl",
  IGUI_Viewpoint_KeyShift: "Mayús",
  IGUI_Viewpoint_Locked: "Bloqueado",
  IGUI_Viewpoint_MoveFree: "libre: %1",
  IGUI_Viewpoint_OneItem: "1 objeto",
  IGUI_Viewpoint_Other: "Otro",
  IGUI_Viewpoint_PadAcross: "Transferir",
  IGUI_Viewpoint_PadActions: "Acciones",
  IGUI_Viewpoint_PadCancel: "Cancelar",
  IGUI_Viewpoint_PadClose: "Cerrar",
  IGUI_Viewpoint_PadOk: "Aceptar",
  IGUI_Viewpoint_PadReverse: "Invertir",
  IGUI_Viewpoint_PadSelect: "Seleccionar",
  IGUI_Viewpoint_PadShow: "Mostrar",
  IGUI_Viewpoint_PadTabs: "Pestañas",
  IGUI_Viewpoint_PadTakeOff: "Quitar",
  IGUI_Viewpoint_PadTick: "Marcar",
  IGUI_Viewpoint_RemoveJunk: "Quitar marca de basura",
  IGUI_Viewpoint_RightClick: "Clic derecho",
  IGUI_Viewpoint_Selected: "Seleccionados: %1; peso: %2",
  IGUI_Viewpoint_ShowEach: "Mostrar cada uno (%1)",
  IGUI_Viewpoint_SlotOther: "Otro",
  IGUI_Viewpoint_SlotPads: "Protectores",
  IGUI_Viewpoint_SplitAcross: "Dividir entre",
  IGUI_Viewpoint_StackAgain: "Volver a apilar",
  IGUI_Viewpoint_Unchoose: "Deseleccionar",
  IGUI_Viewpoint_Unfold: "Desplegar",
  IGUI_Viewpoint_Vicinity: "Alrededores",
  IGUI_Viewpoint_Wheel: "Rueda del ratón",
  IGUI_invpage_Loot_all: "Tomar todo",
};

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

test("all Viewpoint 0.1.7 native inventory labels are in the Spanish JSON catalog", () => {
  assert.ok(!catalogText.startsWith("\uFEFF"), "the JSON catalog must be UTF-8 without a BOM");
  assert.deepEqual(duplicateKeys(catalogText), [], "IG_UI.json must not have duplicate keys");
  const catalog = JSON.parse(catalogText);
  const viewpointEnglish = JSON.parse(fs.readFileSync(viewpointEnglishPath, "utf8"));
  const expectedViewpointKeys = Object.keys(translations)
    .filter((key) => key.startsWith("IGUI_Viewpoint_"))
    .sort();
  assert.deepEqual(Object.keys(viewpointEnglish).sort(), expectedViewpointKeys);
  for (const [key, value] of Object.entries(translations)) {
    assert.equal(catalog[key], value, `${key} must match its Spanish text`);
  }
  assert.doesNotMatch(expectedViewpointKeys.map((key) => catalog[key]).join(" "), /Cercan[ií]as|A[nñ]adir/);
});

test("native inventory actions use Mexican Spanish in current and legacy catalogs", () => {
  assert.deepEqual(duplicateKeys(contextMenuText), [], "ContextMenu.json must not have duplicate keys");
  const contextMenu = JSON.parse(contextMenuText);
  assert.equal(contextMenu.ContextMenu_Grab_all, "Tomar todo");
  assert.equal(contextMenu.ContextMenu_Wash, "Lavar");
  assert.deepEqual(duplicateKeys(spanishUiText), [], "UI.json must not have duplicate keys");
  const spanishUi = JSON.parse(spanishUiText);
  assert.equal(spanishUi.UI_ChilaSeda_WashBandages, "Lavar vendas");
  assert.equal(spanishUi.UI_ChilaSeda_WashNearbySource, "Lavar vendas (fuente de agua cercana)");
  assert.equal(spanishUi.UI_ChilaSeda_WashAccessibleContainers, "Lavar vendas (mochilas y contenedores accesibles)");
  assert.match(legacyUiText, /IGUI_Viewpoint_CtlAdd = "Agregar a la seleccion"/);
  assert.match(legacyUiText, /IGUI_Viewpoint_CtlTitle = "Controles del mouse"/);
  assert.match(legacyUiText, /IGUI_Viewpoint_Vicinity = "Alrededores"/);
  assert.match(legacyUiText, /IGUI_invpage_Loot_all = "Tomar todo"/);
  assert.match(legacyContextMenuText, /ContextMenu_Grab_all = "Tomar todo"/);
  assert.match(legacyContextMenuText, /ContextMenu_Wash = "Lavar"/);
});

test("translation mod loads after Viewpoint and carries the catalog revision", () => {
  assert.match(modInfo, /^modversion=1\.5\.8$/m);
  const loadAfter = new Set(modInfo.match(/^loadModAfter=(.+)$/m)?.[1].split(",") ?? []);
  assert.ok(loadAfter.has("Viewpoint"), "translations must load after Viewpoint");
});
