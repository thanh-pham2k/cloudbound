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

---

## Batch 5 — Hero Animation Keyframes (`assets/inbox/B5_hero_anim.png`)

**Gồm 8 subimages (lưới 4×2) cho 4 trạng thái MVP của Tôn Ngộ Không:**
- Hàng 1: `Idle 1`, `Idle 2`, `Run 1`, `Run 2`
- Hàng 2: `Attack Windup`, `Attack Swing`, `Dash 1`, `Dash 2`

```text
Create a 2.5D isometric character animation sprite sheet for the Monkey Hero (Sun Wukong) containing 8 separate keyframes arranged in a clean 4x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each pose, no overlapping, no cast shadows on background, and no text or labels.

Consistent Design & Style (matching existing Hero):
- Cute chibi monkey warrior with warm brown fur (#D4A373), yellow-gold tunic (#FBBF24), golden headband, flowing red scarf (#DC2626), holding a red-and-gold staff.
- Fixed 2.5D isometric projection (35-45 degree elevated angle, facing front-right-down).
- Minimal Stylized look: clean shapes, soft cel shading, crisp uniform dark indigo-slate ink outline (#1E293B).

8 Keyframes (4 columns x 2 rows, identical character size across all cells):
- Row 1 (Idle & Run):
  1. Col 1 (Idle 1): Standing relaxed combat-ready pose holding staff upright.
  2. Col 2 (Idle 2): Subtle breathing/bob pose, scarf slightly lifted, staff held slightly lower.
  3. Col 3 (Run 1): Mid-stride running pose leaning slightly forward, left foot forward, scarf trailing back.
  4. Col 4 (Run 2): Opposite stride running pose, right foot forward, scarf trailing back.
- Row 2 (Attack & Dash):
  5. Col 1 (Attack Windup): Pulling red-gold staff back behind shoulder ready to strike.
  6. Col 2 (Attack Swing): Sweeping staff forward in a wide horizontal strike with a subtle golden arc motion.
  7. Col 3 (Dash 1): Low forward-leaning dash lunge with staff tucked back and red scarf streaming straight behind.
  8. Col 4 (Dash 2): Extended fast-dash glide pose with trailing wind-wisp lines.

Negative constraints: No flat 2D side-view, no 90-degree top-down, no photorealism, no cast shadows on white background, no overlapping poses, no text.
```

---

## Batch 6 — Enemy #2, Boss/Boar Combat & FX (`assets/inbox/B6_enemies_fx.png`)

**Gồm 6 subimages (lưới 3×2):**
1. Quái thứ 2 — Tiểu Yêu Rừng (`enemy_imp`)
2. Lợn Rừng Tấn Công (`enemy_boar_attack`)
3. Yêu Vương Đập Đất (`boss_slam`)
4. Đồng Vàng (`gold_coin`)
5. Vệt Chém Gậy (`fx_staff_slash`)
6. Vòng Sóng Đập Đất (`fx_boss_slam`)

```text
Create a 2.5D isometric game combat & monster sprite sheet containing 6 separate assets arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each item, no overlapping, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle).
- Minimal Stylized look: simple clean shapes, soft cel shading, crisp dark indigo-slate ink outline (#1E293B), matching our existing chibi characters.

6 Subimages (3x2 grid):
1. Top-left (Monster #2 — Forest Imp): Cute chibi horned forest demon imp with muted crimson skin (#C95B5B), dark little horns (#1E293B), tattered brown loincloth (#9C6644), holding a simple wooden club.
2. Top-center (Wild Boar Charge Pose): Same chunky dark slate-gray wild boar (#7B8499) with cream tusks lowered forward in an aggressive charging lunge pose.
3. Top-right (Demon King Boss Slam Pose): Same large crimson-skinned Demon King boss with gold armor/crown (#FBBF24) and red cape, raising both arms and slamming his heavy golden staff downward.
4. Bottom-left (Gold Coin Pickup): Stylized chunky ancient Chinese gold coin (#FBBF24) with a square center hole and warm shine.
5. Bottom-center (Staff Slash FX): Clean stylized golden-white crescent slash arc effect (#FBBF24, #FFFFFF) with crisp minimal stylized edges.
6. Bottom-right (Boss Ground Slam FX): Clean 2.5D isometric flat circular shockwave ring in warm orange-gold and crimson (#FBBF24, #DC2626).

Negative constraints: No photorealism, no cast shadows on white background, no overlapping items, no text.
```

---

## Batch 7 — Environment Details (`assets/inbox/B7_env_details.png`)

**Gồm 6 subimages (lưới 3×2):**
1. Hàng Rào Gỗ (`fence_wooden`)
2. Cầu Gỗ Nhỏ (`bridge_wooden`)
3. Bụi Cây Xanh (`bush_green`)
4. Cụm Cỏ Hoa (`grass_tuft`)
5. Vách Đá 2.5D (`cliff_wall`)
6. Thác Nước (`waterfall`)

```text
Create a 2.5D isometric game environment detail sprite sheet containing 6 separate objects arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each object, no overlapping, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle).
- Minimal Stylized look: simple clean geometric shapes, low detail, pastel palette, crisp dark indigo-slate ink outline (#1E293B).

6 Subimages (3x2 grid):
1. Top-left (Wooden Fence): 2.5D isometric short rustic wooden fence segment aligned along the 45-degree isometric diagonal in warm wood-brown (#D4A373, #9C6644).
2. Top-center (Small Wooden Bridge): 2.5D isometric short plank wooden bridge with low side posts aligned along the 45-degree isometric diagonal (#D4A373, #9C6644).
3. Top-right (Round Pastel Bush): Stylized low rounded green bush (#9ED48A, #7BB86E) with 2-3 tiny pink blossom dots (#F9A8D4).
4. Bottom-left (Grass & Flower Tuft): Small simple cluster of pastel green grass blades (#9ED48A) with 2 tiny cream-yellow wildflowers (#E9C46A).
5. Bottom-center (Isometric Cliff Wall Segment): 2.5D isometric faceted slate-gray mountain cliff block (#7B8499, #9CA3AF) with a thin pastel green grass cap (#9ED48A) on top.
6. Bottom-right (Waterfall Strip): Stylized 2.5D isometric cascading sky-blue waterfall (#7CC6EE) with soft white-cyan foam (#CBEAF8) at the bottom.

Negative constraints: No photorealism, no cast shadows on white background, no overlapping objects, no text.
```

