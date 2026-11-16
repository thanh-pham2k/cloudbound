# Cloudbound — Animation Asset & Integration Batch Prompts

**TL;DR:** Bộ **12 prompt độc lập**: 1 Master, 10 batch tạo và tích hợp asset, 1 Final QA. Mỗi prompt nằm trong code block riêng để copy trực tiếp vào agent. **Không tạo ZIP. Agent phải tạo asset thật, tích hợp vào Godot và kiểm thử runtime.**

**Thứ tự thực hiện:** `00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11`.

Mỗi batch phải hoàn thành **Generate → Validate → Integrate → Runtime Test** trước khi chuyển sang batch tiếp theo.

---

## Prompt 00 — Master: Quy tắc chung

```text
ROLE: Senior Godot 4 Gameplay Engineer, 2D Character Animator, Technical Artist and QA Lead.

PROJECT: Cloudbound — Path to Heaven
REPOSITORY: https://github.com/thanh-pham2k/cloudbound

MISSION:
Autonomously GENERATE, VALIDATE, INTEGRATE and TEST real animation assets directly in the existing Godot 4 project.

THIS IS AN ACTION TASK, NOT A PLANNING TASK.

1. INSPECT THE REPOSITORY
Read project.godot, existing scenes, scripts, SpriteFrames, original artwork, and:
- docs/assets/animation_pack_qa/GATE_A.md
- docs/assets/animation_pack_qa/manifest.json
- assets/processed/
- assets/animations/
- scripts/player/player_controller.gd

Inspect relevant enemy, boss and combat scripts for each batch.

2. GENERATE REAL ASSETS
Use an actual image-generation tool.
Generate real animation poses, not descriptions or placeholders.
Use the original PNGs and approved Scene 03 screenshot as visual references.

Preserve:
- Premium hand-painted Chinese fantasy
- 3/4 top-down isometric perspective
- Warm upper-left lighting
- Original character identity, costume, proportions and weapons
- Consistent character scale and feet anchors

Each sheet must contain exactly one action and one facing direction.

3. TRANSPARENCY
Output genuine transparent RGBA PNGs.
Never generate a checkerboard background.
Never use white, gray or black backgrounds as fake transparency.
Preserve antialiased edges without halos.

4. ANIMATION QUALITY
Use equally sized frame cells.
Create distinct sequential poses.
Maintain stable pivots and consistent proportions.
Avoid clipping, duplicated limbs, duplicated weapons and perspective drift.
Make looping animations seamless.

5. VALIDATE
Check alpha, frame count, frame dimensions, alignment, animation continuity and visual consistency.
Inspect frames against both dark and light backgrounds.
Regenerate invalid assets when feasible.
Only integrate assets that pass QA.

6. INTEGRATE INTO GODOT
Extract frames into organized asset directories.
Create or update SpriteFrames resources.
Bind animations to the correct AnimatedSprite2D nodes.
Update animation states, directions, FPS, pivots and looping behavior.
Preserve existing gameplay logic, cooldowns, hitboxes, damage and enemy AI.

7. RUNTIME TEST
Run Godot import and actual gameplay tests.
Capture real runtime screenshots and animation previews.
Fix missing resources, incorrect scale, jitter, clipping and animation-state conflicts.

8. REPORT
Provide:
- Generated asset paths
- Number of atlases and frames
- READY / NEEDS_REPAIR / FAILED status
- Modified files
- Runtime test results
- Screenshots or preview paths
- Remaining issues

STRICT RULES:
- Do not create ZIP archives.
- Do not stop after generating images.
- Do not create placeholder assets.
- Do not overwrite existing READY animations unnecessarily.
- Do not fabricate test results.
- Do not commit or push automatically.
- Keep changes scoped to the active batch.

If image generation is unavailable, report the blocker rather than pretending assets were created.

DEFINITION OF DONE:
Real generated assets are validated, integrated and visibly working inside the actual Godot game.
```

---

## Prompt 01 — Wukong Walk Up / Right

