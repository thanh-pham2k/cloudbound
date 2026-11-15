# Asset Inbox

Thả asset bạn muốn xử lý vào thư mục này (`assets/inbox/`).

## Cách sử dụng
1. Copy/thả ảnh, sprite sheet, hoặc thư mục batch (`B01`–`B06`, hoặc file lẻ) vào `assets/inbox/`.
2. Nhắn cho agent xử lý (kèm tên batch hoặc mục đích nếu cần, ví dụ: *"xử lý asset trong inbox cho B03 hero"*).
3. Agent sẽ:
   - Chuẩn hoá / tách frame / đóng gói atlas / xuất `.tres` qua `gameforge-kit` (hoặc đưa vào `assets/base/` đối với tile/prop tĩnh).
   - Chạy `scripts/tools/validate_assets.py` và test Godot headless.
   - Di chuyển toàn bộ file gốc đã xử lý từ `assets/inbox/` sang `assets/archive/<timestamp>/` để `assets/inbox/` sạch sẽ cho đợt asset tiếp theo.
