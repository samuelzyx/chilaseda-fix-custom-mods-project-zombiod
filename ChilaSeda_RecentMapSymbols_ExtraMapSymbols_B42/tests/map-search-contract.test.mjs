import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaFile = path.join(modRoot, "42/media/lua/client/ChilaSeda_RecentMapSymbols.lua");
const vanillaEntryFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISTextEntryBox.lua";
const lua = fs.readFileSync(luaFile, "utf8");

test("map search instantiates its Java text control before getText", () => {
  const start = lua.indexOf("local function addSearchTab(");
  const end = lua.indexOf("local originalCreateChildren", start);
  assert.ok(start >= 0 && end > start, "map search constructor must exist");
  const constructor = lua.slice(start, end);
  const initialized = constructor.indexOf("searchEntry:initialise()");
  const instantiated = constructor.indexOf("searchEntry:instantiate()");
  const read = constructor.indexOf("searchEntry:getText()");
  assert.ok(initialized >= 0 && instantiated > initialized && read > instantiated,
    "search entry must initialize, instantiate, and only then read its Java text");

  const vanilla = fs.readFileSync(vanillaEntryFile, "utf8");
  assert.match(vanilla, /function ISTextEntryBox:getText\(\)\s*return self\.javaObject:getText\(\)/);
});

test("map initializes the search tab from createChildren only once", () => {
  assert.match(lua, /local originalCreateChildren = ISWorldMapSymbols\.createChildren\s+ISWorldMapSymbols\.createChildren = function\(symbolsUI, \.\.\.\)[\s\S]*?originalCreateChildren\(symbolsUI, \.\.\.\)[\s\S]*?addSearchTab\(symbolsUI\)/);
  assert.match(lua, /if symbolsUI\.searchSymbolsView or not symbolsUI\.panel then return end/);
});

test("map search has an X button that clears text and refreshes suggestions", () => {
  const constructor = lua.slice(lua.indexOf("local function addSearchTab("), lua.indexOf("local originalCreateChildren"));
  assert.match(constructor, /searchEntry:setPlaceholderText\(getText\("IGUI_ChilaSeda_SearchMapSymbols"\)\)/);
  assert.match(constructor, /clearSearchButton[\s\S]*?buttonHeight, "X"[\s\S]*?searchEntry:setText\(""\)/);
  assert.match(constructor, /view\.lastSearchText = ""[\s\S]*?refreshSearchSuggestions\(symbolsUI\)[\s\S]*?refreshSearchTab\(symbolsUI\)/);
  assert.doesNotMatch(constructor, /searchEntry\.tooltip\s*=/);
  assert.doesNotMatch(constructor, /view\.searchMessage = getText\("IGUI_ChilaSeda_SearchMapSymbolsHint"\)/);
});

test("zoom reset updates its button and never calls setTitle on the view target", () => {
  const constructor = lua.slice(lua.indexOf("local function addSearchTab("), lua.indexOf("local originalCreateChildren"));
  assert.match(constructor, /local zoomLabel\s+zoomLabel = ISButton:new[\s\S]*?function\(\)[\s\S]*?zoomLabel:setTitle\("100%"\)/);
  assert.doesNotMatch(constructor, /function\(self\)[\s\S]{0,100}self:setTitle\("100%"\)/);
});

test("zoom limits results to rows that fit inside the search panel", () => {
  const refresh = lua.slice(lua.indexOf("local function refreshSearchTab("), lua.indexOf("local SEARCH_SUGGESTIONS"));
  assert.match(refresh, /view:getHeight\(\) - y - UI_BORDER_SPACING/);
  assert.match(refresh, /local displayLimit = math\.min\(MAX_SEARCH_RESULTS, fitRows \* columns\)/);
  assert.match(refresh, /math\.min\(matchCount, displayLimit\)/);
});
