---
name: clipboard-copy
description: Copy local file contents or generated text to the macOS clipboard with pbcopy. Use when the user asks to copy a file or text to the clipboard, prepare paste-ready manuscript/code snippets, or quickly transfer content between tools.
---

# Clipboard Copy

## Workflow

Use this skill when the user explicitly wants clipboard output.

1. Identify the source to copy.
- If the user provides a file path, copy that file.
- If no path is provided, default to `sections/02_1_overview.tex` when it exists in the current workspace.
- If the user wants generated text copied, pass the text through stdin.

2. Run the bundled script.
- File copy: `scripts/copy_to_clipboard.sh <path>`
- Default file copy: `scripts/copy_to_clipboard.sh`
- Text copy via stdin: `printf '%s' "<text>" | scripts/copy_to_clipboard.sh -`

3. Confirm the result.
- Report exactly what was copied.
- If copying fails, report the reason (`pbcopy` unavailable, file missing, or permission issue).

## Notes

- This skill is macOS-specific and requires `pbcopy`.
- In sandboxed sessions, clipboard access may require escalated permissions.
