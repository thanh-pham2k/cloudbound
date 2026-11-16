# Six-scene animation and gameplay progress

- [x] Audit the existing Gate A baseline. Scene 03 uses approved Wukong idle-down, idle-right, and walk-down resources. Gate A rejected 34 checkerboard reconstructions.
- [ ] Generate and validate Wukong walk-up and walk-right.
- [ ] Generate and integrate Wukong attacks, casts, dash, hurt, and death.
- [ ] Generate and integrate the four enemy animation sets and the guardian set.
- [ ] Generate and integrate combat VFX and both pickups.
- [ ] Verify continuity across all six scenes. Scene handoff now carries HP and EXP, and reapplies selected upgrades to recover maximum HP and combat stats. Restart clears the run state and reloads the current scene.
- [ ] Capture current runtime views for all six scenes and record manual gameplay results.
- [ ] Complete final QA and changed-file summary.

## Validation log

- Baseline `python3 scripts/tools/validate_assets.py` returned `[PASS] Repository asset validation passed.`
- Godot 4.7.2 is installed at `/Applications/Godot.app/Contents/MacOS/Godot`.
- Repository testing instructions reserve gameplay playtesting for the user. Automated verification is limited to asset and resource checks.

### Wukong walk-up source QA

The first generated 1774 × 887 RGBA sheet is staged at
`.gameforge/work/cloudbound-animation/wukong_walk_up_source.png`.
Its first cell has low-alpha pixels extending to the cell edges, while the
alpha ≥ 128 silhouette remains within the cell. The raw sheet remains
NEEDS_REPAIR pending alpha cleanup and visual review on light and dark ground.

The cleaned walk-up candidate supersedes the raw sheet for integration.
All eight poses were reviewed against light and dark backgrounds. Distant
residue removed by cleanup had alpha values of 8 or less. GameForge normalized
the poses to 208 × 176 at pivot (104, 151) and packed the atlas under
`assets/generated/wukong/`. The Scene 03 SpriteFrames now includes
`walk_up`, and the existing directional selector resolves it when facing up.

Godot 4.7.2 loaded the integrated resource and verified all eight atlas
regions, looping, and 10 FPS. Repository asset validation and
`git diff --check` passed. Motion during gameplay remains for manual review.

### Shared Wukong resource

Scenes 01, 02, 04, 05, and 06 now use the same Wukong SpriteFrames as
Scene 03. A Godot 4.7.2 resource check loaded and instantiated all six
PackedScenes outside the running tree and verified each player binding
contains the eight walk-up frames. Headless editor import completed with
the nested GameForge example-project warning.

The eight-pose right-facing walk source was generated from the approved
right-facing idle reference and staged under
`.gameforge/work/cloudbound-animation/wukong_walk_right_source.png`.
Alpha cleanup, frame extraction, and motion review are pending.

The right-facing walk is integrated in the shared Wukong SpriteFrames.
Godot verified eight 208 × 176 regions at 10 FPS. Left-facing movement
mirrors the right-facing walk. Motion in gameplay awaits manual review.

### Wukong combat animation binding

The player controller now records the direction at the start of a basic
attack and selects distinct painted animation names for J, K, and L.
Damage still uses the existing attack and skill execution paths. All
six scene resources loaded after the controller change.

The first down-facing staff attack sheet contained a brown gradient in the
transparent pixels. The gradient disappeared when composited using the
actual alpha channel. All six poses were extracted, normalized, and packed.
The shared SpriteFrames includes `attack_down`. Godot verified its six
208 × 176 atlas regions and non-looping 24 FPS configuration. A pixel check
verified distinct RGBA cells with transparent pixels for both generated
walks and the down-facing attack. Manual playback review is pending.

Scene exits now fade to black over 0.22 seconds before saving the handoff,
and destination scenes fade in over 0.22 seconds. All six PackedScenes
loaded after the change. Transition timing still needs manual review.

All three directional basic attacks are bound in the shared Wukong
SpriteFrames. Godot verified six 208 × 176 atlas regions per direction,
non-looping at 24 FPS. The painted selector mirrors the right-facing
attack for leftward strikes. Repository asset validation passed.
Manual combat playback and foot placement review remain open.

