# Asset Metadata (`assets/metadata/`)

Áp dụng cơ chế kế thừa 3 tầng (**Global → Category → Asset Override**):

1. **Global (`assets/visual_bible.yaml`)**: Quy chuẩn chung cho toàn game (art style 2.5D Isometric, gameplay-first, bảng màu, ánh sáng, scale, export, QA).
2. **Category (`assets/metadata/<category>/config.yaml`)**: Quy định riêng cho từng nhóm `environment`, `characters`, `props` (kích thước hợp lệ, anchor, collision, animation).
3. **Asset Override (`assets/metadata/<category>/<asset_id>.json`)**: **Không bắt buộc** cho mọi ảnh. Chỉ tạo khi một asset cụ thể cần ghi đè thông số của Category (dựa theo `_template.asset.json`).
