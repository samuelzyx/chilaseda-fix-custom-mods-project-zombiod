import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaFile = path.join(modRoot, "42/media/lua/client/ChilaSeda_InventoryTetrisNoPaneGuard.lua");
const lua = fs.readFileSync(luaFile, "utf8");

test("inventory UI fallback never calls the unsafe base getContainers helper", () => {
  const fallbackStart = lua.indexOf("local function fallbackContainers(");
  const installStart = lua.indexOf("local function install()", fallbackStart);
  assert.ok(fallbackStart >= 0 && installStart > fallbackStart, "fallback and install functions must exist");
  const fallback = lua.slice(fallbackStart, installStart);

  assert.doesNotMatch(lua, /baseGetContainers/);
  assert.match(fallback, /pcall\(character\.getInventory, character\)/);
  assert.match(fallback, /pcall\(selectedItem\.getContainer, selectedItem\)/);
  assert.match(fallback, /return result/);
});

test("the Tetris wrapper runs only after the inventory page is confirmed ready", () => {
  const installStart = lua.indexOf("local function install()");
  const install = lua.slice(installStart);
  assert.match(install, /if not inventoryPageReady\(character\) then\s*return fallbackContainers\(character, selectedItem, \.\.\.\)\s*end\s*local ok, result = pcall\(original/);
});
