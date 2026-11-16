# Gate A partial acceptance

**Three Wukong animations and 16 frames passed the checks for Scene 03 integration. Gate A remains open for the rest of the pack.** The original archive and original artwork were preserved. [Manifest and per-animation status](manifest.json)

| Animation | Source sheet ID | Frames extracted and integrated | FPS | Status |
|---|---:|---:|---:|---|
| `idle_down` | 10 | 4 | 6 | READY |
| `idle_right` | 42 | 4 | 6 | READY |
| `walk_down` | 26 | 8 | 10 | READY |
| Dedicated Skill K and L casts | — | 0 | — | MISSING |

The source alpha defined crop separators. Distant low-alpha residue was removed while keeping antialiasing near the silhouettes. Each strip used one uniform scale factor. Frames share a 208 × 176 transparent canvas and a ground pivot at (104, 151). Centering follows the body and feet rather than the weapon, and the walk retains vertical stride movement. Frame PNGs, atlases, metadata, and the SpriteFrames resource are under `assets/animations/wukong/`.

GameForge atlas structure and consistency passed for all three. Its motion metric flags 14.2 pixels of horizontal spread across the walking feet. The paired composites show alternating foot contacts within the shared body-centered origin and intact silhouettes. The last walk frame approaches the source edge, and the visible staff tip remained intact in the normalized output. The Godot runtime check verified the resource, frame dimensions and counts, looping, and idle animation advancing in Scene 03. Walking continuity during player movement remains for manual review. [Frame contact sheet](wukong_frame_contact.png) · [Frame QA data](wukong_frame_qa.json)

## Checkerboard trials

All 34 baked-checkerboard animation sheets went through a separate estimated-alpha pass under `.gameforge/work/wukong_gate_a/reconstruction/`. The pass estimated local background tone and nearest solid foreground colors, then reconstructed the alpha transition. Light and dark review exposed holes in red rune fills, reduced cyan bloom, bright orb rims, changes to the spirit's fading silhouette, and hard shadow edges on character poses. These trials are rejected from runtime use and remain **NEEDS_REPAIR**. No reconstructed frames were promoted. [Reconstruction contact sheet](reconstruction_trials.jpg)

## Scene 03

Only the Scene 03 player uses these SpriteFrames. Horizontal idle mirrors the approved right-facing strip for left. Upward idle uses front idle, and movement without its own validated direction uses front locomotion. Unsupported attack, cast, hurt, and death animation states hold the current pose. Dash uses the available locomotion loop. The existing input, combat timing, effects, and progression are separate from the sprite.

- [Scene 03 opening viewport](scene_03_idle.png)
- [Scene 03 later idle frame](scene_03_idle_later.png)

Both captures are actual 1280 × 720 Godot 4.7.2 viewports. The capture paused gameplay and allowed only the sprite to advance for the second image. Headless import, repository asset validation, and `git diff --check` passed. No simulated gameplay was performed.

Changed files include the Scene 03 player resource binding, the player animation selection, the Wukong profile, the extracted frames and SpriteFrames, and this QA directory.
