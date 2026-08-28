#!/usr/bin/env node
import { createHash, randomUUID } from "node:crypto";
import { createReadStream } from "node:fs";
import { open, unlink } from "node:fs/promises";
import { createServer } from "node:http";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { authenticateBearer, buildTokenRegistry, loadKeychainTokenEntries, requireScope } from "./auth.mjs";
import { asGatewayError, GatewayError, safeDisplayName } from "./common.mjs";
import { createGatewayMcpServer } from "./mcp-server.mjs";
import {
  parseOrThrow,
  attachmentPreviewSchema,
  knowledgeBatchReadSchema,
  knowledgeFrontmatterSchema,
  knowledgeListSchema,
  knowledgeOutlineSchema,
  knowledgeReadSchema,
  knowledgeSearchSchema,
  knowledgeSectionReadSchema,
  knowledgeTagSearchSchema,
  operationIdSchema,
  recordAppendSchema,
  recordCreateSchema
} from "./schemas.mjs";
import { inspectUploadedTemp, KnowledgeService } from "./service.mjs";

const JSON_LIMIT = 2 * 1024 * 1024;

function setSecurityHeaders(response) {
  response.setHeader("Cache-Control", "no-store");
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Referrer-Policy", "no-referrer");
}

function writeJson(response, status, value, extraHeaders = {}) {
  const body = Buffer.from(JSON.stringify(value));
  setSecurityHeaders(response);
  response.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": body.length,
    ...extraHeaders
  });
  response.end(body);
}

function writeError(response, error) {
  if (response.headersSent) return response.end();
  const safe = asGatewayError(error);
  writeJson(
    response,
    safe.status,
    {
      error: {
        code: safe.code,
        message: safe.message,
        ...(safe.details === undefined ? {} : { details: safe.details })
      }
    },
    safe.status === 401 ? { "WWW-Authenticate": 'Bearer realm="obsidian-mcp-main"' } : {}
  );
}

async function readJson(request) {
  const contentType = request.headers["content-type"] ?? "";
  if (!contentType.toLowerCase().startsWith("application/json")) throw new GatewayError(415, "json_required");
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > JSON_LIMIT) throw new GatewayError(413, "json_too_large");
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw new GatewayError(400, "invalid_json");
  }
}

function singleHeader(request, name) {
  const value = request.headers[name];
  if (Array.isArray(value) || typeof value !== "string") throw new GatewayError(400, `missing_${name.replaceAll("-", "_")}`);
  return value;
}

function decodeOriginalName(request) {
  try {
    return safeDisplayName(decodeURIComponent(singleHeader(request, "x-original-name")));
  } catch (error) {
    if (error instanceof URIError) throw new GatewayError(400, "invalid_original_name");
    throw error;
  }
}

async function streamUpload(request, tempPath, maxBytes) {
  const handle = await open(tempPath, "wx", 0o600);
  const hash = createHash("sha256");
  let size = 0;
  let oversized = false;
  try {
    for await (const chunk of request) {
      size += chunk.length;
      if (size > maxBytes) {
        oversized = true;
        continue;
      }
      hash.update(chunk);
      await handle.write(chunk);
    }
    if (oversized) throw new GatewayError(413, "attachment_too_large");
    await handle.sync();
  } finally {
    await handle.close().catch(() => {});
  }
  return { size, sha256: hash.digest("hex") };
}

