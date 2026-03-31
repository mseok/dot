#!/usr/bin/env python3
"""Check that a draft's main narrative does not rely on wiki links."""

from __future__ import annotations

import argparse
import pathlib
import re


HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
ALLOWED_SECTIONS = {
    "Source notes",
    "Source notes (provenance)",
    "Claim ledger",
    "Next notes to review",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fail if wiki links appear in the main narrative outside "
        "allowed provenance sections."
    )
    parser.add_argument("draft", help="Path to a Markdown draft note.")
    return parser.parse_args()


def split_frontmatter(lines: list[str]) -> tuple[int, int]:
    if len(lines) < 3 or lines[0].strip() != "---":
        return (0, -1)
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return (0, index)
    return (0, -1)


def main() -> int:
    draft_path = pathlib.Path(parse_args().draft).expanduser().resolve()
    if not draft_path.exists():
        raise SystemExit(f"Missing draft: {draft_path}")

    lines = draft_path.read_text(encoding="utf-8").splitlines()
    _, frontmatter_end = split_frontmatter(lines)
    current_section = ""
    violations: list[str] = []

    for index, line in enumerate(lines, start=1):
        if frontmatter_end != -1 and index - 1 <= frontmatter_end:
            continue

        heading_match = HEADING_RE.match(line)
        if heading_match:
            current_section = heading_match.group(2).strip()
            continue

        if not WIKILINK_RE.search(line):
            continue

        if current_section not in ALLOWED_SECTIONS:
            violations.append(
                f"Line {index}: wiki link found in main narrative under section "
                f"'{current_section or 'unsectioned body'}'"
            )

    if violations:
        print("FAIL")
        for violation in violations:
            print(f"- {violation}")
        return 1

    print("PASS: no wiki links found in the main narrative")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
