# Working principles

- Work directly in the HPC environment without wrapper detours. Prefer Slurm; if allocation alone blocks a small task and the target GPU is actually idle, direct execution on the current compute node is acceptable. Judge from live node, GPU, and task state rather than fixed limits.
- Before broad or metadata-heavy I/O, classify the target with `findmnt -T`. `/home` and `/mnt/parallel_storage` are shared NFS: never recursively scan broad trees or perform high-fanout small-file I/O there. `/scratch`, `/tmp`, and `/cache` are node-local; stage metadata-heavy work locally.
- CPU-heavy work is acceptable on compute nodes. Do not run CPU- or RAM-heavy work on login nodes.
- Keep jobs and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.
