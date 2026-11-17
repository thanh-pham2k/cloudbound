# Batch Asset Prompts — Hoa Quả Sơn (Phase 2)

Tuân thủ quy tắc **Batch-Based Generation** trong [AGENTS.md](../../AGENTS.md) và phong cách đã duyệt trong `assets/inbox/002-create-a-3x2-grid-concept-art-sheet-containing-6-separate-cl.png`:
- Mỗi batch tạo **1 ảnh sprite sheet duy nhất** trên **nền trắng tinh (`#FFFFFF`)**, các subimage tách biệt hoàn toàn, không chồng lấn, không bị cắt ở mép, không chữ/nhãn.
- Hoàn thành & kiểm tra từng batch (thả vào `assets/inbox/B1_characters.png`, `B2_tiles.png`, `B3_environment.png`, `B4_interactables.png`) trước khi tách và tích hợp vào Godot.

---

## Global Style Block (Dùng chung cho mọi Batch)

- **Projection:** True 2.5D isometric (`35–45°` elevated angle, 45° diagonal orientation, clear top and two front-isometric faces).
- **Art Style:** Minimal Stylized, clean simple geometric shapes, low detail, minimal surface texture, crisp dark indigo-slate ink outline (`#1E293B`), soft top-left daylight, **NO cast shadows on the white background**.
- **Color Palette:** Pastel jade green (`#9ED48A`, `#7BB86E`), cream-tan dirt (`#EBD8B7`), pastel pink peach (`#F9A8D4`, `#F472B6`), warm wood & straw (`#D4A373`, `#9C6644`, `#E9C46A`), slate stone (`#D8D2CA`, `#9CA3AF`, `#7B8499`), warm gold (`#FBBF24`), crimson (`#DC2626`).

---

## Batch 1 — Characters & Enemies (`assets/inbox/B1_characters.png`)

**Gồm 5 subimages (lưới 3×2):**
1. Tôn Ngộ Không (`player_hero` — 1.0×)
2. Khỉ Trưởng Lão (`npc_elder` — 1.0×)
3. Khỉ Gác Cổng (`npc_guide` — 0.95×)
4. Quái Lợn Rừng (`enemy_boar` — 1.0×)
5. Yêu Vương Boss (`boss_demon_king` — 2.2×)

```text
Create a 2.5D isometric game character sprite sheet containing 5 separate characters arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each character, no overlapping, no ground tiles, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle, characters standing on an isometric plane facing front-right-down).
- Minimal Stylized look: cute chibi proportions, simple clean shapes, low detail, minimal surface noise, soft cel shading, top-left daylight, crisp dark indigo-slate ink outline (#1E293B).
- Unified pastel-vibrant palette: warm gold (#FBBF24), crimson (#DC2626), warm wood-brown (#D4A373, #9C6644), pastel jade green (#6BBF7A), slate-gray (#7B8499), cream (#EBD8B7).

5 Subimages (consistent relative scale):
1. Top-left (1.0x, Monkey Hero / Sun Wukong): Cute chibi monkey warrior with warm fur (#D4A373), yellow-gold tunic (#FBBF24), golden headband, flowing red scarf (#DC2626), holding a simple red-and-gold staff.
2. Top-center (1.0x, Elder Monkey NPC): Friendly chibi elder monkey with brown robe (#9C6644), long white beard, kind expression, holding a simple wooden walking staff.
3. Top-right (0.95x, Village Guard Monkey NPC): Cute chibi monkey villager wearing a simple soft jade-green vest (#6BBF7A) and cream sash (#EBD8B7), standing alert.
4. Bottom-left (1.0x, Wild Boar Monster): Stylized chunky wild boar with dark slate-gray fur (#7B8499), small cream tusks (#EBD8B7), and fierce little eyes, facing front-right-down.
5. Bottom-right (2.2x, Demon King Boss): Large imposing chibi-stylized demon king with crimson skin (#DC2626), warm gold shoulder armor and crown (#FBBF24), red cape, holding a heavy gold-tipped battle staff.

Negative constraints: No flat 2D side-view, no pure 90-degree top-down view, no photorealism, no cast shadows on white background, no overlapping sprites, no text.
```

---

## Batch 2 — Ground & Terrain Tiles (`assets/inbox/B2_tiles.png`)

**Gồm 4 subimages (lưới 2×2):**
1. Tile cỏ xanh pastel (`tile_grass`)
2. Tile đường đất kem (`tile_dirt`)
3. Tile đá Hang Boss (`tile_cave_stone`)
4. Bậc thang đá Hang Boss (`stairs_stone`)

