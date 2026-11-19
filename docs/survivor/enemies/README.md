# Bộ quái mới — Hoa Quả Sơn

Đã adapt **27 sprite sheet thành 27 atlas và 252 frame** cho Godot. Có 18 quái thường, 5 elite và 4 boss. Ảnh gốc được giữ trong `assets/inbox/`.

[Manifest nguồn, frame và điểm neo](../../../assets/survivor/enemies/manifest.json) · [Quái thường 1](roster-1.png) · [Quái thường 2](roster-2.png) · [Elite và boss](roster-3.png) · [Tư thế tấn công elite và boss](actions-3.png)

## Cách chơi và chọn boss

Mở project trong Godot rồi bấm **F5** để chơi với Boar King ở cuối trận. Quái thường mới xuất hiện trong các đợt hiện tại. Biến thể elite bắt đầu từ đợt 4. Mỗi biến thể dùng hồ sơ quái nhẹ hoặc nặng đã có, với cùng điểm sinh, giới hạn làn, sát thương, phần thưởng và thời gian tấn công.

Để chơi với một trong bốn boss mới, mở `scenes/monkey_army_survivor.tscn`, chọn node gốc `MonkeyArmySurvivor` và đổi **Boss Appearance** trong Inspector. Bấm **F6** để chạy scene. Có thể chọn Ancient Treant, Nine-Tailed Fox, Bull Demon King hoặc Golden Dragon. Tên và chân dung boss trên HUD cùng thông báo Victory cập nhật theo lựa chọn. Bốn boss chia sẻ hồ sơ chiến đấu cuối trận hiện tại.

Các biến thể dùng art và animation của sheet. Tên như Goblin Archer hoặc Slime Splitter mô tả tạo hình. Chúng vẫn dùng đòn tấn công và quy tắc của hồ sơ quái đã có.

## Kiểm tra

| Hạng mục | Kết quả | Bằng chứng |
|---|---|---|
| Ảnh gốc và alpha | PASS | 20 sheet có kênh alpha, 7 sheet RGB đã tách nền sáng. Manifest lưu mã băm, kích thước nguồn, vùng cắt, vùng atlas và điểm neo. |
| Tài nguyên Godot | PASS | Nạp đủ 27 bộ `SpriteFrames` với 252 vùng atlas. Thứ tự frame và các clip đứng, chạy, tấn công, trúng đòn, gục khớp manifest. |
| Kích thước và bố cục | PASS | Cùng một tỷ lệ trên các frame của mỗi quái. Atlas có lề trong suốt và điểm neo ở chân. Preview Godot hiển thị đủ 27 tạo hình với tư thế di chuyển và tấn công. |
| Lịch spawn và boss | PASS | Test lịch spawn kiểm tra đủ 23 biến thể, đúng làn và đúng hồ sơ. Test finale kiểm tra Boar King và bốn lựa chọn mới, bao gồm tên, HP, phần thưởng và Victory. |
| Hồi quy gameplay | PASS | 48 kiểm tra về điều khiển, đội hình, vũ khí, shop, kinh tế và kết quả trận. |
| Trọn trận trên cửa sổ Godot | PASS | Chạy 5× đến mốc 300 giây rồi đánh bại Boar King tại 5:00.78, sau 61.07 giây thực. |

[Kiểm tra tài nguyên](assets.log) · [Kiểm tra render](render.log) · [Hồi quy gameplay](regression.log) · [Log trận 5×](live.log) · [Ảnh trong trận ở phút 4](live/240s.png) · [Victory](live/result.png)

## File thay đổi

- `assets/survivor/enemies/` chứa atlas, tài nguyên `SpriteFrames`, import metadata và manifest.
- `scripts/tools/prepare_survivor_enemies.py` tách sheet và kiểm tra lại tài nguyên đã tạo.
- `scripts/survivor/enemy_looks.gd` khai báo nhóm biến thể và tên boss.
- `scripts/survivor/actor.gd` phát animation từ atlas. `match.gd` chọn biến thể khi sinh quái. `hud.gd` hiển thị boss đã chọn.
- `tests/validate_survivor_enemies.gd` kiểm tra tài nguyên, lịch spawn và boss, đồng thời chụp preview Godot.

## Chạy lại

```sh
python3 scripts/tools/prepare_survivor_enemies.py --check
godot --headless --path . --editor --import
godot --headless --path . --script tests/validate_survivor_enemies.gd
godot --path . --resolution 1280x720 --script tests/validate_survivor_enemies.gd -- --capture
godot --headless --path . --fixed-fps 60 --script tests/validate_survivor.gd
godot --path . --resolution 1280x720 --script tests/run_survivor_live.gd -- "--output=$PWD/docs/survivor/enemies/live"
```
