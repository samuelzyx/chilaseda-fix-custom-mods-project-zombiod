import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const calibration = fs.readFileSync(
  path.join(modRoot, "42/media/lua/client/ChilaSeda_ViewpointNativeForageHeightCalibration.lua"),
  "utf8",
);

test("Ctrl+Shift+Delete toggles calibration from key start and key press events", () => {
  assert.match(calibration, /local function handleDeleteChordEvent\(key, source\)/);
  assert.match(calibration, /key ~= deleteKey then return end/);
  assert.match(calibration, /if control and shift and not shortcutWasDown then[\s\S]*?pcall\(toggleWindow\)/);
  assert.match(calibration, /Events\.OnKeyPressed\.Add\(function\(key\)[\s\S]*?handleDeleteChordEvent\(key, "OnKeyPressed"\)/);
  assert.match(calibration, /Events\.OnKeyStartPressed\.Add\(function\(key\)[\s\S]*?handleDeleteChordEvent\(key, "OnKeyStartPressed"\)/);
});

test("held-key polling remains available if Viewpoint consumes the Delete event", () => {
  assert.match(calibration, /local function shortcutDown\(\)[\s\S]*?control and shift and keyDown\(deleteKey\)/);
  assert.match(calibration, /Events\.OnTick\.Add\(function\(\) handleShortcut\("OnTick"\) end\)/);
  assert.match(calibration, /Events\.OnTickEvenPaused\.Add\(function\(\) handleShortcut\("OnTickEvenPaused"\) end\)/);
});