---

## Batch 8 — Seamless Ground Surfaces, Cave Arch & Mountains (`assets/inbox/B8_ground_surfaces.png`)

**Gồm 6 subimages (lưới 3×2) — Chuyên dùng lát sàn & nền không viền đen để ghép liền mạch như ảnh concept:**
1. Mảng cỏ pastel liền mạch (`ground_grass_patch` — không viền)
2. Mảng sân đất kem liền mạch (`ground_dirt_patch` — không viền)
3. Mảng sàn đá lục giác Hang Boss (`ground_cave_floor` — không viền)
4. Vòm vách đá Hang Boss hình móng ngựa (`cave_back_wall`)
5. Góc vách đá 2.5D phủ cỏ (`cliff_corner_ledge`)
6. Nền trời & núi xa Hoa Quả Sơn (`bg_distant_mountains`)

```text
Create a 2.5D isometric game terrain surface & background sprite sheet containing 6 separate assets arranged in a clean 3x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each item, no overlapping, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric, matching the Hoa Qua Son concept sheet):
- Fixed 2.5D isometric projection (35-45 degree elevated angle).
- Minimal Stylized look: soft pastel hand-painted cel shading, clean low-detail shapes, unified pastel palette (#9ED48A grass, #EBD8B7 cream dirt, #DDD6CE stone floor, #7B8499 cliff rock, #B8D4E3 sky & distant mountains).

6 Subimages (3x2 grid):
1. Top-left (Seamless Grass Ground Patch): Soft rounded organic flat grass patch in pastel jade-green (#9ED48A, #86C577) with a few tiny grass blades and 2-3 tiny white-yellow flower dots, NO dark outline around the outer edge so it blends seamlessly.
2. Top-center (Seamless Cream Dirt Plaza Patch): Soft rounded organic flat dirt clearing patch in warm cream-tan (#EBD8B7, #DFC79F) with subtle soft shading, NO dark outline around the outer edge so it blends seamlessly.
3. Top-right (Boss Cave Hex/Stone Floor Patch): Flat 2.5D isometric paved stone floor patch in warm light stone-gray (#DDD6CE) with subtle muted mortar lines (#B8B0A4) forming soft hexagonal/irregular flagstones, NO dark outline around the outer edge.
4. Bottom-left (Boss Cave Horseshoe Rock Wall): Large 2.5D isometric curved horseshoe-shaped rocky cave back-wall made of chunky faceted gray stones (#9CA3AF, #7B8499) with crisp dark ink outlines (#1E293B), open at the front-bottom so a boss arena sits inside.
5. Bottom-center (Elevated Cliff Corner Segment): 2.5D isometric chunky slate-gray mountain cliff corner (#7B8499, #9CA3AF) topped with soft pastel green grass edge (#9ED48A) and crisp #1E293B outlines.
6. Bottom-right (Distant Misty Mountains & Sky): Wide soft pastel sky-blue (#CBEAF8) backdrop with layered misty blue-green mountain silhouettes (#9EC5D6, #7FAEC4) and 2 fluffy white clouds.

Negative constraints: No photorealism, no text, no labels, no overlapping items, no dark black borders on items 1-3.
```

---

## Batch 9 — Water Stream & Ground Transitions (`assets/inbox/B9_water_transitions.png`)

**Gồm 4 subimages (lưới 2×2):**
1. Dòng suối xanh ngọc (`stream_water`)
2. Đá cuội rải rìa đường (`pebble_cluster`)
3. Cột đèn lồng gỗ Làng Khỉ (`lantern_post`)
4. Ánh sáng vàng Cổng Mở (`fx_portal_glow`)

```text
Create a 2.5D isometric game environment detail sprite sheet containing 4 separate assets arranged in a clean 2x2 grid on a solid pure white (#FFFFFF) background with wide empty spacing between each item, no overlapping, no cast shadows on background, and no text or labels.

Camera & Art Style (Minimal Stylized 2.5D Isometric):
- Fixed 2.5D isometric projection (35-45 degree elevated angle).
- Minimal Stylized look: simple clean shapes, pastel palette, crisp dark indigo-slate ink outline (#1E293B) for solid props.

4 Subimages (2x2 grid):
1. Top-left (Isometric Stream Water Segment): 2.5D isometric curved clear sky-blue water stream strip (#7CC6EE) with soft white-cyan ripples (#CBEAF8) and subtle grassy-stone bank edges.
2. Top-right (Small Pebble Cluster): 3-4 tiny smooth rounded gray stones (#D8D2CA, #9CA3AF) grouped loosely for ground path edges, crisp #1E293B outline.
3. Bottom-left (Village Wooden Lantern Post): Cozy 2.5D isometric small wooden post (#9C6644) hanging a glowing red-gold Chinese paper lantern (#DC2626, #FBBF24).
4. Bottom-right (Golden Portal Glow FX): Soft glowing warm golden-yellow archway light aura (#FBBF24, #FEF08A) for the unlocked Boss Cave exit.

Negative constraints: No photorealism, no cast shadows on white background, no overlapping items, no text.
```


