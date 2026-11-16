# Cloudbound animation and gameplay QA

**Goal status — PARTIAL**

## Asset generation

- Generated 43 requested animations represented by 13 Godot SpriteFrames resources. The original three approved Wukong animations remain in the shared player resource.
- Godot verified the requested names, counts, sizes, and loop flags. The repository validator checked transparency, alignment, and distinct pixel data across the 43 new atlases.
- The upward and right-facing Wukong attacks use 256 × 176 cells with manually aligned foot pivots to keep the staff within the canvas. Other character cells use 208 × 176.
- GameForge motion review remains open for the enemy and guardian sets. The collapse height tolerances were adjusted for the spirit, caster, boar, golem, and guardian. Those checks still report motion warnings.
- Source attempts with opaque backdrops were excluded. Replacement sheets were used for the golem death, guardian rune special, and guardian death.

[Animation previews](previews/) · [Asset checkpoints](PROGRESS.md)

## Integration

| System | Current state |
|---|---|
| Wukong | Shared resource in six scenes with directional walk and attack, skill casts, dash, hurt and death |
| Enemies | Cloud spirit, caster, boar and golem each have five animations bound to the encounter controller |
| Guardian | Six animations bound, with slam and rune special selected by the existing attack patterns |
| VFX | Animated slash, projectile, impact, circular warning, and portal swirl |
| Pickups | Animated health and loot orbs with configurable enemy drops, healing, and currency HUD |
| Progression | Scene handoff preserves HP, XP, level, selected upgrades and loot. Upgrades reconstruct max HP and combat stats. Restart reloads the current scene and resets the run. |

## Runtime evidence

All six opening viewports were captured from Godot 4.7.2 at 1280 × 720. Each scene was loaded individually and paused for its capture.

| Scene | Viewport | Gameplay |
|---|---|---|
| 01 Mortal Realm | [Capture](runtime/scene_01_mortal_realm.png) | Portal and handoff pending |
| 02 Cloud Bridge | [Capture](runtime/scene_02_stairway_clouds.png) | Spirit encounter and handoff pending |
| 03 Cloud Outskirts | [Capture](runtime/scene_03_azure_outskirts.png) | Player moves, attacks, skills, damage and pickups pending |
| 04 Celestial Courtyard | [Capture](runtime/scene_04_azure_center.png) | Golem encounter and handoff pending |
| 05 Guardian Arena | [Capture](runtime/scene_05_boss_arena.png) | Both guardian phases, death reward and portal unlock pending |
| 06 Gate of Heaven | [Capture](runtime/scene_06_gate_of_heaven.png) | Arrival state and victory pending |

## Test results

- Opened all 43 preview GIFs and decoded their final frames. Each GIF has the same frame count as its atlas, and all 43 contact sheets passed PNG verification.
- Verified the project launch scene and all five portal destination paths in the Godot resource audit.

- Passed Godot 4.7.2 headless editor import, the 43-animation SpriteFrames audit, repository asset validation, and `git diff --check`.
- The import warned that Godot ignored the nested GameForge example project.
- Gameplay testing is assigned to the user by the repository workflow. No simulated gameplay test was run.

## Manual verification

- Press F5 and play Scene 01 through Scene 06 in order. Record HP, max HP, XP, level and loot before each portal, and compare the values and applied upgrades after arrival.
- In Scene 03, check WASD, attacks in all directions, distinct K and L casts, Space dash, hurt, death, and restart. Inspect foot alignment and staff visibility during motion.
- Check the four enemies' movement, attack warnings, hurt and death animations and one XP reward per kill. Collect orbs, verify max HP caps healing, and verify loot updates immediately and carries forward.
- In Scene 05, verify ground slam, rune special, warnings in both phases, one death reward, and one portal. Enter the portal and finish Scene 06.

## Changed areas

- Shared Wukong SpriteFrames and five additional scene bindings.
- Controller updates in `scripts/player/`, `scripts/enemies/`, and `scripts/boss/`.
- Scene flow, progression, loot, and HUD in `scripts/main.gd`, `scripts/systems/`, and `scripts/ui/ui_manager.gd`.
- Combat effect and pickup integration in `scripts/combat/` and `scripts/world/`.
- New atlases, extracted frames and resources in `assets/generated/{wukong,enemies,pickups,combat_vfx}/`.
- Asset staging and verification in `scripts/tools/`, with pickup profile, previews and runtime captures.

## Checkpoint revalidation — 2026-11-16

- Read repository `AGENTS.md`, handoff, this report, the original attached specification, and GameForge validation instructions. Reviewed the existing tracked diff and inventoried all 816 untracked files (including generated frames, atlases, resources, previews, and scripts). Existing assets and code were preserved.
- User requested continuing from the handoff; no per-scene manual playtest results or reproducible gameplay failures have been supplied. Gameplay rows above remain pending. No new gameplay fix is claimed in this checkpoint.
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --import --quit` — exit 0, Godot 4.7.2. Warning: nested GameForge example project ignored. No import error reported.
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/tools/verify_animation_pack.gd` — exit 0:
  ```text
  PASS: 43 requested animations, 13 SpriteFrames resources
  PASS: six player bindings, launch scene, and five portal destinations
  ```
