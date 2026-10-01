# Claude Code guidance

Claude Code uses the same working agreement as Codex. Each host links its
global `~/.claude/CLAUDE.md` to this checkout's `ai/codex/AGENTS.md`, so there
is one maintained source and no Claude-specific copy to drift. The server
section, the research router and the host facts in `~/.codex/host-context.md`
apply to Claude in the same way.

Install or refresh the link and the skills:

```bash
~/dot/bin/install_claude.sh
```

Use `--guidance-only` to refresh the link without touching skills. An existing
regular `CLAUDE.md` is moved to a timestamped backup beside it; an unrelated
symlink is left untouched.

Skills mirror the Codex user skills. Every skill installed below
`~/.codex/skills` is linked under the same name below `~/.claude/skills`, to the
same source. The installer removes only links into the retired
`~/agent-skills/skills/claude` scope and broken links. Host-local directories,
including the research skills written by `deploy-research.py` and skills
synced by Claude itself, are preserved. Run it after `install_codex.sh`, which
`install.sh` does.

`settings.json`, credentials, MCP registrations, hooks and plugins are
host-local and are not stored in this repository, as with Codex `config.toml`.
Command permissions on an HPC host follow the intent of
`ai/codex/rules/hpc.rules` but are maintained in that host's `settings.json`.
