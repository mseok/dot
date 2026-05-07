# Plot Gotchas

Use this list as the final review pass after code generation.

## Semantics

- Do not aggregate unless `aggregation.mode` says to aggregate.
- Do not invent uncertainty bands or error bars.
- Do not smooth training curves unless explicitly requested.
- Do not reorder categories unless `x_order`, `hue_order`, or `facet_order` is provided.

## Color and accessibility

- Default to `okabe-ito` for paper figures unless the user asks otherwise.
- Do not use rainbow or `jet`-style palettes.
- Keep the same semantic category on the same color across panels.
- If `grayscale_safe` is true, do not rely on color alone; use markers, line styles, or direct labels when needed.

## Layout

- Single-column figures must stay readable after width reduction.
- Keep legends out of the data region when possible.
- Avoid rotated category labels unless they are truly necessary.
- For ablation panels, use shared axes when cross-panel comparisons are the point.

## Family-specific cautions

- `line`: sort by `x` before plotting.
- `grouped_bar`: avoid too many hue groups; facet instead.
- `scatter_regression`: trend lines should not silently overwrite the raw data story.
- `heatmap`: use `annot` only for small matrices.
- `ablation_panel`: do not mix independent y-scales with claims of direct comparability.

## Export

- Save vector formats for publication when possible.
- Use transparent backgrounds only if the downstream workflow needs them.
- Do not claim final visual quality without actually rendering the figure.
