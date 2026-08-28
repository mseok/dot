import { createHash, timingSafeEqual } from "node:crypto";
import { execFileSync } from "node:child_process";
import { GatewayError } from "./common.mjs";

export const DEFAULT_SCOPES = ["knowledge:read", "attachment:read", "attachment:write", "record:write"];

function tokenDigest(token) {
  return createHash("sha256").update(token).digest();
}

export function buildTokenRegistry(entries) {
  const registry = [];
  const seen = new Set();
  for (const [host, configuration] of Object.entries(entries)) {
    const token = typeof configuration === "string" ? configuration : configuration.token;
    const scopes = typeof configuration === "string" ? DEFAULT_SCOPES : configuration.scopes ?? DEFAULT_SCOPES;
    if (!/^[a-z0-9][a-z0-9_-]{0,31}$/.test(host)) throw new Error(`Invalid token host: ${host}`);
    if (typeof token !== "string" || token.length < 32) throw new Error(`Token for ${host} must contain at least 32 characters`);
    const digest = tokenDigest(token);
    const key = digest.toString("hex");
    if (seen.has(key)) throw new Error("Bearer tokens must be unique per host");
    seen.add(key);
    registry.push({ host, digest, scopes: new Set(scopes) });
  }
  if (registry.length === 0) throw new Error("At least one gateway token is required");
  return registry;
}

export function loadKeychainTokenEntries({ service, hosts = ["local", "messi", "gpu22"] }) {
  const entries = {};
  for (const host of hosts) {
    const token = execFileSync("/usr/bin/security", ["find-generic-password", "-w", "-s", service, "-a", host], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"]
    }).trim();
    entries[host] = { token, scopes: DEFAULT_SCOPES };
  }
  return entries;
}

export function authenticateBearer(authorization, registry) {
  const match = typeof authorization === "string" ? authorization.match(/^Bearer ([^\s]+)$/) : null;
  if (!match) throw new GatewayError(401, "unauthorized", "A bearer token is required");
  const supplied = tokenDigest(match[1]);
  for (const entry of registry) {
    if (timingSafeEqual(supplied, entry.digest)) return { host: entry.host, scopes: entry.scopes };
  }
  throw new GatewayError(401, "unauthorized", "The bearer token is invalid");
}

export function requireScope(identity, scope) {
  if (!identity.scopes.has(scope)) throw new GatewayError(403, "insufficient_scope", `Missing scope: ${scope}`);
}
