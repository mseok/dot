# Audit Check Details

> Detailed check specifications for `$audit-project-structure`. The SKILL.md has pointers here — read this when executing the relevant phase.

---

## Phase 3.5: Recognized Growth Patterns

Projects naturally grow beyond the initial scaffold. These are documented in `$init-project` as expected additions:

| Pattern | Recognized as |
|---------|---------------|
| `experiments/` | Experiment configs, sweep logs, results |
| `experiments/configs/` | Parameter sweep definitions |
| `scripts/` | Utility scripts (data processing, plotting) |
| `legacy/` | Preserved old code/data (per `$project-safety`) |
| `correspondence/reviews/<venue>-roundN/` | Reviewer comments, rebuttal, analysis per R&R round |
| `correspondence/reviews/<venue>-roundN/analysis/` | Comment tracker, review analyses, verbatim tex |
| `docs/<venue>/internal-reviews/` | Internal review work (referee2 agent reports) |
| `docs/venues/<venue>/camera-ready/` | Final accepted version |
| `notes.md` | Quick research notes, meeting summaries |
| `SETUP.md` | Environment setup instructions |
| `pyproject.toml` | Python package management |
| `.venv/` | Virtual environment |

When a recognized pattern is found, report it as **Info** — present and expected.

### Unrecognized items

Any top-level directory or file that is **not** part of the common core, conditional structure, or recognized growth patterns should be flagged as **Info — unrecognized** for user review. Do not flag hidden files/directories that are standard (`.git/`, `.DS_Store`, etc.).

---

## Phase 3.6: Pre-Template Detection & Remediation

### Pre-template project detection

If the project has **no `.context/`** AND **no `.codex/`**, flag it as a **pre-template project** and add a consolidated note:

```
Pre-template project detected
===============================
This project predates the current init-project template.
To bring it into the framework, consider adding:

  1. mkdir -p .context && touch .context/current-focus.md .context/project-recap.md
  2. mkdir -p .codex && copy settings.local.json from another project
  3. Create an AGENTS.md (see $init-project Phase 3 for template)
  4. mkdir to-sort && touch to-sort/.gitkeep
  5. Merge global permissions into `.codex/settings.local.json` (see Phase 3.11)

Or run $init-project in "retrofit" mode if available.
```

### Remediation suggestions

For each missing common core item, include a one-line remediation suggestion:

| Missing item | Suggestion |
|-------------|------------|
| `.context/` | `mkdir -p .context && touch .context/current-focus.md .context/project-recap.md` |
| `.gitignore` | Copy template from `$init-project` Phase 3 |
| `.codex/settings.local.json` | Run Phase 3.11 permissions sync (or create manually) |
| `to-sort/` | `mkdir to-sort && touch to-sort/.gitkeep` |
| `AGENTS.md` | See `$init-project` Phase 3 for template |
| `README.md` | See `$init-project` Phase 3 for template |
| `correspondence/` | `mkdir -p correspondence/reviews && touch correspondence/reviews/.gitkeep` |
| `docs/` | `mkdir -p docs/{literature-review,readings}` |
| `docs/literature-review/` | `mkdir -p docs/literature-review && touch docs/literature-review/.gitkeep` — `$literature` outputs go here |
| `docs/venues/` | `mkdir -p docs/venues && touch docs/venues/.gitkeep` |
| `log/` | `mkdir log && touch log/.gitkeep` |
| `MEMORY.md` | Seed from `$init-project` Phase 3 template (research or teaching variant) |

---

## Phase 3.7: Overleaf Separation Check

If `paper/` exists (symlink or directory), scan it for files that violate the Overleaf separation rule. **This is a hard rule — any violations are flagged as Missing (not Info).**

### Forbidden file types in `paper/`

| Pattern | Category |
|---------|----------|
| `*.py`, `*.R`, `*.jl`, `*.m`, `*.sh`, `*.ipynb`, `*.do` | Code |
| `*.csv`, `*.xlsx`, `*.json` (non-LaTeX), `*.dta`, `*.parquet`, `*.rds`, `*.pkl`, `*.feather`, `*.h5` | Data |
| `requirements.txt`, `pyproject.toml`, `renv.lock` | Package management |
| `.venv/`, `__pycache__/`, `node_modules/` | Runtime artifacts |

