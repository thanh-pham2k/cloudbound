# Semantic world v3 — hành lang thông, nhãn màu thống nhất

Bản v2 bị lỗi: một nhà nằm ở cổ chai từ quảng trường sang rừng; mái/bậc che phần đất nối. V3 đặt lại cả 3 nhà về mép tây/tây nam và chừa nửa đông quảng trường để nối lên rừng. Đây là bản đồ mới được dựng từ gameplay, không phải tô màu lại ảnh v2.

## Nguồn chuẩn

`assets/blueprints/semantic_world_v3/layout.json` chứa geometry, 17 object, cửa, footprint, visual envelope và tuyến.

`assets/blueprints/semantic_palette.json` là registry 16 class dùng chung. Bản này dùng 12 màu class. Mọi pixel của cùng class có RGB giống nhau, kể cả nhà/cây ở vị trí khác. Mái vàng và thân nâu trong ảnh minh họa đều mang class `building` trong nhãn.

## Các lớp đã xuất

Trong `assets/blueprints/semantic_world_v3/`, cùng resolution 1536×1024:

- `semantic_colors.png`: nhãn màu phẳng chuẩn, không legend/chữ/bóng/anti-alias.
- `semantic_ids.png`: ID class nhìn thấy.
- `surface_ids.png`: mặt đất/nền/vách trước khi đặt vật thể; giữ nền phía dưới vật thể.
- `instance_ids.png`: ID riêng cho 17 instance, PNG 16 bit.
- `collision_mask.png`: footprint vật cản.
- `obstacle_visual_envelopes.png`: vùng bảo thủ bao toàn bộ hình chiếu object, không chỉ chân.
- `walkable_mask.png`: nền đi được trừ footprint.
- `protected_corridor.png`: hành lang bảo vệ 160px; đường đất rộng 120px.
- `height_ids.png`: 0 ngoài đất; 1 mặt plateau. Chỉ một tầng.
- `validation.json`: kết quả kiểm tra của bộ dữ liệu.

`docs/semantic-world-v3/semantic-map-legend.png` thêm bảng tra màu; `layout-review.png` thêm tên/route/điểm cửa. Hai ảnh review không dùng làm label mask.

## Kiểm tra đã chạy

`python3 scripts/tools/validate_semantic_world.py`: PASS.

- Không có collider hoặc visual envelope của vật cản chạm hành lang bảo vệ.
- Footprint đều nằm trên đất.
- Spawn, đích trong rừng, cả 3 cửa nhà, NPC và 3 pickup đều đi tới được với agent bán kính 20px. Kiểm tra trên free-space đã erode, không chỉ nhìn đường bằng mắt.
- Class/instance hợp lệ, cùng kích thước; mọi RGB khớp bảng LUT theo ID.

Đây là kiểm tra trên blueprint/mask. Nó không chứng minh ảnh concept AI có đúng từng pixel, không phải kiểm thử Godot.

## Concept minh họa

`assets/inbox/concept-v3-semantic-village-forest.png` được tạo bằng image_gen với semantic map làm bố cục chính; v2 chỉ làm tham chiếu phong cách. Đã kiểm tra trực quan: 3 nhà về phía trái, đoạn nối từ quảng trường lên rừng nhìn thấy liên tục, không còn nhà chắn cổ chai.

Ảnh sinh có sai khác nhỏ về silhouette, NPC/pickup và phối cảnh so với bản đồ kế hoạch. Vì vậy **không dùng mask kế hoạch làm ground-truth segmentation pixel của ảnh minh họa**. Khi tích hợp hoặc cần dataset pixel-aligned, phải chốt một nguồn geometry, reconcile các silhouette/anchor thực tế và validate lại. Bản đồ semantic là kế hoạch có thể dựng được; concept là ảnh minh họa tham chiếu.

Chưa thay scene Godot hiện tại trong lượt này.

## Dùng lại

1. Đọc `docs/rules/SEMANTIC_SEGMENTATION_RULES.md` (AGENTS.md đã liên kết bắt buộc).
2. Chỉnh `layout.json` theo gameplay.
3. `python3 scripts/tools/build_semantic_world.py --render-only`.
4. `python3 scripts/tools/validate_semantic_world.py`.
5. Chỉ tạo/adapt asset sau khi kết quả đạt; thay scale/silhouette phải chạy lại.

Chạy builder không có `--render-only` sẽ tạo lại bố cục mẫu v3. Dependencies: Pillow, NumPy, SciPy. Không chỉnh màu label map bằng công cụ ảnh có smoothing.
