import { createHash, randomUUID } from "node:crypto";
import { link, open, readFile, realpath, rename, stat, unlink } from "node:fs/promises";
import path from "node:path";

export class GatewayError extends Error {
  constructor(status, code, message = code, details) {
    super(message);
    this.name = "GatewayError";
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export function asGatewayError(error) {
  if (error instanceof GatewayError) return error;
  if (error?.status && error?.code) {
    return new GatewayError(error.status, error.code, error.message, error.details);
  }
  return new GatewayError(500, "internal_error", "Internal server error");
}

export function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

export async function sha256File(filePath) {
  const handle = await open(filePath, "r");
  const hash = createHash("sha256");
  try {
    const buffer = Buffer.allocUnsafe(1024 * 1024);
    while (true) {
      const { bytesRead } = await handle.read(buffer, 0, buffer.length, null);
      if (bytesRead === 0) break;
      hash.update(buffer.subarray(0, bytesRead));
    }
  } finally {
    await handle.close();
  }
  return hash.digest("hex");
}

function canonicalize(value) {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, canonicalize(value[key])])
    );
  }
  return value;
}

export function requestHash(kind, host, payload) {
  return sha256(JSON.stringify(canonicalize({ kind, host, payload })));
}

export function isInside(root, candidate) {
  return candidate === root || candidate.startsWith(`${root}${path.sep}`);
}

export async function resolveRegularFile(root, relativePath, allowedPrefixes = ["Notes/"]) {
  if (path.isAbsolute(relativePath) || relativePath.includes("\\")) {
    throw new GatewayError(400, "invalid_path");
  }
  const normalized = path.posix.normalize(relativePath);
  if (
    !allowedPrefixes.some((prefix) => normalized.startsWith(prefix)) ||
    normalized.includes("../") ||
    !normalized.endsWith(".md")
  ) {
    throw new GatewayError(400, "invalid_path");
  }
  const [rootReal, candidateReal] = await Promise.all([
    realpath(root),
    realpath(path.join(root, ...normalized.split("/")))
  ]).catch((error) => {
    if (error?.code === "ENOENT") throw new GatewayError(404, "not_found");
    throw error;
  });
  if (!isInside(rootReal, candidateReal)) throw new GatewayError(400, "path_escape");
  const info = await stat(candidateReal);
  if (!info.isFile()) throw new GatewayError(400, "not_regular_file");
  return { normalized, absolute: candidateReal };
}

export function sanitizeExtension(name) {
  const extension = path.extname(name).slice(1).toLowerCase();
  return /^[a-z0-9]{1,12}$/.test(extension) ? extension : "bin";
}

