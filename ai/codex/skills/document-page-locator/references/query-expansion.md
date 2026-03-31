# Query Expansion Cheatsheet

Use this file when the user's wording is conceptual and the exact phrase is
unlikely to appear in the document.

## General Pattern

Build the query set in this order:

1. Exact user phrase
2. Core nouns and noun phrases
3. Formal labels likely to appear in headings or tables
4. Broader section titles that probably contain the answer

Prefer 3-8 total queries.

## Korean Report Patterns

When the user asks a report-style question, proxy terms often work better than
the original sentence.

### Goal and progress questions

- `목표`
- `세부 목표`
- `중간 목표`
- `달성`
- `달성현황`
- `달성률`
- `목표치`
- `실적`
- `계획 대비`
- `당초`

### Execution and evidence questions

- `추진실적`
- `성과`
- `성과지표`
- `실적 근거`
- `산출물`
- `단계`
- `후속`

### Planning and roadmap questions

- `로드맵`
- `사업계획서`
- `연차`
- `1단계`
- `2단계`
- `추진 계획`

## Example

User request:

`초기 로드맵 대비 중간 목표 달성 여부`

Suggested search set:

- `초기 로드맵 대비 중간 목표 달성 여부`
- `중간 목표`
- `목표 달성`
- `달성현황`
- `달성률`
- `추진실적`
- `성과지표`
- `사업계획서`
