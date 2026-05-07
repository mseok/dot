#!/usr/bin/env python3
"""Validate a simple claim ledger section inside an Obsidian draft note."""

from __future__ import annotations

import argparse
import pathlib
import re


CLAIM_RE = re.compile(r"^\s*-\s*Claim:\s*(.+)$")
SOURCE_RE = re.compile(r"^\s*Source:\s*(.+)$")
STATUS_RE = re.compile(r"^\s*Status:\s*(solid|partial|speculative)\s*$")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Check that each claim entry has a source and valid status."
    )
    parser.add_argument("draft", help="Path to a Markdown draft note.")
    return parser.parse_args()


def main() -> int:
    draft_path = pathlib.Path(parse_args().draft).expanduser().resolve()
    if not draft_path.exists():
        raise SystemExit(f"Missing draft: {draft_path}")

    lines = draft_path.read_text(encoding="utf-8").splitlines()
    errors: list[str] = []
    claim_count = 0
    current_claim: str | None = None
    saw_source = False
    saw_status = False

    for index, line in enumerate(lines, start=1):
        claim_match = CLAIM_RE.match(line)
        if claim_match:
            if current_claim is not None:
                if not saw_source:
                    errors.append(f"Line {index}: previous claim missing Source")
                if not saw_status:
                    errors.append(f"Line {index}: previous claim missing Status")
            current_claim = claim_match.group(1).strip()
            saw_source = False
            saw_status = False
            claim_count += 1
            continue

        if current_claim is None:
            continue

        source_match = SOURCE_RE.match(line)
        if source_match:
            saw_source = True
            source_text = source_match.group(1)
            if not WIKILINK_RE.search(source_text):
                errors.append(f"Line {index}: source should include at least one [[Wiki Link]]")
            continue

        if STATUS_RE.match(line):
            saw_status = True
            continue

    if current_claim is not None:
        if not saw_source:
            errors.append("Final claim missing Source")
        if not saw_status:
            errors.append("Final claim missing Status")

    if claim_count == 0:
        errors.append("No '- Claim:' entries found")

    if errors:
        print("FAIL")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"PASS: validated {claim_count} claim entries")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
