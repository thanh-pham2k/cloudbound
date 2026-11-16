# Processed artwork integration

Run [Scene 01](../../scenes/scene_01_mortal_realm.tscn) with **F6** in Godot to start the six-scene route. The project still opens its original wave mode with **F5**.

## Visual review

These are opening gameplay frames from the actual Godot scenes at 1280 × 720. The capture harness paused each scene after initialization and sent no inputs. The six-panel inbox concept board served as the reference, including its Scene 03 panel. A separately approved Scene 03 screenshot was unavailable. The benchmark matches the major layout and encounter beats, with visible differences in framing and surface detail.

| Scene | Godot capture | Comparison with the concept board |
|---|---|---|
| 01 Mortal Realm | [Screenshot](../../assets/previews/processed_integration/scene_01.png) | The house, blossom, curved path and departure portal frame the island. The painted path is a single short cutout. |
| 02 Cloud Bridge | [Screenshot](../../assets/previews/processed_integration/scene_02.png) | One bridge joins two grass islands with a lantern at each end. The cloud spirit uses the existing ranged encounter behavior. |
| 03 Cloud Outskirts | [Screenshot](../../assets/previews/processed_integration/scene_03.png) | The diagonal path separates the ranged pair and melee enemy, with the Wukong hero entering from the lower left. The island has deeper cliffs and the path has more regular stonework than the reference panel. |
| 04 Celestial Courtyard | [Screenshot](../../assets/previews/processed_integration/scene_04.png) | The circular arena and four perimeter pillars frame the four-enemy encounter. The supplied stone disc has foliage around its rim. |
| 05 Guardian Arena | [Screenshot](../../assets/previews/processed_integration/scene_05.png) | The arena uses cooler stone, cyan pillars and a tinted center seal. The opening telegraph shows the red rune and the existing circular range marker. |
| 06 Gate of Heaven | [Screenshot](../../assets/previews/processed_integration/scene_06.png) | The golden gate, portal, rails, closed chest and two blossom trees are visible. The scene reuses the circular stone platform. |

[3 × 2 Godot screenshot sheet](../../assets/previews/processed_integration/comparison_3x2.png)

## Asset quality and inventory

All 45 extracted PNGs loaded as Godot textures with the manifest dimensions. The source-sheet hashes still match the extraction manifest. The four B02 review items were inspected at native resolution on light and dark backgrounds. Separate runtime copies of the balustrade, lantern-roof house and golden gateway attenuate faint outer fringe at alpha 16 or below, more than three pixels away from the alpha-above-32 silhouette. The extracted PNGs and their QA records were preserved. The stairs remain **REVIEW_REQUIRED** and are deferred since the requested route has no staircase.

