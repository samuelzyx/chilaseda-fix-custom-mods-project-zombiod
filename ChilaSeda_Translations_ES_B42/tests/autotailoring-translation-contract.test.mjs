import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const modRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const catalogsRoot = path.join(modRoot, '42/media/lua/shared/Translate/ES');

const expectedKeys = {
  'ContextMenu.json': [
    'ContextMenu_AutoTailoring_Bandana',
    'ContextMenu_AutoTailoring_Sacks',
    'ContextMenu_AutoTailoring_Knitting',
    'ContextMenu_AutoTailoring_Belt',
  ],
  'IG_UI.json': [
    'IGUI_AutoTailoring_Stop_Materials',
    'IGUI_AutoTailoring_Stop_MaxLevel',
    'IGUI_AutoTailoring_Stop_Scrap',
    'IGUI_AutoTailoring_Stop_Lost',
  ],
  'Sandbox.json': [
    'Sandbox_AutoTailoring_AllowBandana',
    'Sandbox_AutoTailoring_AllowBandana_tooltip',
    'Sandbox_AutoTailoring_AllowSacks',
    'Sandbox_AutoTailoring_AllowSacks_tooltip',
    'Sandbox_AutoTailoring_AllowKnitting',
    'Sandbox_AutoTailoring_AllowKnitting_tooltip',
    'Sandbox_AutoTailoring_AllowBelt',
    'Sandbox_AutoTailoring_AllowBelt_tooltip',
    'Sandbox_AutoTailoring_ShowXP',
    'Sandbox_AutoTailoring_ShowXP_tooltip',
    'Sandbox_AutoTailoring_ShowLockedRecipes',
    'Sandbox_AutoTailoring_ShowLockedRecipes_tooltip',
  ],
  'Tooltip.json': [
    'Tooltip_AutoTailoring_Bandana',
    'Tooltip_AutoTailoring_Sacks',
    'Tooltip_AutoTailoring_Knitting',
    'Tooltip_AutoTailoring_Belt',
    'Tooltip_AutoTailoring_Needs',
    'Tooltip_AutoTailoring_TakeApart',
    'Tooltip_AutoTailoring_Known',
    'Tooltip_AutoTailoring_Surface',
    'Tooltip_AutoTailoring_SharpKnife',
    'Tooltip_AutoTailoring_HeavyThread',
    'Tooltip_AutoTailoring_CannotStart',
    'Tooltip_AutoTailoring_MissingKnowledge',
  ],
};

function findDuplicateKeys(text) {
  const seen = new Set();
  const duplicates = new Set();

  for (const match of text.matchAll(/^\s*"((?:[^"\\]|\\.)+)"\s*:/gm)) {
    const key = JSON.parse(`"${match[1]}"`);
    if (seen.has(key)) duplicates.add(key);
    seen.add(key);
  }

  return [...duplicates];
}

test('AutoTailoring B42.22 catalogs parse, contain all 32 translations, and have no duplicate keys', () => {
  let translatedCount = 0;

  for (const [file, keys] of Object.entries(expectedKeys)) {
    const filePath = path.join(catalogsRoot, file);
    const text = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '');
    const catalog = JSON.parse(text);

    assert.deepEqual(findDuplicateKeys(text), [], `${file} contains duplicate keys`);
    for (const key of keys) {
      assert.equal(typeof catalog[key], 'string', `${file} is missing ${key}`);
      assert.ok(catalog[key].trim(), `${file}:${key} is empty`);
      assert.ok(!/^UI_[A-Za-z0-9_]+$/.test(catalog[key]), `${file}:${key} is still a raw UI key`);
      translatedCount += 1;
    }
  }

  assert.equal(translatedCount, 32);
});

test('translation mod version and load order include AutoTailoring', () => {
  const modInfo = fs.readFileSync(path.join(modRoot, '42/mod.info'), 'utf8');

  assert.match(modInfo, /^modversion=1\.5\.8$/m);
  assert.match(modInfo, /^loadModAfter=.*(?:^|,)AutoTailoring(?:,|$)/m);
});
