# Cloudbound generated animation pack QA

For the follow-up extraction, reconstruction trials and Scene 03 results, see [Gate A partial acceptance](GATE_A.md). The inventory below records the initial inspection.

**Gate A is blocked for gameplay integration.** The archive contains 44 asset sheets and 10 references. All 54 PNGs decoded and were visually inventoried. The [manifest](manifest.json) records each source's filename, dimensions, alpha, identity, inferred action and facing, observed visible counts, and QA status. The [contact sheet](archive_contact_sheet.jpg) is indexed to the manifest. Counts describe visible poses and do not certify grid geometry, distinct timing, or motion continuity.

## Wukong gate

| Archive IDs | Observed material | Finding |
|---|---|---|
| 10, 42 | Four frontal idle poses and four right-facing idle poses | True RGBA. Native alpha inspection shows four separate silhouettes in each. Faint nonzero alpha exists between cells, so a raw grid slice still needs cleanup. |
| 26 | Eight frontal locomotion poses | True RGBA. Eight separated visible groups; the last approaches the right edge within one pixel at alpha above 8. Full edge and ground-contact review are pending. |
| 19, 20, 21, 33, 34, 39, 40, 41 | Rear and side motion or idle variants | Opaque RGB with baked checkerboard. |
| 05, 14, 25, 35 | Eight death, six attack, six dash, and four probable hurt poses | Opaque RGB with baked checkerboard, including around staff, scarf and soft shadows. The attack includes a painted slash. |
| — | Dedicated Skill 1 and Skill 2 casts | No identifiable dedicated sequences in the supplied archive. |

The true-alpha strips are candidates for a partial prototype. They do not supply validated attacks, dash, hurt, death, or skill casts. The baked RGB examples have shading mixed with the checkerboard, so global white/gray keying would risk scarf edges, staff highlights, shadows and glow. The original PNGs and archive were preserved. No directional aliases or missing frames were fabricated.

## Enemy, boss, and VFX findings

- The mixed spirit and ranged-demon sheet contains several actions per row. The Golem and pig-demon composites use different counts per row. The pig sheet has three visible idle poses. A single equal-cell grid would cut poses or introduce blanks.
- The Guardian has slam and death candidates, but no identifiable dedicated six-frame idle in the pack. Its art should be kept distinct from the Stone Golem sheets.
- Standalone and mixed VFX provide six- or eight-frame candidates, including six red health-orb and six golden loot-orb poses in the mixed sheet. Their RGB backgrounds are baked into the partially transparent-looking artwork.
- Seven static sheets correspond by artwork to the existing processed terrain, scenery, UI, roster and effects. Existing runtime art remains available.

## Validation and remaining work

Repository asset validation passed. No new runtime animations, pickups, run-state changes, or scene screenshots were produced because the requested gate precedes integration. Existing Wukong static presentation and the K/L control changes were preserved.

The gate can be reassessed with true-alpha exports of the missing actions or manually masked frame sets reviewed on both light and dark backgrounds, plus a decision on separate K/L casts or an approved shared visual fallback. The subsequent Scene 03 benchmark should verify stance scale, feet anchors, direction fallbacks and animation timing against the current combat events.
