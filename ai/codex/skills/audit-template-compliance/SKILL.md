---
name: audit-template-compliance
description: "Compare a project's LaTeX preamble against the working paper template. Reports missing features, conflicts, and redundancies. Optional --apply mode syncs changes interactively."
allowed-tools:
  - Read
  - Glob
  - Grep
  - Edit
  - Write
  - Bash(ls*)
  - Bash(latexmk*)
  - Bash(lualatex*)
  - Bash(biber*)
  - Skill
argument-hint: "[project-path] [--apply]"
---

# Template Compliance

> Compare a research project's LaTeX preamble against the working paper template (`templates/latex-wp/your-template.sty` + `your-bib-template.sty`). Classify every difference, produce a scored report, and optionally apply changes interactively.

## When to Use

- After the template has been updated and you want to check older papers
- Before submission — verify the preamble is clean and up to date
- When a paper has mysterious compilation issues (often a stale preamble)
- During periodic maintenance or alongside `$audit-project-structure`
- When starting work on a paper that hasn't been touched in a while

## When NOT to Use

- **Setting up a new project** — use `$init-project` instead (it copies the template)
- **Fixing compilation errors** — use `$latex-autofix` first, then run this
- **Non-LaTeX projects** — this skill is LaTeX-specific

---

## Critical Rules

1. **Never edit without `--apply`.** Default mode is report-only. Without `--apply`, the skill produces a report and exits.
2. **Never auto-apply Conflict items.** Conflicts always require explicit user confirmation via an explicit user confirmation prompt.
3. **Semantic comparison, not line-by-line.** Compare packages, options, commands, and environments as logical units — not raw text diffs.
4. **Preserve project-specific additions.** Items classified as **Keep** are informational. Never suggest removing them unless they conflict with a template feature.
5. **Template is the reference, not the authority.** Projects may legitimately diverge. The skill reports differences — the user decides what to act on.
6. **Compile after applying.** If `--apply` makes any changes, always verify with `$latex-autofix`.

---

## Protocol

### Phase 1: Locate & Parse

1. **Resolve the project path.** Accept as argument or use CWD. Resolve to absolute path.
2. **Find the project's preamble files.** The canonical location is the **Overleaf document**, accessed via the `paper/` symlink in the project directory. Search in this order:
   - **New format (`.sty` files):** `paper/your-template.sty` + `paper/your-bib-template.sty` (Overleaf symlink — **preferred**)
   - **Legacy format:** `paper/settings.tex` (Overleaf symlink)
   - If no `paper/` symlink exists, check for an Overleaf folder directly: `~/Library/CloudStorage/YOUR-CLOUD/Apps/Overleaf/<Paper Name>/your-template.sty` (or `settings.tex`)
   - Project root: `your-template.sty` + `your-bib-template.sty` or `settings.tex` (for local-only projects without Overleaf)
   - Any `\input{settings}` or `\usepackage{your-template}` in `main.tex` pointing elsewhere

   **NEVER** check settings/style files in subdirectories like `docs/`, `to-sort/`, `docs/venues/`, or any non-paper location. Only the main paper's preamble is relevant.

   If no preamble files are found, report error and exit.

3. **Read the template.** Search in this order:
   - `~/Library/CloudStorage/YOUR-CLOUD/Apps/Overleaf/Template/your-template.sty` + `your-bib-template.sty` (Overleaf source)
   - `~/Library/CloudStorage/YOUR-CLOUD/Task Management/templates/latex-wp/your-template.sty` + `your-bib-template.sty` (local copy — identical)
   - Legacy fallback: `settings.tex` in either location

   If no template files are found, report "Template not found — cannot compare. Verify that the Overleaf Template folder exists or the local copy in `templates/latex-wp/`." and exit.

4. **Parse both files into semantic blocks:**

   | Block | What to extract |
   |-------|----------------|
   | **Packages** | Package name + options (e.g., `[dvipsnames]{xcolor}`) |
   | **Hyperref** | All `\hypersetup{}` key-value pairs + `\urlstyle` |
   | **Bibliography** | System (biblatex/natbib), all options, `\addbibresource`, source mappings, field clearing (`\AtEveryBibitem`), possessive citation commands |
   | **Custom commands** | All `\newcommand`, `\renewcommand`, `\DeclareMathOperator`, `\newcolumntype` |
   | **Theorem environments** | All `\newtheorem` declarations with their styles and counters |
   | **Build config** | `.latexmkrc` content (engine, output dir, PDF copy-back) |

   For packages, normalise options: `\usepackage[a,b]{pkg}` and `\usepackage[b,a]{pkg}` are equivalent.

---

### Phase 2: Compare

For each semantic block, compare the project against the template. Detailed check tables for each block: [`references/comparison-checklist.md`](references/comparison-checklist.md)

Blocks to compare: **Packages** (missing, extra, options, load order, duplicates) · **Hyperref** (missing keys, different values, urlstyle, cleveref ordering) · **Bibliography** (system mismatch, options, source mappings, field clearing, possessive citations) · **Custom Commands** (missing, different definitions, column types, math commands) · **Theorem Environments** (missing, different styles/counters, numberwithin) · **Build Config** (.latexmkrc existence, engine, output dir, PDF copy-back)

