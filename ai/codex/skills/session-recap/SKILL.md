---
name: session-recap
description: "End-of-session checklist. Checks for uncommitted changes, offers to update focus, project docs, context, and session log. Replaces the old stop reminder flow."
allowed-tools: Bash(git*), Read, Write, Edit, Glob, Grep, Skill, Task
argument-hint: (no arguments)
---

# Closing — End-of-Session Checklist

> On-demand session wrap-up. Run `$session-recap` when you're done working to make sure nothing is lost.

## When to Use

- End of a work session
- Before switching projects
- When the user says "wrap up", "closing time", "let's close out", "end of session"

## What It Does NOT Do

- Never runs automatically — this is user-triggered only
- Never forces any action — every step is offered, not imposed
- Never pushes to remote unless explicitly confirmed

---

## Quick Reference: What Gets Updated Where

| Action | What it writes | What it captures |
|--------|---------------|-----------------|
| **Update focus** | `.context/current-focus.md` | Session summary (rotated history), open loops, mental state, weekly goals |
| **Refresh project docs** | Project's own `AGENTS.md`, `README.md`, `docs/*.md` | Stale file trees, outdated counts, next steps |
| **Sync project state** | `.context/projects/_index.md` | Project stage, target journal, co-authors, status |
| **Archive session log** | `log/YYYY-MM-DD-HHMM.md` (new file) | Detailed timestamped record of the full session |
| **Memory** (automatic) | Auto memory (`~/.codex/projects/<hash>/memory/MEMORY.md`) + project-root `MEMORY.md` | Infrastructure learnings → auto memory; domain knowledge (notation, decisions, citations) → project memory |
| **Save to context** (only if needed) | Any file in `.context/` (profile, people, workflows) | New collaborators, preferences, workflow changes — facts to persist beyond this session |

---

## Protocol

Three phases: **scan**, **interview**, **execute in parallel**, then **git last**.

### Phase 1: Context Scan (automatic, no prompting)

Silently detect what's applicable. Do these checks in parallel:

1. **Session summary** — prepare a 3-5 bullet recap of what was done this session
2. **Git repo?** — `git rev-parse --is-inside-work-tree 2>/dev/null`
3. **Has project docs?** — check for `AGENTS.md` or `README.md` in CWD
4. **Context root available?** — check whether `.context/` (or configured task-management context path) is accessible
5. **Has uncommitted changes?** — `git status` + `git diff --stat` (if git repo)
6. **Memory candidates** — scan session for learnings, gotchas, decisions worth persisting
7. **Working directory validation** — resolve CWD to its project name. Print: `Session closing for: <project-name> (<full-path>)`. This becomes the anchor for all file writes in Phase 3.

### Phase 2: Interview (one interaction)

Present the session summary, then ask **one multi-select question** with all applicable actions:
Use a single multi-select prompt in plain chat.

**Question:** "Which closing actions do you want to run?"

| Option | When to include | Description |
|--------|-----------------|-------------|
| **Update focus** | Only if context root is available | Rotate session history in `.context/current-focus.md` — captures where you left off, manages open loops, updates weekly goals |
| **Refresh project docs** | Only if CWD has `AGENTS.md` or `README.md` | Update the project's own `AGENTS.md`/`README.md` — fixes stale file trees, counts, and next steps |
| **Sync project state** | Only if context root is available and CWD has `AGENTS.md` | Propagate stage/journal/status to `.context/projects/_index.md` and related project context files |
| **Archive session log** | Always | Create timestamped `log/YYYY-MM-DD-HHMM.md` — permanent detailed record of this session |

Pre-select recommended options by listing them first with "(Recommended)" suffix. Typically: Update focus + Archive session log.

**Memory** — automatic, never asked. Both MEMORY.md files are updated silently:
- **Auto memory** (`~/.codex/projects/<hash>/memory/MEMORY.md`): infrastructure learnings, tool gotchas, permission patterns
- **Project memory** (project-root `MEMORY.md`): domain corrections and decisions (per `learn-tags` rule)

