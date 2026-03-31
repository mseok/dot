---
name: recent-notes-research-questions
description: Mine recent Obsidian notes for creative, testable research questions by reading a compact cluster of recently updated notes, extracting tensions and transfer opportunities, and synthesizing ranked ideas grounded in the user's own note history. Use when the user wants idea generation, research questions, experiment concepts, thesis directions, or cross-note synthesis from their latest notes rather than generic brainstorming.
---

# Recent Notes Research Questions

## Overview

Turn recent note activity into research questions that are grounded in the
user's actual work. Read a small bundle of recent notes, extract recurring
motifs and unresolved tensions, then propose questions that are novel enough to
matter and concrete enough to test.

## Default Assumptions

- Treat "recent" as `7-21` days or roughly `8-20` recently modified Markdown
  notes unless the user specifies a tighter scope.
- Read note summaries, frontmatter, and top-level sections first. Drill deeper
  only when a note becomes central to an idea.
- Prefer concept, project, and experiment notes over templates or generated
  drafts.
- Include lecture, literature, or reference notes only when they create a
  useful bridge into an active research thread.
- Save nothing unless the user asks for a note.

## Workflow

### 1. Set the note window

- If the user names seed notes, a project, or a folder, center the search there.
- Otherwise gather recent Markdown notes from the vault while excluding obvious
  noise such as `.obsidian`, `Attachments`, `Templates`, and other non-note
  regions unless the user explicitly wants them.
- Use `scripts/list_recent_notes.py` when the vault is large or when you need a
  deterministic candidate list before reading.

### 2. Build a compact note packet

For each selected note, extract only the information needed to reason:

- note title and relative path
- frontmatter fields such as `projects`, `categories`, `tags`, and `related`
- summary-like sections such as `## Summary`, `## Key sentence`, `## Goals`,
  `## Failure modes`, `## Open questions`, or their Korean equivalents
- the main technical object: model, estimator, mechanism, dataset, or workflow
- claims, assumptions, bottlenecks, and "what would have to be true" statements

Avoid reading the entire vault by default. Keep the packet narrow enough that a
cross-note synthesis is still coherent.

### 3. Extract idea sources before proposing questions

Look for question-worthy structure, not just interesting nouns.

Primary lenses:

- repeated failure modes
- approximation gaps
- train-objective versus downstream-goal mismatch
- metric or evaluation blind spots
- assumptions that appear in one note but are violated in another
- methods in one note that could transfer to another
- quantities the notes care about but do not actually estimate
- different abstractions of the same problem that have not been unified

When the notes are technical or fragmented, read
[references/idea-lenses.md](references/idea-lenses.md) and use those lenses
explicitly.

### 4. Convert synthesis into research questions

Produce `3-7` candidate questions. For each one, include:

- a concise question title
- the question itself in one sentence
- why it emerges from these recent notes
- a falsifiable hypothesis, design intuition, or expected mechanism
- the smallest next check that would clarify whether the idea is real
- the key risk or failure mode
- the type of novelty: mechanism, method, evaluation, transfer, or framing

Prefer questions that are actionable in the user's real workflow. Do not fall
back to generic templates like "Can we improve X with Y?" unless the notes truly
support that jump.

### 5. Rank and present

Rank the questions by:

- novelty relative to the recent notes
- feasibility within the user's current tooling and projects
- clarity of the next discriminating check
- expected scientific value if the idea works

Mark each question as:

- `near-term`
- `mid-term`
- `speculative`

### 6. Save only if asked

If the user asks to save the output into the vault, create a standalone note
with:

- a clear title
- frontmatter suitable for the vault
- `projects` links when the questions clearly belong to an active project
- explicit provenance listing the source notes

## Output Contract

Unless the user asks for a different shape, return:

1. the note window you used
2. the source notes actually read
3. a short cross-note synthesis
4. `3-7` ranked research questions
5. one recommended next note or experiment-design memo to write next

Use this question template:

```markdown
### RQ1. [Short title] (`near-term` | `mid-term` | `speculative`)

**Question:** [One-sentence research question]
**Why this appears now:** [Tie directly to recent notes]
**Hypothesis / mechanism:** [What might be true]
**Smallest next check:** [Minimal analysis, derivation, or experiment design]
**Main risk:** [Why this may fail]
**Novelty type:** mechanism | method | evaluation | transfer | framing
```

## Quality Bar

Before finishing, confirm that:

- every question is tied to specific notes, not generic background knowledge
- at least one question comes from a cross-note bridge rather than a single note
- at least one question targets a failure mode or blind spot
- supported observations and speculative leaps are clearly separated
- the output is narrower and sharper than a generic brainstorming dump

## Resources

- `scripts/list_recent_notes.py`: build a deterministic recent-note candidate
  list with metadata, headings, and summary snippets
- [references/idea-lenses.md](references/idea-lenses.md): lenses for turning
  recent technical notes into creative but grounded research questions
