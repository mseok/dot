#!/usr/bin/env bash
# Align the repository-managed Claude Code surface with the Codex one.
#
# Managed by this script:
#   $CLAUDE_HOME/CLAUDE.md (link to the common ai/codex/AGENTS.md)
#   individual user skill links below $CLAUDE_HOME/skills/ that mirror the
#   user skills installed below $CODEX_HOME/skills/
#
# Deliberately not managed here:
#   settings.json, authentication, MCP registrations, hooks, plugins, and
#   host-local skill directories such as the deployed research skills.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
GUIDANCE_SOURCE="$DOT_HOME/ai/codex/AGENTS.md"
CLAUDE_TARGET_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CODEX_TARGET_HOME="${CODEX_HOME:-$HOME/.codex}"
AGENT_SKILLS_ROOT="${AGENT_SKILLS_HOME:-$HOME/agent-skills}"
GUIDANCE_ONLY=0

log()   { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: bin/install_claude.sh [options]

Options:
  --guidance-only      Link guidance without changing skills.
  --claude-home PATH   Use PATH instead of $HOME/.claude.
  --codex-home PATH    Use PATH instead of $HOME/.codex.
  -h, --help           Show this help.

The installer links the global CLAUDE.md to the common AGENTS.md and mirrors
the Codex user skills as individual links. It removes only skill links that
point into the retired agent-skills Claude scope or that are broken. It never
copies settings.json, credentials, MCP state, or hooks, and it preserves
host-local skill directories.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --guidance-only)
      GUIDANCE_ONLY=1
      ;;
    --claude-home)
      shift
      if (( $# == 0 )); then
        error "--claude-home requires a path."
        exit 2
      fi
      CLAUDE_TARGET_HOME="$1"
      ;;
    --codex-home)
      shift
      if (( $# == 0 )); then
        error "--codex-home requires a path."
        exit 2
      fi
      CODEX_TARGET_HOME="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac
  shift
done

backup_path() {
  local path="$1" ts backup suffix
  ts="$(date +%Y%m%d_%H%M%S)"
  backup="${path}.bak_${ts}"
  suffix=0
  while [[ -e "$backup" || -L "$backup" ]]; do
    suffix=$((suffix + 1))
    backup="${path}.bak_${ts}_${suffix}"
  done
  mv "$path" "$backup"
  log "Backed up: $path -> $backup"
}

link_guidance() {
  local dst="$CLAUDE_TARGET_HOME/CLAUDE.md"

  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" == "$GUIDANCE_SOURCE" ]]; then
      log "Claude guidance link already up to date: $dst"
      return 0
    fi
    warn "Leaving unrelated Claude guidance symlink untouched: $dst -> $(readlink "$dst")"
    return 0
  elif [[ -e "$dst" ]]; then
    backup_path "$dst"
  fi

  ln -s "$GUIDANCE_SOURCE" "$dst"
  log "Linked: $dst -> $GUIDANCE_SOURCE"
}

# Drop links that no longer belong to the shared skill set. Directories and
# links owned by the host, a plugin or the research deployer are preserved.
prune_skill_links() {
  local skills_root="$1" retired="$AGENT_SKILLS_ROOT/skills/claude" entry target

  for entry in "$skills_root"/*; do
    [[ -L "$entry" ]] || continue
    target="$(readlink "$entry")"
    if [[ "$target" == "$retired"/* ]]; then
      rm "$entry"
      log "Removed retired Claude-scope skill link: $entry"
    elif [[ ! -e "$entry" ]]; then
      rm "$entry"
      log "Removed broken skill link: $entry -> $target"
    fi
  done
}

mirror_codex_skills() {
  local skills_root="$CLAUDE_TARGET_HOME/skills" codex_skills="$CODEX_TARGET_HOME/skills"
  local entry name source installed

  mkdir -p "$skills_root"
  prune_skill_links "$skills_root"

  if [[ ! -d "$codex_skills" ]]; then
    warn "No Codex skills at $codex_skills; nothing to mirror."
    return 0
  fi

  for entry in "$codex_skills"/*; do
    [[ -d "$entry" ]] || continue
    name="$(basename "$entry")"
    installed="$skills_root/$name"
    if [[ -L "$entry" ]]; then
      source="$(readlink "$entry")"
    else
      source="$entry"
    fi

    if [[ -L "$installed" ]]; then
      if [[ "$(readlink "$installed")" == "$source" ]]; then
        continue
      fi
      warn "Leaving unrelated skill link untouched: $installed -> $(readlink "$installed")"
    elif [[ -e "$installed" ]]; then
      log "Preserving host-local skill directory: $installed"
    else
      ln -s "$source" "$installed"
      log "Linked: $installed -> $source"
    fi
  done
}

main() {
  if [[ ! -f "$GUIDANCE_SOURCE" ]]; then
    error "Common guidance is missing from this checkout: $GUIDANCE_SOURCE"
    exit 1
  fi

  mkdir -p "$CLAUDE_TARGET_HOME"
  log "Installing repository-managed Claude files into $CLAUDE_TARGET_HOME"
  link_guidance

  if [[ "$GUIDANCE_ONLY" == "1" ]]; then
    log "Guidance-only update: skills unchanged."
  else
    mirror_codex_skills
  fi

  cat <<EOF

Claude installation summary
  common guidance: $CLAUDE_TARGET_HOME/CLAUDE.md -> $GUIDANCE_SOURCE
  skills: mirrored from $CODEX_TARGET_HOME/skills (host-local directories kept)
  host-local state: settings.json, auth, MCP, hooks, plugins (unchanged)
EOF
}

main "$@"
