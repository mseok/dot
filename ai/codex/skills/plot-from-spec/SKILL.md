---
name: plot-from-spec
description: >
  Generate publication-ready Python plotting code from a structured plot
  specification. Use when the user provides a dataframe schema, file columns, or
  semantic mappings and wants one of these supported plot families: training or
  evaluation line plots, grouped bar plots with error bars, scatter plots with
  linear trend lines, heatmaps, or ablation summary panels. Use this skill to
  normalize a plotting request into a strong spec, validate it, and emit
  deterministic matplotlib or seaborn code. Do not use for unsupported exotic
  plot types, raw image editing, interactive dashboards, or end-to-end
  experiment execution.
---

# Plot From Spec

Use this skill to turn a plotting request into a validated `plot_spec.json` and then into publication-ready Python plotting code.

## Quick start

- Read [`references/spec-schema.md`](references/spec-schema.md).
- Read [`references/plot-families.md`](references/plot-families.md) for the chosen family only.
- Read [`references/plot-gotchas.md`](references/plot-gotchas.md) before finalizing code.
- Draft or normalize the request into [`assets/plot_spec.template.json`](assets/plot_spec.template.json).
- Run `python3 scripts/validate_plot_spec.py <spec.json>`.
- Run `python3 scripts/generate_plot_code.py <spec.json> --output <plot_script.py>`.

## Intake contract

- Ask only for missing fields that materially change the generated code:
  - supported `plot_family`
  - data source path or dataframe variable name
  - semantic mapping such as `x`, `y`, `color`, `facet`, or `value`
  - aggregation mode and uncertainty rule
  - export basename or formats
- If the user starts with a vague plotting idea, first convert it into a structured spec and call out only the blocking gaps.
- Preserve scientific semantics. Do not invent smoothing, normalization, or uncertainty metrics.
- Keep the v0 scope limited to the five supported families.
- If the real request is "polish existing plotting code," redirect to a polishing skill instead of expanding this one.
- Do not claim the figure was rendered or visually verified unless the generated script was actually run.

## Workflow

1. Normalize the request into the schema from [`references/spec-schema.md`](references/spec-schema.md).
2. Confirm that the selected family is supported in [`references/plot-families.md`](references/plot-families.md).
3. Validate the spec with `scripts/validate_plot_spec.py`.
4. Generate code with `scripts/generate_plot_code.py`.
5. Apply the publication defaults from [`assets/paper.mplstyle`](assets/paper.mplstyle) and [`assets/palette-presets.json`](assets/palette-presets.json).
6. Review the output against [`references/plot-gotchas.md`](references/plot-gotchas.md).

## Supported families

- `line`: training or evaluation curves with optional uncertainty bands
- `grouped_bar`: categorical comparisons with optional error bars
- `scatter_regression`: scatter plots with optional per-group linear trend lines
- `heatmap`: pivoted value grids
- `ablation_panel`: small-multiple categorical ablation summaries

## Output contract

Return results in this order:

1. `Spec`: the final structured plot spec or the minimal missing fields
2. `Code`: the generated script path or code block
3. `Assumptions`: any defaults used for palette, sizing, aggregation, or export
4. `Checks`: any gotchas that still need a human eye or actual execution
