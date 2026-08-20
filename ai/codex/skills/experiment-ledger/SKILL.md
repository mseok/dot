---
name: experiment-ledger
description: Maintain one durable experiment note in the user's Obsidian vault. Use when planning, launching, updating, resuming, or reviewing a comparable research experiment that needs a hypothesis, core pseudocode, source commit, execution lineage, artifacts, status, and outcome. Do not use for ordinary coding, short checks, transient status, or disposable debugging.
---

# Maintain an Obsidian experiment note

Track experiments, not Codex sessions. Use one evolving note for one decision-complete hypothesis and algorithm. Never create a session-start note or a note merely as a precaution.

## Follow the vault's contract

The vault root is `${CODEX_HOME}/../Obsidian`.

1. Classify that exact path with `findmnt -T` before writing.
2. Read the vault's exact `AGENTS.md`, `STYLE.md`, `Templates/Experiment Template.md`, and relevant project hub before drafting. Those files override the shape described here.
3. Access only exact paths. Never recursively search the vault. When an existing note cannot be located from a user-provided path, wikilink, hub, or exact tracked filename, ask instead of scanning note contents.
4. Inspect `git -C <vault> status --short` before writing. Preserve unrelated changes and use the vault's exact-note commit helper.

Use the current vault layout rather than creating a ledger hierarchy:

- Put experiment notes flat in `Notes/`.
- Use `YYYY-MM-DD sentence-like title.md`, required frontmatter, the canonical project spelling, `kind/experiment`, project and topic tags, and the short non-master hostname when applicable.
- Start from the existing experiment template. Add `status` only for ledger-managed experiments, using `planned`, `running`, `completed`, `failed`, `inconclusive`, or `cancelled`.
- Let Obsidian Bases, tags, project hubs, and wikilinks provide retrieval. Do not create `Experiments/`, `INDEX.md`, or a parallel metadata taxonomy.

Use the same note for retries and multiple jobs that test the same hypothesis, algorithm, and decision criterion. Create a new natural-title note and link its predecessor when one of those changes materially.

## Freeze source before a durable run

Before launching a result that may be compared, cited, resumed, or used for a later decision:

1. State the intent, hypothesis, comparison surface, and decision criterion.
2. Ensure every result-affecting source, configuration, and launch-script change is committed in the source repository. Reuse `HEAD` when there are no relevant changes; never make an empty commit.
3. Before recording `HEAD` as the source commit, require `git status --porcelain --untracked-files=no` to produce no output. This tracked-clean gate is not permission to reset, stash, discard, or commit unrelated changes.
4. Treat an untracked repository file as result-affecting when it can change imports, configuration, launch behavior, or code and plugin discovery. Commit it or resolve it with the user's direction before launch. Preserve unrelated untracked files; they do not need to be removed for a tracked-clean run.
5. Use the current checkout by default and stage only experiment-relevant files. If unrelated tracked changes prevent a tracked-clean launch, stop and ask the user. Create a worktree only when the user asks or approves it, or when a distinct checkout is genuinely necessary for concurrent or conflicting work; never alter unrelated files or create a worktree solely for cleanliness or experiment bookkeeping.
6. Record the full source SHA and only checkout caveats that can affect reproduction. A source push is not required unless the user asks.
7. Record only result-affecting surfaces that actually exist, such as the data or manifest, checkpoint and hash, resolved configuration, seeds, comparison population, command, Slurm job and resources, output artifact name and digest, W&B run and `trainer/global_step`, and stop condition. Do not invent a fixed roster, checkpoint list, seed grid, validation, or bookkeeping surface merely because a run is comparable. Use `N/A` only where the vault template requires a field and `UNVERIFIED` when a relevant fact was not retained or re-authenticated.

Do not put raw logs, full configs, datasets, results, or bare absolute server paths in the vault. Keep stable identifiers, compact evidence, conclusions, and repository-relative implementation pointers.

## Preserve the core algorithm

When the experiment introduces, changes, or evaluates a core algorithm, include a concise LaTeX-style block using the Obsidian Pseudocode plugin's `pseudo` fence. Capture inputs, outputs, state initialization, ordered updates, loops, branches, aggregation or selection, assumptions, and invariants. Use `<full-sha>:<repo-relative-path>::<symbol>` to bind the sketch to implementation. State any known deviation between the sketch and committed code.

Use this form, adapted to the actual algorithm:

````markdown
## 핵심 알고리즘

```pseudo
\begin{algorithm}
\caption{<Natural algorithm title>}
\begin{algorithmic}
  \Require <inputs and assumptions>
  \Ensure <outputs or postcondition>
  \State <initialize state>
  \For{<ordered iteration>}
    \State <compute and update>
    \If{<decision condition>}
      \State <branch action>
    \EndIf
  \EndFor
  \State \Return <result>
\end{algorithmic}
\end{algorithm}
```

- 구현: `<full-sha>:<repo-relative-path>::<symbol>`
- 가정과 불변식:
- 구현과 다른 점:
````

If no core algorithm is involved, omit the section or say why it is not applicable. Do not paste literal source fragments; the commit and symbol are the exact implementation surface.

## Write at meaningful transitions

- Before launch, create or update a decision-complete plan with status `planned`.
- After submission or direct launch, record the exact command, job or process identifier, resources, output artifact, and status `running`. Commit the note once the launch contract is complete; do not commit every scheduler poll.
- At termination, update the same note to `completed`, `failed`, `inconclusive`, or `cancelled`. Put observed evidence before interpretation, preserve limitations, and name the next decision.
- Do not add a `retry observation` section or append routine retry/poll snapshots to the note. Scheduler state, GPU utilization, partial cache counts, startup excerpts, and transient progress belong in chat or durable run artifacts. Add retry evidence only when it changes the source/launch contract, terminal status, first failure boundary, or next decision.

Use the vault's helper from the vault root so only the note is staged:

```text
python3 scripts/codex_note_commit.py 'Notes/<note>.md' --message '<short subject>'
```

Use `--push` only when the user explicitly asks to publish that vault commit. Never force-push. Do not add hooks, background tracking, automatic session notes, wrappers, or validation runs for this ledger.
