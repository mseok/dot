# Working principles

- Keep execution and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.
- For durable or comparable experiments—not short checks or disposable debugging—run from committed source and use the `experiment-ledger` skill to record the hypothesis, core pseudocode, execution, artifacts, and result.
- Use the current checkout by default. Do not create a branch or worktree solely because unrelated files are dirty or untracked, or because work is an experiment; create one only when the user asks or when a separate checkout is necessary for concurrent or conflicting work.