```text
Execute the Cloudbound MASTER instructions.

BATCH 01: WUKONG WALK UP AND WALK RIGHT

GOAL:
Generate missing Wukong walking directions and integrate them into Scene 03.

FIRST INSPECT:
- assets/animations/wukong/
- assets/processed/characters/staff_wielding_monkey_hero.png
- scripts/player/player_controller.gd
- docs/assets/animation_pack_qa/GATE_A.md
- Existing READY walk_down animation
- Approved Scene 03 reference

GENERATE:
1. wukong_walk_up.png — 8 frames
2. wukong_walk_right.png — 8 frames

TECHNICAL SPEC:
- 208x176 pixels per frame
- Feet pivot: (104,151)
- 8 columns x 1 row per atlas
- Atlas dimensions: 1664x176
- Genuine RGBA transparency
- Consistent character scale

ANIMATION:
- Natural alternating footsteps
- Stable body and feet alignment
- Smooth looping
- Walk Up visibly faces away from the camera
- Walk Right visibly faces right
- Preserve Wukong's red scarf, red-gold armor and golden staff
- No clipped weapons or duplicated poses

INTEGRATION:
1. Generate both animation sheets.
2. Validate alpha and all 16 frames.
3. Extract individual frames.
4. Update Wukong SpriteFrames.
5. Update directional animation selection.
6. Preserve existing READY idle_down, idle_right and walk_down.
7. Test WASD movement in Scene 03.
8. Verify correct facing, looping and feet alignment.
9. Capture runtime screenshots and animation previews.
10. Fix confirmed defects.

DELIVER:
- Two generated atlases
- Sixteen extracted frames
- Updated SpriteFrames
- Working Scene 03 movement
- QA report and runtime evidence

Do not create ZIP.
Do not commit or push.

DONE WHEN:
Walk Up and Walk Right are genuinely animated and working in Scene 03.
```

---

## Prompt 02 — Wukong Basic Attack

```text
Execute the Cloudbound MASTER instructions.

BATCH 02: WUKONG BASIC STAFF ATTACK

GOAL:
Generate and integrate directional staff attack animations.

FIRST INSPECT:
- Original Wukong character artwork
- Existing Wukong SpriteFrames
- scripts/player/player_controller.gd
- Existing attack damage and cooldown logic
- CombatSystem and melee slash implementation

GENERATE:
1. attack_down — 6 frames
2. attack_up — 6 frames
3. attack_right — 6 frames

TOTAL: 18 frames.

ANIMATION:
- Frame sequence: anticipation, wind-up, swing, impact, follow-through, recovery
- Clear golden staff movement
- Preserve character identity and weapon proportions
- Maintain stable feet pivot
- Use a larger uniform canvas if necessary to avoid weapon clipping
- Do not bake separate slash VFX into character frames
- Genuine transparent RGBA

INTEGRATION:
1. Generate all three animation sheets.
2. Validate and extract frames.
3. Update Wukong SpriteFrames.
4. Integrate attack_down, attack_up and attack_right.
5. Bind animations to the existing J attack action.
6. Preserve current attack damage, range and cooldown.
7. Prevent animation callbacks from applying duplicate damage.
8. Prevent idle/walk states from interrupting attacks incorrectly.
9. Test attacks in Scene 03 against real enemies.
10. Capture runtime screenshots and previews.

DELIVER:
- Three animation atlases
- Eighteen extracted frames
- Updated player animation logic
- Working J attack
- QA and runtime test report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
Wukong performs readable directional staff attacks in actual gameplay without combat regressions.
```

---

## Prompt 03 — Wukong Skill K / L

```text
Execute the Cloudbound MASTER instructions.

BATCH 03: WUKONG SKILL K AND SKILL L

GOAL:
Generate dedicated skill-casting animations and integrate them into existing combat.

FIRST INSPECT:
- scripts/player/player_controller.gd
- data/skills.json
- Existing CombatSystem
- Existing Wukong SpriteFrames
- Current skill_1 and skill_2 input mappings

GENERATE:
1. skill_1_down — 6 frames
2. skill_2_down — 6 frames

TOTAL: 12 frames.

SKILL K:
- Golden circular shockwave
- Staff preparation
- Energy charging
- Grounded casting pose
- Release
- Recovery

SKILL L:
- Multi-target magical strike
- Staff raised
- Magical concentration
- Casting release
- Follow-through
- Recovery

REQUIREMENTS:
- Preserve Wukong identity and proportions
- Genuine RGBA transparency
- Keep independent combat VFX separate from character animations
- Stable feet pivot
- Do not reuse generic attack poses as fake skill animations

INTEGRATION:
1. Generate both cast animations.
2. Validate and extract all frames.
3. Update Wukong SpriteFrames.
4. Bind K to skill_1 animation.
5. Bind L to skill_2 animation.
6. Preserve existing damage, radius, targeting and cooldowns.
7. Ensure one cast triggers one gameplay skill execution.
8. Prevent animation-state conflicts.
9. Test both skills against Scene 03 enemies.
10. Capture actual runtime evidence.

DELIVER:
- Two cast animation atlases
- Twelve extracted frames
- Updated SpriteFrames and animation state logic
- Working K and L animations
- QA and runtime test report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
K and L trigger visually distinct casting animations synchronized with existing combat.
```