After saving, the memory updates are **shown for review** in Phase 3.5 — you can veto or adjust before git commit.

**Save to context** — do NOT include in the multi-select (it needs free-form input). After Phase 3 completes, ask separately only if the session produced something clearly worth saving to `.context/` (a new collaborator, workflow preference, research insight). If nothing stands out, skip silently.

### Phase 3: Parallel Execution

**Path validation gate** (before launching agents):

Confirm all output paths are within the Task Management directory or the current project directory:
- `.context/current-focus.md` → Task Management
- `log/YYYY-MM-DD-HHMM.md` → Task Management
- `AGENTS.md`, `README.md` → CWD (must be a project directory, not a parent)
- `MEMORY.md` → CWD or auto-memory path

If context root is not available, skip "Update focus" and "Sync project state", then tell the user exactly which actions were skipped and why.

If CWD is a parent directory (e.g., Research Projects root instead of a specific project), warn: *"CWD appears to be a parent directory, not a project. Session log and focus update will proceed, but project docs refresh is skipped."* Do NOT write project-specific files to parent directories.

Launch **parallel Task agents** (subagent_type: "general-purpose") for all selected actions simultaneously. Each agent handles one action independently:

| Agent | What it writes |
|-------|---------------|
| Focus agent | `.context/current-focus.md` — session rotation, open loops, weekly goals |
| Project docs agent | Project `AGENTS.md`, `README.md` — stale trees, counts, next steps |
| Project state agent | `.context/projects/_index.md` — stage, journal, status |
| Session log agent | `log/YYYY-MM-DD-HHMM.md` — timestamped session archive |

**Memory update** runs in the main context (it's fast — just appending to MEMORY.md files) while agents execute.

Wait for all agents to complete before proceeding to Phase 3.5.

### Phase 3.5: Memory Review

After agents complete, show what was saved to memory (if anything):

```
Memory updates:
  Auto memory:    + "zsh `status` is read-only — use `result` instead"
  Project memory: + [LEARN:notation] Treatment is D_i not T_i
                  + Key Decision: Use CS estimator (staggered treatment)
```

If nothing was saved, show: `Memory: nothing to save this session.`

the user can say "undo" or "remove the last one" to adjust. Otherwise, proceed to Phase 4.

### Phase 4: Git Sync (must be last)

Only after all Phase 3 agents have completed (so their file changes are included):

1. Run `git status` (never use `-uall`) and `git diff --stat`
2. If there are uncommitted changes, ask with an explicit multiple-choice prompt:
   - **Commit & push (Recommended)** — stage, commit, and push to remote
   - **Commit only** — stage and commit, no push
   - **Skip** — leave changes uncommitted
3. Before pushing, verify a remote exists with `git remote -v`. If no remote, warn and fall back to commit-only.

If not a git repo, skip silently.

---

## Output

After all phases, print a summary:

```
Session closed:
  Focus:        updated / skipped
  Project docs: refreshed / skipped / n/a
  Memory:       updated [N items] / nothing to save
  Context:      saved [what] / skipped
  Session log:  created / skipped
  Git:          committed & pushed (abc1234) / committed (abc1234) / skipped / not a repo
```

---

## Design Notes

- **One interaction, not seven.** The old sequential approach required 6-7 separate confirmations. Now it's one multi-select + one git question.
- **Parallel agents** for independent actions. Focus, docs, and session log don't depend on each other.
- **Memory is automatic but visible.** Always saved (it's never destructive), but shown for review in Phase 3.5 so you can veto or adjust before git commit.
- **Git is always last.** It captures all file changes from the parallel agents.
- This skill replaces the old stop-reminder flow (deleted — it was too noisy). `$session-recap` is **opt-in** — the user invokes it when ready.
