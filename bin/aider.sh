#!/usr/bin/env bash

set -euo pipefail

# Path to the apps.json file (adjust if needed)
CONFIG_COPILOT_FILE="${HOME}/.config/github-copilot/apps.json"

if [[ ! -f "$CONFIG_COPILOT_FILE" ]]; then
	echo "Could not find $CONFIG_COPILOT_FILE. Please check the path and try again." >&2
	exit 1
fi

# Extract the first oauth_token using jaq
OAUTH_TOKEN=$(jaq -r 'to_entries[0].value.oauth_token' "$CONFIG_COPILOT_FILE")
if [[ -z "$OAUTH_TOKEN" || "$OAUTH_TOKEN" == "null" ]]; then
	echo "No oauth_token found in the first entry of $CONFIG_COPILOT_FILE." >&2
	exit 1
fi

# Fetch the Copilot token from GitHub API
COPILOT_TOKEN=$(curl -s -H "Authorization: Bearer $OAUTH_TOKEN" \
	"https://api.github.com/copilot_internal/v2/token" | jaq -r '.token')

if [[ -z "$COPILOT_TOKEN" || "$COPILOT_TOKEN" == "null" ]]; then
	echo "No 'token' field found in the API response." >&2
	exit 1
fi

# Export the token as OPENAI_API_KEY in the current process
export OPENAI_API_BASE="https://api.githubcopilot.com"
export OPENAI_API_KEY="$COPILOT_TOKEN"

# Inform the user
echo "OPENAI_API_KEY is set for this session."
echo "AVAILABLE MODELs:"
curl -s https://api.githubcopilot.com/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Copilot-Integration-Id: vscode-chat" | jaq -r '.data[].id'

# Launch aider with the environment variable set
echo "Starting aider..."

exec aider "$@"
