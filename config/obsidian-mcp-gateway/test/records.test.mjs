import assert from "node:assert/strict";
import { appendFile, readdir, readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { api, createFixture, PNG_BYTES, TOKENS, upload } from "./helpers.mjs";

async function json(response) {
  const value = await response.json();
  return { response, value };
}

test("records are isolated, retry-safe, sequential under concurrency, and reject human edits", async (t) => {
  const fixture = await createFixture();
  t.after(() => fixture.close());
  const mainBefore = await readFile(path.join(fixture.mainRoot, "Notes", "main evidence.md"), "utf8");

  const search = await json(
    await api(fixture.baseUrl, TOKENS.local, "/v1/tools/knowledge-search", {
      query: "Immutable main evidence",
      namespace: "main",
      limit: 20
    })
  );
  assert.equal(search.response.status, 200);
  assert.equal(search.value.results[0].namespace, "main");
  const read = await json(
    await api(fixture.baseUrl, TOKENS.local, "/v1/tools/knowledge-read", {
      namespace: "main",
      path: "Notes/main evidence.md"
    })
  );
  assert.equal(read.response.status, 200);
  assert.match(read.value.content, /Immutable main evidence/);

  const outsideNotes = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/knowledge-read", {
    namespace: "main",
    path: ".obsidian/private.md"
  });
  assert.equal(outsideNotes.status, 400);
  assert.equal((await outsideNotes.json()).error.code, "invalid_path");

  const invalidPrefix = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/knowledge-list", {
    namespace: "main",
    path_prefix: "../Archive",
    limit: 20
  });
  assert.equal(invalidPrefix.status, 400);
  assert.equal((await invalidPrefix.json()).error.code, "invalid_path_prefix");

  const uploaded = await (await upload(fixture.baseUrl, TOKENS.gpu22, "upload-gpu22-0001", "gpu22.png", PNG_BYTES)).json();
  const missingProject = await api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-create", {
    title: "Remote record without project",
    body: "Must be rejected.",
    tags: ["kind/log"],
    operation_id: "record-gpu22-no-project"
  });
  assert.equal(missingProject.status, 400);
  assert.equal((await missingProject.json()).error.code, "project_required");
  const createBody = {
    title: "GPU22 raw upload pilot",
    body: "The attachment used the raw-byte route.",
    tags: ["kind/log", "topic/obsidian-mcp"],
    project: "MCP Pilot",
    attachment_ids: [uploaded.attachment_id],
    operation_id: "record-gpu22-0001"
  };
  const createdResponse = await api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-create", createBody);
  assert.equal(createdResponse.status, 201);
  const created = await createdResponse.json();
  assert.match(created.path, /^Inbox\/Agents\/gpu22\/2026-08-27 GPU22 raw upload pilot--[a-f0-9]{8}\.md$/);

  const retry = await api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-create", createBody);
  assert.equal(retry.status, 201);
  assert.deepEqual(await retry.json(), created);
  assert.equal((await readdir(path.join(fixture.mainRoot, "Inbox", "Agents", "gpu22"))).length, 1);

  const appendA = api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-append", {
    record_id: created.record_id,
    body: "Concurrent append A",
    operation_id: "append-messi-0001"
  });
  const appendB = api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-append", {
    record_id: created.record_id,
    body: "Concurrent append B",
    operation_id: "append-local-0001"
  });
  const [resultA, resultB] = await Promise.all([appendA, appendB]);
  assert.equal(resultA.status, 200);
  assert.equal(resultB.status, 200);
  const recordPath = path.join(fixture.mainRoot, created.path);
  const afterConcurrent = await readFile(recordPath, "utf8");
  assert.match(afterConcurrent, /Concurrent append A/);
  assert.match(afterConcurrent, /Concurrent append B/);

  await appendFile(recordPath, "\nHuman edit.\n");
  const wrongHost = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/record-append", {
    record_id: created.record_id,
    body: "Must reject cross-host append",
    operation_id: "append-local-0002"
  });
  assert.equal(wrongHost.status, 403);
  assert.equal((await wrongHost.json()).error.code, "record_host_mismatch");

  const humanConflict = await api(fixture.baseUrl, TOKENS.gpu22, "/v1/tools/record-append", {
    record_id: created.record_id,
    body: "Must not merge",
    operation_id: "append-gpu22-0003"
  });
  assert.equal(humanConflict.status, 409);
  assert.equal((await humanConflict.json()).error.code, "human_edit_detected");

  const spoofed = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/record-create", {
    ...createBody,
    operation_id: "record-local-0002",
    host: "gpu22"
  });
  assert.equal(spoofed.status, 400);
  assert.equal((await spoofed.json()).error.code, "invalid_request");

  const destination = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/record-create", {
    ...createBody,
    operation_id: "record-local-0003",
    destination_path: "../main/Notes/escape.md"
  });
  assert.equal(destination.status, 400);
  assert.equal((await destination.json()).error.code, "invalid_request");

  const nonexistentWrite = await api(fixture.baseUrl, TOKENS.local, "/v1/tools/main-write", { path: "Notes/x.md" });
  assert.equal(nonexistentWrite.status, 404);
  assert.equal(await readFile(path.join(fixture.mainRoot, "Notes", "main evidence.md"), "utf8"), mainBefore);
});
