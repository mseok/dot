---
name: init-environment
description: Inspect and minimally initialize or refresh Codex for the current HPC node. Use when the user asks to initialize, refresh, or diagnose the Codex HPC environment, storage topology, Slurm access, or shell permissions; do not use for ordinary coding work.
---

# Initialize the HPC environment

Keep the setup minimal. Start with read-only discovery, and change durable configuration only when the user asks to initialize or refresh it.

## Discover the current environment

1. Identify the node with `hostname`.
2. Use targeted `findmnt -T` queries for the working path, `/home`, `/mnt/parallel_storage`, `/scratch`, `/tmp`, and `/cache`. Do not discover storage with recursive filesystem scans.
3. Check Slurm directly with `scontrol ping`, `scontrol show node <hostname>`, `sinfo`, and a node-bounded `squeue`. Use a bounded `sacct` query only when accounting evidence is relevant. On a compute node, if local `sacct` fails because `AccountingStorageHost=localhost` while `slurmdbd` is on `master`, use the exact fallback `ssh -o BatchMode=yes master sacct ...` and do not retry locally.
4. On a GPU node, inspect devices with a concise `nvidia-smi` query. If it fails once, report the failure instead of retrying blindly.
5. Classify login versus compute nodes from scheduler evidence. If the evidence is incomplete, say that the node type is unknown rather than guessing.

Treat scheduler allocation and physical usage as different facts. Compare Slurm state with live CPU, memory, GPU process, GPU memory, and utilization evidence. Another user's allocation is not by itself evidence that a GPU is busy.

Prefer Slurm for execution. If Slurm rejects a task only because another allocation owns the current compute node, recheck the target GPU immediately before launch. When it is actually idle and the task is small enough by contextual judgment, direct execution is allowed; pin the exact device with `CUDA_VISIBLE_DEVICES`. Do not invent fixed time, memory, or utilization thresholds.

## Protect shared storage

- Treat `/home` and `/mnt/parallel_storage` as NFS on the current cluster.
- Never run broad recursive `find`, `grep`, or `rg`, or high-fanout small-file reads and writes, on NFS.
- Stage metadata-heavy work in a suitable node-local location such as `/scratch`, `/tmp`, or `/cache`, then copy back compact results.
- Remember that node-local files are not visible to other compute nodes. Put multi-node job inputs on shared storage or use an inline scheduler submission such as `sbatch --wrap`.
- Record filesystem type and sharing topology, not sandbox-specific read-only mount flags.

## Keep the harness small

- Keep only stable principles in the global `AGENTS.md`.
- Keep scheduler and GPU shell permissions in one rules file.
- Do not add hooks, wrappers, tracking, persistent snapshots, or extra validation without an observed need.
- Do not inspect authentication data, sessions, memories, archived data, environment secrets, or earlier harness material.
- For work in an existing codebase, preserve its validation and error-handling style.

Report only the node classification, mount classification, relevant scheduler and GPU state, configuration changes, and unresolved facts. Do not launch smoke tests or compute jobs solely to validate this skill.
