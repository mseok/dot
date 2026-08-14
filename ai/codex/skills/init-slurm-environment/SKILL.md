---
name: init-slurm-environment
description: Bootstrap or deliberately refresh a minimal Codex setup on an arbitrary Slurm cluster. Use after installing Codex or these dotfiles on a new Slurm system, after scheduler or storage topology changes, or when the user explicitly asks to reinitialize the Slurm environment. Do not use per session or for routine coding, job execution, and ordinary debugging.
---

# Initialize a Slurm environment

Run this as a one-time bootstrap or an explicit refresh. Start with read-only discovery. Do not launch a job merely to prove that the skill works.

## Discover without path or host assumptions

1. Identify the short hostname and cluster name. Check the controller with `scontrol ping`, then retain only relevant fields from `scontrol show config`, including controller, accounting, temporary-filesystem, and cluster settings.
2. Determine the current node role from Slurm evidence. Try the exact short hostname with `scontrol show node`; a matching node is a compute node. A non-match only proves that the host is not registered as a compute node. Distinguish controller, login/client, compute, and unknown instead of guessing from the hostname.
3. Inspect `sinfo` and a bounded `squeue` view. Use a bounded `sacct` query only when accounting is relevant. If local accounting fails, inspect `AccountingStorageType`, `AccountingStorageHost`, and `AccountingStoragePort` and report the configuration problem. Do not guess an SSH destination or encode a controller hostname as a fallback.
4. Identify the paths that actual work will use: the working tree, `CODEX_HOME`, user-named data, checkpoint, output, cache, and temporary paths. Run `findmnt -T` on those exact paths. If important storage roots are not yet known, inspect the mount table with `findmnt` without traversing file contents, then ask which roots matter.
5. Classify topology from evidence, not names. Network and cluster filesystems are shared candidates; block-backed filesystems and tmpfs are node-local candidates. Bind mounts and unclear sources remain unknown until resolved. Never assume that names such as `home`, `mnt`, `scratch`, `cache`, or `tmp` imply sharing or locality.
6. On a GPU node, compare Slurm GRES state with one concise `nvidia-smi` query. Treat allocation, running processes, memory use, and utilization as separate facts. If the query fails once, report it without blind retries.

Treat shared or unknown storage conservatively. Do not recursively scan broad trees or perform high-fanout small-file I/O there. Choose a confirmed node-local staging location for metadata-heavy work, and keep inputs or results that must cross nodes on confirmed shared storage.

Cross-node visibility is not proven by a path existing on the current host. Verify it only when an actual planned workflow requires the fact, using an existing allocation when possible. Do not submit a smoke job solely for environment initialization.

## Merge the minimal Codex configuration

Change durable configuration only when the user asked to initialize or refresh it. Preserve existing configuration by default.

### Add to AGENTS.md without replacing it

- Never replace the whole `$CODEX_HOME/AGENTS.md`, and never delete, reorder, or rephrase unrelated existing instructions.
- Read the exact file when it exists. Add only stable, verified facts or policies that are missing and materially useful on this Slurm system.
- Put initializer-owned additions in one bounded block:

```markdown
<!-- BEGIN init-slurm-environment -->
## Local Slurm environment

- <stable verified cluster or storage fact>
<!-- END init-slurm-environment -->
```

- If that block already exists, update only its contents. If it does not exist, append it once. If no new stable fact is needed because equivalent guidance already exists, leave the file unchanged.
- Record only stable topology such as confirmed shared roots, confirmed node-local staging roots, and durable scheduler/client constraints. Do not record current jobs, allocations, free GPUs, utilization, memory pressure, or other transient observations.
- Keep portable principles in the dotfiles source. Add discovered cluster-specific facts only to the live `$CODEX_HOME/AGENTS.md` unless the user explicitly asks to publish those facts.

### Preserve unrelated rules

- Keep Slurm, GPU inspection, and explicitly authorized direct launchers in `$CODEX_HOME/rules/hpc.rules`.
- Never replace unrelated existing rules. If equivalent Slurm coverage already exists, leave it unchanged. Otherwise add or refresh one clearly delimited initializer-owned block and preserve everything outside it.
- Prefer command basenames and standard system paths; do not hard-code usernames, cluster hostnames, mount names, or user-specific executable paths in the portable rules source.
- If `sacct` requires a named-host SSH workaround, treat that as a Slurm client configuration defect. Report or fix the canonical Slurm configuration instead of making the workaround part of the portable rules template.
- After changing `.rules`, state that a new Codex task is required before the new decisions are loaded.

Do not add hooks, wrappers, background tracking, snapshots, or extra skills as part of initialization. Do not inspect authentication data, environment secrets, sessions, memories, archived data, backups, or earlier harness material; they are not environment-discovery inputs.

Report only the detected cluster and node role, relevant storage classifications, scheduler/accounting and GPU facts, exact additive configuration changes, whether a new task is required, and unresolved facts.
