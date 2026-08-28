import { readFile } from "node:fs/promises";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import {
  attachmentPreviewSchema,
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
import { asGatewayError } from "./common.mjs";
import { requireScope } from "./auth.mjs";

function success(value, content = []) {
  return {
    content: [{ type: "text", text: JSON.stringify(value, null, 2) }, ...content],
    structuredContent: value
  };
}

function failure(error) {
  const safe = asGatewayError(error);
  const value = {
    error: {
      code: safe.code,
      message: safe.message,
      ...(safe.details === undefined ? {} : { details: safe.details })
    }
  };
  return { isError: true, content: [{ type: "text", text: JSON.stringify(value, null, 2) }] };
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

export function createGatewayMcpServer(service, identity) {
  const server = new McpServer(
    { name: "obsidian-mcp-gateway", version: "1.0.0" },
    {
      instructions:
        "The iCloud Obsidian vault is canonical. Notes/ is human-owned and read-only to agents. Agent writes create or append only gateway-owned Inbox/Agents/<authenticated-host>/ records, and attachments go to Attachments/. Remote-host records require the canonical project name. Attachment bytes must use the raw upload route through a host-local bridge; never place original file bytes or base64 in tool arguments. Host identity comes only from bearer authentication. Delete, rename, move, promotion, arbitrary overwrite, and automatic merge are unavailable."
    }
  );

  server.registerTool(
    "knowledge_list",
    {
      description: "List active Markdown under Notes and Inbox/Agents, with namespace, path, SHA-256, size, and mtime.",
      inputSchema: knowledgeListSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeList(input));
    })
  );

  server.registerTool(
    "knowledge_search",
    {
      description: "Search active main Notes and Inbox/Agents, plus the optional read-only legacy pilot namespace.",
      inputSchema: knowledgeSearchSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeSearch(input));
    })
  );

  server.registerTool(
    "knowledge_read",
    {
      description: "Read one Markdown search result, optionally by line range, and return its current SHA-256.",
      inputSchema: knowledgeReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeRead(input));
    })
  );

  server.registerTool(
    "knowledge_batch_read",
    {
      description: "Read up to 20 Markdown notes with a bounded total character budget.",
      inputSchema: knowledgeBatchReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeBatchRead(input));
    })
  );

  server.registerTool(
    "knowledge_frontmatter",
    {
      description: "Read only a note's YAML frontmatter plus its exact parsed Obsidian tags and current SHA-256.",
      inputSchema: knowledgeFrontmatterSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeFrontmatter(input));
    })
  );

  server.registerTool(
    "knowledge_outline",
    {
      description: "Return a note's Markdown heading tree with zero-based line numbers.",
      inputSchema: knowledgeOutlineSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeOutline(input));
    })
  );

  server.registerTool(
    "knowledge_section_read",
    {
      description: "Read one uniquely resolved Markdown heading section; partial heading paths are allowed when unambiguous.",
      inputSchema: knowledgeSectionReadSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeSectionRead(input));
    })
  );

  server.registerTool(
    "knowledge_tag_search",
    {
      description: "Find active Notes or Inbox/Agents Markdown carrying an exact frontmatter or inline Obsidian tag.",
      inputSchema: knowledgeTagSearchSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "knowledge:read");
      return success(await service.knowledgeTagSearch(input));
    })
  );

  server.registerTool(
    "attachment_preview",
    {
      description: "Return attachment metadata and, for images, a bounded thumbnail as MCP ImageContent.",
      inputSchema: attachmentPreviewSchema,
      annotations: { readOnlyHint: true, destructiveHint: false, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "attachment:read");
      const preview = await service.attachmentPreview(input);
      const structured = { ...preview.metadata, has_image_preview: Boolean(preview.image) };
      if (!preview.image) return success(structured);
      const data = await readFile(preview.image.path);
      return success(structured, [{ type: "image", data: data.toString("base64"), mimeType: preview.image.mime }]);
    })
  );

  server.registerTool(
    "record_create",
    {
      description: "Create one append-only Markdown record under Inbox/Agents/<authenticated-host>; remote hosts require project.",
      inputSchema: recordCreateSchema,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "record:write");
      return success(await service.recordCreate(identity.host, input));
    })
  );

  server.registerTool(
    "record_append",
    {
      description: "Append to a same-host gateway record if its stored and current content SHA still match.",
      inputSchema: recordAppendSchema,
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false }
    },
    guarded(async (input) => {
      requireScope(identity, "record:write");
      return success(await service.recordAppend(identity.host, input));
    })
  );

  return server;
}
