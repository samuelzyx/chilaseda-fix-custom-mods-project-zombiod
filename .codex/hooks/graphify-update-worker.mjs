import fs from "node:fs";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const hookDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(hookDirectory, "../..");
const logPath = path.join(hookDirectory, "graphify-update.log");
const lockPath = path.join(hookDirectory, "graphify-update.lock");

function log(text) {
  fs.appendFileSync(logPath, `${new Date().toISOString()} ${text}\n`, "utf8");
}

function localInterpreter() {
  const pointerPath = path.join(projectRoot, "graphify-out", ".graphify_python");
  const configuredPath = fs.readFileSync(pointerPath, "utf8").trim();
  if (!configuredPath) throw new Error("graphify-out/.graphify_python está vacío");

  const resolvedPath = path.resolve(projectRoot, configuredPath);
  const relativePath = path.relative(projectRoot, resolvedPath);
  if (
    !relativePath ||
    relativePath === ".." ||
    relativePath.startsWith(`..${path.sep}`) ||
    path.isAbsolute(relativePath)
  ) {
    throw new Error("el runtime configurado no está dentro del workspace mods");
  }

  const executable = `.${path.sep}${relativePath}`;
  if (!fs.existsSync(resolvedPath)) throw new Error(`no existe el runtime local: ${relativePath}`);
  return executable;
}

let lockFd;
try {
  try {
    lockFd = fs.openSync(lockPath, "wx");
  } catch (error) {
    if (error.code !== "EEXIST") throw error;
    const ageMs = Date.now() - fs.statSync(lockPath).mtimeMs;
    if (ageMs < 600_000) {
      log("SKIPPED: a Graphify update is already running");
      process.exit(0);
    }
    fs.rmSync(lockPath, { force: true });
    lockFd = fs.openSync(lockPath, "wx");
  }
  fs.writeFileSync(lockFd, `${process.pid}\n`, "utf8");
  fs.closeSync(lockFd);
  lockFd = undefined;
  log(`START pid=${process.pid}`);

  const result = spawnSync(localInterpreter(), ["-m", "graphify", "update", "."], {
    cwd: projectRoot,
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
    timeout: 600_000,
    windowsHide: true,
  });

  const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
  if (result.error || result.status !== 0) {
    log(`FAILED exit=${result.status ?? "unknown"} ${result.error?.message ?? ""}\n${output}`);
    process.exitCode = 1;
  } else {
    log(`OK\n${output}`);
  }
} catch (error) {
  log(`FAILED ${error.stack ?? error.message}`);
  process.exitCode = 1;
} finally {
  if (lockFd !== undefined) fs.closeSync(lockFd);
  fs.rmSync(lockPath, { force: true });
}
