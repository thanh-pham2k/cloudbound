# Batch 01 — Terrain & Path integration

Terrain-only integration into `scenes/hoa_qua_son_terrain.tscn`. `project.godot` now starts this scene. No trees, houses, actors, enemies, interactables, collision bodies or gameplay objects are instantiated. Legacy gameplay scenes are untouched; their old art remains deleted as previously requested.

## Inputs inspected

- Approved Organic S-Curve segmentation: `assets/inbox/003-action-tao-anh-theo-prompt-cam-on.png`, 1254×1254 RGB.
- Actual 3×3 atlas: `assets/inbox/001-tao-anh-theo-prompt-vua-cap.png`, 1254×1254 RGB; nine 418×418 cells with dark grid separators.
- `001-tao-asset-theo-prompt-vua-e-xuat-nhe.png` is a separate single grass image, not the specified atlas. It is retained untouched and not substituted into Batch 01.

Both input hashes are recorded in generated manifests. No new artwork was generated.

## Atlas extraction and use

A 2px inset removes grid separators. Each output keeps 414×414 native pixels; no resizing, mirroring, rotation, stretching or mesh deformation.

| Cell | Output under `assets/sprites/batch01/` | Use |
|---|---|---|
| 1 | grass_fill.png | Grass material, including lighter Secret Nook grass |
| 2 | dirt_fill.png | Continuous dirt route and village plaza |
| 3 | grass_dirt_edge.png | Extracted/reserved: fixed one-sided horizontal geometry |
| 4 | path_corner.png | Extracted/reserved: fixed corner does not trace the approved curve |
| 5 | path_t_junction.png | Extracted/reserved: fixed end profile/orientation does not fit this junction exactly |
| 6 | cliff_straight.png | Inspected opaque face crop `[0,238,414,24]` for shallow flat boundary rim |
| 7 | cliff_outer_corner.png | Extracted/reserved: fixed grass/cliff silhouette |
| 8 | cliff_inner_corner.png | Extracted/reserved: fixed grass/cliff silhouette |
| 9 | stone_fill.png | Rock material within approved purple cliff-boundary regions |

Cells 6–8 contain a **baked RGB checkerboard**, not real transparency. Edge-connected neutral checker pixels were removed; alpha is preserved in the extracted PNGs. The full native-size cell remains available. The face crop is taken without scaling or deformed geometry at runtime.

All materials use the same uniform 0.5 world scale and original orientation. Opposite texture edges were measured rather than assumed seamless. The shader crossfades half-period translated samples within 12% of wrap boundaries. It changes sample opacity near joins, not asset geometry. Some softness and repeated motifs remain.

## Segmentation preservation

The supplied image has gradients, anti-aliasing and nonexact label colors. It is normalized to the existing semantic registry using nearest-class matching; source SHA256, source pixel dimensions and pixel→world transform are saved.

- Island silhouette is preserved **exactly relative to the normalized approved mask**, with no smoothing, simplification, dilation, resampling or expansion.
- House placeholders in the village are restored to underlying dirt; tree placeholders are restored to grass. No corresponding objects are added.
- 539 tiny disconnected nearest-color fringe pixels around marker edges are restored to grass; no main-path component is removed or rerouted.
- Main S-route and Secret Nook branch use the approved dirt mask. The lighter Secret Nook region is retained as a grass tint variant, not a new semantic class.
- Purple boundary-region footprints are preserved as rock material. An 8px shallow rim stays inside the outer island silhouette.
- No raised/extruded wall is invented. A full organic raised cliff enclosure needs compatible directional faces, corners and end caps that this atlas does not supply coherently.

`assets/blueprints/terrain_batch01/` stores canonical IDs, land/path/cliff/nook/rim masks, source metadata and a validated raster route. The scene composites editable material layers from these masks, rather than baking the whole world into one sprite.

## PASS / FAIL report

Full machine-readable evidence: `validation.json`.

| Check | Result | Evidence |
|---|---|---|
| Terrain coverage and silhouette | PASS | 0 clear-color holes; 0 rendered pixels outside normalized silhouette in native 1254×1254 GPU capture |
| Main S-route connectivity | PASS | Village, forest, clearing and boss approach connected after eroding dirt by an 8px-radius agent |
| Secret Nook connection | PASS | Branch shares main dirt component; 66 touching dirt/nook pixels; Nook reachable with 8px clearance |
| Cliff boundary coverage | PASS | No unrepresented boundary pixels; rim clipped inside silhouette |
| Texture joins after integration | PASS | GPU mean wrap jump 0.777/255, ordinary texel variation 0.980, threshold 3.000 |
| Native extraction / uniform scale | PASS | 9 assets at 414×414; all five material layers use scale 0.5 |
| No gameplay objects | PASS | Scene contains only five Polygon2D layers and one Camera2D |
| Unblended raw atlas seamlessness | FAIL | Grass opposite-edge MAE 3.987 horizontal / 2.149 vertical; dirt 2.700 / 2.608; stone 4.519 / 4.340 |
| Complete raised-cliff kit | FAIL | Missing coherent directional cliff faces, compatible organic corners and end caps |

Intentional material overlap: the opaque grass underlay covers all land; dirt, cliff regions and Nook/rim materials overlay only their masks. This is compositing, not accidentally overlapping terrain tiles. The native render test detects exterior spill and coverage holes.

Inherited segmentation block steps remain visible at close zoom. They are input geometry, not tile gaps. Connectivity is a raster/free-space test for the stated agent size, not a gameplay/controller test and not a claim that a larger future character will fit.

## Validation executed

Godot 4.7.2, native OpenGL Compatibility renderer, viewport 1280×720 plus a 1254×1254 offscreen GPU validation viewport.

1. `python3 scripts/tools/prepare_terrain_batch01.py`
2. `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import`
3. `/Applications/Godot.app/Contents/MacOS/Godot --path . --script tests/capture_terrain_batch01.gd`
4. `python3 tests/validate_terrain_batch01.py`

Import completed without errors. Native scene/capture assertions and all terrain-continuity/connectivity checks passed. Raw-atlas/cliff-kit failures remain explicitly recorded. No old character/gameplay tests were run against the deleted art set.

## Screenshots

- `terrain-overview.png`: running scene, entire island.
- `secret-junction.png`: actual rendered S-route/branch join and Nook.
- `north-cliffs.png`: approved northern cliff-boundary regions.
- `terrain-native.png`: exact source-resolution GPU capture used for coverage/seam measurements.
- `atlas-extraction.png`: all nine extracted source cells, alpha shown against a review background.

## Files changed

See `CHANGED_FILES.md` for the individual integration-file list. The earlier uncommitted removal of the old art set is separate and was not reversed. No source sheet was moved or overwritten.
