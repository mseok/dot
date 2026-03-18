---
name: obsidian-authoring
description: Create or update Obsidian notes via MCP with correct frontmatter, vault-relative links, attachment handling, and provenance sections. Use when the user asks to write a new Obsidian note, revise an existing note, organize local results into Obsidian, attach figures or artifacts to a note, or summarize chat history and repository outputs into a structured vault note.
---

# Obsidian Authoring

## Overview

Create or update Obsidian notes with MCP tools, while preserving vault
conventions and avoiding broken local-path references.

Treat this skill as the default workflow for:

- new notes
- updates to existing notes
- research summaries
- experiment recaps
- notes that require attachments or local artifact provenance

## Workflow

### 1. Decide the note mode

Choose one of these modes before writing:

- new note from scratch
- update an existing note
- history-and-artifact recap note

For recap notes, also read `references/history-recap.md`.

### 2. Inspect vault context first

Before writing, inspect nearby vault context with MCP.

- List the vault root or relevant directory.
- Search for nearby notes by topic.
- If updating, fetch the exact target note first.
- Reuse established frontmatter style when the note clearly belongs to an
  existing project or notebook cluster.

### 3. Build the note contents

For most notes, keep the structure simple and purpose-driven.

Use short sections that help the note age well:

- summary or thesis
- evidence or key points
- interpretation
- next action
- provenance when local artifacts matter

When the note is analytical, prefer decision-complete summaries over raw dumps.

When the note is intended to preserve paper-style pseudocode in Obsidian:

- If the vault uses `obsidian-pseudocode`, place LaTeX-like algorithm content
  inside fenced `pseudo` code blocks instead of raw `\begin{algorithm}` blocks
  in the main Markdown flow.
- Keep equations outside the pseudocode block as normal Obsidian math using
  `$...$` or `$$...$$` when the formulas need to be readable or reusable.
- If the note is created inside an indexed cluster folder and a local
  `README.md` exists, update that index note to link the new page when useful.

### 4. Apply Obsidian frontmatter rules

When creating or updating the note:

- Set `date` to today's date.
- Set `writer` to `문석현`.
- Do not place the date or writer in the title or body.
- Keep tags and categories minimal and project-relevant.

### 5. Apply Obsidian body rules

When writing math in Obsidian:

- Use inline math as `$...$`.
- Promote long expressions to display equations.
- Avoid backticks for mathematical symbols.

When local artifacts matter:

- Keep absolute filesystem paths out of the main narrative.
- Put them only in `# 원본 산출물 경로`.

## Image And Attachment Rules

Read `references/attachment-workflow.md` before attaching any figure, image,
PDF, or local artifact to the note.

The short version is:

- Never leave a local filesystem path or `file:///...` link as the primary
  note reference.
- Upload a vault-local attachment under `Attachments/` when MCP can safely
  create it.
- Prefer SVG, Markdown tables, CSV-derived summaries, or other text-safe
  artifacts when binary upload is not available.
- If only a binary local image exists and MCP cannot upload it in the current
  environment, do not embed the local path. Record it only under
  `# 원본 산출물 경로`.
- After adding an attachment, verify that the attachment exists in the vault
  and that the note embeds `![[Attachments/<name>]]`.

## MCP Tool Pattern

Prefer this order:

- `obsidian_simple_search` to find candidate notes
- `obsidian_get_file` to inspect the exact note or template-like neighbor
- `obsidian_put_file` for new notes and text-safe attachments
- `obsidian_patch_file` when preserving an existing note matters
- `obsidian_list_vault_directory` to verify attachments and destinations

## Verification Checklist

Before finishing:

- Confirm the new note exists in the vault.
- Confirm every embedded attachment exists in `Attachments/`.
- Confirm the note uses vault-relative embeds, not local paths.
- Confirm any local absolute paths are confined to `# 원본 산출물 경로`.
- Confirm frontmatter and body follow project-specific authoring rules.
