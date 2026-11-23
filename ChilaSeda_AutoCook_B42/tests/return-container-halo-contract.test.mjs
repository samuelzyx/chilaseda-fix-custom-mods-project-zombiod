import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const mobilityPath = path.join(
  modRoot,
  "42/media/lua/client/ChilaSeda_AutoCookMobility.lua",
);
const mobilityLua = fs.readFileSync(mobilityPath, "utf8");
const locales = ["EN", "ES", "ES_MX"];

function parseJsonWithoutDuplicateKeys(source) {
  let index = 0;
  const skipWhitespace = () => {
    while (/\s/.test(source[index] ?? "")) index += 1;
  };
  const parseString = () => {
    const start = index;
    index += 1;
    while (index < source.length) {
      if (source[index] === "\\") {
        index += 2;
        continue;
      }
      if (source[index++] === '"') break;
    }
    return JSON.parse(source.slice(start, index));
  };
  const parseValue = () => {
    skipWhitespace();
    if (source[index] === "{") {
      index += 1;
      const keys = new Set();
      skipWhitespace();
      if (source[index] === "}") {
        index += 1;
        return;
      }
      while (index < source.length) {
        skipWhitespace();
        const key = parseString();
        assert.ok(!keys.has(key), `duplicate JSON key: ${key}`);
        keys.add(key);
        skipWhitespace();
        assert.equal(source[index++], ":", `expected colon after ${key}`);
        parseValue();
        skipWhitespace();
        const separator = source[index++];
        if (separator === "}") return;
        assert.equal(separator, ",", `expected comma after ${key}`);
      }
      assert.fail("unterminated JSON object");
    }
    if (source[index] === "[") {
      index += 1;
      skipWhitespace();
      if (source[index] === "]") {
        index += 1;
        return;
      }
      while (index < source.length) {
        parseValue();
        skipWhitespace();
        const separator = source[index++];
        if (separator === "]") return;
        assert.equal(separator, ",", "expected comma in JSON array");
      }
      assert.fail("unterminated JSON array");
    }
    if (source[index] === '"') {
      parseString();
      return;
    }
    const start = index;
    while (index < source.length && !/[\s,}\]]/.test(source[index])) index += 1;
    assert.ok(index > start, "expected a JSON value");
  };

  parseValue();
  skipWhitespace();
  assert.equal(index, source.length, "unexpected trailing JSON content");
  return JSON.parse(source);
}

test("return-container text uses the Project Zomboid %1 placeholder in all catalogs", () => {
  for (const locale of locales) {
    const catalogPath = path.join(
      modRoot,
      `42/media/lua/shared/Translate/${locale}/UI.json`,
    );
    const catalog = parseJsonWithoutDuplicateKeys(fs.readFileSync(catalogPath, "utf8"));
    const message = catalog.UI_ChilaSeda_AutoCook_ReturnedTo;
    assert.ok(message, `${locale} return-container message exists`);
    assert.equal((message.match(/%1/g) ?? []).length, 1, `${locale} has one %1 token`);
    assert.doesNotMatch(message, /\{\d+\}/, `${locale} has no unsupported brace placeholder`);
    assert.match(message.replace("%1", "Mochila de campo"), /Mochila de campo/);
  }
});

test("completion notices report item identity and suppress the same item and destination twice", () => {
  assert.match(mobilityLua, /ChilaSedaHaloNotices/);
  assert.match(mobilityLua, /local noticeKey = itemKey \.\. "\|" \.\. tostring\(destination\)/);
  assert.match(mobilityLua, /return notice duplicate suppressed item=/);
  assert.match(mobilityLua, /return notice item=/);
  assert.match(mobilityLua, /getText\("UI_ChilaSeda_AutoCook_ReturnedTo", destination\)/);
});

test("AutoCook mobility Lua compiles with the Project Zomboid Kahlua compiler", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "autocook-return-halo-"));
  try {
    const harness = path.resolve(
      modRoot,
      "../ChilaSeda_AccessibleActions_B42/tests/LuaCompileContract.java",
    );
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath",
      gameJar,
      "-d",
      tempDir,
      harness,
    ]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      [
        "-classpath",
        `${gameJar};${tempDir}`,
        "LuaCompileContract",
        mobilityPath,
        "--compile-only",
      ],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua syntax compile passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("mod metadata and README identify AutoCook 2.0.13", () => {
  const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
  const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
  assert.match(modInfo, /^modversion=2\.0\.13$/m);
  assert.match(readme.split(/\r?\n/, 1)[0], /2\.0\.13/);
  assert.match(readme, /Version 2\.0\.13:/);
});