---

## Prompt 04 — Wukong Dash / Hurt / Death

```text
Execute the Cloudbound MASTER instructions.

BATCH 04: WUKONG DASH, HURT AND DEATH

GOAL:
Generate and integrate movement and reaction animations.

FIRST INSPECT:
- Wukong original artwork
- Existing player animation states
- Dash implementation
- Damage and invulnerability logic
- Death and restart flow

GENERATE:
1. dash_right — 6 frames
2. hurt_down — 4 frames
3. death_down — 8 frames

TOTAL: 18 frames.

ANIMATION:
DASH:
- Fast forward movement
- Low dynamic pose
- Red scarf trailing behind
- Clear start and recovery

HURT:
- Visible impact reaction
- Short recoil
- Recovery

DEATH:
- Progressive loss of balance
- Controlled collapse
- Stable final pose
- Non-looping

REQUIREMENTS:
- Consistent Wukong identity
- Genuine transparent RGBA
- No clipped limbs or staff
- Stable scale and feet anchor
- No unrelated baked VFX

INTEGRATION:
1. Generate and validate all animations.
2. Extract frames.
3. Update SpriteFrames.
4. Bind Dash to Space.
5. Bind Hurt to damage events.
6. Bind Death to the existing death state.
7. Preserve dash speed, duration and invulnerability.
8. Prevent death animation from being interrupted.
9. Verify death does not loop.
10. Test dash, damage, death and restart in Scene 03.

DELIVER:
- Three atlases
- Eighteen frames
- Updated player animation states
- Runtime evidence
- QA report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
Dash, Hurt and Death work correctly without breaking player movement or combat.
```

---

## Prompt 05 — Green Cloud Spirit

```text
Execute the Cloudbound MASTER instructions.

BATCH 05: GREEN CLOUD SPIRIT

GOAL:
Generate and integrate complete Green Cloud Spirit animations.

FIRST INSPECT:
- Existing Green Cloud Spirit artwork
- EnemyBase implementation
- Enemy configuration and behavior
- Scene encounter definitions
- Existing enemy animation resources

GENERATE:
1. idle — 4 frames
2. move — 6 frames
3. attack — 6 frames
4. hurt — 4 frames
5. death — 6 frames

TOTAL: 26 frames.

ANIMATION:
- Idle: gentle floating
- Move: smooth cloud gliding
- Attack: anticipation, magical release, recovery
- Hurt: visible reaction
- Death: progressive cloud dissipation

REQUIREMENTS:
- Preserve original green spirit identity
- Maintain translucent silhouette
- Genuine transparent RGBA
- No damaged alpha inside the spirit
- Consistent perspective and scale
- Stable floating anchor

INTEGRATION:
1. Generate all five animation sheets.
2. Validate transparency and frame continuity.
3. Extract frames and create SpriteFrames.
4. Bind animations to the actual corresponding enemy type.
5. Preserve existing enemy AI, damage and EXP.
6. Preserve death signals and reward behavior.
7. Test the spirit in its actual scene.
8. Verify animation states during movement, attack, damage and death.
9. Capture runtime screenshots and previews.
10. Fix integration defects.

DELIVER:
- Five atlases
- Twenty-six frames
- Integrated enemy animations
- QA report
- Runtime test evidence

Do not create ZIP.
Do not commit or push.

DONE WHEN:
The Green Cloud Spirit is fully animated and functioning in gameplay.
```

---

## Prompt 06 — Blue-robed Ranged Demon

