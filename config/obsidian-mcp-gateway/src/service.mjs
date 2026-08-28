import { randomUUID } from "node:crypto";
import { DatabaseSync } from "node:sqlite";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import {
  lstat,
  mkdir,
  readFile,
  readdir,
  realpath,
  rename,
  stat,
  unlink
} from "node:fs/promises";
import path from "node:path";
import {
  GatewayError,
  attachmentFileName,
  atomicCreate,
  atomicWrite,
  dateInTimeZone,
  detectMime,
  fsyncDirectory,
  isInside,
  jsonString,
  readUtf8AndHash,
  requestHash,
  resolveRegularFile,
  sha256,
  sha256File,
  titleSlug,
  unique
} from "./common.mjs";
import { extractFrontmatter, extractTags, normalizeTag, parseHeadings, sectionFromHeading } from "./markdown.mjs";

const execFileAsync = promisify(execFile);
const DEFAULT_MAX_FILE_BYTES = 256 * 1024 * 1024;
const DEFAULT_MAX_VAULT_BYTES = 5 * 1024 * 1024 * 1024;
const DEFAULT_MAX_PREVIEW_BYTES = 4 * 1024 * 1024;

function operationResponse(row) {
  return row ? JSON.parse(row.response_json) : null;
}

function attachmentReceipt(row, registeredBy, deduplicated = false) {
  return {
    attachment_id: row.attachment_id,
    path: row.path,
    sha256: row.sha256,
    byte_size: row.byte_size,
    mime: row.mime,
    original_name: row.original_name,
    source_host: row.source_host,
    registered_by: registeredBy,
    wikilink: `![[${row.path}]]`,
    deduplicated
  };
}

function safeYamlScalar(value, field) {
  if (typeof value !== "string" || /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/.test(value)) {
    throw new GatewayError(400, `invalid_${field}`);
  }
  return jsonString(value);
}

function buildAttachmentSection(rows) {
  if (rows.length === 0) return "";
  return `\n\n## Attachments\n\n${rows.map((row) => `![[${row.path}]]`).join("\n")}`;
}

function buildRecord({ recordId, operationId, host, title, body, tags, project, created, attachments }) {
  const lines = [
    "---",
    `title: ${safeYamlScalar(title, "title")}`,
    `created: ${created}`,
    "tags:",
    ...tags.map((tag) => `  - ${safeYamlScalar(tag, "tag")}`),
    `record_id: ${safeYamlScalar(recordId, "record_id")}`,
    `operation_id: ${safeYamlScalar(operationId, "operation_id")}`
  ];
  if (host !== "local") lines.push(`host: ${safeYamlScalar(host, "host")}`);
  if (project) lines.push(`project: ${safeYamlScalar(project, "project")}`);
  lines.push("---", "", body.trim());
  return `${lines.join("\n")}${buildAttachmentSection(attachments)}\n`;
}

async function markdownFiles(root, prefixes = ["Notes"]) {
  const found = [];
  async function walk(directory, prefix) {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error) {
      if (error?.code === "ENOENT") return;
      throw error;
    }
    entries.sort((a, b) => a.name.localeCompare(b.name));
    for (const entry of entries) {
      if (entry.isSymbolicLink()) continue;
      const absolute = path.join(directory, entry.name);
      const relative = path.posix.join(prefix, entry.name);
      if (entry.isDirectory()) await walk(absolute, relative);
      else if (entry.isFile() && entry.name.toLowerCase().endsWith(".md")) found.push({ absolute, relative });
    }
  }
  for (const prefix of prefixes) await walk(path.join(root, ...prefix.split("/")), prefix);
  return found;
}

function knowledgeRoots(service, namespace) {
  const roots = [];
  if (namespace === "main" || namespace === "both") roots.push(["main", service.mainRoot, ["Notes", "Inbox/Agents"]]);
  if ((namespace === "pilot" || namespace === "both") && service.legacyRoot) {
    roots.push(["pilot", service.legacyRoot, ["Notes"]]);
  }
  return roots;
}

