import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_InventoryTetrisFoodOrganizer.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
const translationsRoot = path.resolve(
  modRoot,
  "../ChilaSeda_Translations_ES_B42/42",
);
const translationModInfo = fs.readFileSync(path.join(translationsRoot, "mod.info"), "utf8");
const translationReadme = fs.readFileSync(
  path.resolve(modRoot, "../ChilaSeda_Translations_ES_B42/README.md"),
  "utf8",
);
const englishMenu = fs.readFileSync(
  path.join(modRoot, "42/media/lua/shared/Translate/EN/ContextMenu_EN.txt"),
  "utf8",
);
const spanishMenu = fs.readFileSync(
  path.join(translationsRoot, "media/lua/shared/Translate/ES/ContextMenu_ES.txt"),
  "utf8",
);
const englishUI = fs.readFileSync(
  path.join(modRoot, "42/media/lua/shared/Translate/EN/UI_EN.txt"),
  "utf8",
);
const spanishUI = fs.readFileSync(
  path.join(translationsRoot, "media/lua/shared/Translate/ES/UI_ES.txt"),
  "utf8",
);

test("freshness and calorie sorting are transactional and reported through Halo Notes", () => {
  assert.ok(fs.existsSync(luaPath), "food organizer Lua was not found");
  const gameRoot = process.env.PZ_GAME_ROOT
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join(gameRoot, "projectzomboid.jar");
  assert.ok(fs.existsSync(gameJar), "Project Zomboid Java archive was not found: " + gameJar);
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "tetris-food-sort-"));
  try {
    const harness = path.join(modRoot, "tests/OverflowFloorDropKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const classpath = gameJar + ";" + tempDir;
    const fixture = String.raw`
local logs = {}
local notes = {}
local activeContainerGrid
function print(message) logs[#logs + 1] = tostring(message) end
local function event()
    local result = {}
    function result.Add(callback) result.callback = callback end
    return result
end
Events = {
    OnFillInventoryObjectContextMenu = event(),
    OnGameBoot = event(),
    OnGameStart = event(),
}
local forceMissingTranslations = false
local translated = {
    ContextMenu_Equip_Primary = "Equip Primary",
    ContextMenu_Equip_Secondary = "Equip Secondary",
    ContextMenu_ChilaSeda_InventoryTetris_OrganizeFood = "Organize food",
    ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness = "By freshness",
    ContextMenu_ChilaSeda_InventoryTetris_FoodCalories = "By calories",
    UI_ChilaSeda_InventoryTetris_FoodSortSuccessFreshness = "Organized by freshness: %1 food items.",
    UI_ChilaSeda_InventoryTetris_FoodSortSuccessCalories = "Organized by calories: %1 food items.",
    UI_ChilaSeda_InventoryTetris_FoodSortNoSpace = "No changes: no space.",
    UI_ChilaSeda_InventoryTetris_FoodSortOverflow = "No changes: overflow food.",
    UI_ChilaSeda_InventoryTetris_FoodSortGravity = "No changes: gravity.",
    UI_ChilaSeda_InventoryTetris_FoodSortNoFoods = "No food.",
    UI_ChilaSeda_InventoryTetris_FoodSortUnavailable = "No changes: unavailable.",
    UI_ChilaSeda_InventoryTetris_FoodSortFailed = "No changes: failed.",
    UI_ChilaSeda_InventoryTetris_FoodSortReview = "Review the grid.",
}
function getText(key, count)
    local value = forceMissingTranslations and key or (translated[key] or key)
    if count then value = string.gsub(value, "%%1", tostring(count)) end
    return value
end
local player = { Say = function(self, message) notes[#notes + 1] = message end }
function getSpecificPlayer() return player end
HaloTextHelper = {
    addText = function(playerObj, message, spacer, red, green, blue)
        notes[#notes + 1] = message
    end,
}
ISInventoryPane = { getActualItems = function(items) return items end }
local function makeOption(text, target, onSelect, params)
    return { text = text, name = text, target = target, onSelect = onSelect, params = params }
end
local function makeContext(includeEquip)
    local context = { options = {} }
    if includeEquip then
        context.options[1] = { text = "Equip Primary", name = "Equip Primary" }
        context.options[2] = { text = "Equip Secondary", name = "Equip Secondary" }
    end
    function context:addOption(text, target, onSelect, ...)
        local params = { ... }
        local option = makeOption(text, target, onSelect, params)
        self.options[#self.options + 1] = option
        return option
    end
    function context:insertOptionAfter(anchor, text, target, onSelect, ...)
        local params = { ... }
        for index, current in ipairs(self.options) do
            if current.text == anchor then
                local option = makeOption(text, target, onSelect, params)
                table.insert(self.options, index + 1, option)
                return option
            end
        end
        return nil
    end
    function context:getNew(parentMenu) return makeContext(false) end
    function context:addSubMenu(option, submenu) option.submenu = submenu end
    return context
end
local ItemStack = {}
function ItemStack.create(x, y, isRotated, fullType, category)
    return {
        itemIDs = {},
        count = 0,
        x = x,
        y = y,
        isRotated = isRotated,
        itemType = fullType,
        category = category,
    }
end
function ItemStack.addItem(stack, item)
    if not stack.itemIDs[item:getID()] then
        stack.itemIDs[item:getID()] = true
        stack.count = stack.count + 1
    end
end
function ItemStack.removeItem(stack, item)
    if stack.itemIDs[item:getID()] then
        stack.itemIDs[item:getID()] = nil
        stack.count = stack.count - 1
    end
end
function ItemStack.getAllItems(stack, inventory)
    local result = {}
    for id in pairs(stack.itemIDs) do
        local item = inventory:getItemWithID(id)
        if item then result[#result + 1] = item end
    end
    return result
end
function ItemStack.getFrontItem(stack, inventory)
    for id in pairs(stack.itemIDs) do
        return inventory:getItemWithID(id)
    end
end
function ItemStack.canAddItem(stack, item)
    return stack.itemType == item:getFullType() and stack.count < 100
end
function ItemStack.copyWithoutItems(stack)
    return ItemStack.create(stack.x, stack.y, stack.isRotated, stack.itemType, stack.category)
end
local TetrisItemData = {
    getItemSize = function(item, rotated)
        if rotated then return item.gridH or 1, item.gridW or 1 end
        return item.gridW or 1, item.gridH or 1
    end,
    getMaxStackSize = function(item) return 100 end,
}
local TetrisItemCategory = { getCategory = function(item) return "FOOD" end }
local ItemGrid = { gatherSameItems = function() end }
local ItemContainerGrid = {
    FindInstance = function(inventory, playerNum)
        if activeContainerGrid and activeContainerGrid.inventory == inventory then
            return activeContainerGrid
        end
        return nil
    end,
}
local modules = {
    ["InventoryTetris/Model/ItemStack"] = ItemStack,
    ["InventoryTetris/Data/TetrisItemData"] = TetrisItemData,
    ["InventoryTetris/Data/TetrisItemCategory"] = TetrisItemCategory,
    ["InventoryTetris/Model/ItemContainerGrid"] = ItemContainerGrid,
    ["InventoryTetris/Model/ItemGrid"] = ItemGrid,
}
function require(name) return modules[name] or true end
SandboxVars = { InventoryTetris = { EnableGravity = false } }
instanceof = function(item, className)
    return className == "Food" and item ~= nil and item.vanillaFood == true
end
local function makeFood(id, fullType, age, freshness, calories)
    local item = { id = id, fullType = fullType, vanillaFood = true }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:isFood() return true end
    function item:isBurnt() return freshness == 4 and fullType == "Base.BurntMeat" end
    function item:isRotten() return freshness == 1 end
    function item:isFresh() return freshness == 3 end
    function item:canAge() return freshness ~= 4 end
    function item:getAge() return age end
    function item:getCalories() return calories end
    function item:getContainer() return self.container end
    return item
end
local function makeNonFood(id, fullType)
    local item = { id = id, fullType = fullType }
    function item:getID() return self.id end
    function item:getFullType() return self.fullType end
    function item:getContainer() return self.container end
    return item
end
local function makeContainer(items, width, height, stacks, overflow)
    local inventory = { items = items, itemById = {} }
    for _, item in ipairs(items) do
        item.container = inventory
        inventory.itemById[item.id] = item
    end
    function inventory:getItemWithID(id) return self.itemById[id] end
    function inventory:getItems()
        local list = { values = self.items }
        function list:size() return #self.values end
        function list:get(index) return self.values[index + 1] end
        return list
    end
    local grid = {
        inventory = inventory,
        width = width,
        height = height,
        persistentData = { stacks = stacks },
        rebuilds = 0,
        syncs = 0,
    }
    function grid:_rebuildStackMap(doPhysics) self.rebuilds = self.rebuilds + 1 end
    function grid:_sendModData() self.syncs = self.syncs + 1 end
    local containerGrid = { inventory = inventory, grids = { grid }, overflow = overflow or {} }
    activeContainerGrid = containerGrid
    return inventory, grid, containerGrid
end
local function stackAt(item, x, y)
    local stack = ItemStack.create(x, y, false, item:getFullType(), "FOOD")
    ItemStack.addItem(stack, item)
    return stack
end
local function stackWith(items, x, y)
    local stack = ItemStack.create(x, y, false, items[1]:getFullType(), "FOOD")
    for _, item in ipairs(items) do ItemStack.addItem(stack, item) end
    return stack
end
local function choose(context, optionIndex)
    local option = context.options[3].submenu.options[optionIndex]
    local params = option.params
    option.onSelect(option.target, params[1], params[2], params[3])
end
`;
    const scenario = String.raw`
assert(type(Events.OnFillInventoryObjectContextMenu.callback) == "function", "context hook installed")
local rotten = makeFood(11, "Base.Apple", 20, 1, 50)
local stale = makeFood(12, "Base.Apple", 12, 2, 50)
local freshNew = makeFood(13, "Base.Apple", 4, 3, 50)
local freshOld = makeFood(14, "Base.Apple", 8, 3, 50)
local burnt = makeFood(15, "Base.BurntMeat", 2, 4, 280)
local bottle = makeNonFood(19, "Base.WaterBottleFull")
local mixedFreshnessStack = stackWith({ rotten, stale, freshNew, freshOld }, 2, 1)
local burntStack = stackAt(burnt, 2, 2)
local bottleStack = stackAt(bottle, 1, 0)
local inventory, grid = makeContainer(
    { rotten, stale, freshNew, freshOld, burnt, bottle },
    5,
    3,
    { mixedFreshnessStack, burntStack, bottleStack }
)
local context = makeContext(true)
Events.OnFillInventoryObjectContextMenu.callback(0, context, { rotten })
assert(context.options[3].text == "Organize food", "root menu is inserted after Equip Secondary")
assert(context.options[3].submenu.options[1].text == "By freshness", "freshness submenu option")
choose(context, 1)
assert(grid.persistentData.stacks[1].chilaFoodOrganizerRank == 1, "rotten food is first")
local staleSorted
local freshSorted
local burntSorted
for _, stack in ipairs(grid.persistentData.stacks) do
    if stack.chilaFoodOrganizerRank == 2 then staleSorted = stack end
    if stack.chilaFoodOrganizerRank == 3 then freshSorted = stack end
    if stack.chilaFoodOrganizerRank == 4 then burntSorted = stack end
end
assert(staleSorted ~= nil and staleSorted.x == 2, "stale food follows the fixed non-food slot")
assert(freshSorted ~= nil, "fresh group exists")
assert(burntSorted ~= nil and burntSorted.x == 4, "burnt food is last")
assert(grid.persistentData.stacks[1] ~= staleSorted and staleSorted ~= freshSorted,
    "different freshness states split one original same-type stack")
assert(ItemStack.getFrontItem(freshSorted, inventory):getID() == 14, "oldest fresh item is at the front")
local keptBottle
for _, stack in ipairs(grid.persistentData.stacks) do
    if stack == bottleStack then keptBottle = stack end
end
assert(keptBottle == bottleStack and bottleStack.x == 1 and bottleStack.y == 0, "non-food position is preserved")
assert(notes[#notes] == "Organized by freshness: 5 food items.", "success Halo Note reports mode and count")

local meatOld = makeFood(21, "Base.Meat", 9, 3, 300)
local meatNew = makeFood(22, "Base.Meat", 3, 3, 300)
local meatLowerCalories = makeFood(23, "Base.Meat", 2, 3, 120)
local apple = makeFood(24, "Base.Apple", 1, 3, 50)
local meatStack = stackWith({ meatNew, meatOld }, 2, 0)
local lowerCaloriesStack = stackAt(meatLowerCalories, 3, 0)
local appleStack = stackAt(apple, 0, 1)
local calorieInventory, calorieGrid = makeContainer(
    { meatOld, meatNew, meatLowerCalories, apple },
    4,
    2,
    { meatStack, lowerCaloriesStack, appleStack }
)
local calorieContext = makeContext(true)
Events.OnFillInventoryObjectContextMenu.callback(0, calorieContext, { apple })
choose(calorieContext, 2)
assert(calorieGrid.persistentData.stacks[1].itemType == "Base.Meat", "highest-calorie food group is first")
assert(ItemStack.getFrontItem(calorieGrid.persistentData.stacks[1], calorieInventory):getID() == 21,
    "older item breaks an equal-calorie tie")
assert(calorieGrid.persistentData.stacks[2].itemType == "Base.Meat"
    and ItemStack.getFrontItem(calorieGrid.persistentData.stacks[2], calorieInventory):getID() == 23,
    "same-type meat with a different calorie value gets a separate, lower stack")
assert(calorieGrid.persistentData.stacks[1] ~= calorieGrid.persistentData.stacks[2],
    "different calorie values do not remain in the same stack")
assert(ItemStack.getFrontItem(calorieGrid.persistentData.stacks[3], calorieInventory):getID() == 24,
    "lower-calorie food groups follow higher-calorie groups")
assert(notes[#notes] == "Organized by calories: 4 food items.", "calorie success Halo Note is shown")
local function findSortTrace(prefix)
    for index = 1, #logs do
        local line = logs[index]
        if string.sub(line, 1, #prefix) == prefix then return line end
    end
end
local calorieTraceBase = "[ChilaSeda_InventoryTetrisFoodOrganizer] sort_trace event="
assert(findSortTrace(calorieTraceBase .. "begin mode=calories"), "calorie sort start is traced")
assert(findSortTrace(calorieTraceBase .. "plan_end mode=calories result=ready"), "calorie plan is traced")
assert(findSortTrace(calorieTraceBase .. "commit_begin mode=calories"), "calorie commit start is traced")
local plannedLayout = findSortTrace(calorieTraceBase .. "layout phase=planned mode=calories grid=1")
local beforeLayout = findSortTrace(calorieTraceBase .. "layout phase=before mode=calories grid=1")
assert(plannedLayout and string.sub(plannedLayout, -#"Base.Apple@2,0,rot=false,count=1{24:Base.Apple:cal=50}")
    == "Base.Apple@2,0,rot=false,count=1{24:Base.Apple:cal=50}",
    "planned calorie layout traces item IDs, calorie values, and positions")
assert(beforeLayout and string.sub(beforeLayout, -#"Base.Apple@0,1,rot=false,count=1{24:Base.Apple:cal=50}")
    == "Base.Apple@0,1,rot=false,count=1{24:Base.Apple:cal=50}",
    "original calorie layout is traced before the commit")

local splitRotten = makeFood(31, "Base.Apple", 20, 1, 50)
local splitFresh = makeFood(32, "Base.Apple", 2, 3, 50)
local crowdedStack = stackWith({ splitRotten, splitFresh }, 1, 0)
local fixedA = makeNonFood(39, "Base.WaterBottleFull")
local fixedStack = stackAt(fixedA, 0, 0)
local crowdedInventory, crowdedGrid = makeContainer(
    { splitRotten, splitFresh, fixedA },
    2,
    1,
    { fixedStack, crowdedStack }
)
local originalStackArray = crowdedGrid.persistentData.stacks
local crowdedContext = makeContext(true)
Events.OnFillInventoryObjectContextMenu.callback(0, crowdedContext, { splitRotten })
choose(crowdedContext, 1)
assert(crowdedGrid.persistentData.stacks == originalStackArray, "no-space abort keeps the original stack array")
assert(crowdedGrid.persistentData.stacks[2] == crowdedStack and crowdedStack.x == 1,
    "no-space abort keeps food in place")
assert(crowdedStack.chilaFoodOrganizerMode == nil, "no-space abort makes no partial stack changes")
assert(notes[#notes] == "No changes: no space.", "failure Halo Note explains the no-space result")

local overflowGridFood = makeFood(41, "Base.Potato", 7, 2, 120)
local inGridFood = makeFood(42, "Base.Carrot", 2, 3, 25)
local inGridStack = stackAt(inGridFood, 0, 0)
local overflowStack = stackAt(overflowGridFood, 2, 0)
local overflowInventory, overflowItemGrid = makeContainer(
    { overflowGridFood, inGridFood },
    4,
    2,
    { inGridStack },
    { overflowStack }
)
local overflowArray = overflowItemGrid.persistentData.stacks
local overflowContext = makeContext(true)
Events.OnFillInventoryObjectContextMenu.callback(0, overflowContext, { inGridFood })
choose(overflowContext, 1)
assert(overflowItemGrid.persistentData.stacks == overflowArray
    and overflowItemGrid.persistentData.stacks[1] == inGridStack, "overflow abort leaves stacks unchanged")
assert(notes[#notes] == "No changes: overflow food.", "overflow failure Halo Note is shown")

forceMissingTranslations = true
local fallbackFood = makeFood(51, "Base.Potato", 4, 3, 120)
local unknownModItem = makeNonFood(52, "Example.ModFoodContainer")
function unknownModItem:getFood() return { foodProxy = true } end
local fallbackFoodStack = stackAt(fallbackFood, 0, 0)
local unknownStack = stackAt(unknownModItem, 1, 0)
local fallbackInventory, fallbackGrid = makeContainer(
    { fallbackFood, unknownModItem },
    2,
    1,
    { fallbackFoodStack, unknownStack }
)
local fallbackContext = makeContext(true)
Events.OnFillInventoryObjectContextMenu.callback(0, fallbackContext, { fallbackFood })
assert(fallbackContext.options[3].text == "Organizar alimentos", "missing root label uses readable fallback")
assert(fallbackContext.options[3].submenu.options[1].text == "Por frescura", "missing submenu label uses readable fallback")
choose(fallbackContext, 1)
assert(fallbackGrid.persistentData.stacks[1].x == fallbackFoodStack.x
    and fallbackGrid.persistentData.stacks[1].y == fallbackFoodStack.y,
    "vanilla instanceof false keeps an unrecognized mod item fixed without aborting: " .. table.concat(logs, " | "))
assert(fallbackGrid.persistentData.stacks[2].x == unknownStack.x
    and fallbackGrid.persistentData.stacks[2].y == unknownStack.y,
    "unrecognized mod item keeps its original grid position: " .. table.concat(logs, " | "))
assert(notes[#notes] == "Organizados por frescura: 1 alimentos.",
    "missing UI translation uses readable fallback instead of exposing its key")
for _ = 1, 80 do choose(calorieContext, 2) end
local sortTracePrefix = "[ChilaSeda_InventoryTetrisFoodOrganizer] sort_trace event="
local sortTraceLimitPrefix = sortTracePrefix .. "limit "
local sortTraceCount = 0
local sortTraceLimitCount = 0
for index = 1, #logs do
    local line = logs[index]
    if string.sub(line, 1, #sortTracePrefix) == sortTracePrefix
        and string.sub(line, 1, #sortTraceLimitPrefix) ~= sortTraceLimitPrefix then
        sortTraceCount = sortTraceCount + 1
    end
    if string.sub(line, 1, #sortTraceLimitPrefix) == sortTraceLimitPrefix then
        sortTraceLimitCount = sortTraceLimitCount + 1
    end
end
assert(sortTraceCount == 96, "sort layout diagnostics are capped at 96 records per session; got " .. tostring(sortTraceCount))
assert(sortTraceLimitCount == 1, "sort layout trace limit is reported once; got " .. tostring(sortTraceLimitCount))
`;
    const fixturePath = path.join(tempDir, "food-organizer-contract.lua");
    assert.match(lua, /local ORGANIZER_ENABLED = true/);
    const luaFixture = lua;
    fs.writeFileSync(fixturePath, fixture + luaFixture + "\n" + scenario, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", classpath, "OverflowFloorDropKahluaContract", fixturePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Inventory Tetris overflow Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("food organizer can be explicitly disabled without installing hooks", () => {
  assert.match(lua, /local ORGANIZER_ENABLED = true/);
  const disabledLua = lua.replace(
    "local ORGANIZER_ENABLED = true",
    "local ORGANIZER_ENABLED = false",
  );
  assert.notEqual(disabledLua, lua, "disabled fallback fixture should override the default");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? path.join("J:/SteamLibrary/steamapps/common/ProjectZomboid", "projectzomboid.jar");
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const helper = path.join(modRoot, "tests/OverflowFloorDropKahluaContract.java");
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(helper), "Kahlua contract helper was not found");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "tetris-food-sort-disabled-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, helper]);
    const fixture = String.raw`
local logs = {}
function print(message) logs[#logs + 1] = tostring(message) end
local function event()
    local result = {}
    function result.Add(callback) result.callback = callback end
    return result
end
Events = {
    OnFillInventoryObjectContextMenu = event(),
    OnGameBoot = event(),
    OnGameStart = event(),
}
`;
    const scenario = String.raw`
assert(Events.OnFillInventoryObjectContextMenu.callback == nil,
    "disabled organizer must not install its context-menu hook")
assert(Events.OnGameBoot.callback == nil and Events.OnGameStart.callback == nil,
    "disabled organizer must not install deferred hooks")
local disabledTrace = false
for _, line in ipairs(logs) do
    if string.find(line, "disabled feature=freshness-and-calories", 1, true) then disabledTrace = true end
end
assert(disabledTrace, "disabled organizer state must be traceable")
`;
    const contractPath = path.join(tempDir, "food-organizer-disabled.lua");
    fs.writeFileSync(contractPath, fixture + disabledLua + "\n" + scenario, "utf8");
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "OverflowFloorDropKahluaContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Inventory Tetris overflow Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("organizer metadata and translations stay with the active local addon", () => {
  assert.match(modInfo, /^id=ChilaSeda_InventoryTetrisSizeCap_B42$/m);
  assert.match(modInfo, /^require=INVENTORY_TETRIS$/m);
  assert.match(modInfo, /^loadModAfter=INVENTORY_TETRIS,EQUIPMENT_UI,EQUIPMENT_UI_B42$/m);
  assert.match(modInfo, /^versionMin=42\.20$/m);
  assert.match(modInfo, /^modversion=1\.4\.9$/m);
  assert.match(readme, /Version 1\.4\.7/);
  assert.match(translationModInfo, /^id=ChilaSeda_Translations_ES_B42$/m);
  assert.match(translationModInfo, /^modversion=1\.5\.3$/m);
  assert.match(translationModInfo, /^loadModAfter=.*ChilaSeda_InventoryTetrisSizeCap_B42/m);
  assert.match(translationReadme, /1\.5\.0/);
  assert.match(englishMenu, /ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness/);
  assert.match(englishMenu, /ContextMenu_ChilaSeda_InventoryTetris_FoodCalories/);
  assert.match(spanishMenu, /ContextMenu_ChilaSeda_InventoryTetris_OrganizeFood = "Organizar alimentos"/);
  assert.match(spanishMenu, /ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness = "Por frescura"/);
  assert.match(spanishMenu, /ContextMenu_ChilaSeda_InventoryTetris_FoodCalories = "Por calorías"/);
  for (const key of [
    "ContextMenu_ChilaSeda_InventoryTetris_OrganizeFood",
    "ContextMenu_ChilaSeda_InventoryTetris_FoodFreshness",
    "ContextMenu_ChilaSeda_InventoryTetris_FoodCalories",
  ]) {
    const keyLines = spanishMenu.match(new RegExp(`^\\s*${key}\\s*=`, "gm")) ?? [];
    assert.equal(keyLines.length, 1, `${key} should occur exactly once in the winning catalog`);
  }
  assert.match(englishUI, /FoodSortSuccessFreshness/);
  assert.match(englishUI, /FoodSortNoSpace/);
  assert.match(spanishUI, /FoodSortSuccessCalories/);
  assert.match(spanishUI, /FoodSortOverflow/);
});
