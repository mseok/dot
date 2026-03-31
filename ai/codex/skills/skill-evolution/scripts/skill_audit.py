#!/usr/bin/env python3
"""
Fast structural audit for Codex skills.

This script complements quick_validate.py by checking structural hygiene only.
It does not claim behavioral correctness or purpose fit.

Checks include:
- TODO placeholders
- missing or weak "when to use" wording
- dangling local markdown links in SKILL.md
- missing agents/openai.yaml metadata
- missing $skill-name mention in default_prompt
- oversized SKILL.md files that should likely be split
- optional skill-specific invariants for known local skills
"""

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None

LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
TODO_RE = re.compile(r"\[TODO:|TODO\b", re.IGNORECASE)
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n?", re.DOTALL)

SKILL_SPECIFIC_EXPECTATIONS = {
    "skill-evolution": {
        "required_markdown_terms": (
            "diagnose-only",
            "patch",
            "retarget",
            "narrow patch",
            "deep patch",
            "`Diagnosis`",
            "`Mode`",
            "`Patch depth`",
            "`Rubric`",
            "`Revision plan`",
            "`Changes`",
            "`Validation`",
            "`Scores`",
            "`Next prompt`",
            "references/deep-patch-playbook.md",
            "references/evaluation-loop.md",
            "references/score-gate-case-pack.json",
            "references/specialized-upgrade-cases.md",
            "references/mode-test-prompts.md",
            "implementation agent",
            "evaluation agent",
            "independent",
            "score_gate.py",
            "machine-readable",
        ),
        "required_prompt_terms": ("diagnose", "score", "patch", "retarget", "evaluation"),
    }
}


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def extract_frontmatter(markdown: str) -> dict:
    match = FRONTMATTER_RE.match(markdown)
    if not match:
        raise ValueError("No valid YAML frontmatter found in SKILL.md")
    frontmatter_text = match.group(1)
    if yaml is not None:
        frontmatter = yaml.safe_load(frontmatter_text)
        if not isinstance(frontmatter, dict):
            raise ValueError("Frontmatter must parse to a YAML mapping")
        return frontmatter
    return fallback_frontmatter(frontmatter_text)


def fallback_frontmatter(frontmatter_text: str) -> dict:
    data = {}
    lines = frontmatter_text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        if line.startswith((" ", "\t")):
            i += 1
            continue
        if ":" not in line:
            raise ValueError(f"Unsupported frontmatter line without key separator: {line}")
        key, raw_value = line.split(":", 1)
        key = key.strip()
        value = raw_value.lstrip()
        if value in {">", "|"}:
            i += 1
            block = []
            while i < len(lines):
                block_line = lines[i]
                if block_line.startswith("  "):
                    block.append(block_line[2:])
                    i += 1
                    continue
                if block_line.startswith("\t"):
                    block.append(block_line.lstrip("\t"))
                    i += 1
                    continue
                if not block_line.strip():
                    block.append("")
                    i += 1
                    continue
                break
            data[key] = "\n".join(block).strip()
            continue
        data[key] = strip_quotes(value.strip())
        i += 1
    if not isinstance(data, dict):
        raise ValueError("Frontmatter must parse to a YAML-like mapping")
    return data


def has_risky_plain_description(markdown: str) -> bool:
    match = FRONTMATTER_RE.match(markdown)
    if not match:
        return False
    for raw_line in match.group(1).splitlines():
        if not raw_line.lstrip().startswith("description:"):
            continue
        if re.match(r'^\s*description:\s*([\'"].*|[>|].*)$', raw_line):
            return False
        value = raw_line.split(":", 1)[1]
        return ": " in value
    return False


def extract_interface_fields(yaml_text: str) -> dict:
    interface = {}
    in_interface = False
    for raw_line in yaml_text.splitlines():
        line = raw_line.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if re.match(r"^[^\s].*:\s*$", line):
            in_interface = line.strip() == "interface:"
            continue
        if not in_interface:
            continue
        if not raw_line.startswith("  "):
            in_interface = False
            continue
        stripped = raw_line.strip()
        if ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        interface[key.strip()] = strip_quotes(value)
    return interface


def iter_local_links(markdown: str):
    for raw_target in LINK_RE.findall(markdown):
        target = raw_target.strip()
        if not target or target.startswith(("http://", "https://", "#", "mailto:")):
            continue
        yield target.split("#", 1)[0]


