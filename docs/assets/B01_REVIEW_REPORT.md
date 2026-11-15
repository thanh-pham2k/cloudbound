# Cloudbound B01 — Pre-Integration Audit

**Status: `REVIEW_REQUIRED`. This is a code-and-image review, not a completed Godot runtime validation.**

## Evidence inspected

- GitHub `main`: `91707048ef61455e4d71dae3c8283a9b8d100c7b` (15 Nov 2026).
- Project documents: `AGENTS.md`, `docs/assets/VISUAL_BIBLE.md`, `docs/assets/ASSET_SPEC.md`, `docs/assets/BATCH_PLAN.md`.
- Existing B01 metadata, source normalization/validation code, isolated Godot assembly scene, and selected existing PNGs/previews from the GitHub repository.
- Four *newly produced* concept sheets from this conversation, included in `assets/inbox/b01/revision_references/`.

## Findings

| Area | Finding | Status |
| --- | --- | --- |
| Source art | The 4 latest concept sheets are **RGB 1536×1024** composite illustrations, **not** transparent 128×128 sprites. Each has labels, diagrams, and decorative backgrounds. | REVIEW_REQUIRED |
| Old base files | 10 earlier PNG assets and matching metadata exist on GitHub, but there is no evidence that the four revised concepts have been converted to separate PNG modules in `assets/base/`. | REVIEW_REQUIRED |
| Ground tiles | The old tiles are 128×128 RGBA according to metadata. The source script forces pixel-edge matching by mirroring quadrants; the old 5×5 preview shows obvious symmetric repeats. | REVIEW_REQUIRED |
| Stone terrain | There is no reusable seamless `ground_stone_tile_01.png` on `main`. A rune-center tile is not a substitute for a complete stone floor. | BLOCKER |
| Grass/stone transition | Old single isolated asset is already marked REVIEW_REQUIRED in metadata; the new 12-part contact sheet remains non-exported. | BLOCKER |
| Island rim | Only `platform_cloud_edge_01` and `platform_cloud_corner_01` (isolated cloud shapes) are on `main`. The four directional edges and four corners in the new contact sheet are not independent sprites. | BLOCKER |
| Bridge/stairs | Existing bridge and stairs files can be displayed, but there is no joint-pivot/connector contract proving aligned walkable paths; revised connector artwork is still only a sheet. | BLOCKER |
| Godot verification | Existing `tests/b01_assembly_test.tscn` is a test scene, not proof of runtime correctness. **No Godot executable is available in this inspection environment.** | NOT_RUN |
| Approval | Existing `b01_metadata.json` has `validation_status=REVIEW_REQUIRED`. No new art should be approved solely on the basis of conceptual `PASS` labels. | REVIEW_REQUIRED |

## Art direction mismatch requiring clarification

The latest B01 concept sheets include apparent green grass tile edges and stand-alone cloud platform effects, but a TileMapLayer requires tiles whose border pixel geometry matches neighboring tiles. Screenshot-style contact sheets cannot meet that automatically by cropping. Source art should be redrawn as true rectangular tiling layers, with island edges as separate overlays.

## Included inspection files

- `scripts/tools/review_b01_assets.py`: Non-destructive SHA-256, dimensions, alpha, per-edge, mirrored-texture, and missing-module check. Produces a JSON review report and two **offline previews**.
- `tests/test_b01_review.py`: Three synthetic unit tests; executed locally: **3/3 PASS**.
- `tests/b01_revised_assembly.tscn` and `.gd`: New isolated Godot review scene, deliberately warning about absent revised modules. Not yet executed in Godot.
- `assets/inbox/b01/revision_references/*.png`: The four latest reference sheets (RGB concept art), for manual redrawing, **not ready for import**.

## Running after copying files into your local project

```bash
python3 -m pip install Pillow
python3 -m unittest discover -s tests -p 'test_b01_review.py' -v
python3 scripts/tools/review_b01_assets.py --project-root .
# Result: assets/previews/b01_validation_review.json,
#         assets/previews/b01_repeat_5x5_review.png,
#         assets/previews/b01_offline_assembly_review.png

godot --headless --path . --editor --import
# For real renderer screenshot, prefer a GUI-capable Godot session:
godot --path . res://tests/b01_revised_assembly.tscn -- --screenshot
# Result if capture works: assets/previews/b01_godot_assembly_actual.png
```

**Do not accept a screenshot without examining it at actual gameplay zoom.** Headless/no-render backends can produce empty or invalid captures; the script checks empty images but does not detect uniformly blank frames.

## Remaining work

1. Art Agent converts each concept into genuine individual PNG modules, with exact 128px connection edges and transparent outer silhouettes. Add missing flat stone tile.
2. Run `review_b01_assets.py` locally on the actual project and fix reported issues; inspect tileability preview visually.
3. Open the isolated Godot review scene in the Editor and check floating island rims, bridge endpoints, and stair contact. Add collision/navigation validation only when geometry contract is defined.
4. Update `assets/base/environment/b01_metadata.json` from real file hashes and test outcomes after passing review, and obtain explicit human approval.

**Do not modify existing gameplay scenes or any files under `tools/gameforge-kit/` in this process.**
