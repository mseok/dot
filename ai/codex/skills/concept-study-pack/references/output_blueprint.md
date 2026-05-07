# Output Blueprint

Use this reference when designing or auditing a comprehensive standalone study pack.

## Artifact Roles

| Artifact | Role | Required Qualities |
|---|---|---|
| `00_beginner_route.md` | A concrete study route | Time budget, sequence, stuck-recovery table, minimum success criteria |
| `00_index.md` | Canonical map | Dependency graph, file purposes, recommended entry points |
| Prerequisite notes | Remove hidden assumptions | Definitions, small examples, why each tool is needed later |
| Main concept notes | Teach the concept deeply | Intuition, formal derivation, micro-examples, edge cases, self-checks |
| Source/paper note | Preserve factual accuracy | Version/date, method, results, limitations, citations, stale-claim cleanup |
| `worked_solutions.md` | Recovery from failed exercises | Step-by-step core derivations, template solutions, answer/checklist mappings |
| `self_check_answer_key.md` | Fast self-grading | Short answer for every self-check, FAQ check, and final checklist item; detectable by answer coverage validation |
| Applied worksheets | Transfer to real work | Inputs, outputs, latent variables, assumptions, diagnostics, failure modes, short design answer; detectable by worksheet validation |
| `visual_index.md` | Figure map | Figure filename, concept, note links, when to revisit |
| `assets/figures/` | Offline visual memory | Local renderable images, stable filenames, no remote dependency |
| `scripts/generate_figures.py` | Reproducible figures | Deterministic enough for regeneration, clear output path |
| `offline_index.html` | Browser launch page | Inline CSS, local relative links/images, no network dependency, passes multi-HTML hygiene checks |
| `offline_reader.html` | Browser-readable compiled route | Single local HTML reader, local images, no CDN, no external scripts, validated with `--offline-reader` |
| `scripts/build_offline_reader.sh` | Reproducible reader build | Local renderer such as Pandoc, deterministic output, no remote assets, validated with `--reader-build-script` or `--require-reader-build-script` |

## Language Contract

Default to Korean-English bilingual learner scaffolding for this user's study packs:

- Keep canonical terms, formulas, variable names, paper/source names, and code/API names in English.
- Add Korean explanations beside key intuitions, stuck-recovery rules, figure prompts, answer-key guidance, worksheet prompts, and final success criteria.
- Do not translate every paragraph twice by default; use bilingual support where it reduces self-study friction.
- If the user explicitly requests a single language or a fully bilingual reader, follow that request and state the choice in the learner contract.

## Beginner Depth Rubric

A section is too sparse if it:
- names an object before saying what it measures or transforms;
- jumps from an integral/sum/differential equation to the final formula without intermediate algebra;
- uses a sign convention without a physical or geometric example;
- has no tiny example that can be checked by hand;
- asks an exercise whose method is not shown somewhere in the pack.

A section is sufficiently standalone if the learner can answer:
- What are the inputs and outputs?
- What does each side of the main equation count?
- What changes if the sign, boundary condition, or scale changes?
- Which prerequisite note repairs confusion?
- Which worked solution has the same pattern?
- Where is the exact short answer for the local self-check?
- Where is the Korean-English recovery explanation if the English formula text is not enough?

## Figure Selection Rubric

Prefer 5-10 reusable figures over many one-off diagrams. Prioritize:
- conservation/control-volume signs;
- gradient/divergence/Laplacian geometry;
- smoothing or diffusion over time;
- basis decomposition and mode decay;
- frequency ordering or band structure;
- probability density/current/drift-diffusion pictures;
- algorithm or workflow diagrams for paper methods.

Every figure must be linked from `visual_index.md` and from at least one explanatory note.

## Applied Worksheet Rubric

Add a worksheet when the concept is meant to transfer into research or code design. A useful worksheet forces the learner to fill in:

- observed inputs and outputs;
- latent variables or unknown quantities;
- parameters and assumptions;
- posterior, responsibility, objective, or diagnostic object;
- a failure mode that the method does not automatically prevent;
- one domain-relevant check that would reveal the failure.

## Source Accuracy Rubric

For papers or current technical claims:
- verify latest version from primary sources;
- separate official facts from interpretation;
- mark pedagogical formulas as pedagogical when the source does not state them exactly;
- remove stale version strings, old result numbers, and older method descriptions;
- keep concise citations or source links in the relevant note.

## Final QA Checklist

Run or perform equivalent checks:
- required files exist;
- all local Markdown/HTML links resolve;
- all image references resolve;
- offline launch page, reader, and any other top-level HTML files have no external `src`/`href`, CDN, remote font, import, analytics, or script dependencies;
- local Markdown/HTML `#fragment` links resolve to headings or HTML `id`/`name` anchors;
- stale terms or old numbers do not appear;
- generated figures exist and are referenced;
- reader build script runs if a compiled reader exists;
- every self-check maps to an answer-key section or worked solution;
- beginner route recovery links point to FAQ, solution, prerequisite, visual notes, answer key, or worksheet.
- Korean-English scaffolding exists for the learner route, stuck-recovery path, figure recovery prompts, self-check answers, applied worksheets, and success criteria unless the user chose a different language contract.

Use the validator flags that match the pack contract:

```bash
python3 /Users/mseok/dot/ai/codex/skills/concept-study-pack/scripts/validate_pack.py PATH_TO_PACK \
  --required-file 00_beginner_route.md \
  --required-file offline_index.html \
  --offline-reader offline_reader.html \
  --reader-build-script scripts/build_offline_reader.sh \
  --expect-worksheet \
  --require-answer-coverage \
  --answer-doc self_check_answer_key.md \
  --answer-doc worked_solutions.md \
  --check-all-html \
  --check-anchors
```

For custom names, replace `--expect-worksheet` with one or more `--worksheet-file` entries and repeat `--answer-doc` for each answer-key or worked-solution file.
Use `--require-reader-build-script` when the default `scripts/build_offline_reader.sh` path is part of the pack contract.