### Allowed in `paper/`

- `.tex`, `.sty`, `.cls`, `.bst`, `.bbl`, `.bib`
- `.pdf`, `.png`, `.eps`, `.jpg`, `.svg`, `.tikz` (figures)
- `.latexmkrc`, `latexmkrc`
- `out/` (build directory)
- `.gitignore`, `README.md` (if Overleaf-generated)

### Required in `paper/`

| File | Check | Severity |
|------|-------|----------|
| `.latexmkrc` | Must exist — needed for `out/` build convention and local compilation | **Missing** if absent |

The `.latexmkrc` should contain at minimum `$out_dir = 'out';` and an `END {}` block to copy the PDF back. If it exists but is missing `$out_dir`, flag as **Degraded**.

### How to check

```bash
# Recursively find forbidden file types inside paper/
find "<project-path>/paper/" -type f \( \
  -name "*.py" -o -name "*.R" -o -name "*.jl" -o -name "*.m" \
  -o -name "*.sh" -o -name "*.ipynb" -o -name "*.do" \
  -o -name "*.csv" -o -name "*.xlsx" -o -name "*.dta" \
  -o -name "*.parquet" -o -name "*.rds" -o -name "*.pkl" \
  -o -name "*.feather" -o -name "*.h5" \
  -o -name "requirements.txt" -o -name "pyproject.toml" \
  -o -name "renv.lock" \
\) 2>/dev/null
```

Also check for directories that should never exist inside `paper/`:
```bash
find "<project-path>/paper/" -type d \( \
  -name ".venv" -o -name "__pycache__" -o -name "node_modules" \
  -o -name "renv" \
\) 2>/dev/null
```

### Report format

For each violation found:

```
✗ Overleaf separation violation: paper/<path-to-file>
  Category: Code / Data / Package management / Runtime artifact
  Remediation: Move to <suggested-project-directory>
```

Suggested destinations follow the rule in `.codex/rules/overleaf-separation.md`:
- Code files → `code/` or `src/`
- Data files → `data/raw/` or `data/processed/`
- Package files → project root
- Notebooks → `code/` or `experiments/`

---

## Phase 3.8: Rules Sync

**This is the one phase that modifies the project.** It ensures every research project has a `.codex/rules/` directory mirroring the global rules from `~/.codex/rules/`.

### Source of truth

