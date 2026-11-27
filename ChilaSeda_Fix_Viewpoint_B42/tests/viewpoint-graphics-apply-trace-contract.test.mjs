import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const sourcePath = path.join(
  modRoot,
  "Source/chilaseda/viewpointhalo/ViewpointGraphicsApplyTrace.java",
);
const harnessPath = path.join(modRoot, "tests/ViewpointGraphicsApplyTraceContract.java");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
  ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
const buddyJar =
  "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";

test("Viewpoint graphics settings apply trace reports state, duration, and failure fallback", () => {
  assert.match(sourcePath && fs.readFileSync(sourcePath, "utf8"), /methodName = "changed"/);
  assert.match(modInfo, /modversion=2\.0\.159/);
  const traceSource = fs.readFileSync(sourcePath, "utf8");
  assert.match(traceSource, /public static final ThreadLocal<Long> START_NANOS/);
  assert.match(traceSource, /public static volatile Supplier<String> shownReader/);
  assert.match(traceSource, /public static String settingsShown\(\)/);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-settings-trace-"));
  try {
    execFileSync(
      path.join(jdkBin, "javac.exe"),
      ["-classpath", `${gameJar};${buddyJar}`, "-d", tempDir, sourcePath, harnessPath],
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      [
        "-classpath",
        `${gameJar};${buddyJar};${tempDir}`,
        "viewpoint.platform.ViewpointGraphicsApplyTraceContract",
      ],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Viewpoint graphics apply trace contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
