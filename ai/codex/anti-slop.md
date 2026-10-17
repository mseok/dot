# Anti-slop checks in Claude Code and Codex

The two clients share the existing Ruff selection in `bin/anti-slop-py`.
`bin/anti-slop-hook` adds deterministic checks at the end of a coding turn.
It does not change the selection, rewrite source, launch another model, install
project dependencies, or replace the project's tests and normal lint command.

## Why use a hook

The upstream [anti-slop](https://github.com/dmmulroy/anti-slop) project vendors
Oxlint rules into a repository and uses its ordinary lint and typecheck workflow.
It does not prescribe an agent hook as its default installation. The agent skill
handles installation and updates; the copied rules remain project-owned.

Community examples use both Git checks and agent hooks. A
[stagelint maintainer's workflow and discussion](https://www.reddit.com/r/ClaudeAI/comments/1w1q0j0/enforce_code_style_on_claude_code_with_a_hook_not/)
uses a Stop check for work that may be reviewed before anybody commits it.
The same discussion identifies repeated Stop continuations, stale editor state
after automatic formatting, and confusing linter failures with broken tools.
The [daymade hook guide](https://github.com/daymade/claude-code-skills/blob/main/daymade-claude-code/claude-code-hooks/SKILL.md)
also requires an explicit continuation bound. These are implementation examples,
not measured evidence of a community-wide convention or overall code quality.

The local decision is to automate the existing mechanical check, preserve
judgment in the common working agreement, and give the agent one corrective
continuation. Code quality improvement has not been measured.

## Behavior

SessionStart and UserPromptSubmit capture the current commit and the contents
of already-dirty Python files. Stop compares the current source with that start
baseline. Existing dirty lines are not added to the agent's repair scope.
New files, staged changes and changes committed during the turn are included.
An automatically generated prompt while a repair is pending keeps the original
baseline. Client, session and repository identify separate private state files.

A new violation blocks the first Stop once. The next Stop checks again, but
neither `stop_hook_active` nor the wrapper's persisted block flag permits another
forced continuation. Remaining violations appear as **unresolved**, and a tool
failure appears as **tool_error**. Neither is a passing result. No state is
treated as an automatic permission to repair unrelated code or weaken rules.
Continuations caused by another Stop hook also receive warning-only feedback.

The snapshot limit is 2 MiB across already-dirty Python files. Each metadata
command has a 5-second timeout; the checker has a 20-second timeout; the native
handler has a 30-second timeout. A checker timeout kills its owned process group,
including child linters. Diagnostic feedback is capped at 4,000 characters.
State is saved atomically with private permissions under the host's local
temporary directory. It contains source baselines and must not be published.
Ruff caching is disabled for this short check, so it does not create or update
project cache directories on shared or read-only source storage.

This preserves the existing changed-line policy. Ruff reports `ARG001` on the
function declaration, which an edit to the body leaves unchanged, so it counts
when the edit created it relative to the start version; an argument that was
already unused stays out of scope.

The selection omits `C901` (complexity) and the style rules (C4, SIM, RET, PERF,
RUF005, PLC0415). In a 2026-10-15 comparison, agents fixed every complexity
finding by splitting code into single-use helpers, and a blind review preferred
the code before the fix in all four cases; style fixes were ties that cost a
turn. The upstream TypeScript rules have no complexity rule either.

Three checks that no Ruff rule covers run on the same scope. They target code
that costs cleanup time later and had high precision on sampled real repositories:

- `AS100`: a module-level function that nothing outside tests calls, when the
  function is new or the change removed its last caller. Calls from tests do not
  count, so writing a test for dead code does not hide it. Decorated functions,
  `main`, dunder names and names in `__all__` or package entry points are exempt.
- `AS101`: a new function whose body repeats an existing function of at least 60
  syntax nodes, ignoring names and docstrings. Import or move the original instead.
- `AS102`: a function or class defined after the `if __name__ == '__main__':`
  guard, which does not exist when the file runs as a script.

In the follow-up comparison these checks plus the remaining Ruff rules blocked 3
of 21 Claude runs, and each correction improved the code in blind review. Run
details are in `/tmp/anti-slop-eval-20261014/summary.md` on messi, which is not
durable.

The check does not prove semantic correctness or complete type safety. Concurrent editors changing the same repository cannot be reliably
attributed to one agent; use the existing separate-checkout workflow when needed.

## Coding guidelines

Sections 2 and 3 of the coding guidelines in `AGENTS.md` replace the upstream
general rules with the specific patterns that cost cleanup time: unrequested
options, fallbacks for impossible cases, an `except` that hides an error,
single-use layers or copied functions, tests that would pass without the
change, and leftovers kept for compatibility. The other sections and every
behavior rule are unchanged.

A 2026-10-15 comparison ran the old and new files under Claude Opus 5.5 and
Codex gpt-6.1-sol, both at high effort, with hooks off: 7 coding tasks
(14 runs per arm) and behavior probes for asking first, email, scientific
comparisons, verification and response format.

- Hidden tests passed 14/14 in every arm.
- Blind review with both orders was a tie: Claude 4:4 (2 ties, 4 inconsistent),
  Codex 3:2 (3 ties, 6 inconsistent). The mean cleanliness score rose from 4.18
  to 4.43 for Claude and from 4.25 to 4.32 for Codex (5 = clean).
- Claude added 15% fewer test lines and used 10% fewer tokens and 16% less
  time. Codex was unchanged.
- Behavior probes held. The new file's only miss was one Claude format probe
  (7/8; old file 4/4), while the old file missed 2 of 4 Claude style probes.
  Moving the response style to a Claude output style made no measurable
  difference, so it stays in `AGENTS.md`, which Codex can read.
- Codex sent the probe's email without asking in all 12 runs (4 old, 8 new).
  Claude asked first in all 20. The text rule alone did not stop Codex.

## Install and verify

Run `python3 ~/dot/bin/install_anti_slop_hooks.py` on the intended host. It merges
only the three handlers into each client's existing settings, preserves unrelated
hooks and configuration, and creates protected backups before atomic publication.
Re-running it does not duplicate handlers. Runtime configuration remains host-local.

Codex requires review and trust of new handlers in `/hooks`, as described by
[OpenAI's hook documentation](https://learn.chatgpt.com/docs/hooks).
Do not bypass trust or manufacture trusted hashes. Existing sessions may need
to reload hooks or restart before the new handlers run. Claude's Stop behavior
and continuation field are documented in its
[hook reference](https://code.claude.com/docs/en/hooks#stop).

Run `python3 -m unittest discover -s tests -p test_anti_slop_hooks.py -v` from
the dotfiles repository to verify scope and loop protections with disposable
fixtures. The ordinary manual command remains `~/dot/bin/anti-slop-py`.
Its optional `--baseline FILE` is intended for the hook's private snapshot.

To remove the integration, remove only handlers whose command invokes
`~/dot/bin/anti-slop-hook` from SessionStart, UserPromptSubmit and Stop in each
client's settings. Keep research and other host-specific handlers. Do not restore
an old full settings backup over subsequent unrelated configuration changes.
