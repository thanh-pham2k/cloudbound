# Đường Đến Thiên Giới (Cloudbound) — MVP

2.5D Isometric Action RPG + Roguelite MVP built with **Godot 4.7 (GDScript)** and integrated with [`gameforge-kit`](tools/gameforge-kit/) as a Git Submodule.

## Setup & Prerequisites

- **Godot 4.x** (tested on Godot `4.7.2.stable`)
- **Python 3** + **Pillow** (`PIL`) for regenerating placeholder sprite atlases via `gameforge-kit`
- *(Optional)* **Blender** for full 3D-to-2.5D rendering via `gameforge-kit` (currently not required; stylized procedural placeholder frames are routed through `gameforge-kit`'s normalizer, packer, validator, and Godot `.tres` exporter)

### Clone with Submodule

```bash
git clone --recurse-submodules <repo-url>
# Or after a regular clone:
git submodule update --init --recursive
```

### Regenerate Sprite Atlases & Godot `.tres` (`gameforge-kit`)

```bash
python3 scripts/tools/build_placeholder_assets.py
```

Outputs are written to `assets/generated/sprites/<character_id>/` (never inside `tools/gameforge-kit/`).

## Controls

| Action | Keys |
| --- | --- |
| Move (8 directions) | `W A S D` or Arrow Keys |
| Basic attack | `J` or left mouse button |
| Dash (`Vân Bộ`) | `Space` or `Shift` |
| Skill 1 (`Lôi Quang Trảm` — AoE burst) | `K` |
| Skill 2 (`Cửu Thiên Lạc Lôi` — Homing bolts) | `L` |
| Pause / Resume | `Esc` or `P` |

## How to Run

### Play in Godot

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Or open the project folder in the Godot 4 Editor and press **F5** to start the six-scene journey in Mortal Realm. Open `scenes/main.tscn` and press **F6** to run the standalone wave arena.

### Run Automated Headless Tests

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/test_runner.tscn
```

## Architecture

- **Data-Driven Config (`data/`):** `enemies.json`, `skills.json`, `upgrades.json`, `floors.json` loaded by `scripts/systems/game_data.gd` (`GameData` autoload).
- **Player Controller:** `scripts/player/player_controller.gd`
- **Combat System:** `scripts/combat/combat_system.gd`, `projectile.gd`, `telegraph_area.gd`, `damage_number.gd`
- **Enemy AI:** `scripts/enemies/enemy_base.gd` (`melee`, `ranged` with retreat AI, `tank` with AoE slam)
- **Boss State Machine:** `scripts/boss/boss_controller.gd` (2 phases, 3 telegraphed patterns: Slam, Charge, Barrage, phase transition at 50% HP)
- **Progression System:** `scripts/systems/progression_system.gd` (EXP curve + 1-of-3 upgrade selection)
- **Floor Manager & World:** `scripts/systems/floor_manager.gd`, `scripts/world/cloud_arena.gd`, `scripts/world/cloud_portal.gd`
- **UI Manager:** `scripts/ui/ui_manager.gd` (HUD, Boss HP bar, Level-Up modal, Pause, Victory, Game-Over)

## Manual Test Checklist

- [ ] Start the standalone wave arena (`scenes/main.tscn`) and verify HUD (HP, EXP, Wave 1, Cooldowns) renders cleanly.
- [ ] Move in all 8 directions with WASD; verify smooth camera follow, Y-sorting around pillars, and arena boundary clamping.
- [ ] Dash (`Space`/`Shift`) and use Skills (`K`, `L`); verify cooldown timers update and invulnerability frames work.
- [ ] Fight `melee`, `ranged` (retreats when approached), and `tank` (telegraphed AoE slam) enemies; verify basic attacks with `J` or left mouse and check damage numbers.
- [ ] Reach 50 EXP to trigger Level-Up modal; pick 1 of 3 upgrades and verify gameplay pauses/resumes cleanly.
- [ ] Clear waves to trigger Boss (`Thiên Lôi Tướng`); verify Boss HP bar, 3 telegraphed patterns, and Phase 2 transition at 50% HP.
- [ ] Defeat Boss to unlock `Cổng Thiên Giới` portal; walk into it to verify Victory screen and Restart button.
- [ ] Let Player HP reach 0 to verify Game-Over screen and Restart button.
