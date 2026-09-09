#!/usr/bin/env bash
# Install the repository-managed Codex surface without copying host-local state.
#
# Managed by this script:
#   $CODEX_HOME/AGENTS.md
#   $CODEX_HOME/rules/hpc.rules (Linux/HPC only)
#   individual user skills below $CODEX_HOME/skills/
#
# Deliberately not managed here:
#   config.toml, authentication, MCP registrations, project trust, databases,
#   and AGENTS.override.md unless the caller supplies an explicit source file.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"
CODEX_SOURCE="$DOT_HOME/ai/codex"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
OVERRIDE_SOURCE="${DOT_CODEX_OVERRIDE_SOURCE:-}"

if [[ "$(uname -s)" == "Linux" ]]; then
  INSTALL_HPC_RULES=1
else
  INSTALL_HPC_RULES=0
fi

log()   { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: bin/install_codex.sh [options]

Options:
  --hpc                    Install the Linux/HPC hpc.rules policy as well.
  --override-from PATH     Copy PATH to $CODEX_HOME/AGENTS.override.md.
  --codex-home PATH        Use PATH instead of $HOME/.codex.
  -h, --help               Show this help.

The installer links portable AGENTS.md, rules, and individual user skills.
It never copies config.toml, credentials, MCP state, or project trust files.
An existing AGENTS.override.md is preserved unless --override-from is given.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --hpc)
      INSTALL_HPC_RULES=1
      ;;
    --override-from)
      shift
      if (( $# == 0 )); then
        error "--override-from requires a path."
        exit 2
      fi
      OVERRIDE_SOURCE="$1"
      ;;
    --codex-home)
      shift
      if (( $# == 0 )); then
        error "--codex-home requires a path."
        exit 2
      fi
      CODEX_HOME="$1"
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

same_path() {
  local left="$1" right="$2"
  [[ "$left" -ef "$right" ]] || [[ "$(readlink "$left" 2>/dev/null || true)" == "$right" ]]
}

ensure_file_link() {
  local src="$1" dst="$2"

  if [[ ! -f "$src" ]]; then
    error "Codex source file is missing: $src"
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    if same_path "$dst" "$src"; then
      log "Codex link already up to date: $dst"
      return 0
    fi

    # A broken link to the old managed source is recoverable and can be
    # replaced. An unrelated link belongs to the host and is left untouched.
    if [[ "$(readlink "$dst" 2>/dev/null || true)" != "$src" ]]; then
      warn "Leaving unrelated Codex symlink untouched: $dst -> $(readlink "$dst")"
      return 0
    fi
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    backup_path "$dst"
  fi

  ln -s "$src" "$dst"
  log "Linked: $dst -> $src"
}

migrate_legacy_skill_root() {
  local skills_dst="$1" skills_src="$2" system_src staging

  # Older versions linked the complete ~/.codex/skills directory into the
  # checkout. Preserve any app-managed .system skills in CODEX_HOME before
  # replacing that root link. The source is intentionally left in place so a
  # failed cross-filesystem copy cannot destroy the existing installation.
  system_src="$skills_src/.system"
  staging=""
  if [[ -d "$system_src" ]]; then
    staging="$CODEX_HOME/.dotfiles-codex-system.$$"
    if [[ -e "$staging" || -L "$staging" ]]; then
      backup_path "$staging"
    fi
    cp -R "$system_src" "$staging"
  fi

  rm -f "$skills_dst"
  mkdir -p "$skills_dst"

  if [[ -n "$staging" ]]; then
    mv "$staging" "$skills_dst/.system"
    log "Preserved Codex-managed system skills under $skills_dst/.system"
  fi
}

install_skills() {
  local skills_src="$CODEX_SOURCE/skills" skills_dst="$CODEX_HOME/skills"
  local skill_src skill_name skill_dst

  if [[ ! -d "$skills_src" ]]; then
    warn "Codex skills source directory is missing: $skills_src"
    return 0
  fi

  if [[ -L "$skills_dst" ]]; then
    if same_path "$skills_dst" "$skills_src"; then
      migrate_legacy_skill_root "$skills_dst" "$skills_src"
    else
      warn "Leaving unrelated Codex skills symlink untouched: $skills_dst -> $(readlink "$skills_dst")"
      return 0
    fi
  elif [[ -e "$skills_dst" && ! -d "$skills_dst" ]]; then
    backup_path "$skills_dst"
    mkdir -p "$skills_dst"
  else
    mkdir -p "$skills_dst"
  fi

  while IFS= read -r -d '' skill_src; do
    skill_name="${skill_src##*/}"
    [[ "$skill_name" == ".system" ]] && continue
    skill_dst="$skills_dst/$skill_name"

    if [[ -L "$skill_dst" ]]; then
      if same_path "$skill_dst" "$skill_src"; then
        continue
      fi
      warn "Leaving unrelated Codex skill symlink untouched: $skill_dst -> $(readlink "$skill_dst")"
      continue
    fi
    if [[ -e "$skill_dst" ]]; then
      warn "Leaving existing Codex skill directory untouched: $skill_dst"
      continue
    fi

    ln -s "$skill_src" "$skill_dst"
    log "Linked Codex skill: $skill_dst -> $skill_src"
  done < <(find "$skills_src" -mindepth 1 -maxdepth 1 -type d -print0)
}

install_override() {
  local destination="$CODEX_HOME/AGENTS.override.md"

  if [[ -z "$OVERRIDE_SOURCE" ]]; then
    if [[ -e "$destination" || -L "$destination" ]]; then
      log "Preserving existing Codex override: $destination"
    else
      log "No AGENTS.override.md created: cluster-specific facts require an explicit Slurm topology audit."
    fi
    return 0
  fi

  if [[ ! -f "$OVERRIDE_SOURCE" ]]; then
    error "Override source does not exist: $OVERRIDE_SOURCE"
    exit 1
  fi

  mkdir -p "$CODEX_HOME"
  if [[ -e "$destination" || -L "$destination" ]]; then
    if cmp -s "$OVERRIDE_SOURCE" "$destination"; then
      log "Codex override already up to date: $destination"
      return 0
    fi
    backup_path "$destination"
  fi

  cp "$OVERRIDE_SOURCE" "$destination"
  chmod 0644 "$destination"
  log "Installed Codex override: $destination"
}

main() {
  if [[ ! -d "$CODEX_SOURCE" ]]; then
    error "Codex files are missing from this checkout: $CODEX_SOURCE"
    exit 1
  fi

  mkdir -p "$CODEX_HOME"
  log "Installing repository-managed Codex files into $CODEX_HOME"
  ensure_file_link "$CODEX_SOURCE/AGENTS.md" "$CODEX_HOME/AGENTS.md"

  if [[ "$INSTALL_HPC_RULES" == "1" ]]; then
    ensure_file_link "$CODEX_SOURCE/rules/hpc.rules" "$CODEX_HOME/rules/hpc.rules"
  else
    log "Skipping hpc.rules on non-Linux host (pass --hpc to opt in)."
  fi

  install_skills
  install_override

  cat <<EOF

Codex installation summary
  portable base: $CODEX_HOME/AGENTS.md
  host-local state: $CODEX_HOME/config.toml, auth, MCP, trust, databases (unchanged)
  cluster override: $CODEX_HOME/AGENTS.override.md (preserved unless explicitly supplied)
EOF
}

main "$@"
