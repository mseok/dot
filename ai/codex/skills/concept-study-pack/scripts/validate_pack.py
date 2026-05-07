#!/usr/bin/env python3
"""Validate a local concept study pack for offline use."""

from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit


EXTERNAL_PREFIXES = ("http://", "https://", "mailto:", "tel:")
KNOWN_FILE_EXTS = {
    ".md",
    ".html",
    ".htm",
    ".png",
    ".jpg",
    ".jpeg",
    ".gif",
    ".svg",
    ".webp",
    ".pdf",
    ".py",
    ".ipynb",
    ".csv",
    ".tsv",
    ".json",
    ".yaml",
    ".yml",
    ".txt",
}
MD_LINK_RE = re.compile(r"!?(?<!\\)\[[^\]]*\]\(([^)]+)\)")
HTML_REF_RE = re.compile(r"(?:href|src)=[\"']([^\"']+)[\"']", re.IGNORECASE)
HTML_NETWORK_RE = re.compile(
    r"(?:href|src)\s*=\s*[\"']\s*(?:(?:https?:)?//|mailto:|tel:)"
    r"|<\s*script\b[^>]*\bsrc\s*="
    r"|@import\s+(?:url\()?['\"]?\s*(?:(?:https?:)?//|https?:)"
    r"|cdnjs\.cloudflare|unpkg|jsdelivr|fonts\.(?:googleapis|gstatic)",
    re.IGNORECASE,
)
ANALYTICS_RE = re.compile(
    r"\b(?:gtag|googletagmanager|google-analytics|plausible|posthog|mixpanel)\b",
    re.IGNORECASE,
)
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
CHECK_SECTION_RE = re.compile(
    r"\bSelf-check\b|FAQ self-check|final checklist|minimum success criteria|success criteria|"
    r"minimum checklist|최소\s*성공|학습\s*완료|최종\s*체크리스트|최종\s*확인|체크리스트",
    re.IGNORECASE,
)
ANSWER_DOC_NAME_RE = re.compile(r"answer|answers|solution|solutions|worked|답안|정답|풀이", re.IGNORECASE)
ANSWER_TARGET_RE = re.compile(r"answer|answers|solution|solutions|worked|답안|정답|풀이", re.IGNORECASE)
WORKSHEET_NAME_RE = re.compile(r"worksheet|applied|practice|실습|연습지", re.IGNORECASE)
HTML_ID_RE = re.compile(r"\b(?:id|name)\s*=\s*['\"]([^'\"]+)['\"]", re.IGNORECASE)


def normalize_markdown_ref(raw: str) -> str:
    ref = raw.strip()
    if " \"" in ref:
        ref = ref.split(" \"", 1)[0]
    if " '" in ref:
        ref = ref.split(" '", 1)[0]
    if ref.startswith("<") and ref.endswith(">"):
        ref = ref[1:-1]
    return unquote(ref.split("#", 1)[0].strip())


def normalize_ref_with_fragment(raw: str) -> tuple[str, str]:
    ref = raw.strip()
    if " \"" in ref:
        ref = ref.split(" \"", 1)[0]
    if " '" in ref:
        ref = ref.split(" '", 1)[0]
    if ref.startswith("<") and ref.endswith(">"):
        ref = ref[1:-1]
    ref = unquote(ref.strip())
    parsed = urlsplit(ref)
    path = parsed.path
    fragment = parsed.fragment
    if "#" in ref and not fragment:
        path, fragment = ref.split("#", 1)
    return path.strip(), fragment.strip()


def is_checkable_local_file(ref: str) -> bool:
    if not ref or ref.startswith("#") or ref.startswith(EXTERNAL_PREFIXES):
        return False
    suffix = Path(ref).suffix.lower()
    return suffix in KNOWN_FILE_EXTS or "/" in ref or ref.startswith(".")


def is_external_ref(ref: str) -> bool:
    stripped = ref.strip()
    return (
        stripped.startswith(EXTERNAL_PREFIXES)
        or stripped.startswith("//")
        or urlsplit(stripped).scheme in {"http", "https", "mailto", "tel"}
    )


