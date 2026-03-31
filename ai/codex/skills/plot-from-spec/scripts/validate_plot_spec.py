#!/usr/bin/env python3
"""Validate plot-from-spec JSON specifications."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SUPPORTED_FAMILIES = {
    "line",
    "grouped_bar",
    "scatter_regression",
    "heatmap",
    "ablation_panel",
}
REQUIRED_TOP_LEVEL = {
    "plot_family",
    "data_source",
    "data_schema",
    "mapping",
    "aggregation",
    "constraints",
    "figure",
    "export",
}
ALLOWED_TOP_LEVEL = set(REQUIRED_TOP_LEVEL)
MAPPING_ALLOWED_KEYS = {"x", "y", "value", "color", "style", "group", "facet", "error"}
FAMILY_MAPPING_REQUIREMENTS = {
    "line": {"x", "y"},
    "grouped_bar": {"x", "y"},
    "scatter_regression": {"x", "y"},
    "heatmap": {"x", "y", "value"},
    "ablation_panel": {"x", "y", "facet"},
}
AGGREGATION_MODES = {"raw", "group_summary", "pre_aggregated"}
SUMMARY_MODES = {"mean", "median", "sum", "min", "max"}
UNCERTAINTY_MODES = {"std", "sem", "ci95", "iqr"}
MEDIUMS = {"paper", "poster", "slides"}
WIDTHS = {"single-column", "double-column", "full-width", "custom"}
EXPORT_FORMATS = {"pdf", "png", "svg"}
TREND_MODES = {"none", "linear"}
DATA_TYPES = {"int", "float", "category", "bool", "string"}


def load_spec(path: str | Path) -> dict:
    spec_path = Path(path).expanduser().resolve()
    return json.loads(spec_path.read_text(encoding="utf-8"))


def _is_number(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def validate_spec(spec: dict) -> dict[str, list[str]]:
    failures: list[str] = []
    warnings: list[str] = []
    passes: list[str] = []

    missing_top = sorted(REQUIRED_TOP_LEVEL - set(spec))
    if missing_top:
        failures.append("missing top-level key(s): " + ", ".join(missing_top))
    else:
        passes.append("all required top-level keys are present")

    unknown_top = sorted(set(spec) - ALLOWED_TOP_LEVEL)
    if unknown_top:
        warnings.append("unknown top-level key(s): " + ", ".join(unknown_top))

    family = spec.get("plot_family")
    if family not in SUPPORTED_FAMILIES:
        failures.append(
            "plot_family must be one of: " + ", ".join(sorted(SUPPORTED_FAMILIES))
        )
    else:
        passes.append(f"plot family '{family}' is supported")

    data_source = spec.get("data_source", {})
    if not isinstance(data_source, dict):
        failures.append("data_source must be an object")
    else:
        has_path = bool(data_source.get("path"))
        has_df = bool(data_source.get("dataframe_name"))
        if has_path == has_df:
            failures.append(
                "data_source must provide exactly one of 'path' or 'dataframe_name'"
            )
        else:
            passes.append("data source provides one concrete loading mode")
        fmt = data_source.get("format")
        if fmt and fmt not in {"csv", "tsv", "parquet"}:
            failures.append("data_source.format must be csv, tsv, or parquet")

    data_schema = spec.get("data_schema", {})
    if not isinstance(data_schema, dict) or not data_schema:
        failures.append("data_schema must be a non-empty object")
    else:
        bad_types = sorted(
            key for key, value in data_schema.items() if value not in DATA_TYPES
        )
        if bad_types:
            warnings.append(
                "non-standard data_schema type labels for: " + ", ".join(bad_types)
            )
        passes.append("data schema is present")

    mapping = spec.get("mapping", {})
    if not isinstance(mapping, dict):
        failures.append("mapping must be an object")
    else:
        missing_mapping = sorted(FAMILY_MAPPING_REQUIREMENTS.get(family, set()) - set(mapping))
        if missing_mapping:
            failures.append(
                "mapping is missing required key(s): " + ", ".join(missing_mapping)
            )
        else:
            passes.append("mapping includes the required fields for the chosen family")

        unknown_mapping = sorted(set(mapping) - MAPPING_ALLOWED_KEYS)
        if unknown_mapping:
            warnings.append("unknown mapping key(s): " + ", ".join(unknown_mapping))

        referenced_columns = sorted(
            {
                value
                for value in mapping.values()
                if isinstance(value, str) and value.strip()
            }
        )
        missing_columns = sorted(
            column for column in referenced_columns if column not in data_schema
        )
        if missing_columns:
            failures.append(
                "mapping references columns absent from data_schema: "
                + ", ".join(missing_columns)
            )
        elif referenced_columns:
            passes.append("mapping columns all exist in data_schema")

    aggregation = spec.get("aggregation", {})
    if not isinstance(aggregation, dict):
        failures.append("aggregation must be an object")
    else:
        mode = aggregation.get("mode")
        if mode not in AGGREGATION_MODES:
            failures.append(
                "aggregation.mode must be one of: " + ", ".join(sorted(AGGREGATION_MODES))
            )
        else:
            passes.append(f"aggregation mode '{mode}' is valid")

        if mode == "group_summary":
            groupby = aggregation.get("groupby")
            if not isinstance(groupby, list) or not groupby:
                failures.append(
                    "aggregation.groupby must be a non-empty list for group_summary mode"
                )
            else:
                missing_groupby = [
                    column for column in groupby if column not in data_schema
                ]
                if missing_groupby:
                    failures.append(
                        "aggregation.groupby references columns absent from data_schema: "
                        + ", ".join(missing_groupby)
                    )
                else:
                    passes.append("aggregation.groupby references valid columns")

            summary = aggregation.get("summary")
            if summary not in SUMMARY_MODES:
                failures.append(
                    "aggregation.summary must be one of: " + ", ".join(sorted(SUMMARY_MODES))
                )
            else:
                passes.append(f"summary statistic '{summary}' is valid")
        elif aggregation.get("groupby"):
            warnings.append(
                "aggregation.groupby is ignored unless aggregation.mode is group_summary"
            )

        uncertainty = aggregation.get("uncertainty")
        if uncertainty and uncertainty not in UNCERTAINTY_MODES:
            failures.append(
                "aggregation.uncertainty must be one of: "
                + ", ".join(sorted(UNCERTAINTY_MODES))
            )
        elif uncertainty:
            passes.append(f"uncertainty metric '{uncertainty}' is valid")

        if family in {"grouped_bar", "ablation_panel"} and mode == "raw":
            warnings.append(
                f"{family} usually works best with pre_aggregated or group_summary data"
            )

    constraints = spec.get("constraints", {})
    if not isinstance(constraints, dict):
        failures.append("constraints must be an object")
    else:
        medium = constraints.get("medium")
        width = constraints.get("width")
        if medium not in MEDIUMS:
            failures.append("constraints.medium must be one of: " + ", ".join(sorted(MEDIUMS)))
        if width not in WIDTHS:
            failures.append("constraints.width must be one of: " + ", ".join(sorted(WIDTHS)))
        if medium in MEDIUMS and width in WIDTHS:
            passes.append("constraints.medium and constraints.width are valid")

        for key in ("colorblind_safe", "grayscale_safe"):
            if not isinstance(constraints.get(key), bool):
                failures.append(f"constraints.{key} must be a boolean")
        if isinstance(constraints.get("colorblind_safe"), bool) and isinstance(
            constraints.get("grayscale_safe"), bool
        ):
            passes.append("accessibility constraint flags are valid")

        if width == "custom" and not _is_number(constraints.get("width_in")):
            failures.append("constraints.width_in must be numeric when width is custom")
        if "height_in" in constraints and constraints["height_in"] is not None and not _is_number(
            constraints["height_in"]
        ):
            failures.append("constraints.height_in must be numeric when provided")
        if "palette" in constraints and not isinstance(constraints["palette"], str):
            failures.append("constraints.palette must be a string when provided")

    figure = spec.get("figure", {})
    if not isinstance(figure, dict):
        failures.append("figure must be an object")
    else:
        trend = figure.get("trend", "none")
        if trend not in TREND_MODES:
            failures.append("figure.trend must be 'none' or 'linear'")
        elif family != "scatter_regression" and trend != "none":
            warnings.append("figure.trend is only used for scatter_regression")

        for key in ("x_order", "hue_order", "facet_order"):
            value = figure.get(key, [])
            if value not in (None, []) and not isinstance(value, list):
                failures.append(f"figure.{key} must be a list when provided")

        if "sharey" in figure and not isinstance(figure["sharey"], bool):
            failures.append("figure.sharey must be a boolean when provided")
        if "annot" in figure and not isinstance(figure["annot"], bool):
            failures.append("figure.annot must be a boolean when provided")
        if "center" in figure and figure["center"] is not None and not _is_number(
            figure["center"]
        ):
            failures.append("figure.center must be numeric or null")

    export = spec.get("export", {})
    if not isinstance(export, dict):
        failures.append("export must be an object")
    else:
        basename = export.get("basename")
        formats = export.get("formats")
        dpi = export.get("dpi")
        if not isinstance(basename, str) or not basename.strip():
            failures.append("export.basename must be a non-empty string")
        if not isinstance(formats, list) or not formats:
            failures.append("export.formats must be a non-empty list")
        else:
            bad_formats = sorted(fmt for fmt in formats if fmt not in EXPORT_FORMATS)
            if bad_formats:
                failures.append(
                    "export.formats contains unsupported value(s): " + ", ".join(bad_formats)
                )
            else:
                passes.append("export formats are supported")
        if not isinstance(dpi, int) or dpi <= 0:
            failures.append("export.dpi must be a positive integer")
        else:
            passes.append("export dpi is valid")
        if "transparent" in export and not isinstance(export["transparent"], bool):
            failures.append("export.transparent must be a boolean when provided")

    return {"failures": failures, "warnings": warnings, "passes": passes}


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a plot-from-spec JSON file.")
    parser.add_argument("spec_path", help="Path to plot_spec.json")
    args = parser.parse_args()

    result = validate_spec(load_spec(args.spec_path))
    print(f"Spec validation: {Path(args.spec_path).expanduser().resolve()}")
    for line in result["passes"]:
        print(f"PASS {line}")
    for line in result["warnings"]:
        print(f"WARN {line}")
    for line in result["failures"]:
        print(f"FAIL {line}")
    print(
        "Summary: "
        f"{len(result['failures'])} FAIL, "
        f"{len(result['warnings'])} WARN, "
        f"{len(result['passes'])} PASS"
    )
    return 1 if result["failures"] else 0


if __name__ == "__main__":
    sys.exit(main())