---

### Phase 3: Classify

Label every difference with: **Adopt** (missing from project, safe to add) · **Keep** (project-specific, informational) · **Conflict** (needs human judgement, always ask) · **Drop** (redundant/superseded).

Full classification rules and when-to-use-each-label guidance: [`references/comparison-checklist.md`](references/comparison-checklist.md#phase-3-classification-rules)

---

### Phase 4: Check Auxiliaries

Check `main.tex` (preamble loading, documentclass, printbibliography, no stale bibliography commands) and `.latexmkrc` (exists, engine, output dir, PDF copy-back).

Full check tables: [`references/comparison-checklist.md`](references/comparison-checklist.md#phase-4-auxiliary-checks)

---

### Phase 5: Report

Produce a structured compliance report. Full format: [`references/report-format.md`](references/report-format.md)

#### Quality Score

Start at **100** and deduct per issue:

| Severity | Deduction | Examples |
|----------|-----------|----------|
| **Major** | -5 | Missing `.latexmkrc`, natbib vs biblatex conflict, missing `hyperref`, missing `cleveref`, `hyperref`/`cleveref` load order wrong |
| **Moderate** | -2 | Missing common packages (booktabs, microtype, enumitem), missing `dvipsnames`, duplicate package loads, missing custom commands (\todo, \red, \blue), missing source mappings, missing field clearing |
| **Minor** | -1 | Missing optional packages, different hyperref colours, missing theorem environments, missing math operators, missing `\numberwithin` |

#### Score Interpretation

| Score | Label |
|-------|-------|
| 90-100 | Excellent — fully aligned |
| 75-89 | Good — minor gaps only |
| 50-74 | Needs attention — several missing features |
| < 50 | Significant drift — consider full resync |

#### Report Sections

1. **Header**: Project name, path, score, date
2. **Summary table**: Counts by classification (Adopt / Keep / Conflict / Drop)
3. **Per-item detail**: Grouped by semantic block, showing classification + what/why
4. **Auxiliaries**: main.tex and .latexmkrc checks
5. **Recommendations**: Prioritised list of suggested actions

If `--apply` is not set, end with:
```
Run `$audit-template-compliance <path> --apply` to interactively apply changes.
```

---

### Phase 6: Apply (--apply mode only)

Apply changes in dependency order to avoid compilation breakage:

1. **Package options** (e.g., add `dvipsnames` to xcolor)
2. **Missing packages** (insert in correct position relative to existing packages)
3. **Hyperref configuration** (update `\hypersetup{}` block)
4. **Bibliography changes** (only if user approves — always ask for explicit user confirmation for system changes)
5. **Custom commands** (append after existing commands section)
6. **Theorem environments** (append after existing theorem section)
7. **`.latexmkrc`** (create or update)
8. **Cleanup** (remove duplicates, drop redundancies)

#### Apply Rules

- **Show a summary first.** Before making any edits, present the full list of changes to be applied (Adopt + Drop items) and ask for confirmation.
- **Conflicts are always individual.** Each Conflict item gets its own explicit confirmation prompt with the template version, project version, and context.
- **Keep items are never touched.** They appear in the report but are skipped during apply.
- **Preserve comments and whitespace.** When inserting packages, match the project's existing formatting style (e.g., if packages are grouped with comment headers, add to the right group).
- **Log what was changed.** After applying, list every edit made.

---

### Phase 7: Verify (--apply mode only)

After applying changes:

1. **Compile with `$latex-autofix`.** This handles any secondary issues the changes might introduce.
2. **Report the result:**
   - If compilation succeeds: report success + number of changes applied
   - If compilation fails: report the error, suggest reverting specific changes, and note which change likely caused the issue

---

## What This Skill Does NOT Do

- **Does not rewrite `main.tex` structure.** Only checks `\input{settings}` and bibliography commands.
- **Does not check content quality.** Use `$proofread` for that.
- **Does not manage `.bib` files.** Use `$validate-bib` for bibliography key issues.
- **Does not handle journal-specific formatting.** Use `$retarget-journal` for that.
- **Does not compare across projects.** Checks one project at a time against the template.

---

## Examples

### Report only (default)

> "$audit-template-compliance ~/papers/costly-voice"

Produces a compliance report without making any changes.

### Apply mode

> "$audit-template-compliance ~/papers/costly-voice --apply"

Produces the report, then interactively applies Adopt and Drop changes with user confirmation.

### Current directory

> "Check my template compliance"

Runs on the current working directory in report-only mode.

### After template update

> "I updated the template — check all my papers"

Run on each project individually. This skill checks one project at a time.

---

## Cross-References

- **`templates/latex-wp/your-template.sty`** + **`your-bib-template.sty`** — the canonical template this skill compares against
- **`$latex-autofix`** — used in Phase 7 to verify compilation after applying changes
- **`$audit-project-structure`** — complementary: checks directory structure, this checks LaTeX preamble
- **`$validate-bib`** — complementary: checks citation keys, this checks bibliography system config
- **`$init-project`** — creates projects from the template; this skill verifies ongoing compliance
- **`$retarget-journal`** — handles journal-specific formatting (different concern)
