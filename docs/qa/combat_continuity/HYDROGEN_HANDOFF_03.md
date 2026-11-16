Implemented the four narrow corrections from [HYDROGEN_REVIEW_03.md](file:///Users/thanhpv/Documents/Work/cloudbound/docs/qa/combat_continuity/HYDROGEN_REVIEW_03.md) using file edits only (no terminal commands, commits, pushes, or gameplay automation).

### Changes

1. **Static `polyline_contains_circle` compile error**
   - [telegraph_area.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/telegraph_area.gd): `TelegraphArea.polyline_contains_circle` and `TelegraphArea._distance_to_polyline` — converted `_distance_to_polyline` to a `static func` directly and removed `_static_distance_to_polyline`, resolving the static-to-instance method call error while preserving `contains_circle` reuse.

2. **Bounded one-slot input buffer (`0.18s`) during action recovery**
   - [player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd): Added `ACTION_BUFFER_WINDOW := 0.18`, `_buffer_action`, `_clear_input_buffer`, and `_consume_buffered_action`, wired into `_ready`, `_unhandled_input`, `_physics_process`, `_start_dash`, `try_manual_attack`, `_cast_skill_1`, `_cast_skill_2`, `_on_sprite_animation_finished`, `take_damage`, and `_die`.
   - Fresh `J`/`K`/`L` presses during recovery of a committed action (`not _active_action.is_empty() and _action_hit_applied`) buffer into one slot without spending cooldowns early or queueing cooldown-locked skills.
   - Buffer counts down only during unpaused gameplay (`_physics_process`), consumes once on action completion when guards/cooldowns permit, never buffers/overwrites from held `J` (`allow_buffer = false`) or held skill keys (`is_action_just_pressed`), keeps anticipation interruption semantics (`K`/`L` over `attack`), and clears on hurt, dash, death, and `_ready`. Preserved `J=3`, `K=4`, `L=3` impact frames and balance config.

3. **Non-danger boss arrival ring**
   - [floor_manager.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/floor_manager.gd): `FloorManager._spawn_boss` — replaced `spawn_circle_telegraph(boss.position, 145.0, 1.1, ...)` with `spawn_ring_burst(boss.position, 145.0, Color(0.45, 0.92, 1.0))` so boss arrival no longer displays a misleading red danger telegraph while keeping boss spawn, AI, and attack warnings unchanged.

4. **Explicit impact/release pose confirmation at telegraph resolution**
   - [enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd) & [boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd): `_start_post_attack_recovery` (called on `t.triggered` before hit/projectile execution) — explicitly confirms the attack animation reaches at least `_get_attack_impact_frame(anim)` via `set_frame_and_progress(impact_frame, 0.0)` (restarting onto `impact_frame` if already finished) and resets `_sprite.speed_scale = 1.0` to continue recovery (`0.24s` cap for enemies, `0.30s` cap for boss) without changing warning durations, cooldowns, or mapped frame indices.

### Files Modified
- [scripts/combat/telegraph_area.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/combat/telegraph_area.gd)
- [scripts/player/player_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/player/player_controller.gd)
- [scripts/systems/floor_manager.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/systems/floor_manager.gd)
- [scripts/enemies/enemy_base.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/enemies/enemy_base.gd)
- [scripts/boss/boss_controller.gd](file:///Users/thanhpv/Documents/Work/cloudbound/scripts/boss/boss_controller.gd)

### Not Tested & Uncertainty
- **Not executed (per instruction — no command/terminal tools invoked):** Godot `--import`, GDScript parse/compile check, `verify_animation_pack.gd`, `validate_assets.py`, `git diff --check`, and live interactive gameplay verification.
- **Unverified at runtime:** Whether `L` pressed on the exact unpause frame vs during remaining `K` recovery frames feels optimal across all upgrade timings, and whether `set_frame_and_progress(impact_frame, 0.0)` inside `_start_post_attack_recovery` eliminates all visual 1-frame drift in live Godot rendering on `EnemyBase` and `BossController`.
