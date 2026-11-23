import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const itemPatch = fs.readFileSync(path.join(modRoot, "42/media/scripts/ExpandedBelt_items.txt"), "utf8");
const runtimeCheck = fs.readFileSync(
  path.join(modRoot, "42/media/lua/shared/ChilaSeda_ExpandedBeltCompat_B42.lua"),
  "utf8",
);

test("the compatibility addon depends on and loads after the Workshop belt", () => {
  assert.match(modInfo, /^id=ChilaSeda_Fix_ExpandedBelt_B42$/m);
  assert.match(modInfo, /^require=Expanded_Belt_B42$/m);
  assert.match(modInfo, /^loadModAfter=Expanded_Belt_B42$/m);
  assert.match(modInfo, /^versionMin=42\.22$/m);
});

test("the item patch preserves the current vanilla belt tags and research recipe", () => {
  assert.match(itemPatch, /module\s+ExpandedBelt\s*\{/);
  assert.match(itemPatch, /item\s+ExpandedBelt\s*\{/);
  assert.match(itemPatch, /Tags\s*=\s*base:hasmetal;base:buckle;base:scrapasbelt,/);
  assert.match(itemPatch, /Researchablerecipes\s*=\s*Forge_Buckle,/);
  assert.equal((itemPatch.match(/\{/g) ?? []).length, (itemPatch.match(/\}/g) ?? []).length);
});

test("the bounded runtime check verifies tags, recipe research and a named fallback", () => {
  assert.match(runtimeCheck, /ScriptManager\.instance:FindItem\(ITEM_TYPE\)/);
  assert.match(runtimeCheck, /ItemTag\.HAS_METAL/);
  assert.match(runtimeCheck, /ItemTag\.BUCKLE/);
  assert.match(runtimeCheck, /ItemTag\.SCRAP_AS_BELT/);
  assert.match(runtimeCheck, /Forge_Buckle/);
  assert.match(runtimeCheck, /result=ready/);
  assert.match(runtimeCheck, /result=fallback reason=/);
  assert.match(runtimeCheck, /Events\.OnGameBoot\.Add\(verifyExpandedBelt\)/);
});
