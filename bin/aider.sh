#!/usr/bin/env bash

set -euo pipefail

# Function to determine which JSON processor to use
get_json_processor() {
    if command -v jq >/dev/null 2>&1; then
        echo "jq"
    elif command -v jaq >/dev/null 2>&1; then
        echo "jaq"
    else
        echo "Error: Neither jq nor jaq is available. Please install one of them." >&2
        exit 1
    fi
}

# Set the JSON processor
JSON_PROCESSOR=$(get_json_processor)

# Path to the config file (check apps.json first, then hosts.json)
CONFIG_COPILOT_FILE="${HOME}/.config/github-copilot/apps.json"
if [[ ! -f "$CONFIG_COPILOT_FILE" ]]; then
    CONFIG_COPILOT_FILE="${HOME}/.config/github-copilot/hosts.json"
fi

if [[ ! -f "$CONFIG_COPILOT_FILE" ]]; then
    echo "Could not find GitHub Copilot config file. Checked:" >&2
    echo "  ${HOME}/.config/github-copilot/apps.json" >&2
    echo "  ${HOME}/.config/github-copilot/hosts.json" >&2
    echo "Please check the paths and try again." >&2
    exit 1
fi

# Extract the first oauth_token using the detected JSON processor
OAUTH_TOKEN=$($JSON_PROCESSOR -r 'to_entries[0].value.oauth_token' "$CONFIG_COPILOT_FILE")
if [[ -z "$OAUTH_TOKEN" || "$OAUTH_TOKEN" == "null" ]]; then
    echo "No oauth_token found in the first entry of $CONFIG_COPILOT_FILE." >&2
    exit 1
fi

# Fetch the Copilot token from GitHub API
COPILOT_TOKEN=$(curl -s -H "Authorization: Bearer $OAUTH_TOKEN" \
    "https://api.github.com/copilot_internal/v2/token" | $JSON_PROCESSOR -r '.token')

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
  -H "Copilot-Integration-Id: vscode-chat" | $JSON_PROCESSOR -r '.data[].id'

# Launch aider with the environment variable set
echo "Starting aider..."

exec aider "$@"
