# Python philosophy for research code

Use these as decision rules when multiple designs are possible.

## Zen of Python (PEP 20) as practical heuristics

- Prefer explicit code over implicit behavior.
- Prefer readable code over “clever” code.
- Prefer flat, simple module graphs over deeply nested packages.
- Handle errors explicitly; fail fast with informative messages.
- Choose one obvious way to do something within a codebase and apply it consistently.

Tip: run `python -c "import this"` to view the full Zen of Python.

## Style and conventions (PEP 8 aligned)

- Name modules and functions with `snake_case`; name classes with `CapWords`.
- Keep functions small and single-purpose; return values instead of mutating hidden state.
- Avoid work at import time; use `main()` entrypoints guarded by `if __name__ == '__main__':`.
- Prefer `pathlib.Path` over stringly-typed paths.
- Use `logging` instead of `print` for long-running jobs.

## Types, contracts, and docstrings

- Add type hints at module boundaries (public functions/classes).
- Document tensor shapes and dtypes in docstrings for data/model boundaries.
- Validate invariants early (e.g., padding masks, label ranges, non-empty batches).

## Packaging for modularity

- Make core code importable as a package (often `src/<pkg_name>/...`).
- Keep experiment entrypoints (train/eval scripts) thin and delegate to importable modules.
- Avoid circular imports; invert dependencies via small interfaces instead.

