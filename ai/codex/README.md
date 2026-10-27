# Codex guidance

`AGENTS.md` is the common working agreement for local and remote work. Each
host links its global `~/.codex/AGENTS.md` to this checkout. The complete server
policy is part of that file, so Codex includes it without an extra file-read
decision. Its server section applies to server execution, including SSH from a
Mac; it does not govern ordinary local Mac work. Server operations also read
the target host's `~/.codex/host-context.md` for host-specific facts.

Update guidance without migrating skills or changing command permissions:

```bash
~/dot/bin/install_codex.sh --guidance-only
```

The installer removes only the obsolete `SERVER.md` symlink that it managed.
Custom files and unrelated symlinks are preserved. `SERVER.md` is no longer a
separate source of shared policy.

Keep each host's checkout on the same published `main` commit. Fetch and
fast-forward reviewed changes, then run the guidance-only installer. Preserve
and reconcile local modifications before updating; do not reset or discard
them to make synchronization succeed. No background Git synchronization is
installed.

`host-context.md` retains audited topology and environment facts on that host.
The `init-slurm-environment` skill updates its managed topology block only
after an explicit full audit. Installation or migration never runs a cluster
audit, guesses storage paths or launches work.

A legacy `AGENTS.override.md` replaces the common policy in Codex; it does not
extend it. Review a generated override's copied body, then migrate it with:

```bash
~/dot/bin/install_codex.sh --guidance-only --migrate-slurm-override
```

This preserves the audited topology block byte for byte in `host-context.md`
and moves the entire old override to a timestamped backup. Custom overrides
and conflicting host context require review. The legacy `--override-from`
option remains explicit and warns that it shadows the common policy.

The full installer also installs `rules/hpc.rules` on Linux/HPC and migrates
personal skills from `~/agent-skills/skills/codex`. The old `skills/` path
contains ignored compatibility links. System skills stay host-local.

`config.toml`, credentials, MCP registrations, project trust, databases and
host facts are not shared through this repository. Rule files control command
permissions separately from AGENTS guidance. A local checkout change is not a
push or an update to another host; sync the reviewed source explicitly.
Already running tasks must reread changed guidance, or start a new task.

Keep each project's runtime environment separate. Python, CUDA and framework
versions belong to that project. General development tools such as Ruff use
the host-shared installation recorded in `~/.codex/host-context.md`, even when
a project environment is active. Follow the project configuration; do not
resolve its dependencies merely to lint or format.

Reuse an existing current handoff or manifest for long-running work. When none
is suitable, `~/dot/bin/codex-task-state read PATH` reads a compact JSON handoff
and its SHA-256. To create one, pipe JSON with `goal` and `next_action` into
`~/dot/bin/codex-task-state write PATH`. Replacing an existing file requires
`--expected-sha HASH` from the latest read, so stale updates are rejected.
Optional fields are `scope`, `decisions`, `sources`, `active_operations`,
`completed_checks`, `pending_questions` and `status`. Keep it in the task's
existing artifact location and update only at meaningful transitions.
A write appends every entry it removes, and replaced goal or scope text,
verbatim to `<name>.history.jsonl` beside the handoff before replacing it.
Completed checks carry IDs such as `[k12]`. Over a 12,000-byte budget the
oldest checks move to the history, except the newest ten and those that another
field cites; a handoff still over budget is saved with a warning. A handoff
records its own path, so `read` reports a copy whose original still exists.
Install the tool before the `thread-handoff` text that tells agents to delete
reversed decisions. To roll back, restore the old tool with `path` added to the
metadata keys it drops, so handoffs the new tool wrote stay writable.

`AGENTS.md` keeps one upstream block, fenced by markers and pinned to the commit
it was copied from: the coding guidelines (`karpathy-guidelines`, from
multica-ai/andrej-karpathy-skills, MIT; sections 2-3 rewritten locally on
2026-10-15; on 2026-10-17 its section 1 was folded into the lead-in because it
contradicted the working agreement's ask rules, section 4 was condensed and
the rest renumbered). The former Attention-kind response-style block
(alexgreensh/attention-span, AGPL-3.0) was replaced on 2026-10-17 by the short
"Chat reply style" section, scoped to chat replies, after the 2026-08..10 audit
found it bleeding into manuscripts, emails and UI work and measured two of its
rules as unfollowed; the full body is installed as the opt-in Claude Code output
style `~/.claude/output-styles/attention-kind.md`, and the original block is
kept in the audit folder. A trim pass on 2026-10-17 moved procedures that a
skill already carries (Slurm launch contract, staging and polling; comparison
labelling; handoff fields) into those skills, host facts into host-context,
and split the body into one rule per bullet; the audit folder's trim ledger
lists every removed sentence with its destination. Codex auto-loads only the AGENTS.md chain with no
imports, and Claude Code loads CLAUDE.md plus its imports, so rules that must
always apply live in the AGENTS.md body; procedures live in skills and
`ai/codex/references/` (currently the Codex browser procedure), which are read
only when the model decides to.

`bin/guidance-check` (SessionStart hook) reports when the global links drift or
an `AGENTS.override.md` shadows the common file, and prints the goal of a
`task-state.json` found in the working tree. `bin/reply-path-check` (Stop hook)
warns when the final reply names relative, missing or unreadable local paths;
both only emit a system message and never block. Wire them in each host's
`~/.claude/settings.json` and `~/.codex/hooks.json`.

`bin/anti-slop-py` is a Python counterpart of dmmulroy/anti-slop. It runs the
host Ruff with a fixed rule selection on the Python files changed against
`HEAD` (or `--base REF`) and reports only findings on changed lines, so
existing code is not gated. The project's other Ruff settings still apply. The
rule list at the top of the script is a matter of taste; edit it there. The
`verification-before-completion` skill comes from obra/superpowers through
`~/agent-skills`.

For automatic checks in Claude Code and Codex, run `python3 ~/dot/bin/install_anti_slop_hooks.py` on the intended host. It preserves existing host-local hooks and adds a bounded Stop check. See [anti-slop hook behavior and verification](anti-slop.md) for scope, timeouts, trust and limitations.

Research guidance is maintained by `obsidian-main/scripts/deploy-research.py`.
The global file carries a short router; detailed recording policy is loaded
once through the relevant research skill. Project files retain their own
instructions without another copy of the shared research block. Use the
deployer's `--guidance-only --client codex --files-file FILE` mode for an
explicit list of guidance files without changing hooks or runtime settings.
