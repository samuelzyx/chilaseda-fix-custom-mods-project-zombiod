import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaFile = path.join(modRoot, "42/media/lua/client/ChilaSeda_OptionsSearch.lua");
const modInfoFile = path.join(modRoot, "42/mod.info");
const spanishUiFile = path.resolve(
  modRoot,
  "../ChilaSeda_Translations_ES_B42/42/media/lua/shared/Translate/ES/UI.json",
);
const vanillaEntryFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISTextEntryBox.lua";
const vanillaElementFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISUIElement.lua";
const vanillaLabelFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISLabel.lua";
const vanillaMainOptionsFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/OptionScreens/MainOptions.lua";
const lua = fs.readFileSync(luaFile, "utf8");
const vanillaEntry = fs.readFileSync(vanillaEntryFile, "utf8");
const vanillaElement = fs.readFileSync(vanillaElementFile, "utf8");
const vanillaLabel = fs.readFileSync(vanillaLabelFile, "utf8");
const vanillaMainOptions = fs.readFileSync(vanillaMainOptionsFile, "utf8");

function section(source, start, end) {
  const from = source.indexOf(start);
  assert.notEqual(from, -1, `missing section start: ${start}`);
  const to = source.indexOf(end, from + start.length);
  assert.notEqual(to, -1, `missing section end: ${end}`);
  return source.slice(from, to);
}

test("search field creates UITextBox2 before any getText call", () => {
  assert.match(vanillaEntry, /function ISTextEntryBox:instantiate\(\)[\s\S]*?self\.javaObject\s*=\s*UITextBox2\.new/);
  assert.match(vanillaEntry, /function ISTextEntryBox:getText\(\)\s*return self\.javaObject:getText\(\)/);
  const attach = section(lua, "local function attachSearch(", "function MainOptions:onChilaSedaBeginKeyFilter(button)");
  const initialized = attach.indexOf("entry:initialise()");
  const instantiated = attach.indexOf("entry:instantiate()");
  const firstRead = attach.indexOf("entry:getText()");
  assert.ok(initialized >= 0 && instantiated > initialized && firstRead > instantiated,
    "entry must initialize, instantiate its Java control, then read committed text");
});

test("text filtering reads the committed value after the UI update", () => {
  const attach = section(lua, "local function attachSearch(", "function MainOptions:onChilaSedaBeginKeyFilter(button)");
  assert.match(attach, /local function applyCommittedText\(\)[\s\S]*?local query = entry:getText\(\) or ""[\s\S]*?applyFilter\(state, query\)/);
  assert.match(attach, /local function deferCommittedText\(\)[\s\S]*?OnTickEvenPaused or Events\.OnTick/);
  assert.match(attach, /entry\.onTextChangeFunction = function\(\)[\s\S]*?applyCommittedText\(\)[\s\S]*?deferCommittedText\(\)/);
  assert.match(attach, /if query ~= state\.lastQuery then/);
});

test("text queries require every literal term and normalize Spanish accents", () => {
  const normalization = section(lua, "local function normalized(", "local function addText(");
  const matcher = section(lua, "local function matchesQuery(", "local function setChildVisible(");
  assert.match(normalization, /:lower\(\)/);
  assert.match(normalization, /\\195\\161.*= "a"/);
  assert.match(matcher, /for term in query:gmatch\("%S\+"\) do/);
  assert.match(matcher, /text:find\(term, 1, true\)/);
  assert.match(matcher, /return false/);
});

test("filter preserves original hidden state and restores row layout when cleared", () => {
  const filter = section(lua, "local function applyFilter(", "local function translated(");
  assert.match(filter, /local rowVisible = textMatches and keyMatches/);
  assert.match(filter, /setChildVisible\(child, childInfo\.baseVisible\)/);
  assert.match(filter, /setChildVisible\(state\.noResults, searching and visibleResultRows == 0\)/);
  assert.match(filter, /setChildY\(child, compactY \+ childInfo\.baseY - row\.baseY\)/);
  assert.match(filter, /contentBottom \+ state\.bottomPadding/);
  assert.match(filter, /setScrollHeight\(state\.panel, state\.originalScrollHeight\)/);
  const attach = section(lua, "local function attachSearch(", "function MainOptions:onChilaSedaBeginKeyFilter(button)");
  assert.match(attach, /local contentHeight = math\.max\(viewportHeight, originalContentBottom,[\s\S]*?originalScrollHeight > originalPanelHeight and originalScrollHeight or 0\)/);
  assert.match(attach, /bottomPadding = bottomPadding/);
});

