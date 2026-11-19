# Monkey Army Defense animation polish

This report records the earlier player-commanded formation. For the current game and reproduction commands, see the [commander report](../commander/README.md).

Open `project.godot` in Godot 4.7.2 and press **F5**. Use **A/D** or **←/→** to command the formation. The polished art uses the existing lane, combat, shop, reward and result logic.

[Integration manifest](../../../assets/survivor/polish/manifest.json) · [Per-sprite render coverage](rendered-coverage.json) · [Asset check](assets.log) · [Rendered checks](visual.log) · [Gameplay regression](regression.log) · [Visible 5× match](live.log)

## Sprite sheets

| Inbox sheet | Extracted | Integrated | Gameplay use |
|---|---:|---:|---|
| 002 Wukong commander | 12 | 12 | Idle, lane movement, commands, staff strikes, hit reaction, cheer and downed pose |
| 003 Baby monkey | 12 | 12 | Shared idle, run, staff, bow, cast, hit and cheer poses |
| 004 Summoning VFX | 8 | 8 | Eight ordered phases of the portal at the recruited slot |
| 005 Baby monkey arrival | 8 | 8 | Gold silhouette sequence that fades into the shared soldier model |
| 006 Formation and commander | 8 | 7 | Lane orders, movement dust and reinforcement cues |
| 007 Weapon combat | 12 | 12 | Ruyi and wooden staff arcs, bow release, streak and impacts, magic cast and area hit |
| 008 Enemy lifecycle | 8 | 8 | Arrival, color-coded impacts and defeat effects |
| 009 Boar King | 8 | 8 | Entrance, warning, slam, shockwave, rage and defeat |
| 010 Combat feedback | 12 | 8 | Hit intensity, motion, strike dust, breach warning and level-up glint |
| 011 Gold and XP | 8 | 8 | Reward drops, trails and receipt glints, plus level-up |
| 012 Shop interactions | 12 | 7 | Recruit and weapon equip feedback, wallet, low Gold and exit |
| 013 Lane warnings | 8 | 8 | Spawn severity, boss, rear-line danger and breaches, command and reinforcement |
| 014 Victory and Defeat | 8 | 8 | Separate result effects around the modal |
| 015 Ambient nature | 8 | 8 | Four grass poses and independent blossom, leaf, pollen and breeze effects |
| **Total** | **132** | **122** | **Every integrated frame and effect appeared in a rendered test** |

Sheets 002, 003, 011 and 015 contain native alpha. The other ten are RGB with baked light backgrounds. The extractor uses measured row and column cuts, removes the baked backgrounds, checks the extracted alpha range, and records original source hashes, crop rectangles, dimensions, and pivots. Wukong and the soldier share a fixed body scale across their poses. The two arrival sequences use registered canvases and a common ground pivot. The four ambient effects stay on the existing edge scenery.

The arrival sheet depicts a different monkey. Its eight poses appear as an effect silhouette while the same soldier art fades in at its existing slot. Weapon attachments remain separate. The new soldier sheet has no downed frame, so the earlier downed sprite is reused. Ten extracted effects are held in reserve because their visuals indicate mechanics the game does not have, including guarding, critical hits, stun, and shop rerolls. The manifest gives the reason for each reserved cell.

## Key gameplay screenshots

- [Summon and formation entry](summon.png) · [Commander pose and lane switch](commander-switch.png)
- [Level-up Shop](shop-level.png) · [Recruit receipt](shop-purchase.png) · [Weapon equip receipt](shop-weapon.png)
- [Enemy entry](enemy-entry.png) · [Lane danger](lane-danger.png) · [Rear-line breach](breach.png)
- [Wooden staff](staff-hit.png) · [Bow projectile](bow-volley.png) · [Area magic](area-magic.png) · [Ruyi strike](ruyi-strike.png)
- [Boss windup](boss-warning.png) · [Boss impact](boss-impact.png) · [Boss rage](boss-rage.png) · [Defeat](defeat.png)
- [Live wave and rewards at 4:00](live/240s.png) · [Live Boar King at 5:00](live/300s.png) · [Live Victory](live/result.png)

The focused images use scripted gameplay events at normal animation speed. The live images use the unmodified wave schedule in a visible Godot window at 5× time scale. The normal-speed test watches texture paths on visible render nodes after drawing each frame. The logs and coverage data distinguish the focused fixtures from the full run.

## PASS/FAIL checklist

| Check | Result | Evidence |
|---|---|---|
| Fourteen originals and extraction | PASS | 14 SHA-256 source identities, four native-alpha sources, ten baked backgrounds, and 132 RGBA cells verified against the extraction manifest. No extracted bounds reach their assigned cell edges. |
| Import and authored frame selection | PASS | Godot 4.7.2 import and startup completed. All 132 textures matched the manifest dimensions. The renderer observed all 122 active images. |
| Formation, scale and equipment | PASS | Captured five soldiers moving together with Wukong behind them. Body envelopes fit their existing slots and each weapon remains an attachment. |
| Summoning, combat and rewards | PASS | Both eight-frame arrival sequences appeared. Tests triggered melee, ranged and area effects, enemy spawn and defeat, lane warnings, breaches and Gold/XP collection. |
| UI and outcome events | PASS | Checked purchase and equip feedback, level-up, boss specials, Victory, Defeat, and Restart through live gameplay or scripted event fixtures. |
| Existing mechanics | PASS | The 48-assertion regression exercised lane limits, weapon ranges, formation spacing, gold and XP, pause, shop prices, spawn routing and outcomes. |
| Complete visible 5× match | PASS | The live run cleared the 300-second checkpoint and defeated the Boar King at 300.783 game seconds in 61.017 wall-clock seconds. It checked 17 shops, six replacements, five occupied slots at Victory, economy deltas and fixed enemy lanes. |

## Changed files

| Path | Change |
|---|---|
| `assets/archive/adapted/survivor/polish/` | Fourteen original source sheets. |
| `assets/survivor/polish/` | Extracted PNGs, Godot import metadata and source-to-cell manifest. |
| `scripts/tools/prepare_survivor_polish.py` | Deterministic extraction and read-only verification. |
| `scripts/survivor/actor.gd` | Commander and soldier poses, attachments and visual arrival. |
| `scripts/survivor/polish.gd` | Shared sprite, tween and sequence helpers. |
| `scripts/survivor/match.gd` | Effects triggered by combat, recruitment, orders, rewards and boss state. |
| `scripts/survivor/battlefield.gd` | Lane warnings and edge scenery animation. |
| `scripts/survivor/hud.gd` | Shop, reward and result effects. |
| `tests/capture_survivor_polish.gd` | Rendered event fixtures and per-image coverage. |
| `docs/survivor/polish/` | Screenshots, test logs and report. |

## Reproduce

Run from the project root with Godot on your path.

```sh
python3 scripts/tools/prepare_survivor_polish.py --check
godot --headless --path . --editor --import
godot --headless --path . --fixed-fps 60 --script tests/validate_survivor.gd
godot --path . --disable-vsync --fixed-fps 60 --resolution 1280x720 --script tests/capture_survivor_polish.gd
godot --path . --resolution 1280x720 --script tests/run_survivor_live.gd -- "--output=$PWD/docs/survivor/polish/live"
```
