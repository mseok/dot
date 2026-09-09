# Codex files in this repository

The repository carries the portable part of the Codex setup:

- `AGENTS.md` is the shared AI4Science/HPC base policy.
- `rules/hpc.rules` is installed on Linux/HPC hosts only.
- `skills/` contains repository-owned user skills. The installer links each
  skill individually, so Codex-managed system skills stay in the host's
  `$CODEX_HOME/skills/.system` directory.

`config.toml`, authentication, MCP registrations, project trust, databases,
and other app state are deliberately not version-controlled. They contain
machine-specific paths, permissions, and credentials.

`AGENTS.override.md` is also host- and cluster-specific. The installer keeps an
existing file untouched. To install a reviewed override explicitly:

```bash
$HOME/dot/bin/install_codex.sh \
  --override-from /path/to/AGENTS.override.md
```

On a new Slurm cluster, run the `init-slurm-environment` skill's explicit
topology audit first. A generic installer must not guess storage paths,
partitions, or node capabilities and turn those guesses into active model
instructions.