def unique_preserve_order(items: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        result.append(item)
    return result


def collect_html_names(root: Path, html_names: list[str] | None, offline_reader: str | None, check_all_html: bool) -> list[str]:
    names = list(html_names) if html_names else ["offline_index.html"]
    if offline_reader:
        names.append(offline_reader)
    if check_all_html:
        names.extend(path.name for path in sorted(root.glob("*.html")))
        names.extend(path.name for path in sorted(root.glob("*.htm")))
    return unique_preserve_order(names)


def iter_doc_files(root: Path, html_names: list[str]) -> list[Path]:
    files = list(root.glob("*.md"))
    for html_name in html_names:
        path = root / html_name
        if path.exists():
            files.append(path)
    return sorted(files)


def check_local_refs(root: Path, html_names: list[str]) -> list[str]:
    errors: list[str] = []
    checked = 0
    for path in iter_doc_files(root, html_names):
        text = path.read_text(encoding="utf-8")
        refs = HTML_REF_RE.findall(text) if path.suffix.lower() in {".html", ".htm"} else MD_LINK_RE.findall(text)
        for raw in refs:
            ref = normalize_markdown_ref(raw)
            if not is_checkable_local_file(ref):
                continue
            checked += 1
            target = (path.parent / ref).resolve()
            if not target.exists():
                errors.append(f"missing local ref: {path.relative_to(root)} -> {raw} -> {target}")
    print(f"checked_local_refs={checked}")
    return errors


def slugify_heading(title: str) -> str:
    text = html.unescape(title.strip())
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"[*_~]", "", text)
    text = text.lower()
    text = re.sub(r"[^\w가-힣 -]", "", text)
    text = re.sub(r"\s+", "-", text.strip())
    text = re.sub(r"-+", "-", text)
    return text


def collect_markdown_anchors(path: Path) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = HEADING_RE.match(line)
        if not match:
            continue
        base = slugify_heading(match.group(2))
        if not base:
            continue
        count = counts.get(base, 0)
        counts[base] = count + 1
        anchors.add(base if count == 0 else f"{base}-{count}")
    return anchors


