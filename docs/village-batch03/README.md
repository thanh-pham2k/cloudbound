# Monkey Village v2

[World capture](overview.png) · [Village close-up](detail.png) · [Extraction and placement metadata](validation.json)

The supplied sheet is 1448×1086 RGB with a baked checkerboard. The crop uses measured columns at x=0, 385, 740, 1090, 1448 and rows at y=0, 362, 724, 1086. An equal-width grid would cut the first roof. The twelve extracted RGBA PNGs retain their source pixel dimensions after trimming and retain the RGB values of selected foreground pixels. Only the extracted copies receive alpha.

| Check | Result | Evidence |
|---|---|---|
| Twelve sprites | PASS | Reviewed every silhouette on a plain backing. No cropped props or visible checkerboard patches, including between the fence rails and under the well roof. |
| Edge quality | FAIL | Subtle pale matte fringes remain on some sprite edges at close zoom. |
| Semantic placement and visual balance | PASS | Four props in the Village layer. The main and small huts face inward from opposite sides, the well sits near center, and the signpost marks the incoming path. The open plaza extends south of the well. |
| Collision and accessibility | PASS | Godot loaded four ground-anchored bodies on layer 2. Both hut footprints stay inside their approved markers. The raster check found no footprint or sprite overlaps and confirmed both hut approaches, the plaza, the main route and Secret Nook share connected space at 8 px agent clearance. |
| Render and proportions | PASS | The Godot overview and close-up show all four props with their existing positions, uniform 0.26 scale, and Y-sort. |

Batch 01 masks and Batch 02 placements are unchanged. The storage marker is vacant. Storage, stall, crates, fence and lantern have no scene nodes or colliders. All twelve reusable v2 sprites remain available. No runtime references to the v1 sprite directory remain. The prior sheet and extracted v1 assets are retained.

## Changed files

- Scenes: `scenes/hoa_qua_son_village.tscn`
- Reproducible extraction and placement: `scripts/tools/prepare_village_batch03.py`
- Source sheet import metadata: `assets/inbox/001-tao-asset-cho-prompt-vua-mo-ta.png.import`
- Twelve PNGs with Godot import sidecars: `assets/sprites/batch03_v2/`
- Captures, metadata and report: `docs/village-batch03/`
