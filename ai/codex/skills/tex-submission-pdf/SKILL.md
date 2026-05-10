---
name: tex-submission-pdf
description: Build polished TeX-based PDF reports for submission, collaborator sharing, manuscript-style memos, polished technical summaries, dataset/provenance reports, or any user request that asks for a clean PDF rather than a rough Markdown export. Use when the user mentions a submission/share PDF, asks for a better-looking PDF, wants tables/code/figures/statistics/plots laid out professionally, or asks that PDF work happen in /tmp with a TeX-based workflow.
---

# TeX Submission PDF

## Overview

Create submission-quality PDFs from a temporary TeX project under `/tmp`, then copy only final artifacts back to the requested destination. Prefer native LaTeX structure over Markdown-to-PDF conversion when layout quality matters.

## Core Workflow

1. Create a dedicated working directory under `/tmp`, for example `/tmp/tex-report-<slug>-<timestamp>`.
2. Keep source, generated figures, intermediate files, and build logs inside that `/tmp` directory.
3. Use TeX as the source of truth: write `main.tex` directly or scaffold it with `scripts/init_tex_report.py`.
4. Convert evidence into polished artifacts:
   - Use `booktabs`, `tabularx`, `siunitx`, and short captions for tables.
   - Use `tcolorbox` or `listings` for code/config/path blocks; avoid raw overflowing verbatim blocks.
   - Use TikZ, PGFPlots, or generated PDF/PNG plots for diagrams and statistics.
   - Include at least one helpful figure or plot when numeric summaries, proportions, counts, or pipeline stages are central.
5. Build with `latexmk -xelatex -interaction=nonstopmode -halt-on-error main.tex` unless the target project requires another engine.
6. Validate before delivery:
   - `pdfinfo <pdf>` for page count and metadata.
   - `pdftotext <pdf> - | head` for extractable text and obvious encoding issues.
   - Quick Look thumbnail or another visual preview for layout sanity.
   - Inspect build logs for fatal errors, missing assets, and serious overfull boxes.
7. Copy the final PDF, and optionally the TeX source zip or `.tex`, to the user-requested destination. Do not leave the vault as the build workspace.

## Layout Standards

Use a restrained academic/report style:

- Clear title, date, and purpose line.
- Executive summary first, then evidence, workflow, caveats, and action checklist.
- Prefer compact tables over long bullet lists when comparing contracts, paths, counts, or settings.
- Use diagrams for pipelines and join contracts instead of only prose.
- Use plots for counts/cutoffs/results when they improve scanability.
- Break long filesystem paths into base path + file list, or use wrapped `tcolorbox` blocks.
- Use short, source-grounded caveats. Do not hide unverified steps.

## TeX Defaults

Use these defaults unless the target repo already has a stronger style:

- Engine: XeLaTeX.
- Korean-capable main font on macOS: `Apple SD Gothic Neo`.
- Monospace font: `Menlo` or `JetBrains Mono`; avoid Korean text inside monospace blocks where possible.
- Packages: `geometry`, `fontspec`, `xeCJK`, `microtype`, `booktabs`, `tabularx`, `array`, `siunitx`, `xcolor`, `hyperref`, `graphicx`, `caption`, `subcaption`, `tikz`, `pgfplots`, `tcolorbox`, `enumitem`.
- Figures: prefer vector PDF/SVG-converted-to-PDF for diagrams and plots; PNG is acceptable for screenshots.
- Captions: state what to read from the figure, not a duplicate title.

## Evidence Discipline

Separate these labels explicitly when accuracy matters:

- **Confirmed**: directly inspected source, local file, official dataset card, or rendered output.
- **Recorded**: present in prior notes/logs but not re-opened in the current environment.
- **Inferred**: logically follows from the data contract but the producing code was not inspected.
- **Unverified**: must be checked before public reproducibility claims.

For collaborator-facing reports, include a short "Audit checklist" when any upstream data-generation step was not directly inspected.

## Script

Use `scripts/init_tex_report.py` to create a clean `/tmp` project:

```bash
python3 /Users/mseok/dot/ai/codex/skills/tex-submission-pdf/scripts/init_tex_report.py \
  --slug xtrimopglm-contact-provenance \
  --title "xTrimoPGLM contact data for TAPE contact-map learning"
```

The script prints the new project path and writes `main.tex`, `Makefile`, `figures/`, `tables/`, `data/`, and `build/`.

## Delivery

In the final answer, provide links to the final PDF and any source `.tex` or archive the user may need. Mention the `/tmp` build directory only when useful for follow-up debugging.