```text
Execute the Cloudbound MASTER instructions.

BATCH 06: BLUE-ROBED RANGED DEMON

GOAL:
Generate and integrate ranged enemy animations.

FIRST INSPECT:
- Original Blue-robed Ranged Demon artwork
- EnemyBase implementation
- Ranged enemy AI
- Projectile spawning and cooldown logic
- Scene 02, 03 and 04 encounter definitions

GENERATE:
1. idle — 4 frames
2. move — 6 frames
3. cast — 6 frames
4. hurt — 4 frames
5. death — 6 frames

TOTAL: 26 frames.

ANIMATION:
- Idle: subtle breathing and robe movement
- Move: controlled movement
- Cast: cyan magic charge and release
- Hurt: short recoil
- Death: coherent collapse

REQUIREMENTS:
- Preserve original blue robe and character identity
- Consistent staff or casting equipment
- Genuine RGBA transparency
- Stable feet pivot
- No baked projectiles inside character frames

INTEGRATION:
1. Generate all animation sheets.
2. Validate and extract frames.
3. Create/update ranged enemy SpriteFrames.
4. Integrate with enemy movement and attack states.
5. Synchronize casting visuals with existing projectile events.
6. Preserve damage, targeting and cooldowns.
7. Prevent duplicate projectile spawning.
8. Test ranged enemies in their actual scenes.
9. Capture runtime evidence.
10. Fix confirmed defects.

DELIVER:
- Five atlases
- Twenty-six frames
- Integrated ranged enemy animation
- QA and runtime test report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
Ranged demons animate correctly while preserving existing combat behavior.
```

---

## Prompt 07 — Pig-like Melee Demon

```text
Execute the Cloudbound MASTER instructions.

BATCH 07: PIG-LIKE MELEE DEMON

GOAL:
Generate and integrate melee enemy animations.

FIRST INSPECT:
- Original Pig-like Melee Demon artwork
- EnemyBase melee implementation
- Chase and melee attack behavior
- Scene 03 and Scene 04 encounters

GENERATE:
1. idle — 4 frames
2. walk — 8 frames
3. axe_attack — 6 frames
4. hurt — 4 frames
5. death — 8 frames

TOTAL: 30 frames.

ANIMATION:
- Idle: subtle breathing
- Walk: heavy alternating footsteps
- Attack: axe wind-up, strike and recovery
- Hurt: impact reaction
- Death: progressive collapse

REQUIREMENTS:
- Preserve original pig-like identity and outfit
- Preserve axe design and proportions
- No duplicated weapons or limbs
- Genuine transparent RGBA
- Consistent ground contact and perspective

INTEGRATION:
1. Generate five animation sheets.
2. Validate and extract all frames.
3. Create/update SpriteFrames.
4. Bind animations to the actual melee enemy controller.
5. Preserve chase AI, melee range, damage and cooldown.
6. Prevent duplicate damage events.
7. Preserve EXP and death signals.
8. Test against Wukong in Scene 03 and Scene 04.
9. Capture runtime screenshots and previews.
10. Fix confirmed defects.

DELIVER:
- Five atlases
- Thirty frames
- Working melee enemy animations
- QA report
- Runtime evidence

Do not create ZIP.
Do not commit or push.

DONE WHEN:
The melee demon has readable animated combat without changing gameplay balance.
```

---

## Prompt 08 — Stone Golem

```text
Execute the Cloudbound MASTER instructions.

BATCH 08: STONE GOLEM

GOAL:
Generate and integrate Stone Golem animations.

FIRST INSPECT:
- Original Stone Golem artwork
- Tank/golem enemy implementation
- Existing enemy stats and collision
- Scene 04 encounter configuration

GENERATE:
1. idle — 4 frames
2. heavy_walk — 8 frames
3. stone_punch — 6 frames
4. hurt — 4 frames
5. death — 8 frames

TOTAL: 30 frames.

ANIMATION:
- Idle: subtle stone-body movement
- Walk: slow, heavy weight shifts
- Punch: anticipation, strike, recovery
- Hurt: readable impact
- Death: coherent collapse

REQUIREMENTS:
- Preserve original stone-body silhouette
- Consistent proportions and colors
- Genuine RGBA transparency
- Stable ground pivot
- No disconnected limbs or duplicated fists

INTEGRATION:
1. Generate all five animation sheets.
2. Validate alpha, alignment and motion.
3. Extract frames and create SpriteFrames.
4. Integrate into the tank/golem enemy.
5. Preserve HP, movement speed, damage and hitboxes.
6. Synchronize punch animation with existing attacks.
7. Preserve death rewards.
8. Test the complete encounter in Scene 04.
9. Verify Y-sort and ground alignment.
10. Capture runtime evidence and fix defects.

DELIVER:
- Five atlases
- Thirty frames
- Integrated Stone Golem animations
- QA report
- Runtime test results

Do not create ZIP.
Do not commit or push.

DONE WHEN:
The Stone Golem animates correctly and remains fully functional in Scene 04.
```

