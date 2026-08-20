---
name: slurm-execution-contract
description: Plan, launch, monitor, cancel, and hand off a Slurm workload only when the user explicitly invokes `$slurm-execution-contract` or explicitly asks to submit, monitor, cancel, replace, scale, or diagnose a Slurm job. Do not use for routine debugging, short tests, metadata inspection, or proxy measurements.
---

# Slurm Execution Contract

Use this opt-in workflow to preserve the user's intended resource shape and experiment lineage. It must not turn ordinary debugging into a queued job.

## Gate: do not use Slurm by default

Keep debugging, short tests, metadata inspection, and proxy measurements in the current safe allocation or direct command when adequate. Submit a Slurm job only when the user requests it or the required resources do not fit.

If the user says “four GPU nodes,” do not treat it as “four GPUs.” If nodes, GPUs per node, CPUs, partition, target node range, or job scope are ambiguous, ask before submitting.

## Local capacity profile

Before planning a GPU placement, read [the local cluster profile](references/cluster-profile.md). Use it for stable topology and CPU/GPU coupling facts only; never use it to claim that a node is currently free.

## GPU-first resource default

For an ordinary one-process-per-GPU workload, request one task and four CPUs per GPU unless the workload has an evidenced CPU, dataloader, preprocessing, or RAM requirement. Do not reserve a whole node merely because all of its GPUs are requested.

Use a shape equivalent to the following when it fits the workload:

```bash
#SBATCH --nodes=<N>
#SBATCH --ntasks-per-node=<GPUs per node>
#SBATCH --gpus-per-node=<GPUs per node>
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=4
```

Do not add `--exclusive`, node-wide CPU requests, or large `--mem` values by default. Increase CPU or RAM only with workload-specific evidence, such as data-loader workers, CPU preprocessing, host-side tensor staging, or a measured memory requirement. If a submitted job shows an unexpectedly large CPU or memory allocation, inspect the script and scheduler output before concluding that GPUs are unavailable.

## Compilation mode

Disable runtime compilation, such as `torch.compile`, for debugging and short tests. Enable it for a result-producing or benchmark run when the workload supports it and debugging has passed. Record the compilation mode in the run card, and do not compare compiled and uncompiled runs as equivalent.

## Contract before a scheduler mutation

State the requested and actual values for:

- nodes; GPUs per node; total GPUs; CPUs per task; partition; time limit
- array/chunk layout; checkpoint; commit; config; split; batch size; world size; seed

Make availability claims only from fresh, scoped scheduler evidence. Query the relevant job IDs and nodes with `squeue`, `sacct`, `scontrol`, or cluster-native equivalents; do not infer availability from an earlier observation or an apparently idle GPU.

## Launch, monitor, and cancel

After submission, report the job ID and exact resource shape. Preserve enough lineage to reproduce the run.

For debugging and short tests, use waits or sleeps of 10 seconds or less. Prefer a fresh scheduler/status query to blind sleeping.

Use a longer bounded wait only when the user explicitly asks to monitor, wait, babysit, or keep watching. State the cadence and monitor the named job IDs; do not promise continuous monitoring without a monitoring mechanism.

Cancel or replace only the exact job IDs explicitly authorized by the user. Verify the current state and report the result. Never broaden a named cancellation to a user-wide or pattern-wide cancellation without new authorization.

## Compare and hand off

Before interpreting a comparison, verify checkpoint, commit, config, data split, batch size, world size, and seed. State every mismatch before drawing conclusions.

Finish with the final job state, resource shape, lineage, validation result, and any pending or failed work. If validation was run and failed, state whether the failure is environmental, pre-existing, or unresolved; never describe it as passed.
