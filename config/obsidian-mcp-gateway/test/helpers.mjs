import { createHash } from "node:crypto";
import { mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { tmpdir } from "node:os";
import { createGateway } from "../src/gateway.mjs";
import { KnowledgeService } from "../src/service.mjs";

export const TOKENS = {
  local: "local-test-token-0123456789-abcdefghijklmnopqrstuvwxyz",
  messi: "messi-test-token-0123456789-abcdefghijklmnopqrstuvwxyz",
  gpu22: "gpu22-test-token-0123456789-abcdefghijklmnopqrstuvwxyz"
};

export const PNG_BYTES = Buffer.from(
  "89504e470d0a1a0a0000000d4948445200000001000000010804000000b51c0c020000000b4944415478da63fcff1f0003030200efbf6b2b0000000049454e44ae426082",
  "hex"
);

export function digest(data) {
  return createHash("sha256").update(data).digest("hex");
}

export async function createFixture(options = {}) {
  const root = await mkdtemp(path.join(tmpdir(), "obsidian-mcp-pilot-test-"));
  const mainRoot = path.join(root, "main");
  const pilotRoot = path.join(root, "legacy-pilot");
  const stateRoot = path.join(root, "state");
  const uploadRoot = path.join(root, "uploads");
  await Promise.all([
    mkdir(path.join(mainRoot, "Notes"), { recursive: true }),
    mkdir(path.join(mainRoot, "Inbox", "Agents"), { recursive: true }),
    mkdir(path.join(mainRoot, "Attachments"), { recursive: true }),
    mkdir(path.join(pilotRoot, "Notes"), { recursive: true }),
    mkdir(path.join(pilotRoot, "Attachments"), { recursive: true }),
    mkdir(uploadRoot, { recursive: true })
  ]);
  await writeFile(
    path.join(mainRoot, "Notes", "main evidence.md"),
    "---\ntitle: Main evidence\ncreated: 2026-08-27\ntags:\n  - kind/reference\n  - topic/mcp\n---\n\nImmutable main evidence.\n\n# Architecture\n\nArchitecture intro with #inline-tag.\n\n## 결과\n\nNested result.\n\n```text\n#not-a-tag\n## Not a heading\n```\n\n# Decision\n\nKeep the single writer.\n"
  );
  const service = await new KnowledgeService({
    mainRoot,
    legacyRoot: pilotRoot,
    stateRoot,
    maxFileBytes: options.maxFileBytes ?? 1024,
    maxVaultBytes: options.maxVaultBytes ?? 16 * 1024,
    maxPreviewBytes: options.maxPreviewBytes ?? 1024 * 1024,
    now: options.now ?? (() => new Date("2026-08-27T10:00:00.000Z"))
  }).initialize();
  const gateway = await createGateway({ service, tokenEntries: TOKENS, port: 0 });
  const baseUrl = `http://127.0.0.1:${gateway.address.port}`;
  return {
    root,
    mainRoot,
    pilotRoot,
    stateRoot,
    uploadRoot,
    service,
    gateway,
    baseUrl,
    async close() {
      await gateway.close();
      await rm(root, { recursive: true, force: true });
    }
  };
}

export async function upload(baseUrl, token, operationId, name, bytes, overrides = {}) {
  const sha = overrides.sha256 ?? digest(bytes);
  const size = overrides.size ?? bytes.length;
  return fetch(`${baseUrl}/v1/attachments/${encodeURIComponent(operationId)}`, {
    method: "PUT",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/octet-stream",
      "Content-Length": String(bytes.length),
      "X-Content-Size": String(size),
      "X-Content-SHA256": sha,
      "X-Original-Name": encodeURIComponent(name)
    },
    body: bytes
  });
}

export async function api(baseUrl, token, route, body, method = "POST") {
  return fetch(`${baseUrl}${route}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      ...(body === undefined ? {} : { "Content-Type": "application/json" })
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) })
  });
}
