---
name: modular-python-deep-learning
description: >
  Use when the user wants to write, refactor, or modularize deep learning
  research code in Python (PyTorch/JAX): split monolithic train/eval scripts
  into importable modules, define explicit tensor-shape and I/O contracts, clean
  up configs and public APIs, separate pure compute from side effects, add
  smoke-test hooks, and prepare HPC-friendly handoffs without implying local
  training or inference.
---

# Modular Python for Deep Learning

Follow this workflow whenever writing or refactoring deep learning research code.

## 0) Adopt the operating principles

- Read and apply `references/karpathy_guidelines.md` before making changes.
- Default to Pythonic code: explicit, readable, minimal magic. Read `references/python_philosophy.md` when unsure.

## 1) Clarify the contract (before coding)

- Restate the goal in 1–2 sentences.
- Specify the I/O contract in concrete terms:
  - Data source and preprocessing assumptions
  - Tensor shapes, dtypes, units, and device placement
  - Metrics and success criteria
  - Performance constraints (memory, speed, batch size)
- Identify “must not change” interfaces (CLI args, checkpoint format, metrics names, log schema).

## 2) Choose module boundaries that match the contract

- Separate **pure compute** from **I/O and side effects**.
- Keep imports side-effect free (no hidden global initialization at import time).
- Prefer a small number of obvious modules over a large web of micro-files.
- Use `references/dl_modular_layout.md` as the default decomposition template.

## 3) Design small, testable APIs

- Prefer functions over classes until state is clearly necessary.
- Pass dependencies explicitly (model, tokenizer, config, device, RNG); avoid global singletons.
- Use `@dataclass(frozen=True)` configs for immutable experiment settings.
- Add type hints and shape comments/docstrings at module boundaries.
- Make failure modes explicit (raise informative exceptions early).

## 4) Implement with “simplicity first”

- Make the smallest change that solves the goal.
- Avoid framework upgrades or architectural rewrites unless required.
- Do not create a “mega-utils.py” dumping ground; create domain-named modules instead.
- Prefer standard library building blocks (`pathlib`, `logging`, `argparse`) unless the user asked for a specific stack.

## 5) Add verification hooks (without pretending to run them)

- Add or update a **CPU smoke test path** (tiny batch, 1–2 steps) for shape + loss sanity.
- Add narrow unit tests for pure functions (tokenization, featurization, losses, metrics).
- Provide exact run commands and what to check in outputs.

If the user mentions remote HPC/Slurm:

- Provide a Slurm script snippet and the expected artifacts (checkpoints, logs, metrics files).
- Provide a short checklist for what to verify on the cluster (first-batch time, GPU util, NaNs, determinism).

## 6) Produce a clean handoff

- Summarize module responsibilities and public entrypoints.
- Document any new CLI flags/config fields and defaults.
- Call out any intentional behavior changes and migration notes (checkpoint compatibility, metric name changes).
