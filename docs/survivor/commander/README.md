# Commander shop and autonomous army

The bottom shop stays open during combat. It shows five role portraits, prices, Gold and an eight-monkey capacity. The match starts with 44 Gold so players can field two affordable recruits before the first kill. Staff costs 15, Archer 22, Mage 26, Tank 20 and Healer 21. Army training costs 32, 58 and 84 Gold for the three successive tiers. Training applies to current units and replacements. XP still advances Wukong’s level during combat. The Boar King is scheduled for 4:49.

Wukong summons from the rear-center line. Staff and Tank take the front rank, Archer and Mage fight behind them, and Healer supports injured troops from the third rank. The formation reviews lane pressure every 1.15 game seconds, preserves the horizontal order of each rank, and reserves a gap for each new recruit, including when all eight share a single rank. Soldiers share one body across all roles. Weapons, shields and role icons are separate sprites.

## Sprite sheets

The [manifest](../../../assets/survivor/summon/manifest.json) records source dimensions, SHA-256 hashes, crop rectangles, frame order, extracted dimensions, alpha ranges and pivots. The [ten original files](../../../assets/archive/adapted/survivor/summon/) are archived intact. Each extracted cell has a transparent three-pixel margin. Body poses use a bottom-center ground pivot. The supplied crouch pose and the existing fade cover the downed state. Standalone effects are triggered by their own events.

| Sheet | Cells | Active use | Source background |
|---|---:|---|---|
| 001 | 8 | Five shop portraits | Native alpha |
| 002 | 8 | Bottom tray and card states | Native alpha |
| 003 | 12 | Shared model’s role equipment and elite attachments | Light matte removed |
| 004 | 12 | Shared idle, movement, attack, cast, injury, cheer and downed poses | Native alpha |
| 005 | 8 | Purchase confirmation and summon arrival | Black matte removed |
| 006 | 12 | Guard and healing feedback | Native alpha |
| 007 | 12 | Role and army capacity icons | Native alpha |
| 008 | 8 | Reinforcement cue | Light matte removed |
| 009 | 12 | Training burst, confirmation and equipment evolution | Native alpha |
| 010 | 12 | Training control | Native alpha |

All 104 cells are extracted and imported. Some decorative variants and icons for mechanics such as rerolls remain in the library.

## PASS/FAIL

| Check | Result | Evidence |
|---|---|---|
| Extraction and Godot import | PASS | Ten verified sources, 104 imported cells at their manifest dimensions, and rendered checks on active portions of the set |
| Bottom shop and training | PASS | Five role prices, insufficient Gold, pause, all training tiers, and slot replacement with inherited training. Eight recruits fit in one rank and a ninth purchase is blocked without a charge. |
| Formation and roles | PASS | Rear-center commander, all three lanes, maintained rank spacing, automatic reinforcement, cross-lane range limits, tank mitigation and healer support |
| Runtime feedback | PASS | Rendered shop, summoning, training, guard, healing and reinforcement fixtures |
| Enemy behavior and rewards | PASS | All three lane routes, unchanged Gold/XP per enemy, 23 regular and elite enemy looks, and five boss profiles |
| Results and restart | PASS | Boss Victory, fatal damage Defeat, restart reset and return to title |
| Visible 5× match | PASS | Victory at 300.733 game seconds in 61.169 wall-clock seconds. 191 kills, eight recruits, three training tiers, and speed restored to 1.0. [Live log](live.log) |

No blocker remains for the playable match. The live army incurred no losses. Replacement was exercised in the focused regression. The suites reported 42 gameplay, 7 enemy, 17 rendered-fixture and 18 live checks passing.

## Screenshots and logs

- Live checkpoints [0s](live/000s.png), [60s](live/060s.png), [120s](live/120s.png), [180s](live/180s.png), [240s](live/240s.png) and [300s](live/300s.png)
- Live [summon](live/summon.png), [training](live/upgrade.png), [Boar King](live/boss.png) and [Victory](live/result.png)
- Normal-speed fixtures [shop](available-shop.png), [all five recruits](summoning-all.png), [training](training-all.png), [healing and guard](heal-and-guard.png), [reinforcement](reinforce-right.png), [boss windup](boss-windup.png), [Victory](victory.png) and [Defeat](defeat.png)
- [Live state and validation](live.log), [gameplay regression](regression.log), [rendered fixtures](rendered-fixtures.log) and [enemy regression](enemies.log)

## Reproduce

Run from the project root. On macOS, substitute `/Applications/Godot.app/Contents/MacOS/Godot` for `godot` if it is outside your PATH.

```sh
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script tests/validate_survivor.gd
godot --headless --path . --script tests/validate_survivor_enemies.gd
godot --path . --resolution 1280x720 --script tests/capture_survivor_polish.gd
godot --path . --resolution 1280x720 --script tests/run_survivor_live.gd -- "--output=$PWD/docs/survivor/commander/live"
```

The live runner opens the actual game window, starts the match, buys troops and training with earned Gold, and logs HP, Gold, XP, level, time and monkey count every 30 game seconds. It sets `Engine.time_scale` to 5.0, keeps the simulated physics timestep at 1/60 second, and restores normal speed after the result.

## Changed files

| Files | Change |
|---|---|
| `scripts/survivor/army_formation.gd`, `match.gd`, `actor.gd`, `battlefield.gd` | Role behavior, spacing, threat-based orders, economy and stationary commander |
| `scripts/survivor/hud.gd`, `polish.gd` | Persistent shop, status icons and feedback |
| `assets/archive/README.md`, `assets/archive/adapted/survivor/`, `assets/survivor/summon/` | Archived originals, extracted parts, imports and manifest |
| `scripts/tools/prepare_summon_assets.py`, `prepare_survivor_assets.py`, `prepare_survivor_enemies.py`, `prepare_survivor_polish.py` | Reproducible extraction and updated archive paths for earlier sheets |
| `assets/survivor/manifest.json`, `assets/survivor/enemies/manifest.json`, `assets/survivor/polish/manifest.json` | Original source archive paths |
| `tests/validate_survivor.gd`, `tests/validate_survivor_enemies.gd`, `tests/capture_survivor_polish.gd`, `tests/run_survivor_live.gd` | Automated, rendered and live validation |
| `docs/survivor/` | Current controls, evidence and historical report pointers |
