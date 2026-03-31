# Benchmark Cases

Use these cases when revising this skill or when using `skill-evolution` to improve it.

Each case includes:

- whether the skill should trigger
- what the skill must do
- what the skill must not do

## Case 1: Positive / direct experiment rewrite

Prompt:

`Turn these rough notes into an experiment note for [[Docking-Reranker]]: changed ligand encoder from 128d to 256d, expect better top-20 enrichment, inspect validation AUC and early retrieval, next run seed sweep.`

Expected behavior:

- Trigger the skill.
- Return the fixed frontmatter and four required sections.

Forbidden behavior:

- Adding extra sections.
- Inventing observed AUC values.

## Case 2: Positive / sparse but usable

Prompt:

`Rewrite this into a structured experiment note for [[Cofolding-Adapter]]: swapped pair-bias block, expected stabler interface geometry, metrics are interface RMSD and clash count, next action is two-seed sanity check.`

Expected behavior:

- Trigger the skill.
- Keep the note concise and decision-complete.

Forbidden behavior:

- Turning the note into a meeting summary.
- Adding execution claims.

## Case 3: Missing project name

Prompt:

`Make this a clean experiment note: changed sampler temperature schedule, expect more diverse linker proposals, inspect validity and novelty, next run compare against baseline.`

Expected behavior:

- Ask exactly one question to resolve the missing project name.
- Do not draft the final note before that answer.

Forbidden behavior:

- Asking multiple clarification questions.
- Guessing a project name.

## Case 4: Anti-trigger / general prose polish

Prompt:

`Polish this note and make the writing cleaner, but keep the same structure.`

Expected behavior:

- Do not trigger this skill.

Forbidden behavior:

- Forcing the fixed experiment-note schema onto a general polishing request.

## Case 5: Anti-trigger / meeting note

Prompt:

`Rewrite these meeting notes into a clearer summary. We discussed docking ablations, deadlines, and who will run which jobs.`

Expected behavior:

- Do not trigger this skill.

Forbidden behavior:

- Recasting the meeting note as an experiment note.

## Case 6: Anti-trigger / paper summary

Prompt:

`Summarize this paper note into Korean and pull out the main method.`

Expected behavior:

- Do not trigger this skill.

Forbidden behavior:

- Producing the experiment-note template.

## Case 7: Environment boundary

Prompt:

`Turn this into an experiment note for [[Docking-Reranker]]: have not run HPC jobs yet, changed score head depth from 2 to 4, expect better pose ranking, inspect top-1 success and calibration, next action launch ablation tomorrow.`

Expected behavior:

- Trigger the skill.
- Use planned or expected language.

Forbidden behavior:

- Claiming that runs already finished.
- Inventing metrics or plots.

## Case 8: Ambiguous project

Prompt:

`Rewrite this experiment draft: changed pocket encoder dropout, expected better generalization, inspect val loss and enrichment, next step rerun on the same split. This might belong to Docking-Reranker or Pocket-Pretrain.`

Expected behavior:

- Ask exactly one question to disambiguate the project.

Forbidden behavior:

- Picking one project without asking.
