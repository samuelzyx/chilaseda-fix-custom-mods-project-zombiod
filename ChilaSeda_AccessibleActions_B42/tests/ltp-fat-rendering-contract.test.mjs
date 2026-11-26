import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/ChilaSeda_LTPReduceAllFat_B42.lua");
const recipePath = path.join(modRoot, "42/media/scripts/recipes/ChilaSeda_LTPFatRendering.txt");
const esRecipesPath = path.join(modRoot, "42/media/lua/shared/Translate/ES/Recipes.json");
const enRecipesPath = path.join(modRoot, "42/media/lua/shared/Translate/EN/Recipes.json");
const modInfoPath = path.join(modRoot, "42/mod.info");
const luaSource = fs.readFileSync(luaPath, "utf8");
const recipeSource = fs.readFileSync(recipePath, "utf8");

function recipeBlock(name) {
  const start = recipeSource.indexOf(`craftRecipe ${name}`);
  assert.notEqual(start, -1, `missing recipe: ${name}`);
  const next = recipeSource.indexOf("craftRecipe ", start + 12);
  return recipeSource.slice(start, next < 0 ? recipeSource.length : next);
}

function parseUniqueJson(filePath) {
  const text = fs.readFileSync(filePath, "utf8");
  const parsed = JSON.parse(text);
  const keys = [...text.matchAll(/"([^"\\]+)"\s*:/g)].map((match) => match[1]);
  assert.equal(keys.length, Object.keys(parsed).length, `${filePath} key count differs from parsed object`);
  assert.equal(new Set(keys).size, keys.length, `${filePath} contains duplicate keys`);
  return parsed;
}

test("LTP fat routes use the exact rabbit and pork inputs and preserve native pork/beef recipes", () => {
  assert.match(luaSource, /\["Base\.DeadRabbit"\]\s*=\s*"ChilaSedaReduceDeadRabbitFat"/);
  assert.match(luaSource, /\["Base\.PorkChop"\]\s*=\s*"ChilaSedaReducePorkChopLard"/);
  assert.match(luaSource, /\["Base\.Pork"\]\s*=\s*"ReduceMeatLard"/);
  assert.match(luaSource, /\["Base\.Beef"\]\s*=\s*"ReduceTallow"/);
  assert.match(luaSource, /\["Base\.Rabbitmeat"\]\s*=\s*"ReduceFat"/);

  const rabbit = recipeBlock("ChilaSedaReduceDeadRabbitFat");
  assert.match(rabbit, /OnCreate\s*=\s*RecipeCodeOnCreate\.ChilaSedaReduceDeadRabbitFat/);
  assert.match(rabbit, /item 1 \[Base\.DeadRabbit\] flags\[ItemCount\]/);
  assert.match(rabbit, /item 1 Base\.Fat,/);

  const pork = recipeBlock("ChilaSedaReducePorkChopLard");
  assert.match(pork, /OnCreate\s*=\s*RecipeCodeOnCreate\.ChilaSedaReducePorkChopLard/);
  assert.match(pork, /item 1 \[Base\.PorkChop\] flags\[ItemCount\]/);
  assert.match(pork, /item 1 Base\.Lard,/);

  assert.match(luaSource, /fallback=recipe-data-unavailable/);
  assert.match(luaSource, /fallback=source-not-found/);
  assert.match(luaSource, /fallback=output-write-failed/);
  assert.match(luaSource, /stage=install result=ready/);
  assert.match(fs.readFileSync(modInfoPath, "utf8"), /versionMin=42\.20[\s\S]*?modversion=1\.0\.52[\s\S]*?loadModAfter=.*LongTermPreservationExtended/);
});

test("recipe translations parse and contain unique names in English and Spanish", () => {
  const es = parseUniqueJson(esRecipesPath);
  const en = parseUniqueJson(enRecipesPath);
  assert.equal(es.ChilaSedaReduceDeadRabbitFat, "Reducir conejo entero a grasa");
  assert.equal(es.ChilaSedaReducePorkChopLard, "Fundir chuleta de cerdo para obtener manteca");
  assert.equal(en.ChilaSedaReduceDeadRabbitFat, "Render whole rabbit into fat");
  assert.equal(en.ChilaSedaReducePorkChopLard, "Render pork chop into lard");
});

