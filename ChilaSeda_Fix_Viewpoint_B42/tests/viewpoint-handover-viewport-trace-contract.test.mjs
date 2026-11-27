import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const sourcePath = path.join(
  modRoot,
  "Source/chilaseda/viewpointhalo/ViewpointHandoverViewportTrace.java",
);
const harnessPath = path.join(
  modRoot,
  "tests/ViewpointHandoverViewportTraceContract.java",
);
const source = fs.readFileSync(sourcePath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const buddyJar =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";

test("Viewpoint handover trace distinguishes partial viewport and logs compositor state", () => {
  assert.match(source, /className = "viewpoint\.render\.HandOver"/);
  assert.match(source, /methodName = "draw"/);
  assert.match(source, /GL11\.GL_VIEWPORT/);
  assert.match(source, /GL11\.GL_SCISSOR_BOX/);
  assert.match(source, /hook-active due=/);
  assert.match(source, /MAX_SAMPLES = 120/);
  assert.match(source, /SAMPLE_INTERVAL_NANOS = 5_000_000_000L/);
  assert.match(source, /public static void beforeHandover\(\) \{\s*runBeforeHandover\(\);\s*\}/);
  assert.match(source, /public static void afterHandover\([\s\S]*?\) \{\s*runAfterHandover\(failure\);\s*\}/);
  assert.match(source, /private static final AtomicInteger SAMPLE_COUNT/);
  assert.match(modInfo, /modversion=2\.0\.159/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-handover-trace-"));
  try {
    execFileSync(
      path.join(jdkBin, "javac.exe"),
      ["-classpath", `${gameJar};${buddyJar}`, "-d", tempDir, sourcePath, harnessPath],
      { stdio: "pipe" },
    );
    const output = execFileSync(
      path.join(jdkBin, "java.exe"),
      [
        "-classpath",
        `${gameJar};${buddyJar};${tempDir}`,
        "viewpoint.render.ViewpointHandoverViewportTraceContract",
      ],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(output, /Viewpoint handover viewport trace contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
