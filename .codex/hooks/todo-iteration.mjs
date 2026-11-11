import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hookDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(hookDirectory, "../..");
const todoPath = path.join(projectRoot, "TODO.md");
const weightReviewMarker = path.join(hookDirectory, "weight-review-last-date.txt");

function localDate() {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function shouldIncludeDailyWeightReview() {
  const today = localDate();
  try {
    if (fs.readFileSync(weightReviewMarker, "utf8").trim() === today) return false;
  } catch { /* no marker yet */ }

  const lockPath = `${weightReviewMarker}.${today}.lock`;
  let lockFd;
  let ownsLock = false;
  try {
    lockFd = fs.openSync(lockPath, "wx");
    ownsLock = true;
    fs.writeSync(lockFd, `${process.pid}\n`);
    fs.closeSync(lockFd);
    lockFd = undefined;
    if (fs.existsSync(weightReviewMarker)
        && fs.readFileSync(weightReviewMarker, "utf8").trim() === today) return false;
    fs.writeFileSync(weightReviewMarker, `${today}\n`, "utf8");
    return true;
  } catch (error) {
    if (lockFd !== undefined) fs.closeSync(lockFd);
    if (error.code === "EEXIST") {
      try {
        if (Date.now() - fs.statSync(lockPath).mtimeMs > 15 * 60 * 1000) {
          fs.unlinkSync(lockPath);
          return shouldIncludeDailyWeightReview();
        }
      } catch { /* lock disappeared during check */ }
      return false;
    }
    throw error;
  } finally {
    if (ownsLock) {
      try { fs.unlinkSync(lockPath); } catch { /* another invocation may have removed it */ }
    }
  }
}

let includeDailyWeightReview = false;
try {
  includeDailyWeightReview = shouldIncludeDailyWeightReview();
} catch { /* TODO reminder must still be delivered if the daily marker fails */ }

const additionalContext = fs.existsSync(todoPath)
  ? [
      "Workspace iteration reminder: consult TODO.md at the start of this work turn and update it before finishing when this turn adds work, confirms a result, changes a status, or leaves a follow-up.",
      "When a task is confirmed complete, remove it from TODO.md; move only durable findings and confirmed outcomes to MEMORY.md. Keep unresolved Codex work separate from Chila validations and conditional follow-ups.",
      "Keep TODO.md limited to open Codex work, Chila validations, and conditional follow-ups; it must contain no completed-task sections or checked items. Format TODO.md for raw-text reading: blank lines between tasks and sections, wrap long task bullets around 100 characters with a two-space continuation indent, and keep one task per bullet. Move only concise durable facts, evidence, and resolution to MEMORY.md. New MEMORY.md entries must include the local record timestamp in YYYY-MM-DD HH:mm:ss followed by the numeric UTC offset, such as -06:00. Never invent retroactive times for older records. Do not copy closed tasks verbatim, archive trivial one-off work, or put open follow-ups in MEMORY.md.",
      "to-do list.txt is Chila's quick-view copy: do not read it, treat it as task input, or synchronize it. Do not recreate it if missing.",
      "Do not create work backups unless Chila explicitly asks; do not automatically remove backups that already exist.",
      ...(includeDailyWeightReview ? [
        "Daily weight review: consult Manual_Pesos_B42_y_Monitor.md and the latest monitor log. After each Jill session, inspect new entries in mods/PesosLogs/*.txt once the requested writer is implemented; until then use Zomboid/Lua/ChilaSeda_WeightMonitor.log. Update the manual and TODO.md only when evidence changes; investigate REVISAR or unexpected values, mark unseen current-session items Sin registro, preserve Markdown tables and technical IDs, and never invent observations. Do not ask Chila to collect items or operate the monitor panel. If UI access is unavailable, report that blocker.",
      ] : []),
    ].join(" ")
  : "TODO.md is missing from this workspace. Do not recreate it unless Chila explicitly asks; report the missing task list.";

process.stdout.write(
  `${JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext,
    },
  })}\n`,
);
