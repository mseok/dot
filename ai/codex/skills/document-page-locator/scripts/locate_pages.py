#!/usr/bin/env python3
"""Locate pages in a page-based document that match one or more queries."""

from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path


TOKEN_RE = re.compile(r"[0-9A-Za-z가-힣_./+-]+")


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().casefold()


def tokenize(text: str) -> list[str]:
    return [token for token in TOKEN_RE.findall(text.casefold()) if len(token) >= 2]


def split_pages(raw_text: str) -> list[str]:
    pages = raw_text.split("\f")
    if pages and not pages[-1].strip():
        pages.pop()
    return pages


def extract_pdf_pages(path: Path) -> list[str]:
    if shutil.which("pdftotext"):
        proc = subprocess.run(
            ["pdftotext", "-layout", str(path), "-"],
            check=True,
            capture_output=True,
            text=True,
        )
        return split_pages(proc.stdout)

    try:
        from pypdf import PdfReader
    except ImportError as exc:
        raise RuntimeError(
            "pdftotext is not installed and pypdf is unavailable. Install one of them."
        ) from exc

    reader = PdfReader(str(path))
    return [(page.extract_text() or "") for page in reader.pages]


def extract_pages(path: Path) -> list[str]:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return extract_pdf_pages(path)
    if suffix in {".txt", ".md"}:
        return [path.read_text(encoding="utf-8")]
    raise RuntimeError(f"Unsupported file type: {suffix}")


def query_threshold(tokens: list[str]) -> int:
    if not tokens:
        return 0
    if len(tokens) == 1:
        return 1
    return max(2, math.ceil(len(tokens) * 0.6))


def collect_snippets(
    lines: list[str],
    query_specs: list[dict[str, object]],
    context_lines: int,
    max_snippets: int,
) -> list[str]:
    snippets: list[str] = []
    seen_ranges: set[tuple[int, int]] = set()

    for idx, line in enumerate(lines):
        normalized_line = normalize(line)
        if not normalized_line:
            continue

        line_hit = False
        for spec in query_specs:
            qnorm = spec["normalized"]
            qtokens = spec["tokens"]
            threshold = spec["threshold"]

            if qnorm and qnorm in normalized_line:
                line_hit = True
                break

            token_hits = [token for token in qtokens if token in normalized_line]
            if len(token_hits) >= threshold:
                line_hit = True
                break

        if not line_hit:
            continue

        start = max(0, idx - context_lines)
        end = min(len(lines), idx + context_lines + 1)
        page_range = (start, end)
        if page_range in seen_ranges:
            continue
        seen_ranges.add(page_range)

        snippet = " / ".join(part.strip() for part in lines[start:end] if part.strip())
        if snippet:
            snippets.append(snippet)

        if len(snippets) >= max_snippets:
            break

    return snippets


def search_page(
    page_number: int,
    page_text: str,
    query_specs: list[dict[str, object]],
    context_lines: int,
    max_snippets: int,
) -> dict[str, object] | None:
    normalized_page = normalize(page_text)
    if not normalized_page:
        return None

    score = 0
    matched_queries: list[dict[str, object]] = []

    for spec in query_specs:
        query = spec["query"]
        qnorm = spec["normalized"]
        qtokens = spec["tokens"]
        threshold = spec["threshold"]

        exact_hits = normalized_page.count(qnorm) if qnorm else 0
        token_hits = [token for token in qtokens if token in normalized_page]

        if exact_hits > 0:
            query_score = exact_hits * 20 + len(token_hits) * 3
            mode = "exact"
        elif len(token_hits) >= threshold:
            query_score = len(token_hits) * 4
            mode = "token"
        else:
            continue

        score += query_score
        matched_queries.append(
            {
                "query": query,
                "mode": mode,
                "exact_hits": exact_hits,
                "token_hits": token_hits,
                "score": query_score,
            }
        )

    if not matched_queries:
        return None

    lines = page_text.splitlines()
    snippets = collect_snippets(lines, query_specs, context_lines, max_snippets)

    return {
        "page": page_number,
        "score": score,
        "matched_queries": matched_queries,
        "snippets": snippets,
    }


def make_query_specs(queries: list[str]) -> list[dict[str, object]]:
    specs = []
    for query in queries:
        tokens = tokenize(query)
        specs.append(
            {
                "query": query,
                "normalized": normalize(query),
                "tokens": tokens,
                "threshold": query_threshold(tokens),
            }
        )
    return specs


def format_text_output(path: Path, results: list[dict[str, object]], page_count: int) -> str:
    lines = [f"FILE {path}", f"PAGES {page_count}", f"RESULTS {len(results)}", ""]

    for result in results:
        lines.append(
            f"PAGE {result['page']} | score={result['score']} | matched={len(result['matched_queries'])}"
        )
        for matched in result["matched_queries"]:
            token_hits = ", ".join(matched["token_hits"]) or "-"
            lines.append(
                "  "
                + f"{matched['mode']}: {matched['query']} | exact_hits={matched['exact_hits']} | tokens={token_hits}"
            )
        for idx, snippet in enumerate(result["snippets"], start=1):
            lines.append(f"  snippet {idx}: {snippet}")
        lines.append("")

    if not results:
        lines.append("No matching pages found.")

    return "\n".join(lines).rstrip() + "\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Locate pages relevant to one or more queries in a PDF."
    )
    parser.add_argument("document", help="Path to a PDF, TXT, or Markdown file.")
    parser.add_argument(
        "--query",
        action="append",
        dest="queries",
        required=True,
        help="Query string. Repeat for multiple keyword variants.",
    )
    parser.add_argument(
        "--top-k",
        type=int,
        default=8,
        help="Maximum number of result pages to return.",
    )
    parser.add_argument(
        "--context-lines",
        type=int,
        default=1,
        help="Number of surrounding lines to include in snippets.",
    )
    parser.add_argument(
        "--max-snippets",
        type=int,
        default=3,
        help="Maximum snippets to emit per page.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="Output format.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    path = Path(args.document).expanduser().resolve()

    if not path.exists():
        print(f"Document not found: {path}", file=sys.stderr)
        return 1

    try:
        pages = extract_pages(path)
    except Exception as exc:  # pragma: no cover - simple CLI error path
        print(f"Failed to extract text: {exc}", file=sys.stderr)
        return 1

    query_specs = make_query_specs(args.queries)
    results: list[dict[str, object]] = []

    for page_number, page_text in enumerate(pages, start=1):
        result = search_page(
            page_number,
            page_text,
            query_specs,
            args.context_lines,
            args.max_snippets,
        )
        if result is not None:
            results.append(result)

    results.sort(key=lambda item: (-int(item["score"]), int(item["page"])))
    results = results[: args.top_k]

    if args.format == "json":
        payload = {
            "file": str(path),
            "page_count": len(pages),
            "queries": args.queries,
            "results": results,
        }
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(format_text_output(path, results, len(pages)), end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
