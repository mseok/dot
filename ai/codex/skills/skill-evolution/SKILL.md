---
name: skill-evolution
description: Continuously improve existing Codex skills through failure-driven iteration. Use when the user wants to upgrade, harden, version up, or refactor a skill after real usage; tighten trigger descriptions, restructure SKILL.md, add references/scripts/assets, or add validation so the next invocation performs better.
---

# Skill Evolution

Use this skill to revise an existing skill after observing actual friction. Prefer the smallest high-leverage change that makes future invocations trigger earlier, ask fewer unnecessary questions, and produce more reliable outputs.

## Quick start

- Read the target skill's `SKILL.md`, `agents/openai.yaml`, and only the directly relevant resources.
- Run `python3 scripts/skill_audit.py <skill-dir>` for a fast structural audit.
- Load `references/failure-taxonomy.md` to classify the observed problem.
- Load `references/upgrade-loop.md` to choose the change type and implementation order.
- Load `references/release-checklist.md` before finalizing the revision.

## Operating rules

- Upgrade from concrete evidence: user feedback, failed outputs, repeated clarifications, missing resources, or stale guidance.
- Fix trigger quality first. If the skill does not activate for the right requests, improve the frontmatter description before expanding the body.
- Keep `SKILL.md` lean. Move detailed patterns into `references/`, deterministic logic into `scripts/`, and reusable deliverables into `assets/`.
- Do not add generic prose "just in case." Every added line should remove a known failure mode or reduce future ambiguity.
- Preserve environment boundaries. If the target skill concerns HPC-only work, do not imply that training, inference, or experiments were executed locally.
- When adding scripts, keep them local-utility focused and testable without remote infrastructure.
- If the request is really "create a new skill from scratch," switch to `$skill-creator` or apply the same initialization workflow first.

## Upgrade workflow

1. Pin down the upgrade driver:
   - one wrong answer pattern
   - one missing workflow
   - one repeated clarification
   - one validation gap
2. Run `scripts/skill_audit.py` on the target skill and collect the warnings.
3. Classify the problem with `references/failure-taxonomy.md`.
4. Choose the smallest effective fix:
   - frontmatter description
   - `SKILL.md` workflow
   - `references/`
   - `scripts/`
   - `agents/openai.yaml`
5. Patch the skill.
6. Validate the revision:
   - run `python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>`
   - rerun `python3 scripts/skill_audit.py <skill-dir>`
   - if `quick_validate.py` fails because `PyYAML` is unavailable in the local Python, report that explicitly and treat `skill_audit.py` as the minimum local gate until the environment is fixed
7. Close with:
   - what failure mode was removed
   - what remains unresolved
   - what real prompt should exercise the revised path next

## Change selection rules

- Edit the frontmatter description when trigger coverage is the problem.
- Edit `SKILL.md` when the workflow order, scope boundaries, or output contract are unclear.
- Add `references/` when the skill needs detailed domain guidance that should load only on demand.
- Add `scripts/` when the same deterministic logic would otherwise be rewritten every time.
- Edit `agents/openai.yaml` when the UI metadata or default prompt is stale.

## High-value targets

- Trigger misses: description is too narrow, too vague, or missing concrete use cases.
- Context bloat: `SKILL.md` is long because specialized details were not moved into references.
- Procedure drift: quick-start steps no longer match the best workflow.
- Capability drift: the skill promises tasks it should redirect away from.
- Validation gaps: broken links, stale placeholders, or missing UI metadata are not caught quickly.
- Environment mismatch: instructions imply local execution for HPC-only steps.
- Weak handoff: the skill lacks a clear output contract or final deliverable.

## Output contract

When upgrading a skill, present the result in this order:

1. `Diagnosis`: the concrete failure mode or upgrade driver.
2. `Revision plan`: the smallest set of changes that should fix it.
3. `Applied changes`: what was modified in the skill.
4. `Validation`: validator output and any remaining warnings.
5. `Next prompt`: one realistic user request that should test the new path.

If the upgrade is blocked by missing artifacts, ask for the single missing input that would change the patch.
