import assert from "node:assert/strict";
import { realpath, writeFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { createBridgeMcpServer } from "../src/bridge.mjs";
import { createFixture, PNG_BYTES, TOKENS } from "./helpers.mjs";

test("HTTP gateway initializes and bridge exposes bounded knowledge tools plus raw upload", async (t) => {
  const fixture = await createFixture();
  t.after(() => fixture.close());

  const directClient = new Client({ name: "gateway-test-client", version: "1.0.0" });
  const directTransport = new StreamableHTTPClientTransport(new URL(`${fixture.baseUrl}/mcp`), {
    requestInit: { headers: { Authorization: `Bearer ${TOKENS.local}` } }
  });
  await directClient.connect(directTransport);
  t.after(() => directClient.close());
  const directTools = await directClient.listTools();
  assert.deepEqual(
    directTools.tools.map((tool) => tool.name).sort(),
    [
      "attachment_preview",
      "knowledge_batch_read",
      "knowledge_frontmatter",
      "knowledge_list",
      "knowledge_outline",
      "knowledge_read",
      "knowledge_search",
      "knowledge_section_read",
      "knowledge_tag_search",
      "record_append",
      "record_create"
    ]
  );
  const searchResult = await directClient.callTool({
    name: "knowledge_search",
    arguments: { query: "Immutable main evidence", namespace: "main", limit: 5 }
  });
  assert.equal(searchResult.isError, undefined);

  const listResult = await directClient.callTool({
    name: "knowledge_list",
    arguments: { namespace: "main", path_prefix: "Notes/", limit: 10 }
  });
  assert.equal(listResult.structuredContent.count, 1);
  assert.equal(listResult.structuredContent.results[0].path, "Notes/main evidence.md");

  const slicedRead = await directClient.callTool({
    name: "knowledge_read",
    arguments: { namespace: "main", path: "Notes/main evidence.md", start_line: 10, line_limit: 3 }
  });
  assert.equal(slicedRead.structuredContent.truncated, true);
  assert.match(slicedRead.structuredContent.content, /# Architecture/);

  const frontmatter = await directClient.callTool({
    name: "knowledge_frontmatter",
    arguments: { namespace: "main", path: "Notes/main evidence.md" }
  });
  assert.deepEqual(frontmatter.structuredContent.tags, ["inline-tag", "kind/reference", "topic/mcp"]);

  const outline = await directClient.callTool({
    name: "knowledge_outline",
    arguments: { namespace: "main", path: "Notes/main evidence.md" }
  });
  assert.deepEqual(
    outline.structuredContent.headings.map((heading) => heading.heading_path),
    ["Architecture", "Architecture::결과", "Decision"]
  );

  const section = await directClient.callTool({
    name: "knowledge_section_read",
    arguments: { namespace: "main", path: "Notes/main evidence.md", heading_path: "결과" }
  });
  assert.match(section.structuredContent.content, /Nested result/);
  assert.doesNotMatch(section.structuredContent.content, /# Decision/);

  const tagSearch = await directClient.callTool({
    name: "knowledge_tag_search",
    arguments: { tag: "topic/mcp", namespace: "main", limit: 10 }
  });
  assert.equal(tagSearch.structuredContent.count, 1);

  const batch = await directClient.callTool({
    name: "knowledge_batch_read",
    arguments: { files: [{ namespace: "main", path: "Notes/main evidence.md" }], max_total_chars: 1000 }
  });
  assert.equal(batch.structuredContent.count, 1);
  assert.match(batch.structuredContent.results[0].content, /Immutable main evidence/);

  const source = path.join(fixture.uploadRoot, "bridge-figure.png");
  await writeFile(source, PNG_BYTES);
  const bridgeServer = await createBridgeMcpServer({
    gatewayUrl: fixture.baseUrl,
    token: TOKENS.local,
    uploadRoots: [await realpath(fixture.uploadRoot)]
  });
  const bridgeClient = new Client({ name: "bridge-test-client", version: "1.0.0" });
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  await Promise.all([bridgeServer.connect(serverTransport), bridgeClient.connect(clientTransport)]);
  t.after(() => bridgeClient.close());
  t.after(() => bridgeServer.close());

  const bridgeTools = await bridgeClient.listTools();
  assert.deepEqual(
    bridgeTools.tools.map((tool) => tool.name).sort(),
    [
      "attachment_preview",
      "attachment_upload",
      "knowledge_batch_read",
      "knowledge_frontmatter",
      "knowledge_list",
      "knowledge_outline",
      "knowledge_read",
      "knowledge_search",
      "knowledge_section_read",
      "knowledge_tag_search",
      "record_append",
      "record_create"
    ]
  );
  const uploadResult = await bridgeClient.callTool({
    name: "attachment_upload",
    arguments: { source_path: source, operation_id: "bridge-upload-0001" }
  });
  assert.equal(uploadResult.isError, undefined, JSON.stringify(uploadResult));
  const receipt = uploadResult.structuredContent;
  assert.equal(receipt.mime, "image/png");

  const previewResult = await bridgeClient.callTool({
    name: "attachment_preview",
    arguments: { attachment_id: receipt.attachment_id }
  });
  assert.equal(previewResult.isError, undefined, JSON.stringify(previewResult));
  const image = previewResult.content.find((item) => item.type === "image");
  assert.ok(image);
  assert.equal(image.mimeType, "image/png");
  assert.ok(image.data.length > 0);

  const previewByPath = await bridgeClient.callTool({
    name: "attachment_preview",
    arguments: { path: receipt.path }
  });
  assert.equal(previewByPath.isError, undefined, JSON.stringify(previewByPath));
  assert.equal(previewByPath.structuredContent.sha256, receipt.sha256);
});
