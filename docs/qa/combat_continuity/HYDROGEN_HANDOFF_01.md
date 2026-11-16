Implemented the bounded combat, telegraph, animation, VFX/damage-number, and six-scene continuity fixes within the authorized script ownership. No commits, pushes, asset edits, toolkit changes, or automated gameplay loops were performed.

---

### 1. Root Causes Found (File & Function)

1. **Immediate hit instead of animation-frame impact & action overlap**
   - [player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd): `try_manual_attack`, `_cast_skill_1`, and `_cast_skill_2` applied damage and spawned slash/burst VFX immediately on input frame 0 while setting `_attack_anim_timer` (`0.25`/`0.35`).
   - `_physics_process` retriggered `try_manual_attack()` whenever `_attack_held` was true and `_atk_timer <= 0.0`, stomping active `skill_1_down`/`skill_2_down` casts and overlapping actions.
   - `_play_anim` restarted non-looping animations (`dash_right` 0.167s vs `dash_duration` 0.18s; `attack_*` 0.25s; `hurt_down` 0.20s) whenever `not _sprite.is_playing()` was evaluated while timers remained > 0.
   - `take_damage` lacked an `amount <= 0` guard and did not cancel pending un-triggered actions on hurt/dash/death.

2. **Damage numbers, hit feedback & `Effects` layering**
   - [combat_system.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/combat_system.gd): `spawn_damage_number` assigned local `position` directly from world `pos` with a fixed `-34` vertical offset (landing at Wukong's knees and Guardian's shins), did not reject `amount <= 0`, and had no stagger for simultaneous hits.
   - `_MeleeSlashEffect` and `_RingBurstEffect` had default `z_index = 0`, allowing them to render behind `CloudPortal` (`z_index = 5`).
   - [damage_number.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/damage_number.gd): Left-aligned label (`Vector2(-24, -14)`), identical `16` px font size for crits and normal hits, and no ease-out scale punch.
   - [enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd) & [boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd): `take_damage` lacked `amount <= 0` guards and sprite hit-flash feedback; boss spawned popups at `global_position + Vector2(0, -16)` (`-50` px total).

3. **Telegraphs, coordinate/margin mismatch, clamping & phase callbacks**
   - [enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd) (`_begin_telegraph`, `_die`): Ranged enemies drew a line of `attack_range` (`340`) width `20.0`, then re-aimed `fire_dir` at `_player.global_position` on `triggered`, defeating sideways dodges. Melee/AoE used inline `hit_rad + 14.0` instead of shared geometry with player radius `16.0`. Enemy death left telegraphs active on screen, and invalid `_player` on `triggered` left `_state` stuck in `TELEGRAPH`.
   - [boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd):
     - `_do_charge_pattern` spawned a straight line of width `58.0` vs `_charge_hit_radius = 68.0` (diameter `136.0`) and ignored `_arena.clamp_to_arena(..., 34.0)` used during `CHARGING`.
     - `_do_barrage_pattern` spawned a `circle(90.0)` at the boss and re-aimed `base_dir` on `triggered` instead of locking spread lanes at telegraph start.
     - `_enter_phase_2` and `_die` did not cancel active telegraphs or invalidate pending phase-1 callbacks, allowing old slam/charge/barrage callbacks to execute during/override `PHASE_TRANSITION`.
     - `_trigger_next_pattern` called `_play_anim("attack")` (mapped to `heavy_walk_down`) before slam/barrage selected their own animations.

4. **Movement animation & facing**
   - [player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd), [enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd), [boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd): Non-looping animations (`hurt_down`, `dash_right`, `attack_*`) restarted near timer expiry (`not _sprite.is_playing()`), player `walk` did not scale with `move_speed` upgrades, and near-vertical `dir.x` could flicker facing.

