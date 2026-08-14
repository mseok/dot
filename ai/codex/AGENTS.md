# Working principles

- Keep execution and debugging minimal. Do not run smoke tests or validation without a concrete reason.
- In an existing codebase, follow its error-handling and validation style. Do not add speculative `try`/`except`, assertions, or defensive checks.
- For durable or comparable experiments—not short checks or disposable debugging—run from committed source and use the `experiment-ledger` skill to record the hypothesis, core pseudocode, execution, artifacts, and result.
