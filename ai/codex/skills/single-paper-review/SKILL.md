---
name: single-paper-review
description: Create a detailed single-paper summary note in Markdown (Obsidian-friendly). Use when asked for "paper review" meaning "논문 정리/요약", single-paper deep summary, or when the user wants method and results written with metric definitions (math + interpretation) and reusable figures/tables embedded from Attachments/.
---

# Single Paper Review

Produce a single-paper note that is:
- Obsidian-friendly Markdown (YAML frontmatter + headings)
- Method/result focused (not reviewer-style acceptance/rejection)
- Metric-literate (each metric defined mathematically + interpreted)
- Reusable (key figures/tables embedded as Attachments so they can be referenced from other notes)

## Use the bundled template
- Preferred template: `assets/review_template.md`
- If the vault already contains `Templates/Single Paper Review Template.md`, it is OK to use that instead (keep the structure identical).

## Workflow
1. Identify the target note path
   - If the user provides a target `.md` file, update that file.
   - Otherwise create a new note named after the paper title (short, descriptive, ASCII).

2. Fill frontmatter minimally but correctly
   - `author`, `venue`, `year`, `url` (and `doi/arxiv/code` if available)
   - Keep `categories: [[Papers]]` unless user requests otherwise.

3. Summarize the paper (single-paper "review" = 정리)
   - TL;DR: 2-5 sentences focused on the mechanism and the headline result.
   - Contributions: 3-5 bullet points, phrased as claims (what changed vs prior work).
   - Problem setup: clearly state task, inputs/outputs, assumptions, and what breaks without the method.

4. Write the method with enough detail to re-implement
   - Start with a high-level pipeline, then expand into key components.
   - Include notation (shapes and symbols) where it reduces ambiguity.
   - If the paper includes an algorithm box, rewrite it as concise pseudo-steps (do not copy verbatim).

5. Add a "Metrics (math + meaning)" section (mandatory)
   For every metric used in Methods/Results:
   - Provide a mathematical definition in LaTeX (use `$$ ... $$`).
   - Specify how the paper computes it (averaging, thresholds, matching rules, postprocessing).
   - Interpret what it means:
     - What higher/lower implies about behavior
     - What it is sensitive to (imbalance, calibration, scale, label noise, etc.)
     - Common failure modes / when the metric can mislead

6. Summarize experiments with "figure/table anchors"
   - State each important claim in plain language.
   - Support it by referencing the exact paper table/figure number and the reported numbers (absolute + delta).
   - Prefer "what matters" over exhaustive enumeration.

7. Make results reusable (figures/tables)
   - Create an attachment folder: `Attachments/<paper-slug>/`
   - For each key result figure/table:
     - Save a cropped image (PNG preferred) into the attachment folder.
     - Embed it in the note under "Figures and tables (reusable)" with:
       - Source: Figure/Table number + page
       - Why it matters: what conclusion it supports
       - How to read: axes/legend/what to focus on
   - Tables:
     - If simple: transcribe to Markdown table for copy/paste reuse.
     - If complex: embed the table image and optionally add a short "takeaway row" list below it.

## Constraints
- Do NOT add steps about generating PDFs of the note.
- Do NOT add steps about creating new schematic/diagram figures.
- Keep text ASCII (use " not curly quotes).
