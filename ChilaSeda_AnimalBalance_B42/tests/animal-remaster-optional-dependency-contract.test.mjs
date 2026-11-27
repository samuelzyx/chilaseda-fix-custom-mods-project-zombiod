import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const info = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
const core = fs.readFileSync(path.join(modRoot, "42/media/lua/shared/ChilaSeda_AnimalBalance_B42.lua"), "utf8");

function field(name) {
  const match = info.match(new RegExp(`^${name}=(.*)$`, "m"));
  assert.ok(match, `missing mod.info field: ${name}`);
  return match[1].split(",").map((value) => value.trim()).filter(Boolean);
}

test("Animal Remaster is optional while required local dependencies remain", () => {
  const required = field("require");
  const orderedAfter = field("loadModAfter");

  assert.deepEqual(required, [
    "ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395",
    "ChilaSeda_AuditSuite_B42",
  ]);
  assert.ok(orderedAfter.includes("AnimalRemasterApproved"), "keep optional load order when RRAR is present");
  assert.equal(required.includes("AnimalRemasterApproved"), false, "RRAR must not be a hard requirement");
  assert.match(info, /^modversion=2\.3\.8$/m);
});

test("Animal Balance skips missing animal definitions and documents the optional integration", () => {
  assert.match(core, /local animals = AnimalDefinitions and AnimalDefinitions\.animals\s+if not animals then return end/);
  assert.doesNotMatch(core, /require\s*\(?\s*["']AnimalRemasterApproved/);
  assert.match(readme, /AnimalRemasterApproved` es opcional/);
  assert.match(readme, /no lo activa ni lo exige/);
});
