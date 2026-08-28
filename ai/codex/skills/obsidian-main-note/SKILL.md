---
name: obsidian-main-note
description: >-
  Save a verified reusable outcome to the canonical Obsidian vault through the
  obsidian_main MCP gateway. Use when the user explicitly asks to record it or
  an applicable project policy requires a durable record.
---

# Obsidian main note

Search the main namespace before creating a duplicate. A permanent agent record
must be concise, evidence-backed, and useful for a later decision; do not save
routine status, raw output, prompts, transcripts, logs, code dumps, configs,
datasets, credentials, or unsettled ideas.

Upload an approved supporting file with `attachment_upload`. The bridge opens
an allow-listed local regular file and streams raw HTTPS bytes; never encode the
original bytes as base64 or JSON. Use the returned attachment ID in
`record_create` with a specific title, canonical tags, the canonical project on
remote hosts, and a stable unique `operation_id`. An identical retry reuses the
same operation ID. A changed request needs a new one.

Use `record_append` only for a record created by the same authenticated host.
The gateway rejects a human edit or cross-host append and never merges it. Do
not edit any Vault file directly. No overwrite, promotion, delete, rename, move,
or Git-publisher fallback is allowed.
