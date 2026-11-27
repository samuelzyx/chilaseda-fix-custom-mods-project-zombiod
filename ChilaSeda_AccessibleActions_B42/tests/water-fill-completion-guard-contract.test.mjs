import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const guardPath = path.join(
  modRoot,
  "42/media/lua/client/zzz_ChilaSeda_WaterFillCompletionGuard.lua",
);
const vanillaPath =
  "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/shared/TimedActions/ISTakeWaterAction.lua";
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("reserved water fills finish when inventory reaches capacity and preserve cancellation otherwise", () => {
  assert.ok(fs.existsSync(vanillaPath), `Vanilla water action not found: ${vanillaPath}`);
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const vanilla = fs.readFileSync(vanillaPath, "utf8");
  const guard = fs.readFileSync(guardPath, "utf8");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "water-fill-guard-"));
  try {
    const prelude = `
local logs = {}
print = function(message) logs[#logs + 1] = tostring(message) end
require = function() end
IsoFlagType = { water = "water" }
ZomboidGlobals = { EquippedOrWornEncumbranceMultiplier = 1 }
luautils = { stringStarts = function() return false end }
instanceof = function(value, kind)
    return value and value.isWorldInventoryObject == true and kind == "IsoWorldInventoryObject"
end
getText = function(key) return key end
sendItemStats = function() end
ISBaseTimedAction = {
    derive = function(base, name)
        local class = { Type = name }
        class.__index = class
        setmetatable(class, { __index = base })
        return class
    end,
    new = function(class, character)
        local action = { character = character }
        setmetatable(action, class)
        return action
    end,
    setAnimVariable = function() end,
    setActionAnim = function() end,
    setOverrideHandModels = function() end,
}
local function makeCharacter(freeCapacity)
    local character = { full = false, freeCapacity = freeCapacity }
    function character:hasFullInventory() return self.full end
    function character:getFreeInventoryCapacity() return self.freeCapacity end
    function character:isEquippedClothing() return false end
    function character:isSecondaryHandItem() return false end
    function character:isTimedActionInstant() return false end
    function character:playSound() return "sound" end
    function character:reportEvent() end
    return character
end
local function makeFluidContainer(amount, capacity)
    local fluid = { amount = amount, capacity = capacity }
    function fluid:getAmount() return self.amount end
    function fluid:getCapacity() return self.capacity end
    return fluid
end
local function makeItem(amount, capacity)
    local item = { fluid = makeFluidContainer(amount, capacity), container = {} }
    function item:getContainer() return self.container end
    function item:getFluidContainer() return self.fluid end
    function item:isEquipped() return false end
    function item:syncItemFields() end
    function item:setBeingFilled() end
    function item:setJobType() end
    function item:setJobDelta() end
    function item:getName() return "Bottle" end
    function item:getFillFromDispenserSound() return nil end
    function item:getPourType() return "Bottle" end
    function item:getStaticModel() return "BottleModel" end
    return item
end
local properties = {}
function properties:has(flag) return flag == IsoFlagType.water end
function properties:get(name)
    if name == "CustomName" then return "Dispenser" end
    return nil
end
local function makeSource(amount)
    local source = { amount = amount }
    function source:getProperties() return properties end
    function source:getSprite() return { getName = function() return "test_water" end } end
    function source:hasFluid() return self.amount > 0 end
    function source:getFluidAmount() return self.amount end
    function source:transferFluidTo(fluid, requested)
        local available = math.min(requested, self.amount, fluid.capacity - fluid.amount)
        self.amount = self.amount - available
        fluid.amount = fluid.amount + available
    end
    return source
end
`;
    const vanillaIsValid = `local vanillaIsValid = ISTakeWaterAction.isValid\n`;
    const checks = `
local function newFill(freeCapacity, sourceAmount, startAmount, itemCapacity)
    local character = makeCharacter(freeCapacity)
    local item = makeItem(startAmount, itemCapacity)
    local source = makeSource(sourceAmount)
    local action = ISTakeWaterAction:new(character, item, source, false)
    return character, item, source, action
end
local character, item, source, action = newFill(0.75, 5, 0.5, 2)
assert(math.abs(action.waterUnit - 0.75) < 0.0001, "new() reserves only free inventory capacity")
action:start()
action:updateUse(0.5)
assert(math.abs(item.fluid.amount - 0.875) < 0.0001, "partial progress transfers fluid")
character.full = true
assert(vanillaIsValid(action) == false, "vanilla would cancel after the inventory becomes full")
assert(ISTakeWaterAction.isValid(action) == true, "guard keeps a started partial fill valid")
action:updateUse(0.75)
assert(ISTakeWaterAction.complete(action) == true, "guarded action completes normally")
assert(math.abs(item.fluid.amount - 1.25) < 0.0001, "completion transfers the reserved remainder")
assert(math.abs(source.amount - 4.25) < 0.0001, "source loses only the reserved amount")

local doneCharacter, doneItem, doneSource, doneAction = newFill(0.4, 0.4, 0.1, 2)
doneAction:start()
doneAction:updateUse(1)
doneCharacter.full = true
assert(doneSource.amount == 0, "planned transfer can exhaust its source")
assert(ISTakeWaterAction.isValid(doneAction) == true,
    "completed reserved volume can finish even when the source is now empty")
assert(ISTakeWaterAction.complete(doneAction) == true)
assert(math.abs(doneItem.fluid.amount - 0.5) < 0.0001)

local earlyCharacter, earlyItem, earlySource, earlyAction = newFill(1, 2, 0, 2)
earlyAction:start()
earlyAction:updateUse(0.25)
earlySource.amount = 0
earlyCharacter.full = true
assert(ISTakeWaterAction.isValid(earlyAction) == false,
    "source exhaustion before the reserved target preserves vanilla cancellation")

local missingCharacter, missingItem, _, missingAction = newFill(1, 2, 0, 2)
missingAction:start()
missingAction:updateUse(0.25)
missingCharacter.full = true
missingItem.container = nil
assert(ISTakeWaterAction.isValid(missingAction) == false,
    "removing the item from its container preserves vanilla cancellation")

local noProgressCharacter, _, _, noProgressAction = newFill(1, 2, 0, 2)
noProgressAction:start()
noProgressCharacter.full = true
assert(ISTakeWaterAction.isValid(noProgressAction) == false,
    "a full inventory before any transfer does not receive an exception")

local drinkingCharacter = makeCharacter(0)
drinkingCharacter.full = true
local drink = { item = nil, waterObject = makeSource(1), character = drinkingCharacter }
assert(ISTakeWaterAction.isValid(drink) == false, "drinking remains on vanilla validation")

for index = 1, 80 do
    local fullCharacter = makeCharacter(1)
    fullCharacter.full = true
    local invalid = {
        item = makeItem(0, 2),
        waterObject = makeSource(1),
        character = fullCharacter,
        waterUnit = 1,
    }
    ISTakeWaterAction.isValid(invalid)
end
assert(#logs <= 24, "guard diagnostics stay within the configured session limit")
local logsBeforeDisable = #logs
TRACE_WATER_FILL_COMPLETION_GUARD = false
local disabledCharacter = makeCharacter(1)
disabledCharacter.full = true
ISTakeWaterAction.isValid({
    item = makeItem(0, 2), waterObject = makeSource(1),
    character = disabledCharacter, waterUnit = 1,
})
assert(#logs == logsBeforeDisable, "trace toggle disables further diagnostics")
`;
    const contract = prelude + vanilla + vanillaIsValid + guard + checks;
    const contractPath = path.join(tempDir, "water-fill-completion-guard.lua");
    fs.writeFileSync(contractPath, contract, "utf8");
    const javaHarness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, javaHarness]);
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", contractPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
