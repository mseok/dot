---
name: gov-rnd-report-writer
description: >
  Draft and revise Korean government R&D result reports, stage reports,
  mid-term evaluation writeups, and related official project-report sections.
  Use when Codex must write or polish government-submitted prose from project
  plans, evaluation rubrics, writing guides, benchmark tables, prior reports,
  or service/product evidence; especially when the document must align with
  section-specific writing instructions and evaluation criteria, avoid
  AI-sounding repetition, and read like a formal Korean report rather than a
  blog post or generic summary.
---

# Gov R&D Report Writer

## Overview

Write Korean government R&D reports as evaluation-facing official documents.
Treat each section as a constrained writing task defined by its writing guide,
evaluation criteria, and available evidence, not as a free-form summary.

## Core Workflow

### 1. Fix the document role first

Identify the exact document type and section role before drafting.

- Distinguish among `사업 추진 상세내용`, `추진실적 및 성과`, `결과활용 및 확산계획`,
  `성과지표`, `중간산출물`, `시장성/파급효과` and similar headings.
- Read the local writing guide or template language literally.
- Infer what the reviewer is expected to judge from that section.

If the section instruction says to cover development, utilization, validation,
and expansion, the draft must reflect those axes in its paragraph structure.

### 2. Build a section contract from source documents

Before writing, extract four things:

- `section role`: what this section is supposed to do
- `evaluation hooks`: what a reviewer will reward in this section
- `hard evidence`: facts that can be supported from plans, reports, tables,
  benchmarks, product status, or service plans
- `forbidden moves`: unsupported claims, blog tone, inflated marketing, or
  generic AI filler

Use the project plan as the baseline commitment document. Then connect current
results back to that baseline with concrete implementation, verification, and
downstream use or expansion language where the section requires it.

If the source is an HWP that cannot be parsed reliably, request or use a PDF
conversion first.

### 3. Draft in evaluation-facing order

Write paragraphs in the order that makes evaluation easiest.

Default order:

1. State the problem or section objective.
2. State what was designed, built, or organized.
3. State how it was used, integrated, or prepared for use.
4. State how it was checked or compared.
5. State why this matters for subsequent deployment, adoption, or expansion.

Do not force all five steps into every section. Use only the steps that match
the writing guide for that section.

### 4. Keep claims tied to evidence

Every strong claim should be traceable to something in the provided material.

- Prefer `구축하였다`, `정리하였다`, `도입하였다`, `확인하였다`, `연계하였다`,
  `적용하였다` when the evidence supports implementation or integration.
- Prefer `가능성을 보였다`, `기반을 마련하였다`, `확장 가능성을 확보하였다` when
  the evidence supports readiness rather than completed deployment.
- Do not imply nationwide adoption, production deployment, or regulatory
  acceptance unless the materials actually support it.

### 5. Run an anti-AI polish pass

After drafting, rewrite anything that sounds like a generic AI summary.

Always remove or compress:

- repetitive rhythm such as `~때도, ~때도, ~때도`
- padded emphasis such as `핵심은 ...이다` used repeatedly
- blog-style transitions such as `이런 점에서`, `다시 말해`, `쉽게 말해`
- empty contrast frames such as `단순히 A가 아니라 B`
  when they do not add new information
- conclusion sentences that merely restate the previous sentence

Rewrite toward denser, report-style Korean:

- prefer nominalized official phrasing over conversational cadence
- prefer one firm claim plus mechanism over three parallel clauses
- name the comparison axis explicitly
- end paragraphs with what was secured, reflected, or enabled

For rewrite patterns and banned rhythms, read
`references/style-rules.md`.

### 6. Run a section-specific validation pass

Before finalizing, verify:

- the section matches the writing guide, not just the topic
- the evaluation criteria are visible in the prose even if not named explicitly
- the argument does not outrun the evidence
- the tone is formal Korean report prose
- repeated phrases or mirrored paragraph openings are minimized

For section mapping rules, read `references/section-mapping.md`.
For a final checklist, read `references/report-checklist.md`.

## Tone Rules

- Write in formal Korean suitable for government submission.
- Prefer firm, impersonal report prose over conversational explanation.
- Keep English technical terms only where they are standard and necessary.
- Explain technical terms on first use when the evaluator may be non-specialist.
- Make evaluation easy without sounding like you are speaking to the rubric.

## Output Modes

Choose one of these based on the user request:

- `direct section prose`: final paragraphs ready to paste into the report
- `rewrite pass`: revise an existing section while preserving facts
- `section contract + draft`: when the section is ambiguous or politically
  sensitive and the reasoning should be made explicit first

Default to `direct section prose` unless the user asks for planning or review.

## Resources

- `references/style-rules.md`
  Use for anti-pattern removal and formal rewrite patterns.
- `references/section-mapping.md`
  Use for mapping section type to paragraph roles and evidence placement.
- `references/report-checklist.md`
  Use for the final validation pass before presenting text to the user.
