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

**Gameplay Layout → Basic Segmentation Plan → Semantic Validation → Optional Scene Concept → Batch Sprite Sheet Generation → Asset Extraction → Godot Integration → Validation**

### Core Rule

**Ưu tiên gameplay, semantic và tính nhất quán trước đồ họa.** Hoàn thành và kiểm tra từng batch trước khi chuyển sang batch tiếp theo. Chỉ bổ sung chi tiết, animation và hiệu ứng khi cần thiết.

---

## Execution Pipeline

**TL;DR:** Thiết kế gameplay → Segmentation cơ bản → Kiểm tra semantic → Chỉ thêm concept/asset khi cần → Tích hợp Godot → Kiểm thử.

```text
1. Gameplay Design
   → Xác định người chơi làm gì, đi đâu, tương tác với gì.

2. Basic Segmentation Plan (default)
   → Bản đồ 2D phẳng: tối đa 2 vùng gameplay, 1 đường nối, 2 footprint nhà, 2 footprint cây.
   → Tối đa 5 class màu chuẩn; không dựng cảnh minh họa hoặc nhiều panel.

3. Semantic Validation
   → Kiểm tra đường liên tục, footprint không chắn lối, khoảng trống và màu semantic.
   → Chỉ tạo concept 2.5D chi tiết nếu người dùng yêu cầu rõ.

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

## Semantic World & Segmentation — Required

Before creating or revising a scene concept, segmentation, semantic blueprint, or asset placement, read and follow [`docs/rules/SEMANTIC_SEGMENTATION_RULES.md`](docs/rules/SEMANTIC_SEGMENTATION_RULES.md).

- Default scene-design output is a **basic flat segmentation plan**, not an illustrated scene, sprite sheet, multi-panel concept, or detailed world map. Use at most two gameplay zones, one connecting path, two building footprints, two tree footprints, and five canonical classes. Do not expand the scope unless the user explicitly asks.
- Basic plans use a flat overhead planning view with uniform-color footprint shapes; no roofs, canopies, extrusion, cliff faces, shadows, textures, characters, icons, or decorative props. This planning convention does not change the Godot game's 2.5D camera.
- Use the canonical class IDs and exact label colors in `assets/blueprints/semantic_palette.json`; never invent a new per-map palette.
- Author connected gameplay routes first. Reserve a clear corridor before placing objects; neither colliders nor roofs/canopies/steps may block or conceal critical route segments.
- Keep surface, visible class, instance, footprint/collision, walkability and height data separate. Record foot anchors, doors, scale and provenance.
- Generate strict label masks deterministically; ImageGen illustrations are references, not trusted RGB label masks or validated layouts.
- Validate palette, agent clearance, all entrances/pickups, and visual-envelope intersections before adapting assets. Revalidate after placement/scale changes.
