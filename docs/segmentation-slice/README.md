# Thử nghiệm scene theo phân vùng — Làng Khỉ → Rừng Đào

Nguồn: `assets/inbox/002-create-a-3x2-grid-concept-art-sheet-containing-6-separate-cl.png`, chỉ ô tổng quan trên trái, crop `[8,8,506,504]`.

Đây là bản thử chơi được riêng, không thay toàn bộ world chính. Main scene vẫn là `hoa_qua_son.tscn`.

## Cách mở

Mở `scenes/segmentation_slice.tscn` rồi Run Current Scene; hoặc bấm F2 từ game chính.

- WASD di chuyển, Space lướt, E tương tác.
- Nói chuyện với Trưởng Lão và thu 3 đào dưới cây.
- F1 đổi camera theo nhân vật / toàn cảnh.
- F3 hiện vùng bề mặt, tầng cao suy dựng, tuyến đi, điểm neo và footprint collision.
- F2 chuyển qua scene cũ hoặc trở lại bản thử. Mỗi lần chuyển khởi tạo scene từ đầu; không giữ tiến độ tạm của scene trước.

## Phương pháp và phạm vi

Đây là **phân vùng ngữ nghĩa vẽ theo ảnh và dựng lại phần khuất**, không phải output tự động của model segmentation, không phải tách pixel hoàn hảo từ concept.

Bố cục đất, đường, vị trí 3 nhà, và cụm cây được tham chiếu từ ô tổng quan. NPC và vật phẩm được đặt bổ sung để kiểm tra gameplay theo các ô cận cảnh. Mặt đất sau mái/tán cây được suy dựng; một số điểm đặt được chỉnh để đủ khoảng đi lại. Không dùng cả 6 ô làm một bản đồ chung tọa độ.

Blueprint có 39 instance, contour đất 124 điểm và tuyến kiểm tra. Đổi từ pixel nguồn sang world: `(source - [120,390]) * 4`. Footprint và điểm chân được lưu riêng với chiều cao sprite. Polygon bề mặt tạo nền; silhouette sprite không được dùng làm collision. Tuyến đi từ làng lên rừng uốn cong theo blueprint thay vì đường chéo cũ.

Bản thử mới tái dựng làng và đoạn đầu rừng. Đoạn đường phía trên kết thúc tại biên bản thử; chưa nối thành toàn bộ map, chưa có boss hay bãi quái trong scene này. Các hệ thống đó vẫn ở scene cũ.

## Dữ liệu

`assets/blueprints/segmentation_slice/blueprint.json` là nguồn dữ liệu runtime có thể chỉnh sửa:

- `surfaces`: polygon cỏ và đất.
- `instances`: loại asset, anchor theo chân, chiều cao, footprint, role.
- `height_regions`: phân vùng cao độ suy dựng để thiết kế tiếp. Chưa có cơ chế di chuyển nhiều tầng; mặt đi hiện liên tục trong 2D.
- `route`, `spawn`, `gameplay`: tuyến đi, spawn và mục tiêu thử nghiệm.

Bốn ảnh ID cùng tọa độ crop:

- `surface_ids.png`: 0 chưa annotate/ngoài phạm vi; 1 cỏ; 2 đất; 3 nước; 4 mặt vách suy dựng. Vùng chưa annotate không có nghĩa là trời.
- `instance_ids.png`: ID theo thứ tự instance trong JSON, biểu diễn footprint/điểm neo, không phải mask silhouette đầy đủ của từng vật thể.
- `height_ids.png`: 0 ngoài đất; 1 vùng thấp; 2 vùng cao suy dựng. Đây là metadata, không tự tạo elevation gameplay.
- `gameplay_ids.png`: 0 ngoài đất; 1 nền; 2 vật cản; 3 tuyến kiểm tra. Các lớp chồng nhau được ghi theo thứ tự; JSON giữ đầy đủ dữ liệu tách biệt.

Runtime đọc JSON, không giải mã mask màu để spawn. Mask là bản đối chiếu giúp phát hiện sai hình học. Script `scripts/tools/build_segmentation_slice.py` tạo JSON từ các điểm trace thủ công và render mask. Sau khi chỉnh trực tiếp JSON, dùng `--render-only` để cập nhật ảnh đối chiếu mà không ghi đè các chỉnh sửa; chạy không có flag sẽ tái tạo trace gốc.

## Kiểm tra

Godot 4.7.2 native, OpenGL Compatibility, 1280×720.

- Import không có lỗi.
- `tests/validate_segmentation_slice.gd`: PASS — 39 anchor trên đất, đi tuyến hai chiều, tiếp cận/NPC/3 đào, collision nhà và mép đảo, F1/F3 và F2 qua lại hai scene.
- Hai bài kiểm tra scene cũ (`validate_layout.gd`, `validate_asset_integration.gd`) vẫn PASS sau khi archive.
- Test dùng InputMap và key event lập trình, có reset vị trí giữa các nhánh nhặt đào độc lập; không phải người chơi test qua bàn phím hệ điều hành.
- Đã xem ảnh Godot thực tế ở góc làng, rừng, toàn cảnh và overlay. Ảnh chụp dùng vị trí/camera được dàn sẵn.

Giới hạn hình ảnh: hình dáng bán đảo là bản suy dựng có điều chỉnh, chưa khớp toàn bộ vi địa hình của concept; tree/character sprites cũ vẫn có viền đậm hơn asset mới. Kết quả này kiểm chứng quy trình trace → blueprint → placement, chưa chứng minh chất lượng của segmentation tự động.

## Archive

14 source sheet đã adapt nằm trong `assets/archive/adapted/`; ảnh concept tham chiếu vẫn ở inbox. Source gốc được giữ nguyên byte, có manifest SHA256. Archive được loại khỏi Godot import bằng `.gdignore`; sprite runtime vẫn giữ nguyên đường dẫn. Hai script tách asset đã hỗ trợ đọc source từ archive.

## Ảnh đối chiếu

- `segmentation-review.png`: ảnh nguồn, vùng trace/suy dựng, các anchor.
- `godot-overview.png`: toàn cảnh bản thử.
- `godot-village.png` / `godot-forest.png`: camera gameplay.
- `godot-debug.png`: blueprint chồng lên scene.
