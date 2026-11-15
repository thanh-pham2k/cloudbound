# Visual Bible — Đường Đến Thiên Giới (Cloudbound: Path to Heaven)

## 1. High-Level Art Direction

- **Genre & Tone:** Hand-painted 2D Chinese mythology action RPG inspired by *Journey to the West* (*Tây Du Ký*), vibrant, readable, and cohesive across all six realms.
- **Characters:** Cute **chibi** proportions (~1:2 to 1:2.5 head-to-body ratio), crisp dark-ink outlines, readable silhouettes at gameplay zoom.
  - **Hero (`player_hero`):** Red-gold Chinese chibi warrior with black hair & topknot, golden headband, red-brown martial arts outfit, golden waist sash, and wooden fighting staff.
  - **Enemies:**
    - `enemy_ranged`: **Green Cloud Slime** (jade-green slime with fluffy cloud wisps).
    - `enemy_melee`: **Small Horned Demon** (red-skinned chibi imp with dark horns and wooden club).
    - `enemy_tank`: **Stone Guardian** (heavy moss-topped carved stone golem with glowing cyan runes).
  - **Boss (`boss_thunder_warden`):** **Giant Cyan-Rune Stone Guardian** (~2.5x–3x hero scale, carved stone body, moss crown, glowing cyan runes, ground-slam telegraphs).
- **Camera & Projection:** Fixed **3/4 top-down** 2D gameplay camera (`Camera2D`, no 3D rendering) with `2.5D` depth illusion via front-facing platform thickness and Godot `Y-sorting`.
- **Rendering Style:** Warm painterly cel-shading, soft gradients, clean outer silhouettes, and high-contrast combat telegraphs.

## 2. Color Palette

| Role | Color Name | Hex Reference | Usage |
| --- | --- | --- | --- |
| Primary Environment | Soft Jade Green | `#6BBF9B` / `#4E9A7A` | Cloud-island grass, moss, tree foliage |
| Highlight / Stone | Warm Cream | `#F5EFE0` / `#E4D8BE` | Cloud rims, carved stone courtyard tiles, bridges, stairways |
| Sky & Atmosphere | Sky Blue | `#7CC6EE` / `#4E8EC4` | Sky backdrop, cyan boss runes, crystal glow |
| Accent / Threat | Muted Crimson Red | `#C95B5B` / `#8F3439` | Hero outfit/scarf, horned demon, slam/danger telegraphs |
| Celestial Accent | Warm Gold | `#E8BE54` / `#C4932B` | Hero headband/sash, heavenly gateway, reward chest, portal |
| Ink / Shadow | Deep Indigo-Slate | `#1E293B` | Ground contact shadows, clean character outlines |

## 3. Six-Scene Visual Progression

1. **Scene 01 — Mortal Realm (`scene_01_mortal_realm`):** Small Chinese village courtyard with wooden house, peach blossom tree, wooden fence, stone pathway, and gateway. Hero starting area.
2. **Scene 02 — Stairway to Clouds (`scene_02_stairway_clouds`):** Two floating islands connected by a walkable stone bridge; hero crossing toward a green cloud slime ahead.
3. **Scene 03 — Azure Cloud Outskirts (`scene_03_azure_outskirts`):** Grassy floating island with peach & green trees, mossy rocks, lanterns, and combat against green slimes and a horned demon.
4. **Scene 04 — Azure Cloud Center (`scene_04_azure_center`):** Circular/carved stone courtyard with ancient cyan-rune jade pillars, crystal pedestal reward, demon, and slimes.
5. **Scene 05 — Cloudstone Boss Arena (`scene_05_boss_arena`):** Large carved stone arena hosting the Giant Cyan-Rune Stone Guardian with clear ground-slam warning telegraphs and ample dodge space.
6. **Scene 06 — Gate of Heaven (`scene_06_gate_of_heaven`):** Golden celestial gateway, swirling 8-frame portal energy, reward chest, and peaceful cloud atmosphere.
