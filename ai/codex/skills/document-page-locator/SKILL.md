---
name: document-page-locator
description: >
  Find the pages in a PDF or other page-based document that are relevant to a
  user-provided keyword, phrase, or question. Use when the user supplies a file
  path or attachment and asks where in the document a topic is discussed, which
  pages to read for a concept, or what sections support a claim. Expand
  conceptual requests into proxy keywords, run deterministic text extraction,
  and return page numbers with matched cues and short rationale.
---

# Document Page Locator

Use this skill to turn a request such as "Which pages discuss X?" into a short
list of concrete page numbers and reasons.

## Workflow

1. Identify the document path and the user's target concept.
2. Expand the request into 3-8 search queries.
3. Run `scripts/locate_pages.py` on the document.
4. Read the top-hit pages or snippets to separate direct hits from nearby but
   inferred pages.
5. Answer with page numbers, visible section names if present, and one-line
   reasons.

## Expand The Query

Start with the exact user phrase.

If the phrase is conceptual or unlikely to appear verbatim, add proxy queries:

- Core nouns or noun phrases
- Formal report language likely to express the same concept
- Section titles, table headers, or evaluation labels
- Korean/English variants for technical terms when both may appear
- Slightly broader section cues that could contain the answer

Prefer a small, deliberate query set. Too many low-signal keywords produce noisy
pages.

For common proxy patterns, read `references/query-expansion.md`.

## Run The Script

Use the bundled script for deterministic page-level search.

```bash
python3 scripts/locate_pages.py "/path/to/file.pdf" \
  --query "초기 로드맵 대비 중간 목표 달성 여부" \
  --query "중간 목표" \
  --query "목표 달성" \
  --query "달성현황" \
  --query "달성률" \
  --query "추진실적" \
  --query "성과지표" \
  --top-k 10
```

The script:

- Uses `pdftotext -layout` when available and falls back to `pypdf`
- Scores pages by exact phrase hits plus token overlap
- Emits page numbers, scores, matched queries, and short snippets
- Supports plain text output or JSON output with `--format json`

## Interpret The Results

- Treat a page as a direct hit only when a heading, table row, or body snippet
  actually matches one of the expanded queries.
- If hits cluster in a page range, inspect neighboring pages because tables and
  explanations often continue across page boundaries.
- If a page is relevant only because it is adjacent to a direct-hit page, label
  it as inferred rather than direct.
- If text extraction is poor, say so explicitly. Do not overstate confidence for
  scanned PDFs or image-only pages.

## Output Style

Return a compact answer:

- `p.23-26`: direct hit for `성과지표`, `달성률`, `목표치(A)`, `실적(B)`
- `p.19-22`: inferred/secondary support because `중간 단계 산출물` lists the
  intermediate deliverables
- `p.30`: interpretation page explaining partial achievement and follow-up areas

When useful, add one short sentence explaining why the user should read those
pages first.

## Limits And Fallbacks

- PDF-first skill. It works best on PDFs with extractable text.
- For scanned PDFs, OCR may be required outside this skill.
- For `.hwp`, use `hwp-processor` first to extract text; page mapping may become
  approximate if the extraction does not preserve page boundaries.
- For long, concept-heavy questions, always expand the query before trusting the
  first zero-hit result.
