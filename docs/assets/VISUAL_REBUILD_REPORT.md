# Cloudbound gameplay visual rebuild

The supplied six-panel reference establishes the visual target. I inspected
the checked-out project, its asset contracts, the B01 source and preview
inventory, and opening frames rendered from the original gameplay scenes.
Then I rebuilt Azure Cloud Outskirts first and reviewed it in Godot before
extending the shared terrain to the other scenes. The rendered layouts
are ready for visual review at gameplay zoom.

## Asset audit

| Asset or system | Original classification | Runtime treatment and remaining work |
| --- | --- | --- |
| Jade grass variants | INVALID_FOR_PRODUCTION | Repeating high-contrast texture produced a checkerboard. Replaced in gameplay with continuous, seeded terrain shading and surface detail. |
| Flat stone, path, grass-to-stone joins | INVALID_FOR_PRODUCTION | Repeating rune art made stair-stepped paths. Replaced with separately fitted pavers on a curve and a broken boundary where grass meets stones. Painterly wear remains visibly weaker than the reference. |
| Cloud platform edges, outer and inner corner tiles, underside | INVALID_FOR_PRODUCTION | The perimeter occupied adjacent grid cells and broke up into individual cloud blocks. The same outline now drives grass, continuous cliff foundation, repeating rock faces, and moss overhang. The rock facets still have a regular, procedural rhythm. |
| Bridge entrance, straight, extension, exit | NEEDS_FIX | Existing PNGs put posts and details at incompatible seams. Scene 02 uses a continuous angled stone deck assembled from slab, rail, and post components. Its support and railing are simpler than the reference. |
| Stone stairs | NEEDS_FIX | Standalone stair sprite is usable as an art reference for placement. Scene 01 reuses the stairs baked into the village gate illustration. A finished reusable stair module with matching joins remains open. |
| Circular arena and medallion tiles | INVALID_FOR_PRODUCTION | Square repetition and loose overlays obscured the intended ellipse. Scenes 04 and 05 now use concentric rows with radially staggered joints and engraved bands. |
| Green and peach trees, bush and mossy rocks | READY | Reused at scene-specific scales and grounded for Y-sorting. Distinct flower clusters and broken-stone dressing remain desirable for matching the reference. |
| House and heavenly gate | NEEDS_FIX | Reused the artwork with a runtime crop mask for stray contact-sheet lines. Scene 01 uses its stone arch as the actual exit rather than drawing two gates. |
| Village arch, fences, rune pillars, lantern and crystal pedestal | READY | Reused existing PNGs. The bright crystal is in the asset named `deco_incense_brazier_01.png`. Four collision-bearing pillar bases remain in each courtyard. |
| Loose flowers, banner and open reward chest | MISSING | The existing chest is closed. Taller architectural lanterns and open-chest light would bring Scene 06 closer to the reference. |
| Hero, green slime, horned demon | READY | Existing SpriteFrames remain bound to their original actors. Their proportions and battle poses differ from the reference at the wider gameplay framing. |
| Stone guardian and heavy construct | NEEDS_FIX | Existing directions and actions load. Scene 05 increases the guardian's visual scale and opens with a better view of its face and arms. Side silhouettes and forceful slam poses still need redraw and motion review. |
| Staff swing, hit and dash VFX | NEEDS_FIX | Existing combat effects remain active. The hand-painted swing, hit spark, and dash trail shown in the reference still need a dedicated art pass. |
| Boss telegraph and slam | NEEDS_FIX | Existing telegraph radius and timing remain in use. Dedicated ground fractures, debris and warm slam accents are missing. |
| Portal animation frames | INVALID_FOR_PRODUCTION | The existing frame art visibly contains frame numbers and layout fragments. Replaced that runtime overlay with animated light confined to the painted opening of the gate. |
| Reward glow | MISSING | No dedicated chest glow or open reward art added. |
| Sky, cloud banks, distant islands and waterfall | READY | Reused the existing sprites and layered them over a viewport-sized gradient. Background composition and scale were adjusted in Scene 03. |
| Contact sheets, target panels and previous B01 previews | REFERENCE_ONLY | Kept as source and comparison evidence. |
| Island bounds, props, camera and parallax | NEEDS_FIX | Movement now uses inset versions of the visible shoreline. Bridge, player, enemy, and portal placement use the same geometry. Grounded prop sorting and camera framing were integrated into the existing gameplay scenes. |

