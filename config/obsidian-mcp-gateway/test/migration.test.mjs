import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { sha256 } from "../src/common.mjs";
import { applyMigration, buildMigrationPlan } from "../src/migrate-main.mjs";
import { KnowledgeService } from "../src/service.mjs";
import { PNG_BYTES } from "./helpers.mjs";

test("main migration moves host notes, rewrites links, and preserves pilot journal lineage", async (t) => {
  const root = await mkdtemp(path.join(tmpdir(), "obsidian-main-migration-test-"));
  t.after(() => rm(root, { recursive: true, force: true }));
  const mainRoot = path.join(root, "main");
  const legacyRoot = path.join(root, "legacy");
  const legacyState = path.join(root, "legacy-state");
  const targetState = path.join(root, "target-state");
  await Promise.all([
    mkdir(path.join(mainRoot, "Notes"), { recursive: true }),
    mkdir(path.join(mainRoot, "Attachments"), { recursive: true }),
    mkdir(path.join(legacyRoot, "Notes"), { recursive: true }),
    mkdir(path.join(legacyRoot, "Attachments"), { recursive: true })
  ]);
  const movedName = "2026-08-27 GPU result.md";
  await writeFile(
    path.join(mainRoot, "Notes", movedName),
    "---\ntitle: GPU result\ncreated: 2026-08-27\nhost: gpu22\ntags: [kind/log]\n---\n\nResult.\n"
  );
  await writeFile(
    path.join(mainRoot, "Notes", "Human note.md"),
    "---\ntitle: Human note\ncreated: 2026-08-27\ntags: [kind/concept]\n---\n\n"
      + "[[Notes/2026-08-27 GPU result|result]]\n"
  );
  await writeFile(path.join(mainRoot, "Attachments", "existing.txt"), "existing");

  const attachmentDigest = sha256(PNG_BYTES);
  const legacyAttachmentPath = `Attachments/${attachmentDigest}.png`;
  await writeFile(path.join(legacyRoot, legacyAttachmentPath), PNG_BYTES);
  const recordId = "11111111-2222-4333-8444-555555555555";
  const legacyRecordPath = "Notes/2026-08-27 Pilot record--11111111.md";
  const recordContent =
    "---\ntitle: Pilot record\ncreated: 2026-08-27\ntags: [kind/log]\n"
    + `record_id: \"${recordId}\"\noperation_id: \"record-op\"\nhost: \"messi\"\n---\n\n`
    + `![[${legacyAttachmentPath}]]\n`;
  await writeFile(path.join(legacyRoot, legacyRecordPath), recordContent);
  const service = await new KnowledgeService({ mainRoot: legacyRoot, legacyRoot, stateRoot: legacyState }).initialize();
  service.transaction(() => {
    service.db
      .prepare(
        "INSERT INTO attachments(attachment_id, sha256, path, byte_size, mime, original_name, source_host, created_at, managed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)"
      )
      .run(
        `att_${attachmentDigest}`,
        attachmentDigest,
        legacyAttachmentPath,
        PNG_BYTES.length,
        "image/png",
        "한글 image.png",
        "messi",
        "2026-08-27T00:00:00.000Z"
      );
    const uploadResponse = JSON.stringify({
      attachment_id: `att_${attachmentDigest}`,
      path: legacyAttachmentPath,
      sha256: attachmentDigest,
      byte_size: PNG_BYTES.length,
      mime: "image/png",
      original_name: "한글 image.png",
      source_host: "messi",
      registered_by: "messi",
      wikilink: `![[${legacyAttachmentPath}]]`,
      deduplicated: false
    });
    const recordResponse = JSON.stringify({
      record_id: recordId,
      path: legacyRecordPath,
      sha256: sha256(recordContent),
      source_host: "messi",
      attachment_ids: [`att_${attachmentDigest}`],
      wikilink: "[[Notes/2026-08-27 Pilot record--11111111]]"
    });
    service.db
      .prepare(
        "INSERT INTO operations(operation_id, host, kind, request_hash, response_json, created_at) VALUES (?, ?, ?, ?, ?, ?)"
      )
      .run("upload-op", "messi", "attachment_upload", "upload-request", uploadResponse, "2026-08-27T00:00:00.000Z");
    service.db
      .prepare(
        "INSERT INTO operations(operation_id, host, kind, request_hash, response_json, created_at) VALUES (?, ?, ?, ?, ?, ?)"
      )
      .run("record-op", "messi", "record_create", "record-request", recordResponse, "2026-08-27T00:01:00.000Z");
    service.db
      .prepare(
        "INSERT INTO attachment_uploads(operation_id, attachment_id, host, original_name, created_at) VALUES (?, ?, ?, ?, ?)"
      )
      .run("upload-op", `att_${attachmentDigest}`, "messi", "한글 image.png", "2026-08-27T00:00:00.000Z");
    service.db
      .prepare(
        "INSERT INTO records(record_id, path, source_host, last_sha256, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
      )
      .run(
        recordId,
        legacyRecordPath,
        "messi",
        sha256(recordContent),
        "2026-08-27T00:01:00.000Z",
        "2026-08-27T00:01:00.000Z"
      );
    service.db
      .prepare("INSERT INTO record_attachments(record_id, attachment_id, operation_id) VALUES (?, ?, ?)")
      .run(recordId, `att_${attachmentDigest}`, "record-op");
  });
  service.close();

  const plan = await buildMigrationPlan({ mainRoot, legacyRoot, legacyState });
  assert.equal(plan.counts.moved, 1);
  assert.equal(plan.counts.link_occurrences, 1);
  assert.equal(plan.counts.legacy_records, 1);
  assert.match(plan.pilot.attachments[0].target_path, /^Attachments\/한글 image--[a-f0-9]{12}\.png$/u);
  const result = await applyMigration(plan, { targetState });
  assert.deepEqual(result, {
    notes: 1,
    inbox: 2,
    active: 3,
    moved: 1,
    imported_records: 1,
    imported_attachments: 1
  });
  assert.match(
    await readFile(path.join(mainRoot, "Notes", "Human note.md"), "utf8"),
    /\[\[Inbox\/Agents\/gpu22\/2026-08-27 GPU result\|result\]\]/
  );
  const importedRecord = await readFile(path.join(mainRoot, plan.pilot.records[0].target_path), "utf8");
  assert.match(importedRecord, new RegExp(plan.pilot.attachments[0].target_path.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));

  const migrated = await new KnowledgeService({ mainRoot, legacyRoot, stateRoot: targetState }).initialize();
  t.after(() => migrated.close());
  const retried = migrated.checkOperation("record-op", "messi", "record_create", "record-request");
  assert.equal(retried.path, plan.pilot.records[0].target_path);
  assert.equal(retried.sha256, plan.pilot.records[0].target_sha256);
});