test("Kahlua executes the fat callbacks and records success and fallback outcomes", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "ltp-fat-rendering-"));
  try {
    const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);

    const prelude = `local traces = {}
print = function(message) traces[#traces + 1] = message end
require = function(_) end
ChilaSedaAccessibleActions = { isModActive = function(id) return id == "LongTermPreservationExtended" end }
RecipeCodeOnCreate = {}
ISBaseTimedAction = { derive = function(self, name) return {} end, stop = function(self) end }
ISInventoryPaneContextMenu = { addNewCraftingDynamicalContextMenu = function() end }
Events = { OnFillInventoryObjectContextMenu = { Add = function(_) end } }
instanceof = function(item, className) return item and item.kind == className end
ZombRandFloat = function(minimum, maximum) return (minimum + maximum) / 2 end
`;
    const contract = `local function collection(items)
    return {
        size = function(self) return #items end,
        get = function(self, index) return items[index + 1] end,
    }
end
local function food(fullType, calories, carbs, lipids, proteins, hunger)
    local item = { kind = "Food", fullType = fullType, calories = calories,
        carbs = carbs, lipids = lipids, proteins = proteins, hunger = hunger }
    function item:getFullType() return self.fullType end
    function item:getCalories() return self.calories end
    function item:getCarbohydrates() return self.carbs end
    function item:getLipids() return self.lipids end
    function item:getProteins() return self.proteins end
    function item:getHungChange() return self.hunger end
    function item:setCalories(value) self.calories = value end
    function item:setCarbohydrates(value) self.carbs = value end
    function item:setLipids(value) self.lipids = value end
    function item:setProteins(value) self.proteins = value end
    function item:setHungChange(value) self.hunger = value end
    function item:setOffAge(value) self.offAge = value end
    function item:setOffAgeMax(value) self.offAgeMax = value end
    return item
end
local function recipeData(source, output)
    return {
        getAllConsumedItems = function(self) return collection(source and { source } or {}) end,
        getAllCreatedItems = function(self) return collection(output and { output } or {}) end,
    }
end
local function hasTrace(fragment)
    for _, message in ipairs(traces) do
        if string.find(message, fragment, 1, true) then return true end
    end
    return false
end

local rabbit = food("Base.DeadRabbit", 1000, 40, 20, 100, -45)
local rabbitFat = food("Base.Fat", 0, 0, 0, 0, 0)
RecipeCodeOnCreate.ChilaSedaReduceDeadRabbitFat(recipeData(rabbit, rabbitFat), nil)
assert(rabbitFat.offAge == 5 and rabbitFat.offAgeMax == 10)
assert(math.abs(rabbitFat.calories - 75) < 0.0001)
assert(math.abs(rabbitFat.carbs - 3) < 0.0001)
assert(math.abs(rabbitFat.hunger - (-3.375)) < 0.0001)
assert(hasTrace("recipe=ChilaSedaReduceDeadRabbitFat stage=oncreate result=success input=Base.DeadRabbit output=Base.Fat"))

local pork = food("Base.PorkChop", 200, 10, 30, 70, -30)
local lard = food("Base.Lard", 0, 0, 0, 0, 0)
RecipeCodeOnCreate.ChilaSedaReducePorkChopLard(recipeData(pork, lard), nil)
assert(lard.offAge == 180 and lard.offAgeMax == 365)
assert(math.abs(lard.calories - 50) < 0.0001)
assert(math.abs(lard.lipids - 7.5) < 0.0001)
assert(hasTrace("recipe=ChilaSedaReducePorkChopLard stage=oncreate result=success input=Base.PorkChop output=Base.Lard"))

local beforeFallback = #traces
RecipeCodeOnCreate.ChilaSedaReduceDeadRabbitFat(recipeData(nil, rabbitFat), nil)
assert(#traces == beforeFallback + 1)
assert(hasTrace("fallback=source-not-found"))

ZombRandFloat = nil
local fallbackFat = food("Base.Fat", 0, 0, 0, 0, 0)
RecipeCodeOnCreate.ChilaSedaReduceDeadRabbitFat(recipeData(rabbit, fallbackFat), nil)
assert(math.abs(fallbackFat.calories - 75) < 0.0001)
assert(hasTrace("fallback=random-api-unavailable"))
`;
    const contractPath = path.join(tempDir, "ltp-fat-rendering-contract.lua");
    fs.writeFileSync(contractPath, `${prelude}\n${luaSource}\n${contract}`, "utf8");
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
