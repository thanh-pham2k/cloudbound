# Visual Bible — Đường Đến Thiên Giới (Cloudbound: Path to Heaven)

## 1. High-Level Art Direction

- **Genre & Tone:** Hand-painted 2D Chinese mythology fantasy inspired by *Journey to the West* (*Tây Du Ký*), approachable and vibrant rather than grimdark.
- **Characters:** Cute **chibi** proportions (roughly 1:2 to 1:2.5 head-to-body ratio), expressive silhouettes, readable headgear/weapons at gameplay zoom.
- **Camera & Projection:** Fixed **3/4 top-down** gameplay camera (`2D` sprites with `2.5D` depth illusion via front-facing vertical thickness on platforms/pillars and Godot `Y-sorting`).
- **Rendering Style:** Minimal cel/painterly shading, soft gradients, crisp outer silhouettes (dark warm-slate or indigo ink outline `1.5–2px` equivalent at `128x128` scale), and clean internal value separation so combat telegraphs remain legible at 60 FPS.

## 2. Color Palette

| Role | Color Name | Hex Reference | Usage |
| --- | --- | --- | --- |
| Primary Environment | Soft Jade Green | `#6BBF9B` / `#4E9A7A` | Cloud-island grass/moss, jade stone trim, healing/wind cues |
| Highlight / Stone | Warm Cream | `#F5EFE0` / `#E4D8BE` | Cloud tops, carved marble tiles, stairways, UI parchment |
| Sky & Atmosphere | Sky Blue | `#7CC6EE` / `#3B7CB8` | Sky backdrop, cloud shadows, player aura, portal energy |
| Accent / Threat | Muted Crimson Red | `#C95B5B` / `#8F3439` | Enemy cloth/armor, demon accents, danger telegraphs |
| Celestial Accent | Warm Gold | `#E8BE54` / `#C4932B` | Hero trim, temple roofs, boss crown, level-up & portal rings |
| Ink / Shadow | Deep Indigo-Slate | `#1E293B` | Ground contact shadows, clean character outlines |

## 3. Environment & Modularity

- **Simple Modular Environment:** Floating cloud islands are composed from reusable ground tiles, beveled platform edges (showing 2.5D underside thickness), cloud-wisp borders, stone bridges, and sparse props (jade pillars, lanterns, peach-blossom/pine bonsai, incense braziers).
- **Gameplay Readability First:** Floor surfaces stay low-contrast (soft jade/cream/slate) so bright projectiles, red/gold attack telegraphs, and chibi characters pop immediately.
- **Consistent Lighting:** Top-left soft key light (~35°–45°), subtle warm bounce from cloud rims, soft elliptical contact shadow directly beneath every character's feet.

## 4. Reference Usage Rule

- The **six-panel reference image** provided for the project defines mood, proportions, palette, and motif language only.
- **Do NOT treat the reference image as a sprite atlas or crop/slice it directly into game assets.** All production assets must be authored cleanly per `ASSET_SPEC.md` and `BATCH_PLAN.md`.
