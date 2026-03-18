#!/bin/zsh

set -u
set -o pipefail

BASE="$HOME/Library/Application Support/chatgpt-obsidian-mcp"
SETTINGS_FILE="$BASE/settings.env"
LOCAL_REST_ENV_FILE="$BASE/local-rest.env"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  print "Missing settings file: $SETTINGS_FILE" >&2
  exit 1
fi

source "$SETTINGS_FILE"

PLUGIN_SETTINGS="$VAULT_PATH/.obsidian/plugins/obsidian-local-rest-api/data.json"
COMMUNITY_PLUGINS="$VAULT_PATH/.obsidian/community-plugins.json"

if [[ ! -f "$PLUGIN_SETTINGS" || ! -f "$COMMUNITY_PLUGINS" ]]; then
  print "Missing Obsidian Local REST API plugin files in vault." >&2
  exit 1
fi

/usr/bin/python3 - "$PLUGIN_SETTINGS" "$COMMUNITY_PLUGINS" "$LOCAL_REST_ENV_FILE" <<'PY'
import json, pathlib, sys

settings_path, plugins_path, output_path = sys.argv[1:4]
settings = json.load(open(settings_path))
plugins = json.load(open(plugins_path))

if "obsidian-local-rest-api" not in plugins:
    raise SystemExit("obsidian-local-rest-api is not enabled in community-plugins.json")

enable_insecure = bool(settings.get("enableInsecureServer", False))
host = "127.0.0.1"
if enable_insecure:
    scheme = "http"
    port = int(settings["insecurePort"])
    verify_ssl = "false"
else:
    scheme = "https"
    port = int(settings["port"])
    verify_ssl = "false"

api_key = settings["apiKey"]
base_url = f"{scheme}://{host}:{port}"

out = pathlib.Path(output_path)
out.write_text(
    "\n".join(
        [
            f'REST_PORT="{port}"',
            f'OBSIDIAN_BASE_URL_DYNAMIC="{base_url}"',
            f'OBSIDIAN_VERIFY_SSL_DYNAMIC="{verify_ssl}"',
            f'OBSIDIAN_API_KEY_DYNAMIC="{api_key}"',
            "",
        ]
    )
)
PY

/bin/chmod 600 "$LOCAL_REST_ENV_FILE"
print "Updated $LOCAL_REST_ENV_FILE"