async function handleRawUpload(request, response, service, identity, operationId) {
  requireScope(identity, "attachment:write");
  parseOrThrow(operationIdSchema, operationId);
  const expectedSha256 = singleHeader(request, "x-content-sha256").toLowerCase();
  if (!/^[a-f0-9]{64}$/.test(expectedSha256)) throw new GatewayError(400, "invalid_content_sha256");
  const expectedSizeText = singleHeader(request, "x-content-size");
  if (!/^(0|[1-9][0-9]{0,12})$/.test(expectedSizeText)) throw new GatewayError(400, "invalid_content_size");
  const expectedSize = Number(expectedSizeText);
  if (!Number.isSafeInteger(expectedSize)) throw new GatewayError(400, "invalid_content_size");
  if (expectedSize > service.maxFileBytes) {
    request.resume();
    throw new GatewayError(413, "attachment_too_large");
  }
  const contentLength = request.headers["content-length"];
  if (contentLength !== undefined && Number(contentLength) !== expectedSize) {
    request.resume();
    throw new GatewayError(400, "content_length_mismatch");
  }
  const originalName = decodeOriginalName(request);
  const requestDigest = service.attachmentRequestDigest(identity.host, {
    operationId,
    expectedSha256,
    expectedSize,
    originalName
  });
  const retry = await service.findOperation(operationId, identity.host, "attachment_upload", requestDigest);
  if (retry) {
    request.resume();
    return writeJson(response, 200, retry);
  }
  const tempPath = path.join(service.mainRoot, "Attachments", `.mcp-incoming-${operationId}-${randomUUID()}.tmp`);
  try {
    const streamed = await streamUpload(request, tempPath, service.maxFileBytes);
    if (streamed.size !== expectedSize) throw new GatewayError(400, "content_size_mismatch");
    if (streamed.sha256 !== expectedSha256) throw new GatewayError(400, "digest_mismatch");
    const inspected = await inspectUploadedTemp(tempPath, originalName);
    if (inspected.sha256 !== expectedSha256 || inspected.byteSize !== expectedSize) {
      throw new GatewayError(400, "post_write_verification_failed");
    }
    const receipt = await service.registerAttachment({
      host: identity.host,
      operationId,
      requestDigest,
      tempPath,
      sha256: inspected.sha256,
      byteSize: inspected.byteSize,
      mime: inspected.mime,
      originalName
    });
    return writeJson(response, 201, receipt);
  } catch (error) {
    await unlink(tempPath).catch(() => {});
    throw error;
  }
}

async function handleJsonTool(request, response, service, identity, route) {
  const body = await readJson(request);
  if (route === "/v1/tools/attachment-preview") {
    requireScope(identity, "attachment:read");
    const preview = await service.attachmentPreview(parseOrThrow(attachmentPreviewSchema, body));
    return writeJson(response, 200, { ...preview.metadata, has_image_preview: Boolean(preview.image) });
  }
  if (route === "/v1/tools/knowledge-search") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeSearch(parseOrThrow(knowledgeSearchSchema, body)));
  }
  if (route === "/v1/tools/knowledge-list") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeList(parseOrThrow(knowledgeListSchema, body)));
  }
  if (route === "/v1/tools/knowledge-read") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeRead(parseOrThrow(knowledgeReadSchema, body)));
  }
  if (route === "/v1/tools/knowledge-batch-read") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeBatchRead(parseOrThrow(knowledgeBatchReadSchema, body)));
  }
  if (route === "/v1/tools/knowledge-frontmatter") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeFrontmatter(parseOrThrow(knowledgeFrontmatterSchema, body)));
  }
  if (route === "/v1/tools/knowledge-outline") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeOutline(parseOrThrow(knowledgeOutlineSchema, body)));
  }
  if (route === "/v1/tools/knowledge-section-read") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeSectionRead(parseOrThrow(knowledgeSectionReadSchema, body)));
  }
  if (route === "/v1/tools/knowledge-tag-search") {
    requireScope(identity, "knowledge:read");
    return writeJson(response, 200, await service.knowledgeTagSearch(parseOrThrow(knowledgeTagSearchSchema, body)));
  }
  if (route === "/v1/tools/record-create") {
    requireScope(identity, "record:write");
    return writeJson(response, 201, await service.recordCreate(identity.host, parseOrThrow(recordCreateSchema, body)));
  }
  if (route === "/v1/tools/record-append") {
    requireScope(identity, "record:write");
    return writeJson(response, 200, await service.recordAppend(identity.host, parseOrThrow(recordAppendSchema, body)));
  }
  throw new GatewayError(404, "not_found");
}

