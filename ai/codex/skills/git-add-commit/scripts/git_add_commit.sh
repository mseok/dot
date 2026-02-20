#!/usr/bin/env bash
set -euo pipefail

print_usage() {
  cat <<'USAGE'
Usage: git_add_commit.sh [--dry-run] [--message "subject"]

Options:
  --dry-run            Preview commit message and staged file summary.
  --message "subject"  Use explicit commit subject.
  -h, --help           Show this help.
USAGE
}

dry_run=0
message=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    --message)
      if [[ $# -lt 2 ]]; then
        echo "Error: --message requires a value." >&2
        exit 2
      fi
      message="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      print_usage >&2
      exit 2
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: Not inside a Git repository." >&2
  exit 1
fi

added_now=0
if ! git diff --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  git add -A
  added_now=1
fi

if git diff --cached --quiet; then
  echo "No staged changes to commit."
  exit 0
fi

staged_name_status="$(git diff --cached --name-status)"
staged_files="$(printf '%s\n' "$staged_name_status" | awk 'NF {print $NF}')"
file_count="$(printf '%s\n' "$staged_files" | awk 'NF' | wc -l | tr -d ' ')"
shortstat="$(git diff --cached --shortstat | sed 's/^ *//')"

if [[ -z "$message" ]]; then
  added_count="$(printf '%s\n' "$staged_name_status" | awk 'substr($1,1,1)=="A"{c++} END{print c+0}')"
  modified_count="$(printf '%s\n' "$staged_name_status" | awk 'substr($1,1,1)=="M"{c++} END{print c+0}')"
  deleted_count="$(printf '%s\n' "$staged_name_status" | awk 'substr($1,1,1)=="D"{c++} END{print c+0}')"
  renamed_count="$(printf '%s\n' "$staged_name_status" | awk 'substr($1,1,1)=="R"{c++} END{print c+0}')"
  copied_count="$(printf '%s\n' "$staged_name_status" | awk 'substr($1,1,1)=="C"{c++} END{print c+0}')"

  action="update"
  non_zero_ops=0
  for c in "$added_count" "$modified_count" "$deleted_count" "$renamed_count" "$copied_count"; do
    if [[ "$c" -gt 0 ]]; then
      non_zero_ops=$((non_zero_ops + 1))
    fi
  done

  if [[ "$non_zero_ops" -eq 1 ]]; then
    if [[ "$added_count" -gt 0 ]]; then
      action="add"
    elif [[ "$deleted_count" -gt 0 ]]; then
      action="remove"
    elif [[ "$modified_count" -gt 0 ]]; then
      action="update"
    else
      action="refactor"
    fi
  elif [[ "$deleted_count" -gt 0 && "$added_count" -gt 0 && "$modified_count" -eq 0 ]]; then
    action="restructure"
  fi

  top_dirs="$(printf '%s\n' "$staged_files" | awk -F/ 'NF{print (NF>1 ? $1 : ".")}' | sort | uniq -c | sort -nr)"
  distinct_scope_count="$(printf '%s\n' "$top_dirs" | awk 'NF' | wc -l | tr -d ' ')"
  top_scope="$(printf '%s\n' "$top_dirs" | awk 'NF{print $2; exit}')"

  scope="multiple areas"
  if [[ "$distinct_scope_count" -eq 1 ]]; then
    if [[ "$top_scope" == "." ]]; then
      scope="root files"
    else
      scope="$top_scope"
    fi
  fi

  message="${action}: ${scope}"
fi

body_stat="$shortstat"
if [[ -z "$body_stat" ]]; then
  body_stat="${file_count} file(s) changed"
fi

file_lines="$(printf '%s\n' "$staged_files" | awk 'NR<=8 {print "- " $0}')"
if [[ "$file_count" -gt 8 ]]; then
  file_lines="${file_lines}\n- ... (${file_count} files total)"
fi

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run: commit not created."
  if [[ "$added_now" -eq 1 ]]; then
    echo "Auto-staged unstaged/untracked changes with git add -A."
  fi
  echo
  echo "Subject:"
  echo "$message"
  echo
  echo "Body:"
  echo "$body_stat"
  echo
  echo "Files:"
  printf '%b\n' "$file_lines"
  exit 0
fi

git commit -m "$message" -m "$body_stat"$'\n\n'"Files:"$'\n'"$(printf '%b\n' "$file_lines")"

commit_hash="$(git rev-parse --short HEAD)"
echo "Committed ${commit_hash}: ${message}"
if [[ "$added_now" -eq 1 ]]; then
  echo "Included unstaged/untracked changes via git add -A."
fi