export function attachmentFileName(originalName, digest, prefixLength = 12) {
  const extension = sanitizeExtension(originalName);
  const rawStem = path.basename(originalName, path.extname(originalName));
  const stem = rawStem
    .normalize("NFC")
    .replace(/[\u0000-\u001F\u007F/:*?"<>|#[\]\\^]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 120)
    .trim();
  return `${stem || "attachment"}--${digest.slice(0, prefixLength)}.${extension}`;
}

export function safeDisplayName(value) {
  const name = path.basename(value.normalize("NFC")).trim();
  if (!name || name === "." || name === ".." || name.includes("\0")) {
    throw new GatewayError(400, "invalid_original_name");
  }
  if (name !== value.normalize("NFC").trim()) {
    throw new GatewayError(400, "invalid_original_name");
  }
  if (isCredentialLikeName(name)) throw new GatewayError(403, "credential_file_rejected");
  return name;
}

export function isCredentialLikeName(value) {
  const name = value.toLowerCase();
  return (
    /^(\.env($|\.)|credentials?($|\.)|secrets?($|\.)|tokens?($|\.)|kubeconfig$)/.test(name) ||
    /^(id_(rsa|dsa|ecdsa|ed25519)(\.|$)|authorized_keys$|known_hosts$)/.test(name) ||
    /\.(pem|key|p12|pfx|jks|keystore)$/.test(name)
  );
}

const extensionMimes = new Map([
  ["md", "text/markdown; charset=utf-8"],
  ["txt", "text/plain; charset=utf-8"],
  ["csv", "text/csv; charset=utf-8"],
  ["json", "application/json"],
  ["yaml", "application/yaml"],
  ["yml", "application/yaml"],
  ["svg", "image/svg+xml"],
  ["html", "text/html; charset=utf-8"],
  ["htm", "text/html; charset=utf-8"],
  ["pdf", "application/pdf"],
  ["zip", "application/zip"],
  ["docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"],
  ["xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"],
  ["pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"],
  ["hwp", "application/x-hwp"],
  ["hwpx", "application/vnd.hancom.hwpx"]
]);

export async function detectMime(filePath, originalName) {
  const handle = await open(filePath, "r");
  const head = Buffer.alloc(8192);
  let bytesRead;
  try {
    ({ bytesRead } = await handle.read(head, 0, head.length, 0));
  } finally {
    await handle.close();
  }
  const data = head.subarray(0, bytesRead);
  if (data.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return "image/png";
  if (data.subarray(0, 3).equals(Buffer.from([255, 216, 255]))) return "image/jpeg";
  if (data.subarray(0, 6).toString("ascii") === "GIF87a" || data.subarray(0, 6).toString("ascii") === "GIF89a") return "image/gif";
  if (data.subarray(0, 4).toString("ascii") === "%PDF") return "application/pdf";
  if (data.subarray(0, 4).toString("hex") === "504b0304") return extensionMimes.get(sanitizeExtension(originalName)) ?? "application/zip";
  if (data.subarray(0, 3).toString("hex") === "1f8b08") return "application/gzip";
  if (data.subarray(0, 4).toString("ascii") === "RIFF" && data.subarray(8, 12).toString("ascii") === "WEBP") return "image/webp";
  const extensionMime = extensionMimes.get(sanitizeExtension(originalName));
  if (extensionMime) return extensionMime;
  if (data.length > 0 && !data.includes(0) && Buffer.from(data.toString("utf8"), "utf8").length > 0) {
    const replacementCount = (data.toString("utf8").match(/\uFFFD/g) ?? []).length;
    if (replacementCount <= Math.max(1, Math.floor(data.length / 100))) return "text/plain; charset=utf-8";
  }
  return "application/octet-stream";
}

export async function atomicWrite(filePath, content, mode = 0o600) {
  const directory = path.dirname(filePath);
  const temporary = path.join(directory, `.${path.basename(filePath)}.${randomUUID()}.tmp`);
  const handle = await open(temporary, "wx", mode);
  try {
    await handle.writeFile(content);
    await handle.sync();
  } catch (error) {
    await handle.close().catch(() => {});
    await unlink(temporary).catch(() => {});
    throw error;
  }
  await handle.close();
  await rename(temporary, filePath);
  await fsyncDirectory(directory);
}

export async function atomicCreate(filePath, content, mode = 0o600) {
  const directory = path.dirname(filePath);
  const temporary = path.join(directory, `.${path.basename(filePath)}.${randomUUID()}.tmp`);
  const handle = await open(temporary, "wx", mode);
  try {
    await handle.writeFile(content);
    await handle.sync();
  } catch (error) {
    await handle.close().catch(() => {});
    await unlink(temporary).catch(() => {});
    throw error;
  }
  await handle.close();
  try {
    await link(temporary, filePath);
    await fsyncDirectory(directory);
  } finally {
    await unlink(temporary).catch(() => {});
  }
}

export async function fsyncDirectory(directory) {
  const handle = await open(directory, "r");
  try {
    await handle.sync();
  } finally {
    await handle.close();
  }
}

export async function readUtf8AndHash(filePath) {
  const content = await readFile(filePath, "utf8");
  return { content, sha256: sha256(Buffer.from(content, "utf8")) };
}

export function dateInTimeZone(now = new Date(), timeZone = "Asia/Seoul") {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(now);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

export function titleSlug(title) {
  const result = title
    .normalize("NFC")
    .replace(/[^\p{L}\p{N} ._-]+/gu, " ")
    .replace(/[._]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80)
    .trim();
  return result || "record";
}

export function jsonString(value) {
  return JSON.stringify(value);
}

export function unique(values = []) {
  return [...new Set(values)];
}
