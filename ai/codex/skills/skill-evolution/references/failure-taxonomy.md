# Failure Taxonomy

Use this taxonomy to convert vague "the skill feels weak" feedback into a
concrete patch target.

## 1. Trigger failure

Symptoms:

- The skill does not activate for obvious requests.
- The skill activates too broadly and hijacks unrelated tasks.
- The user has to name the skill explicitly every time.

Patch target:

- Frontmatter `description`
- Sometimes `agents/openai.yaml` `default_prompt`

Typical fix:

- Add specific request phrasings, file types, task names, and exclusions to the
  description.

## 2. Intake failure

Symptoms:

- The skill asks for too much information up front.
- The skill misses one blocking field and proceeds with weak assumptions.
- The same clarification is asked across multiple sessions.
- Evidence-light requests stall instead of using a default audit path.

Patch target:

- `SKILL.md` intake contract
- A reference file with defaults when needed

Typical fix:

- Define the minimum evidence needed to choose a mode or patch depth.
- State the exact missing artifact that justifies asking a question.

## 3. Workflow failure

Symptoms:

- The skill knows the task but chooses the wrong order.
- Setup, execution, and reporting are mixed together.
- Good steps exist but the preferred path is hard to discover.

Patch target:

- `SKILL.md`
- Possibly one workflow reference

Typical fix:

- Reorder the steps, collapse ambiguous branches, and make the preferred path
  explicit.

## 4. Scope failure

Symptoms:

- The skill promises tasks it should redirect away from.
- It depends on tools or environments that are not available.
- The default tool, editor, or medium no longer matches the real job.
- Old branches or references for abandoned use cases still remain and confuse
  the main workflow.

Patch target:

- Frontmatter `description`
- `SKILL.md` scope and caveats
- Obsolete references or helper guides

Typical fix:

- Narrow the promise, add redirect rules, and prune dead branches or stale
  references.
- If the job stays the same but the medium changes, retarget the skill and
  demote the old medium to fallback interoperability only.

## 5. Reference failure

Symptoms:

- Domain detail keeps reappearing in `SKILL.md`.
- Codex needs a large block of specialized knowledge only for one branch.
- The same table, schema, or command matrix is copied between skills.

Patch target:

- `references/`

Typical fix:

- Move detailed material into a reference file and link it from the relevant
  step.
- Delete references that only served abandoned branches.

## 6. Determinism failure

Symptoms:

- The same helper code gets rewritten every time.
- Repeated manual steps are error-prone.
- Minor audits or format checks take too long by hand.

Patch target:

- `scripts/`

Typical fix:

- Add a local script that produces deterministic output and is easy to test.

## 7. Output failure

Symptoms:

- The final answer shape varies too much.
- The skill omits critical assumptions or follow-up checks.
- The user receives commands but not the expected deliverable shape.

Patch target:

- `SKILL.md` output contract
- Output template reference when needed

Typical fix:

- State the required sections, assumptions, deliverables, and verification
  checklist.

## 8. Validation failure

Symptoms:

- Stale placeholders or broken links survive multiple revisions.
- UI metadata drifts from the skill body.
- The audit path creates false confidence because it checks only structure.

Patch target:

- `scripts/`
- Release checklist
- Mode test prompts

Typical fix:

- Keep structural validation fast, but pair it with one realistic behavioral
  prompt.

## 9. Environment boundary failure

Symptoms:

- The skill implies local execution for HPC-only workloads.
- It reports runtime results that cannot exist in the current environment.
- It forgets to separate local design from remote execution.

Patch target:

- `SKILL.md`
- Relevant references

Typical fix:

- Make the boundary explicit and add a remote-only verification checklist where
  needed.
