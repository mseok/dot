# Release Checklist

Use this checklist before considering a skill revision complete.

## Required

- Frontmatter `name` and `description` are valid.
- The description includes clear "when to use" wording.
- No `[TODO:` placeholders remain.
- Linked local files in `SKILL.md` exist.
- `agents/openai.yaml` exists and matches the current skill intent.
- `interface.default_prompt` mentions `$skill-name`.
- `python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>` passes.
- `python3 scripts/skill_audit.py <skill-dir>` reports no failures.

If `quick_validate.py` is blocked only by a missing local `PyYAML` install, call that out explicitly instead of pretending the validator passed.

## Recommended

- `SKILL.md` stays concise and pushes deep detail into `references/`.
- The quick start shows the preferred path first.
- Scope boundaries and redirect rules are explicit.
- The output contract is concrete enough to grade success from one response.
- Environment limits are explicit when the skill touches HPC-only execution.

## Closeout note

Record three things in the final response:

1. What concrete failure mode was removed.
2. What structural warnings remain, if any.
3. What prompt should be used next to exercise the revision.
