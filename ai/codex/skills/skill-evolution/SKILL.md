---
name: skill-evolution
description: >
  Audit, score, patch, or retarget an existing Codex skill after real friction.
  Use when the user wants to review a skill without editing it, repair weak
  triggering or workflow drift, harden validation, run an implementation-agent
  and evaluation-agent loop with a rubric and independent scoring, prune
  obsolete branches, or switch the skill's default tool, editor, or output
  medium without creating a new skill. Escalate patch work from narrow to deep
  only when repeated failures or multi-layer drift justify a wider rewrite.
---

# Skill Evolution

Use this skill to improve an existing skill after observing real friction.
Default to the smallest change that removes the failure mode, but treat deep
patching as a first-class path when the skill has drifted across multiple
layers.

## Mode selection

Choose one mode before editing:

- `diagnose-only`: audit the target skill, classify the failure mode, and
  propose changes without editing anything
- `patch`: update the existing skill while preserving the same job; default to
  `narrow patch`, then escalate to `deep patch` only when the evidence justifies
  it
- `retarget`: keep the same job but change the skill's default tool, editor, or
  output medium; old behavior becomes fallback interoperability only

If the real request is "create a new skill from scratch," switch to
`$skill-creator`.

## Patch depth selection

Only choose a patch depth when the mode is `patch`.

- `narrow patch`: one frontmatter fix, one workflow rewrite, one reference
  update, one script change, or one output-contract repair
- `deep patch`: multiple layers drifted at once, such as `SKILL.md`,
  `references/`, `scripts/`, `agents/openai.yaml`, and the output contract no
  longer matching each other

Read [`references/deep-patch-playbook.md`](references/deep-patch-playbook.md)
when deciding whether to escalate.

## Quick start

- Decide the mode: `diagnose-only`, `patch`, or `retarget`.
- If the user wants a score, a threshold such as `>=9`, or separate
  implementation and evaluation roles, read
  [`references/evaluation-loop.md`](references/evaluation-loop.md) before
  patching.
- If the scored path uses the default harness, load
  [`references/score-gate-case-pack.json`](references/score-gate-case-pack.json)
  and validate the evaluator report with
  `python3 scripts/score_gate.py references/score-gate-case-pack.json <evaluator-report.json>`.
- If the mode is `patch`, decide between `narrow patch` and `deep patch`.
- Read the target skill's `SKILL.md`, `agents/openai.yaml`, and only the
  directly relevant references or scripts.
- Run `python3 scripts/skill_audit.py <skill-dir>` for a structural audit.
- Run
  `python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>`
  when a real YAML parse check is available.
- Classify the problem with
  [`references/failure-taxonomy.md`](references/failure-taxonomy.md).
- Use [`references/upgrade-loop.md`](references/upgrade-loop.md) for sequencing.
- Load [`references/specialized-upgrade-cases.md`](references/specialized-upgrade-cases.md)
  only when the failure is about visual excess, broken rendered artifacts,
  external style transfer, or medium retargeting.
- Before closing, read
  [`references/release-checklist.md`](references/release-checklist.md) and pick
  one prompt from
  [`references/mode-test-prompts.md`](references/mode-test-prompts.md).

## Intake contract

- Ask only for the single missing artifact that would materially change the
  chosen mode or patch depth.
- If the user asks for scored improvement and no rubric is provided, the
  implementation agent defines the rubric before patching.
- If the user asks for separate implementation and evaluation agents, the
  implementation agent owns the rubric and patch plan, while the evaluation
  agent scores independently from that rubric alone.
- In the default score-gated path, keep the evaluator report machine-readable
  so it can be checked with `scripts/score_gate.py`.
- If the request is "evaluate" or "improve this skill" without a failing
  example, use the current request plus the first audit finding as enough
  evidence to proceed.
