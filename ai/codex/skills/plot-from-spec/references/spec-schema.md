# Spec Schema

Use this schema to turn a plotting request into a deterministic input for code generation.

## Required top-level keys

- `plot_family`
- `data_source`
- `data_schema`
- `mapping`
- `aggregation`
- `constraints`
- `figure`
- `export`

## `plot_family`

Allowed values:

- `line`
- `grouped_bar`
- `scatter_regression`
- `heatmap`
- `ablation_panel`

## `data_source`

Provide exactly one of these:

- `path`: file path to `csv`, `tsv`, or `parquet`
- `dataframe_name`: variable name to use in an existing notebook or session

Optional keys:

- `format`: override file format if suffix is ambiguous

## `data_schema`

Map every referenced field to a simple type label.

Recommended labels:

- `int`
- `float`
- `category`
- `bool`
- `string`

## `mapping`

Shared keys:

- `x`
- `y`

Optional shared keys:

- `color`
- `style`
- `group`
- `facet`
- `error`

Heatmap-only key:

- `value`

## Family-specific mapping requirements

- `line`: require `x`, `y`; allow `color`, `style`, `group`, `error`
- `grouped_bar`: require `x`, `y`; allow `color`, `error`
- `scatter_regression`: require `x`, `y`; allow `color`, `style`
- `heatmap`: require `x`, `y`, `value`
- `ablation_panel`: require `x`, `y`, `facet`; allow `color`, `error`

## `aggregation`

Required key:

- `mode`: `raw`, `group_summary`, or `pre_aggregated`

Optional keys:

- `groupby`: list of columns, required for `group_summary`
- `summary`: `mean`, `median`, `sum`, `min`, or `max`
- `uncertainty`: `std`, `sem`, `ci95`, or `iqr`

Rules:

- Use `raw` when every row should be plotted directly.
- Use `group_summary` when the plotting code must aggregate repeated observations.
- Use `pre_aggregated` when the input already contains final plot values and optional error columns.

## `constraints`

Required keys:

- `medium`: `paper`, `poster`, or `slides`
- `width`: `single-column`, `double-column`, `full-width`, or `custom`
- `colorblind_safe`: boolean
- `grayscale_safe`: boolean

Optional keys:

- `width_in`
- `height_in`
- `palette`

## `figure`

Optional keys:

- `title`
- `xlabel`
- `ylabel`
- `legend_title`
- `x_order`
- `hue_order`
- `facet_order`
- `trend`: `none` or `linear`
- `sharey`
- `annot`
- `fmt`
- `center`

## `export`

Required keys:

- `basename`
- `formats`
- `dpi`

Optional keys:

- `outdir`
- `transparent`

## Minimal example

```json
{
  "plot_family": "line",
  "data_source": {
    "dataframe_name": "df"
  },
  "data_schema": {
    "epoch": "int",
    "method": "category",
    "auroc": "float",
    "seed": "int"
  },
  "mapping": {
    "x": "epoch",
    "y": "auroc",
    "color": "method",
    "group": "seed"
  },
  "aggregation": {
    "mode": "group_summary",
    "groupby": ["epoch", "method"],
    "summary": "mean",
    "uncertainty": "std"
  },
  "constraints": {
    "medium": "paper",
    "width": "single-column",
    "colorblind_safe": true,
    "grayscale_safe": true,
    "palette": "okabe-ito"
  },
  "figure": {
    "xlabel": "Epoch",
    "ylabel": "AUROC",
    "legend_title": "Method",
    "trend": "none"
  },
  "export": {
    "basename": "training_auroc",
    "formats": ["pdf", "png"],
    "dpi": 300
  }
}
```
