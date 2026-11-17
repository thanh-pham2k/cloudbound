# Cloudbound — Asset & Scene Design Rules

## Asset & Scene Design Principles

1. **Simplicity:** Asset cực kỳ đơn giản, ít chi tiết, dễ tạo bằng AI. Không thêm texture hoặc hiệu ứng phức tạp khi chưa cần thiết.
2. **Semantic Layout:** Sắp xếp đối tượng hợp lý theo chức năng, vị trí và quan hệ không gian. Đường đi phải kết nối các khu vực gameplay.
3. **Visual Consistency:** Duy trì phong cách 2.5D isometric thống nhất về tỷ lệ, góc nhìn, màu sắc và ánh sáng.
4. **Gameplay Readability:** Người chơi phải dễ nhận biết đường đi, vật cản, đối tượng tương tác và lối ra.
5. **Modularity & Reusability:** Asset độc lập, dễ tái sử dụng, thay thế và mở rộng. Không gộp các đối tượng cần tương tác vào background.
6. **Technical Compatibility:** Tuân thủ cấu hình Godot và quy chuẩn dự án về kích thước, anchor, layer, collision và metadata.

### Workflow

**Gameplay Layout → Scene Concept → Semantic Blueprint → Asset Generation (Batch) → Godot Integration → Validation**

### Core Rule

**Ưu tiên gameplay và semantic trước đồ họa.** Mỗi batch phải đáp ứng các nguyên tắc trên. Chỉ bổ sung chi tiết, animation và hiệu ứng khi thực sự cần thiết.
