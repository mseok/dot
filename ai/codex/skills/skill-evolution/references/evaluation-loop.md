# Evaluation Loop

Use this guide when the user asks for:

- a numeric score
- a target threshold such as `>=9`
- separate implementation and evaluation agents
- repeated revision until the score clears a gate

## Role split

- `implementation agent`: defines the rubric, states the target threshold,
  patches the skill, and reports its own score as provisional only
- `evaluation agent`: scores independently from the rubric and target threshold
  without relying on the implementation agent's score or preferred fix

If the rubric changes materially, reset the loop and rescore from the current
revision.

## Required loop

1. The implementation agent defines a 10-point rubric with category weights and
   pass expectations.
2. The evaluation agent scores the current revision against that rubric.
3. If the independent evaluation score is below the requested threshold, the
   implementation agent applies the smallest patch that should raise the score.
4. Rerun structural validators.
5. The evaluation agent scores the revised skill against the same rubric.
6. Repeat until the evaluator reaches the threshold or states a blocker.

## Default score gate harness

When the default harness is used:

- `references/score-gate-case-pack.json` is the canonical machine-readable case
  pack
- `references/score-gate-report.example.json` is the evaluator report schema
- `python3 scripts/score_gate.py references/score-gate-case-pack.json <evaluator-report.json>`
  is the deterministic local gate
- the case pack sets the default threshold, but the evaluator report may raise
  it when the user explicitly asks for a stricter gate such as `10.0/10`

The evaluator report should be machine-readable and should not rely on prose
interpretation to decide whether the threshold was met.

## Guardrails

- Do not let the evaluation agent reuse the implementation agent's score as its
  own score.
- Structural validation never substitutes for the independent evaluation score.
- The default score gate is passed only when `scripts/score_gate.py` accepts the
  case pack and evaluator report.
- The implementation agent may explain the rubric, but not the desired
  evaluation outcome.
- If the user asked for separate roles, keep the evaluator read-only.

## Closeout

Always report:

- the rubric and threshold
- the implementation score
- the independent evaluation score
- whether the loop cleared the threshold
- the smallest remaining blocker if the loop stopped below threshold
