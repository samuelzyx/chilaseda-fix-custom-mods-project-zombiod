import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const tracePath = path.join(
  modRoot,
  "42/media/lua/client/zzzz_ChilaSeda_AnomalousStorm_HudTrace.lua",
);

test("HUD trace records storm-only, bounded UI and camera metrics through Kahlua", () => {
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "anomalous-storm-hud-trace-"));
  try {
    const harness = path.join(modRoot, "tests/AnomalousStormHudTraceKahluaContract.java");
    execFileSync(path.join(jdkBin, "javac.exe"), ["-classpath", gameJar, "-d", tempDir, harness]);
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "AnomalousStormHudTraceKahluaContract", tracePath],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Anomalous storm HUD trace Kahlua contract passed/);
    const unavailableBridgeResult = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${tempDir}`, "AnomalousStormHudTraceKahluaContract", tracePath, "no-bind-class"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(unavailableBridgeResult, /Anomalous storm HUD trace Kahlua contract passed/);
    assert.match(unavailableBridgeResult, /unavailable bindClass assertions passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});

test("diagnostic is enabled by the existing local storm mod and documents its limits", () => {
  const info = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
  const readme = fs.readFileSync(path.join(modRoot, "README.md"), "utf8");
  const trace = fs.readFileSync(tracePath, "utf8");
  assert.match(info, /^modversion=0\.4\.26$/m);
  assert.match(info, /^loadModAfter=.*Viewpoint/m);
  assert.match(readme, /HUD Trace/);
  assert.match(readme, /event=metrics-change/);
  assert.match(trace, /MAX_SAMPLES = 120/);
  assert.match(trace, /MAX_CHANGES = 80/);
  assert.match(trace, /javaBindingUnavailable = false/);
  assert.match(trace, /logFallback\("luajava\.bindClass", "unavailable"\)/);
});
