# Attachment Workflow

Use this reference whenever a new Obsidian note needs figures, images, or
other local artifacts.

## Core rule

Do not use a local filesystem path as the primary note reference.

Wrong:

- `file:///home/.../plot.png`
- `/home/.../plot.png` in the middle of the note body

Right:

- `![[Attachments/plot.svg]]`
- a short `# 원본 산출물 경로` section that records the absolute local source
  path for provenance

## Preferred upload path

If the artifact is text-safe, create it directly in the vault with the
Obsidian MCP.

Text-safe usually means:

- `.svg`
- `.md`
- `.csv`
- `.json`
- plain-text summaries derived from the raw artifact

For `.svg` specifically:

1. Read the source SVG from the local filesystem.
2. Create `Attachments/<clear-name>.svg` with `obsidian_put_file`.
3. Embed it in the note with `![[Attachments/<clear-name>.svg]]`.
4. Verify with `obsidian_list_vault_directory` or `obsidian_get_file`.

## Binary artifact rule

In this environment, MCP attachment creation is reliable for text-safe files
but not for arbitrary binary files.

If the only available artifact is a local binary image such as:

- `.png`
- `.jpg`
- `.pdf`

follow this order:

1. Look for an `.svg` companion in the same analysis directory.
2. If no `.svg` exists, check whether the figure can be replaced by a concise
   Markdown table or textual summary in the note.
3. If neither is possible, do not embed the local binary path. Record the
   absolute path only in `# 원본 산출물 경로`.

## Naming rules

Prefer deterministic, descriptive attachment names:

- `Attachments/ecsi-sweep1-ode-tail-comparison.svg`
- `Attachments/ecsi-sweep2-churn-window-comparison.svg`

Avoid generic names unless the vault already uses a specific convention such as
`Pasted image ...`.

## Required verification

After adding an attachment:

- verify the file exists in `Attachments/`
- verify the note embeds the vault path
- verify no `file:///...` links remain in the main body

## Minimal note pattern

Use this pattern when an attachment is available:

```markdown
## 그림

![[Attachments/example-figure.svg]]

## 원본 산출물 경로

- `/absolute/local/path/to/example-figure.svg`
```

If no safe attachment could be added, keep only the provenance section and make
the limitation explicit in one sentence.
