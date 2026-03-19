# Failure Taxonomy

Use this taxonomy to convert vague "the skill feels weak" feedback into a concrete patch target.

## 1. Trigger failure

Symptoms:

- The skill does not activate for obvious requests.
- The skill activates too broadly and hijacks unrelated tasks.
- The user has to name the skill explicitly every time.

Patch target:

- Frontmatter `description`
- Sometimes `agents/openai.yaml` `default_prompt`

Typical fix:

- Add specific request phrasings, file types, task names, and exclusions to the description.

## 2. Intake failure

Symptoms:

- The skill asks for too much information up front.
- The skill misses one blocking field and proceeds with weak assumptions.
- The same clarification is asked across multiple sessions.

Patch target:

- `SKILL.md` intake contract
- Supporting reference with defaults

Typical fix:

- Define a minimal contract, defaults, and the exact missing fields that justify a question.

## 3. Workflow failure

Symptoms:

- The skill knows the task but chooses the wrong order.
- It mixes setup, execution, and reporting in a confusing way.
- Good steps exist, but they are hard to discover from the quick start.

Patch target:

- `SKILL.md`
- Possibly a workflow reference

Typical fix:

- Reorder the steps, collapse branches, and make the preferred path explicit.

## 4. Scope failure

Symptoms:

- The skill claims to handle tasks it should redirect.
- It tries to combine prediction, benchmarking, training, and ops in one path.
- It makes promises that depend on unavailable tools or environments.

Patch target:

- Frontmatter `description`
- `SKILL.md` scope or caveats

Typical fix:

- Narrow the promises and add clear redirect rules for out-of-scope requests.

## 5. Reference failure

Symptoms:

- Domain detail keeps reappearing in `SKILL.md`.
- Codex needs a large block of specialized knowledge only for one branch.
- The same table, schema, or command matrix is copied between skills.

Patch target:

- `references/`

Typical fix:

- Move detailed material into a reference file and link it from the relevant step.

## 6. Determinism failure

Symptoms:

- The same helper code gets rewritten every time.
- Repeated manual steps are error-prone.
- Minor format checks or audits take too long to do by hand.

Patch target:

- `scripts/`

Typical fix:

- Add a local script that produces deterministic output and is easy to test.

## 7. Output failure

Symptoms:

- The final answer shape varies too much.
- The skill omits critical assumptions or follow-up checks.
- The user receives commands but not the expected artifacts or memo shape.

Patch target:

- `SKILL.md` output contract
- Output template reference

Typical fix:

- State the required sections, assumptions, deliverables, and verification checklist.

## 8. Validation failure

Symptoms:

- Stale placeholders or broken links survive multiple revisions.
- UI metadata drifts from the skill body.
- The skill looks fine on inspection but fails basic hygiene checks.

Patch target:

- `scripts/`
- Release checklist

Typical fix:

- Add a fast audit script and run it together with `quick_validate.py`.

## 9. Environment boundary failure

Symptoms:

- The skill implies local execution for HPC-only workloads.
- It reports runtime results that cannot exist in the current environment.
- It forgets to separate local design from remote execution.

Patch target:

- `SKILL.md`
- Relevant references

Typical fix:

- Make the boundary explicit and add a remote-only verification checklist where needed.
