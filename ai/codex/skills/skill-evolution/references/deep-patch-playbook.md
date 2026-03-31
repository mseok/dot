# Deep Patch Playbook

Use this guide only when the mode is `patch`.

## Narrow patch vs deep patch

Choose `narrow patch` by default.

Stay narrow when the failure is local:

- one weak trigger description
- one unclear workflow step
- one missing reference
- one stale metadata field
- one script bug or missing check

Escalate to `deep patch` only when at least one of these is true:

- the same failure pattern appears in two or more prompts, sessions, or
  revisions
- drift already spans two or more layers such as `SKILL.md`, `references/`,
  `scripts/`, `agents/openai.yaml`, or the output contract
- the wrong default tool, editor, or medium leaks through multiple layers
- stale branches, obsolete references, or dead helper logic materially confuse
  the current skill

## What deep patch is allowed to change

- rewrite the quick start and intake contract
- realign `SKILL.md`, `references/`, `scripts/`, and `agents/openai.yaml`
- prune dead branches, obsolete references, and stale helper logic
- redesign the validation path when the current one creates false confidence
- rewrite the output contract when the current deliverable shape is unstable

## What deep patch must not do

- widen the scope beyond the user's actual job
- preserve dead optionality "just in case"
- create a new skill when retargeting the old one is sufficient
- add broad rewrites without naming the concrete repeated failure or drift

## Closeout expectations

When the work is `deep patch`, the final response must say:

- what evidence justified escalation
- which layers were realigned
- which obsolete branches or references were removed or demoted
- what still remains unresolved

When the work stays `narrow patch`, say why escalation was not necessary.
