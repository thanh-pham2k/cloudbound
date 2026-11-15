# Asset Pipeline Integration Guide (`gameforge-kit` + Godot 4)

## 1. Role of `gameforge-kit`

The pinned submodule at [`tools/gameforge-kit/`](../../tools/gameforge-kit/AGENTS.md) is **never modified directly**. It is invoked from the repository root with external isolation flags:

```bash
--project-root . --output-dir assets/generated --work-dir .gameforge/work --exporter godot
```

### Supported `gameforge-kit` Capabilities (Verified)
- **Batch Planning:** `scripts/sprites/batch_planner.py` (reads `profiles/cloudbound_isometric.json`, validates against `schemas/sprite_profile.schema.json`).
- **Frame Normalization:** `scripts/sprites/frame_normalizer.py` (resizes/pads PNG RGBA frames to `128x128` with safe margin & feet pivot alignment).
- **Atlas Packing:** `scripts/sprites/atlas_packer.py` (packs horizontal strip PNGs + `.atlas.json`).
- **Validation:** `scripts/sprites/validators.py` (structural duplicate/blank/dimension checks, frame consistency, motion checks).
- **Preview Generation:** `scripts/sprites/preview_generator.py` & `scripts/viewer/build_viewer.py` (contact sheets, GIFs, HTML gallery in `assets/previews/` or `.gameforge/work/`).
- **Godot 4 Export:** `scripts/sprites/godot_exporter.py` (generates `<character_id>_sprite_frames.tres` for `AnimatedSprite2D`).

### Not Provided by `gameforge-kit`
- Static environment tiles/props (`B01`, `B02`) and non-sprite-sheet assets do not have a built-in procedural generator in `gameforge-kit`. Author them into `assets/base/environment/...` and validate them with `scripts/tools/validate_assets.py`.

## 2. Standard Art Agent Workflow (Per Batch)

1. Place raw source frames in `assets/source/<domain>/<asset_id>/<task_id>/frame_000.png` (or static PNGs in `assets/base/environment/...`).
2. Plan & dry-run with `gameforge-kit`:
   ```bash
   python3 tools/gameforge-kit/scripts/sprites/batch_orchestrator.py \
     --project-root . \
     --profile profiles/cloudbound_isometric.json \
     --character <character_id> \
     --output-dir assets/generated \
     --work-dir .gameforge/work \
     --exporter godot \
     --dry-run
   ```
3. Normalize, pack, validate, and export `.tres` (via `frame_normalizer.py`, `atlas_packer.py`, `validators.py`, `godot_exporter.py` or `scripts/tools/build_placeholder_assets.py` pattern).
4. Run repository-level asset validation:
   ```bash
   python3 scripts/tools/validate_assets.py
   ```
5. Optional lightweight Godot headless resource-load check (asset sanity only — do not run automated gameplay playtests; the user tests gameplay manually):
   ```bash
   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit
   ```
