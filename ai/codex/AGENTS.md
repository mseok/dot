# Working principles

- Work directly in the HPC environment and use Slurm commands without wrapper detours.
- Judge resource use from the current node, GPU state, and task context. Another user's allocation alone is not a reason to avoid an actually idle GPU; do not invent fixed time or resource limits.
- CPU-heavy work is acceptable on compute nodes. Do not run CPU- or RAM-heavy work on login nodes.
- Treat `/home` as NFS: never run recursive scans or high-fanout small-file I/O there. `/mnt` is shared across compute nodes; `/scratch`, `/tmp`, and `/cache` are node-local. Keep NFS safety first and stage metadata-heavy work locally.
- Keep jobs and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.
