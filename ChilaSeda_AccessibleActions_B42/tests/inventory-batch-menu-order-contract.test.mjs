import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_InventoryContextMenuPolish.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");

test("batch dismantling follows Fabricar and preserves the remaining menu order", () => {
  assert.match(modInfo, /^modversion=1\.0\.43$/m);
  assert.match(readme, /^# ChilaSeda - Acciones Accesibles \(Build 42\) 1\.0\.43$/m);
  assert.match(lua, /ContextMenu_ShowCraftRecipesUsed/);
  assert.match(lua, /ContextMenu_DismantleAllAtOnce/);
  assert.match(lua, /MAX_BATCH_MENU_ORDER_TRACE_LINES = 12/);

  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "accessible-menu-order-"));
  try {
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);

    const fixture = String.raw`
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
local labels = {
  ContextMenu_ShowCraftRecipesUsed = "Fabricar",
  ContextMenu_DismantleAllAtOnce = "Procesar en lote",
}
getText = function(key) return labels[key] or key end
getTexture = function() return nil end
require = function() end
ISInventoryPaneContextMenu = {}
local inventoryCallback
Events = {
  OnFillInventoryObjectContextMenu = {
    Add = function(callback) inventoryCallback = callback end,
  },
  OnFillWorldObjectContextMenu = {
    Add = function(callback) end,
  },
}
` + lua + String.raw`
assert(type(inventoryCallback) == "function", "inventory polish callback must register")
local primary = { name = "Equipar primaria" }
local secondary = { name = "Equipar secundaria" }
local craft = { name = getText("ContextMenu_ShowCraftRecipesUsed") }
local delete = { name = "Eliminar 3 objetos" }
local batch = { name = getText("ContextMenu_DismantleAllAtOnce"), subOption = {} }
local context = { options = { primary, secondary, craft, delete, batch } }
inventoryCallback(0, context)
assert(context.options[1] == primary and context.options[2] == secondary)
assert(context.options[3] == craft and context.options[4] == batch)
assert(context.options[5] == delete, "unrelated menu option order must be preserved")
for index, option in ipairs(context.options) do
  assert(option.id == index, "menu option IDs must be refreshed")
end
assert(logs[1]:find("state=moved", 1, true), logs[1])

inventoryCallback(0, context)
assert(context.options[4] == batch, "the pair should stay adjacent on later menus")
assert(logs[#logs]:find("state=already-adjacent", 1, true), logs[#logs])

local noCraft = { options = { primary, secondary, delete, batch } }
inventoryCallback(0, noCraft)
assert(noCraft.options[3] == delete and noCraft.options[4] == batch,
  "without Fabricar, keep the original relative order")
for _ = 1, 20 do inventoryCallback(0, context) end
assert(#logs <= 12, "menu-order diagnostics must remain bounded")
`;
    const fixturePath = path.join(tempDir, "inventory-batch-menu-order.lua");
    fs.writeFileSync(fixturePath, fixture, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixturePath, "--execute"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
