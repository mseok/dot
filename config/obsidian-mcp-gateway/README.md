# Obsidian multi-host MCP gateway

The iCloud Obsidian vault is canonical. Only this Mac mini gateway may create agent records or attachments in it. Original attachment bytes travel as a raw HTTPS request body and never as MCP JSON, base64, or LLM context.

## Storage contract

- Human-owned, agent read-only: `Notes/**/*.md`
- Permanent agent records: `Inbox/Agents/<authenticated-host>/**/*.md`
- Shared opaque attachments: `Attachments/`
- Operational journal and previews: `/Volumes/ExternalSSD/Services/obsidian-mcp/state/`
- Read-only rollback namespace: `/Volumes/ExternalSSD/Services/obsidian-mcp-pilot/vault/`
- Listener: `127.0.0.1:39123`, published through the existing Funnel HTTPS 443 ingress
- LaunchAgent: `local.obsidian-mcp-gateway`

The gateway exposes Streamable HTTP MCP at `/mcp`, raw upload at `PUT /v1/attachments/{operation_id}`, and narrow JSON routes used by host-local STDIO bridges. A direct HTTP MCP client cannot upload a client-local path; `attachment_upload` exists only on the local STDIO bridge that can open and stream that file.

Read tools cover `Notes/` and `Inbox/Agents/` in the `main` namespace. The `pilot` namespace remains read-only during the 30-day rollback window. Write tools are limited to raw attachment upload, new record creation, and same-host conditional append. There are no arbitrary overwrite, promotion, delete, rename, move, or merge tools.

## Identity and secrets

Tokens are unique for `local`, `messi`, and `gpu22`; the token fixes host identity and scope. The Mac mini stores token verification material in Keychain service `local.obsidian-mcp-gateway.tokens`. Local MCP configuration contains no token.

Linux stores its token at `${XDG_CONFIG_HOME:-$HOME/.config}/obsidian-mcp/token`, inside a non-symlink `0700` directory as a non-symlink `0600` file. `run-linux-bridge.sh` validates both modes and exports only the file path; `bridge.mjs` reads the value at startup. Reboot requires no kernel-keyring reinjection. Never put token values in TOML, JSON, shell profiles, repositories, logs, or command arguments.

## Install and cutover

Stage code without starting a writer:

```zsh
npm ci --ignore-scripts
./scripts/provision-keychain-tokens.zsh
./scripts/install-mac-mini.zsh stage
```

Generate a count-guarded freeze manifest while the live vault is still untouched:

```zsh
node src/migrate-main.mjs plan \
  --main-root "/Users/mseok/Library/Mobile Documents/iCloud~md~obsidian/Documents/kepano-obsidian-main" \
  --legacy-root /Volumes/ExternalSSD/Services/obsidian-mcp-pilot/vault \
  --legacy-state /Volumes/ExternalSSD/Services/obsidian-mcp-pilot/state \
  --manifest /Volumes/ExternalSSD/Services/obsidian-mcp/rollback/migration-manifest.json \
  --expect-moves 190 --expect-legacy-records 4 --expect-legacy-attachments 4
```

After snapshots are complete and legacy writers are stopped, apply and verify:

```zsh
node src/migrate-main.mjs apply \
  --manifest /Volumes/ExternalSSD/Services/obsidian-mcp/rollback/migration-manifest.json \
  --target-state /Volumes/ExternalSSD/Services/obsidian-mcp/state
./scripts/install-mac-mini.zsh activate
./scripts/status.zsh
```

The installer refuses activation until the migrated journal exists. The legacy pilot runtime and service definition are retained, not deleted.

## File safety

- Uploads must resolve beneath `OBSIDIAN_UPLOAD_ROOTS`; hidden path components, symlinks, devices, credential-like names, and `OBSIDIAN_UPLOAD_DENY_ROOTS` are rejected.
- Client and gateway SHA-256 values and byte sizes must agree.
- The gateway streams to a same-filesystem temporary file, fsyncs, then atomically renames.
- New filenames retain a sanitized original stem and add `--<sha12>`; identical bytes reuse the first indexed path.
- New uploads are limited to 256 MiB per file and 5 GiB total managed bytes. Pre-existing vault attachments do not consume this quota.
- `operation_id` is idempotent. Reuse with a different request returns `409 operation_conflict`.
- Append checks the journaled content SHA against the actual file while serialized. Human drift returns `409 human_edit_detected` and is never merged automatically.

`attachment_preview` is the only tool that can return MCP `ImageContent`, and only for a bounded thumbnail. It accepts an indexed attachment ID or a validated `Attachments/...` path.

## Client configuration

Use `obsidian_main` from `examples/codex-mcp.toml` locally. On Linux, install the app under `~/.local/share/obsidian-mcp-gateway`, provision the secret file, and adapt `examples/codex-mcp-linux.toml` to the exact user and upload roots. The public gateway URL and allow-listed roots are not secrets.

The read-side tools were retained after comparing [MarkusPfundstein/mcp-obsidian](https://github.com/MarkusPfundstein/mcp-obsidian) and the safety-focused [voiderd-sub fork](https://github.com/voiderd-sub/mcp-obsidian). Their arbitrary append, overwrite, patch, rename, and delete tools remain intentionally excluded.

## Checks

`npm test` covers traversal and hidden paths, raw upload integrity and deduplication, quota enforcement, preview by ID/path, record concurrency and human-edit conflicts, and the main migration with pilot journal preservation. Protocol runners in `scripts/` exercise actual MCP initialize, tools/list, raw upload, preview, record creation, and idempotent retry.
