# Hoa Quả Sơn — Three-Lane Monkey Defense

Open `project.godot` in Godot 4.7.2, press **F5**, and choose **Start Game**. Use **A/D** or **←/→** to command a lane and **Esc** to pause or resume. Wukong and the monkeys attack automatically. Recruit and equip monkeys in level-up shops. **Continue** saves unspent Gold and resumes the battle.

[Left formation](formation-left.png) · [Center formation](gameplay.png) · [Right formation](formation-right.png) · [Army Shop](shop.png) · [Boar King](boss.png) · [Victory](victory.png) · [Terrain plan](semantic-plan.png)

[Animation polish, sprite-sheet manifest and new QA captures](polish/README.md) · [Bộ 27 quái và boss mới](enemies/README.md)

## Gameplay decisions

- Enemy routes start at X = 420, 640 or 860. Slimes, boars and the Boar King advance down their assigned lane. A same-lane follower can offset slightly and queue behind its leader. Enemy attack warnings are fixed in place and limited to the enemy's lane.
- The selected lane is marked in gold at the rear line. Regular breaches cost Wukong HP and grant no kill rewards. The Boar King remains in its lane at the rear line and winds up repeated breach strikes while alive.
- A single smoothly moving anchor sets Wukong’s position and all five slot positions. Three monkeys form the front rank, and two form the reserve rank. The commander stays behind both. Slot occupancy survives lane changes, and a replacement takes its vacant slot.
- Weapon range and targeting are independent of formation movement. A flank staff can reach across a boundary when close enough. Bows and magic can target adjacent lanes at longer ranges. The Boar King still arrives at 4:38. Its health is 1,150 because Wukong contributes less damage from the rear.

## Acceptance checklist

| Check | Result | Evidence |
|---|---|---|
| Start and three command lanes | PASS | The match starts centered. Both key sets select lanes, clamp at the edges and move smoothly. |
| Strict enemy routes and local separation | PASS | All three enemy types spawn at each exact center in focused tests. Scheduled enemies kept their assigned lane and advanced without moving upward throughout the full match. A focused test verified local separation behind a same-lane leader. |
| Lane-limited strikes and breaches | PASS | A telegraphed strike missed Wukong after he left its lane. A regular breach reduced HP without a reward. The boss held its lane and telegraphed a rear-line hit. |
| Commander and formation clearance | PASS | Tested the full five-monkey formation on all three lanes and sampled its position during transitions. Conservative sprite and equipment envelopes stayed clear of one another and the battlefield edges. Native screenshots show the three positions. |
| Recruitment and replacement | PASS | Purchases filled vacant slots, the five-ally cap held, and a replacement reused the same slot without moving its neighbors or leaving a visible duplicate. |
| Weapon behaviors and range | PASS | Tested short-range melee, both sides of the melee range boundary, an adjacent-lane bow projectile, and an adjacent-lane magic strike with splash damage. Automatic attacks ran during the full match. |
| Existing battlefield, economy and shop | PASS | Checked scrolling coverage, prop clearance and all 141 imported assets. Real kills granted Gold and XP. Level-up paused the match. Shop controls handled costs, invalid purchases, slot selection and resume. |
| Boss, Victory, Defeat and Restart | PASS | Scheduled boss death opened Victory. A stationary run without purchases reached Defeat. Restart reset health, time, waves, Gold, level, lane and army. Main Menu returned to the title. |
| Complete match | PASS | Headless Victory at **306.53 s** with 180 kills, 17 shops and a peak of five monkeys. Rendered Victory at **301.75 s** with 179 kills. Stationary headless Defeat at **110.25 s**. |

## Reproducing validation

Run from the project root with the Godot executable on your path.

```sh
godot --headless --path . --quit-after 6
godot --headless --path . --fixed-fps 60 --script tests/validate_survivor.gd
godot --path . --disable-vsync --fixed-fps 60 --resolution 1280x720 --script tests/validate_survivor.gd -- --capture
```

The full-match test drives the lane commands and shop with programmed inputs over the regular wave schedule. The GPU run uses 4× engine time after the focused checks. The screenshots come from that rendered run. The final suite reported 48 passing headless assertions and 55 passing rendered assertions. A separate native mouse and keyboard check verified Start, level-up pause, carrying Gold forward, recruiting, equipping a bow, and moving the archer ahead of Wukong into the right lane.

## Changed files

| Path | Change |
|---|---|
| `scripts/survivor/match.gd` | Shared formation anchor, lane-filtered enemy attacks, bounded separation, rear line and boss balance. |
| `scripts/survivor/actor.gd` | Per-enemy lane and rear-line strike state. |
| `scripts/survivor/battlefield.gd` | Shared lane geometry and rear-line markers. |
| `scripts/survivor/hud.gd` | Commander controls and rear-line HP hint. |
| `tests/validate_survivor.gd` | Lane, formation, weapon and full-match regression checks and capture selection. |
| `docs/survivor/` | Validation report and rendered left, center, right, shop, boss and victory screenshots. |

The existing scene and supplied sprite sheets serve the updated mode. The terrain plan retains the authored scroll strip and protected corridor. The older exploration scenes still reference art removed before the Survivor MVP.
