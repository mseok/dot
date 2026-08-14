# Working principles

- Work directly in the HPC environment without wrapper detours. Prefer Slurm; if allocation alone blocks a small task and the target GPU is actually idle, direct execution on the current compute node is acceptable. Judge from live node, GPU, and task state rather than fixed limits.
- Before broad or metadata-heavy I/O, classify the exact target with `findmnt -T`. Treat network-backed and unclassified filesystems conservatively: never recursively scan broad shared trees or perform high-fanout small-file I/O there. Stage metadata-heavy work on a confirmed node-local filesystem, and keep cross-node inputs and results on confirmed shared storage; do not infer topology from path names.
- CPU-heavy work is acceptable on compute nodes. Do not run CPU- or RAM-heavy work on login nodes.
- Keep jobs and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.
- For durable or comparable experiments—not short checks or disposable debugging—run from committed source and use the `experiment-ledger` skill to record the hypothesis, core pseudocode, execution, artifacts, and result.