```text
Create a 2.5D isometric game terrain tile sheet containing 4 separate 2:1 isometric diamond terrain blocks arranged in a clean 2x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each tile, no overlapping, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- True 2:1 isometric diamond projection (~30-40 degree elevation, clean top diamond face with thin isometric front thickness rim).
- Minimal Stylized look: very simple flat painterly cel shading, minimal texture noise, crisp dark indigo-slate ink outline (#1E293B).

4 Subimages (2x2 grid):
1. Top-left (Pastel Grass Tile): Seamless 2:1 isometric diamond grass tile in soft pastel jade-green (#9ED48A, #7BB86E) with 2-3 tiny minimal grass blades.
2. Top-right (Cream Dirt Path Tile): Seamless 2:1 isometric diamond dirt path tile in warm cream-tan (#EBD8B7, #D2B991) with very subtle smooth surface tone.
3. Bottom-left (Cave Stone Floor Tile): Seamless 2:1 isometric diamond stone courtyard tile in muted light stone-gray (#D8D2CA, #9CA3AF) with simple clean carved stone lines.
4. Bottom-right (Stone Cave Stairs): 2.5D isometric stone stairway (4 clean steps) ascending toward top-right in muted stone-gray (#D8D2CA, #9CA3AF) with clean #1E293B outlines.

Negative constraints: No flat top-down squares, no photorealism, no heavy noise, no overlapping tiles, no text.
```

---

## Batch 3 — Environment Props (`assets/inbox/B3_environment.png`)

**Gồm 6 subimages (lưới 3×2):**
1. Nhà Khỉ chính (`hut_main`)
2. Nhà Khỉ phụ (`hut_small`)
3. Cây Đào (`tree_peach`)
4. Cây Xanh (`tree_green`)
5. Tảng Đá (`rock_cluster`)
6. Đuốc Đá Hang Boss (`torch_brazier`)

```text
Create a 2.5D isometric game environment props sprite sheet containing 6 separate objects arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each object, no overlapping, no ground tiles attached, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle, clear top and two front-isometric faces).
- Minimal Stylized look: simple clean geometric shapes, low detail, soft cel shading, top-left daylight, crisp dark indigo-slate ink outline (#1E293B).

6 Subimages (3x2 grid):
1. Top-left (Main Monkey Hut): Cozy 2.5D isometric wooden village hut with warm brown timber walls (#D4A373, #9C6644), layered straw-gold roof (#E9C46A), small front wooden stairs, and tiny red lantern accent (#DC2626).
2. Top-center (Small Monkey Hut): Simpler, slightly smaller 2.5D isometric wooden hut matching the same timber and straw roof style.
3. Top-right (Peach Blossom Tree): Stylized 2.5D isometric peach tree with simple brown trunk (#9C6644) and fluffy layered pastel-pink blossom canopy (#F9A8D4, #F472B6).
4. Bottom-left (Green Forest Tree): Stylized 2.5D isometric forest tree with simple brown trunk (#9C6644) and rounded layered soft jade-green canopy (#6BBF7A, #7BB86E).
5. Bottom-center (Mossy Stone Rock): Chunky faceted 2.5D isometric gray rock (#D8D2CA, #9CA3AF) with a tiny touch of pastel green moss (#7BB86E) at the base.
6. Bottom-right (Stone Brazier Torch): 2.5D isometric carved stone pedestal brazier (#9CA3AF) with a bright warm gold-and-crimson flame (#FBBF24, #DC2626) on top.

Negative constraints: No flat 2D side-view, no 90-degree top-down, no photorealism, no cast shadows on white background, no overlapping objects, no text.
```

---

## Batch 4 — Interactive Objects & Landmarks (`assets/inbox/B4_interactables.png`)

**Gồm 6 subimages (lưới 3×2):**
1. Đĩa Đá Spawn (`spawn_disc`)
2. Quả Đào Tiên (`peach_pickup`)
3. Rương Đóng (`chest_closed`)
4. Rương Mở (`chest_open`)
5. Cổng Hang Boss — Khóa (`gate_locked`)
6. Cổng Hang Boss — Mở (`gate_unlocked`)

```text
Create a 2.5D isometric game interactive props sprite sheet containing 6 separate objects arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each object, no overlapping, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle).
- Minimal Stylized look: simple clean shapes, high gameplay readability, soft cel shading, top-left daylight, crisp dark indigo-slate ink outline (#1E293B).

6 Subimages (3x2 grid):
1. Top-left (Stone Spawn Disc): Flat 2.5D isometric circular carved stone pedestal pad (#D8D2CA, #9CA3AF) with a simple cloud-swirl emblem carved in the center.
2. Top-center (Glowing Immortal Peach): Collectible 2.5D stylized peach fruit in pastel pink and cream (#F9A8D4, #EBD8B7) with a subtle warm golden-yellow aura (#FBBF24) and two tiny green leaves.
3. Top-right (Closed Reward Chest): 2.5D isometric wooden treasure chest with crimson-brown wood (#9C6644, #DC2626) and warm gold metal trim/lock (#FBBF24), closed lid.
4. Bottom-left (Opened Reward Chest): Same 2.5D isometric treasure chest with lid open and a warm golden glow (#FBBF24) shining from inside.
5. Bottom-center (Locked Cave Archway): 2.5D isometric carved stone cave archway (#9CA3AF, #7B8499) sealed shut with heavy stone blocks/bars.
6. Bottom-right (Unlocked Cave Archway): Same 2.5D isometric stone cave archway now open and glowing with warm golden portal light (#FBBF24) inside.

Negative constraints: No flat 2D side-view, no 90-degree top-down, no photorealism, no cast shadows on white background, no overlapping objects, no text.
```