---

## Prompt 09 — Guardian Boss

```text
Execute the Cloudbound MASTER instructions.

BATCH 09: CYAN-RUNE STONE GUARDIAN BOSS

GOAL:
Generate and integrate complete Guardian Boss animations.

FIRST INSPECT:
- Original Guardian Boss artwork
- BossController implementation
- Boss phases and attack patterns
- Existing AoE telegraphs
- Scene 05 encounter and portal unlock logic

GENERATE:
1. idle — 6 frames
2. heavy_walk — 8 frames
3. ground_slam — 8 frames
4. cyan_rune_special — 8 frames
5. hurt — 4 frames
6. death — 8 frames

TOTAL: 42 frames.

ANIMATION:
- Idle: breathing and cyan rune energy
- Walk: heavy deliberate movement
- Ground Slam: anticipation, impact, recovery
- Rune Special: magical charge, release, recovery
- Hurt: readable reaction
- Death: progressive collapse

REQUIREMENTS:
- Preserve original boss identity and scale
- Preserve cyan rune markings
- Genuine RGBA transparency
- Consistent perspective and pivots
- No disconnected stone body parts
- Keep AoE telegraphs separate from boss frames

INTEGRATION:
1. Generate six animation sheets.
2. Validate all forty-two frames.
3. Extract frames and create boss SpriteFrames.
4. Bind animations to actual boss states.
5. Preserve existing boss phases, HP, damage and cooldowns.
6. Synchronize attack visuals with gameplay timing.
7. Preserve AoE warning readability.
8. Prevent duplicate damage and death signals.
9. Test the complete boss fight in Scene 05.
10. Verify boss death and portal unlock.
11. Capture runtime screenshots and animation previews.

DELIVER:
- Six atlases
- Forty-two frames
- Integrated boss animations
- Complete boss runtime test evidence
- QA report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
The Guardian Boss is fully animated and the Scene 05 encounter works correctly.
```

---

## Prompt 10 — Combat VFX, Portal & Pickups

```text
Execute the Cloudbound MASTER instructions.

BATCH 10: COMBAT VFX, PORTAL AND PICKUPS

GOAL:
Generate and integrate animated combat effects and collectible drops.

FIRST INSPECT:
- Existing CombatSystem
- CloudPortal implementation
- FloorManager enemy death signals
- PlayerController heal() implementation
- HUD and progression systems
- Scene transition logic

GENERATE:
1. golden_staff_slash — 6 frames
2. cyan_projectile — 6 frames
3. portal_swirl — 8 frames
4. cyan_impact — 6 frames
5. red_aoe_warning — 6 frames
6. health_orb_idle — 6 frames
7. loot_orb_idle — 6 frames

TOTAL: 44 frames.

VISUAL REQUIREMENTS:
- Separate sheet for each effect
- Genuine transparent RGBA
- Soft glows without baked checkerboard
- No opaque rectangular backgrounds
- Seamless portal and pickup loops
- Consistent Cloudbound visual style

INTEGRATION:

COMBAT VFX:
- Integrate golden staff slash into melee attacks.
- Integrate cyan projectile into ranged attacks.
- Integrate cyan impact into spell hit feedback.
- Integrate red AoE warning into boss telegraphs.
- Preserve existing damage timing and hitboxes.

PORTAL:
- Integrate animated portal swirl.
- Preserve objective-based portal unlocking.
- Preserve portal collision and scene transitions.

HEALTH ORB:
- Spawn at valid enemy death positions.
- Use configurable drop probability.
- Collect through Area2D/proximity.
- Call player.heal(amount).
- Never exceed max_hp.
- Show pickup feedback.

LOOT ORB:
- Spawn at valid enemy death positions.
- Use configurable drop probability.
- Collect through Area2D/proximity.
- Increment persistent loot currency.
- Update the HUD immediately.

RELIABILITY:
- Prevent duplicate drops from repeated death signals.
- Preserve existing EXP and life_on_kill behavior.
- Keep drops inside walkable terrain.
- Keep uncollected drops scene-local unless requirements say otherwise.
- Persist collected loot across scene transitions.

TEST:
1. Generate and validate all seven effect sheets.
2. Extract frames and integrate effects.
3. Test staff slash and cyan projectile.
4. Test boss AoE warning.
5. Test portal animation.
6. Test health pickup with damaged and full HP.
7. Test loot pickup and HUD counter.
8. Test duplicate death-signal protection.
9. Test scene transitions and loot persistence.
10. Capture actual runtime evidence.

DELIVER:
- Seven atlases
- Forty-four frames
- Integrated combat VFX and portal
- Functional Health Orb and Loot Orb
- Updated HUD and persistence where required
- QA and runtime test report

Do not create ZIP.
Do not commit or push.

DONE WHEN:
All effects and pickups work correctly in actual gameplay.
```

