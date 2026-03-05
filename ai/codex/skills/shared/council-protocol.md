# Council Protocol

> Shared protocol for multi-model council mode via OpenRouter. Any review agent or skill can opt into this by providing domain-specific system prompts and output formatting. This file defines the generic orchestration flow.

## What Council Mode Is

Instead of a single reviewer, council mode runs a 3-stage deliberation across **multiple LLM providers** (Claude, GPT, Gemini) via OpenRouter:

1. **Stage 1: Independent Assessments** — N models (typically 3, each from a different provider) independently evaluate the same artifact using the same instructions
2. **Stage 2: Anonymised Peer Review** — each model evaluates the others' assessments without knowing which model produced which
3. **Stage 3: Chairman Synthesis** — a chairman model reads everything and produces the final report

The key insight: genuine model diversity (different architectures, training data, biases) surfaces issues that any single model — or even multiple instances of the same model — would miss.

## Infrastructure

Council mode is powered by the **`llm-council` Python package** (`packages/llm-council/`), which provides:

- `LLMClient` — generic async OpenRouter client with JSON/text chat and retry logic
- `CouncilService` — 3-stage orchestration engine with customisable Stage 2/3 prompts
- `CouncilResult` — Pydantic models for structured results
- CLI — `python -m llm_council` for standalone use

The package is a shared dependency between Codex council mode and the topic-finder app. It requires `OPENROUTER_API_KEY` in the environment.

## When to Use

- Pre-submission quality checks (high stakes)
- When thoroughness matters more than speed
- When the user explicitly requests "council mode", "council review", or "thorough review"
- Never the default — standard single-reviewer mode remains the default for all consumers

## Prerequisites for a Consumer

An agent or skill that supports council mode must provide:

| What | Where | Purpose |
|------|-------|---------|
| **System prompt builder** | Consumer's `references/council-personas.md` | How to construct the system prompt sent to all models |
| **Output formatter** | Consumer's `references/council-prompts.md` | Stage 3 chairman prompt template + output format |
| **Council mode section** | Consumer's agent/skill body | Short section noting support + pointer to reference files |
| **Trigger phrases** | Consumer's frontmatter description/examples | How the user activates council mode |

## Orchestration Protocol

The **main session** orchestrates council mode. Review agents cannot orchestrate themselves (they lack Bash). When council mode is triggered:

### Pre-flight

1. Run the consumer's standard pre-checks and hard gates
2. If any gate fails, report immediately — do not invoke the council (save cost)
3. Collect all source material (file contents, logs, rubrics) into a system prompt and user message
4. Read the consumer's reference files for prompt construction guidance

### Stage 1: Independent Assessments

The main session invokes the `llm-council` package (via CLI or Python script). The library:

1. Sends the system prompt + user message to N different LLM models via OpenRouter
2. Each model independently produces a JSON assessment
3. All calls are parallel (async)
4. Failed models are logged and skipped — the council proceeds with available responses

**Default models:** `anthropic/claude-sonnet-4.5`, `openai/gpt-5`, `google/gemini-2.5-pro`

### Stage 2: Anonymised Peer Review

The library automatically:

1. Labels Stage 1 assessments as "Assessment A", "Assessment B", etc. (anonymised)
2. Sends all assessments to each model for cross-evaluation
3. Each model evaluates the others' work, identifies agreements/disagreements, and provides a ranking
4. Rankings are parsed and aggregated

