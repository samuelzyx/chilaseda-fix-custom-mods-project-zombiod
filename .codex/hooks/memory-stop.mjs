import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const hookDirectory = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(hookDirectory, "../..");
const memoryPath = path.join(projectRoot, ".ai-memory", "MEMORY.md");

function readHookInput() {
  return new Promise((resolve, reject) => {
    let input = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      input += chunk;
    });
    process.stdin.on("end", () => {
      try {
        resolve(JSON.parse(input));
      } catch (error) {
        reject(error);
      }
    });
    process.stdin.on("error", reject);
  });
}

function redactSensitiveText(text) {
  return text
    .replace(/\bBearer\s+[A-Za-z0-9._~+/-]+=*/gi, "Bearer [redactado]")
    .replace(
      /\b((?:access|refresh)[ _-]?token|api[_ -]?key|client[_ -]?secret|password|contraseña)\s*[:=]\s*[^\s,;]+/gi,
      "$1=[redactado]",
    );
}

function makeMemoryLine(message) {
  const flattened = message
    .replace(/```[\s\S]*?```/g, "[bloque de código]")
    .replace(/!\[([^\]]*)\]\([^)]+\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
    .replace(/`([^`]+)`/g, "$1")
    .replace(/[*_>#]/g, "")
    .replace(/[\r\n\t]+/g, " ")
    .replace(/\s{2,}/g, " ")
    .trim();

  const safeText = redactSensitiveText(flattened);
  const summary =
    safeText.length > 360 ? `${safeText.slice(0, 357).trimEnd()}…` : safeText;
  const date = new Intl.DateTimeFormat("en-CA", {
    timeZone: "America/Mexico_City",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());

  return `- ${date} · Cierre Codex: ${summary}`;
}

async function main() {
  try {
    const hookInput = await readHookInput();
    const message = hookInput.last_assistant_message?.trim() ?? "";

    if (!message) {
      process.stdout.write("{}\n");
      return;
    }

    const memoryLine = makeMemoryLine(message);

    if (process.argv.includes("--dry-run")) {
      process.stdout.write(`${JSON.stringify({ memoryLine })}\n`);
      return;
    }

    fs.appendFileSync(memoryPath, `${memoryLine}\n`, "utf8");
    process.stdout.write("{}\n");
  } catch {
    process.stdout.write(
      `${JSON.stringify({ systemMessage: "No se pudo actualizar .ai-memory/MEMORY.md." })}\n`,
    );
  }
}

main();