- `python3 scripts/tools/validate_assets.py` — exit 0: `[PASS] Repository asset validation passed.`
- `git diff --check` — exit 0, no output.
- The resource audit instantiates scenes outside the running tree; it does not exercise combat, pickups, transitions, or persistence. No automated gameplay simulation was executed, as required by repository `AGENTS.md`.
- Structural checks do not resolve the existing GameForge motion warnings. Animation quality, complete encounters, pickup behavior, and continuity across all five transitions still require manual evidence. The goal remains PARTIAL and is not complete.
- No commit, push, toolkit modification, asset regeneration, or balance change was performed during this revalidation.

## Definition-of-done evidence audit

| Original criterion | Current evidence | Completion decision |
|---|---|---|
| 1. Required animation assets exist | Resource audit loads all 43 requested animations in 13 SpriteFrames; extracted frames and atlas files exist | Asset existence verified |
| 2. All animations pass asset QA | Repository structural validation passes; GameForge motion review remains open | Not achieved |
| 3. Correct SpriteFrames integration | Six scene player bindings and all requested animation settings pass resource audit; controller mappings reviewed | Resource bindings verified; gameplay selection pending |
| 4. Wukong animations work in gameplay | Controller integration and opening captures only | Not proven |
| 5. Enemy animations work in gameplay | Four sets bound in EnemyBase; opening captures only | Not proven |
| 6. Boss animations work in gameplay | Guardian set bound in BossController; opening capture only | Not proven |
| 7. Combat VFX work correctly | Five VFX resources load and code references exist | Not proven in combat |
| 8. Health and loot pickups function | OrbPickup and configurable death drops implemented; heal feedback exists in PlayerController | Collection, HP cap, HUD and duplicate protection need gameplay evidence |
| 9. Progression persists across six scenes | Snapshot/restore and selected-upgrade reconstruction exist; five destination paths pass | All five actual handoffs and retained values need gameplay evidence |
| 10. Godot runtime validation passes | Import and resource audit pass | Gameplay runtime validation incomplete |
| 11. Actual gameplay evidence available | Six paused opening captures and 43 previews exist | Combat and full journey evidence missing |

### Motion warning inspection

Reviewed `guardian_heavy_walk_down/contact_sheet.png`: eight poses show alternating support feet, intact silhouette, and a stable overall body position. The reported 58.3 px horizontal spread measures changing lowest occupied pixels; this can change when the support foot switches. This static review does not establish smooth playback, weight, or absence of sliding in Scene 05. Keep `REVIEW_REQUIRED`; do not normalize away the step or relax the warning threshold merely to obtain a pass.

The original `manifest.json` describes the earlier Gate A source archive, including rejected sheets. It is historical baseline evidence, not the inventory or approval record for the newly generated pack.

The following warnings were read from existing GameForge reports (not a fresh validator run). Reports are under ignored `.gameforge/work`; this table preserves the specific open checks in the QA deliverable.

| Animation | Recorded motion issue |
|---|---|
| boar_axe_attack_down | foot_slide_warning: Foot anchor horizontal spread is 57.2px (> 12.0px). |
| boar_death_down | foot_slide_warning: Foot anchor horizontal spread is 70.3px (> 12.0px). |
| boar_walk_down | foot_slide_warning: Foot anchor horizontal spread is 36.4px (> 12.0px). |
| caster_death_down | foot_slide_warning: Foot anchor horizontal spread is 32.6px (> 12.0px). |
| caster_walk_down | foot_slide_warning: Foot anchor horizontal spread is 36.3px (> 12.0px). |
| golem_death_down | foot_slide_warning: Foot anchor horizontal spread is 26.6px (> 12.0px). |
| golem_heavy_walk_down | foot_slide_warning: Foot anchor horizontal spread is 51.8px (> 12.0px). |
| guardian_death_down | foot_slide_warning: Foot anchor horizontal spread is 22.2px (> 12.0px). |
| guardian_ground_slam_down | foot_slide_warning: Foot anchor horizontal spread is 15.4px (> 12.0px). |
| guardian_heavy_walk_down | foot_slide_warning: Foot anchor horizontal spread is 58.3px (> 12.0px). |
| spirit_attack_down | foot_slide_warning: Foot anchor horizontal spread is 30.8px (> 12.0px). |
| spirit_death_down | foot_slide_warning: Foot anchor horizontal spread is 19.6px (> 12.0px). |
| spirit_hurt_down | foot_slide_warning: Foot anchor horizontal spread is 35.8px (> 12.0px). |
