import { spawn, spawnSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const checkerPath = path.join(projectRoot, "tools", "Check-WorkshopFixUpdates.ps1");
const stateRoot = path.join(
  process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local"),
  "ZomboidWorkshopFixHook",
);
const logPath = path.join(stateRoot, "hook.log");
const validClients = new Set(["copilot", "claude", "codex"]);

function log(message) {
  fs.mkdirSync(stateRoot, { recursive: true });
  fs.appendFileSync(logPath, `${new Date().toISOString()} ${message}\n`, "utf8");
}

function isProjectPath(value) {
  if (typeof value !== "string" || !value) return false;
  const cwd = path.resolve(value).toLowerCase();
  const root = projectRoot.toLowerCase();
  const relative = path.relative(root, cwd);
  return relative === "" || (!relative.startsWith(`..${path.sep}`) && relative !== "..");
}

function isBugReview(prompt) {
  const issue = /\b(?:bugs?|errors?|errores?|fall(?:a|o|as|os)?|crashes?|exceptions?|stack[\s-]?traces?|logs?|console\.txt|debuglog|errorlogs?)\b/i;
  const action = /\b(?:resolver|resuelve|resolviendo|arreglar|arregla|corregir|corrige|depurar|debug(?:ging)?|diagnosticar|diagnostica|investigar|investiga|revisar|revisa|analizar|analiza|reproducir|reproduce|solucionar|soluciona|fix(?:ing)?|diagnose|troubleshoot|investigate|review|analy[sz]e)\b/i;
  return issue.test(prompt) && action.test(prompt);
}

function steamIsOpen() {
  const executable = process.platform === "win32" ? "tasklist.exe" : "pgrep";
  const args =
    process.platform === "win32"
      ? ["/FI", "IMAGENAME eq steam.exe", "/NH"]
      : ["-x", "steam"];
  const result = spawnSync(executable, args, {
    encoding: "utf8",
    timeout: 3000,
    windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0 && result.status !== 1) {
    throw new Error(`Steam process check failed with exit code ${result.status}.`);
  }
  return result.stdout.toLowerCase().includes("steam.exe") ||
    (process.platform !== "win32" && result.status === 0);
}

function markerFor(client, sessionId) {
  const hash = crypto.createHash("sha256").update(`${client}:${sessionId}`).digest("hex");
  return path.join(stateRoot, `${hash}.started`);
}

function runChecker(markerPath) {
  const args = [
    "-NoProfile",
    "-NonInteractive",
    "-WindowStyle",
    "Hidden",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    checkerPath,
  ];
  const result = spawnSync("powershell.exe", args, {
    cwd: projectRoot,
    encoding: "utf8",
    maxBuffer: 4 * 1024 * 1024,
    timeout: 300000,
    windowsHide: true,
  });
  if (result.error || result.status !== 0) {
    fs.rmSync(markerPath, { force: true });
    const detail = result.error?.message || (result.stderr || "").trim();
    log(`Checker failed (exit ${result.status}): ${detail.slice(0, 1000) || "no details"}`);
    process.exitCode = 1;
    return;
  }
  log("Checker completed successfully.");
}

async function main() {
  const clientIndex = process.argv.indexOf("--client");
  const client = clientIndex >= 0 ? process.argv[clientIndex + 1] : "";
  if (!validClients.has(client)) throw new Error("Missing or invalid --client value.");

  if (process.argv.includes("--worker")) {
    const markerName = process.argv[process.argv.indexOf("--worker") + 1];
    if (!markerName || path.basename(markerName) !== markerName) {
      throw new Error("Invalid worker marker.");
    }
    runChecker(path.join(stateRoot, markerName));
    return;
  }

  const event = JSON.parse(fs.readFileSync(0, "utf8"));
  const prompt = event.prompt || event.initialPrompt || event.initial_prompt || "";
  const sessionId = event.sessionId || event.session_id || "";
  const eligible =
    isProjectPath(event.cwd) &&
    typeof prompt === "string" &&
    isBugReview(prompt) &&
    typeof sessionId === "string" &&
    sessionId.length > 0;

  if (process.argv.includes("--dry-run")) {
    const steamOpen = eligible ? steamIsOpen() : false;
    process.stdout.write(
      `${JSON.stringify({
        projectMatch: isProjectPath(event.cwd),
        diagnosticPrompt: typeof prompt === "string" && isBugReview(prompt),
        sessionIdPresent: typeof sessionId === "string" && sessionId.length > 0,
        steamOpen,
        wouldRun: eligible && steamOpen,
      })}\n`,
    );
    return;
  }

  if (!eligible || !steamIsOpen()) {
    process.stdout.write("{}\n");
    return;
  }

  fs.mkdirSync(stateRoot, { recursive: true });
  const markerPath = markerFor(client, sessionId);
  const markerName = path.basename(markerPath);
  let marker;
  try {
    marker = fs.openSync(markerPath, "wx");
    fs.closeSync(marker);
  } catch (error) {
    if (error.code === "EEXIST") {
      process.stdout.write("{}\n");
      return;
    }
    throw error;
  }

  try {
    const child = spawn(
      process.execPath,
      [fileURLToPath(import.meta.url), "--client", client, "--worker", markerName],
      {
        cwd: projectRoot,
        detached: true,
        stdio: "ignore",
        windowsHide: true,
      },
    );
    child.once("error", (error) => {
      fs.rmSync(markerPath, { force: true });
      log(`Could not start checker worker: ${error.message}`);
    });
    child.once("spawn", () => log(`Checker started for ${client}.`));
    child.unref();
  } catch (error) {
    fs.rmSync(markerPath, { force: true });
    throw error;
  }

  process.stdout.write("{}\n");
}

main().catch((error) => {
  process.stderr.write(`Workshop fix hook: ${error.message}\n`);
  process.stdout.write("{}\n");
});
