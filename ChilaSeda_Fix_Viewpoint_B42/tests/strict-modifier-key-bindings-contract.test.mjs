import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

const modRoot = path.resolve(import.meta.dirname, "..");
const sourcePath = path.join(
  modRoot,
  "Source/chilaseda/viewpointhalo/StrictModifierKeyBindings.java",
);
const source = fs.readFileSync(sourcePath, "utf8");
const modInfo = fs.readFileSync(path.join(modRoot, "42/mod.info"), "utf8");
const javaArchiveLine = modInfo.match(/^javaJarFile=(.+)$/m)?.[1];

test("Core's injected hook delegates without reading private modifier state", () => {
  const handler = source.match(
    /@Patch\.OnEnter\(skipOn = true\)\s*public static boolean rejectBaseBindingWhenExtraModifierIsDown\([\s\S]*?\n    }/,
  )?.[0];
  assert.ok(handler, "missing Core's injected hook");
  assert.match(handler, /return shouldSuppress\(binding\);/);
  assert.doesNotMatch(handler, /LOG_TAG|LOGGED_SUPPRESSED_KEYS|last(?:Ctrl|Alt|Shift)/);
  assert.match(source, /public static boolean shouldSuppress\(Core\.KeyBinding binding\)/);
});

test("the 2.0.116 Java archive retains the modifier helper and forage bridge", () => {
  assert.equal(modInfo.match(/^modversion=(.+)$/m)?.[1], "2.0.116");
  assert.equal(
    javaArchiveLine,
    "media/java/client/ChilaSedaViewpointHalo-2.0.116.jar",
  );

  const archivePath = path.join(modRoot, "42", javaArchiveLine);
  assert.ok(fs.existsSync(archivePath), `missing selected Java archive: ${archivePath}`);

  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const extractionDir = fs.mkdtempSync(path.join(os.tmpdir(), "viewpoint-contract-"));
  try {
    execFileSync(
      path.join(jdkBin, "jar.exe"),
      ["xf", archivePath, "chilaseda/viewpointhalo/StrictModifierKeyBindings.class"],
      { cwd: extractionDir },
    );
    const classFile = path.join(
      extractionDir,
      "chilaseda/viewpointhalo/StrictModifierKeyBindings.class",
    );
    const signature = execFileSync(path.join(jdkBin, "javap.exe"), ["-p", classFile], {
      encoding: "utf8",
    });
    assert.match(signature, /public static boolean isDown\(int, int\);/);
    assert.match(signature, /public static boolean shouldSuppress\(zombie\.core\.Core\$KeyBinding\);/);
    assert.match(signature, /static boolean logModifierTransition\(/);
    assert.match(signature, /static boolean logSuppressedBinding\(/);

    const bytecode = execFileSync(path.join(jdkBin, "javap.exe"), ["-c", "-p", classFile], {
      encoding: "utf8",
    });
    const hookBytecode = bytecode
      .split("public static boolean rejectBaseBindingWhenExtraModifierIsDown")[1]
      ?.split("\n  public static boolean shouldSuppress")[0];
    assert.ok(hookBytecode, "missing injected hook bytecode");
    assert.match(hookBytecode, /invokestatic .*shouldSuppress/);
    assert.doesNotMatch(hookBytecode, /LOGGED_SUPPRESSED_KEYS/);

    const bridgeClass = path.join(path.dirname(classFile), "ForageTuningBridge.class");
    execFileSync(
      path.join(jdkBin, "jar.exe"),
      ["xf", archivePath, "chilaseda/viewpointhalo/ForageTuningBridge.class"],
      { cwd: extractionDir },
    );
    const bridgeSignature = execFileSync(path.join(jdkBin, "javap.exe"), ["-p", bridgeClass], {
      encoding: "utf8",
    });
    assert.match(bridgeSignature, /isNativeTuningAvailable\(\)/);
    assert.match(bridgeSignature, /setNativePinTuning\(double, double\)/);
  } finally {
    fs.rmSync(extractionDir, { recursive: true, force: true });
  }
});

test("modifier runtime diagnostics include transitions and suppressed-key values", () => {
  assert.match(source, /logModifierTransition\("CTRL"/);
  assert.match(source, /logModifierTransition\("ALT"/);
  assert.match(source, /logModifierTransition\("SHIFT"/);
  assert.match(source, /base binding suppressed keyCode=/);
  assert.match(source, /heldModifiers=\[ctrl:/);
  assert.match(source, /bindingModifiers=\[ctrl:/);
  assert.match(source, /!loggedKeys\.add\(key\)/);
});

test("modifier diagnostics log once per transition and once per physical key press", () => {
  const jdkBin = path.resolve(modRoot, "../.tools/jdk-25.0.5/bin");
  const gameJar = process.env.PZ_PROJECT_ZOMBOID_JAR
    ?? "J:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar";
  const buddyJar = "J:/SteamLibrary/steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar";
  assert.ok(fs.existsSync(gameJar), `Project Zomboid Java archive not found: ${gameJar}`);
  assert.ok(fs.existsSync(buddyJar), `ZombieBuddy Java archive not found: ${buddyJar}`);

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "modifier-diagnostics-contract-"));
  try {
    const harness = path.join(modRoot, "tests/StrictModifierKeyDiagnosticsContract.java");
    execFileSync(
      path.join(jdkBin, "javac.exe"),
      ["-classpath", `${gameJar};${buddyJar}`, "-d", tempDir, sourcePath, harness],
    );
    const result = execFileSync(
      path.join(jdkBin, "java.exe"),
      ["-classpath", `${gameJar};${buddyJar};${tempDir}`, "chilaseda.viewpointhalo.StrictModifierKeyDiagnosticsContract"],
      { cwd: path.dirname(gameJar), encoding: "utf8" },
    );
    assert.match(result, /Strict modifier diagnostics contracts passed/);
  } finally {
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
