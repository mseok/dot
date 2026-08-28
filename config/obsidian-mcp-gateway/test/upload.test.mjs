import assert from "node:assert/strict";
import { mkdir, readdir, readFile, symlink, writeFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { validateSourceFile } from "../src/bridge.mjs";
import { createFixture, digest, PNG_BYTES, TOKENS, upload } from "./helpers.mjs";

test("raw uploads are verified, idempotent, deduplicated, bounded, and credential-safe", async (t) => {
  const fixture = await createFixture({ maxFileBytes: 128 });
  t.after(() => fixture.close());

  const firstResponse = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0001", "figure.png", PNG_BYTES);
  assert.equal(firstResponse.status, 201);
  const first = await firstResponse.json();
  assert.equal(first.sha256, digest(PNG_BYTES));
  assert.equal(first.mime, "image/png");
  assert.equal(first.source_host, "local");
  assert.equal(first.deduplicated, false);
  assert.deepEqual(await readFile(path.join(fixture.mainRoot, first.path)), PNG_BYTES);
  assert.match(first.path, /^Attachments\/figure--[a-f0-9]{12}\.png$/);

  const retryResponse = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0001", "figure.png", PNG_BYTES);
  assert.equal(retryResponse.status, 200);
  assert.deepEqual(await retryResponse.json(), first);

  const dedupResponse = await upload(fixture.baseUrl, TOKENS.messi, "upload-messi-0001", "same.png", PNG_BYTES);
  assert.equal(dedupResponse.status, 201);
  const dedup = await dedupResponse.json();
  assert.equal(dedup.attachment_id, first.attachment_id);
  assert.equal(dedup.deduplicated, true);
  assert.equal(dedup.registered_by, "messi");
  const attachmentFiles = (await readdir(path.join(fixture.mainRoot, "Attachments"))).filter((name) => !name.startsWith("."));
  assert.deepEqual(attachmentFiles, [path.basename(first.path)]);

  const conflict = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0001", "different.bin", Buffer.from([0, 1]));
  assert.equal(conflict.status, 409);
  assert.equal((await conflict.json()).error.code, "operation_conflict");

  const mismatch = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0002", "bad.bin", Buffer.from([0, 1, 2]), {
    sha256: "0".repeat(64)
  });
  assert.equal(mismatch.status, 400);
  assert.equal((await mismatch.json()).error.code, "digest_mismatch");

  const oversizedBytes = Buffer.alloc(129, 7);
  const oversized = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0003", "large.bin", oversizedBytes);
  assert.equal(oversized.status, 413);
  assert.equal((await oversized.json()).error.code, "attachment_too_large");

  const opaqueBytes = Buffer.from([0, 1, 2, 3, 4, 5]);
  const opaqueResponse = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0004", "sample.opaque", opaqueBytes);
  assert.equal(opaqueResponse.status, 201);
  assert.equal((await opaqueResponse.json()).mime, "application/octet-stream");

  const credential = await upload(fixture.baseUrl, TOKENS.local, "upload-local-0005", ".env", Buffer.from("SECRET=x"));
  assert.equal(credential.status, 403);
  assert.equal((await credential.json()).error.code, "credential_file_rejected");

  const traversal = await upload(fixture.baseUrl, TOKENS.local, "../escape", "x.bin", Buffer.from([1]));
  assert.equal(traversal.status, 400);
  assert.equal((await traversal.json()).error.code, "invalid_request");

  const unauthorized = await upload(fixture.baseUrl, "x".repeat(40), "upload-local-0006", "x.bin", Buffer.from([1]));
  assert.equal(unauthorized.status, 401);
});

test("local bridge accepts only regular non-symlink files under resolved upload roots", async (t) => {
  const fixture = await createFixture();
  t.after(() => fixture.close());
  const allowed = path.join(fixture.uploadRoot, "allowed.bin");
  const outside = path.join(fixture.root, "outside.bin");
  const link = path.join(fixture.uploadRoot, "link.bin");
  const secret = path.join(fixture.uploadRoot, "id_ed25519");
  const hiddenDirectory = path.join(fixture.uploadRoot, ".hidden");
  const hiddenFile = path.join(hiddenDirectory, "figure.png");
  await writeFile(allowed, Buffer.from([1, 2, 3]));
  await writeFile(outside, Buffer.from([4]));
  await writeFile(secret, "not-a-real-key");
  await mkdir(hiddenDirectory);
  await writeFile(hiddenFile, PNG_BYTES);
  await symlink(allowed, link);
  const resolvedRoot = await import("node:fs/promises").then(({ realpath }) => realpath(fixture.uploadRoot));

  const accepted = await validateSourceFile(allowed, [resolvedRoot], 1024);
  assert.equal(accepted.size, 3);
  await assert.rejects(() => validateSourceFile(outside, [resolvedRoot], 1024), { code: "source_outside_allowed_roots" });
  await assert.rejects(() => validateSourceFile(link, [resolvedRoot], 1024), { code: "symlink_rejected" });
  await assert.rejects(() => validateSourceFile(fixture.uploadRoot, [resolvedRoot], 1024), { code: "not_regular_file" });
  await assert.rejects(() => validateSourceFile(secret, [resolvedRoot], 1024), { code: "credential_file_rejected" });
  await assert.rejects(() => validateSourceFile(hiddenFile, [resolvedRoot], 1024), { code: "hidden_path_rejected" });
});

test("managed attachment quota rejects new bytes but still permits deduplication", async (t) => {
  const fixture = await createFixture({ maxFileBytes: 64, maxVaultBytes: 4 });
  t.after(() => fixture.close());
  const firstBytes = Buffer.from([0, 1, 2, 3]);
  const first = await upload(fixture.baseUrl, TOKENS.local, "quota-local-0001", "first.bin", firstBytes);
  assert.equal(first.status, 201);
  const dedup = await upload(fixture.baseUrl, TOKENS.messi, "quota-messi-0001", "same.bin", firstBytes);
  assert.equal(dedup.status, 201);
  assert.equal((await dedup.json()).deduplicated, true);
  const overQuota = await upload(fixture.baseUrl, TOKENS.local, "quota-local-0002", "second.bin", Buffer.from([9]));
  assert.equal(overQuota.status, 507);
  assert.equal((await overQuota.json()).error.code, "attachment_quota_exceeded");
});
