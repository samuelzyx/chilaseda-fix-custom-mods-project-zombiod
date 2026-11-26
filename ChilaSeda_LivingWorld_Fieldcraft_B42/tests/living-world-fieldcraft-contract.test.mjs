import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const root = path.resolve(import.meta.dirname, "..");
const source = fs.readFileSync(path.join(root, "42/media/lua/server/ChilaSeda_LivingWorldFieldcraft.lua"), "utf8");
const info = fs.readFileSync(path.join(root, "42/mod.info"), "utf8");
const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");

test("loads Living World's registered fishing job and preserves native catch results", () => {
  assert.match(source, /pcall\(require, "LivingWorld\/Fishing"\)/);
  assert.match(source, /FishingJob\.catch = function\(level, lure, x, y\)/);
  assert.match(source, /return item, isTrash/);
  assert.match(source, /result=.*no-bite/);
  assert.match(info, /^require=LivingWorld,ChilaSeda_AnomalousStorm_B42$/m);
  assert.match(info, /^loadModAfter=LivingWorld,ChilaSeda_AnomalousStorm_B42$/m);
});

test("red storm warning and rain reuse native shelter routing without sending threatened NPCs", () => {
  assert.match(source, /state\.Warning == true/);
  assert.match(source, /state\.RainActive == true/);
  assert.match(source, /state\.Phase == "thunderstorm"/);
  assert.match(source, /square:isOutside\(\) and \(ctx\.threatCount or 0\) <= 0/);
  assert.match(source, /return math\.max\(ordinary or 0, 1\.25\)/);
  assert.match(source, /return nativeStart\(ctx\)/);
  assert.match(source, /Comfort\.shelterNear radius=20/);
  assert.match(source, /person\.order ~= "stay"/);
  assert.match(source, /ctx\.mind\.giveUpUntil and ctx\.now < ctx\.mind\.giveUpUntil/);
  assert.match(source, /mind\.action = "errand"/);
  assert.match(source, /mind\.action = previous/);
  assert.match(source, /scope=storm-shelter-only/);
});

test("diagnostics are bounded, toggleable, and documented", () => {
  assert.match(source, /local TRACE_ENABLED = true/);
  assert.match(source, /local TRACE_LIMIT = 128/);
  assert.match(source, /traceCount >= TRACE_LIMIT/);
  assert.match(source, /catchTraces < 32/);
  assert.match(readme, /TRACE_ENABLED/);
  assert.match(readme, /ChilaSeda_LivingWorldFieldcraft/);
});

test("the server integration compiles with the game's Kahlua compiler", () => {
  const jdkBin = path.resolve(root, "../.tools/jdk-25.0.5/bin");
  const gameJar = "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "lw-fieldcraft-kahlua-"));
  try {
    const harness = path.join(root, "tests/LuaCompileContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const result = execFileSync(path.join(jdkBin, "java.exe"), [
      "-classpath", `${gameJar};${tempDir}`, "LuaCompileContract",
      path.join(root, "42/media/lua/server/ChilaSeda_LivingWorldFieldcraft.lua"),
    ], { cwd: path.dirname(gameJar), encoding: "utf8" });
    assert.match(result, /Kahlua syntax compile passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
