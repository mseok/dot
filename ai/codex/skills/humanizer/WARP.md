# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## What this repo is
This repository is a **Codex skill** implemented entirely as Markdown.

The “runtime” artifact is `SKILL.md`: Codex reads the YAML frontmatter (metadata + allowed tools) and the prompt/instructions that follow.

`README.md` is for humans: installation, usage, and a compact overview of the patterns.

## Key files (and how they relate)
- `SKILL.md`
  - The actual skill definition.
  - Starts with YAML frontmatter (`---` … `---`) containing `name`, `version`, `description`, and `allowed-tools`.
  - After the frontmatter is the editor prompt: the canonical, detailed pattern list with examples.
- `README.md`
  - Installation and usage instructions.
  - Contains a summarized “24 patterns” table and a short version history.

When changing behavior/content, treat `SKILL.md` as the source of truth, and update `README.md` to stay consistent.

## Common commands
### Install the skill into Codex
Recommended (clone directly into Codex skills directory):
```bash
mkdir -p ~/.codex/skills
git clone https://github.com/blader/humanizer.git ~/.codex/skills/humanizer
```

Manual install/update (only the skill file):
```bash
mkdir -p ~/.codex/skills/humanizer
cp SKILL.md ~/.codex/skills/humanizer/
```

## How to “run” it (Codex)
Invoke the skill:
- `$humanizer` then paste text

## Making changes safely
### Versioning (keep in sync)
- `SKILL.md` has a `version:` field in its YAML frontmatter.
- `README.md` has a “Version History” section.

If you bump the version, update both.

### Editing `SKILL.md`
- Preserve valid YAML frontmatter formatting and indentation.
- Keep the pattern numbering stable unless you’re intentionally re-numbering (since the README table and examples reference the same numbering).

### Documenting non-obvious fixes
If you change the prompt to handle a tricky failure mode (e.g., a repeated mis-edit or an unexpected tone shift), add a short note to `README.md`’s version history describing what was fixed and why.