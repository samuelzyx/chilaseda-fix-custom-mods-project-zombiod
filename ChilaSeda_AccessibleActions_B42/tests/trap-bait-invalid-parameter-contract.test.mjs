import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzz_ChilaSeda_TrapBaitMenuFilter.lua",
);
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");

test("trap bait filter skips callback parameters without raising or removing menu options", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  const lua = fs.readFileSync(luaPath, "utf8");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "trap-bait-filter-"));
  try {
    const harness = [
      "local callback, logs = nil, {}",
      "print = function(message) logs[#logs + 1] = tostring(message) end",
      "Events = { OnFillWorldObjectContextMenu = { Add = function(fn) callback = fn end } }",
      lua,
      "logs = {}",
      "local bad = { param1 = function() end, param2 = true, onSelect = function() end }",
      "local context = { options = { bad }, numOptions = 1 }",
      "callback(0, context, nil, false)",
      "assert(#context.options == 1, 'invalid callback argument must not remove the bait option')",
      "assert(context.numOptions == 1, 'invalid callback argument must not change menu count')",
      "assert(#logs == 1 and string.find(logs[1], 'paramType=function', 1, true), 'invalid callback is logged once')",
      "local tableParam = { param1 = {}, param2 = true, onSelect = function() end }",
      "context.options = { tableParam }; context.numOptions = 1",
      "callback(0, context, nil, false)",
      "assert(#context.options == 1 and context.numOptions == 1, 'non-item table must be ignored')",
      "assert(#logs == 1, 'invalid-parameter trace stays bounded')",
    ].join("\n");
    const harnessPath = path.join(tempDir, "trap-bait-filter-contract.lua");
    fs.writeFileSync(harnessPath, harness, "utf8");
    const javaHarness = path.join(modRoot, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, javaHarness]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "LuaCompileContract", harnessPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Kahlua contract passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
