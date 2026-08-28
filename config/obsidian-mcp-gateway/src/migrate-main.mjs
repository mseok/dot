import { DatabaseSync } from "node:sqlite";
import { copyFile, lstat, mkdir, open, readFile, readdir, realpath, rename, stat } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import {
  attachmentFileName,
  atomicWrite,
  detectMime,
  fsyncDirectory,
  isInside,
  sha256,
  sha256File
} from "./common.mjs";
import { KnowledgeService } from "./service.mjs";

const EXCLUDED_SOURCE_DIRECTORIES = new Set([".git", ".obsidian", "Archive", "Derived"]);
const ATTACHMENT_PREFIX_LENGTHS = [12, 16, 24, 32, 64];

function relative(root, candidate) {
  return path.relative(root, candidate).split(path.sep).join("/");
}

async function regularFiles(root, { markdownOnly = false, skipTopLevel = new Set() } = {}) {
  const found = [];
  async function walk(directory) {
    const entries = await readdir(directory, { withFileTypes: true });
    entries.sort((left, right) => left.name.localeCompare(right.name));
    for (const entry of entries) {
      const absolute = path.join(directory, entry.name);
      const rel = relative(root, absolute);
      if (rel.split("/").some((part) => part.startsWith("."))) continue;
      if (skipTopLevel.has(rel.split("/", 1)[0])) continue;
      if (entry.isSymbolicLink()) continue;
      if (entry.isDirectory()) await walk(absolute);
      else if (entry.isFile() && (!markdownOnly || entry.name.toLowerCase().endsWith(".md"))) {
        found.push({ absolute, path: rel });
      }
    }
  }
  await walk(root);
  return found;
}

function stripScalar(value) {
  const trimmed = value.trim();
  if (trimmed.length >= 2 && trimmed[0] === trimmed.at(-1) && ["'", '"'].includes(trimmed[0])) {
    return trimmed.slice(1, -1).trim();
  }
  return trimmed;
}

