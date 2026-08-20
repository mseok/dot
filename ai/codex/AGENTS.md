# Working principles

- Store analysis work, experiment outputs, reports, visualizations, logs, checkpoints, and other generated artifacts outside the source checkout in a repository-specific artifact root. Keep only production code and lightweight, version-controlled reproducibility metadata in the source repository.
- Before writing to a repository-specific artifact root, add that exact path to `$CODEX_HOME/config.toml` under `sandbox_workspace_write.writable_roots`. For this storage, use `/mnt/parallel_storage/wykim_lab/icl_mseok/artifacts/<repository-name>` unless the project defines a different artifact root.
- Do not create analysis-result directories, generated reports, experiment logs, or transient worktrees inside a source checkout. Existing active jobs may retain a compatibility symlink into the external artifact root until they complete.
- Keep execution and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.

## Python and CUDA environments

- CUDA 12.8 (`cu128`) is the workspace invariant. Never install, resolve, or recreate an environment with CUDA 13 (`cu13`) artifacts. When a dependency provides CUDA build variants, select `cu128`; if that is unavailable, stop and ask rather than falling back to `cu13`.
- Do not delete or recreate a repository `.venv`, lockfile, or shared package cache as the first response to a Python or `uv` environment issue. First inspect the expected Python and `uv` versions, `pyproject.toml`, lockfile state, and the active interpreter.
- Recreating a `.venv`, changing a lockfile, or deleting a shared package cache requires a diagnosed cause, exact targets, and explicit user approval.
- For Ruff formatting and linting, use `/mnt/parallel_storage/wykim_lab/icl_mseok/appl/bin/ruff` only. Do not use `uv run ruff` or a project-local Ruff executable. For routine tests, prefer an existing project venv executable such as `.venv/bin/python -m pytest` over `uv run`.
- Treat a shared UV cache read-only or lock error as an environmental block, not a reason to request privileged execution. Use the shared Ruff binary for formatter/linter work and make at most one direct-project-venv fallback for a test; if it is unavailable, report the validation as unexecuted due to the cache lock and stop. Do not narrate or repeat cache-retry attempts.
- Use a node-local `UV_CACHE_DIR` only for an explicitly approved environment repair, install, or sync; never create one merely to run routine formatting, linting, or a short test.
- If an explicitly run validation command fails, do not present that validation as passed or omit the failure from the final report. State whether it is an environment issue, a pre-existing failure, or an unresolved regression.

## Slurm escalation and monitoring

- Do not choose Slurm merely because it is available. For debugging, short tests, metadata inspection, and proxy measurements, use the current safe allocation or direct command when adequate; do not escalate them into full inference, a sweep, or a queued job without a concrete reason.
- Before launching, cancelling, or replacing a Slurm job, restate the exact requested shape: nodes, GPUs per node, total GPUs, CPUs per task, partition, time limit, and array/chunk layout. Do not reinterpret “N GPU nodes” as “N GPUs”.
- For an ordinary one-process-per-GPU workload, request GPU-first minimal resources: one task and four CPUs per GPU by default, with no node-wide memory reservation. Do not request `--exclusive`, 24 CPUs/GPU, 192 CPUs/node, or large `--mem` values unless the workload has an evidenced CPU, dataloader, preprocessing, or RAM requirement.
- Make scheduler availability claims only from fresh, scoped scheduler evidence. Do not cancel or replace an existing job without the user's explicit authorization for the exact job ID.
- During debugging or short tests, use waits or sleeps of 10 seconds or less. Use a longer bounded monitoring interval only when the user explicitly asks to monitor, wait, or babysit; prefer scheduler-aware polling over blind sleep.
- Disable runtime compilation (for example, `torch.compile`) for debugging and short tests. Enable it for result-producing or benchmark runs when supported, and record the compilation mode; do not silently change it between compared runs.

## Research and experiment work

- Treat a request framed as analysis, comparison, diagnosis, or research as read-only unless the user also explicitly asks to implement, launch, or create an artifact.
- Before claiming two runs are comparable, verify the checkpoint, commit, config, data split, batch size, world size, seed, and evaluation protocol. Label every mismatch before interpreting results.
- In experimental reports, distinguish observed results from plans. State the numerator, denominator, coverage, remaining failures, and the exact evidence source.
- For a proposed experiment, lead with the hypothesis, the smallest discriminating test, the matched baseline, the expected decision criterion, and the next escalation only if the result warrants it.

- For durable or comparable experiments—not short checks or disposable debugging—run from committed source and use the `experiment-ledger` skill to record the hypothesis, core pseudocode, execution, artifacts, and result.
- Use the current checkout by default. Before a durable experiment records `HEAD` as its source commit, require a clean index and tracked working tree and no execution-affecting untracked repository file. Preserve unrelated files; never alter them or create a worktree solely to satisfy cleanliness, and ask the user if unrelated tracked changes block the launch.
