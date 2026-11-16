# Combat and continuity QA — CB-COMBAT-20261116

Status: IN_PROGRESS. Scope follows the user's eight-phase combat/continuity request. Source and runtime evidence must both support acceptance. A headless import is not gameplay verification.

## Root causes confirmed before implementation

| Area | Baseline source evidence | Effect |
|---|---|---|
| J/K/L | `try_manual_attack`, `_cast_skill_1`, `_cast_skill_2` apply damage/spawn VFX directly during input; character animation follows later | Hits precede visible impact/cast release |
| Action arbitration | Single `_attack_anim_timer` can be overwritten by held J, K/L or reaction/dash selection | Cast can disappear while its damage already happened |
| Charge warning | Boss passes width 58 to line telegraph, but uses hit radius 68 against player center throughout movement | Visible corridor understates danger width and endpoint extent |
| Barrage warning | Boss draws a radius-90 circle but releases a fan of projectiles | Anticipation shape does not describe the attack direction |
| Circle warning | Texture is decorative isometric oval on a square canvas; real distance test uses a circle plus player margin | Art silhouette and damage boundary can imply different safe positions |
| Popup acceptance | Enemy/boss use requested damage amount rather than actual HP reduction; nonpositive input not rejected at receiver | Potential zero/negative/rejected-hit feedback and overkill number ambiguity |

Hydrogen owns the remaining detailed audit and implementation. Findings above are from current baseline source; visible defect reproduction is tracked separately.

## Asset review

Luna read-only audit: existing character canvases/pivots and contact sheets inspected. No replacement or normalization justified from static sheets. Candidate painted impact frames: J=3, K=4, L=3 (zero-based). Existing assets remain in use. Motion warnings remain REVIEW_REQUIRED until playback evidence resolves them; static review alone does not establish absence of foot sliding.

## Runtime method and evidence limits

Use Godot 4.7.2 Compatibility with actual native window inputs. Passive observer [manual_capture.gd](manual_capture.gd) adds F12 viewport/state capture and F9 three-second viewport recording; it observes normal game state and does not inject gameplay, grant stats, kill enemies or switch scenes. Input and scene/state timestamps are saved in JSONL. Scene transitions must happen through actual portals. Pausing while inspecting evidence is allowed and must be visible in trace.

Baseline run [baseline_runtime/](baseline_runtime/) observed Scene 01 -> 02, HP 120/120, level 1 and loot 0 carried forward. Later death happened while idle during tooling delays before combat probes. No combat success/failure conclusion follows. Baseline evidence does not validate later code edits. No supplied Scene 05 screenshot is present in the latest request; repository and new runtime evidence are used.

## Acceptance matrix

| Test | Required evidence | Current result |
|---|---|---|
| Four directional Wukong movement | Actual moving viewport/clip, correct facing/flip/pivot and stable transitions | Pending final code |
| J impact timing and once-only damage | Frame/state trace and viewport show damage on impact, cooldown unchanged | Pending |
| K and L | Distinct complete casts, release timing, applied damage and existing targeting/bolt counts | Pending |
| Damage feedback | Real successful hits, visible high-layer numbers with rise/fade/crit distinction, rejected damage silent | Pending |
| Boss warning geometry | Actual slam/charge/fan anticipation consistent with hit query and coordinates, boundary check | Pending |
| Dodge | Successful move/dash out and no hit after leaving actual geometry | Pending |
| Enemy animation | Chase, attack/reaction/death in actual encounters | Pending |
| Boss animation | Walk, anticipation, both phases, hurt and death without stomping | Pending |
| Five scene handoffs | Portal 01->02->03->04->05->06 and correctly framed/spawned arrival | Pending final code |
| Persistence | HP/maxHP/XP/level/upgrades/stats/loot before/after each transition | Pending |
| Restart | End/restart clears intended run state and reloads current scene without stale callbacks | Pending |

## Validation

Awaiting Hydrogen implementation handoff and exact executed output. No new validation success is claimed here yet.

## Remaining work

Inspect Hydrogen diff, reconcile art impact frame choices, run final import/resource/asset checks, then perform visible gameplay and fix confirmed regressions. Capture final runtime evidence separately from baseline. Keep incomplete tests explicitly pending. No commit/push.