### Loot currency

GameData now retains collected loot across scene handoffs and emits
`loot_changed` for immediate HUD updates. New runs and current-scene
restarts clear the total. All six scene resources still load. Pickup
spawning, collection, and animation remain pending.

### Wukong skill casts

Both dedicated casts are bound to the shared player resource as
`skill_1_down` and `skill_2_down`. Godot verified six 208 × 176 regions
per cast, non-looping at 18 FPS. The existing skill execution still owns
damage and effects. Manual playback and combat timing review are pending.

### Wukong dash and reactions

Requested dedicated dash, hurt, and death sheets. The player can select the
painted dash resource during the dash window and allows its own death sprite
to advance while the game-over overlay pauses the scene. Gameplay timers
still control movement and invulnerability.

Enemy deaths now roll configurable health and loot drops (22% and 35%
by default, healing 18 HP or awarding one loot). Death connections
are one-shot. Drops are clamped to the arena and remain scene-local.
Health orbs are left for later at full HP. Pickup spawning requires
the corresponding SpriteFrames, which are pending generation QA and import.
All six PackedScenes loaded with the pickup scripts.

### Cloud spirit and caster

Cloud spirit idle, movement, and death atlases pass structural checks.
The death animation shrinks from a 115 px silhouette to a 34 px puff.
The default fixed-height tolerance flagged that intended change, so the
death batch uses a 65% height-variation limit. Motion remains flagged
for review. Generation of the five blue-robed caster sheets has started.

Cloud spirit hurt extraction completed. Its combined resource is now
available at `assets/generated/enemies/spirit/spirit_sprite_frames.tres`.
Godot loaded all 26 frames and checked looping only for idle and movement.
The generated set remains flagged for motion review in the toolkit.

### Full pack resource audit

Godot 4.7.2 loaded 13 SpriteFrames resources and verified all 43 requested
animation names, frame counts, dimensions, and loop settings. The repository
asset validator now also checks RGBA transparency, distinct cells, and atlas
alignment for the generated pack.

Run the asset-only audit with:
```sh
godot --headless --editor --path . --import
godot --headless --path . --script scripts/tools/verify_animation_pack.gd
python3 scripts/tools/validate_assets.py
```

### Runtime viewport evidence

Captured and visually reviewed the six opening viewports at 1280 × 720
using Godot 4.7.2 Compatibility rendering on macOS. Each scene was loaded
directly and paused for the capture. These images verify opening composition
and actor, HUD, and portal rendering where those elements are present.
Combat, pickup collection, and scene handoffs still need manual gameplay
verification.

1. [Mortal Realm](runtime/scene_01_mortal_realm.png)
2. [Cloud Bridge](runtime/scene_02_stairway_clouds.png)
3. [Cloud Outskirts](runtime/scene_03_azure_outskirts.png)
4. [Celestial Courtyard](runtime/scene_04_azure_center.png)
5. [Guardian Arena](runtime/scene_05_boss_arena.png)
6. [Gate of Heaven](runtime/scene_06_gate_of_heaven.png)

### Frame sequence review

- Boar death: the lowest occupied pixels move from boots to hands and axe
  as the boar falls. The contact sheet shows eight distinct poses and a
  stable prone finish. The 70.3 px toolkit warning uses those changing
  lowest pixels. In-game placement still needs review.
- Wukong right-facing attack: the staff is intact in all six poses, but
  bounding-box centering shifts the boots left in the extension pose.
  Use a hand-positioned foot anchor and wider attack canvas if necessary
  to retain the entire staff while aligning the body.

[Boar death preview](previews/boar_death_down/preview.gif) ·
[Wukong right attack preview](previews/wukong_attack_right/preview.gif)

The right-facing attack was repacked on a 256 × 176 canvas with
hand-positioned horizontal foot anchors. Its vertical pivot and playback
settings are unchanged. The contact sheet and GIF were regenerated.
The 43-animation resource audit and repository atlas validation passed
with the new dimensions.
