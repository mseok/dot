---
name: git-add-commit
description: Stage Git changes and create a concise commit from the staged diff. Use when the user asks to add unstaged or untracked files only if needed, summarize the actual code changes, and commit in one flow.
---

# Git Add Commit

Use this skill to create a commit in one pass while keeping staging behavior safe and explicit.

## Workflow

1. Validate repository context.
- Run `git rev-parse --is-inside-work-tree`.
- Inspect `git status --short` to see staged vs unstaged changes.

2. Stage only missing changes.
- If unstaged or untracked files exist, run `git add -A`.
- If all intended changes are already staged, do not restage blindly.

3. Build a commit summary from the staged diff.
- Prefer `scripts/git_add_commit.sh --dry-run` to generate a subject and body draft.
- Keep subject concise and action-first (for example `add:`, `fix:`, `update:`, `refactor:`).
- Keep body factual: shortstat plus key changed files.

4. Create the commit.
- Run `scripts/git_add_commit.sh` to auto-generate the message.
- Run `scripts/git_add_commit.sh --message "<subject>"` when the user gives an exact subject.
- If nothing is staged after optional add, stop and report that there is nothing to commit.

5. Report the result.
- Return commit hash and final commit subject.
- Mention if `git add -A` was executed because unstaged changes were detected.

## Script

Use `scripts/git_add_commit.sh` for deterministic behavior.

- `--dry-run`: preview generated commit message and file summary without committing.
- `--message "..."`: force a subject while preserving auto-staging behavior.