def audit_skill(skill_dir: Path) -> tuple[int, int, int, list[str]]:
    failures = 0
    warnings = 0
    passes = 0
    lines: list[str] = []

    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return 1, 0, 0, [f"FAIL SKILL.md missing: {skill_md}"]

    markdown = load_text(skill_md)
    try:
        frontmatter = extract_frontmatter(markdown)
    except Exception as exc:
        return 1, 0, 0, [f"FAIL frontmatter: {exc}"]

    skill_name = str(frontmatter.get("name", "")).strip()
    description = str(frontmatter.get("description", "")).strip()

    if yaml is None:
        warnings += 1
        lines.append(
            "WARN PyYAML unavailable; YAML syntax validation skipped, using degraded frontmatter parsing"
        )

    if TODO_RE.search(markdown):
        failures += 1
        lines.append("FAIL TODO placeholder(s) remain in SKILL.md")
    else:
        passes += 1
        lines.append("PASS no TODO placeholders found")

    normalized_description = " ".join(description.lower().split())
    if "use when" not in normalized_description:
        warnings += 1
        lines.append("WARN description does not include explicit 'Use when' wording")
    else:
        passes += 1
        lines.append("PASS description includes explicit trigger wording")

    if has_risky_plain_description(markdown):
        warnings += 1
        lines.append(
            "WARN description is an unquoted plain scalar containing ': '; quote it or use '>'"
        )
    else:
        passes += 1
        lines.append("PASS description avoids risky plain-scalar YAML style")

    skill_lines = markdown.count("\n") + 1
    if skill_lines > 500:
        warnings += 1
        lines.append(f"WARN SKILL.md is long ({skill_lines} lines); consider moving detail to references/")
    else:
        passes += 1
        lines.append(f"PASS SKILL.md length is reasonable ({skill_lines} lines)")

    linked_missing = []
    for link_target in iter_local_links(markdown):
        resolved = (skill_dir / link_target).resolve()
        if not resolved.exists():
            linked_missing.append(link_target)
    if linked_missing:
        failures += 1
        joined = ", ".join(sorted(set(linked_missing)))
        lines.append(f"FAIL missing linked local file(s): {joined}")
    else:
        passes += 1
        lines.append("PASS all linked local files in SKILL.md exist")

    agents_yaml = skill_dir / "agents" / "openai.yaml"
    if not agents_yaml.exists():
        warnings += 1
        lines.append("WARN agents/openai.yaml is missing")
    else:
        try:
            interface = extract_interface_fields(load_text(agents_yaml))
        except Exception as exc:
            failures += 1
            lines.append(f"FAIL agents/openai.yaml parse error: {exc}")
        else:
            if not interface:
                failures += 1
                lines.append("FAIL agents/openai.yaml interface section is missing or empty")
            else:
                missing = [
                    key
                    for key in ("display_name", "short_description", "default_prompt")
                    if not str(interface.get(key, "")).strip()
                ]
                if missing:
                    failures += 1
                    lines.append(
                        "FAIL agents/openai.yaml missing interface field(s): " + ", ".join(missing)
                    )
                else:
                    passes += 1
                    lines.append("PASS agents/openai.yaml interface fields are present")

                default_prompt = str(interface.get("default_prompt", ""))
                expected_skill_ref = f"${skill_name}" if skill_name else "$skill-name"
                if expected_skill_ref not in default_prompt:
                    warnings += 1
                    lines.append(f"WARN default_prompt does not mention {expected_skill_ref}")
                else:
                    passes += 1
                    lines.append("PASS default_prompt mentions the skill explicitly")

                expectations = SKILL_SPECIFIC_EXPECTATIONS.get(skill_name)
                if expectations:
                    missing_terms = [
                        term
                        for term in expectations["required_markdown_terms"]
                        if term not in markdown
                    ]
                    if missing_terms:
                        failures += 1
                        lines.append(
                            "FAIL SKILL.md missing expected structural term(s): "
                            + ", ".join(missing_terms)
                        )
                    else:
                        passes += 1
                        lines.append(
                            "PASS SKILL.md includes expected mode, patch-depth, output, and reference terms"
                        )

                    default_prompt_lower = default_prompt.lower()
                    missing_prompt_terms = [
                        term
                        for term in expectations["required_prompt_terms"]
                        if term not in default_prompt_lower
                    ]
                    if missing_prompt_terms:
                        failures += 1
                        lines.append(
                            "FAIL default_prompt missing expected mode term(s): "
                            + ", ".join(missing_prompt_terms)
                        )
                    else:
                        passes += 1
                        lines.append("PASS default_prompt includes expected mode terms")

    return failures, warnings, passes, lines


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a Codex skill for common upgrade issues.")
    parser.add_argument("skill_dir", help="Path to the skill directory")
    args = parser.parse_args()

    skill_dir = Path(args.skill_dir).expanduser().resolve()
    failures, warnings, passes, lines = audit_skill(skill_dir)

    print(f"Skill audit: {skill_dir}")
    for line in lines:
        print(line)
    print(f"Summary: {failures} FAIL, {warnings} WARN, {passes} PASS")
    print("Note: PASS means structural hygiene only, not behavioral correctness.")

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