def collect_html_anchors(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    anchors = {html.unescape(match) for match in HTML_ID_RE.findall(text)}
    heading_re = re.compile(r"<h[1-6][^>]*>(.*?)</h[1-6]>", re.IGNORECASE | re.DOTALL)
    counts: dict[str, int] = {}
    for raw_heading in heading_re.findall(text):
        base = slugify_heading(raw_heading)
        if not base:
            continue
        count = counts.get(base, 0)
        counts[base] = count + 1
        anchors.add(base if count == 0 else f"{base}-{count}")
    return anchors


def collect_anchors(path: Path) -> set[str]:
    suffix = path.suffix.lower()
    if suffix == ".md":
        return collect_markdown_anchors(path)
    if suffix in {".html", ".htm"}:
        return collect_html_anchors(path)
    return set()


def check_anchor_refs(root: Path, html_names: list[str], check_anchors: bool) -> list[str]:
    if not check_anchors:
        return []
    errors: list[str] = []
    anchor_cache: dict[Path, set[str]] = {}
    for path in iter_doc_files(root, html_names):
        text = path.read_text(encoding="utf-8")
        refs = HTML_REF_RE.findall(text) if path.suffix.lower() in {".html", ".htm"} else MD_LINK_RE.findall(text)
        for raw in refs:
            ref_path, fragment = normalize_ref_with_fragment(raw)
            if not fragment or is_external_ref(raw):
                continue
            if not ref_path:
                target = path.resolve()
            else:
                if not is_checkable_local_file(ref_path):
                    continue
                target = (path.parent / ref_path).resolve()
            if not target.exists():
                continue
            if target not in anchor_cache:
                anchor_cache[target] = collect_anchors(target)
            if fragment not in anchor_cache[target]:
                rel_source = path.relative_to(root)
                rel_target = target.relative_to(root) if target.is_relative_to(root) else target
                errors.append(f"missing anchor ref: {rel_source} -> {raw} -> {rel_target}#{fragment}")
    return errors


def check_offline_html(root: Path, html_names: list[str]) -> list[str]:
    errors: list[str] = []
    for html_name in html_names:
        path = root / html_name
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        for lineno, line in enumerate(text.splitlines(), start=1):
            if HTML_NETWORK_RE.search(line) or ANALYTICS_RE.search(line):
                errors.append(
                    f"offline html external/script dependency: {html_name}:{lineno}: {line[:160]}"
                )
    return errors


def check_required_files(root: Path, required: list[str]) -> list[str]:
    return [f"missing required file: {item}" for item in required if not (root / item).exists()]


def check_reader_build_script(root: Path, reader_build_script: str | None, require_reader_build_script: bool) -> list[str]:
    if not reader_build_script:
        if require_reader_build_script:
            reader_build_script = "scripts/build_offline_reader.sh"
        else:
            return []
    errors: list[str] = []
    path = root / reader_build_script
    if not path.exists():
        errors.append(f"missing reader build script: {reader_build_script}")
        return errors
    if not path.is_file():
        errors.append(f"reader build script is not a file: {reader_build_script}")
        return errors
    try:
        first_line = path.read_text(encoding="utf-8", errors="ignore").splitlines()[0]
    except IndexError:
        first_line = ""
    if path.suffix == ".sh" and not first_line.startswith("#!"):
        errors.append(f"reader build script missing shebang: {reader_build_script}")
    return errors


def check_expected_figures(root: Path, html_names: list[str], figures: list[str]) -> list[str]:
    errors: list[str] = []
    docs = "\n".join(p.read_text(encoding="utf-8") for p in iter_doc_files(root, html_names))
    for fig in figures:
        path = root / fig
        if not path.exists():
            errors.append(f"missing expected figure: {fig}")
        if fig not in docs:
            errors.append(f"expected figure is not referenced: {fig}")
    return errors


def check_forbidden_patterns(root: Path, patterns: list[str]) -> list[str]:
    errors: list[str] = []
    files = list(root.glob("*.md")) + list(root.glob("*.html"))
    for pattern in patterns:
        regex = re.compile(pattern)
        for path in files:
            for lineno, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
                if regex.search(line):
                    errors.append(f"forbidden pattern {pattern!r}: {path.relative_to(root)}:{lineno}: {line[:160]}")
    return errors


def normalize_heading(title: str) -> str:
    text = re.sub(r"`([^`]*)`", r"\1", title)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = re.sub(r"^[\d.\s#_-]+", "", text.strip())
    text = re.sub(r"[^\w가-힣]+", " ", text.lower())
    return " ".join(text.split())


def is_answer_doc(path: Path) -> bool:
    return bool(ANSWER_DOC_NAME_RE.search(path.name))


def check_worksheet_presence(root: Path, expect_worksheet: bool, worksheet_files: list[str]) -> list[str]:
    errors = check_required_files(root, worksheet_files)
    if not expect_worksheet:
        return errors
    if worksheet_files:
        return errors
    candidates = [
        path
        for path in root.glob("*")
        if path.is_file() and path.suffix.lower() in {".md", ".html", ".htm"}
        and WORKSHEET_NAME_RE.search(path.name)
    ]
    if not candidates:
        errors.append("missing worksheet: no top-level worksheet/applied/practice note found")
    return errors


def collect_section_text(lines: list[str], start_index: int, heading_level: int) -> str:
    body: list[str] = []
    for line in lines[start_index + 1 :]:
        match = HEADING_RE.match(line)
        if match and len(match.group(1)) <= heading_level:
            break
        body.append(line)
    return "\n".join(body)


def check_answer_coverage(root: Path, require_answer_coverage: bool, answer_docs: list[str]) -> list[str]:
    if not require_answer_coverage:
        return []

    errors: list[str] = []
    explicit_docs = [root / item for item in answer_docs]
    errors.extend(f"missing answer doc: {item}" for item in answer_docs if not (root / item).exists())
    discovered_docs = [path for path in root.glob("*.md") if is_answer_doc(path)]
    answer_paths = sorted({path.resolve() for path in explicit_docs if path.exists()} | {path.resolve() for path in discovered_docs})
    if not answer_paths:
        return ["missing answer coverage: no answer/solution/worked-solution markdown file found"]

    answer_headings: set[str] = set()
    for answer_path in answer_paths:
        for line in answer_path.read_text(encoding="utf-8").splitlines():
            match = HEADING_RE.match(line)
            if match:
                answer_headings.add(normalize_heading(match.group(2)))

    for path in sorted(root.glob("*.md")):
        if path.resolve() in answer_paths:
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            match = HEADING_RE.match(line)
            if not match:
                continue
            title = match.group(2)
            if not CHECK_SECTION_RE.search(title):
                continue
            normalized = normalize_heading(title)
            section_text = collect_section_text(lines, index, len(match.group(1)))
            linked_targets = [
                normalize_markdown_ref(raw)
                for raw in MD_LINK_RE.findall(section_text)
            ]
            has_answer_link = any(ANSWER_TARGET_RE.search(target) for target in linked_targets)
            has_exact_heading = normalized in answer_headings
            has_explicit_mapping = bool(
                re.search(r"answer[- ]?key|정답|답안|풀이|worked solution|worked-solution", section_text, re.IGNORECASE)
                and linked_targets
            )
            if not (has_answer_link or has_exact_heading or has_explicit_mapping):
                errors.append(
                    f"missing answer mapping: {path.relative_to(root)}:{index + 1}: {title}"
                )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path, help="study pack root directory")
    parser.add_argument("--required-file", action="append", default=[], help="relative file that must exist")
    parser.add_argument("--expect-figure", action="append", default=[], help="relative figure path that must exist and be referenced")
    parser.add_argument("--forbid", action="append", default=[], help="regex pattern that must not appear in top-level md/html")
    parser.add_argument("--offline-html", action="append", default=None, help="offline HTML filename to check; may be repeated; defaults to offline_index.html")
    parser.add_argument("--offline-reader", help="compiled offline reader HTML that must exist and be checked")
    parser.add_argument("--reader-build-script", help="relative script path used to build the offline reader; validates presence and basic shell-script hygiene")
    parser.add_argument("--require-reader-build-script", action="store_true", help="require scripts/build_offline_reader.sh unless --reader-build-script is provided")
    parser.add_argument("--check-all-html", action="store_true", help="check every top-level .html/.htm file for local refs and offline dependency hygiene")
    parser.add_argument("--check-anchors", action="store_true", help="validate local Markdown/HTML #fragment links against headings or HTML id/name attributes")
    parser.add_argument("--expect-worksheet", action="store_true", help="require a top-level worksheet/applied/practice note")
    parser.add_argument("--worksheet-file", action="append", default=[], help="relative worksheet file that must exist")
    parser.add_argument("--require-answer-coverage", action="store_true", help="require self-check/checklist sections to map to answer or worked-solution material")
    parser.add_argument("--answer-doc", action="append", default=[], help="relative answer-key or worked-solution markdown file; may be repeated")
    args = parser.parse_args()

    root = args.root.resolve()
    if not root.exists() or not root.is_dir():
        print(f"not a directory: {root}", file=sys.stderr)
        return 2

    html_names = collect_html_names(root, args.offline_html, args.offline_reader, args.check_all_html)
    required_files = list(args.required_file)
    if args.offline_reader:
        required_files.append(args.offline_reader)
    required_files.extend(args.worksheet_file)

    errors: list[str] = []
    errors.extend(check_required_files(root, required_files))
    errors.extend(check_local_refs(root, html_names))
    errors.extend(check_anchor_refs(root, html_names, args.check_anchors))
    errors.extend(check_offline_html(root, html_names))
    errors.extend(check_expected_figures(root, html_names, args.expect_figure))
    errors.extend(check_forbidden_patterns(root, args.forbid))
    errors.extend(check_worksheet_presence(root, args.expect_worksheet, args.worksheet_file))
    errors.extend(check_answer_coverage(root, args.require_answer_coverage, args.answer_doc))
    errors.extend(check_reader_build_script(root, args.reader_build_script, args.require_reader_build_script))

    if errors:
        print("FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
