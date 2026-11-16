# Cloudbound sprite-sheet extraction and QA

**45 PNG assets extracted. 41 passed. 4 require manual edge review. All seven source batches were found.**

## Source inspection

| Batch | Sheet | Measured dimensions | Encoding | Source alpha range | Extracted |
|---|---|---:|---|---:|---:|
| B01 Terrain & Platforms | `assets/inbox/image copy.png` | 1254 × 1254 | PNG RGBA | 0–255 | 6 |
| B02 Bridges & Architecture | `assets/inbox/image copy 2.png` | 1254 × 1254 | PNG RGBA | 0–255 | 6 |
| B03 Nature & Decorations | `assets/inbox/image copy 3.png` | 1254 × 1254 | PNG RGBA | 0–255 | 9 |
| B04 Characters & Enemies | `assets/inbox/image copy 4.png` | 1536 × 1024 | PNG RGBA | 0–254 | 6 |
| B05 Portal, Chest & VFX | `assets/inbox/image copy 5.png` | 1774 × 887 | PNG RGBA | 0–255 | 6 |
| B06 Background & Clouds | `assets/inbox/image copy 6.png` | 1774 × 887 | PNG RGBA | 0–255 | 4 |
| B07 UI Elements | `assets/inbox/image copy 7.png` | 1774 × 887 | PNG RGBA | 0–255 | 8 |

The inbox also contains `assets/inbox/image.png`, a 1672 × 941 RGB scene reference board. Source paths and SHA-256 hashes are recorded in the manifest. Extraction verified the source hashes after writing the outputs.

All seven sheets were visually inspected before cropping. Checkerboard, solid black fill, and obvious unwanted white or colored matte were absent in the composites. The sheets contained true alpha and scattered faint residue. B02 had low-alpha spill between silhouettes. B04 peaks at alpha 254, and its original alpha values were retained. B06 contains a painted sky rectangle and three translucent scenery layers. B07 contains six groups and yields eight PNGs because the three ability buttons were separated.

## Processing and validation

- Crop guides followed visible artwork bounds. B02 and the B07 ability cluster used distinct alpha components to separate adjacent silhouettes. Faint pixels at most 12 source pixels from a visible contour were retained with their original alpha. Distant near-transparent residue was cleared. Transparent crops received two pixels of clear padding per side.
- The opaque sky uses RGB from the painted rectangle with a few pixels of soft perimeter trimmed. All sprite pixels remain at source scale. The manifest records source crop, output alpha bounds, and suggested pixel pivots.
- All 45 PNGs reopened and decoded. Each RGBA output has a transparent border and a nonempty alpha bounding box. Retained RGBA pixels were checked for exact equality with their source pixels. Source coordinate coverage showed zero duplicated pixels and zero omitted pixels above alpha 8 for B01, B03, B04, B05 and B07. B02 omitted 71 faint pixels above alpha 8 and none above 32. B06 omitted the sky perimeter when producing the opaque rectangle.
- The checkerboard and paired light/dark composites were visually reviewed for clipping, neighboring fragments, opaque fill, halos, color, lighting, and perspective. The B07 button crops were corrected to remove fragments of the upper button and checked again on both previews. Visual scale varies in the previews so each sprite is legible. Individual PNGs retain original pixel scale.
- `python3 scripts/tools/validate_assets.py` passed. It validates existing repository assets. The processed files were checked separately as described above.
- The toolkit normalizer targets fixed animation-frame canvases and uses source alpha as a paste mask, which alters translucent pixels. These native-size static cuts were exported directly to preserve source pixels. Atlas packing and Godot export were outside the preprocessing scope.

## Assets requiring manual correction or sign-off

| Asset | Inspect at native resolution |
|---|---|
| [stone_balustrade](architecture/stone_balustrade.png) | Lower-left railing fringe near the house roof tip. Correct remaining matte only if visible on the target background. |
| [stone_staircase](architecture/stone_staircase.png) | Top and bottom fringes near the bridge and gateway. Correct remaining matte only if visible on the target background. |
| [lantern_roof_house](architecture/lantern_roof_house.png) | Roof tip fringe near the balustrade end. Correct remaining matte only if visible on the target background. |
| [golden_dragon_gateway](architecture/golden_dragon_gateway.png) | Roof crest fringe near the stair base. Correct remaining matte only if visible on the target background. |

## Per-asset status

