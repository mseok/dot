---
name: toy-experiment-note-normalizer
description: Turn rough experiment bullets or partial lab notes into a decision-complete Obsidian experiment note with fixed frontmatter and sections. Use when the user wants one experiment note rewritten into this vault's structured experiment format without inventing results. Do not use for meeting notes, paper summaries, daily notes, or general prose polishing.
---

# Toy Experiment Note Normalizer

Use this skill to normalize one rough experiment note into a structured Obsidian experiment note.

## Scope

- Use only when the target artifact is a single experiment note.
- Do not use for meeting notes, literature reviews, daily notes, or general note cleanup.
- Preserve local and HPC boundaries. If the source notes describe planned runs or missing results, keep them as expectations or checks. Do not imply execution happened.

## Minimum input

- A project name that can be written as `[[Project Name]]`
- Enough source material to state:
  - what changed
  - expected outcome
  - metrics to inspect
  - next action

If the project name is missing or ambiguous, ask exactly one question to resolve it before drafting. If the rest of the note is sparse but the job is still clearly an experiment note, proceed and mark missing facts as `Unknown from source notes`.

## Workflow

1. Confirm this is an experiment-note request, not a meeting, paper, or general-polish request.
2. Identify or ask for the project name.
3. Extract the four required decisions from the source notes:
   - what changed
   - expected outcome
   - metrics to inspect
   - next action
4. Draft the note with the fixed schema below.
5. Keep statements factual. Use planned or expected language unless the source notes explicitly contain results.
6. When revising or benchmarking this skill, read [references/benchmark-cases.md](references/benchmark-cases.md).

## Output contract

Return a single Markdown note in this shape:

```markdown
---
projects:
- [[PROJECT_NAME]]
categories:
- [[Experiments]]
---

# <Concise experiment title>

## What changed
...

## Expected outcome
...

## Metrics
...

## Next action
...
```

Rules:

- Keep the four section names exact.
- Do not add sections unless the user explicitly asks.
- Do not invent metric values or runtime outcomes.
- If a required fact is missing, write `Unknown from source notes` in the relevant line rather than guessing.
