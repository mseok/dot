---
name: concept-study-pack
description: Build or upgrade comprehensive, standalone, offline-ready study packs for a specific concept, paper, math topic, or research method. Use when the user asks to study something broadly and deeply, create a flight/offline study pack, make beginner-friendly Korean-English bilingual materials from sparse prior knowledge, add prerequisite ladders, worked solutions, self-check answer keys, applied worksheets, visual explanations, local figures, an offline HTML launch page, or a browser-readable offline reader.
---

# Concept Study Pack

## Purpose

Create a self-contained learning pack that lets the user study a concept without internet access. Optimize for a learner who may only know the concept names and may lack basic math prerequisites.

## Core Workflow

1. **Fix the learner contract.**
   State the assumed level, target depth, available time, offline constraint, and language contract. If the user gives a path, inspect existing files first. If the target depends on a paper, standard, software API, or current result, verify against primary/current sources before editing.

   Default language contract for this user: keep canonical technical terms, formulas, variable names, and paper/source names in English, but provide Korean-English bilingual support for learner-facing scaffolding. At minimum, bilingualize route instructions, stuck-recovery notes, key intuitions, self-check prompts or answer keys, applied worksheet prompts, figure captions or visual-index recovery prompts, and final success criteria. Do not duplicate every paragraph in both languages unless the user explicitly asks for a fully bilingual text.

2. **Build a prerequisite ladder before the main concept.**
   Teach the smallest required objects first: notation, units, variables, geometry, algebra/calculus identities, probability meanings, and one tiny numeric or symbolic example per new operation.

3. **Split the pack into navigable artifacts.**
   Prefer this default shape unless the existing project has a better convention:
   - `00_beginner_route.md`: study order, time budget, stuck-recovery rules, minimum success criteria.
   - `00_index.md` or equivalent: canonical table of contents and dependency map.
   - Core concept notes: one note per conceptual layer, from intuition to formalism to application.
   - Paper/source note, if relevant: current factual summary, method, results, caveats, and citations.
   - `worked_solutions.md` or numbered equivalent: full solutions for must-solve derivations plus template solutions for repeated patterns.
   - `self_check_answer_key.md` or numbered equivalent: short answers for every self-check, FAQ check, and end-of-route checklist item.
   - Applied worksheet note, when useful: domain-specific practice that forces the learner to name inputs, outputs, latent variables, assumptions, diagnostics, and failure modes.
   - `visual_index.md`: every local figure, what it explains, and where to revisit it.
   - `assets/figures/`: local PNGs or SVGs needed for offline study.
   - `scripts/generate_figures.py` or equivalent: regenerate figures deterministically when practical.
   - `offline_index.html`: local launch page with relative links and local images only.
   - `offline_reader.html` plus `scripts/build_offline_reader.sh`, when practical: a single browser-readable compiled route that does not require a Markdown renderer, CDN, remote fonts, analytics, or external scripts.

4. **Write for stalled learners.**
   For each major note, include:
   - "what this section is trying to compute/explain";
   - definitions before symbols are used;
   - one worked micro-example before abstract formulas;
   - Korean-English "if stuck, go here" links to prerequisite, FAQ, solution, or visual notes;
   - short self-check questions whose answers are mapped to an exact answer-key section and, for long derivations, to the relevant worked solution.

5. **Make solutions complete enough to recover from failure.**
   Do not merely give final answers for derivations. Keep short answers in the answer key, and keep full derivations in worked solutions. For each must-solve derivation, show the starting object, what each side counts, the sign convention, every algebraic step that a beginner would otherwise skip, and the final interpretation in words. For repeated exercises, use pattern templates with "covers these exercises" lists.

6. **Use visuals as conceptual infrastructure, not decoration.**
   Create figures for sign conventions, geometry, flow/current, smoothing, basis decomposition, frequency ordering, distributions, and any place where a formula hides a spatial picture. Store figures locally and reference each figure from at least one explanatory note plus the visual index.

7. **Create an offline HTML hub.**
   Keep it dependency-free: inline CSS, no CDN, no remote fonts, no analytics, no external scripts. The launch page should expose the route, table of contents, figures, quick recovery links, answer key, and applied worksheets. If the learner may not have a Markdown renderer, also generate a compiled `offline_reader.html` from the canonical Markdown route, for example with local Pandoc and MathML. Treat W3C XML namespace URLs in generated MathML as identifiers, not network dependencies, but use a hygiene check that catches real external `src`/`href`, scripts, fonts, imports, and CDN references.