## Runtime screenshots and scene status

Captures are full-size 1280 × 720 opening frames from Godot 4.7.2 on
the Compatibility renderer. The screenshot harness loads the actual
scene and captures its viewport without sending gameplay input.
Before and after framing changes reflect the actual scene cameras.

| Scene | Evidence | Status and open visual work |
| --- | --- | --- |
| 01 Mortal Realm | [After](../../assets/previews/visual_rebuild/scene_01_after.png) | REVIEW_REQUIRED. Village path, house, blossom and walk-through arch are in place. Terrain dressing and the gate opening need art polish. |
| 02 Stairway to Clouds | [After](../../assets/previews/visual_rebuild/scene_02_after.png) | REVIEW_REQUIRED. Bridge spans two islands and follows the walkable deck. Rail detail, supports and landing transitions are simplified. |
| 03 Azure Cloud Outskirts | [Before](../../assets/previews/visual_rebuild/scene_03_before.png) · [After](../../assets/previews/visual_rebuild/scene_03_after.png) | REVIEW_REQUIRED. Continuous island, diagonal path and three-enemy staging echo the reference. The grass-to-cliff transition, texture detail and character scale remain short of the painted target. |
| 04 Azure Cloud Center | [After](../../assets/previews/visual_rebuild/scene_04_after.png) | REVIEW_REQUIRED. Radial courtyard, rune pillars and cyan crystal are in place. Pavers and mixed enemy poses need art review. |
| 05 Cloudstone Boss Arena | [Before](../../assets/previews/visual_rebuild/scene_05_before.png) · [After](../../assets/previews/visual_rebuild/scene_05_after.png) | REVIEW_REQUIRED. The guardian reads larger and the courtyard is elliptical. The capture shows the opening warning circle. The requested slam art and pose still need review. |
| 06 Gate of Heaven | [Before](../../assets/previews/visual_rebuild/scene_06_before.png) · [After](../../assets/previews/visual_rebuild/scene_06_after.png) | REVIEW_REQUIRED. The approach, gold gate, chest and blossom tree form the main composition. Open-chest art and reward glow are missing. |

## Verification

- Repository asset validator passed for the existing PNG, atlas,
  metadata, and SpriteFrames inventory.
- Godot 4.7.2 headless import completed. Godot reported the nested
  toolkit example project and excluded it from import.
- Both existing isolated B01 asset assembly scenes loaded headlessly.
- The existing B01 review unit tests passed, 3 of 3.
- All six rendered opening frames were inspected. Full movement,
  combat, progression and transitions remain for manual play in Godot,
  per the repository's asset-only validation scope.
- Blender was unavailable. No new raster sprite frames were necessary
  for the terrain implementation. No external AI image API was used
  or tested.

## Files and sources

- Created `scripts/world/island_surface.gd`,
  `scripts/world/island_surface.gdshader`, and
  `scripts/world/prop_cleanup.gdshader` with Godot UID files.
  These sources define the new modular runtime geometry and materials.
- Updated `scripts/world/cloud_arena.gd`, `scripts/world/cloud_portal.gd`,
  `scripts/main.gd`, `scripts/systems/floor_manager.gd`, and
  `scripts/boss/boss_controller.gd` for scene assembly, exit artwork,
  camera framing, spawn positions and guardian presentation.
- Updated `VISUAL_BIBLE.md` and `INTEGRATION_GUIDE.md` and added this audit.
  Saved nine live viewport captures and their Godot import descriptors
  under `assets/previews/visual_rebuild/`.
- Reused the six scene entry points, existing combat and progression
  systems, atlas resources, isolated B01 fixtures, sprite art and
  screenshot harness. Preserved the original artwork in `assets/source/`,
  `assets/base/`, and `assets/generated/`, the pinned GameForge Kit,
  encounter balance, player inputs and HUD implementation.
