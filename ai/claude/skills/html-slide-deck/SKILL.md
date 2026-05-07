---
name: html-slide-deck
description: >
  Generate a single-file HTML slide deck from a set of source notes (Obsidian or
  plain Markdown), a technical writeup, or a cluster of experiment logs. Use
  this skill whenever the user asks for slides, a presentation, a 발표자료, a
  deck, a lab-meeting summary, a "summarize these notes as slides," or any
  request to turn multiple written artifacts into a presentation — even if they
  do not say the word "HTML." The output is a self-contained .html file with
  one CDN dependency (KaTeX for math), keyboard navigation, A4-landscape print
  support, inline SVG charts, and an opinionated academic-paper aesthetic (white
  background, matplotlib tab10 palette, system font). Supports English and
  Korean content equally.
---

# HTML Slide Deck

Turn a cluster of source notes into a single-file HTML presentation. Optimized for lab meetings, internal technical reviews, and research updates — the kind of deck where the audience needs numbers, formulas, and source-provenance, not stock photos.

## When to use

- User has several notes / experiment logs / analysis documents and wants a presentation.
- User says: make slides, presentation, deck, 발표자료, lab meeting summary, summarize as slides, HTML slides.
- The deck will be viewed in a browser (not PowerPoint / Keynote) and shared as a file or link.

Do **not** use for: .pptx output (use `anthropic-skills:pptx`), single-page documents (use plain Markdown), or when the user specifically asks for Reveal.js / Slidev / Marp syntax.

## Output contract

A single `.html` file at a user-chosen location. The file:

- Loads with exactly one CDN dependency: KaTeX (for math rendering). Everything else is inline.
- Shows one slide at a time, centered in the viewport, auto-scaled to fit any window.
- Responds to ←/→ or PageUp/PageDown to navigate, `f` to toggle fullscreen, `p` for print preview (A4 landscape), and `1`–`9` to jump to slide N.
- Each slide carries its source-note path in the bottom-left footer and its page number in the bottom-right — provenance is mandatory for technical decks.
- Prints cleanly: `@media print` lays out all slides sequentially, one A4-landscape page each.

## Workflow

### 1. Understand the source material

Ask the user which notes / files are the source, or extract the list from the conversation if they were already discussed. Skim each source and identify:

- The **central claim** the deck should make (the three-line summary).
- Key **numbers, tables, and formulas** worth quoting verbatim.
- **Figures** (embedded images, `Attachments/...`) — note whether they need to be inlined, linked, or reconstructed as inline SVG.
- **Narrative arc**: problem → theory → experiments → climax → next steps. See `references/layouts.md` § "Narrative scaffolds" for typical decompositions at 10-slide vs 25–30-slide sizes.

If anything is ambiguous (audience, language, length), ask the user before drafting. Common decisions:

- **Audience**: lab meeting (keep debugging, numbers), Ph.D. defense rehearsal (theory-forward, condensed), external talk (simplified, more context).
- **Language**: English, Korean, or bilingual. The template is language-agnostic — just use one consistently. KaTeX handles both.
- **Length**: 10–12 (short, one message), 15–20 (medium), 25–30+ (full).

### 2. Draft the narrative before touching HTML

Write a flat list of slides — kicker + one-line H1 claim + source note — in plain text first, then show it to the user for feedback. This catches structural problems before you start moving divs around. Format:

```
1. Title — RDBDock Recent Progress
2. Part 1 — "Input is already biased by ~1.6 Å" [2026-04-18 ETKDG vs Crystal]
3. ...
```

One claim per slide. If you cannot state the H1 as a short assertion, the slide is not ready.

### 3. Copy the template and fill it in

Copy `assets/template.html` to the destination path. The template contains:

- Full CSS (colors, layouts, typography, print rules) — do not modify without reason.
- Viewport-center positioning via `position:absolute; top:50%; left:50%; transform: translate(-50%,-50%) scale(var(--s))`. The `--s` CSS variable is set by a small JS `fit()` function on load and resize. This is the critical pattern that makes the deck render correctly at any window size — do not replace it with flexbox centering, which breaks when the slide's layout box (1280×720) exceeds the viewport.
- A `#deck` container where slides go.
- Keyboard nav + print media query already wired up.

