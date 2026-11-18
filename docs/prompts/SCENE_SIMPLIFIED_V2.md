# Simplified scene concept v2

Generated with the built-in image_gen tool. Output: assets/inbox/concept-v2-simple-village-forest.png.

Purpose: new simplified village/forest concept for the next segmentation trial. Not yet integrated into Godot. This concept is an art reference, not a ground-truth segmentation map. Ground occluded by huts and canopies still needs reconstruction and gameplay validation.

## Final prompt

Use case: stylized-concept.
Asset type: a NEW simplified gameplay scene concept for the Cloudbound Godot project, designed to be reconstructed from semantic regions and independent reusable sprites.

Create ONE single coherent landscape image, not a collage, not a sprite sheet. Show only a small playable Monkey Village connected to the beginning of a Peach Forest. Keep the cheerful pastel 2.5D isometric art direction, warm golden wooden roofs, pink peach trees, green grass, cream dirt, muted purple-gray cliffs. Fixed orthographic elevated camera; consistent isometric projection and scale throughout.

PRIORITY: exceptionally simple, readable geometry for manual segmentation and Godot reconstruction. The scene should resemble a clean early game art blockout with charming finished color shapes, not a richly illustrated painting.

LAYOUT:
One connected grassy plateau with a simple rounded irregular perimeter, fully contained in the image with comfortable margins. A broad cream village clearing occupies the lower-left half. One continuous wide gently S-curving cream path leads from the clearing toward the upper-right peach grove, ending at a small clear landing within the plateau. No detached platforms. A single uniform-height exposed cliff face forms the front perimeter. No nested terraces, concealed routes, gaps or bridges needed.
Exactly three very simple wooden huts frame the village clearing: one larger house along the rear edge and two small houses at the sides. Each hut has one plain golden pitched roof, a rectangular wooden body, one dark doorway and two broad entrance steps; no ornaments, beams, individual shingles, railings or lanterns.
Exactly four simple pink peach trees frame the forest path, with plain brown trunks and two or three large rounded canopy masses each. Place trees alternately along the outside of the path so the entire walkable corridor remains visible. Exactly two simple green trees near the outer village boundary. Exactly two low simple gray rocks, away from the path.
A plain small stone spawn disc in the village clearing. One tiny simple monkey elder and one tiny monkey hero establish gameplay scale without drawing attention from terrain. Three small peach pickups on clear grass beside three tree trunks.
No other props.

READABILITY:
All tree foot points, hut entrances and pickups must be visible and clearly separated.
Do not let tree crowns or hut roofs cover the main path, neighboring objects, or the main terrain boundary.
Keep substantial open ground between objects. The clearing and path together must leave ample room for walking and dodging.
Grass, dirt, cliff and background each have a distinct largely uniform pastel color. Crisp natural boundaries between regions. Very subtle broad shading only; no speckles, texture noise, mottling, grass blades, flowers, leaf detail, petals, tiny stones, cracks, particles, glow, ambient mist or intricate rock facets.
Simple short contact shadows under objects, no long shadows crossing terrain classes.
Very thin soft colored outlines or no outlines; no heavy black outlines.
Background is a single pale blue field. No mountains, clouds, waterfall, sky illustration, vignette or landscape beyond the island.
No text, labels, UI, grid, numbers, watermark, inset panels or diagram annotations.

COMPOSITION:
Landscape image, entire miniature level visible. Clearly distinguish village, connecting path and forest at a glance. Preserve simple proportions that can be rebuilt faithfully with a small number of independent game assets.
