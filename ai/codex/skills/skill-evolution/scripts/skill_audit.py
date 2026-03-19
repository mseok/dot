#!/usr/bin/env python3
"""
Fast structural audit for Codex skills.

This script complements quick_validate.py by checking for:
- TODO placeholders
- missing or weak "when to use" wording
- dangling local markdown links in SKILL.md
- missing agents/openai.yaml metadata
- missing $skill-name mention in default_prompt
- oversized SKILL.md files that should likely be split
"""

import argparse
import re
import sys
from pathlib import Path

LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
TODO_RE = re.compile(r"\[TODO:|TODO\b", re.IGNORECASE)


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def extract_frontmatter(markdown: str) -> dict:
    match = re.match(r"^---\n(.*?)\n---\n?", markdown, re.DOTALL)
    if not match:
        raise ValueError("No valid YAML frontmatter found in SKILL.md")
    frontmatter = {}
    for raw_line in match.group(1).splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        if ":" not in raw_line:
            continue
        key, value = raw_line.split(":", 1)
        frontmatter[key.strip()] = strip_quotes(value)
    return frontmatter


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

    if TODO_RE.search(markdown):
        failures += 1
        lines.append("FAIL TODO placeholder(s) remain in SKILL.md")
    else:
        passes += 1
        lines.append("PASS no TODO placeholders found")

    if "use when" not in description.lower():
        warnings += 1
        lines.append("WARN description does not include explicit 'Use when' wording")
    else:
        passes += 1
        lines.append("PASS description includes explicit trigger wording")

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
                    lines.append(
                        f"WARN default_prompt does not mention {expected_skill_ref}"
                    )
                else:
                    passes += 1
                    lines.append("PASS default_prompt mentions the skill explicitly")

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

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
