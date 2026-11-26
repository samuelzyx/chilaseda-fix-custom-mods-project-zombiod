import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const workspace = path.resolve(import.meta.dirname, "../..");
const tetrisPath = path.join(import.meta.dirname, "../42/media/lua/client/ChilaSeda_InventoryTetrisSizeCap.lua");
const baitPath = path.join(workspace, "ChilaSeda_AccessibleActions_B42/42/media/lua/client/zzzz_ChilaSeda_TrapBaitMenuFilter.lua");
const translationsPath = path.join(workspace, "ChilaSeda_Translations_ES_B42/42/media/lua/shared/Translate/ES/ItemName.json");

test("overflow chooser cancellation closes the context menu", () => {
  const source = fs.readFileSync(tetrisPath, "utf8");
  assert.match(source, /menu:addOption\("Cancelar movimiento", menu, function\(contextMenu\)/);
  assert.match(source, /contextMenu:hideAndChildren\(\)/);
});

test("trap bait menu removes the unsupported LTP fat outputs only", () => {
  const source = fs.readFileSync(baitPath, "utf8");
  assert.match(source, /\["Base\.Fat"\] = true/);
  assert.match(source, /\["Base\.Tallow"\] = true/);
  assert.match(source, /\["Base\.Lard"\] = true/);
  assert.match(source, /\["Base\.Salt"\] = true/);
  assert.match(source, /option\.param2/);
  assert.match(source, /table\.remove\(menu\.options, index\)/);
  assert.match(source, /option\.name == addBaitLabel[\s\S]*?#submenu\.options == 0/);
  assert.match(source, /OnFillWorldObjectContextMenu\.Add/);
});

test("Spanish fat names parse and contain unique keys", () => {
  const raw = fs.readFileSync(translationsPath, "utf8");
  const data = JSON.parse(raw);
  const keys = [...raw.matchAll(/^\s*"([^"\\]+)"\s*:/gm)].map((match) => match[1]);
  assert.equal(new Set(keys).size, keys.length, "duplicate JSON keys");
  assert.equal(data["Base.Fat"], "Grasa animal");
  assert.equal(data["Base.Tallow"], "Sebo (grasa animal)");
});
