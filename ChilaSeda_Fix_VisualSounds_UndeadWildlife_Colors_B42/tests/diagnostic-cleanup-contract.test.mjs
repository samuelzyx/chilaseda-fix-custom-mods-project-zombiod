import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const lua = fs.readFileSync(
  path.join(modRoot, "42/media/lua/client/ChilaSeda_VisualSoundsUndeadWildlifeColors.lua"),
  "utf8",
);
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("confirmed Viewpoint bridge omits success logs but preserves fallback diagnostics", () => {
  assert.match(lua, /SDI\.viewAngle = renderSafeViewAngle/);
  assert.match(lua, /SDI API unavailable; patch skipped/);
  assert.match(lua, /Viewpoint frame-angle bridge unavailable; using the isometric cue angle/);
  assert.doesNotMatch(lua, /SDI hooks loaded|angle replaced with Viewpoint frame yaw/);
  assert.match(modInfo, /^modversion=0\.8\.10$/m);
  assert.match(readme, /Version 0\.8\.10[\s\S]*Removes success-only startup messages/);
});