function noteHost(content) {
  const frontmatter = content.match(/^---\r?\n([\s\S]*?)\r?\n(?:---|\.\.\.)(?:\r?\n|$)/)?.[1] ?? "";
  const raw = frontmatter.match(/^host\s*:\s*(.+?)\s*$/im)?.[1];
  if (!raw) return null;
  const value = stripScalar(raw).normalize("NFC");
  if (value === "gpu22" || value === "gpu01") return value;
  return "multi-host";
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function rewriteWikilinkTarget(content, from, to, optionalMarkdown = false) {
  const suffix = optionalMarkdown ? "(?:\\.md)?" : "";
  const pattern = new RegExp(`(\\[\\[)${escapeRegExp(from)}${suffix}(?=[\\]|#])`, "gu");
  let count = 0;
  return {
    content: content.replace(pattern, (_match, opening) => {
      count += 1;
      return `${opening}${to}`;
    }),
    count
  };
}

function rewriteMany(content, mappings) {
  let updated = content;
  const changes = [];
  for (const mapping of mappings) {
    const result = rewriteWikilinkTarget(updated, mapping.from, mapping.to, mapping.optional_markdown);
    updated = result.content;
    if (result.count > 0) changes.push({ ...mapping, count: result.count });
  }
  return { content: updated, changes };
}

async function fileDescriptor(absolute, rel, originalName = path.basename(rel)) {
  const info = await stat(absolute);
  const digest = await sha256File(absolute);
  return {
    path: rel,
    sha256: digest,
    byte_size: info.size,
    mode: info.mode & 0o777,
    modified_at: info.mtime.toISOString(),
    mime: await detectMime(absolute, originalName)
  };
}

function chooseAttachmentPath(originalName, digest, usedPaths) {
  for (const prefixLength of ATTACHMENT_PREFIX_LENGTHS) {
    const candidate = `Attachments/${attachmentFileName(originalName, digest, prefixLength)}`;
    const existingDigest = usedPaths.get(candidate);
    if (!existingDigest || existingDigest === digest) return candidate;
  }
  throw new Error(`attachment path collision for ${originalName}`);
}

function openLegacyDatabase(databasePath) {
  return new DatabaseSync(databasePath, { readOnly: true });
}

function rows(db, sql) {
  return db.prepare(sql).all().map((row) => ({ ...row }));
}

function operationPlans(operations, attachments, records) {
  const attachmentById = new Map(attachments.map((item) => [item.attachment_id, item]));
  const recordById = new Map(records.map((item) => [item.record_id, item]));
  return operations.map((operation) => {
    const response = JSON.parse(operation.response_json);
    if (operation.kind === "attachment_upload") {
      const attachment = attachmentById.get(response.attachment_id);
      if (!attachment) throw new Error(`operation references unknown attachment: ${operation.operation_id}`);
      response.path = attachment.target_path;
      response.wikilink = `![[${attachment.target_path}]]`;
      response.deduplicated = attachment.deduplicated;
    } else if (operation.kind === "record_create") {
      const record = recordById.get(response.record_id);
      if (!record) throw new Error(`operation references unknown record: ${operation.operation_id}`);
      response.path = record.target_path;
      response.sha256 = record.target_sha256;
      response.wikilink = `[[${record.target_path.slice(0, -3)}]]`;
    }
    return { ...operation, response_json: JSON.stringify(response) };
  });
}

export async function buildMigrationPlan({ mainRoot, legacyRoot, legacyState }) {
  mainRoot = await realpath(mainRoot);
  legacyRoot = await realpath(legacyRoot);
  legacyState = await realpath(legacyState);
  const notesRoot = path.join(mainRoot, "Notes");
  const directNotes = (await readdir(notesRoot, { withFileTypes: true }))
    .filter((entry) => entry.isFile() && entry.name.toLowerCase().endsWith(".md"))
    .sort((left, right) => left.name.localeCompare(right.name));
  const moves = [];
  for (const entry of directNotes) {
    const sourcePath = `Notes/${entry.name}`;
    const absolute = path.join(notesRoot, entry.name);
    const content = await readFile(absolute, "utf8");
    const host = noteHost(content);
    if (!host) continue;
    const info = await stat(absolute);
    moves.push({
      source_path: sourcePath,
      target_path: `Inbox/Agents/${host}/${entry.name}`,
      host,
      source_sha256: sha256(Buffer.from(content, "utf8")),
      byte_size: info.size,
      mode: info.mode & 0o777
    });
  }
  const moveBySource = new Map(moves.map((move) => [move.source_path, move.target_path]));
  const noteMappings = moves.map((move) => ({
    from: move.source_path.slice(0, -3),
    to: move.target_path.slice(0, -3),
    optional_markdown: true
  }));
  const linkUpdates = [];
  const sourceMarkdown = await regularFiles(mainRoot, {
    markdownOnly: true,
    skipTopLevel: EXCLUDED_SOURCE_DIRECTORIES
  });
  for (const file of sourceMarkdown) {
    const before = await readFile(file.absolute, "utf8");
    const rewritten = rewriteMany(before, noteMappings);
    if (rewritten.changes.length === 0) continue;
    const info = await stat(file.absolute);
    linkUpdates.push({
      source_path: file.path,
      final_path: moveBySource.get(file.path) ?? file.path,
      source_sha256: sha256(Buffer.from(before, "utf8")),
      target_sha256: sha256(Buffer.from(rewritten.content, "utf8")),
      mode: info.mode & 0o777,
      changes: rewritten.changes
    });
  }

  const attachmentRoot = path.join(mainRoot, "Attachments");
  const existingAttachments = [];
  const usedPaths = new Map();
  const firstPathByDigest = new Map();
  for (const file of await regularFiles(attachmentRoot)) {
    const descriptor = await fileDescriptor(file.absolute, `Attachments/${file.path}`);
    existingAttachments.push(descriptor);
    usedPaths.set(descriptor.path, descriptor.sha256);
    if (!firstPathByDigest.has(descriptor.sha256)) firstPathByDigest.set(descriptor.sha256, descriptor.path);
  }

  const legacyDbPath = path.join(legacyState, "journal.sqlite");
  const legacyDb = openLegacyDatabase(legacyDbPath);
  let legacyAttachments;
  let legacyRecords;
  let legacyOperations;
  let attachmentUploads;
  let recordAttachments;
  try {
    legacyAttachments = rows(
      legacyDb,
      "SELECT attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at FROM attachments ORDER BY path"
    );
    legacyRecords = rows(
      legacyDb,
      "SELECT record_id, path, source_host, last_sha256, created_at, updated_at FROM records ORDER BY path"
    );
    legacyOperations = rows(
      legacyDb,
      "SELECT operation_id, host, kind, request_hash, response_json, created_at FROM operations ORDER BY created_at, operation_id"
    );
    attachmentUploads = rows(
      legacyDb,
      "SELECT operation_id, attachment_id, host, original_name, created_at FROM attachment_uploads ORDER BY operation_id"
    );
    recordAttachments = rows(
      legacyDb,
      "SELECT record_id, attachment_id, operation_id FROM record_attachments ORDER BY record_id, attachment_id, operation_id"
    );
  } finally {
    legacyDb.close();
  }

  const pilotAttachments = [];
  for (const row of legacyAttachments) {
    const sourceAbsolute = path.join(legacyRoot, ...row.path.split("/"));
    const actualDigest = await sha256File(sourceAbsolute);
    const info = await stat(sourceAbsolute);
    if (actualDigest !== row.sha256 || info.size !== row.byte_size) {
      throw new Error(`legacy attachment drift: ${row.path}`);
    }
    const reused = firstPathByDigest.get(row.sha256);
    const targetPath = reused ?? chooseAttachmentPath(row.original_name, row.sha256, usedPaths);
    usedPaths.set(targetPath, row.sha256);
    if (!reused) firstPathByDigest.set(row.sha256, targetPath);
    pilotAttachments.push({
      ...row,
      source_path: row.path,
      target_path: targetPath,
      deduplicated: Boolean(reused),
      managed: reused ? 0 : 1,
      mode: info.mode & 0o777
    });
  }
  const attachmentMappings = pilotAttachments.map((item) => ({
    from: item.source_path,
    to: item.target_path,
    optional_markdown: false
  }));
  const pilotRecordMappings = legacyRecords.map((row) => ({
    from: row.path.slice(0, -3),
    to: `Inbox/Agents/${row.source_host}/${path.basename(row.path, ".md")}`,
    optional_markdown: true
  }));
  const pilotRecords = [];
  for (const row of legacyRecords) {
    const sourceAbsolute = path.join(legacyRoot, ...row.path.split("/"));
    const before = await readFile(sourceAbsolute, "utf8");
    const sourceDigest = sha256(Buffer.from(before, "utf8"));
    if (sourceDigest !== row.last_sha256) throw new Error(`legacy record drift: ${row.path}`);
    const rewritten = rewriteMany(before, [...attachmentMappings, ...pilotRecordMappings]);
    const info = await stat(sourceAbsolute);
    pilotRecords.push({
      ...row,
      source_path: row.path,
      target_path: `Inbox/Agents/${row.source_host}/${path.basename(row.path)}`,
      source_sha256: sourceDigest,
      target_sha256: sha256(Buffer.from(rewritten.content, "utf8")),
      mode: info.mode & 0o777,
      changes: rewritten.changes
    });
  }
  legacyOperations = operationPlans(legacyOperations, pilotAttachments, pilotRecords);

  const hostCounts = Object.fromEntries(
    [...new Set(moves.map((move) => move.host))]
      .sort()
      .map((host) => [host, moves.filter((move) => move.host === host).length])
  );
  const beforeNotes = (await regularFiles(path.join(mainRoot, "Notes"), { markdownOnly: true })).length;
  const beforeInbox = await stat(path.join(mainRoot, "Inbox", "Agents"))
    .then(() => regularFiles(path.join(mainRoot, "Inbox", "Agents"), { markdownOnly: true }))
    .then((files) => files.length)
    .catch((error) => {
      if (error?.code === "ENOENT") return 0;
      throw error;
    });
  return {
    version: 1,
    generated_at: new Date().toISOString(),
    roots: { main: mainRoot, legacy: legacyRoot, legacy_state: legacyState },
    counts: {
      notes_before: beforeNotes,
      inbox_before: beforeInbox,
      moved: moves.length,
      moved_by_host: hostCounts,
      link_files: linkUpdates.length,
      link_occurrences: linkUpdates.reduce(
        (total, update) => total + update.changes.reduce((sum, change) => sum + change.count, 0),
        0
      ),
      legacy_records: pilotRecords.length,
      legacy_attachments: pilotAttachments.length,
      notes_after: beforeNotes - moves.length,
      inbox_after: beforeInbox + moves.length + pilotRecords.length,
      active_after: beforeNotes + beforeInbox + pilotRecords.length,
      existing_attachments: existingAttachments.length
    },
    moves,
    link_updates: linkUpdates,
    existing_attachments: existingAttachments,
    pilot: {
      attachments: pilotAttachments,
      records: pilotRecords,
      operations: legacyOperations,
      attachment_uploads: attachmentUploads,
      record_attachments: recordAttachments
    }
  };
}

async function verifyFile(root, descriptor, field = "path") {
  const absolute = path.join(root, ...descriptor[field].split("/"));
  const info = await lstat(absolute);
  if (!info.isFile() || info.isSymbolicLink()) throw new Error(`not a regular file: ${descriptor[field]}`);
  const digest = await sha256File(absolute);
  const expected = field === "source_path" ? descriptor.source_sha256 ?? descriptor.sha256 : descriptor.sha256;
  if (digest !== expected) throw new Error(`SHA drift: ${descriptor[field]}`);
}

async function copyAtomic(source, destination, mode) {
  await mkdir(path.dirname(destination), { recursive: true });
  const temporary = path.join(path.dirname(destination), `.${path.basename(destination)}.${process.pid}.migration-tmp`);
  await copyFile(source, temporary);
  const handle = await open(temporary, "r+");
  try {
    await handle.chmod(mode);
    await handle.sync();
  } finally {
    await handle.close();
  }
  await rename(temporary, destination);
  await fsyncDirectory(path.dirname(destination));
}

function assertTargetAbsent(root, rel) {
  return lstat(path.join(root, ...rel.split("/"))).then(
    () => {
      throw new Error(`target already exists: ${rel}`);
    },
    (error) => {
      if (error?.code !== "ENOENT") throw error;
    }
  );
}

async function preflight(plan, targetState) {
  const mainRoot = await realpath(plan.roots.main);
  const legacyRoot = await realpath(plan.roots.legacy);
  const stateInfo = await stat(path.join(targetState, "journal.sqlite")).catch((error) => {
    if (error?.code === "ENOENT") return null;
    throw error;
  });
  if (stateInfo) throw new Error(`target state is not fresh: ${targetState}`);
  for (const move of plan.moves) {
    await verifyFile(mainRoot, move, "source_path");
    await assertTargetAbsent(mainRoot, move.target_path);
  }
  for (const update of plan.link_updates) await verifyFile(mainRoot, update, "source_path");
  for (const descriptor of plan.existing_attachments) await verifyFile(mainRoot, descriptor);
  for (const attachment of plan.pilot.attachments) {
    await verifyFile(legacyRoot, attachment, "source_path");
    if (!attachment.deduplicated) await assertTargetAbsent(mainRoot, attachment.target_path);
  }
  for (const record of plan.pilot.records) {
    await verifyFile(legacyRoot, record, "source_path");
    await assertTargetAbsent(mainRoot, record.target_path);
  }
}

function seedExistingAttachments(service, descriptors) {
  const seen = new Set();
  service.transaction(() => {
    for (const item of descriptors) {
      if (seen.has(item.sha256)) continue;
      seen.add(item.sha256);
      service.db
        .prepare(
          "INSERT INTO attachments(attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at, managed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)"
        )
        .run(
          `att_${item.sha256}`,
          item.sha256,
          item.path,
          item.byte_size,
          item.mime,
          path.basename(item.path),
          "legacy",
          item.modified_at
        );
    }
  });
}

function importPilotRows(service, pilot) {
  const existingSha = service.db.prepare("SELECT attachment_id FROM attachments WHERE sha256 = ?");
  service.transaction(() => {
    for (const item of pilot.attachments) {
      if (existingSha.get(item.sha256)) continue;
      service.db
        .prepare(
          "INSERT INTO attachments(attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at, managed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        )
        .run(
          item.attachment_id,
          item.sha256,
          item.target_path,
          item.byte_size,
          item.mime,
          item.original_name,
          item.source_host,
          item.created_at,
          item.managed
        );
    }
    for (const item of pilot.operations) {
      service.db
        .prepare(
          "INSERT INTO operations(operation_id, host, kind, request_hash, response_json, created_at) VALUES (?, ?, ?, ?, ?, ?)"
        )
        .run(item.operation_id, item.host, item.kind, item.request_hash, item.response_json, item.created_at);
    }
    for (const item of pilot.attachment_uploads) {
      service.db
        .prepare(
          "INSERT INTO attachment_uploads(operation_id, attachment_id, host, original_name, created_at) VALUES (?, ?, ?, ?, ?)"
        )
        .run(item.operation_id, item.attachment_id, item.host, item.original_name, item.created_at);
    }
    for (const item of pilot.records) {
      service.db
        .prepare(
          "INSERT INTO records(record_id, path, source_host, last_sha256, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
        )
        .run(item.record_id, item.target_path, item.source_host, item.target_sha256, item.created_at, item.updated_at);
    }
    for (const item of pilot.record_attachments) {
      service.db
        .prepare("INSERT INTO record_attachments(record_id, attachment_id, operation_id) VALUES (?, ?, ?)")
        .run(item.record_id, item.attachment_id, item.operation_id);
    }
  });
}

export async function applyMigration(plan, { targetState }) {
  await preflight(plan, targetState);
  const mainRoot = await realpath(plan.roots.main);
  const legacyRoot = await realpath(plan.roots.legacy);
  await mkdir(targetState, { recursive: true, mode: 0o700 });
  const service = await new KnowledgeService({
    mainRoot,
    legacyRoot,
    stateRoot: targetState
  }).initialize();
  try {
    seedExistingAttachments(service, plan.existing_attachments);
    for (const update of plan.link_updates) {
      const absolute = path.join(mainRoot, ...update.source_path.split("/"));
      const before = await readFile(absolute, "utf8");
      const rewritten = rewriteMany(
        before,
        update.changes.map(({ from, to, optional_markdown }) => ({ from, to, optional_markdown }))
      );
      if (sha256(Buffer.from(rewritten.content, "utf8")) !== update.target_sha256) {
        throw new Error(`link rewrite plan mismatch: ${update.source_path}`);
      }
      await atomicWrite(absolute, rewritten.content, update.mode);
    }
    for (const move of plan.moves) {
      const source = path.join(mainRoot, ...move.source_path.split("/"));
      const destination = path.join(mainRoot, ...move.target_path.split("/"));
      await mkdir(path.dirname(destination), { recursive: true });
      await rename(source, destination);
    }
    await fsyncDirectory(path.join(mainRoot, "Notes"));
    await fsyncDirectory(path.join(mainRoot, "Inbox", "Agents"));

    for (const attachment of plan.pilot.attachments) {
      if (attachment.deduplicated) continue;
      const source = path.join(legacyRoot, ...attachment.source_path.split("/"));
      const destination = path.join(mainRoot, ...attachment.target_path.split("/"));
      await copyAtomic(source, destination, attachment.mode);
    }
    for (const record of plan.pilot.records) {
      const source = path.join(legacyRoot, ...record.source_path.split("/"));
      const before = await readFile(source, "utf8");
      const rewritten = rewriteMany(before, [
        ...plan.pilot.attachments.map((item) => ({
          from: item.source_path,
          to: item.target_path,
          optional_markdown: false
        })),
        ...plan.pilot.records.map((item) => ({
          from: item.source_path.slice(0, -3),
          to: item.target_path.slice(0, -3),
          optional_markdown: true
        }))
      ]);
      if (sha256(Buffer.from(rewritten.content, "utf8")) !== record.target_sha256) {
        throw new Error(`record rewrite plan mismatch: ${record.source_path}`);
      }
      const destination = path.join(mainRoot, ...record.target_path.split("/"));
      await mkdir(path.dirname(destination), { recursive: true });
      await atomicWrite(destination, rewritten.content, record.mode);
    }
    importPilotRows(service, plan.pilot);
  } finally {
    service.close();
  }
  return verifyMigration(plan, { targetState });
}

export async function verifyMigration(plan, { targetState }) {
  const mainRoot = await realpath(plan.roots.main);
  for (const move of plan.moves) {
    const finalUpdate = plan.link_updates.find((item) => item.source_path === move.source_path);
    const expected = finalUpdate?.target_sha256 ?? move.source_sha256;
    const digest = await sha256File(path.join(mainRoot, ...move.target_path.split("/")));
    if (digest !== expected) throw new Error(`moved note verification failed: ${move.target_path}`);
  }
  for (const update of plan.link_updates.filter((item) => item.final_path === item.source_path)) {
    const digest = await sha256File(path.join(mainRoot, ...update.final_path.split("/")));
    if (digest !== update.target_sha256) throw new Error(`link update verification failed: ${update.final_path}`);
  }
  for (const attachment of plan.pilot.attachments) {
    const digest = await sha256File(path.join(mainRoot, ...attachment.target_path.split("/")));
    if (digest !== attachment.sha256) throw new Error(`attachment verification failed: ${attachment.target_path}`);
  }
  for (const record of plan.pilot.records) {
    const digest = await sha256File(path.join(mainRoot, ...record.target_path.split("/")));
    if (digest !== record.target_sha256) throw new Error(`record verification failed: ${record.target_path}`);
  }
  const db = new DatabaseSync(path.join(targetState, "journal.sqlite"), { readOnly: true });
  try {
    const records = db.prepare("SELECT COUNT(*) AS count FROM records").get().count;
    const operations = db.prepare("SELECT COUNT(*) AS count FROM operations").get().count;
    if (records !== plan.pilot.records.length || operations !== plan.pilot.operations.length) {
      throw new Error("journal row count verification failed");
    }
  } finally {
    db.close();
  }
  const notes = (await regularFiles(path.join(mainRoot, "Notes"), { markdownOnly: true })).length;
  const inbox = (await regularFiles(path.join(mainRoot, "Inbox", "Agents"), { markdownOnly: true })).length;
  if (notes !== plan.counts.notes_after || inbox !== plan.counts.inbox_after) {
    throw new Error(`active note count verification failed: Notes=${notes}, Inbox=${inbox}`);
  }
  return {
    notes,
    inbox,
    active: notes + inbox,
    moved: plan.moves.length,
    imported_records: plan.pilot.records.length,
    imported_attachments: plan.pilot.attachments.length
  };
}

function parseArguments(argv) {
  const [command, ...rest] = argv;
  if (!["plan", "apply", "verify"].includes(command)) throw new Error("usage: migrate-main.mjs plan|apply|verify [options]");
  const options = {};
  for (let index = 0; index < rest.length; index += 2) {
    const key = rest[index];
    const value = rest[index + 1];
    if (!key?.startsWith("--") || value === undefined) throw new Error(`invalid option: ${key ?? "<missing>"}`);
    options[key.slice(2).replaceAll("-", "_")] = value;
  }
  return { command, options };
}

async function cli() {
  const { command, options } = parseArguments(process.argv.slice(2));
  if (!options.manifest) throw new Error("--manifest is required");
  const manifestPath = path.resolve(options.manifest);
  if (command === "plan") {
    for (const required of ["main_root", "legacy_root", "legacy_state"]) {
      if (!options[required]) throw new Error(`--${required.replaceAll("_", "-")} is required`);
    }
    const plan = await buildMigrationPlan({
      mainRoot: options.main_root,
      legacyRoot: options.legacy_root,
      legacyState: options.legacy_state
    });
    const guards = [
      ["expect_moves", "moved"],
      ["expect_legacy_records", "legacy_records"],
      ["expect_legacy_attachments", "legacy_attachments"]
    ];
    for (const [option, field] of guards) {
      if (options[option] !== undefined && Number(options[option]) !== plan.counts[field]) {
        throw new Error(`${field} count ${plan.counts[field]} did not match guard ${options[option]}`);
      }
    }
    const body = `${JSON.stringify(plan, null, 2)}\n`;
    await mkdir(path.dirname(manifestPath), { recursive: true });
    await atomicWrite(manifestPath, body, 0o600);
    process.stdout.write(`${JSON.stringify({ ...plan.counts, manifest_sha256: sha256(body) }, null, 2)}\n`);
    return;
  }
  const plan = JSON.parse(await readFile(manifestPath, "utf8"));
  if (!options.target_state) throw new Error("--target-state is required");
  const result = command === "apply"
    ? await applyMigration(plan, { targetState: path.resolve(options.target_state) })
    : await verifyMigration(plan, { targetState: path.resolve(options.target_state) });
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) {
  cli().catch((error) => {
    process.stderr.write(`migrate-main: ${error.message}\n`);
    process.exitCode = 1;
  });
}
