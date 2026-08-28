#!/usr/bin/env node
import { createHash } from "node:crypto";
import { Resolver } from "node:dns/promises";
import { createReadStream } from "node:fs";
import { lstat, readFile, realpath, stat } from "node:fs/promises";
import { request as httpRequest } from "node:http";
import { request as httpsRequest } from "node:https";
import { isIP } from "node:net";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  attachmentPreviewSchema,
  attachmentUploadSchema,
  knowledgeBatchReadSchema,
  knowledgeFrontmatterSchema,
  knowledgeListSchema,
  knowledgeOutlineSchema,
  knowledgeReadSchema,
  knowledgeSectionReadSchema,
  knowledgeSearchSchema,
  knowledgeTagSearchSchema,
  recordAppendSchema,
  recordCreateSchema
} from "./schemas.mjs";
import { asGatewayError, GatewayError, isCredentialLikeName, isInside, safeDisplayName } from "./common.mjs";

const DEFAULT_MAX_FILE_BYTES = 256 * 1024 * 1024;
const DEFAULT_MAX_PREVIEW_BYTES = 4 * 1024 * 1024;
const DEFAULT_MAX_JSON_RESPONSE_BYTES = 2 * 1024 * 1024;

function success(value, content = []) {
  return {
    content: [{ type: "text", text: JSON.stringify(value, null, 2) }, ...content],
    structuredContent: value
  };
}

function failure(error) {
  const safe = asGatewayError(error);
  return {
    isError: true,
    content: [
      {
        type: "text",
        text: JSON.stringify(
          {
            error: {
              code: safe.code,
              message: safe.message,
              ...(safe.details === undefined ? {} : { details: safe.details })
            }
          },
          null,
          2
        )
      }
    ]
  };
}

function guarded(callback) {
  return async (input) => {
    try {
      return await callback(input);
    } catch (error) {
      return failure(error);
    }
  };
}

function validateGatewayUrl(value) {
  const url = new URL(value);
  const loopback = url.hostname === "127.0.0.1" || url.hostname === "localhost" || url.hostname === "::1";
  if (url.protocol !== "https:" && !(url.protocol === "http:" && loopback)) {
    throw new Error("OBSIDIAN_GATEWAY_URL must use HTTPS except for loopback testing");
  }
  if (url.pathname !== "/" && url.pathname !== "") throw new Error("OBSIDIAN_GATEWAY_URL must not contain a path");
  url.pathname = "/";
  url.search = "";
  url.hash = "";
  return url;
}

export async function resolveUploadRoots(value) {
  const rawRoots = value
    .split(path.delimiter)
    .map((item) => item.trim())
    .filter(Boolean);
  if (rawRoots.length === 0) throw new Error("OBSIDIAN_UPLOAD_ROOTS must contain at least one directory");
  const roots = [];
  for (const root of rawRoots) {
    const absolute = await realpath(path.resolve(root));
    const info = await stat(absolute);
    if (!info.isDirectory()) throw new Error(`Upload root is not a directory: ${root}`);
    roots.push(absolute);
  }
  return [...new Set(roots)];
}

export async function validateSourceFile(
  sourcePath,
  roots,
  maxFileBytes = DEFAULT_MAX_FILE_BYTES,
  displayName,
  denyRoots = []
) {
  const absoluteInput = path.resolve(sourcePath);
  const inputInfo = await lstat(absoluteInput).catch((error) => {
    if (error?.code === "ENOENT") throw new GatewayError(404, "source_not_found");
    throw error;
  });
  if (inputInfo.isSymbolicLink()) throw new GatewayError(403, "symlink_rejected");
  if (!inputInfo.isFile()) throw new GatewayError(403, "not_regular_file");
  const resolved = await realpath(absoluteInput);
  const matchedRoot = roots.find((root) => isInside(root, resolved));
  if (!matchedRoot) throw new GatewayError(403, "source_outside_allowed_roots");
  if (denyRoots.some((root) => isInside(root, resolved))) throw new GatewayError(403, "source_denied");
  const relativeParts = path.relative(matchedRoot, resolved).split(path.sep).filter(Boolean);
  if (relativeParts.some((part) => part.startsWith("."))) throw new GatewayError(403, "hidden_path_rejected");
  if (inputInfo.size > maxFileBytes) throw new GatewayError(413, "attachment_too_large");
  const originalName = safeDisplayName(displayName ?? path.basename(resolved));
  if (isCredentialLikeName(path.basename(resolved))) throw new GatewayError(403, "credential_file_rejected");
  return { path: resolved, size: inputInfo.size, originalName };
}

