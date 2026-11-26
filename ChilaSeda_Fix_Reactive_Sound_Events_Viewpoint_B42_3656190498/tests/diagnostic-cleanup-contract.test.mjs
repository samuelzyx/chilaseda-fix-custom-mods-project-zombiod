import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const lua = fs.readFileSync(
  path.join(modRoot, "42/media/lua/client/ChilaSeda_ReactiveSoundViewpointFix.lua"),
  "utf8",
);
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("confirmed rotation fix no longer registers the temporary test marker or logs", () => {
  assert.match(lua, /function Marker:setAngleFromPoint\(\)/);
  assert.match(lua, /bridge\.angle/);
  assert.doesNotMatch(lua, /cycleTestMarker|testDirections|OnKeyPressed|KEY_F6|print\(/);
  assert.match(modInfo, /^modversion=1\.1\.4$/m);
  assert.doesNotMatch(modInfo, /Ctrl\+Shift\+F6/);
  assert.match(readme, /Version 1\.1\.4[\s\S]*Retira el marcador de prueba/);
  assert.match(readme, /Version 1\.1\.4[\s\S]*Retira el marcador de prueba/);
});
