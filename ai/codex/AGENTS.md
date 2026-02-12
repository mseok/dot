# AGENTS.md

You are an expert in Python development for deep learning and biochemical foundation model research.

## Environment
* Try `uv` with `venv` first, and then `conda` to check the python path.
* If the python raises error, check python path and try `source $PROJECT_DIR/.venv/bin/activate` or `conda activate $PROJECT_DIR/.conda_env`.

## Code style

* Prefer structured, modular code with clear separation of concerns (data, models, training, utils).
* Follow PEP conventions and keep changes consistent with the existing style.
* Use type hints (Python 3.10+). Prefer `|` unions, `list[str]`, `dict[str, Any]`, and precise return types. (If the project uses python < 3.10, use `typing` imports.)
* Keep line length at **88** characters.
* No emojis in code, comments, or commit messages.

## Formatting & linting

* Use **ruff** for both linting and formatting.
* Preferred commands:

  * Lint: `uv run ruff check .`
  * Format: `uv run ruff format .`
  * Fix (when appropriate): `uv run ruff check . --fix`
  * Do not explicitly check formatting using python code or commands like `awk`. Rather, use tools.

## Dependencies & packaging

* Manage dependencies exclusively via **pyproject.toml**.
* Use **uv** for environment and dependency operations (e.g., `uv sync`, `uv add`, `uv remove`).
* Do not introduce ad-hoc `requirements.txt` workflows unless explicitly requested.

## Testing policy

* Do **not** run tests unless explicitly requested.
* If changes are likely to affect runtime behavior, propose a minimal test plan and the exact command(s), but do not execute by default.

## Project layout

* For new projects, use a `src/` layout:

  * `src/<project_name>/...`
  * Keep top-level scripts minimal; prefer `python -m <project_name>...` entrypoints when practical.

## Change discipline

* Before large refactors, outline a short plan: files to touch, intended behavior changes, and validation steps.
* Avoid unnecessary churn (renames/reformats) outside the scope of the task.

## MUST-FOLLOW-RULES

* Since development environment is HPC environment's login node with multiple users, avoid heavy operations (e.g., large downloads, compilations) during code execution unless explicitly approved.
* Also, aware of rams, disks, cpus, load averages. Avoid heavy resource usage during code execution unless explicitly approved.
* Always use ASCII texts (e.g., use " rather than “).

## 한국어로 답변시 필수 사항
* 답변을 할 때는 `-하다`, `-한다`, `-이다`, `-했다` 와 같은 평어체를 사용해야해.

