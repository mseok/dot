#!/usr/bin/env python3
"""Build a compact Markdown source bundle from Obsidian notes."""

from __future__ import annotations

import argparse
import pathlib
import re
from typing import Iterable


HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)$")
WIKILINK_RE = re.compile(r"\[\[([^\]]+)\]\]")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect note metadata, headings, and wiki links into a "
        "compact Markdown source bundle."
    )
    parser.add_argument(
        "notes",
        nargs="+",
        help="One or more Obsidian note paths.",
    )
    parser.add_argument(
        "--output",
        help="Write the bundle to this Markdown path instead of stdout.",
    )
    parser.add_argument(
        "--max-headings",
        type=int,
        default=8,
        help="Maximum number of headings to keep per note. Default: 8.",
    )
    parser.add_argument(
        "--max-links",
        type=int,
        default=12,
        help="Maximum number of wiki links to keep per note. Default: 12.",
    )
    return parser.parse_args()


def split_frontmatter(text: str) -> tuple[list[str], list[str]]:
    lines = text.splitlines()
    if len(lines) < 3 or lines[0].strip() != "---":
        return [], lines

    frontmatter: list[str] = []
    for index in range(1, len(lines)):
        if lines[index].strip() == "---":
            return frontmatter, lines[index + 1 :]
        frontmatter.append(lines[index])
    return [], lines


def collect_headings(lines: Iterable[str], limit: int) -> list[str]:
    headings: list[str] = []
    for line in lines:
        match = HEADING_RE.match(line)
        if not match:
            continue
        level = len(match.group(1))
        title = match.group(2).strip()
        headings.append(f"{'  ' * (level - 1)}- {title}")
        if len(headings) >= limit:
            break
    return headings


def collect_links(text: str, limit: int) -> list[str]:
    seen: set[str] = set()
    links: list[str] = []
    for match in WIKILINK_RE.finditer(text):
        label = match.group(1).strip()
        if label in seen:
            continue
        seen.add(label)
        links.append(f"- [[{label}]]")
        if len(links) >= limit:
            break
    return links


def render_note_block(path: pathlib.Path, max_headings: int, max_links: int) -> str:
    text = path.read_text(encoding="utf-8")
    frontmatter, body_lines = split_frontmatter(text)
    headings = collect_headings(body_lines, max_headings)
    links = collect_links(text, max_links)

    parts = [f"## {path.name}", "", f"- Path: `{path}`"]

    if frontmatter:
        parts.extend(["- Frontmatter:", "```yaml", *frontmatter, "```"])

    if headings:
        parts.extend(["- Headings:"] + headings)

    if links:
        parts.extend(["- Linked notes:"] + links)

    preview_lines = [
        line for line in body_lines if line.strip() and not line.strip().startswith("#")
    ][:5]
    if preview_lines:
        parts.extend(["- Preview:", "```text", *preview_lines, "```"])

    return "\n".join(parts)


def main() -> int:
    args = parse_args()
    note_paths = [pathlib.Path(note).expanduser().resolve() for note in args.notes]
    missing = [str(path) for path in note_paths if not path.exists()]
    if missing:
        raise SystemExit("Missing note(s): " + ", ".join(missing))

    blocks = [
        render_note_block(path, args.max_headings, args.max_links) for path in note_paths
    ]
    output = "# Source Bundle\n\n" + "\n\n".join(blocks) + "\n"

    if args.output:
        output_path = pathlib.Path(args.output).expanduser().resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(output, encoding="utf-8")
    else:
        print(output, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
