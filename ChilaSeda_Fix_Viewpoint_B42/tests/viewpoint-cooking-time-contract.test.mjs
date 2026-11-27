import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(modRoot, "42/media/lua/client/zzzzzzzzzzzzzz_ChilaSeda_ViewpointCookingTime.lua");
const lua = fs.readFileSync(luaPath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gameRoot = process.env.PZ_GAME_ROOT ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid";
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR ?? path.join(gameRoot, "projectzomboid.jar");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("Viewpoint cooking display reports game minutes, pause, readiness and burning safely", () => {
  assert.equal(modInfo.match(/^modversion=(.+)$/m)?.[1], "2.0.159");
  assert.match(modInfo, /require=ZombieBuddy/);
  assert.match(modInfo, /loadModAfter=.*Viewpoint.*ChilaSeda_Translations_ES_B42/);
  assert.match(lua, /getCookingTime/);
  assert.match(lua, /getMinutesToCook/);
  assert.match(lua, /getMinutesToBurn/);
  assert.match(lua, /TRACE_LIMIT = 16/);
  assert.match(lua, /ChilaSedaViewpointCookingTimeTrace ~= true/);
  assert.match(lua, /ViewpointInvDetails\.render/);

  const prelude = String.raw`
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
Events = { OnGameStart = makeEvent() }
print = function(value) TestLog[#TestLog + 1] = tostring(value) end
TestLog, TestDrawnLabels, TestBars = {}, {}, {}
ChilaSedaViewpointCookingTimeTrace = true
function require() return true end
function instanceof(item, name) return name == "Food" and item.isFood == true end
local text = {
  IGUI_invpanel_Cooking = "Cooking",
  IGUI_invpanel_Burning = "Burning",
  IGUI_ChilaSeda_CookingRemainingShort = "%d min remaining",
  IGUI_ChilaSeda_BurningRemainingShort = "%d min until burnt",
  IGUI_ChilaSeda_CookingReady = "Ready to take off heat",
  IGUI_ChilaSeda_CookingRemaining = "Cooking: %d min remaining",
  IGUI_ChilaSeda_CookingPaused = "Paused: %d min remaining",
  IGUI_ChilaSeda_CookingReady = "Ready to take off heat",
  IGUI_ChilaSeda_BurningRemaining = "Burning: %d min until burnt",
  IGUI_ChilaSeda_CookingBurnt = "Burnt",
}
getText = function(key) return text[key] or key end
ISInventoryPane = {
  drawItemDetails = function(self, item)
    local key = item:getCookingTime() > item:getMinutesToCook() and "IGUI_invpanel_Burning" or "IGUI_invpanel_Cooking"
    TestDrawnLabels[#TestDrawnLabels + 1] = getText(key) .. ":"
  end,
}
ViewpointInvStyle = {
  text = function(_, label, x, y, color) TestDrawnLabels[#TestDrawnLabels + 1] = label end,
  bar = function(_, x, y, width, height, fraction, color) TestBars[#TestBars + 1] = { fraction = fraction, color = color } end,
  good = { "good" }, bad = { "bad" },
}
ViewpointInvDetails = {
  render = function() TestDrawnLabels[#TestDrawnLabels + 1] = "base-details" end,
}
local function food(elapsed, cookAt, burnAt, heat, cooked, burnt, frozen)
  local item = { isFood = true, elapsed = elapsed, cookAt = cookAt, burnAt = burnAt, heat = heat,
    cooked = cooked or false, burnt = burnt or false, frozen = frozen or false }
  function item:isIsCookable() return true end
  function item:getCookingTime() return self.elapsed end
  function item:getMinutesToCook() return self.cookAt end
  function item:getMinutesToBurn() return self.burnAt end
  function item:getHeat() return self.heat end
  function item:isCooked() return self.cooked end
  function item:isBurnt() return self.burnt end
  function item:isFrozen() return self.frozen end
  function item:getFullType() return "Base.TestFood" end
  return item
end
`;

  const assertions = String.raw`
assert(ISInventoryPane.chilaSedaCookingTimeWrapped == true, "native inventory cooking hook must install")
assert(ViewpointInvDetails.chilaSedaCookingTimeWrapped == true, "Viewpoint details hook must install")
assert(#Events.OnGameStart.callbacks == 0, "successful install must remove retry callback")
local baseGetText = getText
local cooking = food(13.2, 30, 90, 1.8)
local state, reason = ChilaSedaViewpointCookingTimeStateForTests(cooking)
assert(state.name == "cooking" and state.remaining == 17 and math.abs(state.fraction - 0.44) < 0.001,
  "cooking state must report ceil of the remaining in-game minutes and progress fraction")
ISInventoryPane:drawItemDetails(cooking, 0, 0, 0, false)
assert(TestDrawnLabels[#TestDrawnLabels] == "Cooking (17 min remaining):", "vanilla progress row must include the game minutes remaining")
assert(getText == baseGetText, "native label wrapper must restore getText after drawing")

local paused = food(13.2, 30, 90, 0.5)
local pausedState = ChilaSedaViewpointCookingTimeStateForTests(paused)
assert(pausedState.name == "paused" and pausedState.remaining == 17, "heat loss must pause cooking without changing remaining game minutes")
local beforePausedRow = #TestDrawnLabels
ISInventoryPane:drawItemDetails(paused, 0, 0, 0, false)
assert(TestDrawnLabels[#TestDrawnLabels] == "Cooking:", "vanilla row must retain its fallback when cooking is paused")
local ui, metrics, rect = {}, { pad = 4, font = 14, gap = 3, bar = 4, unit = 60 }, { x = 2, y = 3, w = 240, h = 220 }
ViewpointInvDetails.item = paused
ViewpointInvDetails:render(ui, metrics, rect, nil)
assert(TestDrawnLabels[#TestDrawnLabels] == "Paused: 17 min remaining", "Viewpoint detail panel must keep the paused remaining time visible")
assert(math.abs(TestBars[#TestBars].fraction - 0.44) < 0.001, "paused detail must preserve the cooking progress fraction")

local ready = food(30, 30, 90, 1.8, true)
local readyState = ChilaSedaViewpointCookingTimeStateForTests(ready)
assert(readyState.name == "ready" and readyState.remaining == 0 and readyState.fraction == 1, "completion must clamp the bar and stop the cook countdown")
ISInventoryPane:drawItemDetails(ready, 0, 0, 0, false)
assert(TestDrawnLabels[#TestDrawnLabels] == "Ready to take off heat:", "native row must call out a cooked item")

local burning = food(36, 30, 90, 1.8, true)
local burningState = ChilaSedaViewpointCookingTimeStateForTests(burning)
assert(burningState.name == "burning" and burningState.remaining == 54 and math.abs(burningState.fraction - 0.1) < 0.001,
  "burning must use time remaining until the burn threshold and a separate progress range")
ISInventoryPane:drawItemDetails(burning, 0, 0, 0, false)
assert(TestDrawnLabels[#TestDrawnLabels] == "Burning (54 min until burnt):", "vanilla burning row must show time until burnt")
ViewpointInvDetails.item = burning
ViewpointInvDetails:render(ui, metrics, rect, nil)
assert(TestDrawnLabels[#TestDrawnLabels] == "Burning: 54 min until burnt", "Viewpoint detail panel must localize the burning countdown")
assert(TestBars[#TestBars].color == ViewpointInvStyle.bad, "burning progress must use warning color")

local burnt = food(90, 30, 90, 0, true, true)
local burntState = ChilaSedaViewpointCookingTimeStateForTests(burnt)
assert(burntState.name == "burnt" and burntState.fraction == 1, "burnt food must not receive a negative countdown")
ViewpointInvDetails.item = burnt
ViewpointInvDetails:render(ui, metrics, rect, nil)
assert(TestDrawnLabels[#TestDrawnLabels] == "Burnt", "Viewpoint details must identify burnt food")

local notStarted = food(0, 30, 90, 0)
assert(ChilaSedaViewpointCookingTimeStateForTests(notStarted) == nil, "cold, untouched food must not show a cooking timer")
local nonFood = { isFood = false }
assert(ChilaSedaViewpointCookingTimeStateForTests(nonFood) == nil, "non-food items must bypass cooking display")
local missingData = { isFood = true, isIsCookable = function() return true end }
assert(ChilaSedaViewpointCookingTimeStateForTests(missingData) == nil, "missing game getters must use a safe fallback")
assert(getText == baseGetText, "all drawing paths must preserve the game's translation function")

for i = 1, 30 do
  local candidate = food(1 + i, 80, 120, 1.8)
  ViewpointInvDetails.item = candidate
  ViewpointInvDetails:render(ui, metrics, rect, nil)
  ISInventoryPane:drawItemDetails(candidate, 0, 0, 0, false)
end
local traceLines = 0
for _, line in ipairs(TestLog) do
  if line:find("[ChilaSeda_ViewpointCookingTime]", 1, true) then traceLines = traceLines + 1 end
end
assert(traceLines == 16, "cooking trace must stop at its 16-line session limit")
local logCount, labelCount = #TestLog, #TestDrawnLabels
ChilaSedaViewpointCookingTimeTrace = false
ISInventoryPane:drawItemDetails(cooking, 0, 0, 0, false)
assert(#TestLog == logCount and #TestDrawnLabels == labelCount + 1, "disabling trace must leave the countdown active")
CONTRACT_DIAGNOSTICS = table.concat(TestLog, "\n")
`;

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-cooking-time-"));
  try {
    const harness = path.join(modRoot, "tests/ViewpointCookingTimeKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const fixturePath = path.join(tempDir, "viewpoint-cooking-time.lua");
    fs.writeFileSync(
      fixturePath,
      `${prelude}\nlocal loadOk, loadError = pcall(function()\n${lua}\nend)\nif not loadOk then CONTRACT_RESULT = false; CONTRACT_ERROR = "load: " .. tostring(loadError) else\nlocal contractOk, contractError = pcall(function()\n${assertions}\nend)\nCONTRACT_RESULT = contractOk\nCONTRACT_ERROR = contractError and tostring(contractError) or ""\nend\nCONTRACT_DIAGNOSTICS = table.concat(TestLog, "\\n")`,
      "utf8",
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "ViewpointCookingTimeKahluaContract", fixturePath],
      { cwd: gameRoot, encoding: "utf8" },
    );
    assert.match(result, /Viewpoint cooking time Kahlua contract passed/);
    assert.match(result, /event=install result=installed methods=ISInventoryPane\.drawItemDetails,ViewpointInvDetails\.render/);
    assert.match(result, /state=paused/);
    assert.match(result, /state=ready/);
    assert.match(result, /state=burning/);
    assert.match(result, /state=burnt/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
