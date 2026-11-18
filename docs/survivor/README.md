# Hoa Quả Sơn — Monkey Army Survivor

Open `project.godot` in Godot 4.7.2 and press **F6** with the Survivor scene open or **F5** from anywhere. Choose **Start Game**. Use **A/D** or **←/→** to change lanes and **Esc** to pause or resume. Wukong and the army attack automatically. On each level-up, recruit or select an ally and buy a weapon for that slot. **Continue** saves unspent Gold and resumes the match.

[Gameplay](gameplay.png) · [Army Shop](shop.png) · [Boar King](boss.png) · [Victory](victory.png) · [Semantic plan](semantic-plan.png)

## Acceptance checklist

| Check | Result | Evidence |
|---|---|---|
| Launch and controls | PASS | Godot opens the title and Start enters the center lane. Tested both key sets, smooth transitions, lane bounds and native input. |
| Scrolling and battlefield clearance | PASS | The repeated ground covers the viewport at every scroll offset. Prop envelopes are outside the protected corridor. Reviewed the rendered match at multiple recycling offsets. |
| Asset import and alignment | PASS | All 141 extracted cells from 15 sheets imported at their recorded native sizes. All non-terrain outputs have transparent and visible pixels. Actor sprites are bottom-aligned at their combat footprints. |
| Enemies and wave progression | PASS | Purple Slimes, Wild Boars and the Boar King spawned on the regular schedule and advanced from the top. The idle run took damage and reached Defeat. |
| Auto-combat and cross-lane range | PASS | Wukong and monkeys attacked during the full run. Focused checks exercised melee range and rejection at one lane-width, a cross-lane bow projectile, magic splash and a missing weapon. |
| Army and purchases | PASS | Recruitment added one ally with a starter staff. The five-ally limit, dead ally replacement, insufficient Gold, invalid slots and duplicate-equipment rejection were checked. Verified weapon selection and charging through shop controls. |
| Gold, XP and pause | PASS | Real kills paid Gold and XP. Level-up opened the paused shop. Native mouse clicks verified skipping, carrying forward Gold, recruiting for 19 Gold, equipping a 16 Gold bow and resuming with it. |
| Results and reset | PASS | Scheduled boss death produced Victory. Zero player HP produced Defeat. Restart reset time, waves, health, Gold, level, lane and army. Main Menu returned to the title. |
| Full match | PASS | Headless Victory at **296.72 seconds**, 183 kills, 17 shops, five allies and 189 Gold spent. Native rendered Victory at **297.68 seconds**. Stationary headless run with no purchases reached Defeat at **195.50 seconds**. |
| 16:9 presentation | PASS | Reviewed the 1280×720 GPU captures and a 1120×630 native window. The screenshots show the supplied sprites, soft lane bands, combat feedback, shop layout and Boss HUD. |

## Reproducing the checks

Run from the project root with the Godot executable on your path.

```sh
godot --headless --path . --editor --import
godot --headless --path . --quit-after 6
godot --headless --path . --fixed-fps 60 --script tests/validate_survivor.gd
godot --path . --disable-vsync --fixed-fps 60 --resolution 1280x720 --script tests/validate_survivor.gd -- --capture
```

The full-match test uses programmed lane input and purchasing through a regular wave schedule. It also runs a separate stationary, no-purchase match. GPU capture uses 4× engine time after the focused checks and runs the same gameplay systems. The native input smoke test separately exercised Start, lane changes, Pause, Resume and the first recruit and weapon purchase in a standalone window at normal speed.

## Asset and layout decisions

- The extraction manifest records each original sheet, SHA-256 and row-major source rectangles. The extractor uses measured cuts for irregular grids, preserves the original PNGs, and removes light baked backgrounds or checker patterns. Unused variants are available in the extracted set. `image.png` is the battlefield reference.
- Characters use supplied pose sequences and horizontally mirrored views. The source Wukong sheet has a hurt pose but no downed frame. Defeat tilts and fades the supplied hurt pose. Recruits share one sprite set, and their equipped weapon is a separate sprite.
- The 1280×1140 semantic plan depicts one authored scroll strip using five registry colors. Its path class is the protected gameplay corridor, visually rendered as three grass bands. The circular tree and rock marks denote ground footprints. The props are decorative and have no solid colliders. Combat has circular proximity and strike footprints in gameplay coordinates. The viewport maps strip coordinates to screen coordinates at 1:1 scale before vertical offset and recycling. There are no doors or world-space pickups. Rewards are collected automatically.
- The earlier exploration scenes reference art removed before this task. The legacy layout check reports missing files despite passing its structural assertions. Separately, the legacy v3 semantic mask validator passed. The Survivor launch scene has its own supplied art and no missing runtime texture was found.

## Changed files

| Path | Change |
|---|---|
| `project.godot` | Launches Survivor and preserves the 16:9 play area when resizing. |
| `scenes/monkey_army_survivor.tscn` | Survivor entry scene. |
| `scripts/survivor/match.gd` | Match rules, waves, formation, combat, economy, progression and state transitions. |
| `scripts/survivor/actor.gd` | Shared pose playback, foot anchors, weapon sprites, damage and death feedback. |
| `scripts/survivor/battlefield.gd` | Scroll projection, seamless ground, lane markers, edge decoration and spawn cue. |
| `scripts/survivor/hud.gd` | HUD, menu, pause, army shop and results. |
| `scripts/tools/prepare_survivor_assets.py` | Reproducible source extraction and provenance manifest. |
| `assets/survivor/` | 141 PNGs, matching Godot import metadata and extraction manifest. |
| `assets/inbox/.gdignore` | Keeps source sheets and the reference out of runtime imports. |
| `tests/validate_survivor.gd` | Automated gameplay checks, complete matches, semantic-plan export and native captures. |
| `docs/survivor/` | Test results, semantic plan and four native screenshots. |

Godot script UID sidecars accompany the new scripts.
