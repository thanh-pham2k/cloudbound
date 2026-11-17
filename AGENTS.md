# Cloudbound — Asset & Scene Design Rules

## Asset & Scene Design Principles

1. **Simplicity:** Asset cực kỳ đơn giản, ít chi tiết, dễ tạo bằng AI. Tránh texture và hiệu ứng phức tạp.
2. **Semantic Layout:** Sắp xếp đối tượng hợp lý theo chức năng và quan hệ không gian. Đường đi phải kết nối các khu vực gameplay.
3. **Visual Consistency:** Thống nhất phong cách 2.5D isometric, tỷ lệ, góc nhìn, màu sắc và ánh sáng.
4. **Gameplay Readability:** Dễ nhận biết đường đi, vật cản, đối tượng tương tác và lối ra.
5. **Modularity & Reusability:** Asset độc lập, dễ tái sử dụng, thay thế và mở rộng.
6. **Technical Compatibility:** Tuân thủ cấu hình Godot và quy chuẩn dự án về kích thước, anchor, layer, collision và metadata.
7. **Batch-Based Generation:** Ưu tiên tạo asset theo từng batch. Mỗi batch được tạo trong **một ảnh sprite sheet chứa nhiều subimages**, thay vì tạo từng ảnh riêng lẻ. Các subimages phải tách biệt, không chồng lấn, không bị cắt và có phong cách nhất quán. Sau khi tạo, tách thành các asset độc lập để tích hợp vào Godot.

### Workflow

**Gameplay Layout → Scene Concept → Semantic Blueprint → Batch Sprite Sheet Generation → Asset Extraction → Godot Integration → Validation**

### Core Rule

**Ưu tiên gameplay, semantic và tính nhất quán trước đồ họa.** Hoàn thành và kiểm tra từng batch trước khi chuyển sang batch tiếp theo. Chỉ bổ sung chi tiết, animation và hiệu ứng khi cần thiết.

---

## Execution Pipeline

**TL;DR:** Thiết kế gameplay trước → Tạo scene tổng thể → Chuẩn hóa semantic → Tạo asset theo batch → Tích hợp Godot → Kiểm thử.

```text
1. Gameplay Design
   → Xác định người chơi làm gì, đi đâu, tương tác với gì.

2. Scene Concept
   → Tạo ảnh xem trước toàn bộ bản đồ 2.5D isometric.

3. Semantic Layout
   → Sắp xếp nhà, cây, đường, cầu và khu vực gameplay hợp lý.

4. Asset Breakdown
   → Phân loại asset đơn giản, chia thành các batch.

5. Batch Generation
   → Mỗi batch tạo 1 sprite sheet chứa nhiều subimages.
   → Tách thành các asset độc lập.

6. Godot Integration
   → Ráp bản đồ, thiết lập collision, interaction và navigation.

7. Gameplay Validation
   → Chơi thử, sửa lỗi và cải thiện.
   → Lặp lại cho đến khi gameplay ổn định.
```

**Nguyên tắc:** *Gameplay First → Semantic First → Simple Assets → Consistency → Polish Later.*

**Chiến lược:** Hoàn thành một khu vực nhỏ có thể chơi được (**Vertical Slice**) trước khi mở rộng toàn bộ thế giới.
