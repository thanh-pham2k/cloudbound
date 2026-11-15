# Asset Catalog — Đường Đến Thiên Giới (Cloudbound)

Audit status across `B01`–`B06` against the Six-Scene Visual Reference.
Status values: `READY`, `NEEDS_FIX`, `MISSING`, `PLACEHOLDER`, `REVIEW_REQUIRED`.

| Asset ID | Batch | Type | Dimensions | Status | Path | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| `ground_jade_tile_01`, `02` | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/ground/` | Seamless toroidal RGBA tiles |
| `ground_stone_tile_01`, `ground_cloud_tile_01` | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/ground/` | Carved stone & cloud floor |
| `ground_rune_center_01` | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/ground/` | Center courtyard medallion |
| `ground_grass_stone_*` (12 transition tiles) | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/ground/` | Edges, outer & inner corners |
| `platform_cloud_*` (9 rim/underside modules) | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/platforms/` | N/S/E/W edges, NW/NE/SW/SE corners, underside |
| `bridge_stone_*` + `stairs_stone_01` | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/bridges/` | Entrance, middle, extension, exit, stairs |
| `ground_arena_tile_01..09` | `B01` | `environment` | `128x128` | `READY` | `assets/base/environment/ground/` | Circular arena stone floor tiles |
| `arch_jade_pillar_01`, `arch_celestial_gate_01`, `arch_heaven_gateway_01`, `arch_village_house_01` | `B02` | `architecture` | `128x192` / `256x256` | `READY` | `assets/base/environment/architecture/` | Pillars, village house, gateways |
| `deco_peach_bonsai_01`, `deco_green_tree_01`, `deco_bush_01`, `deco_cloud_lantern_01`, `deco_cloud_rock_01`, `deco_incense_brazier_01`, `deco_wooden_fence_01`, `bg_distant_island_01`, `bg_cloud_bank_01` | `B02`/`B03`/`B08` | `decoration` | `128x128` / `256x128` | `READY` | `assets/base/environment/decorations/` | Village, island, foliage & sky backdrop props |
| `prop_reward_chest_01` | `B08` | `prop` | `128x128` | `READY` | `assets/base/props/` | Scene 06 reward chest |
| `player_hero` | `B03` | `character` | `128x128` (15 anims) | `READY` | `assets/generated/sprites/player_hero/player_hero_sprite_frames.tres` | Red-gold Chinese chibi warrior with topknot & wooden staff |
| `enemy_melee` (Horned Demon) | `B04` | `monster` | `128x128` (15 anims) | `READY` | `assets/generated/sprites/enemy_melee/enemy_melee_sprite_frames.tres` | Red horned demon |
| `enemy_ranged` (Green Cloud Slime) | `B04` | `monster` | `128x128` (15 anims) | `READY` | `assets/generated/sprites/enemy_ranged/enemy_ranged_sprite_frames.tres` | Green cloud slime |
| `enemy_tank` (Stone Guardian) | `B04` | `monster` | `128x128` (15 anims) | `READY` | `assets/generated/sprites/enemy_tank/enemy_tank_sprite_frames.tres` | Heavy stone guardian |
| `boss_thunder_warden` (Giant Stone Guardian) | `B05` | `boss` | `128x128` (15 anims) | `READY` | `assets/generated/sprites/boss_thunder_warden/boss_thunder_warden_sprite_frames.tres` | Giant cyan-rune Stone Guardian boss |
| `vfx_heaven_portal_00..07` | `B06` | `vfx` | `128x128` (8 frames) | `READY` | `assets/base/vfx/` | Swirling golden-violet portal loop |
| Combat VFX sprites (`vfx_slash_arc`, `vfx_hit_impact`, `vfx_dash_trail`) | `B06` | `vfx` | `128x128` | `PLACEHOLDER` | Procedural in `scripts/combat/` | Combat system currently uses lightweight 2D arcs/rings; source sheet available for future extraction |
