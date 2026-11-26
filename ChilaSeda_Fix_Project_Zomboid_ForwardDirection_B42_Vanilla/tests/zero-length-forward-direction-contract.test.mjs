import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const sourcePath = path.join(modRoot, "Source/chilaseda/viewpointfixes/forwarddirection/ZeroLengthForwardDirectionGuard.java");
const source = fs.readFileSync(sourcePath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const jarLine = modInfo.match(/^javaJarFile=(.+)$/m)?.[1];
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const buddyJar = "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";

test("the vanilla guard skips only an exactly zero direction and preserves other inputs", () => {
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(buddyJar), `ZombieBuddy Java archive not found: ${buddyJar}`);
  const tempDir = path.resolve(modRoot, "../.tmp-forward-direction-contract");
  try {
    fs.mkdirSync(tempDir, { recursive: true });
    const harness = path.join(modRoot, "tests/ZeroLengthForwardDirectionGuardContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", `${gameJar};${buddyJar}`, "-d", tempDir, sourcePath,
    ]);
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", `${tempDir};${gameJar};${buddyJar}`, "-d", tempDir, harness,
    ]);
    const result = execFileSync(path.join(jdkBin, "java.exe"), [
      "-classpath", `${gameJar};${buddyJar};${tempDir}`,
      "chilaseda.viewpointfixes.forwarddirection.ZeroLengthForwardDirectionGuardContract",
    ], { cwd: path.dirname(gameJar), encoding: "utf8" });
    assert.match(result, /Zero-length forward-direction contract passed/);
    const bytecode = execFileSync(path.join(jdkBin, "javap.exe"), [
      "-classpath", `${tempDir};${gameJar};${buddyJar}`, "-v",
      "chilaseda.viewpointfixes.forwarddirection.ZeroLengthForwardDirectionGuard",
    ], { encoding: "utf8" });
    assert.match(bytecode, /descriptor: \(Lzombie\/characters\/IsoGameCharacter;Lzombie\/iso\/Vector2;\)Z/);
    assert.match(bytecode, /Lme\/zed_0xff\/zombie_buddy\/Patch\$OnEnter;/);
    assert.match(bytecode, /Lme\/zed_0xff\/zombie_buddy\/Patch\$This;/);
    assert.match(bytecode, /Lme\/zed_0xff\/zombie_buddy\/Patch\$Argument;/);
    assert.match(bytecode, /public static boolean shouldSkip\(zombie\.iso\.Vector2\)/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("the patch is narrow, bounded, documented, and selected after ZombieBuddy", () => {
  assert.match(source, /methodName = "setForwardDirection"/);
  assert.match(source, /@OnEnter\(skipOn = true\)/);
  assert.match(source, /direction\.getLengthSquared\(\) == 0\.0f/);
  assert.match(source, /public static boolean shouldSkip\(Vector2 direction\)/);
  assert.match(source, /fallback=preserve-current-facing/);
  assert.match(source, /MAX_TRACE_LINES = 32/);
  assert.match(source, /TRACE_ENABLED = true/);
  assert.match(source, /public static void setTraceEnabled\(boolean enabled\)/);
  assert.match(source, /TRACE_LINES\.getAndIncrement\(\)/);
  assert.match(modInfo, /^require=ZombieBuddy$/m);
  assert.match(modInfo, /^loadModAfter=ZombieBuddy$/m);
  assert.equal(jarLine, "media/java/client/ChilaSedaForwardDirectionFix.jar");
  const jarPath = path.join(modRoot, "42", jarLine);
  assert.ok(fs.existsSync(jarPath), `selected local Java archive not found: ${jarPath}`);
  const listing = execFileSync(path.join(jdkBin, "jar.exe"), ["tf", jarPath], { encoding: "utf8" });
  assert.ok(listing.split(/\r?\n/).includes(
    "chilaseda/viewpointfixes/forwarddirection/ZeroLengthForwardDirectionGuard.class",
  ));
});
