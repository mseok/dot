#!/usr/bin/env node
import assert from "node:assert/strict";

const baseUrl = process.env.OBSIDIAN_GATEWAY_URL;
const token = process.env.OBSIDIAN_GATEWAY_TOKEN;
const query = process.env.OBSIDIAN_MAIN_SEARCH_QUERY ?? "K-Fold";
if (!baseUrl || !token) throw new Error("OBSIDIAN_GATEWAY_URL and OBSIDIAN_GATEWAY_TOKEN are required");

async function request(route, body, bearer = token) {
  const response = await fetch(new URL(route, `${baseUrl.replace(/\/$/, "")}/`), {
    method: "POST",
    headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  const value = await response.json();
  return { status: response.status, value };
}

const search = await request("v1/tools/knowledge-search", { query, namespace: "main", limit: 1 });
assert.equal(search.status, 200);
assert.equal(search.value.count, 1);
const result = search.value.results[0];
const read = await request("v1/tools/knowledge-read", { namespace: "main", path: result.path });
assert.equal(read.status, 200);
assert.equal(read.value.sha256, result.sha256);

const spoof = await request("v1/tools/record-create", {
  title: "Rejected",
  body: "Must not write",
  tags: ["kind/log"],
  operation_id: "reject-local-spoof-0001",
  host: "gpu22"
});
const destination = await request("v1/tools/record-create", {
  title: "Rejected",
  body: "Must not write",
  tags: ["kind/log"],
  operation_id: "reject-local-path-0001",
  destination_path: "../main/Notes/escape.md"
});
const mainWrite = await request("v1/tools/main-write", { path: "Notes/escape.md", body: "no" });
const wrongToken = await request(
  "v1/tools/knowledge-search",
  { query, namespace: "main", limit: 1 },
  "definitely-wrong-token"
);

assert.deepEqual([spoof.status, destination.status, mainWrite.status, wrongToken.status], [400, 400, 404, 401]);
assert.equal(spoof.value.error.code, "invalid_request");
assert.equal(destination.value.error.code, "invalid_request");
assert.equal(mainWrite.value.error.code, "not_found");
assert.equal(wrongToken.value.error.code, "unauthorized");

process.stdout.write(
  `${JSON.stringify({
    main_read: {
      namespace: result.namespace,
      path: result.path,
      sha256: result.sha256,
      content_bytes: Buffer.byteLength(read.value.content, "utf8")
    },
    rejected: {
      host_spoof: `${spoof.status} ${spoof.value.error.code}`,
      destination_path: `${destination.status} ${destination.value.error.code}`,
      main_write: `${mainWrite.status} ${mainWrite.value.error.code}`,
      wrong_token: `${wrongToken.status} ${wrongToken.value.error.code}`
    }
  })}\n`
);
