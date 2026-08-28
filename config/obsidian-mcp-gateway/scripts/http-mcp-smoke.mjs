#!/usr/bin/env node
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const url = process.env.OBSIDIAN_GATEWAY_MCP_URL;
const token = process.env.OBSIDIAN_GATEWAY_TOKEN;
if (!url || !token) throw new Error("OBSIDIAN_GATEWAY_MCP_URL and OBSIDIAN_GATEWAY_TOKEN are required");

const client = new Client({ name: "obsidian-mcp-http-smoke", version: "0.1.0" });
const transport = new StreamableHTTPClientTransport(new URL(url), {
  requestInit: { headers: { Authorization: `Bearer ${token}` } }
});
try {
  await client.connect(transport);
  const result = await client.listTools();
  process.stdout.write(`${JSON.stringify({ initialized: true, tools: result.tools.map((tool) => tool.name).sort() })}\n`);
} finally {
  await client.close();
}
