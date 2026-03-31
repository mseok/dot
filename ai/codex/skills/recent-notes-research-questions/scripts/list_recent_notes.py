#!/usr/bin/env python3
"""List recent Markdown notes with lightweight metadata and summary snippets."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
from pathlib import Path
from typing import Iterable


DEFAULT_EXCLUDES = {
    ".git",
    ".obsidian",
    "Attachments",
    "Templates",
    "node_modules",
    "__pycache__",
}

SUMMARY_HEADINGS = {
    "summary",
    "key sentence",
    "key points",
    "goals",
    "goal",
    "open questions",
    "failure mode",
    "failure modes",
    "next steps",
    "overview",
    "요약",
    "핵심 문장",
    "핵심",
    "학습 목표",
    "열린 질문",
    "오픈 질문",
    "실패 모드",
    "다음 단계",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", help="Vault root")
    parser.add_argument("--limit", type=int, default=12, help="Max notes to emit")
    parser.add_argument(
        "--days",
        type=int,
        default=14,
        help="Only include notes modified in the last N days",
    )
    parser.add_argument(
        "--include-dir",
        action="append",
        default=[],
        help="Only include notes whose relative path starts with this prefix",
    )
    parser.add_argument(
        "--exclude-dir",
        action="append",
        default=[],
        help="Exclude additional directory names or prefixes",
    )
    parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format",
    )
    return parser.parse_args()


def should_skip(path: Path, root: Path, include_dirs: list[str], exclude_dirs: set[str]) -> bool:
    rel = path.relative_to(root)
    rel_parts = set(rel.parts[:-1])

    if include_dirs:
        rel_posix = rel.as_posix()
        if not any(
            rel_posix.startswith(prefix.rstrip("/") + "/") or rel_posix == prefix.rstrip("/")
            for prefix in include_dirs
        ):
            return True

    if rel_parts & DEFAULT_EXCLUDES:
        return True

    rel_posix = rel.as_posix()
    for prefix in exclude_dirs:
        normalized = prefix.rstrip("/")
        if normalized in rel_parts or rel_posix.startswith(normalized + "/"):
            return True

    return False


def parse_frontmatter(text: str) -> tuple[dict[str, object], str]:
    if not text.startswith("---\n"):
        return {}, text

    end = text.find("\n---\n", 4)
    if end == -1:
        return {}, text

    block = text[4:end]
    body = text[end + 5 :]
    data: dict[str, object] = {}
    current_key: str | None = None

    for raw_line in block.splitlines():
        line = raw_line.rstrip()
        if not line.strip():
            continue
        if re.match(r"^[A-Za-z0-9_-]+:\s*", line):
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()
            current_key = key
            if not value:
                data[key] = []
            else:
                data[key] = parse_frontmatter_value(value)
        elif line.lstrip().startswith("- ") and current_key:
            existing = data.get(current_key)
            if not isinstance(existing, list):
                existing = [] if existing in (None, "") else [str(existing)]
            existing.append(strip_quotes(line.lstrip()[2:].strip()))
            data[current_key] = existing

    return data, body


def parse_frontmatter_value(value: str) -> object:
    value = value.strip()
    if value == "[]":
        return []
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [strip_quotes(item.strip()) for item in inner.split(",") if item.strip()]
    return strip_quotes(value)


def strip_quotes(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def extract_title(path: Path, body: str) -> str:
    for line in body.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return path.stem


def extract_headings(body: str, limit: int = 6) -> list[str]:
    headings: list[str] = []
    for line in body.splitlines():
        if line.startswith("#"):
            heading = line.lstrip("#").strip()
            if heading:
                headings.append(heading)
        if len(headings) >= limit:
            break
    return headings


def extract_summary(body: str, max_chars: int = 280) -> str:
    lines = body.splitlines()

    for i, line in enumerate(lines):
        if not line.startswith("#"):
            continue
        heading = line.lstrip("#").strip().lower()
        if heading not in SUMMARY_HEADINGS:
            continue
        snippet = collect_section(lines[i + 1 :], max_chars=max_chars)
        if snippet:
            return snippet

    return first_paragraph(body, max_chars=max_chars)


def collect_section(lines: Iterable[str], max_chars: int) -> str:
    chunks: list[str] = []
    size = 0
    for line in lines:
        stripped = line.strip()
        if line.startswith("#"):
            break
        if not stripped:
            if chunks:
                break
            continue
        size += len(stripped) + 1
        chunks.append(stripped)
        if size >= max_chars:
            break
    return trim_text(" ".join(chunks), max_chars)


def first_paragraph(body: str, max_chars: int) -> str:
    cleaned: list[str] = []
    for line in body.splitlines():
        stripped = line.strip()
        if not stripped:
            if cleaned:
                break
            continue
        if stripped.startswith("#"):
            continue
        cleaned.append(stripped)
        if sum(len(x) for x in cleaned) >= max_chars:
            break
    return trim_text(" ".join(cleaned), max_chars)


def trim_text(text: str, max_chars: int) -> str:
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) <= max_chars:
        return text
    return text[: max_chars - 3].rstrip() + "..."


def iter_notes(root: Path, args: argparse.Namespace) -> list[dict[str, object]]:
    cutoff = dt.datetime.now().timestamp() - args.days * 86400
    notes: list[dict[str, object]] = []
    exclude_dirs = set(args.exclude_dir)

    for path in root.rglob("*.md"):
        if should_skip(path, root, args.include_dir, exclude_dirs):
            continue

        try:
            stat = path.stat()
        except OSError:
            continue

        if stat.st_mtime < cutoff:
            continue

        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue

        frontmatter, body = parse_frontmatter(text)
        notes.append(
            {
                "path": path.relative_to(root).as_posix(),
                "title": extract_title(path, body),
                "modified": dt.datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="minutes"),
                "projects": frontmatter.get("projects", []),
                "categories": frontmatter.get("categories", []),
                "tags": frontmatter.get("tags", []),
                "headings": extract_headings(body),
                "summary": extract_summary(body),
            }
        )

    notes.sort(key=lambda item: item["modified"], reverse=True)
    return notes[: args.limit]


def render_markdown(notes: list[dict[str, object]]) -> str:
    lines = [f"# Recent notes ({len(notes)})", ""]
    for note in notes:
        lines.append(f"## {note['title']}")
        lines.append(f"- Path: `{note['path']}`")
        lines.append(f"- Modified: `{note['modified']}`")
        projects = as_list(note["projects"])
        categories = as_list(note["categories"])
        tags = as_list(note["tags"])
        if projects:
            lines.append(f"- Projects: {', '.join(projects)}")
        if categories:
            lines.append(f"- Categories: {', '.join(categories)}")
        if tags:
            lines.append(f"- Tags: {', '.join(tags)}")
        if note["headings"]:
            lines.append(f"- Headings: {' | '.join(note['headings'])}")
        if note["summary"]:
            lines.append(f"- Summary: {note['summary']}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def as_list(value: object) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item) for item in value if str(item).strip()]
    if isinstance(value, str):
        return [value] if value.strip() else []
    return [str(value)]


def main() -> int:
    args = parse_args()
    root = Path(os.path.expanduser(args.root)).resolve()
    notes = iter_notes(root, args)

    if args.format == "json":
        print(json.dumps(notes, ensure_ascii=False, indent=2))
    else:
        print(render_markdown(notes), end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