| Batch | Asset | Runtime use |
|---|---|---|
| B01 | `large_grass_island` | 01, 02, 03 · painted terrain |
| B01 | `small_grass_island` | Available in the processed library for optional dressing |
| B01 | `circular_stone_arena` | 04, 05, 06 · stone platform |
| B01 | `curved_garden_path` | 01 · winding path |
| B01 | `straight_garden_path` | 03 · diagonal path |
| B01 | `carved_cloud_medallion` | 05 · cyan-tinted arena seal |
| B02 | `arched_stone_bridge` | 02 · bridge deck and rail artwork |
| B02 | `stone_balustrade` | 06 · perimeter rails, cleaned runtime copy |
| B02 | `stone_staircase` | Deferred · REVIEW_REQUIRED |
| B02 | `lantern_roof_house` | 01 · village house, cleaned runtime copy |
| B02 | `golden_dragon_gateway` | 06 · portal surround, cleaned runtime copy |
| B02 | `wooden_rope_fence` | Available in the processed library for optional dressing |
| B03 | `pink_blossom_tree` | 01, 03, 06 · blossom trees |
| B03 | `green_canopy_tree` | Available in the processed library for optional dressing |
| B03 | `white_flower_shrub` | 03 · path-side shrub |
| B03 | `mossy_boulder` | Available in the processed library for optional dressing |
| B03 | `meadow_flower_patch` | Available in the processed library for optional dressing |
| B03 | `stone_lantern` | 02, 03 · route landmarks |
| B03 | `cyan_rune_pillar` | 04, 05 · obstacle visuals |
| B03 | `pink_flower_shrub` | Available in the processed library for optional dressing |
| B03 | `flowering_rock_cluster` | 03 · perimeter dressing |
| B04 | `staff_wielding_monkey_hero` | 01–06 · player pose |
| B04 | `mint_cloud_spirit` | 02 · ranged enemy pose |
| B04 | `cyan_magic_caster` | 03, 04 · ranged enemy pose |
| B04 | `boar_axeman` | 03, 04 · melee enemy pose |
| B04 | `stone_golem` | 04 · tank pose |
| B04 | `armored_rune_colossus` | 05 · boss pose |
| B05 | `blue_vortex_portal` | 01–06 · live portal after opening or unlock |
| B05 | `golden_reward_chest` | 06 · decorative reward chest |
| B05 | `cyan_comet` | 01–06 · projectile rendering when spawned |
| B05 | `golden_slash` | 01–06 · slash effect when spawned |
| B05 | `red_rune_circle` | 01–06 · circular attack warnings when spawned |
| B05 | `cyan_ground_burst` | 01–06 · ring burst when spawned |
| B06 | `blue_sky` | 01–06 · opaque backdrop |
| B06 | `distant_floating_islands` | 01–06 · far parallax |
| B06 | `foreground_cloud_bank` | 01–06 · mid parallax |
| B06 | `drifting_cloud_wisps` | 01–06 · atmospheric parallax |
| B07 | `monkey_hero_portrait` | 01–06 · HUD portrait |
| B07 | `hero_health_mana_bar` | 01–06 · live HP and XP |
| B07 | `enemy_health_bar` | 02–04 · live enemy HP |
| B07 | `dragon_boss_health_bar` | 05 · boss health and phase |
| B07 | `ability_button_top` | 01–06 · K cooldown indicator |
| B07 | `ability_button_lower_left` | 01–06 · Space cooldown indicator |
| B07 | `ability_button_lower_right` | 01–06 · L cooldown indicator |
| B07 | `virtual_joystick` | Hidden · no existing touch movement binding |

## Implementation and verification

- The six authored `scenes/scene_*.tscn` files enable the shared painted world and HUD. `scripts/world/cloud_arena.gd` fits scenery and an independent walkable outline to the supplied sprites. `scripts/world/painted_sprite.gd` supplies ground-anchored placement, static poses and skinned progress meters. `scripts/main.gd` and `scripts/systems/floor_manager.gd` set camera composition and actor placement for the new terrain.
- The player, enemy and boss scripts use static poses on the existing animated sprite nodes. Direction flipping and combat effects remain available. The painted pose set has one image per actor; attack and movement animations from the original wave mode are still available in that mode.
- `scripts/world/cloud_portal.gd`, `scripts/combat/combat_system.gd`, `scripts/combat/projectile.gd` and `scripts/combat/telegraph_area.gd` use the processed effects without changing their damage rules, timers or trigger shapes. `scripts/ui/ui_manager.gd` keeps the existing HP, XP, level, objective, cooldown and boss signal bindings. The blue meter tracks XP because the project has no mana system.
- Godot 4.7.2 Compatibility import completed and the six scenes produced real viewport captures. The pinned toolkit's nested demo was intentionally ignored by Godot. A static Godot geometry check confirmed one connected Scene 02 walkable polygon at the player's 28-pixel clearance, including the player start, bridge center and enemy landing. The original wave entry point also loaded headlessly. The repository asset validator and `git diff --check` passed.
- Runtime textures use linear filtering on the painted layers. The 37 referenced processed and derived textures total approximately 26.1 MiB in raw RGBA8 across the full library of referenced art. GPU allocation and frame time were unmeasured.
- Movement, attacks, dash, enemy defeat, boss phase changes, portal entry, live HUD changes and the full route still require manual play. The repository reserves gameplay testing for the user. Current scene transitions create a new player and call `progression.reset()`. Code inspection shows HP, XP and applied upgrades reset between scenes.