async function hashFile(filePath) {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(filePath)) hash.update(chunk);
  return hash.digest("hex");
}

export function createIpv4DnsLookup(value) {
  if (value === undefined || value.trim() === "") return undefined;
  const servers = value
    .split(",")
    .map((server) => server.trim())
    .filter(Boolean);
  if (servers.length === 0 || servers.some((server) => isIP(server) !== 4)) {
    throw new Error("OBSIDIAN_GATEWAY_IPV4_DNS_SERVERS must be a comma-separated list of IPv4 DNS servers");
  }
  const resolver = new Resolver();
  resolver.setServers(servers);
  let cursor = 0;
  return (hostname, options, callback) => {
    resolver.resolve4(hostname).then(
      (addresses) => {
        if (addresses.length === 0) return callback(new Error(`No A record for ${hostname}`));
        if (typeof options === "object" && options?.all) {
          return callback(null, addresses.map((address) => ({ address, family: 4 })));
        }
        const address = addresses[cursor % addresses.length];
        cursor += 1;
        return callback(null, address, 4);
      },
      (error) => callback(error)
    );
  };
}

function responseHeader(response, name) {
  const value = response.headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] : value;
}

function asRequestError(error) {
  if (error instanceof GatewayError) return error;
  return new GatewayError(502, "gateway_unreachable", "Gateway connection failed", {
    cause: typeof error?.code === "string" ? error.code : "network_error"
  });
}

function requestBuffer(
  url,
  {
    method = "GET",
    headers = {},
    body,
    timeout = 60_000,
    maxResponseBytes = DEFAULT_MAX_JSON_RESPONSE_BYTES,
    oversizedCode = "gateway_response_too_large",
    lookup
  } = {}
) {
  return new Promise((resolve, reject) => {
    const requestFunction = url.protocol === "https:" ? httpsRequest : httpRequest;
    let settled = false;
    let timer;
    const finish = (callback, value) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      callback(value);
    };
    const request = requestFunction(url, { method, headers, ...(lookup ? { lookup } : {}) }, (response) => {
      const chunks = [];
      let size = 0;
      response.on("data", (chunk) => {
        size += chunk.length;
        if (size > maxResponseBytes) {
          request.destroy(new GatewayError(413, oversizedCode));
          return;
        }
        chunks.push(chunk);
      });
      response.on("end", () =>
        finish(resolve, {
          status: response.statusCode ?? 0,
          headers: response.headers,
          body: Buffer.concat(chunks)
        })
      );
      response.on("error", (error) => finish(reject, asRequestError(error)));
    });
    request.on("error", (error) => finish(reject, asRequestError(error)));
    timer = setTimeout(() => request.destroy(new GatewayError(504, "gateway_timeout")), timeout);
    if (body?.pipe) {
      body.on("error", (error) => request.destroy(new GatewayError(500, "source_read_failed", "Source file read failed", {
        cause: typeof error?.code === "string" ? error.code : "read_error"
      })));
      body.pipe(request);
    } else if (body !== undefined) {
      request.end(body);
    } else {
      request.end();
    }
  });
}

function parseJsonResponse(response) {
  try {
    return JSON.parse(response.body.toString("utf8"));
  } catch {
    throw new GatewayError(502, "invalid_gateway_json");
  }
}

function responseError(response) {
  let body;
  try {
    body = JSON.parse(response.body.toString("utf8"));
  } catch {
    body = null;
  }
  const code = body?.error?.code ?? `http_${response.status}`;
  const message = body?.error?.message ?? `Gateway returned HTTP ${response.status}`;
  throw new GatewayError(response.status, code, message, body?.error?.details);
}

