# History And Artifact Recap

Use this reference when the note is not a generic memo but a reconstruction of
past work from Codex history and local artifacts.

## Retrieval order

Collect evidence in this order:

1. Codex history for intent and interpretation
2. repository artifacts for exact settings and metrics
3. existing Obsidian notes for project-local framing

### Codex history

Search:

- `~/.codex/history.jsonl`
- `~/.codex/sessions/YYYY/MM/DD/*.jsonl`

Look for:

- sweep names
- case names
- baseline and current-best wording
- why a new axis was chosen
- any explicit interpretation the user accepted

### Repository artifacts

Prefer:

- `summary.json`
- `metrics.json`
- `resolved_config.yaml`
- `implementation/*.md`
- `commands/*.md`
- analysis outputs under `tmp/analysis/`

If multiple sources disagree, prefer the artifact that is closer to the
completed run summary over ad hoc logs.

## Reconstruction rule

Do not write a flat dump of numbers. Rebuild the experiment chain:

1. baseline or prior assumption
2. first sweep and why it was run
3. result that selected the temporary best
4. next sweep and why it followed
5. current best setting
6. remaining uncertainty

## Stable recap sections

Use this section pattern unless the user asks for another structure:

- `# 요약`
- `# 정리 기준`
- one section per sweep or experiment family
- comparison section if multiple baselines matter
- `# 후속 해석`
- `# 원본 산출물 경로`

## Comparison rule

When two runs share the same schedule or effective configuration trajectory,
state that explicitly and separate rerun variance from actual parameter effects.
