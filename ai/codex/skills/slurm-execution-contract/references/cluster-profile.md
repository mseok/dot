# Local Slurm Cluster Profile

This is a topology and policy snapshot, not a source of live availability.
Refresh scheduler state before every launch, cancellation, or placement claim.

## Observed topology

Captured on 2026-08-20 from `sinfo` and `scontrol`:

- `gpu01` through `gpu32`: 8 GPUs, 192 CPUs, and 1,934,000 MB of reported memory per node.
- `gpu-all` spans the GPU fleet. Observed group partitions include `gpu-wyk`
  (`gpu01`–`gpu03`, `gpu05`–`gpu20`), `gpu-hits` (`gpu04`), `gpu-hwang`
  (`gpu21`–`gpu26`), and `gpu-ahn` (`gpu27`–`gpu32`). Verify access and
  membership live; partition policy can change.
- The scheduler uses `select/cons_tres` with `CR_CORE_MEMORY` and backfill.
  CPU cores and memory can therefore block a GPU placement when the job asks
  for more of them than it needs.

## GPU-first CPU/RAM rule

Do not attach node-wide CPU or RAM requests to a GPU workload by default. For
an ordinary one-process-per-GPU job, start with one task and four CPUs per
GPU, then increase CPU or RAM only when the data loader, preprocessing,
host-side staging, or a measured profile requires it.

A request that effectively needs 24 CPUs per GPU needs all 192 CPUs for an
8-GPU node. The ordinary 4-CPU/GPU default needs 32 CPUs for that node. A
node with only 64 idle CPUs can therefore host the ordinary request but not
the oversized one, even if its GPU state looks similar. Do not assume 24
CPUs/GPU is universal; inspect the submitted job and site policy, then reduce
the request if the workload does not justify it.

## Live preflight

Before a scheduler mutation, use scoped queries such as:

```bash
sinfo -N -p <partition> -o '%N|%c|%m|%G|%C|%t'
scontrol show node <node-list>
squeue -j <job-id> -o '%.18i %.9P %.8T %.10M %.6D %R'
scontrol show job <job-id>
```

Interpret `%C` as `allocated/idle/other/total` CPUs. Compare that result with
the intended `--nodes`, `--gpus-per-node`, `--ntasks-per-node`,
`--cpus-per-task`, memory, partition, and job-array shape before submitting.
Avoid `--exclusive` and large `--mem` requests unless they are specifically
required by the workload.
