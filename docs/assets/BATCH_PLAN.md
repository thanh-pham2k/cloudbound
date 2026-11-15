# Batch Production Plan (`B01`–`B06`)

Each batch is **self-contained** so an Art Agent can produce and validate it independently without touching gameplay code.

---

## B01: Ground & Platforms

- **Required Assets:**
  - `ground_jade_tile_01.png`, `ground_jade_tile_02.png` (modular cloud-jade floor tiles)
  - `ground_rune_center_01.png` (center celestial rune medallion)
  - `platform_cloud_edge_01.png`, `platform_cloud_corner_01.png` (2.5D island rim with underside thickness)
  - `bridge_stone_01.png`, `bridge_stone_02.png`
- **Output Paths:**
  - Source: `assets/source/environment/`
  - Base (final static PNGs): `assets/base/environment/ground/`, `assets/base/environment/platforms/`, `assets/base/environment/bridges/`
- **Naming:** `<category>_<name>_<variant>.png` (lowercase `snake_case`)
- **Dimensions:** `128x128` PNG RGBA (`256x128` allowed for bridges/medallions), seamless tile edges on ground tiles.
- **Animation Requirements:** None (static).
- **Acceptance Criteria:** PNG RGBA, transparent exterior on edges/bridges, seamless 4-edge tiling on `ground_*` tiles, soft jade/cream/sky palette per `VISUAL_BIBLE.md`.
- **Dependencies:** None.

---

## B02: Environment Props

- **Required Assets:**
  - `arch_jade_pillar_01.png` (matches arena obstacle pillars)
  - `arch_celestial_gate_01.png` (optional backdrop arch)
  - `deco_cloud_lantern_01.png`, `deco_incense_brazier_01.png`, `deco_peach_bonsai_01.png`, `deco_cloud_rock_01.png`
- **Output Paths:**
  - Source: `assets/source/environment/`
  - Base: `assets/base/environment/architecture/`, `assets/base/environment/decorations/`, `assets/base/props/`
- **Naming:** `<category>_<name>_<variant>.png`
- **Dimensions:** `128x128` (decorations/rocks) or `128x192` (tall pillars/gates), PNG RGBA, bottom-center ground contact at `y = height - 16`.
- **Animation Requirements:** None (static).
- **Acceptance Criteria:** Clean 100% transparent background, top-left lighting, clear silhouette separated from `B01` ground colors.
- **Dependencies:** `B01` (palette & scale alignment).

---

## B03: Hero Sprites

- **Required Assets:** `player_hero` (Cute chibi Celestial Monk / Skyblade with jade-blue robes, warm gold trim, glowing sword).
- **Output Paths:**
  - Source frames: `assets/source/characters/player_hero/<task_id>/frame_000.png`
  - Base normalized frames: `assets/base/characters/hero/`
  - Generated atlases & Godot `.tres`: `assets/generated/sprites/player_hero/player_hero_sprite_frames.tres`
- **Naming:** `player_hero_{animation}_{direction}`
- **Dimensions:** `128x128` per frame, pivot `(64, 112)` (`bottom_center_feet`), safe margin `4px`.
- **Animation Requirements:** `idle` (4f @ 6fps, loop), `walk` (4f @ 8fps, loop), `attack` (4f @ 12fps), `hurt` (2f @ 10fps), `death` (4f @ 8fps) × `down`, `right`, `up`.
- **Acceptance Criteria:** Passes `gameforge-kit` `validators.py` (`PASS` or reviewed `REVIEW_REQUIRED`), `player_hero_sprite_frames.tres` loads cleanly in Godot 4 with all 15 animations.
- **Dependencies:** None (must preserve `player_hero_sprite_frames.tres` path).

---

## B04: Enemy Sprites

- **Required Assets:**
  - `enemy_melee` (Fallen Cloud Imp / Demonling — crimson & dark indigo)
  - `enemy_ranged` (Storm Archer — teal & violet, bow/orb)
  - `enemy_tank` (Stone/Jade Construct or Heavy Demon — bulky silhouette, shield/hammer)
- **Output Paths:**
  - Source frames: `assets/source/enemies/<enemy_id>/`
  - Base: `assets/base/enemies/slime/`, `assets/base/enemies/demon/` (or `<enemy_id>/`)
  - Generated: `assets/generated/sprites/<enemy_id>/<enemy_id>_sprite_frames.tres`
- **Naming:** `{enemy_id}_{animation}_{direction}`
- **Dimensions:** `128x128` per frame, pivot `(64, 112)`.
- **Animation Requirements:** Same 5 animations × 3 directions (`15` tasks per enemy).
- **Acceptance Criteria:** Distinct silhouettes readable at `0.9–1.15` scale, passes `gameforge-kit` structural & consistency validators, exports `.tres`.
- **Dependencies:** `B03` (scale & outline thickness reference).

---

## B05: Boss Sprites

- **Required Assets:** `boss_thunder_warden` / `stone_guardian` (Thiên Lôi Tướng — horned/crowned celestial general, gold & purple aura, halberd/hammer).
- **Output Paths:**
  - Source frames: `assets/source/boss/boss_thunder_warden/`
  - Base: `assets/base/boss/stone_guardian/`
  - Generated: `assets/generated/sprites/boss_thunder_warden/boss_thunder_warden_sprite_frames.tres`
- **Naming:** `boss_thunder_warden_{animation}_{direction}`
- **Dimensions:** `128x128` (compatible with existing `profiles/cloudbound_isometric.json`) or `256x256` with a dedicated boss profile. Pivot `bottom_center_feet`.
- **Animation Requirements:** `idle`, `walk`, `attack`, `hurt`, `death` × `down`, `right`, `up` (`15` tasks).
- **Acceptance Criteria:** Clear attack windup readable over Phase 1 & Phase 2 telegraphs, passes `gameforge-kit` validation, exports `.tres`.
- **Dependencies:** `B03`, `B04` (visual hierarchy — Boss must read larger and more imposing).

---

## B06: Combat VFX & Portal

- **Required Assets:**
  - `vfx_slash_arc` (player auto-attack / Q skill crescent)
  - `vfx_thunder_bolt` (E skill & boss barrage orb)
  - `vfx_impact_burst` (hit spark / ring burst)
  - `vfx_heaven_portal` (`Cổng Thiên Giới` swirling gold/sky-blue portal loop)
- **Output Paths:**
  - Source frames: `assets/source/vfx/<vfx_id>/`
  - Base: `assets/base/vfx/`
  - Generated: `assets/generated/sprites/<vfx_id>/`
- **Naming:** `{vfx_id}_{animation}_down` (for single-direction VFX packed via `gameforge-kit`) or `vfx_<name>_01.png`
- **Dimensions:** `128x128` per frame, PNG RGBA, center pivot `(64, 64)`.
- **Animation Requirements:** 4–6 frames @ `12 fps` (`loop: true` for portal, `loop: false` for bursts/slashes).
- **Acceptance Criteria:** Additive/alpha-friendly clean edges, no opaque black/white boxes, high contrast against `B01` jade/cream ground.
- **Dependencies:** `B01` (contrast check against ground).