async function handleMcp(request, response, service, identity) {
  if (request.method !== "POST") throw new GatewayError(405, "method_not_allowed");
  const mcp = createGatewayMcpServer(service, identity);
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
  await mcp.connect(transport);
  response.on("close", () => {
    transport.close().catch(() => {});
    mcp.close().catch(() => {});
  });
  await transport.handleRequest(request, response);
}

export async function createGateway({ service, tokenEntries, bind = "127.0.0.1", port = 39123 }) {
  const registry = buildTokenRegistry(tokenEntries);
  const server = createServer(async (request, response) => {
    try {
      const url = new URL(request.url, `http://${request.headers.host ?? "localhost"}`);
      if (request.method === "GET" && url.pathname === "/healthz") {
        const status = service.status();
        return writeJson(response, 200, { status: status.status, writer: status.writer, main: status.main });
      }
      const identity = authenticateBearer(request.headers.authorization, registry);
      if (url.pathname === "/mcp") return await handleMcp(request, response, service, identity);
      const uploadMatch = url.pathname.match(/^\/v1\/attachments\/([^/]+)$/);
      if (request.method === "PUT" && uploadMatch) {
        let operationId;
        try {
          operationId = decodeURIComponent(uploadMatch[1]);
        } catch {
          throw new GatewayError(400, "invalid_request");
        }
        return await handleRawUpload(request, response, service, identity, operationId);
      }
      const previewMatch = url.pathname.match(/^\/v1\/attachments\/(att_[a-f0-9]{64})\/preview$/);
      if (request.method === "GET" && previewMatch) {
        requireScope(identity, "attachment:read");
        const preview = await service.attachmentPreview(previewMatch[1]);
        if (!preview.image) throw new GatewayError(415, "not_an_image");
        setSecurityHeaders(response);
        response.writeHead(200, {
          "Content-Type": preview.image.mime,
          "Content-Length": preview.image.byte_size,
          "Content-Disposition": "inline"
        });
        return createReadStream(preview.image.path).pipe(response);
      }
      const metadataMatch = url.pathname.match(/^\/v1\/attachments\/(att_[a-f0-9]{64})$/);
      if (request.method === "GET" && metadataMatch) {
        requireScope(identity, "attachment:read");
        return writeJson(response, 200, service.getAttachment(metadataMatch[1]));
      }
      if (request.method === "POST" && url.pathname.startsWith("/v1/tools/")) {
        return await handleJsonTool(request, response, service, identity, url.pathname);
      }
      throw new GatewayError(404, "not_found");
    } catch (error) {
      writeError(response, error);
    }
  });
  server.requestTimeout = 15 * 60 * 1000;
  server.headersTimeout = 30 * 1000;
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, bind, resolve);
  });
  return {
    server,
    service,
    address: server.address(),
    async close() {
      await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())));
      service.close();
    }
  };
}

async function main() {
  const mainRoot = process.env.OBSIDIAN_MAIN_VAULT_ROOT;
  const legacyRoot = process.env.OBSIDIAN_LEGACY_VAULT_ROOT;
  const stateRoot = process.env.OBSIDIAN_STATE_ROOT;
  const keychainService = process.env.OBSIDIAN_GATEWAY_KEYCHAIN_SERVICE ?? "local.obsidian-mcp-gateway.tokens";
  if (!mainRoot || !legacyRoot || !stateRoot) throw new Error("Main, legacy, and state root environment variables are required");
  const service = await new KnowledgeService({ mainRoot, legacyRoot, stateRoot }).initialize();
  const tokenEntries = loadKeychainTokenEntries({ service: keychainService });
  const gateway = await createGateway({
    service,
    tokenEntries,
    bind: process.env.OBSIDIAN_GATEWAY_BIND ?? "127.0.0.1",
    port: Number(process.env.OBSIDIAN_GATEWAY_PORT ?? "39123")
  });
  const shutdown = async () => {
    await gateway.close();
    process.exit(0);
  };
  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
  console.error(`Obsidian MCP main gateway listening on ${gateway.address.address}:${gateway.address.port}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
