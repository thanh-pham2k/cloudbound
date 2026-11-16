# Checkpoint Cloudbound — 16/11/2026

Mục tiêu sáu cảnh đang PARTIAL; lần tiếp tục hiện tại đã kiểm tra lại tài nguyên, còn chờ bằng chứng chơi thử thủ công. Game đã được mở lại từ Cảnh 01 — Phàm Gian để người dùng test. Chưa có kết quả playtest được ghi nhận. Checkpoint này lưu trạng thái công việc trong repo.

- Đã tích hợp 43 animation vào 13 SpriteFrames, cùng VFX, vật phẩm hồi máu, linh ngọc và chuyển cảnh giữ tiến trình.
- Godot 4.7.2 đã kiểm tra import, 43 animation, tài nguyên người chơi của sáu cảnh và năm đích đến của cổng. `python3 scripts/tools/validate_assets.py` và `git diff --check` đã qua.
- Có 43 preview và ảnh viewport mở đầu của sáu cảnh. Danh sách kiểm thử và các mục chưa xác minh nằm trong [QA report](QA_REPORT.md).
- Chưa xác minh trong gameplay các chuyển động, timing combat, nhặt vật phẩm, cổng sau khi hạ guardian và dữ liệu giữ qua năm lần chuyển cảnh. Các cảnh báo motion của GameForge vẫn cần đối chiếu.
- Thay đổi nằm trong worktree `/Users/thanhpv/Documents/Work/cloudbound`. Hãy kiểm tra cả file chưa được Git theo dõi. Không tự commit, push, hoặc xóa thay đổi hiện có.

## Prompt cho lần sau

```text
/goal Tiếp tục mục tiêu Cloudbound sáu cảnh trong /Users/thanhpv/Documents/Work/cloudbound từ checkpoint hiện có. Đọc AGENTS.md, docs/assets/animation_pack_qa/HANDOFF.md và QA_REPORT.md. Đọc đặc tả gốc tại /Users/thanhpv/.codex/attachments/ad2ad2a7-3f27-4a0a-832d-06bee4791e77/pasted-text-1.txt. Kiểm tra git status, diff và file untracked trước khi sửa. Tái sử dụng assets và công việc hiện có.

Kết quả tôi test thủ công từ Phàm Gian tới Cổng Thiên Giới:
[Dán kết quả theo từng cảnh và mô tả lỗi, nếu có]

Dựa trên kết quả test, sửa lỗi đã xác nhận, chạy lại import và kiểm tra tài nguyên, rồi cập nhật QA_REPORT.md. AGENTS.md giao playtest gameplay trực tiếp cho tôi. Giữ mục tiêu mở nếu còn thiếu bằng chứng. Chỉ hoàn tất khi đủ bằng chứng cho toàn bộ tiêu chí trong đặc tả gốc. Không tự commit hoặc push.
```

## Revalidation 16/11/2026

Đã kiểm tra lại import (exit 0), 43 animation/13 SpriteFrames, binding sáu cảnh/năm đích cổng, asset validator và diff whitespace. Người dùng yêu cầu tiếp tục từ bàn giao, chưa gửi kết quả chơi thử hoặc lỗi tái hiện. Không sửa gameplay khi chưa có lỗi xác nhận; xem QA_REPORT.md để biết lệnh và giới hạn bằng chứng. Không commit/push.
