# Approved Assets (`assets/approved/`)

Thư mục lưu trữ các asset **đã vượt qua QA (tự động + trực quan)** và được khóa làm nguồn chuẩn.

## Nguyên tắc bất biến
- Asset đã đưa vào `approved/` **không được tự động ghi đè** khi chạy các đợt generate mới.
- Muốn sửa asset đã duyệt, phải tạo phiên bản/nhánh mới hoặc đánh dấu `NEEDS_REPAIR` trong báo cáo QA trước khi thay thế.
- Asset từ đây được đóng gói/export qua `tools/gameforge-kit/` sang `assets/generated/` để Godot sử dụng.