test("vanilla keybinding category titles and dividers stay with matching results", () => {
  assert.match(vanillaMainOptions, /self:addHorizontalLine\(y, getText\("UI_optionscreen_binding_/);
  assert.match(vanillaMainOptions, /self:addHorizontalLine\(y, getText\("UI_optionscreen_binding_/);
  assert.match(vanillaMainOptions, /self:addHorizontalLine\(y, getText\("UI_optionscreen_binding_/);
  assert.match(vanillaMainOptions, /self:addHorizontalLine\(y, getText\("UI_optionscreen_binding_/);
  const annotation = section(lua, "local function keybindingCategoryLabel(", "local function refreshSearchOverlays(");
  assert.match(annotation, /entry\.value:match\("\^%\[\.\+%\]\$"\)/);
  assert.match(annotation, /rowByElement\[entry\.txt\] or rowByElement\[entry\.btn\]/);
  assert.match(annotation, /row\.isCategoryHeader = true/);
  const filter = section(lua, "local function applyFilter(", "local function translated(");
  assert.match(filter, /categoryHasMatches\[row\.category\] = true/);
  assert.match(filter, /if row\.isCategoryHeader then[\s\S]*?categoryHasMatches\[row\.category\] == true/);
  assert.match(filter, /visibleResultRows == 0/);
  const builder = section(lua, "local pageBuilders = {", "local originalCreate = MainOptions.create");
  assert.match(builder, /keyBindingEntries\[#keyBindingEntries \+ 1\] = entry/);
  assert.match(builder, /keyBindingEntries = keyBindingEntries/);
  assert.match(lua, /spec\.supportsKeyFilter, spec\.keyBindingEntries/);
});

test("Kahlua keeps only the matching category divider and restores it when cleared", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const helpers = section(lua, "local function safeField(", "local function refreshSearchOverlays(");
  const fixture = `${helpers}
getText = function(key)
  if key == "UI_optionscreen_binding_Combat" then return "Combat" end
  if key == "UI_optionscreen_binding_Survival" then return "Survival" end
  return key
end
local function element(y, text, internal, title)
  local value = { y = y, height = 10, text = text, internal = internal, title = title, visible = true }
  function value:setVisible(visible) self.visible = visible end
  function value:setY(newY) self.y = newY end
  return value
end
local function row(y, text, elements)
  local children = {}
  for _, value in ipairs(elements) do
    children[#children + 1] = { element = value, baseY = value.y, height = value.height, baseVisible = true }
  end
  return { baseY = y, bottomY = y + 10, height = 10, text = normalized(text), category = "", children = children }
end
local combatLine = element(0, "", nil, nil)
local combatTitle = element(0, "Combat", nil, nil)
local combatLabel = element(20, "Hit", nil, nil)
local combatButton = element(20, nil, "Hit", "Left Ctrl")
local otherCombatLabel = element(40, "Push", nil, nil)
local otherCombatButton = element(40, nil, "Push", "Q")
local survivalLine = element(60, "", nil, nil)
local survivalTitle = element(60, "Survival", nil, nil)
local survivalLabel = element(80, "Sleep", nil, nil)
local survivalButton = element(80, nil, "Sleep", "Left Shift")
local rows = {
  row(0, "Combat", { combatLine, combatTitle }),
  row(20, "Hit Left Ctrl", { combatLabel, combatButton }),
  row(40, "Push Q", { otherCombatLabel, otherCombatButton }),
  row(60, "Survival", { survivalLine, survivalTitle }),
  row(80, "Sleep Left Shift", { survivalLabel, survivalButton }),
}
local headers, bindings = annotateKeyBindingCategories(rows, {
  { value = "[Combat]" },
  { txt = combatLabel, btn = combatButton },
  { txt = otherCombatLabel, btn = otherCombatButton },
  { value = "[Survival]" },
  { txt = survivalLabel, btn = survivalButton },
})
assert(headers == 2 and bindings == 3, "all vanilla categories and bindings must map")
local panel = { height = 100, scrollHeight = 100 }
function panel:getHeight() return self.height end
function panel:setScrollHeight(height) self.scrollHeight = height end
function panel:setYScroll(value) self.yScroll = value end
local noResults = element(0, "No results", nil, nil)
local state = { panel = panel, rows = rows, noResults = noResults, originalScrollHeight = 100,
  searchStartY = 0, bottomPadding = 0, keyFilter = "Left Ctrl" }
applyFilter(state, "")
assert(combatLine.visible and combatTitle.visible, "matching category title and divider stay visible")
assert(combatButton.visible and not otherCombatButton.visible, "only matching bindings stay visible")
assert(not survivalLine.visible and not survivalTitle.visible and not survivalButton.visible,
  "unmatched category title and divider are hidden")
assert(not noResults.visible, "visible matching bindings suppress no-results label")
state.keyFilter = "Right Alt"
applyFilter(state, "")
assert(noResults.visible and not combatTitle.visible and not survivalTitle.visible,
  "no-results state hides all category dividers")
state.keyFilter = ""
applyFilter(state, "")
assert(combatLine.visible and combatTitle.visible and otherCombatButton.visible
  and survivalLine.visible and survivalTitle.visible and survivalButton.visible,
  "clearing the filter restores every original category and binding")
`;
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "options-search-category-kahlua-"));
  try {
    const fixtureFile = path.join(tempDir, "category-contract.lua");
    fs.writeFileSync(fixtureFile, fixture, "utf8");
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixtureFile, "--execute"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("filter header and scrolling options area are separate blocks", () => {
  const attach = section(lua, "local function attachSearch(", "function MainOptions:onChilaSedaClearTextFilter(button)");
  assert.match(lua, /local TRACE_ENABLED = true/);
  assert.match(lua, /TRACE_MAX_LINES, traceLines = 24, 0/);
  assert.match(lua, /if not TRACE_ENABLED or traceLines >= TRACE_MAX_LINES then return end/);
  assert.match(attach, /translated\("UI_ChilaSeda_OptionsSearch_Filters", "Filters"\)/);
  assert.match(attach, /overlay:setScrollChildren\(false\)/);
  assert.match(attach, /panel:setY\(originalPanelY \+ controls\.contentOffset\)/);
  assert.match(attach, /panel:setHeight\(viewportHeight\)/);
  assert.match(attach, /panel:addChild\(noResults\)/);
  assert.doesNotMatch(attach, /overlay:addChild\(noResults\)/);
  assert.match(attach, /controls\.dividerY/);
  assert.match(attach, /divider\.background = true/);
  assert.match(attach, /trace\("filter-layout-ready"[\s\S]*?scroll=separate/);
  assert.match(attach, /trace\("filter-layout-fallback"[\s\S]*?reason=panel-too-narrow/);
  assert.match(fs.readFileSync(modInfoFile, "utf8"), /^modversion=1\.0\.10$/m);
});

test("fixed filter header has a Spanish translation", () => {
  const catalog = JSON.parse(fs.readFileSync(spanishUiFile, "utf8"));
  assert.equal(catalog.UI_ChilaSeda_OptionsSearch_Filters, "Filtros");
  assert.equal(catalog.UI_ChilaSeda_OptionsSearch_ShowCategory,
    "Ver otras opciones de esta categoria");
});

test("filter header layout reserves non-overlapping rows and an options viewport", () => {
  const layoutSource = section(lua, "local FILTER_HEIGHT", "local function safeField(");
  const fixture = `${layoutSource}
local regular = filterControlLayout(900, false)
assert(regular.titleY + FILTER_TITLE_HEIGHT <= regular.entryY, "title must not overlap text filter")
assert(regular.clearSearchY == regular.entryY, "text clear stays beside its search field")
assert(regular.dividerY >= regular.entryY + FILTER_HEIGHT, "divider must follow text filter")
assert(regular.contentOffset == regular.dividerY + FILTER_DIVIDER_HEIGHT + FILTER_BLOCK_BOTTOM_GAP,
  "options viewport starts after the fixed filter block")
assert(regular.categoryButtonY == regular.entryY and regular.categoryButtonWidth >= MIN_CATEGORY_BUTTON_WIDTH,
  "category action shares the search row when enough horizontal space is available")
local wide = filterControlLayout(900, true)
assert(wide.entryY + FILTER_HEIGHT <= wide.buttonY, "key filter starts below text filter")
assert(wide.clearSearchY == wide.entryY and wide.clearButtonY == wide.buttonY,
  "clear buttons stay beside their filters when the panel is wide")
assert(wide.dividerY >= wide.buttonY + FILTER_HEIGHT, "divider must follow both wide controls")
local narrow = filterControlLayout(250, true)
assert(narrow.clearButtonY >= narrow.buttonY + FILTER_HEIGHT,
  "narrow clear-key control gets its own row")
assert(narrow.dividerY >= narrow.clearButtonY + FILTER_HEIGHT,
  "divider must follow the wrapped narrow controls")
assert(narrow.categoryButtonY >= narrow.clearButtonY + FILTER_HEIGHT + FILTER_CONTENT_GAP,
  "a narrow panel puts the category action on its own row after the key controls")
`;
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "options-search-layout-kahlua-"));
  try {
    const fixtureFile = path.join(tempDir, "filter-layout-contract.lua");
    fs.writeFileSync(fixtureFile, fixture, "utf8");
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixtureFile, "--execute"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("filter header does not scroll with the options rows or cover their result message", () => {
  const implementation = section(
    lua,
    'require "OptionScreens/MainOptions"',
    "local originalKeyRelease = MainOptions.onKeyRelease",
  );
  const fixture = `
local function widget(x, y, width, height, text)
  local value = { x = x, y = y, width = width, height = height, text = text,
    visible = true, children = {}, scrollHeight = 0 }
  function value:initialise() end
  function value:instantiate() end
  function value:setAnchorLeft(v) self.anchorLeft = v end
  function value:setAnchorRight(v) self.anchorRight = v end
  function value:setAnchorTop(v) self.anchorTop = v end
  function value:setAnchorBottom(v) self.anchorBottom = v end
  function value:setVisible(v) self.visible = v end
  function value:setScrollChildren(v) self.scrollChildren = v end
  function value:addChild(child) self.children[#self.children + 1] = child; child.parent = self end
  function value:getWidth() return self.width end
  function value:getHeight() return self.height end
  function value:getX() return self.x end
  function value:getY() return self.y end
  function value:setY(v) self.y = v end
  function value:setHeight(v) self.height = v end
  function value:getScrollHeight() return self.scrollHeight end
  function value:setScrollHeight(v) self.scrollHeight = v end
  function value:setYScroll(v) self.yScroll = v end
  function value:getChildren() return self.children end
  function value:setPlaceholderText(v) self.placeholder = v end
  function value:getText() return self.text or "" end
  function value:setText(v) self.text = v end
  function value:setTitle(v) self.text = v end
  return value
end
require = function(_) end
print = function(_) end
MainOptions = {}
UIFont = { Small = "small" }
getTextOrNull = function(_) return nil end
ISPanelJoypad = { new = function(_, x, y, w, h) return widget(x, y, w, h) end }
ISLabel = { new = function(_, x, y, h, text) return widget(x, y, 200, h, text) end }
ISTextEntryBox = { new = function(_, text, x, y, w, h) return widget(x, y, w, h, text) end }
ISButton = { new = function(_, x, y, w, h, text) return widget(x, y, w, h, text) end }
`;
  const assertions = `
local tabs = { children = {} }
function tabs:addChild(child) self.children[#self.children + 1] = child; child.parent = self end
local instance = { tabs = tabs }
local panel = widget(0, 22, 900, 300)
panel.scrollHeight = 420
panel.scrollChildren = true
local clippedHeader = widget(0, -28, 200, 10, "Mods")
local clippedOption = widget(0, -12, 200, 10, "Hide vanilla HUD")
local otherOption = widget(0, 8, 200, 10, "Show tooltips")
panel:addChild(clippedHeader)
panel:addChild(clippedOption)
panel:addChild(otherOption)
local overlay = attachSearch(instance, panel, "Mods", {
  { search = "mods", display = "Mods" },
}, true, nil)
local state = panel.chilaSedaOptionsSearchState
local title, divider
for _, child in ipairs(overlay.children) do
  if child.text == "Filters" then title = child end
  if child.height == FILTER_DIVIDER_HEIGHT then divider = child end
end
assert(title and title.parent == overlay, "Filters title belongs to the fixed header")
assert(divider and divider.parent == overlay, "divider belongs to the fixed header")
assert(overlay.background and overlay.scrollChildren == false, "header is a visible non-scrolling block")
assert(panel.scrollChildren == true, "options rows keep their own scrolling panel")
assert(panel.y == 22 + overlay.height, "results start exactly after the fixed header")
assert(panel.height == 300 - overlay.height, "results viewport reserves the header height")
assert(divider.y + divider.height <= overlay.height, "divider stays inside the filter block")
assert(state.noResults.parent == panel and state.noResults.y == FILTER_MARGIN,
  "no-results message belongs to the options viewport")
assert(state.originalScrollHeight == 420 and panel.scrollHeight == 420,
  "the options panel preserves its independent content scroll height")
assert(state.searchStartY == 0, "a list that starts above its viewport is normalized to the top")
applyFilter(state, "hide")
assert(clippedOption.y == 0 and clippedOption.visible,
  "the first matching result starts fully inside the results viewport")
assert(state.categoryButton.visible and state.categoryCandidate.search == "mods",
  "one matching category exposes the show-rest-of-category action")
state.keyFilter = "Ctrl"
MainOptions:onChilaSedaShowCategory(state.categoryButton)
assert(state.panel.chilaSedaOptionsSearchEntry:getText() == "Mods",
  "the category action replaces the text query with the category name")
assert(state.keyFilter == "" and clippedHeader.visible and clippedOption.visible and otherOption.visible,
  "the category action clears the key filter and restores every option in that category")
assert(not state.categoryButton.visible,
  "the category action hides itself once the full category is already displayed")
assert(#tabs.children == 1 and tabs.children[1] == overlay,
  "only the fixed filter block is attached to the tab panel")
applyFilter(state, "no-match")
assert(state.noResults.visible, "no-results message appears inside results area")
assert(overlay.scrollHeight == 0, "filter interaction does not change header scroll")
applyFilter(state, "")
assert(not state.noResults.visible and panel.scrollHeight == 420,
  "clearing filters restores the independent options viewport")
`;
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "options-search-block-kahlua-"));
  try {
    const fixtureFile = path.join(tempDir, "filter-block-contract.lua");
    fs.writeFileSync(fixtureFile, `${fixture}${implementation}${assertions}`, "utf8");
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", fixtureFile, "--execute"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("no-results label stays left-aligned at the top of the results viewport", () => {
  const label = section(lua, "local noResults = ISLabel:new(", "\n\tnoResults:initialise()");
  assert.match(vanillaLabel, /function ISLabel:new\s*\(x, y, height, name, r, g, b, a, font, bLeft\)/);
  assert.match(vanillaLabel, /if \(bLeft ~= true\) then\s+o\.x = o\.x - o\.width/);
  assert.match(label, /FILTER_MARGIN, FILTER_MARGIN, NO_RESULTS_HEIGHT/);
  assert.match(label, /FILTER_MARGIN,[\s\S]*?UIFont\.Small, true\)/);
});

test("Options Search Lua compiles with the game's Kahlua compiler", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "options-search-kahlua-"));
  try {
    const harness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", luaFile],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("options rows are enumerated from the globally ID-keyed child map", () => {
  const reader = section(lua, "local function readRows(", "local function setScrollHeight(");
  assert.match(vanillaElement, /self\.children\[otherElement\.ID\]\s*=\s*otherElement/);
  assert.match(reader, /panel:getChildren\(\) or panel\.children or \{\}/);
  assert.match(reader, /for _, child in pairs\(childList\) do/);
  assert.doesNotMatch(reader, /ipairs\(panel\.children/);
});

test("text clear button empties the query without clearing the key filter", () => {
  const attach = section(lua, "local function attachSearch(", "function MainOptions:onChilaSedaBeginKeyFilter(button)");
  const clear = section(lua, "function MainOptions:onChilaSedaClearTextFilter(button)", "function MainOptions:onChilaSedaBeginKeyFilter(button)");
  assert.match(attach, /FILTER_HEIGHT, "X", self, MainOptions\.onChilaSedaClearTextFilter/);
  assert.match(attach, /clearSearchButton\.chilaSedaOptionsSearchState = state/);
  assert.match(clear, /entry:setText\(""\)/);
  assert.match(clear, /state\.lastQuery = ""/);
  assert.match(clear, /applyFilter\(state, ""\)/);
  assert.doesNotMatch(attach, /entry:setTooltip/);
});

test("Escape can be captured as a key filter and the adjacent clear button removes it", () => {
	assert.match(lua, /state\.keyFilter = getKeyName\(key\) or tostring\(key\)/);
  assert.match(lua, /Events\.OnKeyPressed\.Add\(function\(key\)/);
	assert.match(lua, /UI_ChilaSeda_OptionsSearch_ClearKey/);
	assert.match(lua, /clearKeyButton\.chilaSedaOptionsKeySearchState = state/);
	const clear = section(lua, "function MainOptions:onChilaSedaClearKeyFilter(button)", "local originalKeyRelease = MainOptions.onKeyRelease");
	assert.match(clear, /state\.keyFilter = ""/);
	assert.match(clear, /applyFilter\(state, entry and entry:getText\(\) or ""\)/);
  assert.doesNotMatch(lua, /table\.sort\s*\(\s*PZAPI\.ModOptions\.Data/);
});

test("each tab's key button captures and filters with its own state", () => {
  assert.match(lua, /keyFilterButton\.chilaSedaOptionsKeySearchState = state/);
  assert.match(lua, /local state = button and button\.chilaSedaOptionsKeySearchState/);
  assert.match(lua, /instance\.chilaSedaOptionsKeyCaptureState/);
  assert.match(lua, /local function matchesKeyName\([\s\S]*?candidateTokens[\s\S]*?queryTokens/);
  assert.match(lua, /for _, field in ipairs\(\{ "title", "text", "value", "key" \}\)/);
  assert.doesNotMatch(lua, /self\.chilaSedaOptionsKeySearchState/);
});

test("search controls keep the key clear button beside its filter when they fit", () => {
  const layout = section(lua, "local function filterControlLayout(", "local function safeField(");
  assert.match(layout, /panelWidth - FILTER_MARGIN \* 2/);
	assert.match(layout, /availableWidth >= MIN_KEY_FILTER_WIDTH \+ KEY_FILTER_GAP \+ CLEAR_KEY_WIDTH/);
	assert.match(layout, /layout\.clearButtonX = layout\.buttonX \+ layout\.buttonWidth \+ KEY_FILTER_GAP/);
	assert.match(layout, /clearButtonY = controlsY \+ FILTER_HEIGHT \+ FILTER_CONTENT_GAP/);
	assert.match(layout, /layout\.clearButtonY = layout\.buttonY \+ FILTER_HEIGHT \+ FILTER_CONTENT_GAP/);
  assert.match(layout, /layout\.dividerY = controlsBottom \+ FILTER_CONTENT_GAP/);
  assert.match(layout, /layout\.contentOffset = layout\.dividerY \+ FILTER_DIVIDER_HEIGHT \+ FILTER_BLOCK_BOTTOM_GAP/);
  assert.doesNotMatch(layout, /FILTER_MARGIN \+ FILTER_WIDTH \+ 8/);
});

test("search controls are attached after vanilla centers each options page", () => {
  const createWrapper = section(lua, "local originalCreate = MainOptions.create", "trace(\"initialized\"");
  const vanillaBuild = vanillaMainOptions.indexOf("self:centerTabChildrenX(getText(\"UI_optionscreen_display\"))");
  const vanillaReturn = vanillaMainOptions.indexOf("function MainOptions:create()");
  assert.ok(vanillaBuild > vanillaReturn, "vanilla centers controls during create");
  assert.match(createWrapper, /local result = originalCreate\(self, \.\.\.\)[\s\S]*?for _, spec in ipairs\(self\.chilaSedaOptionsSearchPageSpecs\)[\s\S]*?attachSearch\(self, spec\.panel/);
});
