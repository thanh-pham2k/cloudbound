# Scene Concept Prompt — Hoa Quả Sơn (Phase 2)

Dựa trên [PHASE_2_SCENE_CONCEPT_BLUEPRINT.md](../PHASE_2_SCENE_CONCEPT_BLUEPRINT.md) và [PHASE_1_GAMEPLAY_BLUEPRINT.md](../PHASE_1_GAMEPLAY_BLUEPRINT.md).

## 1. Master Prompt (Copy & Paste)

```text
Create a wide 16:9 2.5D isometric game level concept overview of Hoa Qua Son (Flower Fruit Mountain) in a Minimal Stylized art style.

Camera & Visual Style:
- Fixed 2.5D isometric projection (35-45 degree elevated camera angle, clean diagonal layout flowing from bottom-left to top-right).
- Minimal Stylized look: simple clean shapes, low detail, minimal surface texture, no visual clutter, soft pastel color palette (soft pastel jade-green grass, warm cream-tan dirt trails, soft pastel pink peach blossoms, warm light-brown wooden huts, muted warm-gray rocks and slate-stone cliffs).
- Consistent soft top-left daylight, subtle contact shadows, crisp readable silhouettes, high gameplay readability.

World Structure & Semantic Layout (ONE continuous connected map, no disconnected islands):
- A single clear winding dirt path connects 4 main areas from bottom-left to top-right, plus 1 small secret side branch:
1. Bottom-left (Monkey Village / Lang Khi): Safe starting clearing with 2-3 simple stylized wooden monkey huts arranged around a small open central plaza, a small stone spawn marker, and an elder monkey NPC standing clearly in the plaza.
2. Lower-middle (Peach Forest / Rung Dao): The winding trail passes through a sparse grove of clustered pastel-pink peach trees with a few visible glowing peaches on the ground/low branches; trees are spaced around the path so they never block or obscure the trail.
3. Side branch from Peach Forest (Secret Nook / Khu Bi Mat): A narrower secondary trail branches off to the side into a small secluded clearing with a single large special peach tree and a small reward chest.
4. Upper-middle (Monster Clearing / Bai Quai): A wide, open, flat combat clearing with just a few simple low rocks and trees around the edges, leaving plenty of open space for movement and dashing, with 2-3 small simple monster silhouettes.
5. Top-right (Boss Cave / Hang Boss): A prominent carved stone cave archway opening into a wide, clearly visible sunken rocky boss arena (cutaway/open-top view so the interior combat floor is easy to read) with a larger Demon King boss silhouette waiting in the center.

Scale & Readability:
- Consistent relative scale across the entire map (player hero size < huts < peach trees < boss cave).
- Clear contrast between walkable dirt paths, open grass/arena floors, and impassable outer cliff/forest boundaries.

Negative constraints: No text, no labels, no numbers, no UI/HUD overlays, no grid lines, no photorealism, no dark gritty textures, no dense foliage blocking the path, no floating disconnected islands.
```

## 2. Prompt biến thể (Nếu AI tạo quá nhiều chi tiết hoặc che đường)

Dùng bản rút gọn này nếu ảnh lần 1 bị rối hoặc cây che mất đường đi:

```text
Minimal stylized 2.5D isometric game map concept, 16:9 wide overview, 40-degree fixed isometric camera, pastel color palette, very simple low-detail geometric shapes, clean readable layout with zero clutter. One continuous winding cream-tan dirt path on soft pastel green grass flowing from bottom-left to top-right connecting: (1) bottom-left: small village plaza with 3 simple wooden huts and a tiny monkey hero; (2) lower-middle: sparse clusters of pastel pink peach trees with a small side trail branching right to a tiny secret clearing with a golden chest; (3) upper-middle: wide open flat battle clearing with a few simple low rocks; (4) top-right: prominent stone cave entrance opening into a wide open-top circular stone boss arena. Crisp silhouettes, soft daylight, high gameplay readability. No text, no labels, no UI, no photorealism, no dense trees covering the path.
```

## 3. Checklist kiểm tra ảnh Concept trước khi duyệt Phase 2

- [ ] Thấy rõ 4 khu vực chính: Làng Khỉ → Rừng Đào → Bãi Quái → Hang Boss.
- [ ] Thấy rõ 1 nhánh phụ rẽ từ Rừng Đào sang Khu Bí Mật.
- [ ] Đường đi chính liên tục, không bị cây/đá/nhà che khuất.
- [ ] Không gian Bãi Quái và Hang Boss đủ rộng để di chuyển & lướt (dash).
- [ ] Phong cách Minimal Stylized pastel đồng nhất, đơn giản, dễ tách thành asset độc lập theo batch.
