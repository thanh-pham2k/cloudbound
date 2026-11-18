# Basic segmentation scene — current default

Purpose: a minimal semantic planning map for Cloudbound. This replaces the complexity defaults of the v2/v3 illustrated concept prompts. It does not replace the existing runtime scene or palette registry.

The map uses a flat overhead planning view. Buildings and trees are ground footprints, not full sprite silhouettes. Image-generator outputs remain proposals; normalize exact RGB colors and validate geometry before using as production masks.

## Prompt

```text
Create ONE extremely simple flat 2D semantic planning map for a game.
This is a basic segmentation layout, not a game screenshot, illustration, isometric render, sprite sheet, or multi-panel concept.

Canvas: 1024 × 1024 pixels. Opaque PNG. Flat overhead view.

Use ONLY these five solid colors:
- Background: #B8D4E3
- Grass / ground: #8FCB74
- Dirt clearing and connecting path: #E8C88F
- Building footprints: #D88C45
- Tree footprints: #438F52

LAYOUT:
One large simple rounded rectangular ground region, fully inside the frame with a clear background margin.
One small dirt clearing in the lower half, connected to one small dirt destination area in the upper half by a single broad, nearly straight path. Both areas and the connecting path form one continuous cream-colored region.
Keep the route centered, unobstructed and visible from beginning to end. Path width must be at least 12% of the ground region's width. Reserve additional empty space beside both edges of the path.

OBJECTS:
Exactly TWO small plain orange rectangles representing building ground footprints, both beside the left edge of the lower clearing.
Exactly TWO small dark-green circles representing tree ground footprints, one on each side of the upper destination area.
Keep every rectangle and circle completely inside the ground region, separated from each other, and outside the cream clearing/path region with a visible grass gap.
No object may cover, cross, touch, narrow or divide the connecting route.
At least 70% of the ground region must remain free of object footprints.

STRICT SIMPLICITY:
Each shape uses exactly one uniform solid color.
No roofs, doors, steps, trunks, canopies, characters, NPCs, pickups, spawn icons, rocks, fences, bridges, water, cliffs, terrain height, shadows, lighting, gradients, textures, outlines, bevels, patterns, flowers, or decorative details.
No text, symbols, arrows, labels, legend, grid, borders, watermark, extra panels, or extra colors.
Simple crisp boundaries. No antialiasing, blur, transparency, or photographic detail.
The result must read as a few large clean semantic regions with only four isolated object footprints.
```

## After generation

- Confirm one connected ground region and connected start → path → destination.
- Confirm only two building and two tree footprints; no overlap with the route or its clearance.
- Normalize RGB to the canonical palette (`assets/blueprints/semantic_palette.json`): IDs 1, 2, 3, 6, 7. Preserve IDs; do not renumber the subset.
- Validate actual agent clearance and area occupancy before adapting assets. A prompt alone is not validation.
- Record spawn and goal as metadata; keep annotation overlays separate from the label map.