5. **Scene continuity & runtime handoff edge cases**
   - [main.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/main.gd): `camera.position` stayed fixed at its opening composition offset (e.g., `(475, -75)` in `stairway_clouds`) as the player walked across wide stages; `GameData.scene_entry` was not cleared after restoration; `_on_floor_cleared` did not guard against `player._is_dead`.
   - [floor_manager.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/floor_manager.gd) & [cloud_portal.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/cloud_portal.gd): No `_portal_spawned` idempotency guard against simultaneous wave-end kills, no dead-player guard on portal `body_entered`, and a boss dying in melee range could spawn the portal directly under the player and trigger transition immediately on death/upgrade dismissal.
   - [orb_pickup.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/orb_pickup.gd): A player standing inside a health orb at full HP would not collect it after taking damage without exiting and re-entering.

---

### 2. Changes Implemented

- **[player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd)**:
  - Replaced timer-only attack playback with frame-driven action state (`_active_action`, `_action_serial`, `_sprite.frame_changed` + `animation_finished`, plus 1-frame static fallback).
  - J/K/L start anticipation on frame 0 and execute `_execute_basic_attack`, `_execute_skill_1`, `_execute_skill_2` once at the impact/release frame (`_action_hit_applied` guard). Preserved `skills.json` damage, cooldown, range, `arc_deg`, crit, K radius, and L target/bolt rules.
  - Blocked held/tapped J from interrupting active J/K/L/dash/hurt; K and L cannot stomp each other, while K/L cleanly supersede basic attack and Space/Hurt/Death cancel any un-triggered action via `_cancel_active_action()`.
  - Added `amount <= 0` guard, `_sprite.modulate` hit flash, height-adjusted damage/heal numbers (`112.0`), non-looping restart prevention (`_play_resolved_anim`), and velocity-scaled walk FPS.
- **[damage_number.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/damage_number.gd)** & **[combat_system.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/combat_system.gd)**:
  - Converted world positions via `effects_container.to_local(...)`, rejected `amount <= 0`, added target-relative `height_offset`, added `0.35s` / `52px` cluster staggering for simultaneous hits, centered labels, enlarged/styled crits (`font_size = 23`, `1.42 -> 1.0` scale ease-out), and smoothed rise/alpha fade.
  - Enforced explicit VFX `z_index` layering (`TelegraphArea = -1`, `_RingBurstEffect = 12`, `_MeleeSlashEffect = 15`, `GameProjectile`/impact `= 20`, `DamageNumber = 100` with `z_as_relative = false`), and added `spawn_hit_impact`, `spawn_capsule_telegraph`, and `spawn_projectile_fan_telegraph`.
- **[telegraph_area.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/telegraph_area.gd)** & **[projectile.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/projectile.gd)**:
  - Added `CAPSULE` and `PROJECTILE_FAN` shapes, `cancel()`, and shared `contains_circle(world_pos, entity_radius)` geometry queries. Kept `CIRCLE` rendering as true circles (never flattened to ellipses). Guarded projectiles against dead targets and `damage <= 0`.
- **[enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd)**:
  - Locked ranged projectile direction (`locked_dir`) at telegraph start with honest lane width `24.0` (`2 * (8 + 4)`) and travel length `max(attack_range, projectile_speed * 1.6)`.
  - Shared `t.contains_circle(_player.global_position, 16.0)` for melee/AoE hits, added `_cancel_telegraph()` on `_die()`, non-looping hurt restart fix, `_sprite.modulate` hit flash, and height-adjusted damage numbers (`122.0` / `152.0` for tank).
- **[boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd)**:
  - Added `_cancel_active_pattern()` + `_pattern_serial` invoked on `_enter_phase_2()` and `_die()` so no phase-1 telegraph/callback fires during `PHASE_TRANSITION` or death.
  - Switched Slam to `t.contains_circle(_player.global_position, 16.0)` / `t2.contains_circle(...)`.
  - Switched Charge to `CAPSULE` telegraph of radius `_charge_hit_radius` (`68.0`, total width `136.0`) along the simulated `_arena.clamp_to_arena(..., 34.0)` path.
  - Switched Barrage to locked `PROJECTILE_FAN` directional lanes matching the exact `7`/`11`-projectile `95°`/`130°` spread and `30.0` collider diameter.
  - Added hit flash on `_sprite.modulate` (preserving Phase 2 `self.modulate`), `height_offset = 225.0`, `amount <= 0` guard, and `heavy_walk` animation during `CHARGING`.