function normalizeKnowledgePrefix(value) {
  if (path.isAbsolute(value) || value.includes("\\")) throw new GatewayError(400, "invalid_path_prefix");
  const normalized = path.posix.normalize(value || "Notes/").normalize("NFC");
  if (
    normalized !== "Notes" &&
    !normalized.startsWith("Notes/") &&
    normalized !== "Inbox/Agents" &&
    !normalized.startsWith("Inbox/Agents/")
  ) {
    throw new GatewayError(400, "invalid_path_prefix");
  }
  return normalized;
}

function linesWithEndings(content) {
  if (content.length === 0) return [];
  return content.split(/(?<=\n)/);
}

export class KnowledgeService {
  constructor({
    mainRoot,
    pilotRoot,
    legacyRoot,
    stateRoot,
    maxFileBytes = DEFAULT_MAX_FILE_BYTES,
    maxVaultBytes = DEFAULT_MAX_VAULT_BYTES,
    maxPreviewBytes = DEFAULT_MAX_PREVIEW_BYTES,
    timeZone = "Asia/Seoul",
    now = () => new Date()
  }) {
    this.mainRoot = path.resolve(mainRoot);
    this.legacyRoot = path.resolve(legacyRoot ?? pilotRoot);
    this.pilotRoot = this.legacyRoot;
    this.stateRoot = path.resolve(stateRoot);
    this.maxFileBytes = maxFileBytes;
    this.maxVaultBytes = maxVaultBytes;
    this.maxPreviewBytes = maxPreviewBytes;
    this.timeZone = timeZone;
    this.now = now;
    this.db = null;
    this.lockTail = Promise.resolve();
  }

