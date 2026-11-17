# QA Reports & Validation (`assets/qa/`)

Mỗi batch asset phải đạt đủ 3 nhóm tiêu chí trong `assets/visual_bible.yaml` (`qa_criteria`) trước khi chuyển sang `assets/approved/`:

1. **Consistency (Nhất quán):** Đúng palette, outline `#1E293B`, góc nhìn 2.5D Isometric (`2:1`), và tỷ lệ theo Reference Library.
2. **Gameplay Readability (Dễ đọc khi chơi):** Silhouette rõ ở zoom gameplay, ít chi tiết nhiễu, phân biệt rõ vùng đi được và vật cản.
3. **Engine Integration (Tích hợp Godot):**
   - Chạy `python3 scripts/tools/validate_assets.py` đạt `PASS` (RGBA transparent PNG, kích thước hợp lệ, naming `snake_case`, atlas JSON & `.tres` khớp).
   - Anchor/pivot đặt ở đáy (`bottom_center` / `bottom_center_feet`) để Y-sorting chính xác.

## Trạng thái chuẩn
- `STRUCTURAL_PASS` — Đạt kiểm tra tự động.
- `REVIEW_REQUIRED` — Chờ duyệt trực quan/gameplay.
- `NEEDS_REPAIR` — Lệch style, lỗi alpha, sai tỷ lệ hoặc lệch pivot.
- `READY` — Đã duyệt, khóa bất biến trong `assets/approved/`.
