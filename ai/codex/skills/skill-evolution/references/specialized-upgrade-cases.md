# Specialized Upgrade Cases

Load this reference only when the failure is specialized rather than generic.

## 1. Visual overdesign

Treat repeated complaints such as "too many colors," "too many accents," or
"too decorative" as concrete evidence, not subjective noise.

Patch target:

- constraint language in `SKILL.md`
- any default prompt that encourages excess styling

Fix:

- freeze restraint earlier in the workflow
- make palette or decoration limits the default behavior

## 2. External style transfer

If the user provides a style system from another domain, extract the reusable
layout or structural rules only.

Do not:

- import the abandoned business context
- copy branding or storytelling baggage into the target skill

## 3. Failed rendered artifact

If the user shows a broken rendered artifact such as a clipped PDF, broken
slide, or bad screenshot, treat the artifact as primary evidence.

Fix:

- patch the skill rules that should have prevented it
- require one post-patch rerun of that artifact path before claiming the issue
  is resolved

## 4. Medium retarget

If the job stays the same but the primary tool, editor, or output medium
changes, treat it as `retarget`, not a new skill.

Patch together:

- frontmatter description
- quick start
- output contract
- `agents/openai.yaml`
- any helper script or validation step that still assumes the old default
