# Source Selection

Select the smallest note set that can support a coherent draft.

## Priority order

1. concept notes that already contain definitions or mechanisms
2. project notes that explain why the idea matters in practice
3. literature notes that anchor terminology or claims
4. daily or meeting notes only when they contain unique decisions

## Good seed notes

Good seeds usually have one of these properties:

- they define the main object or equation
- they capture a research question or confusion clearly
- they link theory to an active project

## Expansion rules

Expand outward from a seed note by:

- title similarity
- shared `projects`
- shared tags
- explicit wiki links
- nearby reference notes

Stop expanding when:

- multiple notes restate the same point
- the central thesis starts drifting
- the draft would need two unrelated introductions

## Bundle size guidance

- small explanatory draft: `3-6` notes
- broader technical explainer: `6-12` notes
- above `12` notes: use `scripts/build_source_bundle.py` and trim aggressively

## Exclusion rules

Exclude notes that are:

- pure TODOs without technical substance
- stale branches contradicted by later notes
- low-signal meeting chatter with no durable insight
- experiments whose results were never interpreted

## Theory plus project mix

When theory and project notes coexist:

- let theory supply the definitions and formal structure
- let project notes supply the practical stakes
- do not let implementation trivia dominate the narrative unless the draft is
  explicitly about debugging or design choices
