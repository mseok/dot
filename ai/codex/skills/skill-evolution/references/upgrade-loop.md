# Upgrade Loop

Use this loop when iterating on an existing skill.

## Step 1. Start from a concrete artifact

Good artifacts:

- a user complaint
- a transcript where the skill underperformed
- a diff showing repeated manual edits
- a missing deliverable or broken output shape

Bad artifacts:

- "make it better"
- generic brainstorming without a failure mode

If there is no concrete artifact, ask for one example prompt or choose the most recent real failure.

## Step 2. Audit before patching

Run:

```bash
python3 scripts/skill_audit.py <skill-dir>
python3 /Users/mseok/dot/ai/codex/skills/.system/skill-creator/scripts/quick_validate.py <skill-dir>
```

Use the audit output to separate structural issues from behavioral ones.

If `quick_validate.py` fails with `ModuleNotFoundError: yaml`, note that the system validator depends on `PyYAML`. Do not hide the failure. Either fix the Python environment or continue with `skill_audit.py` as the local minimum gate and mention the missing dependency in the closeout.

## Step 3. Match the fix to the failure

- Trigger problem: patch frontmatter.
- Missing decision point: patch `SKILL.md`.
- Long, branch-specific detail: add a reference.
- Repeated helper logic: add a script.
- Stale UI affordance: patch `agents/openai.yaml`.

Resist broad rewrites unless the existing skill structure is actively blocking progress.

## Step 4. Keep the patch narrow

For one iteration, prefer one of these scopes:

- one new workflow branch
- one rewritten quick-start section
- one new reference file
- one new helper script
- one output-contract improvement

Large rewrites should be justified by repeated failures across multiple prompts.

## Step 5. Re-validate

Run the same validators after patching. Do not stop at visual inspection.

Interpretation:

- `FAIL`: structural issue or broken path; fix before shipping
- `WARN`: acceptable if intentional, but mention it in the closeout
- `PASS`: no structural issues detected by the local audit

## Step 6. Pick the next real test prompt

End every revision with one prompt that should exercise the new behavior.

Examples:

- "Use `$skill-name` to verify this HPC preflight spec before I submit the Slurm job."
- "Use `$skill-name` to turn PDB ID plus SMILES into a docking handoff and scoring memo."

The test prompt should be narrow enough that success or failure is obvious.
