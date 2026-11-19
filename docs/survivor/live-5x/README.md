# Visible 5× gameplay QA

This report records the earlier player-commanded formation. For the current game and reproduction commands, see the [commander report](../commander/README.md).

**Victory at 300.783 in-game seconds.** The Godot window ran the match at `Engine.time_scale = 5.0` and reached the result in **60.950 wall-clock seconds** from battle start. At the 300-second checkpoint the Boar King had 24 HP. The runner continued for 0.783 game seconds so the game could resolve the fight itself.

The run ended with Wukong at **176/261 HP**, **Level 18**, **726 Gold**, and **5/5 monkeys**. The runner cleared 17 level-up shops, recruited 11 monkeys including six replacements, equipped 11 weapons, and defeated 176 enemies.

[63-second MP4 replay](replay.mp4) · [Live simulation log](simulation.log) · [Focused regression log](regression.log)

## Screenshots

[0 s](000s.png) · [60 s](060s.png) · [120 s](120s.png) · [180 s](180s.png) · [240 s](240s.png) · [300 s](300s.png) · [Boss encounter](boss.png) · [Victory](result.png)

## PASS/FAIL checklist

| Check | Result | Evidence |
|---|---|---|
| Visible desktop window and HUD | PASS | Live macOS Godot window observed during regular waves and the boss fight. HUD displayed HP, Gold, XP, level, timer and monkey count. |
| Real-time 5× execution | PASS | 300 physics ticks per wall-clock second preserved a 1/60-second simulated physics step. The match took 60.950 wall seconds, including brief shop stalls and capture overhead. Time scale returned to 1.0 before the result hold. |
| 300-second checkpoint and result | PASS | The 05:00 image was recorded at 300.050 seconds. The scheduled boss fight ended in Victory at 300.783 seconds. The separate regression run also exercised Defeat and Restart. |
| Enemy spawns and lane containment | PASS | Live snapshots verified assigned lanes and downward movement throughout the match. Focused regression verified exact spawn centers for all three enemy types and no cross-lane chase. |
| Command lane and formation | PASS | Automated A/D commands used all three lanes. Wukong stayed behind the monkeys, which retained valid, spaced slots as they moved. |
| Cross-lane weapon ranges | PASS | Focused regression verified adjacent-lane bow and magic hits, splash damage, and melee hits and misses on opposite sides of its range limit. |
| Gold, XP and level-up shops | PASS | Live reward deltas matched eliminated enemies and level thresholds. Shop payments matched recruit and equipment prices, and the runner resumed play after every shop. |
| Recruitment, equipment and slot reuse | PASS | Live match reached five monkeys and replaced six fallen soldiers. Focused regression verified that replacement reused the vacant slot without moving its neighbors. |
| Logs, screenshots and video | PASS | Status logged at 0 and every 30 in-game seconds through 300. All eight requested screenshots saved at 1280×720. The MP4 was decoded and checked at 854×480, 15 FPS, 63 seconds, with the Victory screen visible at the end. |

The live runner changed only test code. It reused the validated shop policy, lane controller, and formation check and sampled the running Godot viewport for video. The separate 48-assertion regression run used headless mode.

## Reproduce the visible run

On macOS, from the project root, run the following. The game opens immediately and starts automatically. The live runner can also accept `--output=/absolute/path` after the `--` delimiter.

```sh
qa_frames=$(mktemp -d /tmp/cloudbound-live-frames.XXXXXX)
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 \
  --script tests/run_survivor_live.gd -- "--frames=$qa_frames" \
  > docs/survivor/live-5x/simulation.log 2>&1
```

The optional `--frames` argument records 15 viewport frames per wall-clock second to a fresh directory. Omit it for the same visible run without video frame capture. To repeat the focused regression, run:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --fixed-fps 60 \
  --script tests/validate_survivor.gd
```
