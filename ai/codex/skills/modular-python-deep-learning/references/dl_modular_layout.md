# Default modular layout for deep learning research code

Use this template to split a monolithic script into coherent modules. Adapt to the existing repository instead of forcing a rewrite.

## Recommended responsibilities

- `data/`: dataset reading, preprocessing, featurization, collators; no model imports.
- `models/`: model definitions (`nn.Module` / JAX modules), forward contracts, initialization helpers.
- `losses/` and `metrics/`: pure functions; minimal dependencies.
- `train/`: training step, optimizer/scheduler wiring, checkpoint save/load, gradient clipping; keep it readable.
- `eval/`: evaluation loops, prediction writers, metric aggregation.
- `configs/` or `config.py`: dataclasses / typed config schema and defaults.
- `cli.py` or `scripts/train.py`: argument parsing, config loading, distributed init, then call into `train/` and `eval/`.

## Boundary rules

- Keep `data/` independent from `models/` to prevent circular imports.
- Keep pure functions pure (no filesystem, no global RNG mutation, no logging).
- Make device placement explicit and localized (one place that moves tensors/models).

## Practical refactor recipe (from `train.py` to modules)

1) Extract config schema (dataclass) and argument parsing.
2) Extract dataset + collate function.
3) Extract model construction (`build_model(config) -> model`).
4) Extract `train_step(batch, model, ...) -> loss, metrics`.
5) Extract checkpoint I/O.
6) Keep the top-level entrypoint as a thin orchestrator.

## Minimal “shape contract” pattern

- At every boundary (`Dataset.__getitem__`, `collate_fn`, `model.forward`, `loss_fn`), document:
  - keys and shapes in the batch dict
  - expected dtype and device
  - masking conventions (padding, attention masks)

