# Batch 03 Village validation

[Full scene](overview.png) · [Village close-up](detail.png) · [Extraction and placement metadata](validation.json)

| Check | Result | Evidence |
|---|---|---|
| Eight independent assets | PASS | Supplied 1774×887 RGB sheet, four columns and two rows. Cell boundaries and native crop rectangles are in the JSON. All eight silhouettes have space to the cell edges. |
| Background and halos | FAIL | The source has an opaque white matte. Extraction removed the separable background and preserved retained RGB values. Fine pale fringes remain on some edges at close zoom. |
| Houses and collision | PASS | Three distinct approved building regions contain the respective hut anchors and full collision rectangles. All eight ground footprints use layer 2. |
| Access | PASS | All three building approach points, the plaza and the route landmarks remain connected at 8 px clearance. The dirt trail and Secret Nook branch are connected with Nature and Village footprints accounted for. This check covers approach to the storage hut's open frontage. |
| Overlap and scale | PASS | Raster silhouette checks found no overlap between Village sprites or with Nature. All sprites use uniform 0.26 scale, matching Batch 02. Native captures were visually reviewed. |
| Godot load | PASS | Godot 4.7.2 loaded the combined scene and all eight Village bodies and generated both GPU captures. |

Terrain, segmentation and Nature placements are unchanged. The source sheet remains intact.

## Changed files

- scenes/hoa_qua_son_terrain.tscn instances the new Village scene.
- scenes/hoa_qua_son_village.tscn contains the eight editable props.
- assets/sprites/batch03/ contains hut_main, hut_small, hut_storage, well_stone, signpost_wood, fence_wood, lantern_post and wooden_crate PNGs and import sidecars.
- assets/inbox/002-tao-asset-theo-prompt-vua-cung-cap (1).png.import is the supplied sheet's Godot import metadata.
- scripts/tools/prepare_village_batch03.py extracts assets, builds the Village scene and verifies placement.
- tests/capture_terrain_batch01.gd excludes Village from terrain-only captures.
- docs/village-batch03/ contains the report, extraction metadata, two captures and Godot ignore marker.
