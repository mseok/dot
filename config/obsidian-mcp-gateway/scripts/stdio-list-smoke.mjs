#!/usr/bin/env node
import path from "node:path";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

const command = process.argv[2];
if (!command) throw new Error("Usage: stdio-list-smoke.mjs <bridge-wrapper>");
const verifyRead = process.argv.includes("--read");

const allowed = [
  "PATH",
  "OBSIDIAN_GATEWAY_URL",
  "OBSIDIAN_UPLOAD_ROOTS",
  "OBSIDIAN_BRIDGE_NODE",
  "OBSIDIAN_BRIDGE_PATH",
  "OBSIDIAN_GATEWAY_KEY_NAME",
  "OBSIDIAN_GATEWAY_IPV4_DNS_SERVERS",
  "RES_OPTIONS"
];
const env = Object.fromEntries(allowed.filter((name) => process.env[name] !== undefined).map((name) => [name, process.env[name]]));
const client = new Client({ name: "obsidian-mcp-stdio-list-smoke", version: "0.1.0" });
const transport = new StdioClientTransport({ command: path.resolve(command), env, stderr: "pipe" });
try {
  await client.connect(transport);
  const result = await client.listTools();
  const output = { initialized: true, tools: result.tools.map((tool) => tool.name).sort() };
  if (verifyRead) {
    const read = await client.callTool({
      name: "knowledge_list",
      arguments: { namespace: "main", path_prefix: "Notes/", limit: 1 }
    });
    if (read.isError) throw new Error(`knowledge_list failed: ${JSON.stringify(read.content)}`);
    const first = read.structuredContent?.results?.[0];
    output.read = {
      count: read.structuredContent?.count,
      path: first?.path,
      sha256: first?.sha256
    };
  }
  process.stdout.write(`${JSON.stringify(output)}\n`);
} finally {
  await client.close();
}
