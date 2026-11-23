import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const patch = fs.readFileSync(
  path.join(modRoot, "42/media/lua/client/ChilaSeda_SmartRadialNativeOptions_B42.lua"),
  "utf8",
);
const radialPath = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISRadialMenu.lua";
const radial = fs.readFileSync(radialPath, "utf8");

test("the selected Java radial index dispatches the Lua slice at the same index", () => {
  assert.match(radial, /getSliceIndexFromMouse\(x, y\)[\s\S]*?getSliceCommand\(sliceIndex \+ 1\)/);
  assert.match(radial, /function ISRadialMenu:setSliceText[\s\S]*?self\.javaObject:setSliceText\(sliceIndex - 1, text\)/);
  assert.match(radial, /function ISRadialMenu:setSliceTexture[\s\S]*?self\.javaObject:setSliceTexture\(sliceIndex - 1, texture\)/);
});

test("promoting Drink Smart updates the visible order and callback order together", () => {
  const promotion = patch.slice(
    patch.indexOf("if drinkSmartSlice and type(slices) == \"table\""),
    patch.indexOf("return result", patch.indexOf("if drinkSmartSlice and type(slices) == \"table\"")),
  );
  assert.match(promotion, /type\(self\.setSliceText\) == "function"/);
  assert.match(promotion, /type\(self\.setSliceTexture\) == "function"/);
  assert.match(promotion, /table\.insert\(slices, 1, table\.remove\(slices, #slices\)\)/);
  assert.match(promotion, /for index, slice in ipairs\(slices\) do[\s\S]*?self:setSliceText\(index, slice\.text\)[\s\S]*?self:setSliceTexture\(index, slice\.texture\)/);
});
