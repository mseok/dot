#!/usr/bin/env python3
"""
Validate the default score-gated harness for skill-evolution.

This script checks:
- the machine-readable case pack
- the machine-readable evaluator report
- prompt IDs referenced by the case pack
- weighted score computation and threshold gating

It does not execute model behavior. It enforces that the scored path is backed
by reproducible local artifacts rather than prose alone.
"""

import argparse
import json
import re
import sys
from pathlib import Path

PROMPT_HEADING_RE = re.compile(r"^## `([^`]+)`\s*$")
REQUIRED_CASE_IDS = {"implementer-rubric", "evaluator-score", "loop-until-threshold"}


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a top-level JSON object")
    return data


def prompt_ids(mode_test_prompts: Path) -> set[str]:
    ids = set()
    for line in mode_test_prompts.read_text(encoding="utf-8").splitlines():
        match = PROMPT_HEADING_RE.match(line.strip())
        if match:
            ids.add(match.group(1))
    return ids


def validate_case_pack(case_pack: dict, prompt_id_set: set[str]) -> tuple[list[str], list[str], dict[str, float]]:
    failures: list[str] = []
    passes: list[str] = []

    scale_max = case_pack.get("scale_max")
    threshold = case_pack.get("threshold_default")
    rubric = case_pack.get("rubric")
    cases = case_pack.get("required_cases")
    flags = case_pack.get("required_report_flags")

    if not isinstance(scale_max, (int, float)) or scale_max <= 0:
        failures.append("FAIL case pack scale_max must be a positive number")
    else:
        passes.append(f"PASS case pack scale_max is valid ({scale_max})")

    if not isinstance(threshold, (int, float)) or threshold <= 0:
        failures.append("FAIL case pack threshold_default must be a positive number")
    else:
        passes.append(f"PASS case pack threshold_default is valid ({threshold})")

    rubric_map: dict[str, float] = {}
    if not isinstance(rubric, list) or not rubric:
        failures.append("FAIL case pack rubric must be a non-empty list")
    else:
        total_weight = 0.0
        for item in rubric:
            if not isinstance(item, dict):
                failures.append("FAIL every rubric entry must be an object")
                continue
            rubric_id = item.get("id")
            weight = item.get("weight")
            if not isinstance(rubric_id, str) or not rubric_id:
                failures.append("FAIL rubric entry missing non-empty id")
                continue
            if not isinstance(weight, (int, float)) or weight <= 0:
                failures.append(f"FAIL rubric entry {rubric_id} has invalid weight")
                continue
            rubric_map[rubric_id] = float(weight)
            total_weight += float(weight)
        if abs(total_weight - float(scale_max)) > 1e-9:
            failures.append(
                f"FAIL rubric weights must sum to scale_max ({scale_max}), got {total_weight}"
            )
        else:
            passes.append(f"PASS rubric weights sum to scale_max ({scale_max})")

    if not isinstance(cases, list) or not cases:
        failures.append("FAIL case pack required_cases must be a non-empty list")
    else:
        case_map = {}
        for item in cases:
            if not isinstance(item, dict):
                failures.append("FAIL every required case entry must be an object")
                continue
            case_id = item.get("id")
            prompt_id = item.get("prompt_id")
            role = item.get("role")
            if not isinstance(case_id, str) or not case_id:
                failures.append("FAIL required case missing non-empty id")
                continue
            case_map[case_id] = item
            if prompt_id not in prompt_id_set:
                failures.append(f"FAIL prompt_id for case {case_id} not found in mode-test-prompts.md")
            if role not in {"implementation", "evaluation", "loop"}:
                failures.append(f"FAIL role for case {case_id} must be implementation, evaluation, or loop")
        missing = REQUIRED_CASE_IDS - set(case_map)
        if missing:
            failures.append("FAIL required case id(s) missing: " + ", ".join(sorted(missing)))
        else:
            passes.append("PASS required case ids are present")

    if flags != {"independent_evaluation": True}:
        failures.append("FAIL required_report_flags must equal {'independent_evaluation': true}")
    else:
        passes.append("PASS required_report_flags enforce independent evaluation")

    return failures, passes, rubric_map


