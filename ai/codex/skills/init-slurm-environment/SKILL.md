---
name: init-slurm-environment
description: Bootstrap or deliberately refresh a Codex Slurm storage-topology policy. Use after installing Codex or these dotfiles on a new Slurm system, after scheduler or storage topology changes, or when the user explicitly asks to reinitialize the Slurm environment. Do not use per session or for routine coding, job execution, and ordinary debugging.
---

# Initialize a Slurm environment

Run this as a one-time bootstrap or explicit refresh. Start with read-only discovery. The default is a minimal audit; run the full cross-node storage audit only when the user explicitly requests it. Do not submit a job merely to prove the initializer works.

## Modes and scope

- **Minimal audit:** discover the scheduler, the initiating host role, and the concrete roots already in scope. It never uses SSH or submits work.
- **Full topology audit:** only for an explicit request to verify compute-node storage. It uses Slurm-provided hostnames and bounded, read-only SSH probes; it does not submit a job.
- Audit only the working tree, `CODEX_HOME`, and explicitly named data, checkpoint, output, cache, or staging roots. A user-named compute-only root remains in scope even when it is absent from the controller or login host.
- A minimal audit must not create, regenerate, downgrade, or remove a generated storage-topology block. Only an explicit full topology audit may publish named-root or NFS policy.

## Core discovery in every mode

1. Identify the short hostname and cluster name. Check `scontrol ping`, then retain only controller, accounting, temporary-filesystem, and cluster fields from `scontrol show config`.
2. Determine the initiating node role from Slurm evidence. `scontrol show node <short-hostname>` proves a matching compute node; a non-match proves only that it is not registered as one. Report controller, login/client, compute, or unknown without relying on hostname conventions.
3. Inspect `sinfo` and a bounded `squeue` view. Query `sacct` only when accounting is relevant. If accounting fails, report `AccountingStorageType`, `AccountingStorageHost`, and `AccountingStoragePort`; never add an SSH workaround for accounting.
4. Run `findmnt -T` for every in-scope root. If important roots are still unknown, inspect the mount table without traversing file contents and ask which roots matter.
5. Classify a local observation from evidence, never path names: a network or cluster filesystem is a shared candidate; a block-backed filesystem or tmpfs is a node-local candidate; bind mounts and unclear sources remain unknown.
6. On a GPU node only, compare Slurm GRES with one concise `nvidia-smi` query. Allocation, processes, memory use, and utilization are separate facts.

Treat an unverified root conservatively. Do not recursively scan broad trees or create high-fanout metadata I/O on a candidate shared filesystem.

## Full cross-node storage topology audit

### Inventory and probe boundaries

1. Obtain `scontrol show nodes -o` and retain `NodeName`, `NodeAddr`, `NodeHostName`, state, partitions, and GRES. The exact `NodeHostName` returned by Slurm is the only permitted direct-SSH target; never construct a hostname or choose another route.
2. For a full audit, inspect every responding compute node. Do not SSH `DOWN`, `NOT_RESPONDING`, `UNKNOWN`, or future nodes. Report those nodes as unverified; never infer their storage from a responding node.
3. For every in-scope root, run a noninteractive read-only probe such as `ssh -n -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=yes "$NodeHostName" findmnt -T "$root" -o TARGET,SOURCE,FSTYPE,OPTIONS`. The `-n` is mandatory whenever hosts are read from a pipe, otherwise SSH consumes the remaining inventory.
4. For each observed NFS root, collect the matching `nfsstat -m` mount record. Report the export and mount semantics that affect behavior, including NFS version, transport, hard/soft behavior, timeout/retry, and attribute-cache policy when present. Report a `soft` mount as a durability-sensitive infrastructure fact, but do not change it or turn any observed option into a performance claim.
5. Do not inspect SSH configuration, keys, agent state, or authentication material. Do not relax host-key checking, use `accept-new`, alter known-host files, copy data, or open an interactive shell. A connection, authentication, host-key, or command failure remains unresolved.
6. If direct SSH is unavailable but a relevant allocation already exists, execute the same bounded probes inside it. Otherwise report the gap; do not submit an initializer-only verification job.

### Storage classifications

- **shared network root:** every audited responding node resolves the exact path to a consistent network or cluster filesystem. This verifies mount-level cross-node visibility, not application-level performance or write-coherence under load.
- **node-local root:** every audited responding node resolves the path to a local block-backed filesystem or tmpfs.
- **mixed local root:** the path is local on every audited node but its mount point or backing device differs. It is safe only for allocation-scoped staging; do not assume uniform capacity or filesystem layout.
- **unverified root:** a node is unavailable, a probe fails, or observations disagree. Do not generate a durable policy for it.

## Derive workload policy

- Keep source, immutable inputs, durable checkpoints, and cross-node results on a verified shared root.
- Keep metadata-heavy caches, sharded preprocessing, temporary downloads, and ephemeral intermediates on a verified node-local root. Use a job-unique directory inside the allocation; never make a local path an inter-node handoff.
- For NFS roots, avoid turning cache directories or high-fanout small-file workloads into a shared metadata hotspot. Stage from the shared root to local storage when the workload needs it, then persist only necessary results back to shared storage.
- Treat a mixed local root as staging only even if the pathname exists everywhere. Do not infer capacity, quota, cleanup, or persistence from its name.

### NFS durability and concurrency constraints