Drop each slide as a `<section class="slide">` inside `#deck`. The **first** slide should additionally carry the `active` class (the JS also applies it on load, but having it in HTML avoids flash).

Read `references/layouts.md` for ready-to-paste patterns: title slide, two-col, three-col, big-stat, callout, three-lines summary, tables, inline SVG bar charts, KaTeX math, appendix. Each pattern includes the rationale for when to use it.

### 4. Verify numbers against source notes

Technical decks live or die on numeric accuracy. Before declaring the draft done, sample 3–5 of the most prominent numbers (big-stat headlines, best-config percentages, oracle uplift) and cross-check them against the exact source notes. Mismatches erode trust faster than any layout issue.

### 5. Verify in a browser

Open the HTML locally and step through with ←/→. Watch for:

- KaTeX rendering failures (missing braces, `\text{}` around underscores in math).
- Overflowing tables or bullet lists (slide height is fixed at 720 px before scaling — content must fit).
- Broken SVG charts (miscalculated bar heights are common — compute numerically, do not eyeball).
- Footer source-note path mismatches.

Also try `⌘P` / `Ctrl+P` to confirm the print view tiles each slide onto its own landscape page.

## Style constraints (do not negotiate)

The deck must look like a matplotlib figure or an academic paper page, not a SaaS dashboard. These rules come from `~/.claude/CLAUDE.md § HTML Visualization Style` and are baked into the template CSS — do not override:

- **Background**: white (`#fff`) or light grey (`#f5f5f5`). Never dark themes (Catppuccin, Nord, Dracula, Solarized Dark) unless explicitly requested.
- **Colors**: matplotlib tab10 — `#1f77b4`, `#ff7f0e`, `#2ca02c`, `#9467bd`, `#8c564b`, with `#d62728` red reserved for "bad" / "before fix" signals. Max 4–5 series per chart.
- **Grid**: horizontal only, `#ebebeb`. Axis spines `#ccc`. No chart-area background fill.
- **Typography**: system font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif`). No Google Fonts. Body `#222`, labels `#555`, ticks `#888`.
- **No rounded cards, no box shadows, no gradients.** Border: `1px solid #ddd` on chart boxes and slide frames, nothing more.
- **Tabular numerals** everywhere numbers live (`font-variant-numeric: tabular-nums` — already in the table and stat styles).

## Anti-patterns

- **Do not introduce a slide framework** (Reveal.js, Slidev, Marp). The skill's value is being dependency-free. If the user wants a framework, suggest they use its native tooling instead.
- **Do not use flex centering for the slide container.** It silently crops when the window is narrower than 1280 px because `transform: scale` does not shrink the layout box. The template's `position:absolute + translate(-50%,-50%) scale(var(--s))` is the only pattern that works.
- **Do not create a separate CSS file.** The deck must be portable as a single file — inline everything except KaTeX.
- **Do not omit the source-note footer.** In a technical deck, provenance is load-bearing. Every non-title slide should have `<div class="footer"><span class="src">path/to/note.md</span><span>N / N</span></div>`.
- **Do not write narrative commentary into slides** ("as we saw earlier…", "next we will…"). Slide content is the artifact the audience reads; transitions belong in your speaking notes.

## Language notes

The user may write in Korean. When producing Korean content, apply the 평어체 convention from `~/.claude/CLAUDE.md` (sentence endings in `-하다`, `-한다`, `-이다`, `-했다`) rather than `-합니다` / `-습니다`. Do not mix registers within a deck. KaTeX renders the same regardless of surrounding language.

## Files

- [`assets/template.html`](assets/template.html) — the single-file scaffold. Start by copying this.
- [`references/layouts.md`](references/layouts.md) — copy-paste HTML patterns for every layout primitive + narrative scaffolds for different deck lengths.
