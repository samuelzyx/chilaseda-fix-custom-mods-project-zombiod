import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const clientRoot = path.join(modRoot, "42/media/lua/client");
const craft = fs.readFileSync(path.join(clientRoot, "ChilaSeda_AccessibleCrafting_B42.lua"), "utf8");
const destinations = fs.readFileSync(path.join(clientRoot, "ChilaSeda_AccessibleCraftingDestinations.lua"), "utf8");
const ltp = fs.readFileSync(path.join(clientRoot, "ChilaSeda_LTPReduceAllFat_B42.lua"), "utf8");
const daao = fs.readFileSync(path.join(clientRoot, "ChilaSeda_DismantleAllAtOnceMenuOrder_B42.lua"), "utf8");
const trace = fs.readFileSync(path.join(clientRoot, "zzzz_ChilaSeda_AccessibleActionFlowTrace.lua"), "utf8");
const vanillaWidgetPath = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/Entity/ISUI/CraftRecipe/ISWidgetHandCraftControl.lua";
const vanillaWidget = fs.readFileSync(vanillaWidgetPath, "utf8");
const workshopDaaoPath = "J:/SteamLibrary/steamapps/workshop/content/108600/3761218629/mods/DismantleAllAtOnce/42/media/lua/client/DismantleAllAtOnce_ContextMenu.lua";
const workshopDaao = fs.readFileSync(workshopDaaoPath, "utf8");

function section(source, start, end) {
  const from = source.indexOf(start);
  assert.notEqual(from, -1, `missing section start: ${start}`);
  const to = source.indexOf(end, from + start.length);
  assert.notEqual(to, -1, `missing section end: ${end}`);
  return source.slice(from, to);
}

test("shared batch helper matches vanilla input transfer and craft lifecycle", () => {
  const helper = section(craft, "function M.queueHandcraftBatch(", "local function threadBatchLabel(");
  assert.match(vanillaWidget, /if not self\.logic:getRecipe\(\):isCanBeDoneFromFloor\(\) then[\s\S]*?transferIfNeeded\(self\.player, item\)/);
  assert.match(helper, /if not recipe:isCanBeDoneFromFloor\(\) then[\s\S]*?transferIfNeeded\(player, item\)/);
  assert.match(helper, /updateManualInputAllowedItemTypes\(\)/);
  assert.match(helper, /HandcraftStartMultiple,[\s\S]*?false, quantity, false/);
  assert.match(helper, /setOnStart\(function\(target, runningAction\)[\s\S]*?startCraftAction\(runningAction\)/);
  assert.match(helper, /setOnComplete\(function\(target\)[\s\S]*?stopCraftAction\(\)/);
  assert.match(helper, /setOnCancel\(function\(target\)[\s\S]*?stopCraftAction\(true\)/);
  assert.match(helper, /action\.chilaSedaAccessibleBatch = true/);
  assert.match(helper, /Fabricacion masiva no iniciada/);
  assert.match(helper, /ReturnItemsToOriginalContainer\(player, returnToContainer\)/);
  assert.match(vanillaWidget, /ReturnItemsToOriginalContainer\(self\.player, self\.returnToContainer\)/);
});

test("thread batch uses the lifecycle helper and finalizes outputs once", () => {
  const queueThread = section(craft, "local function queueThreadRecipe(", "local vanillaRecipeContext =");
  assert.match(queueThread, /M\.queueHandcraftBatch\(playerObj, logic, quantity, batch\)/);
  assert.match(craft, /if batch and isLastAction then finishRecipeBatch\(batch\) end/);
  assert.match(craft, /if not batch then[\s\S]*?finishRecipeBatch\(batch\)/);
});

test("secondary-bag wristwatch dismantling reuses the vanilla single-recipe callback", () => {
  const fallback = section(craft, "local function addMissingSecondaryWatchDismantle(", "if vanillaCreateInventoryContextMenu then");
  assert.match(fallback, /ISInventoryPaneContextMenu\.addNewCraftingDynamicalContextMenu/);
  assert.match(fallback, /DismantleElectronics/);
  assert.match(fallback, /getContainers\(playerObj, item\)/);
  assert.match(fallback, /if contextHasDismantleRecipe\(context, item, \{\}\) then return end/);
});

test("LTP reduce-all fat goes through the shared lifecycle", () => {
  const queueAll = section(ltp, "local function queueAll(", "local function setCookingPotIcon(");
  assert.match(queueAll, /isRottenReductionInput\(item\)/);
  assert.match(queueAll, /queueHandcraftBatch\(character, logic, quantity\)/);
  assert.doesNotMatch(queueAll, /HandcraftStartMultiple/);
});

test("DAAO bulk route transfers non-floor inputs and starts/stops its logic session", () => {
  assert.match(workshopDaao, /if not recipe:isCanBeDoneFromFloor\(\) then[\s\S]*?transferIfNeeded\(playerObj, item\)/);
  assert.match(workshopDaao, /setOnStart\(onDismantleAllStart, logic\)/);
  assert.match(workshopDaao, /onDismantleAllStart[\s\S]*?startCraftAction\(action\)/);
  assert.match(workshopDaao, /setOnComplete\(onDismantleAllComplete/);
  assert.match(workshopDaao, /target\.logic:stopCraftAction\(\)/);
  assert.match(daao, /if self\.chilaSedaFinishingCraft\s+then[\s\S]*?callback\(callbackTarget\)[\s\S]*?returnProducedItems\(context\)/);
  assert.match(daao, /action\.chilaSedaDismantleContext = context/);
  assert.match(daao, /dismantleContext\.handcraftStartCalled or dismantleContext\.creationFailure/);
  assert.match(daao, /Fabricacion masiva no iniciada/);
});

test("ordinary craft outputs remain routed after vanilla completes the recipe", () => {
  const complete = section(destinations, "function ISCraftAction:complete()", "local originalRepairComplete =");
  assert.match(complete, /originalCraftComplete\(self\)/);
  assert.match(complete, /routeCraftOutput\(playerObj, item\)/);
  assert.match(complete, /notifyOutputDestinations/);
});

test("every direct bulk start in the consolidated mod is guarded by a lifecycle path", () => {
  assert.match(craft, /pcall\(ISEntityUI\.HandcraftStartMultiple,[\s\S]*?false, quantity, false\)/);
  assert.doesNotMatch(craft, /ISEntityUI\.HandcraftStartMultiple\s*\(/,
    "other consolidated crafting entries must use the shared helper");
  assert.match(ltp, /queueHandcraftBatch\(character, logic, quantity\)/);
  assert.match(daao, /originalHandcraftStartMultiple\(player, logic, force, quantity, addToQueue\)/);
  assert.match(trace, /action\.chilaSedaAccessibleBatch or action\.chilaSedaDismantleContext/);
});
