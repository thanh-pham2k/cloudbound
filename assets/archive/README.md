# Adapted source sheets

`adapted/` contains 14 original sheets already extracted into `assets/sprites/`.
The reference concept remains in `assets/inbox/` for active design work.

The originals are byte-preserved. `adapted/manifest.json` records their original path,
archive path and SHA256. Godot import sidecars are removed because these source-only
masters are excluded from engine import by `.gdignore`.

Both extraction scripts search inbox first, then `assets/archive/adapted/`:
- `scripts/tools/extract_batches.py`
- `scripts/tools/extract_concept_batches.py`

Runtime sprites and their resource paths are unaffected by this move.