  async initialize() {
    await Promise.all([
      mkdir(path.join(this.mainRoot, "Notes"), { recursive: true }),
      mkdir(path.join(this.mainRoot, "Inbox", "Agents"), { recursive: true }),
      mkdir(path.join(this.mainRoot, "Attachments"), { recursive: true }),
      mkdir(path.join(this.stateRoot, "previews"), { recursive: true })
    ]);
    this.db = new DatabaseSync(path.join(this.stateRoot, "journal.sqlite"));
    this.db.exec("PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL; PRAGMA foreign_keys=ON; PRAGMA busy_timeout=5000;");
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS operations (
        operation_id TEXT PRIMARY KEY,
        host TEXT NOT NULL,
        kind TEXT NOT NULL,
        request_hash TEXT NOT NULL,
        response_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS attachments (
        attachment_id TEXT PRIMARY KEY,
        sha256 TEXT NOT NULL UNIQUE,
        path TEXT NOT NULL UNIQUE,
        byte_size INTEGER NOT NULL,
        mime TEXT NOT NULL,
        original_name TEXT NOT NULL,
        source_host TEXT NOT NULL,
        created_at TEXT NOT NULL,
        managed INTEGER NOT NULL DEFAULT 1
      );
      CREATE TABLE IF NOT EXISTS attachment_uploads (
        operation_id TEXT PRIMARY KEY REFERENCES operations(operation_id),
        attachment_id TEXT NOT NULL REFERENCES attachments(attachment_id),
        host TEXT NOT NULL,
        original_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS records (
        record_id TEXT PRIMARY KEY,
        path TEXT NOT NULL UNIQUE,
        source_host TEXT NOT NULL,
        last_sha256 TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS record_attachments (
        record_id TEXT NOT NULL REFERENCES records(record_id),
        attachment_id TEXT NOT NULL REFERENCES attachments(attachment_id),
        operation_id TEXT NOT NULL,
        PRIMARY KEY (record_id, attachment_id, operation_id)
      );
    `);
    const attachmentColumns = this.db.prepare("PRAGMA table_info(attachments)").all();
    if (!attachmentColumns.some((column) => column.name === "managed")) {
      this.db.exec("ALTER TABLE attachments ADD COLUMN managed INTEGER NOT NULL DEFAULT 1");
    }
    return this;
  }

  close() {
    this.db?.close();
    this.db = null;
  }

  async withLock(callback) {
    const before = this.lockTail;
    let release;
    this.lockTail = new Promise((resolve) => {
      release = resolve;
    });
    await before;
    try {
      return await callback();
    } finally {
      release();
    }
  }

  async indexExistingAttachments() {
    const root = path.join(this.mainRoot, "Attachments");
    const files = [];
    async function walk(directory, prefix) {
      const entries = await readdir(directory, { withFileTypes: true });
      entries.sort((left, right) => left.name.localeCompare(right.name));
      for (const entry of entries) {
        if (entry.isSymbolicLink() || entry.name.startsWith(".mcp-incoming-")) continue;
        const absolute = path.join(directory, entry.name);
        const relative = path.posix.join(prefix, entry.name);
        if (entry.isDirectory()) await walk(absolute, relative);
        else if (entry.isFile()) files.push({ absolute, relative });
      }
    }
    await walk(root, "Attachments");
    let indexed = 0;
    let known = 0;
    let duplicate = 0;
    for (const file of files) {
      const pathRow = this.db.prepare("SELECT * FROM attachments WHERE path = ?").get(file.relative);
      if (pathRow) {
        known += 1;
        continue;
      }
      const [digest, info] = await Promise.all([sha256File(file.absolute), stat(file.absolute)]);
      const digestRow = this.db.prepare("SELECT * FROM attachments WHERE sha256 = ?").get(digest);
      if (digestRow) {
        duplicate += 1;
        continue;
      }
      const row = {
        attachment_id: `att_${digest}`,
        sha256: digest,
        path: file.relative,
        byte_size: info.size,
        mime: await detectMime(file.absolute, path.basename(file.relative)),
        original_name: path.basename(file.relative),
        source_host: "legacy",
        created_at: info.mtime.toISOString()
      };
      this.db
        .prepare("INSERT INTO attachments(attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at, managed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)")
        .run(row.attachment_id, row.sha256, row.path, row.byte_size, row.mime, row.original_name, row.source_host, row.created_at);
      indexed += 1;
    }
    return { scanned: files.length, indexed, known, duplicate };
  }

  transaction(callback) {
    this.db.exec("BEGIN IMMEDIATE");
    try {
      const result = callback();
      this.db.exec("COMMIT");
      return result;
    } catch (error) {
      this.db.exec("ROLLBACK");
      throw error;
    }
  }

  getOperation(operationId) {
    return this.db.prepare("SELECT * FROM operations WHERE operation_id = ?").get(operationId);
  }

  checkOperation(operationId, host, kind, digest) {
    const row = this.getOperation(operationId);
    if (!row) return null;
    if (row.host !== host || row.kind !== kind || row.request_hash !== digest) {
      throw new GatewayError(409, "operation_conflict", "operation_id was already used with a different request");
    }
    return operationResponse(row);
  }

  async findOperation(operationId, host, kind, digest) {
    return this.withLock(() => this.checkOperation(operationId, host, kind, digest));
  }

  recordOperation(operationId, host, kind, digest, response, createdAt) {
    this.db
      .prepare("INSERT INTO operations(operation_id, host, kind, request_hash, response_json, created_at) VALUES (?, ?, ?, ?, ?, ?)")
      .run(operationId, host, kind, digest, JSON.stringify(response), createdAt);
  }

  async knowledgeSearch({ query, namespace = "both", limit = 20 }) {
    const roots = knowledgeRoots(this, namespace);
    const needle = query.toLocaleLowerCase();
    const results = [];
    for (const [scope, root, prefixes] of roots) {
      for (const file of await markdownFiles(root, prefixes)) {
        if (results.length >= limit) break;
        const content = await readFile(file.absolute, "utf8");
        const lower = content.toLocaleLowerCase();
        const fileMatch = file.relative.toLocaleLowerCase().includes(needle);
        const index = lower.indexOf(needle);
        if (!fileMatch && index < 0) continue;
        const snippetIndex = index >= 0 ? index : 0;
        const start = Math.max(0, snippetIndex - 100);
        const end = Math.min(content.length, snippetIndex + needle.length + 180);
        const snippet = content.slice(start, end).replace(/\s+/g, " ").trim();
        results.push({
          namespace: scope,
          path: file.relative,
          sha256: sha256(Buffer.from(content, "utf8")),
          snippet
        });
      }
      if (results.length >= limit) break;
    }
    return { query, namespace, count: results.length, results };
  }

  async knowledgeList({ namespace = "both", path_prefix: pathPrefix = "Notes/", limit = 100 }) {
    const prefix = normalizeKnowledgePrefix(pathPrefix);
    const candidates = [];
    for (const [scope, root, prefixes] of knowledgeRoots(this, namespace)) {
      for (const file of await markdownFiles(root, prefixes)) {
        if (file.relative.startsWith(prefix)) candidates.push({ namespace: scope, ...file });
      }
    }
    candidates.sort((left, right) =>
      left.namespace === right.namespace
        ? left.relative.localeCompare(right.relative)
        : left.namespace.localeCompare(right.namespace)
    );
    const selected = candidates.slice(0, limit);
    const results = await Promise.all(
      selected.map(async (file) => {
        const [digest, info] = await Promise.all([sha256File(file.absolute), stat(file.absolute)]);
        return {
          namespace: file.namespace,
          path: file.relative,
          sha256: digest,
          byte_size: info.size,
          modified_at: info.mtime.toISOString()
        };
      })
    );
    return {
      namespace,
      path_prefix: prefix,
      count: results.length,
      total: candidates.length,
      truncated: candidates.length > results.length,
      results
    };
  }

  async knowledgeRead({ namespace, path: relativePath, start_line: startLine, line_limit: lineLimit }) {
    const root = namespace === "main" ? this.mainRoot : this.legacyRoot;
    const prefixes = namespace === "main" ? ["Notes/", "Inbox/Agents/"] : ["Notes/"];
    const resolved = await resolveRegularFile(root, relativePath, prefixes);
    const { content, sha256: digest } = await readUtf8AndHash(resolved.absolute);
    const lines = linesWithEndings(content);
    const start = startLine ?? 0;
    const end = lineLimit === undefined ? lines.length : Math.min(lines.length, start + lineLimit);
    return {
      namespace,
      path: resolved.normalized,
      sha256: digest,
      content: lines.slice(start, end).join(""),
      start_line: start,
      end_line_exclusive: end,
      total_lines: lines.length,
      truncated: start > 0 || end < lines.length
    };
  }

  async knowledgeBatchRead({ files, max_total_chars: maxTotalChars = 50_000 }) {
    const results = [];
    const skipped = [];
    let totalChars = 0;
    for (const reference of files) {
      if (totalChars >= maxTotalChars) {
        skipped.push({ ...reference, reason: "max_total_chars" });
        continue;
      }
      const result = await this.knowledgeRead(reference);
      const remaining = maxTotalChars - totalChars;
      const truncated = result.content.length > remaining;
      const content = truncated ? result.content.slice(0, remaining) : result.content;
      results.push({ ...result, content, truncated: result.truncated || truncated, batch_truncated: truncated });
      totalChars += content.length;
    }
    return {
      count: results.length,
      total_chars: totalChars,
      max_total_chars: maxTotalChars,
      results,
      skipped
    };
  }

  async knowledgeFrontmatter({ namespace, path: relativePath }) {
    const note = await this.knowledgeRead({ namespace, path: relativePath });
    const frontmatter = extractFrontmatter(note.content);
    return {
      namespace,
      path: note.path,
      sha256: note.sha256,
      has_frontmatter: frontmatter.has_frontmatter,
      yaml: frontmatter.raw,
      tags: extractTags(note.content)
    };
  }

  async knowledgeOutline({ namespace, path: relativePath }) {
    const note = await this.knowledgeRead({ namespace, path: relativePath });
    const { headings } = parseHeadings(note.content);
    return {
      namespace,
      path: note.path,
      sha256: note.sha256,
      count: headings.length,
      headings
    };
  }

  async knowledgeSectionRead({ namespace, path: relativePath, heading_path: headingPath, include_heading: includeHeading = true }) {
    const note = await this.knowledgeRead({ namespace, path: relativePath });
    const section = sectionFromHeading(note.content, headingPath, includeHeading);
    return {
      namespace,
      path: note.path,
      sha256: note.sha256,
      heading: section.heading,
      include_heading: includeHeading,
      start_line: section.start_line,
      end_line_exclusive: section.end_line_exclusive,
      total_lines: section.total_lines,
      content: section.content
    };
  }

  async knowledgeTagSearch({ tag, namespace = "both", limit = 20 }) {
    const normalizedTag = normalizeTag(tag);
    if (!normalizedTag || /\s/.test(normalizedTag)) throw new GatewayError(400, "invalid_tag");
    const results = [];
    for (const [scope, root, prefixes] of knowledgeRoots(this, namespace)) {
      for (const file of await markdownFiles(root, prefixes)) {
        const content = await readFile(file.absolute, "utf8");
        const tags = extractTags(content);
        if (!tags.includes(normalizedTag)) continue;
        results.push({
          namespace: scope,
          path: file.relative,
          sha256: sha256(Buffer.from(content, "utf8")),
          tags
        });
        if (results.length >= limit) break;
      }
      if (results.length >= limit) break;
    }
    return { tag: normalizedTag, namespace, count: results.length, results };
  }

  attachmentRequestDigest(host, { operationId, expectedSha256, expectedSize, originalName }) {
    return requestHash("attachment_upload", host, {
      operation_id: operationId,
      sha256: expectedSha256,
      byte_size: expectedSize,
      original_name: originalName
    });
  }

  async registerAttachment({ host, operationId, requestDigest, tempPath, sha256: digest, byteSize, mime, originalName }) {
    return this.withLock(async () => {
      const retried = this.checkOperation(operationId, host, "attachment_upload", requestDigest);
      if (retried) {
        await unlink(tempPath).catch(() => {});
        return retried;
      }
      const createdAt = this.now().toISOString();
      const existing = this.db.prepare("SELECT * FROM attachments WHERE sha256 = ?").get(digest);
      if (existing) {
        const absolute = path.join(this.mainRoot, ...existing.path.split("/"));
        const storedDigest = await sha256File(absolute).catch(() => null);
        if (storedDigest !== digest) throw new GatewayError(409, "attachment_storage_drift");
        await unlink(tempPath).catch(() => {});
        const response = attachmentReceipt(existing, host, true);
        this.transaction(() => {
          this.recordOperation(operationId, host, "attachment_upload", requestDigest, response, createdAt);
          this.db
            .prepare("INSERT INTO attachment_uploads(operation_id, attachment_id, host, original_name, created_at) VALUES (?, ?, ?, ?, ?)")
            .run(operationId, existing.attachment_id, host, originalName, createdAt);
        });
        return response;
      }
      const used = this.db.prepare("SELECT COALESCE(SUM(byte_size), 0) AS total FROM attachments WHERE managed = 1").get().total;
      if (used + byteSize > this.maxVaultBytes) throw new GatewayError(507, "attachment_quota_exceeded");
      let relativePath;
      let destination;
      for (const prefixLength of [12, 16, 24, 32, 64]) {
        const filename = attachmentFileName(originalName, digest, prefixLength);
        relativePath = `Attachments/${filename}`;
        destination = path.join(this.mainRoot, "Attachments", filename);
        const destinationInfo = await stat(destination).catch((error) => {
          if (error?.code === "ENOENT") return null;
          throw error;
        });
        if (!destinationInfo || (destinationInfo.isFile() && (await sha256File(destination)) === digest)) break;
        relativePath = null;
        destination = null;
      }
      if (!relativePath || !destination) throw new GatewayError(409, "attachment_path_collision");
      let moved = false;
      try {
        const destinationInfo = await stat(destination).catch((error) => {
          if (error?.code === "ENOENT") return null;
          throw error;
        });
        if (destinationInfo) {
          if (!destinationInfo.isFile() || (await sha256File(destination)) !== digest) {
            throw new GatewayError(409, "attachment_path_collision");
          }
          await unlink(tempPath).catch(() => {});
        } else {
          await rename(tempPath, destination);
          moved = true;
          await fsyncDirectory(path.dirname(destination));
        }
        const row = {
          attachment_id: `att_${digest}`,
          sha256: digest,
          path: relativePath,
          byte_size: byteSize,
          mime,
          original_name: originalName,
          source_host: host,
          created_at: createdAt
        };
        const response = attachmentReceipt(row, host, false);
        this.transaction(() => {
          this.db
            .prepare("INSERT INTO attachments(attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at, managed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)")
            .run(row.attachment_id, row.sha256, row.path, row.byte_size, row.mime, row.original_name, row.source_host, row.created_at);
          this.recordOperation(operationId, host, "attachment_upload", requestDigest, response, createdAt);
          this.db
            .prepare("INSERT INTO attachment_uploads(operation_id, attachment_id, host, original_name, created_at) VALUES (?, ?, ?, ?, ?)")
            .run(operationId, row.attachment_id, host, originalName, createdAt);
        });
        return response;
      } catch (error) {
        if (moved) await unlink(destination).catch(() => {});
        else await unlink(tempPath).catch(() => {});
        throw error;
      }
    });
  }

  getAttachment(attachmentId) {
    const row = this.db.prepare("SELECT * FROM attachments WHERE attachment_id = ?").get(attachmentId);
    if (!row) throw new GatewayError(404, "attachment_not_found");
    return attachmentReceipt(row, row.source_host, false);
  }

  getAttachmentRows(attachmentIds = []) {
    const ids = unique(attachmentIds);
    return ids.map((id) => {
      const row = this.db.prepare("SELECT * FROM attachments WHERE attachment_id = ?").get(id);
      if (!row) throw new GatewayError(400, "unknown_attachment", id);
      return row;
    });
  }

  async resolveAttachmentFile(row) {
    const rootReal = await realpath(this.mainRoot);
    const absolute = path.join(this.mainRoot, ...row.path.split("/"));
    const info = await lstat(absolute).catch((error) => {
      if (error?.code === "ENOENT") throw new GatewayError(409, "attachment_storage_drift");
      throw error;
    });
    if (!info.isFile() || info.isSymbolicLink()) throw new GatewayError(409, "attachment_storage_drift");
    const actual = await realpath(absolute);
    if (!isInside(rootReal, actual) || (await sha256File(actual)) !== row.sha256) {
      throw new GatewayError(409, "attachment_storage_drift");
    }
    return actual;
  }

  async attachmentRowFromPath(relativePath) {
    if (path.isAbsolute(relativePath) || relativePath.includes("\\")) throw new GatewayError(400, "invalid_attachment_path");
    const normalized = path.posix.normalize(relativePath).normalize("NFC");
    if (!normalized.startsWith("Attachments/") || normalized.includes("../")) {
      throw new GatewayError(400, "invalid_attachment_path");
    }
    const [rootReal, candidateReal] = await Promise.all([
      realpath(this.mainRoot),
      realpath(path.join(this.mainRoot, ...normalized.split("/")))
    ]).catch((error) => {
      if (error?.code === "ENOENT") throw new GatewayError(404, "attachment_not_found");
      throw error;
    });
    if (!isInside(rootReal, candidateReal)) throw new GatewayError(400, "attachment_path_escape");
    const info = await lstat(candidateReal);
    if (!info.isFile() || info.isSymbolicLink()) throw new GatewayError(400, "not_regular_file");
    const digest = await sha256File(candidateReal);
    const indexed = this.db.prepare("SELECT * FROM attachments WHERE sha256 = ?").get(digest);
    return {
      ...(indexed ?? {}),
      attachment_id: `att_${digest}`,
      sha256: digest,
      path: normalized,
      byte_size: info.size,
      mime: await detectMime(candidateReal, path.basename(normalized)),
      original_name: path.basename(normalized),
      source_host: indexed?.source_host ?? "legacy",
      created_at: indexed?.created_at ?? info.mtime.toISOString()
    };
  }

  async attachmentPreview(reference) {
    const attachmentId = typeof reference === "string" ? reference : reference.attachment_id;
    const row = reference?.path
      ? await this.attachmentRowFromPath(reference.path)
      : this.db.prepare("SELECT * FROM attachments WHERE attachment_id = ?").get(attachmentId);
    if (!row) throw new GatewayError(404, "attachment_not_found");
    const metadata = attachmentReceipt(row, row.source_host, false);
    if (!row.mime.startsWith("image/")) return { metadata, image: null };
    const input = await this.resolveAttachmentFile(row);
    const previewDirectory = path.join(this.stateRoot, "previews");
    const cacheId = row.attachment_id;
    const pngPath = path.join(previewDirectory, `${cacheId}.png`);
    let previewPath = pngPath;
    let previewMime = "image/png";
    let previewInfo = await stat(previewPath).catch(() => null);
    if (!previewInfo) {
      const temporary = path.join(previewDirectory, `.${cacheId}.${randomUUID()}.png`);
      try {
        await execFileAsync("/usr/bin/sips", ["-Z", "1024", "-s", "format", "png", input, "--out", temporary], {
          maxBuffer: 1024 * 1024
        });
        await rename(temporary, pngPath);
      } catch (error) {
        await unlink(temporary).catch(() => {});
        throw new GatewayError(415, "preview_unavailable", error.message);
      }
      previewInfo = await stat(pngPath);
    }
    if (previewInfo.size > this.maxPreviewBytes) {
      const jpegPath = path.join(previewDirectory, `${cacheId}.jpg`);
      const temporary = path.join(previewDirectory, `.${cacheId}.${randomUUID()}.jpg`);
      try {
        await execFileAsync(
          "/usr/bin/sips",
          ["-Z", "1024", "-s", "format", "jpeg", "-s", "formatOptions", "70", input, "--out", temporary],
          { maxBuffer: 1024 * 1024 }
        );
        const jpegInfo = await stat(temporary);
        if (jpegInfo.size > this.maxPreviewBytes) throw new GatewayError(413, "preview_too_large");
        await rename(temporary, jpegPath);
        previewPath = jpegPath;
        previewMime = "image/jpeg";
        previewInfo = jpegInfo;
      } catch (error) {
        await unlink(temporary).catch(() => {});
        throw error instanceof GatewayError ? error : new GatewayError(415, "preview_unavailable", error.message);
      }
    }
    return {
      metadata,
      image: { path: previewPath, mime: previewMime, byte_size: previewInfo.size }
    };
  }

  async recordCreate(host, input) {
    if (host !== "local" && !input.project) {
      throw new GatewayError(400, "project_required", "Remote-host records require the canonical project name");
    }
    const normalized = {
      ...input,
      attachment_ids: unique(input.attachment_ids ?? [])
    };
    const digest = requestHash("record_create", host, normalized);
    return this.withLock(async () => {
      const retried = this.checkOperation(input.operation_id, host, "record_create", digest);
      if (retried) return retried;
      for (const tag of input.tags) safeYamlScalar(tag, "tag");
      const attachments = this.getAttachmentRows(normalized.attachment_ids);
      const createdAt = this.now();
      const createdIso = createdAt.toISOString();
      const createdDate = dateInTimeZone(createdAt, this.timeZone);
      let recordId;
      let relativePath;
      let destination;
      for (let attempt = 0; attempt < 4; attempt += 1) {
        recordId = randomUUID();
        relativePath = `Inbox/Agents/${host}/${createdDate} ${titleSlug(input.title)}--${recordId.slice(0, 8)}.md`;
        destination = path.join(this.mainRoot, ...relativePath.split("/"));
        const exists = await stat(destination).then(() => true, (error) => {
          if (error?.code === "ENOENT") return false;
          throw error;
        });
        if (!exists) break;
        if (attempt === 3) throw new GatewayError(409, "record_path_collision");
      }
      const content = buildRecord({
        recordId,
        operationId: input.operation_id,
        host,
        title: input.title,
        body: input.body,
        tags: input.tags,
        project: input.project,
        created: createdDate,
        attachments
      });
      await mkdir(path.dirname(destination), { recursive: true });
      await atomicCreate(destination, content);
      const contentSha = sha256(Buffer.from(content, "utf8"));
      const response = {
        record_id: recordId,
        path: relativePath,
        sha256: contentSha,
        source_host: host,
        attachment_ids: normalized.attachment_ids,
        wikilink: `[[${relativePath.slice(0, -3)}]]`
      };
      try {
        this.transaction(() => {
          this.db
            .prepare("INSERT INTO records(record_id, path, source_host, last_sha256, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)")
            .run(recordId, relativePath, host, contentSha, createdIso, createdIso);
          for (const attachment of attachments) {
            this.db
              .prepare("INSERT INTO record_attachments(record_id, attachment_id, operation_id) VALUES (?, ?, ?)")
              .run(recordId, attachment.attachment_id, input.operation_id);
          }
          this.recordOperation(input.operation_id, host, "record_create", digest, response, createdIso);
        });
      } catch (error) {
        await unlink(destination).catch(() => {});
        throw error;
      }
      return response;
    });
  }

  async recordAppend(host, input) {
    const normalized = { ...input, body: input.body ?? "", attachment_ids: unique(input.attachment_ids ?? []) };
    const digest = requestHash("record_append", host, normalized);
    return this.withLock(async () => {
      const retried = this.checkOperation(input.operation_id, host, "record_append", digest);
      if (retried) return retried;
      const record = this.db.prepare("SELECT * FROM records WHERE record_id = ?").get(input.record_id);
      if (!record) throw new GatewayError(404, "record_not_found");
      if (record.source_host !== host) throw new GatewayError(403, "record_host_mismatch");
      const attachments = this.getAttachmentRows(normalized.attachment_ids);
      const resolved = await resolveRegularFile(this.mainRoot, record.path, ["Inbox/Agents/"]);
      const current = await readUtf8AndHash(resolved.absolute);
      if (current.sha256 !== record.last_sha256) {
        throw new GatewayError(409, "human_edit_detected", "Record changed outside the gateway; automatic merge is disabled", {
          expected_sha256: record.last_sha256,
          actual_sha256: current.sha256
        });
      }
      const updatedAt = this.now().toISOString();
      const body = normalized.body.trim();
      const marker = `<!-- append:${input.operation_id} host:${host} at:${updatedAt} -->`;
      const appended = [marker, body, attachments.map((row) => `![[${row.path}]]`).join("\n")]
        .filter(Boolean)
        .join("\n\n");
      const content = `${current.content.trimEnd()}\n\n${appended}\n`;
      await atomicWrite(resolved.absolute, content);
      const contentSha = sha256(Buffer.from(content, "utf8"));
      const response = {
        record_id: input.record_id,
        path: record.path,
        sha256: contentSha,
        appended_by: host,
        attachment_ids: normalized.attachment_ids,
        wikilink: `[[${record.path.slice(0, -3)}]]`
      };
      try {
        this.transaction(() => {
          const changed = this.db
            .prepare("UPDATE records SET last_sha256 = ?, updated_at = ? WHERE record_id = ? AND last_sha256 = ?")
            .run(contentSha, updatedAt, input.record_id, record.last_sha256);
          if (changed.changes !== 1) throw new GatewayError(409, "concurrent_append_conflict");
          for (const attachment of attachments) {
            this.db
              .prepare("INSERT INTO record_attachments(record_id, attachment_id, operation_id) VALUES (?, ?, ?)")
              .run(input.record_id, attachment.attachment_id, input.operation_id);
          }
          this.recordOperation(input.operation_id, host, "record_append", digest, response, updatedAt);
        });
      } catch (error) {
        await atomicWrite(resolved.absolute, current.content);
        throw error;
      }
      return response;
    });
  }

  status() {
    const attachmentCount = this.db.prepare("SELECT COUNT(*) AS count FROM attachments").get().count;
    const byteSize = this.db.prepare("SELECT COALESCE(SUM(byte_size), 0) AS total FROM attachments").get().total;
    const recordCount = this.db.prepare("SELECT COUNT(*) AS count FROM records").get().count;
    return {
      status: "ok",
      writer: "main-agent-inbox-only",
      main: "Notes read-only; Inbox/Agents and Attachments gateway-managed",
      attachment_count: attachmentCount,
      attachment_bytes: byteSize,
      record_count: recordCount
    };
  }
}

export async function inspectUploadedTemp(tempPath, originalName) {
  const info = await stat(tempPath);
  return {
    byteSize: info.size,
    sha256: await sha256File(tempPath),
    mime: await detectMime(tempPath, originalName)
  };
}
