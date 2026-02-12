---
author:
venue:
year:
url:
doi:
arxiv:
code:
keywords:
categories:
  - "[[Papers]]"
aliases:
---

## TL;DR
[2-5 sentences. What problem, what is the core idea, what is the headline result, what should I remember?]

## One-line contributions
1. [Contribution 1]
2. [Contribution 2]
3. [Contribution 3]

## Problem setup
- **Task**: [What is being predicted/optimized?]
- **Inputs/outputs**: [Notation and shapes]
- **Assumptions**: [Data, constraints, priors]
- **Why now / what breaks without this**: [Failure mode or gap]

## Method (high-level)
[Explain the pipeline in 5-10 lines. Include a minimal diagram in text if helpful.]

## Method (details)
### Key components
- [Module A: what it does, equations, design choices]
- [Module B: ...]

### Training / optimization
- **Objective**: [Losses, regularizers]
- **Data**: [Datasets, preprocessing]
- **Compute**: [GPU/TPU, steps, batch size]
- **Hyperparameters**: [Key ones only]

## Metrics (math + meaning)
For every metric used in Methods/Results, write:
1) the mathematical definition, 2) how it is computed in this paper, and 3) what it means (and common pitfalls).

### Metric: [Name]
- **Definition**:
  $$[Put the formula here]$$
- **How computed here**:
  - [Averaging: per-sample / per-class / micro vs macro]
  - [Thresholds, matching rules, postprocessing]
  - [Confidence intervals / seeds / repeats]
- **Interpretation**:
  - [What higher/lower means]
  - [What it is sensitive to (class imbalance, scale, calibration, etc.)]
  - [Failure modes / when it can mislead]

## Experiments
### Experimental setup
- **Datasets**: [Name, size, splits]
- **Baselines**: [Strongest baselines and why they are relevant]
- **Evaluation protocol**: [Single-run vs multi-run, tuning rules]

### Main results (what matters)
- [State the key claim in plain language, then support it with the exact table/figure ref.]
- [Include absolute numbers and deltas vs baseline.]

### Ablations and analysis
- [What changes, expected outcome, what actually happens]

### Qualitative results (if any)
- [What the figure shows, what to pay attention to]

## Figures and tables (reusable)
Goal: capture the most important figures/tables so they can be re-used in other notes without re-opening the paper.

### Figures
![Fig. X: Caption](Attachments/[paper-slug]/fig-x.png)
- **Source**: Paper Figure X (page Y)
- **Why it matters**: [What conclusion it supports]
- **How to read**: [Axes, legend, key regions]

### Tables
#### Table X (paper)
- **Source**: Paper Table X (page Y)
- **Why it matters**: [What conclusion it supports]

Option A (preferred if simple): transcribe to Markdown:
| Column | Column | Column |
|---|---|---|
| ... | ... | ... |

Option B (if complex): attach as image:
![Table X](Attachments/[paper-slug]/table-x.png)

## Limitations and caveats
- [What the paper admits]
- [What the paper does not test]
- [Where the claims may not generalize]

## Reproduction notes
- **Code**: [Repo + commit]
- **Config**: [How to run]
- **Gotchas**: [Non-obvious details]

## Connections
- **Related papers/notes**: [[...]], [[...]]
- **My hypothesis**: [Mechanism-level guess]
- **What to try next**: [Concrete next action]

## Checklist
- [ ] Metrics are defined with formulas and interpreted
- [ ] Main claims are tied to specific figures/tables
- [ ] Key figures/tables are embedded from Attachments/

