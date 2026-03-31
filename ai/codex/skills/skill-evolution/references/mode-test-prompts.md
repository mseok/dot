# Mode Test Prompts

Use one of these prompts after revising the skill.

## `diagnose-only`

`Use $skill-evolution to review this skill and tell me what to change, but do not patch it.`

## `patch-narrow`

`Use $skill-evolution to tighten this skill's trigger wording and output contract.`

## `patch-deep`

`Use $skill-evolution to deeply repair this skill; its workflow, references, UI metadata, and validation path drifted apart after several revisions.`

## `retarget`

`Use $skill-evolution to retarget this skill from one primary editor to another without creating a new skill.`

## `implementer-rubric`

`Use $skill-evolution as the implementation agent. Define a 10-point rubric for this skill, propose the smallest patch plan, and do not score as the independent evaluator.`

## `evaluator-score`

`Use $skill-evolution as the evaluation agent. Score this skill independently against the provided rubric, give category scores, and do not suggest implementation details beyond blocker rationale.`

## `loop-until-threshold`

`Use $skill-evolution with separate implementation and evaluation agents. The implementation agent defines the rubric and patch plan, the evaluation agent scores independently, and the loop continues until the evaluator gives >=9/10 or states a blocker.`
