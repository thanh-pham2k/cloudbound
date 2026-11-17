# Hoa Quả Sơn — Gameplay Blueprint V1

**Status:** Phase 1 — Approved  
**Genre:** Mini Action RPG  
**Perspective:** 2.5D Isometric  
**Engine:** Godot  
**MVP Duration:** 10–15 phút

## 1. Game Concept

Người chơi điều khiển Tôn Ngộ Không khám phá Hoa Quả Sơn, bảo vệ làng khỉ khỏi yêu quái, thực hiện nhiệm vụ, lên cấp và đánh bại Boss để mở khóa khu vực mới.

**Core Gameplay Loop:**

Khám phá → Gặp NPC → Nhận nhiệm vụ → Chiến đấu / Thu thập → Nhận thưởng → Lên cấp → Mở khu vực mới.

## 2. Player & Controls — Confirmed

| Phím | Hành động |
|---|---|
| WASD | Di chuyển 8 hướng |
| Space | Lướt (Dash), né đòn |
| K | Đánh thường theo hướng di chuyển cuối |
| E | Tương tác NPC / đối tượng |

- Nhân vật: Tôn Ngộ Không, sử dụng gậy Như Ý.
- Combat: Action RPG thời gian thực.
- Animation MVP: Idle, Run, Attack, Dash.
- Chưa triển khai kỹ năng phức tạp.

## 3. World Design — Confirmed

Một bản đồ liên thông gồm 4 khu vực:

1. **Làng Khỉ:** Spawn, NPC, nhận và trả nhiệm vụ.
2. **Rừng Đào:** Khám phá, thu thập đào, gặp quái.
3. **Bãi Quái:** Chiến đấu với quái mạnh hơn.
4. **Hang Boss:** Đánh Boss, hoàn thành chương đầu.

**World Structure:**

```text
         [Hang Boss]
              |
         [Bãi Quái]
              |
         [Rừng Đào] ── [Nhánh phụ]
              |
          [Làng Khỉ]
              |
            Spawn
```

- Tuyến chính rõ ràng, có nhánh phụ khám phá.
- Người chơi có thể quay lại khu vực trước.
- Không chuyển scene khi đi giữa các khu vực.
- Các khu vực phải có mục đích gameplay cụ thể.

## 4. Combat & Monster AI — Confirmed

**Player:**
- K tấn công phía trước.
- Space lướt né đòn.
- Có HP, Damage và phản hồi khi trúng đòn.

**Monster AI:**

Patrol → Detect → Chase → Attack → Return.

- Quái tuần tra trong phạm vi.
- Phát hiện và đuổi theo người chơi.
- Tấn công khi đủ gần.
- Quay về vị trí ban đầu khi người chơi đi xa.

**Difficulty:** Dễ đến vừa.

**Death:** Hồi sinh tại Làng Khỉ, không mất EXP hoặc vàng.

## 5. Quest System — Confirmed

| Quest | Mục tiêu |
|---|---|
| Q1 — Bảo vệ làng | Tiêu diệt 3 yêu quái |
| Q2 — Thu thập đào | Thu thập 5 quả đào |
| Q3 — Đánh bại Boss | Tiêu diệt Yêu Vương |

- Nhiệm vụ thực hiện theo trình tự.
- Nhận nhiệm vụ thông qua NPC.
- Có marker và nhật ký nhiệm vụ đơn giản.
- Hoàn thành nhiệm vụ để nhận thưởng và mở tiến trình.

## 6. Progression & Rewards — Confirmed

- Level 1–5.
- Nhận EXP khi đánh quái và hoàn thành nhiệm vụ.
- Lên cấp tự động tăng HP và Damage.
- Phần thưởng gồm EXP, vàng và đào hồi máu.
- Không có bảng kỹ năng hoặc hệ thống trang bị phức tạp.

## 7. MVP Completion Criteria

MVP hoàn thành khi người chơi có thể:

1. Di chuyển, lướt và tấn công.
2. Khám phá 4 khu vực liên thông.
3. Trò chuyện với NPC và nhận nhiệm vụ.
4. Đánh quái, thu thập đào và nhận thưởng.
5. Lên cấp, tăng HP và Damage.
6. Đánh bại Boss và mở khóa lối đi mới.
7. Hoàn thành toàn bộ trải nghiệm trong khoảng 10–15 phút.

## 8. Chưa chốt — Cần thiết kế tiếp

Các thông số và chi tiết sau **chưa được xem là quyết định cuối cùng**:

- **Map Layout:** Kích thước, vị trí, đường đi, nhánh phụ, ranh giới và vật cản.
- **NPC:** Số lượng, vị trí, hội thoại và vai trò cụ thể.
- **Monsters:** Ngoại hình, số lượng, HP, Damage, tốc độ và phạm vi phát hiện.
- **Boss:** Cơ chế tấn công, hành vi và độ khó.
- **Combat Tuning:** Attack range, cooldown, dash distance, invincibility frames và hit feedback.
- **Progression Balance:** EXP từng cấp, chỉ số tăng, phần thưởng và tỷ lệ rơi vật phẩm.
- **Quest Details:** Điều kiện mở khóa, cách hoàn thành và xử lý khi người chơi chết.
- **Visual Design:** Bố cục, tỷ lệ, màu sắc và thiết kế asset cụ thể.

## 9. Out of Scope — MVP

Chưa triển khai:

- Multiplayer / PvP.
- Crafting và hệ thống trang bị.
- Skill tree và combo phức tạp.
- Nhiều bản đồ hoặc nhiều chương.
- Animation và hiệu ứng đồ họa nâng cao.

## 10. Next Phase — Scene Concept

Sử dụng Gameplay Blueprint V1 để thiết kế một ảnh xem trước toàn bộ Hoa Quả Sơn.

**Yêu cầu:**
- 2.5D Isometric, Minimal Stylized.
- Một bản đồ liên thông, có tuyến chính và nhánh phụ.
- Bốn khu vực có chức năng gameplay rõ ràng.
- Semantic layout hợp lý, dễ di chuyển và khám phá.
- Asset đơn giản, đồng nhất tỷ lệ và phong cách.

**Chưa tạo asset hoặc viết code ở giai đoạn này.**

### Core Principle

**Gameplay First → Semantic Layout → Simple Assets → Consistency → Playable MVP → Polish Later.**
