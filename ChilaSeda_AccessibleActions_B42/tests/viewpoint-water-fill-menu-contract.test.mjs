import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const washing = fs.readFileSync(
  path.join(modRoot, "42/media/lua/client/ChilaSeda_AccessibleWashing.lua"),
  "utf8",
);
const viewpointRoot = "J:/SteamLibrary/steamapps/workshop/content/108600/3809306528/mods/Viewpoint";
const viewpointInfo = fs.readFileSync(path.join(viewpointRoot, "common/mod.info"), "utf8");
const viewpointInteract = fs.readFileSync(
  path.join(viewpointRoot, "42/media/lua/client/Viewpoint_Interact.lua"),
  "utf8",
);
const vanillaContextMenu = fs.readFileSync(
  "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISWorldObjectContextMenu.lua",
  "utf8",
);

test("native Viewpoint menu receives fill-container actions during its menu event", () => {
  const registration = washing.indexOf("Events.OnFillWorldObjectContextMenu.Add(extendFillContainerSearch)");
  const definition = washing.indexOf("local function extendFillContainerSearch(");
  assert.ok(definition >= 0 && registration > definition);
  assert.match(washing, /local vanillaCreateMenu = ISWorldObjectContextMenu\.createMenu/);
  assert.match(washing, /extendFillContainerSearch\(playerNum, context, worldobjects, test\)/);
});

test("fill entries retain vanilla water callback and do not duplicate represented containers", () => {
  const extension = washing.slice(
    washing.indexOf("local function extendFillContainerSearch("),
    washing.indexOf("Events.OnFillWorldObjectContextMenu.Add(addWaterAndRainOptions)"),
  );
  assert.match(extension, /if not represented\[item\] then missing\[#missing \+ 1\] = item end/);
  assert.match(extension, /ISWorldObjectContextMenu\.onTakeWater, waterSource, missing, nil, playerNum/);
  assert.match(extension, /ISWorldObjectContextMenu\.onTakeWater, waterSource, nil, item, playerNum/);
});

test("fill scan covers accessible inventory-pane containers and vanilla fillable item types", () => {
  const fillability = washing.slice(
    washing.indexOf("local function isFillableWithWater("),
    washing.indexOf("local function collectFillableItems("),
  );
  assert.match(fillability, /getFluidContainer/);
  assert.match(fillability, /canStoreWater/);
  assert.match(fillability, /return true/);
  assert.match(vanillaContextMenu, /if item:canStoreWater\(\) and not item:isWaterSource\(\)/);
  assert.match(vanillaContextMenu, /elseif item:getFluidContainer\(\) then --Fluid item/);

  const collection = washing.slice(
    washing.indexOf("local function collectPlayerFillables("),
    washing.indexOf("local MAX_WASHABLE_ITEMS"),
  );
  assert.match(collection, /getAccessibleContainers\(playerObj\)/);
  assert.match(collection, /collectFillableItems\(safeCall\(accessible, "get", index\)/);
});

test("water-source Viewpoint menu offers vanilla self and clothing wash callbacks", () => {
  assert.match(washing, /require "TimedActions\/ISWashClothing"/);
  assert.match(washing, /require "TimedActions\/ISWashYourself"/);
  const extension = washing.slice(
    washing.indexOf("local function addVanillaWashOptions("),
    washing.indexOf("local function logWaterMenu("),
  );
  assert.match(extension, /getWashRequiredWater\(ISWashYourself, playerObj, "self"\)/);
  assert.match(extension, /getWashRequiredWater\(ISWashClothing, item, "clothing"\)/);
  assert.match(extension, /onWashYourself/);
  assert.match(extension, /onWashClothing/);
  assert.match(extension, /required <= waterAvailable/);
  assert.match(extension, /ContextMenu_Yourself/);
  assert.match(extension, /ContextMenu_WashClothing/);
  assert.match(extension, /ContextMenu_WashAllClothing/);
  assert.match(washing, /water-menu source=/);
  assert.match(washing, /waterMenuDiagnosticLogged/);
  assert.match(washing, /fillable=.*items=/);
  assert.match(washing, /dirtySelfParts=.*washableClothing=/);
  assert.match(washing, /clothing=\" \..*table\.concat\(clothingNames/);
  assert.match(washing, /MAX_WATER_MENU_DIAGNOSTICS = 32/);
  assert.match(washing, /skipped wash option action=/);
});

test("missing accessible-container API cannot abort water-source wash menu construction", () => {
  const accessor = washing.slice(
    washing.indexOf("local accessibleContainersDiagnosticLogged = false"),
    washing.indexOf("local function collectAccessibleItems("),
  );
  assert.match(accessor, /if type\(getContainers\) ~= "function" then/);
  assert.match(accessor, /pcall\(function\(\) return getContainers\(playerObj\) end\)/);
  assert.match(accessor, /skipped accessible-container scan reason=/);
});

test("Viewpoint menu tolerates inventory panes without optional refresh methods", () => {
  const safeCall = washing.slice(
    washing.indexOf("local function safeCall("),
    washing.indexOf("local function isFillableWithWater("),
  );
  assert.match(safeCall, /pcall\(function\(\) return object\[method\] end\)/);
  assert.match(safeCall, /type\(fn\) ~= "function"/);

  const extension = washing.slice(
    washing.indexOf("local function refreshInventoryPaneMethod("),
    washing.indexOf("local function extendFillContainerSearch("),
  );
  assert.match(extension, /if inventoryPaneRefreshWarnings\[method\] then return end/);
  assert.match(extension, /skipped inventory pane refresh method=/);
  assert.doesNotMatch(washing, /inventoryPane:updateMainListbox\(\)/);
});

test("installed Viewpoint 0.1.7 harvests leaf actions from nested native menus", () => {
  assert.match(viewpointInfo, /modversion=0\.1\.7/);
  assert.match(viewpointInteract, /if o\.subOption then[\s\S]*?collect\(sub, depth \+ 1,/);
});