- A consistent NFS mount proves mount-level visibility only. It does not prove availability under load, application write durability, lock behavior, cache coherence, server failover behavior, or performance. Never report that NFS issues are impossible or resolved solely because the topology audit passed.
- Treat a `soft` NFS mount as unsuitable for an unconditional durability claim: RPC failure can reach the application as an I/O error. Report the setting and keep critical persistence error-aware; do not change the mount option, add a blanket retry, or claim that retries make the path safe.
- For a critical artifact on a shared NFS root, require the producing application to finish and close a temporary file on that same filesystem, surface any write or close error, then publish through its supported atomic rename/replace operation. Do not add `fsync`, retry, or error-handling code speculatively during initialization; verify the application's existing persistence contract before relying on it.
- Assign exactly one writer to each checkpoint or result artifact. Coordinate any multi-process publish through the workload's existing synchronization; do not rely on pathname sharing or client-side cache behavior as a lock protocol.
- If a workflow needs evidence beyond mount topology, propose a bounded allocation-specific persistence check with its real application and artifact path. Do not submit that check as initializer-only work.

## Generate the minimal Codex configuration

Change durable configuration only for an explicit initialize or refresh request. Preserve existing configuration by default.

- Treat `$CODEX_HOME/AGENTS.md` as the Git-managed portable base and never modify it during initialization.
- A minimal audit leaves `AGENTS.override.md` unchanged. If no override exists, report that there is not yet sufficient topology evidence to create one. If a generated override exists, preserve it even when the minimal audit itself has no root facts.
- After an explicit full topology audit, create `AGENTS.override.md` if absent. If an existing override has the generator marker, regenerate it from the current base and the new full-audit facts. If it lacks the marker, stop and ask how to preserve it.
- The override begins with `<!-- Generated by init-slurm-environment. Edit AGENTS.md or rerun the initializer; do not edit this file directly. -->`, followed by the base copied exactly, then one `BEGIN`/`END init-slurm-environment` block.
- Record only stable aggregate conclusions scoped to audited responding compute nodes. Never encode node names, controller names, jobs, allocations, free GPUs, current load, NFS server addresses, or raw export paths. Report unavailable nodes separately instead.
- A full-audit block must have `## Local Slurm environment` followed by exactly these behavior-oriented policies when evidence supports them:
  1. **Execution:** use Slurm for CPU-, RAM-, GPU-, or data-staging-heavy work; do not run such work on a controller or login/client host. Permit direct execution on a compute node only when the user or site policy authorizes it and live allocation and GPU state make it appropriate.
  2. **Storage topology:** group actual paths by classification rather than repeating a rule per path. State shared network roots and their allowed cross-node/durable role, then node-local or mixed-local roots and their allocation-scoped staging-only role. For mixed paths, state that mount layout or capacity may vary and must not be assumed uniform.
  3. **NFS durability:** for every shared NFS root with a behavior-relevant mount semantic such as `soft`, state that shared visibility is not a durability or availability guarantee. Require the workload's error-aware close and same-filesystem temporary-file plus atomic rename/replace publication contract, one writer per critical artifact, and local staging for metadata-heavy work. Do not include raw server or export identifiers, and do not claim that NFS is safe merely because the audit passed.
- Generate only classifications actually observed in that cluster. Omit absent categories and unknown roots; never hard-code `/home`, `/scratch`, `/tmp`, or an NFS option into the portable skill or an unrelated cluster profile.
- Omit unverified roots from the generated block. Do not persist a statement merely saying that a root was not verified.
- If one `CODEX_HOME` serves different clusters with different topology, stop and ask the user to choose a profile boundary. A new Codex task is required after creating or regenerating the override.

## Permissions and sandbox boundary

- The read-only filesystem sandbox cannot open Slurm-controller sockets, inspect GPUs, or establish SSH connections. No instruction or rule can make these operations happen inside the sandbox; use an explicit host-side escalation for the exact read-only command.
- Treat `$CODEX_HOME/rules/hpc.rules` as the Git-managed portable policy for Slurm and GPU inspection. Do not generate per-cluster rules from topology observations.
- Do not add a generic SSH allow rule: SSH can execute arbitrary remote commands. Keep topology probes explicit, noninteractive, and individually escalated.
- Add a site-specific permission only after an observed permission failure and only when the smallest explicit rule solves it. Preserve unrelated rules and state that a new task is required after changing them.

## Acceptance check before publication

1. Test override generation in a temporary `CODEX_HOME` fixture. Verify that the base body is byte-identical, exactly one generated block exists, and a full-audit block contains `## Local Slurm environment` plus evidence-backed execution, grouped-storage, and NFS-durability policies without host-specific, transient, or unverified facts.
2. Run a read-only live-cluster check without submitting a job: verify Slurm inventory, then feed at least two responding Slurm-provided hostnames through the `ssh -n` probe. Confirm both results are returned; this guards against SSH consuming the inventory stream.
3. When an audited root is NFS, confirm that `findmnt -T` and the matching `nfsstat -m` record agree on the mount target, and that a `soft` mount is reported as durability-sensitive rather than treated as safe. When a local root is mixed, verify the policy calls it staging-only.
4. Run a minimal-audit regression fixture with an existing generated full-audit override and verify that it is unchanged. After syncing the portable source to the live skill, compare the two files exactly. Do not publish if either fixture or the read-only checks fail.

Do not add hooks, wrappers, background tracking, snapshots, or extra skills as part of initialization. Report the cluster and node role, storage classifications, NFS mount facts, scheduler/accounting and GPU facts, exact additive configuration changes, whether a new task is required, and unresolved facts.
