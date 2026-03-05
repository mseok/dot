# Karpathy-style coding guidelines (required)

This reference is derived from the repository `forrestchang/andrej-karpathy-skills` (MIT). Use it as an execution policy when writing or refactoring code with an LLM.

Source: https://github.com/forrestchang/andrej-karpathy-skills

## The 4 principles (apply in order)

### 1) Think before coding

- Restate the task and constraints.
- Identify what is already implemented and what must stay stable.
- Plan the smallest set of edits that achieves the goal.
- Confirm edge cases and failure modes (shapes, dtype, device, NaNs, padding/masking, distributed behavior).

### 2) Simplicity first

- Prefer the simplest working solution over clever abstractions.
- Avoid adding dependencies, new frameworks, or meta-programming unless explicitly requested.
- Prefer straightforward data structures and explicit control flow.

### 3) Surgical changes

- Minimize diff size and surface area.
- Edit the fewest files necessary.
- Preserve existing public APIs unless the user explicitly wants a breaking change.

### 4) Goal-driven execution

- Define “done” in measurable terms (tests pass, metrics computed, output format stable, CLI unchanged).
- Verify the change with the narrowest possible checks (import, smoke run, shape test, small unit test).
- Stop once the goal is achieved; do not gold-plate.

## How to apply these principles in deep learning code

- Treat **tensor shapes** as an API: document them at module boundaries and validate early.
- Keep the **training loop** readable and linear; push complexity into small pure helpers.
- Keep **I/O and side effects** (filesystem, logging, distributed init) at the edges (entrypoints).
- Make **reproducibility** explicit: config snapshot, seed handling, deterministic toggles, exact output locations.
- Prefer “one obvious path” for running: a single CLI entrypoint with a stable config schema.

