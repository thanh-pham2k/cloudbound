# Game Design — Hoa Quả Sơn

## 1. Game Concept

- **Thể loại:** Mini Action RPG, 2.5D Isometric.
- **Bối cảnh:** Hoa Quả Sơn, thế giới của Tôn Ngộ Không.
- **Nhân vật:** Tôn Ngộ Không sử dụng gậy Như Ý.
- **Mục tiêu:** Khám phá, đánh quái, hoàn thành nhiệm vụ, lên cấp và mở khóa khu vực mới.
- **Phong cách:** Minimal Stylized, asset đơn giản, màu sắc và tỷ lệ nhất quán.

## 2. Core Gameplay Loop

Khám phá → Gặp NPC → Nhận nhiệm vụ → Đánh quái / Thu thập → Nhận EXP, vàng → Lên cấp → Mở khu vực mới.

## 3. Player Controls

| Phím | Hành động |
|---|---|
| WASD | Di chuyển 8 hướng |
| Space | Lướt (Dash) |
| K | Đánh thường bằng gậy |
| E | Tương tác NPC / vật phẩm |

- Animation MVP: Idle, Run, Attack, Dash.
- Ưu tiên animation 4 hướng để giảm số lượng asset.

## 4. Combat System

- Đánh trực tiếp theo hướng nhân vật.
- Quái tự phát hiện, đuổi theo và tấn công.
- Có HP, Damage, Hitbox và Knockback nhẹ.
- Dash có cooldown ngắn.
- Quái chết sẽ thưởng EXP, vàng hoặc vật phẩm.
- Người chơi chết sẽ hồi sinh tại Spawn.

## 5. Quest & Progression

**Quest 1 — Bảo vệ Hoa Quả Sơn**

- NPC Khỉ Trưởng Lão giao nhiệm vụ tiêu diệt 3 yêu quái.
- Thưởng: 50 EXP + 20 vàng.

**Quest 2 — Thu thập đào tiên**

- Thu thập 5 quả đào trong rừng.
- Thưởng: 40 EXP + 15 vàng.

**Quest 3 — Đánh bại Yêu Vương**

- Tiêu diệt mini-boss, mở khóa khu vực mới.
- Thưởng: 150 EXP.

**Progression:** Level 1–5, tăng HP và Damage khi lên cấp. Phần thưởng và chỉ số sẽ cân chỉnh sau.

## 6. MVP Scope

- 1 bản đồ Hoa Quả Sơn.
- 1 nhân vật Tôn Ngộ Không.
- 2 NPC, 2 loại quái và 1 mini-boss.
- 3 nhiệm vụ.
- Hệ thống combat, EXP, level và phần thưởng cơ bản.
- Thời lượng mục tiêu: 10–15 phút.

## 7. Development Roadmap

1. **Phase 1 — Combat Prototype:** Player movement, dash, attack, monster AI và HP.
2. **Phase 2 — World Design:** Scene concept, semantic layout, tạo asset theo batch và dựng Hoa Quả Sơn.
3. **Phase 3 — RPG Systems:** NPC, quest, EXP, level và rewards.
4. **Phase 4 — Vertical Slice:** Hoàn thiện 3 nhiệm vụ, mini-boss và kiểm thử gameplay.
5. **Phase 5 — Polish:** Cải thiện animation, âm thanh, hiệu ứng và cân bằng game.

## Core Principles

**Gameplay First → Semantic Layout → Simple Assets → Visual Consistency → Playable MVP → Polish Later.**

Không triển khai multiplayer, PvP, crafting, trang bị hoặc kỹ năng phức tạp trong MVP.
