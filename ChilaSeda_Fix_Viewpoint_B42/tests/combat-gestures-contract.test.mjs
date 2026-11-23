import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const luaPath = path.join(
  modRoot,
  "42/media/lua/client/zzzzzz_ChilaSeda_ViewpointCombatGestures.lua",
);
const bridgePath = path.join(modRoot, "Source/chilaseda/viewpointhalo/CombatGesturesBridge.java");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const gestureLua = fs.readFileSync(luaPath, "utf8");

function gameJarPath() {
  return process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
}

function zombieBuddyJarPath() {
  return "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";
}

test("camera gestures classify bolado, vertical, reves, execution and reject short/slow strokes", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = gameJarPath();
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-kahlua-"));
  try {
    const harnessSource = path.join(modRoot, "tests/CombatGesturesKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harnessSource]);
    const runtimeClasspath = `${gameJar};${tempDir}`;
    execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", runtimeClasspath, "CombatGesturesKahluaContract", luaPath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("Java gesture bridge selects one vanilla attack and restores its original list", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = gameJarPath();
  const buddyJar = zombieBuddyJarPath();
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(buddyJar), `ZombieBuddy Java archive not found: ${buddyJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-gesture-bridge-"));
  try {
    const contract = path.join(modRoot, "tests/CombatGesturesBridgeContract.java");
    const classpath = `${gameJar};${buddyJar}`;
    execFileSync(path.join(jdkBin, "javac.exe"), [
      "-classpath", classpath, "-d", tempDir, bridgePath, contract,
    ]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${classpath};${tempDir}`, "chilaseda.viewpointhalo.CombatGesturesBridgeContract"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Combat gesture Java bridge contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("selected Viewpoint archive contains the exposed combat gesture bridge", () => {
  assert.match(modInfo, /^modversion=2\.0\.128$/m);
  const jarLine = modInfo.match(/^javaJarFile=(.+)$/m)?.[1];
  assert.equal(jarLine, "media/java/client/ChilaSedaViewpointHalo-2.0.122.jar");
  const archive = path.join(modRoot, "42", jarLine);
  assert.ok(fs.existsSync(archive), `selected Java archive not found: ${archive}`);

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const listing = execFileSync(path.join(jdkBin, "jar.exe"), ["tf", archive], { encoding: "utf8" });
  assert.ok(listing.split(/\r?\n/).includes("chilaseda/viewpointhalo/CombatGesturesBridge.class"));
});

test("gesture activation uses Ctrl, samples a sub-second stroke, and arms on left click", () => {
  assert.match(gestureLua, /local MAX_STROKE_MS = 900/);
  assert.match(gestureLua, /local function controlIsDown\(\)[\s\S]*?Keyboard\.KEY_LCONTROL[\s\S]*?Keyboard\.KEY_RCONTROL/);
  assert.match(gestureLua, /Events\.OnMouseDown\.Add\(onMouseDown\)/);
  assert.match(gestureLua, /local function leftMouseDown\(\)[\s\S]*?bridge\.leftMouseDown/);
  assert.match(gestureLua, /if not pending or nowMs\(\) > pending\.expires or not leftMouseDown\(\) then return end/);
});

test("gesture attack override restores vanilla choices and writes runtime diagnostics", () => {
  assert.match(gestureLua, /bridge\.armAttack, player, gesture\.kind/);
  assert.match(gestureLua, /bridge\.restoreAttackOverride, reason/);
  assert.match(gestureLua, /restoreAttackOverride\("vanilla selected the gesture"\)/);
  assert.match(gestureLua, /restoreAttackOverride\("click did not start an attack"\)/);
  assert.match(gestureLua, /restoreAttackOverride\("game paused"\)/);
  assert.doesNotMatch(gestureLua, /luajava\.bindClass/);
  for (const marker of [
    "ready; mouse capture and vanilla attack bridge connected",
    "capture started source=org.lwjglx.input.Mouse.getDX/getDY",
    "capture ended points=",
    "recognized ",
    "armed ",
    "attack started with gesture ",
    "gesture stayed vanilla: ",
    "vanilla choices restored",
  ]) {
    assert.ok(gestureLua.includes(marker), `missing DebugLog marker: ${marker}`);
  }
});