---

## Prompt 11 — Final QA: Toàn bộ 6 Scene

```text
ROLE: Senior Godot 4 Gameplay Engineer and QA Lead.

PROJECT: Cloudbound — Path to Heaven
REPOSITORY: https://github.com/thanh-pham2k/cloudbound

TASK:
Perform complete asset integration and gameplay regression testing across all six scenes.

THIS IS AN ACTION TASK.

SCENES:
01 — Mortal Realm
02 — Cloud Bridge
03 — Cloud Outskirts
04 — Celestial Courtyard
05 — Guardian Arena
06 — Gate of Heaven

PHASE 1 — ASSET AUDIT
1. Inspect every generated animation atlas.
2. Verify all extracted frames.
3. Validate genuine RGBA transparency.
4. Verify correct frame counts, FPS and pivots.
5. Check character identity and scale consistency.
6. Detect missing animations and invalid references.
7. Verify SpriteFrames imports.

PHASE 2 — WUKONG
Test:
- Idle
- Walk Up / Down / Right / Left
- J basic attack
- K skill 1
- L skill 2
- Space dash
- Hurt
- Death
- Restart

Verify animation priorities and transitions.

PHASE 3 — ENEMIES
Test:
- Green Cloud Spirit
- Blue-robed Ranged Demon
- Pig-like Melee Demon
- Stone Golem

Verify movement, attack, hurt, death, AI and rewards.

PHASE 4 — BOSS
Test:
- Idle and movement
- Ground slam
- Cyan rune special
- AoE telegraph
- Hurt and death
- Portal unlock after victory

PHASE 5 — VFX AND PICKUPS
Test:
- Staff slash
- Cyan projectile
- Cyan impact
- Portal swirl
- AoE warning
- Health Orb
- Loot Orb

Verify:
- HP never exceeds max_hp.
- Loot counter updates correctly.
- Enemy death rewards occur once.
- Drops appear in valid locations.

PHASE 6 — CONTINUOUS GAMEPLAY
Play through Scene 01 to Scene 06.

Verify persistence of:
- Current HP
- Max HP
- EXP
- Level
- Selected upgrades
- Combat stats
- Loot currency

Check portal objectives, transitions, spawn positions and restart behavior.

PHASE 7 — RUNTIME VALIDATION
1. Run Godot import validation.
2. Run actual gameplay tests.
3. Capture screenshots for all six scenes.
4. Capture animation previews where possible.
5. Check logs and runtime errors.
6. Fix confirmed integration defects.
7. Repeat failed tests.

DELIVER:
- Final animation inventory
- READY / NEEDS_REPAIR / FAILED status
- Modified-file summary
- Runtime screenshots
- Test results per scene
- Remaining blockers
- Explicit PASS/FAIL for each subsystem

STRICT RULES:
- Do not create ZIP archives.
- Do not fabricate test results.
- Do not replace gameplay with screenshots.
- Do not silently change combat balance.
- Do not commit or push automatically.

SUCCESS CRITERIA:
All six scenes are playable with validated animated characters, responsive combat, functional pickups and persistent progression.
```
