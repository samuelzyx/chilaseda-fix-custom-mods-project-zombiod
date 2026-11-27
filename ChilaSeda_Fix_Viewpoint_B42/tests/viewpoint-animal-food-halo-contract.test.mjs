import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzzzzzzzz_ChilaSeda_ViewpointAnimalFoodHalo.lua",
);
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gameRoot = process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR ?? path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint animal pickup and full-food Halo transitions are local, single-shot and traced", () => {
  assert.equal(modInfo.match(/^modversion=(.+)$/m)?.[1], "2.0.159");
  assert.match(modInfo, /require=ZombieBuddy/);
  assert.match(modInfo, /loadModAfter=.*Viewpoint.*ZombieBuddy/);
  assert.match(lua, /ISPickupAnimal\.complete/);
  assert.match(lua, /moodleTypes and moodleTypes\.FOOD_EATEN/);
  assert.match(lua, /level >= 4/);
  assert.match(lua, /Moodles_FoodEaten_lvl4/);
  assert.match(lua, /MAX_ANIMAL_TRACE_LINES = 16/);
  assert.match(lua, /MAX_FOOD_TRACE_LINES = 16/);
  assert.match(lua, /ChilaSedaViewpointAnimalPickupHaloTrace ~= true/);
  assert.match(lua, /ChilaSedaViewpointFoodFullHaloTrace ~= true/);
  assert.match(lua, /result=installed method=ISPickupAnimal\.complete/);
  assert.match(lua, /"Animal\.Pickup"/);
  assert.match(lua, /"Nutrition\.FoodEatenFull"/);
  assert.match(lua, /category_ranching\.png/);
  assert.match(lua, /category_food_and_water\.png/);

  const prelude = String.raw`
function require(name)
  if name == "Viewpoint_Loot" then ViewpointLoot = {} end
  return true
end
function makeEvent()
  local event = { callbacks = {} }
  function event.Add(callback) event.callbacks[#event.callbacks + 1] = callback end
  function event.Remove(callback)
    for i = #event.callbacks, 1, -1 do
      if event.callbacks[i] == callback then table.remove(event.callbacks, i) end
    end
  end
  return event
end
Events = {
  OnGameStart = makeEvent(), OnTick = makeEvent(), OnPlayerUpdate = makeEvent(),
}
MoodleType = { FOOD_EATEN = 17 }
TestLog = {}
print = function(value) TestLog[#TestLog + 1] = tostring(value) end
local localPlayer = { playerNum = 0, foodLevel = 0 }
function localPlayer:getPlayerNum() return self.playerNum end
function localPlayer:getMoodles()
  return { getMoodleLevel = function(_, moodle) assert(moodle == MoodleType.FOOD_EATEN, "food moodle constant must be passed"); return localPlayer.foodLevel end }
end
getSpecificPlayer = function(playerNum) if playerNum == 0 then return localPlayer end end
getText = function(key)
  if key == "Moodles_FoodEaten_lvl4" then return "Lleno a reventar" end
  return key
end
TestNotices = {}
ChilaSeda_ViewpointHaloNotifications = {
  showProtected = function(text, color, icon, duration, source)
    TestNotices[#TestNotices + 1] = { text = text, color = color, icon = icon, duration = duration, source = source }
    return true
  end,
}
ISPickupAnimal = {
  complete = function(self)
    self.vanillaCalls = (self.vanillaCalls or 0) + 1
    return self.result, "vanilla-tail"
  end,
}
`;
  const assertions = String.raw`
assert(ISPickupAnimal.chilaSedaAnimalPickupHaloInstalled == true, "pickup hook must install")
local animal = {
  getCustomName = function() return nil end,
  getFullName = function() return "Goose - Canada Gander" end,
}
local pickup = { character = localPlayer, animal = animal, result = true }
local ok, tail = ISPickupAnimal.complete(pickup)
assert(ok == true and tail == "vanilla-tail", "animal wrapper must preserve vanilla return values")
assert(#TestNotices == 1 and TestNotices[1].text == "+1 Goose - Canada Gander", "successful pickup must show the animal name")
assert(TestNotices[1].source == "Animal.Pickup", "pickup note must identify its source")
assert(TestNotices[1].icon == "media/ui/survival_guide_spiffo/category_ranching.png", "pickup note must use the ranching icon")
ISPickupAnimal.complete(pickup)
assert(#TestNotices == 1, "duplicate completion must not duplicate the animal Halo note")
local failed = { character = localPlayer, animal = animal, result = false }
local failedResult = ISPickupAnimal.complete(failed)
assert(failedResult == false and #TestNotices == 1, "failed completion must not notify")
local remote = { playerNum = 1 }
function remote:getPlayerNum() return self.playerNum end
local remotePickup = { character = remote, animal = animal, result = true }
ISPickupAnimal.complete(remotePickup)
assert(#TestNotices == 1, "non-local animal pickup must not create a local note")
local unnamed = { getCustomName = function() return nil end, getFullName = function() return " " end }
ISPickupAnimal.complete({ character = localPlayer, animal = unnamed, result = true })
assert(#TestNotices == 1, "unnamed animals must not create a malformed note")

local function updatePlayer(player)
  for _, callback in ipairs(Events.OnPlayerUpdate.callbacks) do callback(player) end
end
updatePlayer(localPlayer)
assert(#TestNotices == 1, "initial state is only a baseline")
localPlayer.foodLevel = 4
updatePlayer(localPlayer)
assert(#TestNotices == 2 and TestNotices[2].text == "Lleno a reventar", "level 4 must use the localized food moodle label")
assert(TestNotices[2].source == "Nutrition.FoodEatenFull", "fullness note must identify its source")
assert(TestNotices[2].icon == "media/ui/survival_guide_spiffo/category_food_and_water.png", "fullness note must use the food icon")
updatePlayer(localPlayer)
updatePlayer(localPlayer)
assert(#TestNotices == 2, "remaining at level 4 must not repeat the note")
localPlayer.foodLevel = 3
updatePlayer(localPlayer)
localPlayer.foodLevel = 4
updatePlayer(localPlayer)
assert(#TestNotices == 3, "leaving and re-entering level 4 may notify again")
localPlayer.foodLevel = 3
updatePlayer(localPlayer)
local alreadyFull = { playerNum = 0, foodLevel = 4 }
function alreadyFull:getPlayerNum() return self.playerNum end
function alreadyFull:getMoodles()
  local player = self
  return { getMoodleLevel = function() return player.foodLevel end }
end
updatePlayer(alreadyFull)
assert(#TestNotices == 3, "a newly observed already-full player is only a baseline")
local remoteFood = { playerNum = 1, foodLevel = 4 }
function remoteFood:getPlayerNum() return self.playerNum end
function remoteFood:getMoodles()
  return { getMoodleLevel = function() return remoteFood.foodLevel end }
end
updatePlayer(remoteFood)
assert(#TestNotices == 3, "non-local moodle transitions must be ignored")
assert(table.concat(TestLog, "\n"):find("event=pickup result=shown source=ISPickupAnimal.complete", 1, true), "trace must confirm successful pickup")
assert(table.concat(TestLog, "\n"):find("event=fullness result=shown level=4", 1, true), "trace must confirm level 4 transition")

for i = 1, 30 do
  ISPickupAnimal.complete({ character = localPlayer, animal = animal, result = true })
  localPlayer.foodLevel = (i % 2 == 1) and 4 or 3
  updatePlayer(localPlayer)
end
local animalTraceCount, foodTraceCount = 0, 0
for _, line in ipairs(TestLog) do
  if line:find("[ChilaSeda_ViewpointAnimalPickupHalo]", 1, true) then animalTraceCount = animalTraceCount + 1 end
  if line:find("[ChilaSeda_ViewpointFoodFullHalo]", 1, true) then foodTraceCount = foodTraceCount + 1 end
end
assert(animalTraceCount == 16, "animal trace must stop at its 16-line limit")
assert(foodTraceCount == 16, "food trace must stop at its 16-line limit")
local logCount = #TestLog
local noticeCount = #TestNotices
ChilaSedaViewpointAnimalPickupHaloTrace = false
ChilaSedaViewpointFoodFullHaloTrace = false
ISPickupAnimal.complete({ character = localPlayer, animal = animal, result = true })
localPlayer.foodLevel = 4
updatePlayer(localPlayer)
assert(#TestLog == logCount, "disabled traces must stop logging")
assert(#TestNotices == noticeCount + 2, "disabling traces must leave both notices active")
`;

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-animal-food-halo-"));
  try {
    const harness = path.join(modRoot, "tests/ViewpointAnimalFoodHaloKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "viewpoint-animal-food-halo.lua");
    fs.writeFileSync(
      fixturePath,
      `${prelude}\nlocal loadOk, loadError = pcall(function()\n${lua}\nend)\nif not loadOk then CONTRACT_RESULT = false; CONTRACT_ERROR = "load: " .. tostring(loadError) else\nlocal contractOk, contractError = pcall(function()\n${assertions}\nend)\nCONTRACT_RESULT = contractOk\nCONTRACT_ERROR = contractError and tostring(contractError) or ""\nend\nCONTRACT_DIAGNOSTICS = table.concat(TestLog, "\\n")`,
      "utf8",
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ViewpointAnimalFoodHaloKahluaContract", fixturePath],
      { cwd: gameRoot, encoding: "utf8" },
    );
    assert.match(result, /Animal and food Halo Kahlua contract passed/);
    assert.match(result, /event=install result=installed method=ISPickupAnimal\.complete/);
    assert.match(result, /event=pickup result=shown source=ISPickupAnimal\.complete/);
    assert.match(result, /event=fullness result=shown level=4/);
    assert.match(result, /reason=complete-failed/);
    assert.match(result, /reason=not-local-player/);
    assert.match(result, /reason=animal-name-unavailable/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
