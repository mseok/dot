# Upgrade Loop

Use this sequence when iterating on an existing skill.

## 1. Start from the strongest evidence available

Prefer this order:

1. an explicit failed artifact, transcript, or user complaint
2. the current request plus the first audit finding
3. the most recent real failure you can point to

If one missing artifact would materially change the chosen mode or patch depth,
ask for that single item. Otherwise proceed.

## 2. Choose mode and patch depth

- `diagnose-only`: analyze and propose changes without editing
- `patch`: fix the existing skill
- `retarget`: change the default tool, editor, or medium while keeping the same
  job

If the mode is `patch`, read
[`deep-patch-playbook.md`](deep-patch-playbook.md) to decide whether the work
stays `narrow patch` or escalates to `deep patch`.

## 3. Audit before editing

Run:

```bash
python3 scripts/skill_audit.py <skill-dir>
python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>
```

Use the audit output to separate structural issues from behavioral ones.

If `quick_validate.py` fails with `ModuleNotFoundError: yaml`, call that out
explicitly. Do not pretend the validator passed.

## 4. Match the fix to the failure

- Trigger or scope problem: patch frontmatter first
- Intake, workflow, or output problem: patch `SKILL.md`
- Branch-specific detail: add or prune a reference
- Repeated deterministic logic: add or repair a script
- Stale UI affordance: patch `agents/openai.yaml`

Escalate to `deep patch` only when repeated failures or multi-layer drift
justify coordinated changes across several of those surfaces.

## 5. Re-validate

Run the same structural validators after editing, then exercise one realistic
mode-specific prompt from [`mode-test-prompts.md`](mode-test-prompts.md).

Interpretation:

- `FAIL`: broken path or structural issue; fix before shipping
- `WARN`: acceptable only if explicitly called out in the closeout
- `PASS`: no structural issue detected by the local audit

## 6. Close out clearly

State:

- the failure-taxonomy class
- the chosen mode
- the chosen patch depth
- why the work did or did not escalate to `deep patch`
- one next prompt that should exercise the revised path
