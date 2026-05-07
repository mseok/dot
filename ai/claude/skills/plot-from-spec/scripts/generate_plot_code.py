#!/usr/bin/env python3
"""Generate publication-ready plotting code from a validated plot spec."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from validate_plot_spec import load_spec, validate_spec

SCRIPT_TEMPLATE = r'''#!/usr/bin/env python3
from __future__ import annotations

import json
import math
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

SPEC = json.loads(r"""__SPEC_JSON__""")
PALETTES = json.loads(r"""__PALETTES_JSON__""")
STYLE_PATH = Path(r"__STYLE_PATH__")

WIDTH_PRESETS = {
    "single-column": 3.35,
    "double-column": 6.9,
    "full-width": 7.2,
}
HEIGHT_PRESETS = {
    "line": 2.4,
    "grouped_bar": 2.6,
    "scatter_regression": 2.6,
    "heatmap": 3.0,
    "ablation_panel": 4.4,
}
LINESTYLES = ["-", "--", "-.", ":"]
MARKERS = ["o", "s", "^", "D", "v", "P", "X", "*"]
FALLBACK_RC = {
    "font.family": "DejaVu Sans",
    "font.size": 8,
    "axes.titlesize": 8,
    "axes.labelsize": 8,
    "xtick.labelsize": 7,
    "ytick.labelsize": 7,
    "legend.fontsize": 7,
    "legend.title_fontsize": 7,
    "axes.linewidth": 0.8,
    "xtick.major.width": 0.8,
    "ytick.major.width": 0.8,
    "lines.linewidth": 1.6,
    "lines.markersize": 4,
    "legend.frameon": False,
    "axes.spines.top": False,
    "axes.spines.right": False,
    "savefig.bbox": "tight",
    "savefig.pad_inches": 0.02,
}


def apply_publication_style() -> None:
    sns.set_theme(context="paper", style="ticks")
    if STYLE_PATH.exists():
        plt.style.use(STYLE_PATH)
    else:
        plt.rcParams.update(FALLBACK_RC)


def infer_figure_size() -> tuple[float, float]:
    constraints = SPEC["constraints"]
    family = SPEC["plot_family"]
    width_mode = constraints["width"]
    width_in = constraints.get("width_in")
    height_in = constraints.get("height_in")
    width = WIDTH_PRESETS.get(width_mode, width_in if width_in else 6.0)
    height = height_in if height_in else HEIGHT_PRESETS[family]
    return width, height


def resolve_palette(levels):
    palette_name = SPEC["constraints"].get("palette", "okabe-ito")
    if not levels:
        return {}
    if palette_name in PALETTES:
        colors = PALETTES[palette_name]
    else:
        try:
            colors = sns.color_palette(palette_name, n_colors=max(len(levels), 3)).as_hex()
        except Exception:
            colors = PALETTES["okabe-ito"]
    return {level: colors[index % len(colors)] for index, level in enumerate(levels)}


def infer_format(path: Path, explicit: str | None) -> str:
    if explicit:
        return explicit
    suffix = path.suffix.lower()
    if suffix == ".csv":
        return "csv"
    if suffix in {".tsv", ".txt"}:
        return "tsv"
    if suffix == ".parquet":
        return "parquet"
    raise ValueError(f"Cannot infer file format from suffix: {path.suffix}")


def load_dataframe() -> pd.DataFrame:
    source = SPEC["data_source"]
    if "path" in source:
        path = Path(source["path"]).expanduser()
        fmt = infer_format(path, source.get("format"))
        if fmt == "csv":
            return pd.read_csv(path)
        if fmt == "tsv":
            return pd.read_csv(path, sep="\t")
        if fmt == "parquet":
            return pd.read_parquet(path)
        raise ValueError(f"Unsupported data format: {fmt}")

    dataframe_name = source["dataframe_name"]
    if dataframe_name in globals():
        return globals()[dataframe_name].copy()
    raise KeyError(
        f"DataFrame '{dataframe_name}' is not available in globals(). "
        "Use a file path or run the generated code inside a notebook where that variable exists."
    )


def ordered_values(series: pd.Series, explicit_order=None):
    if explicit_order:
        return list(explicit_order)
    non_null = series.dropna()
    if pd.api.types.is_numeric_dtype(non_null):
        return sorted(non_null.unique().tolist())
    return pd.unique(non_null).tolist()


def summarize_series(grouped, summary_name: str):
    if summary_name == "mean":
        return grouped.mean()
    if summary_name == "median":
        return grouped.median()
    if summary_name == "sum":
        return grouped.sum()
    if summary_name == "min":
        return grouped.min()
    if summary_name == "max":
        return grouped.max()
    raise ValueError(f"Unsupported summary statistic: {summary_name}")


def uncertainty_series(grouped, mode: str):
    if mode == "std":
        return grouped.std(ddof=1)
    if mode == "sem":
        return grouped.sem(ddof=1)
    if mode == "ci95":
        return 1.96 * grouped.sem(ddof=1)
    if mode == "iqr":
        return grouped.quantile(0.75) - grouped.quantile(0.25)
    raise ValueError(f"Unsupported uncertainty mode: {mode}")


def aggregate_frame(df: pd.DataFrame) -> tuple[pd.DataFrame, str | None]:
    agg = SPEC["aggregation"]
    mapping = SPEC["mapping"]
    family = SPEC["plot_family"]
    target_column = mapping["value"] if family == "heatmap" else mapping["y"]
    mode = agg["mode"]

    if mode in {"raw", "pre_aggregated"}:
        return df.copy(), mapping.get("error")

    groupby = list(agg["groupby"])
    grouped = df.groupby(groupby, dropna=False)[target_column]
    summary_name = agg["summary"]
    result = summarize_series(grouped, summary_name).rename(target_column).reset_index()
    error_column = None
    if agg.get("uncertainty"):
        result["_error"] = uncertainty_series(grouped, agg["uncertainty"]).to_numpy()
        error_column = "_error"
    return result, error_column


def make_axis_labels(ax, title=None, xlabel=None, ylabel=None):
    figure = SPEC["figure"]
    ax.set_title(figure.get("title") if title is None else title)
    ax.set_xlabel(figure.get("xlabel", xlabel if xlabel is not None else ""))
    ax.set_ylabel(figure.get("ylabel", ylabel if ylabel is not None else ""))


def draw_line(ax, data: pd.DataFrame, error_column: str | None) -> None:
    mapping = SPEC["mapping"]
    figure = SPEC["figure"]
    x_col = mapping["x"]
    y_col = mapping["y"]
    hue_col = mapping.get("color")
    style_col = mapping.get("style")

    hue_levels = ordered_values(data[hue_col], figure.get("hue_order")) if hue_col else [None]
    palette = resolve_palette(hue_levels if hue_col else ["series"])
    style_levels = ordered_values(data[style_col]) if style_col else [None]
    linestyle_map = {
        level: LINESTYLES[index % len(LINESTYLES)] for index, level in enumerate(style_levels)
    }
    marker_map = {
        level: MARKERS[index % len(MARKERS)] for index, level in enumerate(style_levels)
    }

    group_columns = [column for column in (hue_col, style_col) if column]
    grouped = [((), data)] if not group_columns else data.groupby(group_columns, dropna=False, sort=False)

    for group_key, subset in grouped:
        if not isinstance(group_key, tuple):
            group_key = (group_key,)
        metadata = dict(zip(group_columns, group_key))
        subset = subset.sort_values(x_col)
        hue_value = metadata.get(hue_col)
        style_value = metadata.get(style_col)
        color = palette.get(hue_value if hue_col else "series", "#1f77b4")
        label_parts = [str(value) for value in (hue_value, style_value) if value is not None]
        label = " | ".join(label_parts) if label_parts else None

        ax.plot(
            subset[x_col].to_numpy(),
            subset[y_col].to_numpy(),
            color=color,
            linestyle=linestyle_map.get(style_value, "-"),
            marker=marker_map.get(style_value, "o"),
            label=label,
        )
        if error_column and error_column in subset:
            errors = subset[error_column].fillna(0).to_numpy()
            ax.fill_between(
                subset[x_col].to_numpy(),
                subset[y_col].to_numpy() - errors,
                subset[y_col].to_numpy() + errors,
                color=color,
                alpha=0.18,
                linewidth=0,
            )

    make_axis_labels(ax)
    if hue_col or style_col:
        ax.legend(title=figure.get("legend_title"))


def draw_grouped_bar(ax, data: pd.DataFrame, error_column: str | None, title=None, show_ylabel=True) -> None:
    mapping = SPEC["mapping"]
    figure = SPEC["figure"]
    x_col = mapping["x"]
    y_col = mapping["y"]
    hue_col = mapping.get("color")

    x_levels = ordered_values(data[x_col], figure.get("x_order"))
    hue_levels = ordered_values(data[hue_col], figure.get("hue_order")) if hue_col else [None]
    palette = resolve_palette(hue_levels if hue_col else ["series"])
    positions = np.arange(len(x_levels), dtype=float)
    total_width = 0.8
    bar_width = total_width / max(len(hue_levels), 1)

    for index, hue_value in enumerate(hue_levels):
        subset = data if hue_value is None else data[data[hue_col] == hue_value]
        subset = subset.set_index(x_col).reindex(x_levels).reset_index()
        offset = (index - (len(hue_levels) - 1) / 2.0) * bar_width
        errors = subset[error_column].to_numpy() if error_column and error_column in subset else None
        label = None if hue_value is None else str(hue_value)
        ax.bar(
            positions + offset,
            subset[y_col].to_numpy(),
            width=bar_width * 0.92,
            color=palette.get(hue_value if hue_col else "series", "#4C72B0"),
            edgecolor="black",
            linewidth=0.6,
            yerr=errors,
            capsize=2,
            label=label,
        )

    ax.set_xticks(positions)
    ax.set_xticklabels([str(value) for value in x_levels])
    make_axis_labels(
        ax,
        title=title,
        xlabel=figure.get("xlabel", ""),
        ylabel=figure.get("ylabel", "") if show_ylabel else "",
    )
    if hue_col:
        ax.legend(title=figure.get("legend_title"))


def draw_scatter_regression(ax, data: pd.DataFrame) -> None:
    mapping = SPEC["mapping"]
    figure = SPEC["figure"]
    x_col = mapping["x"]
    y_col = mapping["y"]
    hue_col = mapping.get("color")
    style_col = mapping.get("style")
    hue_levels = ordered_values(data[hue_col], figure.get("hue_order")) if hue_col else [None]
    palette = resolve_palette(hue_levels if hue_col else ["series"])

    sns.scatterplot(
        data=data,
        x=x_col,
        y=y_col,
        hue=hue_col,
        style=style_col,
        palette=palette if hue_col else None,
        ax=ax,
        s=28,
    )

    if figure.get("trend", "none") == "linear":
        group_columns = [column for column in (hue_col, style_col) if column]
        grouped = [((), data)] if not group_columns else data.groupby(group_columns, dropna=False, sort=False)
        for group_key, subset in grouped:
            if not isinstance(group_key, tuple):
                group_key = (group_key,)
            metadata = dict(zip(group_columns, group_key))
            if len(subset) < 2:
                continue
            x_values = subset[x_col].to_numpy(dtype=float)
            y_values = subset[y_col].to_numpy(dtype=float)
            coefficients = np.polyfit(x_values, y_values, 1)
            xs = np.linspace(np.nanmin(x_values), np.nanmax(x_values), 200)
            ys = coefficients[0] * xs + coefficients[1]
            color = palette.get(metadata.get(hue_col), "#1f77b4")
            ax.plot(xs, ys, color=color, linewidth=1.2)

    make_axis_labels(ax)
    if hue_col or style_col:
        ax.legend(title=figure.get("legend_title"))


def heatmap_cmap():
    palette_name = SPEC["constraints"].get("palette")
    center = SPEC["figure"].get("center")
    if palette_name in {"diverging-blue-red", "sequential-teal"}:
        return sns.color_palette(PALETTES[palette_name], as_cmap=True)
    if center is not None:
        return sns.color_palette("vlag", as_cmap=True)
    return sns.color_palette("crest", as_cmap=True)


def draw_heatmap(ax, data: pd.DataFrame) -> None:
    mapping = SPEC["mapping"]
    figure = SPEC["figure"]
    x_col = mapping["x"]
    y_col = mapping["y"]
    value_col = mapping["value"]

    pivot = data.pivot_table(
        index=y_col,
        columns=x_col,
        values=value_col,
        aggfunc="mean",
    )
    sns.heatmap(
        pivot,
        cmap=heatmap_cmap(),
        center=figure.get("center"),
        annot=figure.get("annot", False),
        fmt=figure.get("fmt", ".2f"),
        ax=ax,
        cbar_kws={"shrink": 0.8},
    )
    make_axis_labels(ax)


def draw_ablation_panel(data: pd.DataFrame, error_column: str | None):
    mapping = SPEC["mapping"]
    figure = SPEC["figure"]
    facet_col = mapping["facet"]
    facet_levels = ordered_values(data[facet_col], figure.get("facet_order"))
    n_panels = len(facet_levels)
    ncols = min(3, max(n_panels, 1))
    nrows = int(math.ceil(n_panels / ncols))
    width, base_height = infer_figure_size()
    fig, axes = plt.subplots(
        nrows,
        ncols,
        figsize=(width, max(base_height, nrows * 2.1)),
        squeeze=False,
        sharey=figure.get("sharey", True),
    )

    flat_axes = axes.ravel()
    for index, facet_value in enumerate(facet_levels):
        ax = flat_axes[index]
        subset = data[data[facet_col] == facet_value]
        draw_grouped_bar(
            ax,
            subset,
            error_column,
            title=str(facet_value),
            show_ylabel=index % ncols == 0,
        )
        if index % ncols != 0:
            ax.set_ylabel("")

    for index in range(len(facet_levels), len(flat_axes)):
        fig.delaxes(flat_axes[index])

    fig.tight_layout()
    return fig


def save_figure(fig):
    export = SPEC["export"]
    outdir = Path(export.get("outdir", ".")).expanduser()
    outdir.mkdir(parents=True, exist_ok=True)
    basename = export["basename"]
    saved = []
    for fmt in export["formats"]:
        output_path = outdir / f"{basename}.{fmt}"
        fig.savefig(
            output_path,
            dpi=export["dpi"],
            transparent=export.get("transparent", False),
        )
        saved.append(output_path)
    return saved


def main():
    apply_publication_style()
    raw_df = load_dataframe()
    plot_df, error_column = aggregate_frame(raw_df)
    family = SPEC["plot_family"]

    if family == "ablation_panel":
        fig = draw_ablation_panel(plot_df, error_column)
    else:
        width, height = infer_figure_size()
        fig, ax = plt.subplots(figsize=(width, height))
        if family == "line":
            draw_line(ax, plot_df, error_column)
        elif family == "grouped_bar":
            draw_grouped_bar(ax, plot_df, error_column)
        elif family == "scatter_regression":
            draw_scatter_regression(ax, plot_df)
        elif family == "heatmap":
            draw_heatmap(ax, plot_df)
        else:
            raise ValueError(f"Unsupported family: {family}")
        fig.tight_layout()

    saved_paths = save_figure(fig)
    for path in saved_paths:
        print(f"saved {path}")


if __name__ == "__main__":
    main()
'''


def generate_script(spec: dict, style_path: Path, palette_path: Path) -> str:
    palettes = json.loads(palette_path.read_text(encoding="utf-8"))
    spec_json = json.dumps(spec, indent=2, sort_keys=True)
    palettes_json = json.dumps(palettes, indent=2, sort_keys=True)
    return (
        SCRIPT_TEMPLATE.replace("__SPEC_JSON__", spec_json)
        .replace("__PALETTES_JSON__", palettes_json)
        .replace("__STYLE_PATH__", str(style_path))
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Python plotting code from a plot spec.")
    parser.add_argument("spec_path", help="Path to plot_spec.json")
    parser.add_argument(
        "--output",
        help="Path to the generated Python script. Defaults to <spec_stem>_plot.py",
    )
    args = parser.parse_args()

    spec_path = Path(args.spec_path).expanduser().resolve()
    spec = load_spec(spec_path)
    validation = validate_spec(spec)
    if validation["failures"]:
        for line in validation["failures"]:
            print(f"FAIL {line}", file=sys.stderr)
        return 1

    skill_dir = Path(__file__).resolve().parents[1]
    style_path = skill_dir / "assets" / "paper.mplstyle"
    palette_path = skill_dir / "assets" / "palette-presets.json"
    output_path = (
        Path(args.output).expanduser().resolve()
        if args.output
        else spec_path.with_name(spec_path.stem + "_plot.py")
    )
    output_path.write_text(
        generate_script(spec, style_path=style_path, palette_path=palette_path),
        encoding="utf-8",
    )
    print(f"Generated {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
