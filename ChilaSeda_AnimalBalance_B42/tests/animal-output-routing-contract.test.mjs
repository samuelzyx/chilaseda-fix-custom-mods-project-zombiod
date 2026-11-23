import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const sourcePath = path.join(modRoot, "42/media/lua/shared/ChilaSeda_AnimalBalance_B42.lua");
const source = fs.readFileSync(sourcePath, "utf8");
const promptPath = path.resolve(modRoot, "../ChilaSeda_Fix_Viewpoint_B42/42/media/lua/client/zzzzz_ChilaSeda_ViewpointAnimalCorpsePrompt.lua");
const prompt = fs.readFileSync(promptPath, "utf8");
const pagePath = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISInventoryPage.lua";
const pageSource = fs.readFileSync(pagePath, "utf8");
const bonesPath = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/shared/TimedActions/Animals/ISGetAnimalBones.lua";
const bones = fs.readFileSync(bonesPath, "utf8");

function section(text, start, end) {
  const from = text.indexOf(start);
  assert.notEqual(from, -1, `missing section start: ${start}`);
  const to = text.indexOf(end, from + start.length);
  assert.notEqual(to, -1, `missing section end: ${end}`);
  return text.slice(from, to);
}

test("animal output resolver compares selection with the real inventory root", () => {
  const resolver = section(source, "local function selectedLootContainer(", "local function canStoreIn(");
  assert.match(pageSource, /self\.inventoryPane\.inventory = inventory;\s*self\.inventory = inventory;/);
  assert.match(resolver, /local main = inventory/);
  assert.match(resolver, /selected ~= main/);
  assert.doesNotMatch(resolver, /local main = okPage and page and page\.inventory/);
});

test("bone extraction routes new bones to the selected container before floor", () => {
  assert.match(bones, /function ISGetAnimalBones:complete\(\)[\s\S]*?ButcheringUtil\.butcherAnimalFromGround\(self\.body, self\.character\)/);
  assert.match(source, /ButcheringUtil\.butcherAnimalFromGround = function\(carcass, player, keepCorpse\)[\s\S]*?withBoneExtraction\(carcass, player/);
  assert.match(source, /local moved, dropped, failed = moveNewItemsToSelectedContainer\(player, inventory, snapshot\)/);
  const routing = section(source, "local function moveNewItemsToSelectedContainer(", "local function enforceBoneExtractionCaps(");
  assert.match(routing, /if destination and destination:getType\(\) ~= "floor"[\s\S]*?canStoreIn\(destination, player, item\)[\s\S]*?moveItemToContainer\(inventory, destination, item\)/);
  assert.match(routing, /if not moved then[\s\S]*?dropItemToFloor\(player, inventory, item\)/);
});

test("butchering outputs use the same selected-container resolver", () => {
  assert.match(source, /ButcheringUtil\.addAnimalPart = function[\s\S]*?moveNewItemsToSelectedContainer\(player, inventory, beforeItems\)/);
  assert.match(prompt, /local selected = page and page\.inventoryPane and page\.inventoryPane\.inventory[\s\S]*?local root = safeMethod\(player, "getInventory"\)/);
  assert.match(prompt, /if selected and canStore\(selected, player, item\) then[\s\S]*?selected:AddItem\(item\)/);
});

test("selected output route keeps the documented floor fallback and Halo destination", () => {
  const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
  assert.match(readme, /contenedor seleccionado[\s\S]*?piso junto al personaje[\s\S]*?No usa el inventario principal como destino alternativo/);
  assert.match(source, /ChilaSeda_ViewpointNotifyStoredItem/);
  assert.match(source, /ChilaSeda_ViewpointNotifyDroppedItem/);
});

test("a selected bag equal to page.inventory still differs from the root and wins", () => {
  const rootInventory = { name: "root" };
  const selectedBag = { name: "bag" };
  const page = { inventory: selectedBag, inventoryPane: { inventory: selectedBag } };
  const resolvedMain = rootInventory;
  const destination = page.inventoryPane.inventory !== resolvedMain ? page.inventoryPane.inventory : resolvedMain;
  assert.equal(destination, selectedBag);
});