**Model:** Same models as Stage 1 (each reviews the others' work).

### Stage 3: Chairman Synthesis

The library:

1. Sends all assessments and peer reviews to the chairman model
2. The chairman considers all inputs and produces a single synthesised response
3. The response follows the consumer's required output schema

**Default chairman:** `anthropic/claude-sonnet-4.5`

### Write Output

The main session receives the `CouncilResult` JSON and formats it into the consumer's standard output (e.g., `CRITIC-REPORT.md` for paper-critic). The report uses the consumer's standard format with two sections appended:

```markdown
## Council Notes

### Agreement Summary
- [N] issues confirmed by all reviewers
- [N] issues confirmed by majority
- [N] issues from single reviewer (validated in cross-review)
- [N] disputed issues (marked [DISPUTED])

### Aggregate Rankings
| Assessment | Model | Avg Rank | Rankings Count |
|------------|-------|----------|----------------|
| Assessment A | [model name] | X.X | N |
| Assessment B | [model name] | X.X | N |
| Assessment C | [model name] | X.X | N |

## Council Metadata
- **Mode:** Council ([N] models + peer review + chairman)
- **Models:** [list of model IDs used]
- **Chairman:** [chairman model ID]
- **Timing:** Stage 1: Xms, Stage 2: Xms, Stage 3: Xms, Total: Xms
- **Date:** YYYY-MM-DD
```

These sections are appended **after** the consumer's standard report content. Downstream consumers (e.g., fixer agent) that parse only the standard sections are unaffected.

## CLI Invocation

For simple cases, the main session can use the CLI directly:

```bash
uv run python -m llm_council \
    --system-prompt-file /tmp/council-system.txt \
    --user-message-file /tmp/council-user.txt \
    --models "anthropic/claude-sonnet-4.5,openai/gpt-5,google/gemini-2.5-pro" \
    --chairman "anthropic/claude-sonnet-4.5" \
    --output /tmp/council-result.json
```

For advanced cases (custom Stage 2/3 prompts), write a small Python script that imports `llm_council` and calls `CouncilService.run_council()` with `stage2_system` and `stage3_prompt_builder` parameters.

## Issue Resolution Rules (Chairman)

The consumer's chairman prompt should instruct the chairman to apply these rules:

| Situation | Action |
|-----------|--------|
| Issue confirmed by 2+ models | Retain at the **highest** agreed severity |
| Issue from 1 model, validated in peer review | Retain at the original severity |
| Issue from 1 model, disputed in peer review | Retain with `[DISPUTED]` tag; chairman makes final severity call |
| Issue found only in peer review (missed initially) | Add as a new finding |
| Conflicting severity assessments | Chairman decides; notes the range in the issue description |

**Scoring:** The chairman produces an independent score informed by all inputs — not a mechanical average.

## Model Configuration

| Parameter | Default | Override |
|-----------|---------|---------|
| Stage 1 models | `anthropic/claude-sonnet-4.5`, `openai/gpt-5`, `google/gemini-2.5-pro` | `--models` CLI flag |
| Chairman model | `anthropic/claude-sonnet-4.5` | `--chairman` CLI flag |
| Max tokens | 4096 | `--max-tokens` CLI flag |

The library's `config.py` contains the full model registry with tiers and pricing.

## Cost Considerations

Council mode costs significantly more than standard mode because it calls N models for Stage 1, N models for Stage 2, and 1 model for Stage 3 (total: 2N+1 API calls). With 3 models:

- **Standard mode:** 1 agent call (free — uses Codex context)
- **Council mode:** 7 OpenRouter API calls (3 + 3 + 1)

Pricing depends on the models chosen. Check OpenRouter for current rates. Use council mode when thoroughness justifies the cost — typically pre-submission or high-stakes reviews.

## Persona Support (Optional)

Each consumer can define **personas** in `references/council-personas.md` — distinct reviewer emphases that are prepended to the system prompt. Since council mode already uses different LLM providers (which bring natural perspective diversity), personas are optional but can add further differentiation.

Current approach: the same system prompt goes to all models. Personas are documented as reference material describing what each model *tends to focus on* based on its architecture. Future extension: per-model system prompt variants via the library's API.

## Consumers

| Consumer | Status | Notes |
|----------|--------|-------|
| `paper-critic` | Implemented | First consumer — Technical Rigour, Presentation, Scholarly Standards personas |
| `referee2-reviewer` | Planned | 5-audit protocol + council cross-review |
| `multi-perspective` | Planned | Already has Stage 1 + 3; add Stage 2 |
| `proofread` | Candidate | Lower value — diminishing returns on formatting |
| `code-review` | Candidate | Useful for complex codebases |