- Use `narrow patch` by default.
- Escalate to `deep patch` only when at least one of these is true:
  - the current request plus the first audit finding already shows drift across
    two or more layers
  - the same failure pattern appears in two or more prompts, sessions, or
    revisions
  - stale branches, obsolete references, or wrong-default-medium leakage are
    materially confusing the skill
- Preserve environment boundaries. If the target skill concerns HPC-only work,
  do not imply local execution happened.

## Workflow

1. Pin down the upgrade driver:
   - explicit failed artifact or transcript
   - current request plus the first audit finding
   - most recent real failure you can point to
2. Choose the mode.
3. If the request is score-gated or requires separate roles, define or confirm
   the rubric and threshold, then read
   [`references/evaluation-loop.md`](references/evaluation-loop.md).
4. If the mode is `patch`, choose `narrow patch` or `deep patch`.
5. Read the target skill's core files and only the relevant helpers.
6. Run structural validation before editing:
   - `python3 scripts/skill_audit.py <skill-dir>`
   - `python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>`
7. Classify the failure using
   [`references/failure-taxonomy.md`](references/failure-taxonomy.md).
8. Choose the smallest effective change:
   - frontmatter description for trigger or scope failures
   - `SKILL.md` for workflow, intake, or output-contract failures
   - `references/` for branch-specific detail or specialized cases
   - `scripts/` for deterministic repeated logic
   - `agents/openai.yaml` for stale UI metadata
9. If the work is `deep patch`, also:
   - prune obsolete branches, dead references, or stale helper logic
   - deduplicate repeated guidance between `SKILL.md` and `references/`
   - realign `SKILL.md`, `references/`, `scripts/`, and `agents/openai.yaml`
   - redesign the validation path when the current one creates false confidence
10. Validate the revision:
   - rerun `quick_validate.py`
   - rerun `skill_audit.py`
   - if the driver was a concrete failed artifact, rerun that artifact path once
     under the revised rules
   - if the default score-gated harness is active, run
     `python3 scripts/score_gate.py references/score-gate-case-pack.json <evaluator-report.json>`
   - if the request is score-gated, rerun the independent evaluation loop until
     the evaluator reaches the requested threshold or states a blocker
11. Close with the required output contract and one realistic next prompt.

## Change selection rules

- Fix frontmatter first only when the failure class is `trigger` or `scope`.
- Keep `SKILL.md` lean. Move branch-specific detail into `references/` and
  repeated deterministic logic into `scripts/`.
- Do not add generic prose or optionality "just in case."
- When the user asks for a score or separate roles, prefer a rubric-based
  implementation and evaluation loop over self-scoring.
- When the user asks for 10/10 or a deterministic harness, prefer the default
  case-pack-based score gate over a prose-only loop.
- Retargeting is an upgrade, not a net-new skill, unless both old and new
  mediums must remain first-class.
- Self-application is allowed. When upgrading `skill-evolution` itself, prefer
  patches that reduce unnecessary clarification, make patch-depth escalation
  explicit, tighten the validation loop, and keep evaluator scoring
  independent.

## Output contract

Return results in this order:

1. `Diagnosis`: the concrete failure mode or upgrade driver, including the
   failure-taxonomy class
2. `Mode`: `diagnose-only`, `patch`, or `retarget`
3. `Patch depth`: `none` for `diagnose-only`, otherwise `narrow patch` or
   `deep patch`
4. `Rubric`: the scoring rubric and threshold, or `not requested`
5. `Revision plan`: the smallest set of changes that should fix the problem
6. `Changes`: proposed changes for `diagnose-only`; applied changes for `patch`
   or `retarget`
7. `Validation`: validator output, structural warnings, `score_gate.py` output
   when used, and why the work did or did not escalate to `deep patch`
8. `Scores`: implementation score, independent evaluation score, and loop
   status, or `not requested`
9. `Next prompt`: one realistic request that should exercise the revised path

If the revision changes the skill's default tool or medium, also state what
remains as fallback interoperability only.
