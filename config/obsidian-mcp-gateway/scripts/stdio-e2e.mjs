#!/usr/bin/env node
import path from "node:path";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

function argumentsFrom(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 2) {
    const key = argv[index];
    const value = argv[index + 1];
    if (!key?.startsWith("--") || value === undefined) throw new Error("Arguments must be --key value pairs");
    result[key.slice(2)] = value;
  }
  return result;
}

function toolValue(result, name) {
  if (result.isError) throw new Error(`${name} failed: ${result.content?.[0]?.text ?? "unknown error"}`);
  return result.structuredContent;
}

const args = argumentsFrom(process.argv.slice(2));
for (const key of ["file", "title", "operation-prefix", "body"]) {
  if (!args[key]) throw new Error(`--${key} is required`);
}
if (!args.bridge && !args.wrapper) throw new Error("--bridge or --wrapper is required");
if (args.bridge && args.wrapper) throw new Error("--bridge and --wrapper are mutually exclusive");
for (const key of ["OBSIDIAN_GATEWAY_URL", "OBSIDIAN_UPLOAD_ROOTS"]) {
  if (!process.env[key]) throw new Error(`${key} is required`);
}
if (args.bridge && !process.env.OBSIDIAN_GATEWAY_TOKEN) {
  throw new Error("OBSIDIAN_GATEWAY_TOKEN is required with --bridge");
}

const forwardedNames = [
  "PATH",
  "HOME",
  "XDG_CONFIG_HOME",
  "OBSIDIAN_GATEWAY_URL",
  "OBSIDIAN_GATEWAY_TOKEN",
  "OBSIDIAN_GATEWAY_TOKEN_FILE",
  "OBSIDIAN_GATEWAY_SECRET_DIR",
  "OBSIDIAN_GATEWAY_KEYCHAIN_SERVICE",
  "OBSIDIAN_GATEWAY_HOST",
  "OBSIDIAN_UPLOAD_ROOTS",
  "OBSIDIAN_UPLOAD_DENY_ROOTS",
  "OBSIDIAN_BRIDGE_NODE",
  "OBSIDIAN_BRIDGE_PATH",
  "RES_OPTIONS"
];
const transportEnv = Object.fromEntries(
  forwardedNames
    .filter((name) => process.env[name] !== undefined)
    .map((name) => [name, process.env[name]])
);

const client = new Client({ name: "obsidian-mcp-stdio-e2e", version: "0.1.0" });
const transport = new StdioClientTransport({
  command: args.wrapper ? path.resolve(args.wrapper) : process.execPath,
  args: args.bridge ? [path.resolve(args.bridge)] : [],
  env: transportEnv,
  stderr: "pipe"
});

try {
  await client.connect(transport);
  const tools = (await client.listTools()).tools.map((tool) => tool.name).sort();
  const uploadSpecs = [
    {
      source_path: path.resolve(args.file),
      operation_id: `${args["operation-prefix"]}-upload`,
      ...(args["display-name"] ? { display_name: args["display-name"] } : {})
    },
    ...(args["extra-file"]
      ? [{
          source_path: path.resolve(args["extra-file"]),
          operation_id: `${args["operation-prefix"]}-extra-upload`,
          ...(args["extra-display-name"] ? { display_name: args["extra-display-name"] } : {})
        }]
      : [])
  ];
  const attachments = [];
  for (const uploadArguments of uploadSpecs) {
    const attachment = toolValue(
      await client.callTool({ name: "attachment_upload", arguments: uploadArguments }),
      "attachment_upload"
    );
    const attachmentRetry = toolValue(
      await client.callTool({ name: "attachment_upload", arguments: uploadArguments }),
      "attachment_upload retry"
    );
    if (attachmentRetry.attachment_id !== attachment.attachment_id) {
      throw new Error("attachment retry was not idempotent");
    }
    attachments.push(attachment);
  }
  const attachment = attachments[0];
  const previewResult = await client.callTool({
    name: "attachment_preview",
    arguments: { attachment_id: attachment.attachment_id }
  });
  const preview = toolValue(previewResult, "attachment_preview");
  let record = null;
  if (args["skip-record"] !== "true") {
    const createArguments = {
      title: args.title,
      body: args.body,
      tags: (args.tags ?? "kind/log,topic/obsidian-mcp").split(",").filter(Boolean),
      ...(args.project ? { project: args.project } : {}),
      attachment_ids: attachments.map((item) => item.attachment_id),
      operation_id: `${args["operation-prefix"]}-record`
    };
    record = toolValue(await client.callTool({ name: "record_create", arguments: createArguments }), "record_create");
    const recordRetry = toolValue(
      await client.callTool({ name: "record_create", arguments: createArguments }),
      "record_create retry"
    );
    if (recordRetry.record_id !== record.record_id) throw new Error("record retry was not idempotent");
  }
  process.stdout.write(
    `${JSON.stringify({
      tools,
      attachments,
      record,
      preview: {
        has_image_preview: preview.has_image_preview,
        content_types: previewResult.content.map((item) => item.type)
      },
      retries_idempotent: true
    })}\n`
  );
} finally {
  await client.close();
}
