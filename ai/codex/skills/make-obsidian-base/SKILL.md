---
name: make-obsidian-base
description: Create a new Obsidian category note and matching base file in one step for vaults that use Categories/*.md plus Templates/Bases/*.base. Use when the user asks to add a new category/base pair, wants a one-command setup like /make-obsidian-base [category-name], or wants consistent category scaffolding.
---

# Make Obsidian Base

Create a category note and base file in one run.

## Workflow

1. Identify the target vault path.
- Default to the current working directory.
- If needed, pass `--vault /path/to/vault`.

2. Parse the category name.
- Accept either a single token (`Paper-Notes`) or quoted words (`"Paper Notes"`).
- Normalize separators and spacing.

3. Run the bundled script.
- Command: `scripts/make_obsidian_base.py <category-name>`
- Optional flags:
  - `--vault <path>`
  - `--force` (overwrite existing files)
  - `--dry-run` (preview only)

4. Confirm output.
- Report created/updated file paths.
- If files already exist and `--force` is not set, report skip reasons.

## Output contract

The script creates:

- `Categories/<Category>.md`
- `Templates/Bases/<Category>.base`

The category note is generated as:

```markdown
---
tags:
- categories
---
![[<Category>.base]]
```

The base file includes a default table view with:

- `categories.contains(link("<Category>"))`
- `!file.name.endsWith("Template")`

## Notes

- Keep ASCII-only output.
- Preserve existing files unless `--force` is explicitly provided.