| Batch | Source cell | Asset | Pixels | Alpha | Result |
|---|---|---|---:|---|---|
| B01 | R1C1 | [large_grass_island](terrain/large_grass_island.png) | 646 × 430 | rgba_transparent | PASS |
| B01 | R1C2 | [small_grass_island](terrain/small_grass_island.png) | 351 × 333 | rgba_transparent | PASS |
| B01 | R2C1 | [circular_stone_arena](terrain/circular_stone_arena.png) | 666 × 434 | rgba_transparent | PASS |
| B01 | R2C2 | [curved_garden_path](terrain/curved_garden_path.png) | 512 × 387 | rgba_transparent | PASS |
| B01 | R3C1 | [straight_garden_path](terrain/straight_garden_path.png) | 575 × 341 | rgba_transparent | PASS |
| B01 | R3C2 | [carved_cloud_medallion](terrain/carved_cloud_medallion.png) | 488 × 335 | rgba_transparent | PASS |
| B02 | R1C1 | [arched_stone_bridge](architecture/arched_stone_bridge.png) | 600 × 470 | rgba_transparent | PASS |
| B02 | R1C2 | [stone_balustrade](architecture/stone_balustrade.png) | 459 × 346 | rgba_transparent | REVIEW_REQUIRED |
| B02 | R2C1 | [stone_staircase](architecture/stone_staircase.png) | 446 × 341 | rgba_transparent | REVIEW_REQUIRED |
| B02 | R2C2 | [lantern_roof_house](architecture/lantern_roof_house.png) | 470 × 456 | rgba_transparent | REVIEW_REQUIRED |
| B02 | R3C1 | [golden_dragon_gateway](architecture/golden_dragon_gateway.png) | 605 × 438 | rgba_transparent | REVIEW_REQUIRED |
| B02 | R3C2 | [wooden_rope_fence](architecture/wooden_rope_fence.png) | 467 × 320 | rgba_transparent | PASS |
| B03 | R1C1 | [pink_blossom_tree](nature/pink_blossom_tree.png) | 433 × 416 | rgba_transparent | PASS |
| B03 | R1C2 | [green_canopy_tree](nature/green_canopy_tree.png) | 349 × 395 | rgba_transparent | PASS |
| B03 | R1C3 | [white_flower_shrub](nature/white_flower_shrub.png) | 347 × 263 | rgba_transparent | PASS |
| B03 | R2C1 | [mossy_boulder](nature/mossy_boulder.png) | 363 × 290 | rgba_transparent | PASS |
| B03 | R2C2 | [meadow_flower_patch](nature/meadow_flower_patch.png) | 349 × 221 | rgba_transparent | PASS |
| B03 | R2C3 | [stone_lantern](nature/stone_lantern.png) | 331 × 380 | rgba_transparent | PASS |
| B03 | R3C1 | [cyan_rune_pillar](nature/cyan_rune_pillar.png) | 262 × 422 | rgba_transparent | PASS |
| B03 | R3C2 | [pink_flower_shrub](nature/pink_flower_shrub.png) | 327 × 248 | rgba_transparent | PASS |
| B03 | R3C3 | [flowering_rock_cluster](nature/flowering_rock_cluster.png) | 365 × 231 | rgba_transparent | PASS |
| B04 | R1C1 | [staff_wielding_monkey_hero](characters/staff_wielding_monkey_hero.png) | 486 × 377 | rgba_transparent | PASS |
| B04 | R1C2 | [mint_cloud_spirit](characters/mint_cloud_spirit.png) | 383 × 286 | rgba_transparent | PASS |
| B04 | R1C3 | [cyan_magic_caster](characters/cyan_magic_caster.png) | 352 × 379 | rgba_transparent | PASS |
| B04 | R2C1 | [boar_axeman](characters/boar_axeman.png) | 377 × 354 | rgba_transparent | PASS |
| B04 | R2C2 | [stone_golem](characters/stone_golem.png) | 407 × 375 | rgba_transparent | PASS |
| B04 | R2C3 | [armored_rune_colossus](characters/armored_rune_colossus.png) | 579 × 505 | rgba_transparent | PASS |
| B05 | R1C1 | [blue_vortex_portal](vfx/blue_vortex_portal.png) | 386 × 402 | rgba_transparent | PASS |
| B05 | R1C2 | [golden_reward_chest](vfx/golden_reward_chest.png) | 389 × 304 | rgba_transparent | PASS |
| B05 | R1C3 | [cyan_comet](vfx/cyan_comet.png) | 478 × 303 | rgba_transparent | PASS |
| B05 | R2C1 | [golden_slash](vfx/golden_slash.png) | 511 × 395 | rgba_transparent | PASS |
| B05 | R2C2 | [red_rune_circle](vfx/red_rune_circle.png) | 614 × 404 | rgba_transparent | PASS |
| B05 | R2C3 | [cyan_ground_burst](vfx/cyan_ground_burst.png) | 496 × 422 | rgba_transparent | PASS |
| B06 | R1C1 | [blue_sky](backgrounds/blue_sky.png) | 867 × 425 | opaque | PASS |
| B06 | R1C2 | [distant_floating_islands](backgrounds/distant_floating_islands.png) | 891 × 405 | rgba_transparent | PASS |
| B06 | R2C1 | [foreground_cloud_bank](backgrounds/foreground_cloud_bank.png) | 891 × 351 | rgba_transparent | PASS |
| B06 | R2C2 | [drifting_cloud_wisps](backgrounds/drifting_cloud_wisps.png) | 889 × 338 | rgba_transparent | PASS |
| B07 | R1C1 | [monkey_hero_portrait](ui/monkey_hero_portrait.png) | 400 × 402 | rgba_transparent | PASS |
| B07 | R1C2 | [hero_health_mana_bar](ui/hero_health_mana_bar.png) | 697 × 289 | rgba_transparent | PASS |
| B07 | R1C3 | [enemy_health_bar](ui/enemy_health_bar.png) | 491 × 183 | rgba_transparent | PASS |
| B07 | R2C1 | [dragon_boss_health_bar](ui/dragon_boss_health_bar.png) | 820 × 241 | rgba_transparent | PASS |
| B07 | R2C2 top | [ability_button_top](ui/ability_button_top.png) | 207 × 201 | rgba_transparent | PASS |
| B07 | R2C2 lower-left | [ability_button_lower_left](ui/ability_button_lower_left.png) | 213 × 206 | rgba_transparent | PASS |
| B07 | R2C2 lower-right | [ability_button_lower_right](ui/ability_button_lower_right.png) | 219 × 203 | rgba_transparent | PASS |
| B07 | R2C3 | [virtual_joystick](ui/virtual_joystick.png) | 423 × 414 | rgba_transparent | PASS |
