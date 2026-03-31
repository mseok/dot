# Release Checklist

Use this checklist before considering a skill revision complete.

## Required

- Frontmatter `name` and `description` are valid.
- The description includes clear "Use when" trigger wording.
- No `[TODO:` placeholders remain.
- Linked local files in `SKILL.md` exist.
- `agents/openai.yaml` exists and matches the current skill intent.
- `interface.default_prompt` mentions `$skill-name`.
- `SKILL.md` names the three modes: `diagnose-only`, `patch`, `retarget`.
- `SKILL.md` names the patch-depth terms: `narrow patch`, `deep patch`.
- The output contract includes `Diagnosis`, `Mode`, `Patch depth`,
  `Revision plan`, `Changes`, `Validation`, and `Next prompt`.
- `python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>`
  passes, or a missing `PyYAML` dependency is called out explicitly.
- `python3 scripts/skill_audit.py <skill-dir>` reports no failures.

## Mode consistency

- `SKILL.md` and `agents/openai.yaml` use the same mode names.
- The chosen mode and patch depth appear in the final closeout.
- If scoring was requested, the closeout includes `Rubric` and `Scores`.
- If the work is `deep patch`, the closeout states why a narrow patch was not
  enough.
- If the work is not `deep patch`, the closeout states why escalation was not
  needed.

## Behavioral gate

- At least one realistic prompt from `references/mode-test-prompts.md` matches
  the revised path.
- If the request is score-gated or uses separate roles, the loop in
  `references/evaluation-loop.md` was followed or explicitly not needed.
- If the default score-gated harness was used,
  `python3 scripts/score_gate.py references/score-gate-case-pack.json <evaluator-report.json>`
  passes.
- If the request is score-gated, the independent evaluation score meets the
  requested threshold or the blocker is stated explicitly.
- Structural validation is not presented as proof of behavioral correctness.