def validate_report(report: dict, case_pack: dict, rubric_map: dict[str, float]) -> tuple[list[str], list[str], float]:
    failures: list[str] = []
    passes: list[str] = []

    categories = report.get("categories")
    cases = report.get("cases")
    threshold = report.get("threshold")
    threshold_met = report.get("threshold_met")
    independent = report.get("independent_evaluation")
    blocker = report.get("blocker")

    default_threshold = case_pack.get("threshold_default")
    scale_max = case_pack.get("scale_max")
    if threshold is None:
        threshold = default_threshold
    if not isinstance(threshold, (int, float)):
        failures.append("FAIL report threshold must be numeric")
    elif threshold <= 0 or threshold > float(scale_max):
        failures.append(
            f"FAIL report threshold must be > 0 and <= scale_max ({scale_max}), got {threshold}"
        )
    else:
        if float(threshold) == float(default_threshold):
            passes.append(f"PASS report threshold uses case-pack default ({threshold})")
        else:
            passes.append(f"PASS report threshold overrides default gate ({threshold})")

    total_score = 0.0
    if not isinstance(categories, dict):
        failures.append("FAIL report categories must be an object")
    else:
        if set(categories) != set(rubric_map):
            failures.append("FAIL report categories must match rubric ids exactly")
        for rubric_id, weight in rubric_map.items():
            score = categories.get(rubric_id)
            if not isinstance(score, (int, float)):
                failures.append(f"FAIL report category {rubric_id} must be numeric")
                continue
            if score < 0 or score > weight:
                failures.append(
                    f"FAIL report category {rubric_id} must be between 0 and its weight ({weight})"
                )
                continue
            total_score += float(score)
        if not failures:
            passes.append(f"PASS report category scores are valid (total={total_score:.1f})")

    if not isinstance(cases, dict):
        failures.append("FAIL report cases must be an object")
    else:
        missing_case_status = REQUIRED_CASE_IDS - set(cases)
        if missing_case_status:
            failures.append(
                "FAIL report missing case status for: " + ", ".join(sorted(missing_case_status))
            )
        failing_cases = [case_id for case_id, status in cases.items() if status != "pass"]
        if failing_cases:
            failures.append("FAIL report contains non-pass case status for: " + ", ".join(sorted(failing_cases)))
        else:
            passes.append("PASS report case statuses all pass")

    if independent is not True:
        failures.append("FAIL report independent_evaluation must be true")
    else:
        passes.append("PASS report marks evaluation as independent")

    computed_threshold_met = total_score >= float(threshold)
    if threshold_met is not computed_threshold_met:
        failures.append(
            "FAIL report threshold_met does not match computed score against the report threshold"
        )
    else:
        passes.append("PASS report threshold_met matches computed score")

    if computed_threshold_met and blocker:
        failures.append("FAIL blocker must be empty when threshold_met is true")
    elif not computed_threshold_met and not blocker:
        failures.append("FAIL blocker must be non-empty when threshold_met is false")
    else:
        passes.append("PASS blocker field matches threshold result")

    return failures, passes, total_score


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the score-gated case pack and evaluator report.")
    parser.add_argument("case_pack", help="Path to score-gate-case-pack.json")
    parser.add_argument("report", help="Path to machine-readable evaluator report JSON")
    args = parser.parse_args()

    case_pack_path = Path(args.case_pack).expanduser().resolve()
    report_path = Path(args.report).expanduser().resolve()
    mode_test_prompts = case_pack_path.parent / "mode-test-prompts.md"

    failures: list[str] = []
    passes: list[str] = []

    if not case_pack_path.exists():
        failures.append(f"FAIL case pack missing: {case_pack_path}")
    if not report_path.exists():
        failures.append(f"FAIL evaluator report missing: {report_path}")
    if not mode_test_prompts.exists():
        failures.append(f"FAIL mode-test-prompts missing: {mode_test_prompts}")
    if failures:
        for line in failures:
            print(line)
        print(f"Summary: {len(failures)} FAIL, 0 PASS")
        return 1

    case_pack = load_json(case_pack_path)
    report = load_json(report_path)
    prompt_id_set = prompt_ids(mode_test_prompts)

    case_failures, case_passes, rubric_map = validate_case_pack(case_pack, prompt_id_set)
    report_failures, report_passes, total_score = validate_report(report, case_pack, rubric_map)

    failures.extend(case_failures)
    failures.extend(report_failures)
    passes.extend(case_passes)
    passes.extend(report_passes)

    print(f"Score gate validation: {case_pack_path}")
    for line in passes:
        print(line)
    for line in failures:
        print(line)
    if not failures:
        print(
            f"PASS computed independent evaluation score clears threshold ({total_score:.1f} >= {case_pack['threshold_default']:.1f})"
        )
    print(f"Summary: {len(failures)} FAIL, {len(passes)} PASS")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