8. **Patch existing packs from evidence.**
   When upgrading an existing pack, first audit the real artifact instead of assuming the structure is sufficient. Look specifically for:
   - an `offline_index.html` that is only a link hub when the user needs a browser-readable reader;
   - self-checks whose answers are only loosely referenced or missing;
   - English-only recovery, checklist, answer-key, or worksheet surfaces that should be Korean-English bilingual for this user;
   - math caveats that matter for correctness, such as support conditions, sign conventions, monotonicity guarantees, boundary cases, and approximation gaps;
   - domain-transfer sections that explain ideas but do not make the learner write variables, diagnostics, and failure modes.

## Multi-Agent Pattern

Use subagents only when the user explicitly authorizes multi-agent/delegation. Keep delegated work read-only unless assigning a narrow, disjoint write scope.

Good independent subagent tasks:
- **Source auditor**: verify latest paper/source version, core claims, numbers, and stale wording against primary sources.
- **Prerequisite auditor**: identify missing beginner assumptions and places where formulas jump too fast.
- **Exercise auditor**: inventory all exercises/self-checks and map them to worked solutions.
- **Visual coverage auditor**: propose a minimal set of reusable figures and where each should be linked.
- **Offline QA auditor**: inspect link/image coverage, external dependencies, stale terms, and compiled reader coverage when a reader exists.

The main agent owns integration, final style, file naming, link consistency, and validation. Do not let parallel agents rewrite overlapping files.

## Quality Bar

Use `references/output_blueprint.md` when planning or auditing a full pack. Minimum acceptable output:
- a beginner route that can be followed without asking "what next?";
- prerequisite explanations slow enough for non-math readers;
- complete worked solutions for the core derivations;
- exact short-answer coverage for every self-check and FAQ check;
- applied worksheets when the concept is meant to transfer into the user's research domain;
- Korean-English bilingual learner scaffolding for routes, recovery notes, key intuitions, visual captions/prompts, self-check answers, worksheets, and success criteria;
- local visuals with regeneration path;
- a no-network offline launch page, and a browser-readable offline reader when Markdown rendering cannot be assumed;
- source/version notes for factual or paper-specific material;
- validation commands and their outcomes.

## Validation

Run the bundled validator when the pack is file-based:

```bash
python3 "$HOME/dot/ai/codex/skills/concept-study-pack/scripts/validate_pack.py" PATH_TO_PACK \
  --required-file 00_beginner_route.md \
  --required-file offline_index.html \
  --check-all-html \
  --check-anchors
```

Also run any local figure-generation script, then check generated image files exist and are referenced. Add `--forbid` patterns for stale claims, old version strings, wrong numbers, or deprecated terminology.

When the pack includes a compiled reader, run the local build script before link validation, for example:

```bash
bash scripts/build_offline_reader.sh
```

Then validate the reader, worksheet surface, answer-key mapping, and every top-level HTML file with the relevant flags:

```bash
python3 "$HOME/dot/ai/codex/skills/concept-study-pack/scripts/validate_pack.py" PATH_TO_PACK \
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

Use `--worksheet-file FILE` instead of or in addition to `--expect-worksheet` when the worksheet has a custom name. Repeat `--offline-html FILE` for named HTML entry points, or use `--check-all-html` to check every top-level `.html`/`.htm` file. The validator catches real external `src`/`href`, script tags with `src`, imports, remote fonts, common CDN hosts, and analytics markers across those HTML files.

Use `--check-anchors` when recovery links, answer-key links, or reader links include `#fragment` anchors. Use `--require-reader-build-script` if the pack contract promises a compiled reader and should use the default `scripts/build_offline_reader.sh`.

If the user explicitly asks for a stricter "no http strings anywhere" check, make the reader build compatible with that check or clearly explain any false positives such as MathML namespace identifiers.

For answer coverage, the validator checks structure only: every `Self-check`, `FAQ self-check`, `Minimum success criteria`, or final checklist should have an exact answer-key section, an explicit answer/solution link, or a worked-solution mapping. Still manually spot-check semantic correctness for representative derivations and domain worksheets.

Before the final response, report:
- files added/changed;
- source/version basis if browsing or primary-source verification was used;
- validation commands run;
- anything not validated.