- **[main.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/main.gd)**, **[progression_system.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/progression_system.gd)**, **[floor_manager.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/floor_manager.gd)**, **[cloud_portal.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/cloud_portal.gd)**, **[orb_pickup.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/orb_pickup.gd)**:
  - Cleared `GameData.scene_entry` after safe `.get()` restoration; guarded `_on_floor_cleared()` against dead player; smoothed camera centering once the player moves `> 8 px` from spawn (keeping opening framing intact); added `_portal_spawned` guard, `0.55s` `arm_delay` when boss-death portal spawns within `84 px` of player, dead-player portal check, and overlapping health-orb polling when damaged.

---

### 3. Action Impact Frame Choices & Art Alignment

Inspected contact sheets under [previews/](file:///Users/thanhpv/Documents/Work/cloudbound/docs/assets/animation_pack_qa/previews) and [player_hero_sprite_frames.tres](file:///Users/thanhpv/Documents/Work/cloudbound/assets/generated/sprites/player_hero/player_hero_sprite_frames.tres):
- **Painted Wukong (`wukong_sprite_frames.tres`, 6 frames `0..5`) — impact/release frame `3`**:
  - `attack_down` (`24 FPS`): `#0` ready, `#1` crouch windup, `#2` forward start, **`#3` full horizontal staff sweep**, `#4–#5` recovery.
  - `attack_up` (`24 FPS`): `#0` ready, `#1` crouch windup, `#2` staff raised, **`#3` full horizontal staff extension**, `#4–#5` recovery.
  - `attack_right` (`24 FPS`): `#0` ready, `#1` crouch windup, `#2` draw back, **`#3` full forward staff thrust**, `#4–#5` recovery.
  - `skill_1_down` (`18 FPS`): `#0–#2` raising and driving vertical staff down, **`#3` full crouch with staff slammed to ground**, `#4–#5` rise recovery.
  - `skill_2_down` (`18 FPS`): `#0–#2` lifting and channeling staff overhead (eyes closed at `#2`), **`#3` forward two-handed staff thrust releasing bolts**, `#4–#5` return.
- **Procedural fallback (`player_hero_sprite_frames.tres`, 4 frames `0..3` at `12 FPS`) — impact frame `2`** (`roundi((count - 1) * 0.6)`), matching peak swing arc (`t = 0.67`, `weapon_swing > 0.35`) in `build_placeholder_assets.py`.
- **Static 1-frame fallback (`set_actor_pose` `"default"`)**: uses `0` impact frame with brief anticipation timer (`0.07s`/`0.09s`) so fallback scenes still function deterministically.

---

### 4. Authoritative Warning Geometry Decisions

- **AoE Circles (`EnemyBase` melee/tank, `BossController` Slam)**: `TelegraphArea` (`CIRCLE`) stores the authoritative center and `radius` and exposes `contains_circle(player.global_position, 16.0)` matching `PlayerController`'s `CircleShape2D` radius (`16.0`). Visual `draw_circle`/`draw_arc` always draws a true Euclidean circle (never squashed to an ellipse).
- **Boss Charge**: Switched from `58.0`-wide line to `CAPSULE` with `radius = _charge_hit_radius` (`68.0`, total width `136.0` + semicircular endcaps) along the arena-clamped `34.0`-margin trajectory so the warning exactly covers the swept hit region.
- **Boss Barrage**: Replaced `circle(90)` with `PROJECTILE_FAN` directional lanes (`7` or `11` locked directions across `95°` / `130°`, lane width `30.0` matching `(11 + 4) * 2` collider diameter), firing `GameProjectile`s along those locked directions at release.
- **Enemy Ranged**: Locked `dir` at telegraph start with width `24.0` (`(8 + 4) * 2`) and length `max(attack_range, projectile_speed * 1.6)` so sideways dodges reliably evade the shot.

---

### 5. Asset Motion / Jitter Findings (Reported, Not Edited)

Per ownership rules, no pixels or `.tres`/atlas files were modified. Existing GameForge motion warnings documented in [wukong_frame_qa.json](file:///Users/thanhpv/Documents/Work/cloudbound/docs/assets/animation_pack_qa/wukong_frame_qa.json) (`wukong_walk_down`: `14.2 px` horizontal spread > `12.0 px`) and [QA_REPORT.md](file:///Users/thanhpv/Documents/Work/cloudbound/docs/assets/animation_pack_qa/QA_REPORT.md#L104-L118) (13 `foot_slide_warning` entries across `boar`, `caster`, `golem`, `guardian`, and `spirit`) remain `REVIEW_REQUIRED` for Orchestrator/Luna visual review.

---

### 6. Validations Executed

| Command | Exit | Notes / Warnings |
|---|---:|---|
| `/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import --quit` | `0` | Godot 4.7.2; nested `tools/gameforge-kit/examples/characters/godot_demo` ignored; sandboxed `editor_settings-4.7.tres` write warning outside workspace. No project import errors. |
| `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/tools/verify_animation_pack.gd` | `0` | `PASS: 43 requested animations, 13 SpriteFrames resources`; `PASS: six player bindings, launch scene, and five portal destinations`. |
| `python3 scripts/tools/validate_assets.py` (with `BypassSandbox: true` for user-site `PIL`) | `0` | `[PASS] Repository asset validation passed.` |
| `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit scenes/main.tscn` | `0` | Loaded fallback `main.tscn` cleanly with zero GDScript errors. |
| `git diff --check` | `0` | Clean (no whitespace/conflict-marker issues). |

---

### 7. Files Changed

- [scripts/player/player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd)
- [scripts/enemies/enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd)
- [scripts/boss/boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd)
- [scripts/combat/combat_system.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/combat_system.gd)
- [scripts/combat/damage_number.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/damage_number.gd)
- [scripts/combat/projectile.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/projectile.gd)
- [scripts/combat/telegraph_area.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/telegraph_area.gd)
- [scripts/main.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/main.gd)
- [scripts/systems/floor_manager.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/floor_manager.gd)
- [scripts/systems/progression_system.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/progression_system.gd)
- [scripts/world/cloud_portal.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/cloud_portal.gd)
- [scripts/world/orb_pickup.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/world/orb_pickup.gd)
*(Preserved pre-existing uncommitted `AGENTS.md`, `docs/AGENT_WORKFLOW.md`, and `docs/qa/`. No new files created.)*

---

### 8. Remaining Real-Runtime Checks & Blockers

- **Remaining checks (Orchestrator / User live Godot gameplay)**:
  1. Scene 03 combat verification: J/K/L frame-synced impact timing, held J not stomping K/L, Dash/Hurt/Death/Pause cancellation of windup, and fallback `scenes/main.tscn` playback.
  2. Damage number height, simultaneous-hit stagger, crit differentiation, hit flashes, and VFX layering above portals/actors.
  3. Enemy ranged dodge vs locked line, Boss Charge swept capsule & arena clamping, Boss Barrage fan lanes, and Phase 2 transition cancellation of mid-telegraph patterns.
  4. Movement facing/pivots/foot alignment across all 6 scenes (including visual review of the open `foot_slide_warning` animations).
  5. Full Scene 01 -> 06 journey: smooth camera centering, HP/maxHP/XP/level/upgrade/loot persistence across all 5 transitions, once-only boss death/portal arming, and death/restart reset.
- **Blockers**: None for code/resource checks; live interactive gameplay testing is outside Hydrogen High's scope per the brief.
