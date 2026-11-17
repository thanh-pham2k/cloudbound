# Scene Concept Batch Prompt — Hoa Quả Sơn (Phase 2)

Dựa trên [PHASE_2_SCENE_CONCEPT_BLUEPRINT.md](../PHASE_2_SCENE_CONCEPT_BLUEPRINT.md) và quy tắc **Batch-Based Generation** trong [AGENTS.md](../../AGENTS.md): tạo **1 ảnh sheet gồm nhiều subimages tách biệt** để xem cả tổng thể bản đồ lẫn từng khu vực / trạng thái gameplay trong cùng một phong cách nhất quán.

---

## 1. Batch Scene Concept Sheet — 6 Subimages (Grid 3×2, Khuyên dùng)

Tạo **1 ảnh duy nhất** chứa **6 subimages** (lưới 3 cột × 2 hàng, ngăn cách rõ ràng bằng viền trắng sạch, không chồng lấn, không bị cắt):

```text
Create a 3x2 grid concept art sheet containing 6 separate, clearly framed 2.5D isometric scene subimages for the game "Hoa Qua Son" (Flower Fruit Mountain), separated by clean white gutters, with zero overlapping and zero text or labels.

Consistent Style Across All 6 Subimages (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated camera angle).
- Minimal Stylized look: simple clean geometric shapes, low detail, minimal surface texture, no clutter, unified pastel color palette (soft pastel jade-green grass, warm cream-tan dirt paths, pastel pink peach blossoms, warm light-brown wooden huts, muted warm-gray rocks and slate-stone cliffs).
- Consistent top-left soft daylight, subtle contact shadows, crisp readable silhouettes, high gameplay readability.

6 Subimages (3 columns x 2 rows):
1. Top-left (Full Map Overview): Wide connected overview showing ONE continuous winding dirt path flowing from bottom-left to top-right across 4 areas (Monkey Village -> Peach Forest with a small side branch to a Secret Nook -> Monster Clearing -> Boss Cave).
2. Top-center (Area 1 — Monkey Village / Safe Hub & Quest State): Close-up isometric view of the central plaza with 2-3 simple wooden monkey huts, stone spawn marker, Elder Monkey NPC with a subtle quest icon cue, and Monkey Hero (Sun Wukong with staff) standing ready.
3. Top-right (Area 2 — Peach Forest & Secret Branch / Exploration State): Close-up isometric view of sparse clustered pastel-pink peach trees along a winding trail, collectible glowing peaches, and a narrower side path branching off to a secluded mossy nook with a reward chest.
4. Bottom-left (Area 3 — Monster Clearing / Active Combat State): Close-up isometric view of a wide open flat battle clearing with a few low rocks and peripheral trees, showing the Monkey Hero mid-dash/staff-attack fighting 2 small simple demon monsters with plenty of dodge space.
5. Bottom-center (Area 4 — Boss Cave / Boss Fight State): Close-up isometric view of a prominent stone cave entrance opening into a wide sunken stone arena, showing the Monkey Hero facing a larger Demon King boss in the center.
6. Bottom-right (Area 4 — Boss Cave / Cleared & Unlocked State): Same Boss Cave arena after victory — boss defeated, a glowing golden archway / newly unlocked path opening at the back of the cave, and a reward chest/glow in the center.

Negative constraints: No text, no labels, no numbers, no UI/HUD overlays, no photorealism, no dark gritty textures, no overlapping panels, no cropped objects at panel edges.
```

---

## 2. Biến thể 2×2 — 4 Subimages (Nếu muốn mỗi ô to & rõ hơn)

Dùng bản này nếu AI vẽ lưới 3×2 bị nhỏ chi tiết:

```text
Create a 2x2 grid concept art sheet containing 4 separate, clearly framed 2.5D isometric scene subimages for "Hoa Qua Son", separated by clean white gutters, with zero overlapping and no text or labels.

Consistent Style Across All 4 Subimages:
- Fixed 2.5D isometric camera (35-45 degree angle), Minimal Stylized low-detail shapes, unified pastel palette (pastel jade-green grass, cream-tan dirt trails, pastel pink peach blossoms, warm wooden huts, muted slate-stone cliffs), soft top-left daylight, high gameplay readability.

4 Subimages (2x2 grid):
1. Top-left (Full Connected Map Overview): Continuous winding path from bottom-left to top-right connecting Monkey Village -> Peach Forest (+ side Secret Nook) -> Monster Clearing -> Boss Cave.
2. Top-right (Village & Peach Forest — Exploration/Quest State): Monkey Village plaza with 2-3 wooden huts and Elder NPC leading into sparse pastel-pink peach trees, glowing collectible peaches, and the side branch to a secret chest.
3. Bottom-left (Monster Clearing — Combat State): Wide open flat arena with low peripheral rocks, showing Monkey Hero with staff fighting 2 small demon monsters with clear dodge space.
4. Bottom-right (Boss Cave — Boss Fight & Unlockable Path): Prominent stone cave opening into a wide sunken rocky arena with the larger Demon King boss and a sealed/unlockable back exit archway.

Negative constraints: No text, no labels, no UI, no photorealism, no overlapping panels, no dense foliage blocking paths.
```

---

## 3. Checklist kiểm tra Batch Scene Concept trước khi duyệt Phase 2

- [ ] Cả 6 (hoặc 4) subimages đều tách biệt rõ ràng, không dính/chồng lấn, không bị cắt mất chi tiết ở mép ô.
- [ ] Cùng một góc nhìn 2.5D isometric (35–45°), cùng bảng màu pastel và mức độ chi tiết Minimal Stylized.
- [ ] Thấy đủ 4 khu vực chính + 1 nhánh phụ và các trạng thái: **Tổng quan → Hub/Quest → Khám phá/Thu thập → Chiến đấu → Boss Fight → Mở khóa lối đi**.
- [ ] Đường đi rõ ràng, khu chiến đấu rộng rãi, không bị cây/đá che khuất.
