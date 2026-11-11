import fs from "node:fs";
import { spawn, spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const hookDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(hookDirectory, "../..");

function readHookInput() {
  return new Promise((resolve) => {
    let input = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => { input += chunk; });
    process.stdin.on("end", () => {
      try { resolve(JSON.parse(input)); } catch { resolve({}); }
    });
    process.stdin.on("error", () => resolve({}));
  });
}

function writeResult(result) {
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

function dateInMexicoCity(date = new Date()) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function paths() {
  return {
    marker: path.join(hookDirectory, "graphify-update-last-date.txt"),
    lock: path.join(hookDirectory, "graphify-update.lock"),
    log: path.join(hookDirectory, "graphify-update.log"),
  };
}

function localInterpreter() {
  const pointerPath = path.join(projectRoot, "graphify-out", ".graphify_python");
  const configuredPath = fs.readFileSync(pointerPath, "utf8").trim();
  if (!configuredPath) throw new Error("graphify-out/.graphify_python is empty");

  const resolvedPath = path.resolve(projectRoot, configuredPath);
  const relativePath = path.relative(projectRoot, resolvedPath);
  if (!relativePath || relativePath === ".." || relativePath.startsWith(`..${path.sep}`)
      || path.isAbsolute(relativePath)) {
    throw new Error("configured runtime is outside the mods workspace");
  }
  if (!fs.existsSync(resolvedPath)) throw new Error(`local runtime does not exist: ${relativePath}`);
  return `.${path.sep}${relativePath}`;
}

function runUpdate() {
  const result = spawnSync(localInterpreter(), ["-m", "graphify", "update", "."], {
    cwd: projectRoot,
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
    timeout: 600_000,
    windowsHide: true,
  });
  if (result.error || result.status !== 0) {
    const detail = (result.stderr || result.stdout || result.error?.message || "").trim();
    throw new Error(detail ? detail.slice(-1200) : `Graphify exited ${result.status ?? "unknown"}`);
  }
}

async function runWorker(date) {
  const state = paths();
  try {
    if (date !== dateInMexicoCity()) throw new Error("local date changed before update started");
    runUpdate();
    const temporaryMarker = `${state.marker}.${process.pid}.tmp`;
    fs.writeFileSync(temporaryMarker, `${date}\n`, "utf8");
    fs.renameSync(temporaryMarker, state.marker);
    fs.appendFileSync(state.log, `${new Date().toISOString()} OK ${date}\n`, "utf8");
  } catch (error) {
    fs.appendFileSync(state.log, `${new Date().toISOString()} FAILED ${date}: ${error.message}\n`, "utf8");
  } finally {
    try { fs.unlinkSync(state.lock); } catch { /* lock may already be gone */ }
  }
}

async function main() {
  if (process.argv[2] === "--worker") {
    await runWorker(process.argv[3]);
    return;
  }

  await readHookInput();
  const state = paths();
  const today = dateInMexicoCity();
  if (fs.existsSync(state.marker) && fs.readFileSync(state.marker, "utf8").trim() === today) {
    writeResult({});
    return;
  }
  if (!fs.existsSync(path.join(projectRoot, "graphify-out", "graph.json"))) {
    writeResult({});
    return;
  }

  let lockFd;
  try {
    lockFd = fs.openSync(state.lock, "wx");
    fs.writeSync(lockFd, `${today} ${process.pid}\n`);
    fs.closeSync(lockFd);
    lockFd = undefined;
  } catch (error) {
    if (lockFd !== undefined) fs.closeSync(lockFd);
    if (error.code === "EEXIST") {
      try {
        if (Date.now() - fs.statSync(state.lock).mtimeMs > 30 * 60 * 1000) {
          fs.unlinkSync(state.lock);
          writeResult({ systemMessage: "Graphify dejó un lock vencido; se intentará de nuevo en el siguiente inicio." });
          return;
        }
      } catch { /* lock disappeared during check */ }
      writeResult({});
      return;
    }
    throw error;
  }

  const worker = spawn(process.execPath, [fileURLToPath(import.meta.url), "--worker", today], {
    cwd: projectRoot,
    detached: true,
    stdio: "ignore",
    windowsHide: true,
  });
  worker.once("error", (error) => {
    fs.appendFileSync(state.log, `${new Date().toISOString()} FAILED launch: ${error.message}\n`, "utf8");
    try { fs.unlinkSync(state.lock); } catch { /* lock may already be gone */ }
  });
  worker.unref();
  writeResult({});
}

main().catch((error) => {
  writeResult({ systemMessage: `Graphify no se inició: ${error.message}` });
});
