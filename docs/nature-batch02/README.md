# Batch 02 Nature validation

[Overview](overview.png) · [Close-up](detail.png) · [Placement and extraction data](validation.json)

| Check | Result | Evidence |
|---|---|---|
| Sheet identity and extraction | PASS | 1774×887 RGB. Measured 443–444 px cells in a 4×2 layout. Eight silhouettes clear of cell edges: three peach trees, two green trees, two bushes and one tuft. PNGs cropped at native resolution. |
| Background and halos | FAIL | The checkerboard is baked into RGB. Alpha extraction removes the checkerboard and leaves retained RGB unchanged. Pale edge pixels are still visible around some foliage at close zoom, particularly the grass tufts. The source was preserved. |
| Blueprint placement | PASS | Three green and six peach tree instances. All anchors fall inside their original semantic markers. Two bushes and three tufts occupy open grass. |
| Tree footprints | PASS | Nine 9 px radius circles centered at the trunk bases, on collision layer 2. Decorative vegetation has no collider. Godot loaded all 14 instances. |
| Main route and Secret Nook | PASS | All five landmarks share one free-space component at 8 px agent clearance after accounting for tree footprints. Zero footprint pixels in the protected path/Nook band. This is a mask-based connectivity check. |
| Sprite overlap and scale | PASS | No checked sprite silhouettes overlap each other or the protected corridor. One uniform scale of 0.26 preserves proportions. Native Godot overview and close-up were visually reviewed. |

Two tree anchors needed adjustment within their approved marker regions to keep the route visible. Batch 01 mask geometry and paths were left intact.

## Changed files

- `scenes/hoa_qua_son_terrain.tscn` instances `scenes/hoa_qua_son_nature.tscn`.
- `scenes/hoa_qua_son_nature.tscn` contains editable sprite and footprint nodes.
- `assets/sprites/batch02/` contains `peach_a.png`, `peach_b.png`, `peach_c.png`, `green_a.png`, `green_b.png`, `bush_green.png`, `bush_flowering.png`, `grass_tuft.png` and their Godot import sidecars.
- `assets/inbox/002-tao-asset-theo-prompt-vua-cung-cap.png.import` is generated Godot metadata for the supplied sheet.
- `scripts/tools/prepare_nature_batch02.py` extracts the sprites, builds the nature layer and checks placement.
- `tests/capture_terrain_batch01.gd` excludes the Nature node from baseline captures.
- `docs/nature-batch02/` contains this report, JSON results, two GPU captures and a Godot ignore marker.
