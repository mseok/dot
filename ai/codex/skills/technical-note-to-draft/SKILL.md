---
name: technical-note-to-draft
description: Turn an Obsidian note cluster, literature notes, and project notes into an internal long-form technical draft inside the vault. Use when the user asks for a technical blog-style draft, study post, explainer, or structured narrative from existing notes without requiring publication-ready formatting or external publishing output.
---

# Technical Note To Draft

## Overview

Create an internal technical draft from existing Obsidian notes.
The goal is not to publish directly, but to turn scattered notes into a clear
thesis, roadmap, evidence-backed argument, and follow-up questions.

## Quick Start

1. Identify the draft mode:
   - `study`: organize understanding for later writing
   - `promotion`: explain one idea clearly for external communication later
   - `hybrid`: study deeply while shaping a blog-style narrative
2. Pick `1-3` seed notes that define the topic.
3. Build a source bundle from nearby notes and references.
4. Freeze the draft thesis in one sentence before writing sections.
5. Write the draft in Obsidian-friendly Markdown as a self-contained note and
   keep unsupported claims visibly marked.

## Intake Rules

Ask only when one missing input would materially change the draft.
Otherwise, make a narrow default assumption and proceed.

Default assumptions:

- Store intermediate artifacts under `copilot/`.
- Treat the output as an internal vault draft, not publish-ready Markdown.
- Prefer a concept-style draft unless the source notes clearly indicate an
  experiment recap or meeting synthesis.
- Use English by default when the source notes and target blog style are
  English-heavy; otherwise match the dominant language of the source notes.
- Keep the main narrative self-contained so later blog export does not depend on
  live Obsidian links.

Minimum required inputs:

- at least one seed note, topic name, or project name

Helpful but optional inputs:

- target audience
- desired emphasis such as theory, intuition, methods, or project relevance
- notes to exclude

## Workflow

### 1. Inspect the source region

Start from the user-provided seed notes or topic.

- Search the vault for notes with matching titles, project links, and keywords.
- Prefer concept notes, literature notes, and project notes over daily logs,
  unless the daily notes contain unique decisions.
- Keep the bundle small enough that the central argument stays coherent.

Use `scripts/build_source_bundle.py` when the relevant notes are numerous or
distributed across folders.
Read [references/source-selection.md](references/source-selection.md) when the
topic spans both theory and project notes.

### 2. Build a source map before drafting

Create a compact source map with these fields:

- thesis candidates
- core claims
- supporting evidence
- equations or definitions worth preserving
- examples or applications
- unresolved gaps

Do not start prose until the source map is stable enough to support a section
plan.

Use [assets/templates/source-map.md](assets/templates/source-map.md) as the
default structure.

### 3. Freeze the narrative shape

Adopt the reference blog pattern as a structure, not as imitation of surface
style.

Default section flow:

1. thesis-first introduction
2. why the topic matters
3. roadmap for the reader
4. core sections that move from setup to mechanism to application
5. open questions or next reading

Read [references/style-pattern.md](references/style-pattern.md) for the target
shape and [references/outline-contract.md](references/outline-contract.md) for
the required outline fields.

### 4. Write only evidence-backed prose

Every nontrivial claim should map to a source note, reference note, or clearly
labeled interpretation.

Separate statement strength:

- `solid`: directly supported by a note or cited reference
- `partial`: supported but still compressed or inferred
- `speculative`: useful bridge or interpretation that needs later checking

When the draft includes a claim ledger, verify it with
`scripts/check_claim_ledger.py`.
When self-contained exportability matters, verify that the main body does not
depend on wiki links with `scripts/check_self_contained_draft.py`.

### 5. Save the draft inside the vault

Create the draft as an Obsidian note, usually under `copilot/` while the draft
is still evolving.

Draft note expectations:

- include frontmatter suitable for the vault
- keep provenance links vault-relative
- do not insert absolute filesystem paths into the main narrative
- include a source-notes section and open-questions section
- do not rely on wiki links in the main body to carry definitions, derivations,
  or context required for understanding the draft
- if a concept from another note is essential, restate the needed content inside
  the draft and keep the link only as provenance when useful

Use [assets/templates/draft.md](assets/templates/draft.md) for the final note
shape.

## Writing Rules

- Optimize for a strong explanatory arc, not maximal coverage.
- Prefer full paragraphs over bullet dumps in the main draft.
- Keep equations and notation only when they help the argument move forward.
- Add signposts for readers crossing domains, for example from molecular
  modeling to generative modeling.
- Distinguish definitions, intuition, and implications.
- Do not present local writing-time synthesis as experimental validation.
- When the available notes are weak, produce a narrower draft rather than
  fabricating connective tissue.
- Do not use `[[...]]` links in the main narrative as placeholders for missing
  explanation.
- Keep essential context inside one note so the draft remains understandable
  after export or copy-paste outside Obsidian.

## Output Contract

Unless the user asks for a different shape, produce these artifacts in order:

1. one-sentence thesis
2. intended reader
3. source notes used
4. claim ledger
5. section outline
6. internal draft body
7. open questions
8. next notes to review

## Resources

- [references/style-pattern.md](references/style-pattern.md): reference blog
  structure and stylistic constraints
- [references/source-selection.md](references/source-selection.md): how to pick
  and trim the note bundle
- [references/outline-contract.md](references/outline-contract.md): required
  outline and draft sections
- [assets/templates/source-map.md](assets/templates/source-map.md): source map
  scaffold
- [assets/templates/outline.md](assets/templates/outline.md): section planning
  scaffold
- [assets/templates/draft.md](assets/templates/draft.md): Obsidian draft note
  scaffold
- `scripts/build_source_bundle.py`: gather note metadata and headings into a
  compact draft packet
- `scripts/check_claim_ledger.py`: validate claim-to-source structure in a draft
- `scripts/check_self_contained_draft.py`: flag wiki links that leak into the
  main narrative outside provenance sections

## Verification Checklist

Before finishing:

- confirm the thesis is narrower than the full note bundle
- confirm each major section has at least one identifiable source
- confirm speculative bridges are labeled explicitly
- confirm the draft remains an internal note, not a fake publication page
- confirm the note uses vault-relative links only for provenance or optional
  navigation
- confirm the main narrative stays understandable even if all wiki links are
  stripped