export async function createBridgeMcpServer({
  gatewayUrl,
  token,
  uploadRoots,
  uploadDenyRoots = [],
  maxFileBytes = DEFAULT_MAX_FILE_BYTES,
  maxPreviewBytes = DEFAULT_MAX_PREVIEW_BYTES,
  ipv4DnsServers
}) {
  const baseUrl = validateGatewayUrl(gatewayUrl);
  if (typeof token !== "string" || token.length < 32) throw new Error("OBSIDIAN_GATEWAY_TOKEN is required and must contain at least 32 characters");
  const roots = Array.isArray(uploadRoots) ? uploadRoots : await resolveUploadRoots(uploadRoots);
  const denied = Array.isArray(uploadDenyRoots)
    ? uploadDenyRoots
    : uploadDenyRoots.trim()
      ? await resolveUploadRoots(uploadDenyRoots)
      : [];
  const endpoint = (route) => new URL(route.replace(/^\/+/, ""), baseUrl);
  const lookup = createIpv4DnsLookup(ipv4DnsServers);

  const gatewayJson = async (route, { method = "POST", body, timeout = 60_000 } = {}) => {
    const payload = body === undefined ? undefined : Buffer.from(JSON.stringify(body));
    const response = await requestBuffer(endpoint(route), {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        ...(payload === undefined
          ? {}
          : { "Content-Type": "application/json", "Content-Length": String(payload.length) })
      },
      body: payload,
      timeout,
      lookup
    });
    if (response.status < 200 || response.status >= 300) responseError(response);
    return parseJsonResponse(response);
  };

  const server = new McpServer(
    { name: "obsidian-mcp-host-bridge", version: "1.0.0" },
    {
      instructions:
        "The iCloud Obsidian vault is canonical. Attachment uploads stream raw bytes directly from an allow-listed local path to the Mac mini gateway; never encode original attachment bytes as JSON or base64. Notes/ is human-owned and read-only. Writes create or append only same-host gateway records under Inbox/Agents; remote-host creates require the canonical project. Every write requires a caller-supplied operation_id. Host identity is fixed by the injected bearer token."
    }
  );

  server.registerTool(
    "knowledge_list",
    {
      description: "List active Markdown under Notes and Inbox/Agents with namespace, path, SHA-256, size, and mtime.",
      inputSchema: knowledgeListSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-list", { body: input })))
  );

  server.registerTool(
    "knowledge_search",
    {
      description: "Search active main Notes and Inbox/Agents plus the read-only pilot namespace, returning current SHA-256.",
      inputSchema: knowledgeSearchSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-search", { body: input })))
  );

  server.registerTool(
    "knowledge_read",
    {
      description: "Read one main or pilot Markdown result, optionally by line range, with its current SHA-256.",
      inputSchema: knowledgeReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-read", { body: input })))
  );

  server.registerTool(
    "knowledge_batch_read",
    {
      description: "Read up to 20 Markdown notes with a bounded total character budget.",
      inputSchema: knowledgeBatchReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-batch-read", { body: input })))
  );

  server.registerTool(
    "knowledge_frontmatter",
    {
      description: "Read only a note's YAML frontmatter plus extracted Obsidian tags and current SHA-256.",
      inputSchema: knowledgeFrontmatterSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-frontmatter", { body: input })))
  );

  server.registerTool(
    "knowledge_outline",
    {
      description: "Return a note's Markdown heading tree with zero-based line numbers.",
      inputSchema: knowledgeOutlineSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-outline", { body: input })))
  );

  server.registerTool(
    "knowledge_section_read",
    {
      description: "Read one uniquely resolved Markdown heading section; partial heading paths are allowed when unambiguous.",
      inputSchema: knowledgeSectionReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-section-read", { body: input })))
  );

  server.registerTool(
    "knowledge_tag_search",
    {
      description: "Find active Notes or Inbox/Agents Markdown carrying an exact frontmatter or inline Obsidian tag.",
      inputSchema: knowledgeTagSearchSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/knowledge-tag-search", { body: input })))
  );

  server.registerTool(
    "attachment_upload",
    {
      description: "Stream a regular local file as a raw HTTPS request; file bytes never enter MCP JSON arguments.",
      inputSchema: attachmentUploadSchema,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false }
    },
    guarded(async ({ source_path, operation_id, display_name }) => {
      const source = await validateSourceFile(source_path, roots, maxFileBytes, display_name, denied);
      const digest = await hashFile(source.path);
      const response = await requestBuffer(endpoint(`v1/attachments/${encodeURIComponent(operation_id)}`), {
        method: "PUT",
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/octet-stream",
          "Content-Length": String(source.size),
          "X-Content-Size": String(source.size),
          "X-Content-SHA256": digest,
          "X-Original-Name": encodeURIComponent(source.originalName)
        },
        body: createReadStream(source.path),
        timeout: 15 * 60_000,
        lookup
      });
      if (response.status < 200 || response.status >= 300) responseError(response);
      return success(parseJsonResponse(response));
    })
  );

  server.registerTool(
    "attachment_preview",
    {
      description: "Return attachment metadata; images also return one bounded thumbnail as MCP ImageContent.",
      inputSchema: attachmentPreviewSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      const metadata = await gatewayJson("v1/tools/attachment-preview", { body: input });
      if (!metadata.mime.startsWith("image/")) return success({ ...metadata, has_image_preview: false });
      const response = await requestBuffer(endpoint(`v1/attachments/${metadata.attachment_id}/preview`), {
        method: "GET",
        headers: { Authorization: `Bearer ${token}` },
        timeout: 60_000,
        maxResponseBytes: maxPreviewBytes,
        oversizedCode: "preview_too_large",
        lookup
      });
      if (response.status < 200 || response.status >= 300) responseError(response);
      const declaredSize = Number(responseHeader(response, "content-length") ?? "0");
      if (declaredSize > maxPreviewBytes) throw new GatewayError(413, "preview_too_large");
      const image = response.body;
      if (image.length > maxPreviewBytes) throw new GatewayError(413, "preview_too_large");
      const mimeType = responseHeader(response, "content-type")?.split(";")[0] ?? "image/png";
      return success(
        { ...metadata, has_image_preview: true, preview_mime: mimeType, preview_byte_size: image.length },
        [{ type: "image", data: image.toString("base64"), mimeType }]
      );
    })
  );

  server.registerTool(
    "record_create",
    {
      description: "Create one Markdown record under Inbox/Agents/<authenticated-host>; remote hosts require project.",
      inputSchema: recordCreateSchema,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/record-create", { body: input })))
  );

  server.registerTool(
    "record_append",
    {
      description: "Append to a gateway-created record only if its current content SHA matches the journal.",
      inputSchema: recordAppendSchema,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false }
    },
    guarded(async (input) => success(await gatewayJson("v1/tools/record-append", { body: input })))
  );

  return server;
}

async function main() {
  let token = process.env.OBSIDIAN_GATEWAY_TOKEN;
  if (!token && process.env.OBSIDIAN_GATEWAY_TOKEN_FILE) {
    const tokenPath = path.resolve(process.env.OBSIDIAN_GATEWAY_TOKEN_FILE);
    const info = await lstat(tokenPath);
    if (!info.isFile() || info.isSymbolicLink() || (info.mode & 0o077) !== 0) {
      throw new Error("OBSIDIAN_GATEWAY_TOKEN_FILE must be a non-symlink regular file with mode 0600");
    }
    token = (await readFile(tokenPath, "utf8")).trim();
  }
  const server = await createBridgeMcpServer({
    gatewayUrl: process.env.OBSIDIAN_GATEWAY_URL,
    token,
    uploadRoots: process.env.OBSIDIAN_UPLOAD_ROOTS,
    uploadDenyRoots: process.env.OBSIDIAN_UPLOAD_DENY_ROOTS ?? [],
    ipv4DnsServers: process.env.OBSIDIAN_GATEWAY_IPV4_DNS_SERVERS
  });
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Obsidian raw-file MCP host bridge running on stdio");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
