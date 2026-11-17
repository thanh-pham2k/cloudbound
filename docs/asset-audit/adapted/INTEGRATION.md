# Concept batches adapted — 18/11/2026

Imported the five `00N-use-the-attached...` source sheets. Actual source size is 1536×1024, with six 512×512 cells per sheet, rather than the requested 3072×2048. Masters are unchanged.

## Extraction

Run `python3 scripts/tools/extract_concept_batches.py` (Pillow, NumPy, SciPy). Outputs: `assets/sprites/concept/`, including 30 source sprites, a derived cliff strip, and source/cell/output metadata in `manifest.json`.

A–D retain source alpha, with small residual components removed. E has white matte rather than alpha; extraction reconstructs alpha while retaining cream petals/dust. Terrain fill gutters are cropped and mirrored into repeating textures. Mountains/cloud edges are feathered. A cliff texture is straightened column by column and mirrored to follow the exact polygon boundary without transparent cracks.

## Scene integration

- Textured Polygon2D grass, dirt paths, clearings and cave floor replace overlapping stamped patches. Paths are clipped to the existing walkable boundary.
- New continuous cliff face follows the front boundary. Long water, crest, mist, cloud banks and mountain layers provide depth.
- New golden-roof huts, broad cave backdrop, low front rim and stairs replace corresponding old visual assets.
- Flowers and petals decorate the terrain. Quest bubble, enemy detection rays, reward chest rays, dash dust and existing portal glow are connected to gameplay states.
- Exit and blocker move together into the cave opening; torches flank the arena. One green tree is moved inward onto the clearing ground.
- Main paths, collision system, combat and quest rules remain in place. Cliff height is visual; no new climbable elevation system is introduced.

21 source sprites are used directly or as a derived texture. Nine variants are extracted and imported but reserved rather than forced into unsuitable positions: both grass/dirt transitions, authored curve and fork, cliff_tall_b, outer corner, inner corner, terrace connector, and grass rim. The current continuous path geometry already provides its own curve/fork; the modular ledges need authored terrain elevations to fit naturally.

## Validation

Godot 4.7.2, native OpenGL Compatibility renderer, 1280×720.

- Headless editor import completed without errors.
- `tests/validate_layout.gd`: passed area/path/collision structure checks.
- `tests/validate_asset_integration.gd`: loads all 30 textures, walks both routes using InputMap actions, starts/turns in quests, collects peaches, attacks stationary enemies and boss through K action, dashes, opens reward chest, checks gate glow and disabled blocker.
- These are automated in-memory checks with staged positions and frozen enemy AI for repeatability, not a human playthrough or verification of OS keyboard delivery.
- Four native running-scene captures visually reviewed. Source asset contact sheet also reviewed. Screenshots are staged camera locations; enemy AI may show attack poses.

Known limits: old character/tree/prop sprites retain stronger outlines than the new scenery; source resolution limits close zoom; mirrored textures can exhibit broad repeating motifs. No new artwork was generated.
