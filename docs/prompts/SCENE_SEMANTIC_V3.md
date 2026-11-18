# Corrected semantic concept v3

Generated with built-in image_gen. Output: assets/inbox/concept-v3-semantic-village-forest.png.

Input 1 (authoritative layout): assets/blueprints/semantic_world_v3/semantic_colors.png.
Input 2 (style only; rejected geometry): assets/inbox/concept-v2-simple-village-forest.png.

Label IDs/colors are defined separately in assets/blueprints/semantic_palette.json. This generated illustration is not a pixel-perfect label-map target. See docs/semantic-world-v3/README.md for validation scope and remaining reconciliation.

## Final prompt

Use case: stylized-concept.
Create ONE corrected very simple 2.5D isometric Cloudbound village-to-peach-forest concept, landscape 1536x1024.

INPUT ROLES:
Image 1 is the AUTHORITATIVE gameplay-first semantic layout. Preserve its land contour, connected cream clearing/path, object positions, relative scales and open walking space.
Image 2 is STYLE ONLY and contains a rejected layout. Do not copy its house placements. In particular NEVER restore a house at the clearing-to-forest junction.

Render Image 1 as a charming very minimal game concept using the soft forms of Image 2.
Exactly 3 houses, 4 pink peach trees, 2 green trees, 2 rocks, 1 elder, 1 small monkey hero, 1 stone spawn disc, 3 peach pickups.
The three houses must ALL remain on the WEST / SOUTHWEST side of the clearing, as in Image 1. The eastern half of the clearing and the entire winding forest path remain visibly free of buildings, steps, roofs, rocks and tree crowns.
House base centers approximately (210,610), (470,540), (320,810). Match Image 1. Use modest roofs and tiny entrance steps facing the open clearing.
The pink tree base centers approximately (805,340), (1020,240), (1390,490), (1110,650). Keep canopy shapes within the footprints of the colored silhouettes in Image 1. Green trees remain at approximately (655,410), (930,800). Rocks remain at approximately (160,705), (1260,650).
The reserved clear route runs through (500,730), (630,700), (735,620), (890,530), (930,440), (1060,360), (1190,300), (1260,220). No part of any static object, including a roof, canopy or entrance step, may enter a band extending 80 pixels on either side of this route. The full path must be visible continuously from village to forest landing.
NPC and hero may stand in open clearing; do not add other characters.
Doors, tree bases and peach pickups must be visible and accessible. No roots, stairs or foliage may form a barrier across the path.

STYLE:
Simple broad clean color masses, pastel light green grass, warm cream dirt, muted purple-gray cliff, pink crowns, brown trunks, plain wooden houses with simple warm golden pitched roofs. No window ornament, individual roof shingles, beams, petals, flowers, grass blades, terrain texture noise, tiny stones, cracks, cloud banks, mountains, waterfalls, glow or particles.
Single uniform-height plateau. Simple exposed front cliff face. No detached islands, bridges, extra levels or hidden passages.
Very restrained shading and short contact shadows; no long shadows over the path.
Thin or absent outlines. One consistent orthographic elevated camera and scale.
Plain flat pale blue background, no sky gradient or scenery. Entire island and all objects remain inside the frame.
This is a concept illustration, not a semantic label map: do not add labels, text, numbers, symbols, UI, legends, grids, frames or extra panels.
Preserve Image 1's open corridor and object placement above decorative beauty.