The 12 global rules in `~/.codex/rules/` (which is a symlink to Task Management's `.codex/rules/`). List them at runtime:

```bash
ls ~/.codex/rules/*.md
```

### Comparison logic

1. List global rules: `ls ~/.codex/rules/*.md` → canonical set (filenames only)
2. Check if `<project>/.codex/rules/` exists
3. If it doesn't exist → create it and copy all rules (see below)
4. If it exists → compare each global rule against the project copy:

| Condition | Classification | Action |
|-----------|---------------|--------|
| In global, not in project | **Missing** | Copy from global |
| In both, content differs | **Outdated** | Overwrite with global version |
| In both, content matches | **Synced** | No action |
| In project, not in global | **Extra** | Leave alone, report as Info |

### Content comparison

Use `diff -q` for fast comparison:

```bash
# Check if project rules dir exists
if [ ! -d "<project>/.codex/rules" ]; then
  mkdir -p "<project>/.codex/rules"
fi

# Compare each global rule
for rule in ~/.codex/rules/*.md; do
  name=$(basename "$rule")
  target="<project>/.codex/rules/$name"
  if [ ! -f "$target" ]; then
    # Missing — copy
    cp "$rule" "$target"
  elif ! diff -q "$rule" "$target" > /dev/null 2>&1; then
    # Outdated — overwrite
    cp "$rule" "$target"
  fi
done
```

### Extra rules detection

```bash
# Find rules in project that don't exist globally
for rule in "<project>/.codex/rules/"*.md; do
  name=$(basename "$rule")
  if [ ! -f ~/.codex/rules/"$name" ]; then
    echo "Extra: $name"
  fi
done
```

### Report format

For the Phase 6 report, add a `Rules Sync:` section:

```
Rules Sync:
  .codex/rules/             ✓ synced (12/12 rules)
```

Or when action was taken:

```
Rules Sync:
  .codex/rules/             ⚠ created directory, copied 12 rules
  break-the-glass.md         ✓ copied (was missing)
  data-sensitivity.md        ✓ updated (was outdated)
  scope-discipline.md        ✓ synced
  custom-project-rule.md     ℹ extra — not in global (left alone)
```

### Edge cases

- **No `.codex/` directory at all:** Create `.codex/rules/` (mkdir -p handles this)
- **Pre-template projects:** Phase 3.6 already flags these. Rules sync still runs — having rules without the rest of the scaffold is harmless
- **Symlinked `.codex/rules/`:** If the project's `.codex/rules/` is itself a symlink, skip sync and report as Info ("rules dir is a symlink — skipping sync")

---

## Phase 3.9: Review Process Consistency

If `correspondence/reviews/` exists and is non-empty, verify that review documents follow the process-reviews workflow's expected structure. Also detect misplaced review files elsewhere in the project.

### Expected structure per round

The process-reviews workflow outputs this structure:

```
correspondence/reviews/{venue}-round{n}/
├── reviews-original.pdf              (copy of referee reports)
├── rebuttal.md                       (response draft — may not exist yet)
└── analysis/
    ├── comment-tracker.md            (atomic comment matrix)
    ├── review-analysis.md            (strategic overview)
    └── reviewer-comments-verbatim.tex (LaTeX transcription)
```

### Step 1: Validate round directories

List directories inside `correspondence/reviews/`. Each should match the pattern `{venue}-round{n}` (e.g., `ejor-round1`, `facct-2026-round2`).

| Condition | Severity |
|-----------|----------|
| Directory matches `*-round*` pattern | OK — check contents |
| Directory does not match pattern | **Info** — "unrecognized directory in correspondence/reviews/" |
| No directories found (only `.gitkeep` or empty) | **Info** — "correspondence/reviews/ exists but has no round directories" |

### Step 2: Check required files per round

For each round directory, check:

| File | Required | Severity if absent |
|------|----------|-------------------|
| `reviews-original.pdf` | Yes | **Missing** — "no original reviews PDF in {round}/" |
| `analysis/` | Yes | **Missing** — "no analysis/ subdirectory in {round}/" |
| `analysis/comment-tracker.md` | Yes | **Missing** — "no comment tracker in {round}/analysis/" |
| `analysis/review-analysis.md` | Yes | **Missing** — "no review analysis in {round}/analysis/" |
| `analysis/reviewer-comments-verbatim.tex` | Yes | **Missing** — "no verbatim transcription in {round}/analysis/" |
| `rebuttal.md` | No | Not flagged if absent (created when response work begins) |

### Step 3: Check for build artifacts

Scan each round directory for LaTeX build artifacts that should be in `out/` or absent:

```
*.aux, *.bbl, *.blg, *.fdb_latexmk, *.fls, *.log, *.synctex.gz, *.dvi
```

| Condition | Severity |
|-----------|----------|
| Build artifacts in `analysis/` (not inside `out/`) | **Degraded** — "build artifacts in analysis/ — should be in analysis/out/ or cleaned" |
| `analysis/out/` exists with artifacts | OK — correct location |

### Step 4: Detect misplaced review files

Scan `docs/venues/` for files that look like they belong in `correspondence/reviews/`:

```bash
# Patterns that suggest misplaced review documents
find "<project>/docs/venues/" -type f \( \
  -name "reviewer-comment*" -o -name "comment-tracker*" \
  -o -name "review-analysis*" -o -name "*reviewer-reports*" \
  -o -name "*referee-report*" -o -name "reviews-original*" \
\) 2>/dev/null
```

Also check for directories named `reviewer-comments/` or `reviews/` inside `docs/venues/`:

```bash
find "<project>/docs/venues/" -type d \( \
  -name "reviewer-comments" -o -name "reviews" \
\) 2>/dev/null
```

| Condition | Severity |
|-----------|----------|
| Review files found in `docs/venues/` | **Degraded** — "review file found in docs/venues/ — should be in correspondence/reviews/{venue}-round{n}/" |
| `reviewer-comments/` directory in `docs/venues/` | **Degraded** — "reviewer-comments/ directory found in docs/venues/ — review documents belong in correspondence/reviews/" |

### Step 5: Check for version consistency

If multiple versions of the same file exist (e.g., `comment-tracker.md` and `comment-tracker-v2.md`), report as **Info** — "multiple versions found — verify latest is current".

### Report format

```
Review Process Consistency:
  correspondence/reviews/ejor-round1/
    reviews-original.pdf       ✓ present
    analysis/                  ✓ present
      comment-tracker.md       ✓ present
      review-analysis.md       ✓ present
      reviewer-comments-verbatim.tex  ✓ present
    rebuttal.md                ℹ not yet created

  Misplaced files:             ✓ none found in docs/venues/
```

Or when issues are found:

```
Review Process Consistency:
  correspondence/reviews/ejor-round1/
    reviews-original.pdf       ✓ present
    analysis/                  ✗ missing

  Misplaced files:
    ⚠ docs/venues/ejor/revision-1/reviewer-comments/comment-tracker.md
      → should be in correspondence/reviews/ejor-round1/analysis/
```

### When to skip

- If `correspondence/reviews/` does not exist — Phase 2 already flags this as Missing
- If the project is theoretical with no venue history

---

## Phase 3.10: LaTeX Build Config Consistency

Every directory that contains `.tex` files must have a `.latexmkrc` with `$out_dir = 'out'` so build artifacts stay out of the source directory. This enforces the `latex-outdir` rule project-wide.

### Step 1: Find directories with `.tex` files

```bash
# Find all directories containing .tex files, deduplicated
find "<project>" -name "*.tex" -not -path "*/out/*" -not -path "*/.git/*" \
  -exec dirname {} \; | sort -u
```

### Step 2: Exclude directories

Skip these — they have their own compilation conventions:

| Directory | Reason |
|-----------|--------|
| `paper/` (if symlink to Overleaf) | Overleaf-managed — Phase 3.7 handles separately |
| Any `out/` directory | Build output, not source |
| Any `legacy/` or `archive/` directory | Preserved old files, not actively compiled |

### Step 3: Check each directory

For each remaining directory with `.tex` files:

#### 3a: `.latexmkrc` existence

| Condition | Severity |
|-----------|----------|
| `.latexmkrc` exists | Check contents (Step 3b) |
| `.latexmkrc` missing | **Missing** — ".latexmkrc missing in {dir}/ — build artifacts will pollute source directory" |

#### 3b: `.latexmkrc` content validation

Read the `.latexmkrc` and check for required directives:

| Directive | Required | Severity if absent |
|-----------|----------|-------------------|
| `$out_dir = 'out'` (or equivalent) | Yes | **Degraded** — ".latexmkrc in {dir}/ missing `$out_dir = 'out'`" |
| `$pdf_mode` set | No | Not flagged — defaults are acceptable |

Match `$out_dir` flexibly: accept `$out_dir = 'out'`, `$out_dir = "out"`, `$out_dir='out'` (with or without spaces).

#### 3c: Stale build artifacts

If `.latexmkrc` is correct but build artifacts exist in the source directory (not in `out/`), flag:

```bash
# Check for build artifacts alongside .tex files (not inside out/)
find "<dir>" -maxdepth 1 \( \
  -name "*.aux" -o -name "*.bbl" -o -name "*.blg" \
  -o -name "*.fdb_latexmk" -o -name "*.fls" -o -name "*.log" \
  -o -name "*.synctex.gz" -o -name "*.toc" -o -name "*.nav" \
  -o -name "*.snm" -o -name "*.vrb" -o -name "*.dvi" \
  -o -name "*.bcf" -o -name "*.run.xml" \
\) 2>/dev/null
```

| Condition | Severity |
|-----------|----------|
| Build artifacts in source directory | **Degraded** — "build artifacts in {dir}/ — run `latexmk -C` or move to out/" |
| No artifacts outside `out/` | OK |

### Report format

```
LaTeX Build Config:
  presentations/               ✓ .latexmkrc present, $out_dir = 'out'
  docs/venues/ejor/revision-1/response/  ✓ .latexmkrc present, $out_dir = 'out'
  correspondence/reviews/ejor-round1/analysis/  ✗ .latexmkrc missing
```

### Standard `.latexmkrc` (for remediation suggestions)

When flagging a missing `.latexmkrc`, include the standard content:

```perl
$out_dir = 'out';
$pdf_mode = 1;
$pdflatex = 'pdflatex -interaction=nonstopmode -halt-on-error %O %S';
```

For Beamer presentations using custom fonts (LuaLaTeX):

```perl
$out_dir = 'out';
$pdf_mode = 4;
$lualatex = 'lualatex -interaction=nonstopmode -halt-on-error %O %S';
```

### When to skip

- If no `.tex` files exist anywhere in the project
- Directories inside `paper/` when it's an Overleaf symlink

---

## Phase 3.11: Permissions Sync

**This phase modifies the project** (like Phase 3.8). It ensures the project's `.codex/settings.local.json` has all global permissions from `~/.codex/settings.json`.

### Source of truth

The global permissions in `~/.codex/settings.json` under `permissions.allow` and `permissions.deny`.

### Comparison logic

1. Read global settings: `jq '.permissions.allow // []' ~/.codex/settings.json`
2. Check if `<project>/.codex/settings.local.json` exists
3. If it doesn't exist → create it with global permissions (same startup sync behavior)
4. If it exists → compute the union:

| Condition | Classification | Action |
|-----------|---------------|--------|
| In global, not in local | **Missing** | Add to local |
| In both | **Synced** | No action |
| In local, not in global | **Project-specific** | Leave alone (Info) |

### Implementation

```bash
# If no local settings exist, seed from global
if [ ! -f "<project>/.codex/settings.local.json" ]; then
  mkdir -p "<project>/.codex"
  jq '{permissions: {allow: (.permissions.allow // []), deny: (.permissions.deny // [])}}' \
    ~/.codex/settings.json > "<project>/.codex/settings.local.json"
fi

# Merge allow + deny arrays (additive union, preserving all other keys)
jq -s '.[0].permissions.allow as $ga | .[0].permissions.deny as $gd |
  .[1] |
  .permissions.allow = ((.permissions.allow // []) + $ga | unique | sort) |
  .permissions.deny = ((.permissions.deny // []) + $gd | unique | sort)' \
  ~/.codex/settings.json "<project>/.codex/settings.local.json" \
  > "<project>/.codex/settings.local.json.tmp" \
  && mv "<project>/.codex/settings.local.json.tmp" "<project>/.codex/settings.local.json"
```

### Report format

```
Permissions Sync:
  .codex/settings.local.json   ✓ synced (64/64 allow, 4/4 deny)
```

Or when action was taken:

```
Permissions Sync:
  .codex/settings.local.json   ⚠ added 3 allow permissions (WebFetch, Skill(literature), Bash(jq*))
  .codex/settings.local.json   ⚠ added 1 deny permission (Bash(pip*))
  Total: 67 allow, 5 deny
```

Or when the file was created:

```
Permissions Sync:
  .codex/settings.local.json   ⚠ created with 25 allow, 4 deny permissions from global
```

### Edge cases

- **No `.codex/` directory at all:** Create `.codex/` and seed `settings.local.json` from global
- **`settings.local.json` has non-permissions keys (hooks, model):** Preserve them — only merge the `permissions` object
- **Pre-template projects:** Phase 3.6 already flags these. Permissions sync still runs — having permissions without the rest of the scaffold is harmless

### What this does NOT do

- Never removes existing local permissions (additive only)
- Never modifies `~/.codex/settings.json` (reads it, never writes)
- Never touches `model`, `hooks`, or other settings keys
