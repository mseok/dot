<!-- BEGIN obsidian-research (managed by obsidian-main/scripts/deploy-research.py) -->
## Research continuity

For research work, use `research-workflow` at meaningful hypotheses, changes,
results or decisions; use `experiment-ledger` for comparable terminal results.
Read the relevant skill and its shared recording policy once, then reuse it.
Keep one question report across hosts, preserve user corrections and distinguish
proposals from adopted decisions. Existing authorization covers ordinary
milestone recording. Routine checks do not earn notes. Vault access uses only
host-local `obsidian_main`; never direct files or vault Git. Perform the end-turn
omission check only with active hook-provided session/turn IDs.
<!-- END obsidian-research -->

# Shared working agreement

- The maintained source is `~/dot/ai/codex/AGENTS.md`. Keep each host's global `AGENTS.md`, and Claude Code's global `CLAUDE.md`, linked to its local checkout of this source. Configuration, credentials, MCP registrations and model choices remain host-local.
- Preserve the latest agreed goal, permitted changes, existing structure and completion criterion across turns. Analysis and review permit reading and review artifacts; they do not by themselves authorize changing the target, launching experiments or publishing. Existing explicit authorization remains valid.
- Ask whenever an unresolved ambiguity could change the intended result, scientific meaning, scope, cost or execution conditions. First use the available context to resolve factual gaps. Do not substitute your preference or interpret silence as agreement. Continue independent work while waiting.
- A repeated failure is a reason to reassess the cause, not permission to switch methods. Do not impose a fixed retry count or blindly repeat an unchanged attempt. An equivalent low-impact diagnostic within the agreed scope is allowed; ask before changing the method's meaning, environment, resources, evaluation conditions or external effects. Honor a workflow's existing bounded retry contract.
- Use the current handoff, manifest or index before searching raw history. Narrow to named paths and relevant sections, summarize long tool outputs and retain recovery locators. Avoid repeated full-history reads, broad filesystem scans and encoded media in text output.
- Keep execution and debugging minimal. Run a check only to resolve a concrete uncertainty or satisfy a relevant existing requirement; stop after it passes unless new evidence warrants more. Do not add routine smoke runs, speculative defensive code or unrelated cleanup. Follow the codebase's existing style.
- Retain active process and job identifiers; a tool timeout does not authorize a duplicate launch. Check the exact destination and user-visible result before reporting completion. Distinguish planned, submitted, running, evaluated and published states, and report checks that could not run.
- Use the project's existing artifact location and permission scope. Do not automatically rewrite global sandbox settings for an ordinary output. Preserve unrelated files, environment state and running jobs.
- Keep each project's runtime dependencies in its own environment; follow that project's Python, CUDA and framework versions. Reuse the existing environment, and create a separate one when an authorized new project needs it. Use host-shared installations for general development tools such as Ruff, while respecting project configuration. Do not resolve project dependencies or recreate its environment merely to format or lint; ask if the shared tool cannot satisfy a required version.
- For recurring or long-running work, reuse an existing current handoff or manifest. If none is suitable, keep a compact current-state file in the task's artifact location with `~/dot/bin/codex-task-state`: goal, agreed boundaries, decisions, exact sources, active process/job IDs, completed checks, pending questions and next action. Update at material transitions, not every tool call. Store bulk logs and research evidence elsewhere. Automate stable repeated checks and call a model only for new judgments or exceptions.

## Scientific comparisons

- Define the intended comparison factor first and match all other relevant conditions: cohort and splits, input/reference preparation, compute or sampling budget, seeds and candidate counts, selection rule, evaluator/version, metric, denominator and missingness policy. Derive membership from the current agreed manifest; do not hardcode a historical population.
- Present a performance or causal comparison only on that matched basis. If conditions cannot be matched, explicitly separate the results as non-comparable descriptive evidence and ask how to harmonize them before making the comparison. Do not silently change protocols or launch additional computation to manufacture comparability.
- Preserve source, checkpoint/run, metric direction, numerator/denominator and dependency unit. Separate observations, assumptions, proposals and adopted decisions. A different data source, aggregation or evaluator is not by itself model improvement.
- For durable or comparable experiments, use committed source and `experiment-ledger`. Before recording HEAD as the source, require a clean index and tracked tree and no execution-affecting untracked repository file. Preserve unrelated work; ask if it blocks launch rather than altering it or creating a worktree solely for cleanliness.

## Conditional procedures

- For research recording, follow the managed section above and the relevant research skill. Call `research_disposition` only when hook context supplies an active research session and turn; do not invent IDs or repeat a no-active-turn failure for administrative work.

## Server work

These rules apply to server execution, including SSH work started on a Mac.
They are included here so loading AGENTS.md also loads the complete server policy.
Read the target host's `~/.codex/host-context.md` when present for established
topology and environment facts. Missing facts require a bounded check or
clarification, not a full cluster audit.

- Minimize CPU, GPU, memory and shared-storage load. On controller/login hosts,
  use only short, bounded metadata reads. Put compute- or staging-heavy work in
  the appropriate allocation. Direct compute-node work requires user/site
  authorization and current allocation evidence.
- Before launching, establish the purpose, relevant input subset, requested
  nodes, GPUs per node, total GPUs, CPU/memory budget, concurrency, time limit,
  output location and stop condition. Preserve the user's resource semantics;
  do not turn a diagnosis into a sweep or invent a larger budget.
- Request resources supported by the workload; do not reserve whole nodes,
  excessive CPUs/RAM or exclusive access by habit. Bound process workers and
  nested library threads to the allocation. Do not benchmark resource sizes
  merely to choose a default unless that uncertainty matters to the task.
- Use existing manifests and explicit paths. Do not recursively list, hash,
  decompress or scan shared roots or archives to find one result. Expand a
  scoped search only when the narrower lookup does not answer the question.
- Reuse the established interpreter and tools. Do not repair a routine check
  by recreating environments, changing lockfiles or clearing shared caches.
  Diagnose the cause and ask before such changes. A known equivalent tool in
  the existing environment may be used without changing the task's meaning.
- Keep short debugging runs free of runtime compilation unless compilation is
  the subject of the check. Preserve and record compilation mode in comparable
  result-producing runs.
- Use allocation-local staging when the workload benefits from it; first check
  the actual mount and capacity. Cover repeated input/model reads, caches,
  temporary files and final publication. Do not copy environments per node or
  silently fall back to shared storage without a concrete reason.
- For durable shared artifacts, follow the producing application's checked
  close and atomic-publication contract, with one writer per artifact. Shared
  visibility alone does not prove durable or coherent writes. Preserve the
  host's recorded NFS constraints and existing failure/restart behavior.
- Poll owned job IDs or retained process handles at a cadence appropriate to
  expected duration and the user's request. Back off while unchanged; no fixed
  short sleep loop by default. Submission is not completion: inspect terminal
  state and the relevant result/evaluation receipt. Cancellation or replacement
  must remain within the user's explicit authorization.
- Keep generated results in the established artifact root. A source edit does
  not update already-submitted jobs or frozen archives; report what was changed,
  checked and actually deployed.
