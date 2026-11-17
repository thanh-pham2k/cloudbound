# Hoa Quả Sơn — Scene Concept Blueprint V1

**Status:** Phase 2 — Approved  
**Genre:** Mini Action RPG  
**Perspective:** 2.5D Isometric  
**Art Style:** Minimal Stylized  
**Target:** Vertical Slice 10–15 phút

## 1. World Structure — Confirmed

- Một bản đồ liên thông gồm 4 khu vực.
- Tuyến chính uốn lượn: **Làng Khỉ → Rừng Đào → Bãi Quái → Hang Boss**.
- Một nhánh phụ dẫn đến khu bí mật nhỏ.
- Các khu vực gần nhau nhưng có ranh giới dễ nhận biết.
- Người chơi có thể quay lại các khu vực trước.

## 2. Camera & Visual Style — Confirmed

- Camera isometric cố định, góc nhìn 35–45°.
- Minimal Stylized, hình khối đơn giản, ít chi tiết.
- Bảng màu pastel nhất quán.
- Hạn chế texture, hiệu ứng và vật thể trang trí.
- Đồng nhất tỷ lệ, góc nhìn và ánh sáng.
- Ưu tiên gameplay readability hơn tính chân thực.

## 3. Area Design — Confirmed

| Khu vực | Thiết kế | Chức năng gameplay |
|---|---|---|
| **Làng Khỉ** | 2–3 nhà khỉ, quảng trường trung tâm, NPC | Spawn, nhận nhiệm vụ |
| **Rừng Đào** | Rừng thưa, cây đào theo cụm, đường mòn rõ | Khám phá, thu thập |
| **Bãi Quái** | Bãi đất trống, vài tảng đá và cây | Chiến đấu, né đòn |
| **Hang Boss** | Cửa hang nổi bật, sân đấu rộng bên trong | Boss fight |
| **Nhánh bí mật** | Một khu vực nhỏ ngoài tuyến chính | Đào hồi máu hoặc phần thưởng |

## 4. Semantic Layout — Confirmed

```text
             [HANG BOSS]
                  |
              [BÃI QUÁI]
                  |
              [RỪNG ĐÀO] ── [KHU BÍ MẬT]
                  |
              [LÀNG KHỈ]
                  |
                SPAWN
```

Sơ đồ chỉ thể hiện kết nối logic, không phải tọa độ hoặc bố cục hình học cuối cùng.

**Semantic Rules:**

1. Đường mòn phải kết nối các khu vực gameplay.
2. Mỗi khu vực có landmark và mục đích rõ ràng.
3. Đường chính dễ nhận biết, nhánh phụ dễ khám phá.
4. Cây, đá và nhà không che khuất đường đi hoặc đối tượng quan trọng.
5. Khu vực chiến đấu đủ rộng để di chuyển và lướt.
6. Không đặt vật thể trang trí gây cản trở gameplay.

## 5. Scene Concept Requirements — Confirmed

Ảnh concept tổng thể phải thể hiện:

- Đầy đủ 4 khu vực và một nhánh phụ.
- Đường đi chính liên tục, uốn lượn tự nhiên.
- Landmark rõ ràng tại từng khu vực.
- Không gian di chuyển và chiến đấu dễ nhận biết.
- Tỷ lệ tương đối hợp lý giữa nhân vật, nhà, cây và địa hình.
- Phong cách đơn giản, dễ tái dựng bằng asset độc lập.

**Ưu tiên:** Semantic Layout → Gameplay Readability → Visual Consistency → Aesthetics.

## 6. Unresolved — Cần thiết kế tiếp

Các chi tiết chưa được chốt:

- Kích thước bản đồ và tỷ lệ pixel/world unit.
- Tọa độ, hướng và hình dạng cụ thể của từng khu vực.
- Chiều rộng đường đi, vùng collision và vùng có thể di chuyển.
- Vị trí chính xác của Spawn, NPC, quái, vật phẩm và Boss.
- Vị trí nhánh phụ và điều kiện tiếp cận.
- Tỷ lệ kích thước giữa Player, NPC, nhà, cây và quái.
- Bảng màu cụ thể, ánh sáng và thông số camera.
- Cách hiển thị không gian bên trong Hang Boss trên bản đồ liên thông.
- Ranh giới bản đồ và cách ngăn người chơi đi ra ngoài.

Những nội dung này sẽ được xử lý trong bước Semantic Layout chi tiết, không tự suy đoán khi tạo ảnh.

## 7. Next Steps

1. Thiết kế **Semantic Layout chi tiết**: khu vực, vị trí, đường đi, landmark và gameplay objects.
2. Xác định tỷ lệ tương đối và quy tắc camera.
3. Tạo một ảnh **Scene Concept tổng thể** dựa trên blueprint đã duyệt.
4. Kiểm tra semantic và chỉnh sửa concept nếu cần.
5. Sau khi duyệt concept mới phân rã asset và tạo sprite sheet theo batch.

## Core Principle

**Gameplay-First Scene Design — Simple, Connected, Readable, Consistent, Reconstructable.**

Không tạo asset hoặc viết code trước khi Scene Concept được duyệt.
