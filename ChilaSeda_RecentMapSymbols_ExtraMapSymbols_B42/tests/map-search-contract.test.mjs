import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaFile = path.join(modRoot, "42/media/lua/client/ChilaSeda_RecentMapSymbols.lua");
const vanillaEntryFile = "J:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISTextEntryBox.lua";
const gameJar = "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const harnessSource = path.join(modRoot, "tests/LuaCompileContract.java");
const lua = fs.readFileSync(luaFile, "utf8");

test("map symbols Lua compiles with the game's Kahlua compiler", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(path.join(jdkBin, "javac.exe")), `JDK compiler not found: ${jdkBin}`);
  const tempRoot = path.resolve(os.tmpdir());
  const tempDir = fs.mkdtempSync(path.join(tempRoot, "map-symbols-kahlua-"));
  try {
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", luaFile],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Map symbols Kahlua syntax compile passed/);
  } finally {
    assert.ok(tempDir.startsWith(tempRoot + path.sep), "temporary compiler output must stay under OS temp");
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

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

test("search zoom and layout controls update shared state and refresh the results", () => {
  const constructor = lua.slice(lua.indexOf("local function addSearchTab("), lua.indexOf("local originalCreateChildren"));
  assert.match(constructor, /local zoomLabel\s+zoomLabel = ISButton:new[\s\S]*?setSymbolZoom\(symbolsUI, 1\)/);
  assert.match(constructor, /view\.searchLayout = "list"/);
  assert.match(constructor, /view\.searchLayout = view\.searchLayout == "grid" and "list" or "grid"/);
  assert.match(constructor, /searchLayoutButton:setTitle\(getText\("IGUI_ChilaSeda_MapSearchList"\)\)/);
  assert.match(constructor, /searchLayoutButton:setTitle\(getText\("IGUI_ChilaSeda_MapSearchGrid"\)\)/);
  assert.doesNotMatch(constructor, /function\(self\)[\s\S]{0,100}self:setTitle\("100%"\)/);
});

test("search grid centers icons, shows names on hover, and scrolls within its panel", () => {
  const refresh = lua.slice(lua.indexOf("refreshSearchTab = function("), lua.indexOf("local function updateSymbolButtonTooltips"));
  assert.match(refresh, /local isGrid = view\.searchLayout == "grid"/);
  assert.match(refresh, /columns = math\.max\(1, math\.floor\(\(availableWidth \+ gap\) \/ \(cardWidth \+ gap\)\)\)/);
  assert.match(refresh, /local iconX = isGrid and math\.floor\(\(self\.width - iconSize\) \/ 2\) or 4/);
  assert.match(refresh, /if not isGrid then[\s\S]*?self:drawText\(label/);
  assert.match(refresh, /button\.tooltip = displayName/);
  assert.match(refresh, /view\.setScrollHeight, view/);
  assert.match(refresh, /view\.setYScroll, view, 0/);
  assert.match(refresh, /local displayLimit = MAX_SEARCH_RESULTS/);
});

test("shared zoom reflows every vanilla, recent, and mod-added symbol tab", () => {
  const layout = lua.slice(lua.indexOf("applySymbolButtonLayout = function("), lua.indexOf("local SEARCH_SUGGESTIONS"));
  assert.match(layout, /for _, button in ipairs\(symbolsUI\.buttonList or \{\}\) do/);
  assert.match(layout, /button\.symbol and button\.tab ~= "SearchSymbols" and view and view\.ID/);
  assert.match(layout, /view:clearJoypadButtonsList\(\)/);
  assert.match(layout, /button:setWidth\(cellSize\)/);
  assert.match(layout, /button\.forcedWidthImage = math\.max\(1, cellSize - 2\)/);
  assert.match(layout, /columns = math\.max\(1, math\.min\(8,/);
  assert.match(layout, /view:setScrollHeight\(math\.max\(view\.height, contentBottom\)\)/);
  assert.match(layout, /result=fallback reason=/);
  assert.match(lua, /ISWorldMapSymbols\.createChildren = function\(symbolsUI, \.\.\.\)[\s\S]*?applySymbolButtonLayout\(symbolsUI\)/);
});

test("symbol zoom controls stay pinned while tab contents scroll", () => {
  assert.match(lua, /local function pinControlsAtTop\(view, controls\)/);
  assert.match(lua, /control\.chilaPinnedY - scroll/);
  assert.match(lua, /event=layout tab=/);
  assert.match(lua, /event=search-layout mode=/);
  assert.match(lua, /event=zoom result=applied percent=/);
});

test("all map-symbol JSON catalogs parse, have no duplicate keys, and translate the new controls", () => {
  const catalogPaths = ["EN/IG_UI.json", "ES/IG_UI.json", "ES_MX/IG_UI.json"]
    .map((relative) => path.join(modRoot, "42/media/lua/shared/Translate", relative));
  const requiredKeys = [
    "IGUI_ChilaSeda_MapSearchZoomResetHint",
    "IGUI_ChilaSeda_MapSearchGrid",
    "IGUI_ChilaSeda_MapSearchList",
    "IGUI_ChilaSeda_MapSearchShowGrid",
    "IGUI_ChilaSeda_MapSearchShowList",
  ];
  for (const file of catalogPaths) {
    const raw = fs.readFileSync(file, "utf8");
    const catalog = JSON.parse(raw);
    const keys = [...raw.matchAll(/^\s*"([^"]+)"\s*:/gm)].map((match) => match[1]);
    assert.equal(new Set(keys).size, keys.length, `${path.basename(path.dirname(file))} has duplicate keys`);
    for (const key of requiredKeys) assert.ok(Object.hasOwn(catalog, key), `${file} is missing ${key}`);
    assert.equal(
      catalog.IGUI_ChilaSeda_MapSearchZoomResetHint.endsWith("100%%"),
      true,
      `${file} must escape the literal percent for getText formatting`,
    );
  }
});

test("legacy translation files include the grid and list controls", () => {
  for (const file of ["EN/UI_EN.txt", "ES/UI_ES.txt", "ES_MX/UI_ES_MX.txt"]) {
    const text = fs.readFileSync(path.join(modRoot, "42/media/lua/shared/Translate", file), "utf8");
    assert.match(text, /IGUI_ChilaSeda_MapSearchGrid\s*=/);
    assert.match(text, /IGUI_ChilaSeda_MapSearchList\s*=/);
    assert.match(text, /IGUI_ChilaSeda_MapSearchShowGrid\s*=/);
    assert.match(text, /IGUI_ChilaSeda_MapSearchShowList\s*=/);
    assert.match(text, /IGUI_ChilaSeda_MapSearchZoomResetHint\s*=\s*"[^"]*100%%"/);
  }
});

test("the map symbols patch keeps B42 and Workshop load dependencies", () => {
  const info = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
  assert.match(info, /loadModAfter=MapSymbolSizeSlider,ExtraSymbols/);
  assert.match(info, /versionMin=42\.20/);
  assert.match(info, /modversion=0\.3\.7/);
});
