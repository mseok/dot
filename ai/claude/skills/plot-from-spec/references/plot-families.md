# Plot Families

Use this reference to choose the right family and required fields.

## `line`

Use for:

- training curves
- evaluation-over-step plots
- any ordered `x` axis with one or more series

Require:

- `mapping.x`
- `mapping.y`

Prefer:

- `aggregation.mode = group_summary` when multiple seeds or replicates exist
- `mapping.color` for method identity
- `mapping.style` only when color alone is not enough

Avoid:

- smoothing unless explicitly requested
- bars for ordered temporal data

## `grouped_bar`

Use for:

- categorical comparisons
- model or ablation summaries where one value per category is the main object

Require:

- `mapping.x`
- `mapping.y`

Prefer:

- `mapping.color` when multiple methods are compared within each category
- `mapping.error` or `aggregation.uncertainty` when uncertainty is available

Avoid:

- using this family for dense raw distributions
- more than a small number of hue groups without faceting

## `scatter_regression`

Use for:

- pairwise relationships
- calibration or correlation-style figures
- fitted linear trend visualization

Require:

- `mapping.x`
- `mapping.y`

Prefer:

- `figure.trend = linear` only when a trend line is scientifically appropriate
- `mapping.color` for cohort or method identity

Avoid:

- implying causality from a fitted line
- using linear trend lines when the user did not request or justify them

## `heatmap`

Use for:

- matrix-like summaries
- pairwise scores
- value grids after pivoting or aggregation

Require:

- `mapping.x`
- `mapping.y`
- `mapping.value`

Prefer:

- `figure.center` when the values are signed and need a diverging palette
- `figure.annot = true` only for small grids

Avoid:

- unreadable annotations on large grids
- diverging palettes for non-centered positive-only values

## `ablation_panel`

Use for:

- small multiples of ablation results
- one panel per metric, dataset, or condition
- categorical comparisons that benefit from shared layout

Require:

- `mapping.x`
- `mapping.y`
- `mapping.facet`

Prefer:

- `mapping.color` for method or condition identity
- `figure.sharey = true` when comparisons across panels should be direct

Avoid:

- too many panels in one row
- changing color identity across facets

## Out of scope for v0

Redirect instead of stretching the schema when the user asks for:

- violin or box plots
- 3D plots
- Sankey or network diagrams
- interactive plots
- geographic maps
- figures that depend on image editing rather than plotting code
