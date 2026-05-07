# Layout Primitives

Copy-paste HTML patterns. Each `<section class="slide">` is one slide — drop inside the `#deck` container in `template.html`.

The `kicker` (small uppercase label) marks which part/section a slide belongs to. The `footer` has a left slot for the source file (source-provenance — critical for technical decks) and a right slot for the page number. Always fill both.

---

## 1. Title slide

Use for the opening slide. Big title, divider, meta lines (subtitle, author, date).

```html
<section class="slide active title-slide">
  <div class="kicker">Project · Context</div>
  <h1>Main Title<br>Second Line</h1>
  <div class="divider"></div>
  <div class="meta">Date range · Scope · Benchmark name</div>
  <div class="meta" style="margin-top:6px;">Author · YYYY-MM-DD</div>
  <div class="footer"><span>deck short label</span><span>1 / N</span></div>
</section>
```

Only the first slide should have the `active` class pre-set.

---

## 2. Kicker + H1 + body (the workhorse)

Most slides use this. Kicker at top tells the audience where they are in the narrative; H1 is the single claim of the slide.

```html
<section class="slide">
  <div class="kicker">Part 3 — Debugging</div>
  <h1>One claim, one slide</h1>
  <p>Opening sentence that sets up the evidence.</p>
  <ul>
    <li>Bullet 1 with a concrete number.</li>
    <li>Bullet 2.</li>
  </ul>
  <div class="footer"><span class="src">source-note.md</span><span>N / N</span></div>
</section>
```

---

## 3. Two-column layout

Use when comparing two things (before/after, setup/result, theory/implication). Left-right reads naturally.

```html
<section class="slide">
  <div class="kicker">Part X</div>
  <h1>Two things side by side</h1>
  <div class="two-col">
    <div>
      <h3>Left column heading</h3>
      <ul>
        <li>Point A</li>
        <li>Point B</li>
      </ul>
    </div>
    <div>
      <h3>Right column heading</h3>
      <table>
        <thead><tr><th>Metric</th><th>Value</th></tr></thead>
        <tbody>
          <tr><td>Mean</td><td>1.63</td></tr>
        </tbody>
      </table>
    </div>
  </div>
  <div class="footer"><span class="src">source.md</span><span>N / N</span></div>
</section>
```

---

## 4. Three-column layout

Use for parallel items (experiment A/B/C, option 1/2/3 roadmaps). Keep columns parallel in structure — same heading depth, similar bullet counts.

```html
<div class="three-col">
  <div><h3>Exp A</h3><ul><li>...</li></ul></div>
  <div><h3>Exp B</h3><ul><li>...</li></ul></div>
  <div><h3>Exp C</h3><ul><li>...</li></ul></div>
</div>
```

---

## 5. Big stat (hero number)

Use for a single headline number. Minimize everything else around it.

```html
<div class="big-stat">69 %</div>
<div class="big-stat-label">improvement from terminal-zone oracle</div>
```

For a "best config" hero slide, pair two big-stats stacked, or put one in a two-col next to a supporting table.

---

## 6. Callout

A single-sentence takeaway or reframe. Use sparingly — once per slide at most — to mark the conclusion the audience should leave with.

```html
<div class="callout">
  <strong>Reframe.</strong> The bottleneck is not discretization — it is translation drift.
</div>
```

---

## 7. Three-lines summary

Dedicated layout for "the story in N lines" slides, usually early or at the end. Numbered items with a subtle grey counter.

```html
<div class="three-lines">
  <p><span class="n">1.</span> First claim with <strong>one bold phrase</strong>.</p>
  <p><span class="n">2.</span> Second claim.</p>
  <p><span class="n">3.</span> Third claim leading to the next action.</p>
</div>
```

---

## 8. Table (default styling)

Plain `<table>` already inherits right-aligned numeric columns, left-aligned first column, tabular-nums. Highlight a winner row with `class="hl"`.

```html
<table>
  <thead><tr><th>Config</th><th>Med Å</th><th>≤ 2 Å</th></tr></thead>
  <tbody>
    <tr class="hl"><td>Winner</td><td>6.30</td><td>17.9 %</td></tr>
    <tr><td>Runner-up</td><td>7.02</td><td>15.4 %</td></tr>
  </tbody>
</table>
```

---

## 9. Inline SVG chart (bar)

Charts are inline SVG — no plotting library. Stick to the tab10 colors (`--c1` … `--c5`, plus `#d62728` red for "bad"). Horizontal grid only, thin axis, no chart-area background.

Reusable scaffold:

```html
<svg class="chart" width="500" height="280" viewBox="0 0 500 280">
  <!-- x-axis baseline + y-axis -->
  <line class="axis" x1="70" y1="220" x2="470" y2="220"/>
  <line class="axis" x1="70" y1="40" x2="70" y2="220"/>
  <!-- horizontal grid lines + tick labels -->
  <line class="grid-line" x1="70" y1="180" x2="470" y2="180"/>
  <line class="grid-line" x1="70" y1="140" x2="470" y2="140"/>
  <line class="grid-line" x1="70" y1="100" x2="470" y2="100"/>
  <line class="grid-line" x1="70" y1="60"  x2="470" y2="60"/>
  <text class="tick" x="65" y="223" text-anchor="end">0</text>
  <text class="tick" x="65" y="183" text-anchor="end">5</text>
  <!-- bars (bar height scales: y = 220 - value*scale) -->
  <rect x="120" y="66"  width="70" height="154" fill="var(--c1)"/>
  <rect x="220" y="127" width="70" height="93"  fill="var(--c2)"/>
  <rect x="320" y="135" width="70" height="85"  fill="var(--c3)"/>
  <!-- in-bar value labels, just above each bar -->
  <text class="bar-label" x="155" y="60"  text-anchor="middle">12.8 %</text>
  <text class="bar-label" x="255" y="121" text-anchor="middle">7.8 %</text>
  <text class="bar-label" x="355" y="129" text-anchor="middle">7.1 %</text>
  <!-- x-category labels below baseline -->
  <text class="tick" x="155" y="240" text-anchor="middle">Euler</text>
  <text class="tick" x="255" y="240" text-anchor="middle">Heun</text>
  <text class="tick" x="355" y="240" text-anchor="middle">RK4</text>
  <!-- axis titles -->
  <text class="axis-label" x="270" y="265" text-anchor="middle">integrator</text>
</svg>
```

Rules of thumb:
- Compute bar heights numerically; do not eyeball. If baseline is `y=220` and full height is 180 px for value=15, then one unit = 12 px; value=12.8 → height = 153.6.
- Use `<text class="bar-label">` at `y = barTop - 6` for above-bar labels.
- For grouped/stacked bars, keep color assignments consistent across slides (e.g., always `--c1` = baseline).
- Red (`#d62728`) is reserved for "bad" / "before fix" bars; green (`--c3`) for "good" / "after".

---

## 10. Legend

Use below a chart when colors need decoding.

```html
<div class="legend">
  <span><span class="swatch" style="background:var(--c1)"></span>Baseline</span>
  <span><span class="swatch" style="background:var(--c2)"></span>With fix</span>
</div>
```

---

## 11. Math (KaTeX)

Inline: `$ \nabla\log p = (x_T - x_t)/(\sigma_T - \sigma_t) $`

Block: wrap in `<div class="eq-wrap"> $$ ... $$ </div>`. For dense multi-equation slides use `<div class="math-small">` to shrink without breaking layout.

KaTeX auto-renders on load — you do not need to call anything.

---

## 12. Appendix / source index (last slide)

Close the deck with a self-referential index of all source notes. Helps the audience find the underlying artifact after the talk.

```html
<section class="slide">
  <div class="kicker">Appendix</div>
  <h1>Source notes</h1>
  <div class="two-col">
    <div>
      <h3>Group A</h3>
      <ul style="font-size:14px;">
        <li><code>path/to/note-1.md</code></li>
      </ul>
    </div>
    <div>
      <h3>Group B</h3>
      <ul style="font-size:14px;">
        <li><code>path/to/note-2.md</code></li>
      </ul>
      <h3>Controls</h3>
      <ul style="font-size:14px;">
        <li>← / → navigate, <code>f</code> fullscreen, <code>p</code> print preview (A4 landscape), <code>1–9</code> jump.</li>
      </ul>
    </div>
  </div>
  <div class="footer"><span class="src">N notes total</span><span>N / N</span></div>
</section>
```

---

## Narrative scaffolds

A 25–30-slide deck usually decomposes as:

1. **Title + recap + takeaways-first** (3 slides). State the three-line summary before any evidence. Audience should know the conclusion by slide 3.
2. **Framing / problem setup** (2–3 slides). Show the state of the world, the metric, the benchmark.
3. **Theory or background** (3–4 slides). Derivations, formulas, prior work. Use KaTeX.
4. **Experiments** (4–6 slides per major experiment). Design → result → interpretation.
5. **Debugging / failure modes** (2–4 slides). What broke, how we found it, what fixed it.
6. **Climax slide** (1 slide). The single number that makes the point — big chart, big stat.
7. **Next steps + takeaways + appendix** (3–4 slides). Roadmap, repeat three-line summary, source index.

A 10–12-slide deck collapses (2)+(3) and drops (5).

**One claim per slide.** The H1 should be a short assertion, not a topic. "Terminal zone dominates" beats "Oracle drift window analysis." If you cannot state the claim in the H1, the slide is not ready.
