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
