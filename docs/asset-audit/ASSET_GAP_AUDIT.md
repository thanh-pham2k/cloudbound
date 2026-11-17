# Đối chiếu asset Godot với concept 6 ô

Ngày kiểm tra: 18/11/2026. Nguồn: assets/inbox/002-create-a-3x2-grid-concept-art-sheet-containing-6-separate-cl.png.

Đã đọc scene chính, layout, ánh xạ sprite, code nhân vật/quái/tương tác; xem toàn bộ 51 PNG đã tách; chạy Godot 4.7.2 và chụp 4 khu vực ở viewport 1280×720. Đây là kiểm tra hình ảnh và liên kết tài nguyên, không phải kiểm thử hoàn thành quest. Các ảnh runtime được chụp bằng cách chuyển vị trí player; quái có thể ở trạng thái tấn công. Không sửa gameplay hay asset hiện có.

## Kết luận

Đủ các loại đối tượng chính. Chênh lệch lớn nhất: địa hình chỉ là một mặt bằng chéo, đường/cỏ đóng dấu patch bị lộ mép, vách đá ngắn lặp lại, hang sai tỷ lệ và thiếu cảm giác nhiều tầng núi trong ảnh tổng quan. Asset hiện tại viền đen đậm, còn concept thiên về khối mềm ít viền. Tạo thêm props không tự giải quyết được những điểm này.

Danh mục dưới là bộ module đề xuất để tái hiện ảnh, không phải số lượng vật thể cần đặt trong map. Những món cùng chức năng đã có được đánh dấu thay thế/bổ sung, tránh tạo trùng.

## A. Bộ cần tạo/bổ sung để ráp sát concept

### Batch A — mặt đất và đường, 3×2: 6 subimages, ưu tiên cao nhất

| Tên đề xuất | Nội dung | Thiếu hiện tại |
|---|---|---|
| terrain_grass_fill | Mặt cỏ ít chi tiết, không viền, texture có thể lặp | Patch hiện có mép trắng/lượn, hoa lớn, chồng lên nhau thấy rõ |
| terrain_dirt_fill | Đất kem phẳng, không đá/sỏi lớn | Patch hiện tại lặp motif mạnh |
| terrain_grass_dirt_transition_a | Viền cỏ–đất mềm, cong nhẹ hướng thứ nhất | Chưa có module chuyển tiếp riêng |
| terrain_grass_dirt_transition_b | Viền hướng còn lại, cùng tỷ lệ | Chưa có; có thể dùng biến đổi trong engine nếu phù hợp |
| terrain_path_curve | Góc đường cong rộng và mềm | Chưa có module đường cong |
| terrain_path_fork | Chạc đường dẫn sang khu bí mật | Hiện chỉ chồng các patch đường |

Texture fill cần kiểm tra khả năng lặp sau tách. Curve/fork là overlay alpha để giữ quyền chỉnh đường; không vẽ nguyên map vào sprite.

### Batch B — vách núi và cao độ, 3×2: 6 subimages, ưu tiên cao

| Tên đề xuất | Nội dung | Trạng thái |
|---|---|---|
| cliff_tall_a | Vách đá cao tím xám, mép cỏ trên, một hướng mặt trước | Thay/bổ sung cliff_wall ngắn |
| cliff_tall_b | Vách cao mặt bên còn lại, khớp A | Thiếu biến thể ghép phù hợp |
| cliff_outer_corner | Góc lồi cao khớp A/B | Có cliff_corner_ledge thấp nhưng chưa được đặt trong world |
| cliff_inner_corner | Góc lõm, hốc sườn núi | Chưa có |
| cliff_terrace_connector | Bậc/vai núi nối hai tầng, có mặt trên đủ rộng | Chưa có |
| cliff_grass_rim | Mép cỏ–đá mỏng chạy dọc bờ, ghép lặp | Chưa có module riêng |

Các module phải dùng chung độ cao, điểm nối, phối cảnh và ánh sáng. Cao độ đi lại vẫn cần logic/collision và layout trong Godot.

### Batch C — nước và hậu cảnh, 3×2: 6 subimages

| Tên đề xuất | Nội dung | Trạng thái |
|---|---|---|
| waterfall_long | Dải nước rơi dài, tách khỏi tảng đá | Có waterfall ngắn gắn sẵn đá; chưa đáp ứng thác cao concept |
| waterfall_crest | Miệng nước tràn qua mép núi | Chưa có riêng |
| waterfall_mist | Bọt/sương chân thác | Có bọt trong waterfall, thiếu phần độc lập để kéo dài |
| cloud_bank | Cụm mây/sương lớn alpha, che chân đảo | Chưa có sprite độc lập |
| distant_mountain_layer | Dãy núi xanh nhạt rộng, không hình huy hiệu/khung bo | Thay/bổ sung bg_distant_mountains hiện có |
| stream_extension | Đoạn suối nối được vào miệng thác, hai đầu mở | Có stream_water dạng tiểu cảnh đóng kín |

### Batch D — kiến trúc và khung hang, 3×2: 6 subimages

Đây chủ yếu là thay thế đúng hình dáng, không phải thiếu loại đối tượng.

| Tên đề xuất | Nội dung | Lý do |
|---|---|---|
| hut_main_concept | Nhà lớn mái vàng phẳng từng tấm, sàn nâng, hiên/bậc trước | Nhà hiện tại là mái rơm, khác concept |
| hut_small_concept | Nhà nhỏ cùng hệ mái/hiên | Thay hut_small để đồng bộ |
| cave_back_wide | Vách sau hang thấp, rộng; lòng hang tối, mặt đá ít viền | cave_back_wall có nhưng bị phóng lớn, lấn sân |
| cave_front_rim | Dãy đá thấp ôm mép sân phía trước | Hiện dùng rock_cluster rời, chưa có viền sân riêng |
| cave_floor_fill | Sàn lát tím xám, đá nhỏ vừa, ghép liền | Patch hiện tại mảng đá quá lớn và màu sáng |
| cave_stairs_wide | Bậc đá thấp, rộng, khớp nền sân và góc nhìn | stairs_stone có nhưng kiểu khối vuông/viền đậm |

### Batch E — dấu hiệu và chi tiết nhỏ, 3×2: 6 subimages, làm sau địa hình

| Tên đề xuất | Nội dung | Trạng thái |
|---|---|---|
| flower_daisy_cluster | Cụm hoa trắng nhỏ, ít bông | Hoa đang gộp trong ground_grass_patch/grass_tuft, chưa có sprite độc lập |
| petal_scatter | Cánh hoa hồng rải thưa quanh cây/rương | Chưa có |
| quest_bubble_available | Bong bóng vàng chứa ! | Hiện có ký tự ! bằng Label, thiếu hình bong bóng |
| enemy_alert_marks | 2–3 tia tam giác vàng báo phát hiện | Chưa có như ảnh chiến đấu |
| chest_reward_rays | Tia sáng vàng sau rương còn đóng | chest_open có sáng bên trong; chưa có tia độc lập cho rương đóng |
| dash_dust | Bụi trắng/kem phía sau chân khi lướt | Có vệt tích hợp trong hero_dash và đường trắng code; thiếu bụi tách riêng |

Không cần sinh thêm dấu ? hoặc glow đào bằng AI: có thể dựng từ UI/particle/material. fx_portal_glow đã có nhưng chưa được tham chiếu trong code gameplay; ưu tiên tận dụng.

## B. Đã có, không cần tạo lại để đủ nội dung

- Hero, trưởng lão, lợn rừng, boss; thêm NPC guide và imp ngoài những đối tượng nổi bật trong concept.
- Cây đào, cây xanh, bụi, cỏ có hoa, đá lớn, sỏi.
- Nhà lớn/nhỏ, hàng rào, cột đèn, cầu, suối, thác, vách đá, góc vách, vách hang, bậc đá.
- Đĩa spawn, đào nhặt, rương đóng/mở, cổng khóa/mở, đồng tiền.
- FX chém gậy, boss đập đất, glow cổng.
- Hero idle/run/attack/dash: mỗi trạng thái 2 ảnh. Boar và boss có ảnh attack.

Nếu chỉ cần đủ đối tượng gameplay, các món trên không thiếu. Nếu cần giống phong cách concept, có thể thay lần lượt cây/nhân vật/đá/props bằng phiên bản ít viền; đây là đổi art direction, không gọi là asset mới còn thiếu.

## C. Những việc cần sửa ở Godot hoặc khâu tách ảnh

1. Cỏ và đất đang đóng dấu nhiều patch có mép sáng, tạo hiệu ứng vảy/bánh quy. Sửa masking, ghép nền và tần suất lặp cùng batch A.
2. Layout hiện đi trên một cao độ. Concept có sườn núi, tầng đá và thác dài. Cần thiết kế lại mặt trên, che khuất và collision trước khi đặt batch B.
3. Hậu cảnh chỉ phủ ở tuyến trên, nhiều góc chơi lộ nền xanh trống. Cần bố trí layer theo camera và mây quanh đảo.
4. Hang bị phóng lớn và tròn như vành tường; sàn sân nhỏ, cổng như đặt nổi trên đá. Cần chỉnh scale, offset, vị trí sàn/cổng/bậc và thứ tự lớp. Hai đuốc hiện lệch theo đường chéo, chưa tạo hai bên cửa cân đối như concept.
5. Nhà/cây lớn tương đối so với nhân vật; concept cận cảnh để hero/NPC nổi bật hơn. Chỉnh camera và tỷ lệ trước khi quyết định vẽ lại nhân vật.
6. Cây và bụi còn thưa quanh mép bãi quái. Tăng số lượng/đặt có chủ đích bằng asset có sẵn; không cần tạo một loại cây cho mỗi vị trí.
7. Cầu và suối hiện là một tiểu cảnh nhỏ, chưa tạo cảm giác bắc qua khe núi. Cần đặt đúng đường nối và mép vực.
8. Một số sprite animation/combat có mảnh hình thừa: nhìn thấy ở hero_attack_1, hero_dash_2, enemy_boar_attack, enemy_imp; fx_boss_slam có mảnh ở phía trên. Rà lại cell crop/connected components trên sheet gốc. Chỉ tạo lại khi phần hình chính bị cắt mất hoặc bị ô khác đè lên.
9. cliff_corner_ledge, tile_grass/tile_dirt/tile_cave_stone, player_hero, npc_guide, gold_coin và fx_portal_glow tồn tại nhưng không thấy đường dùng tương ứng trong gameplay hiện tại (hero dùng bộ hero_idle; NPC layout chỉ có elder). Không coi chúng là thiếu.
10. Cổng mở và rương phần thưởng có logic hiện/đổi trạng thái; ảnh runtime chụp hang đang trước thắng boss nên không thấy rương là đúng điều kiện, không phải thiếu PNG.

## D. Animation: chỉ mở rộng khi cần

Concept là ảnh tĩnh, không đủ căn cứ yêu cầu một bộ animation đầy đủ. Nếu mục tiêu là hoàn thiện cảm giác chơi, còn có thể bổ sung hướng nhìn lưng/chéo, chu kỳ đi quái, hit/death và chuyển động nước/lửa. Đây là backlog polish, không tính vào 30 subimages đề xuất để khớp cảnh.

## Quy chuẩn giao batch

- Mỗi batch một sheet 3×2, 6 ô bằng nhau, thứ tự trái sang phải rồi trên xuống dưới đúng bảng; không chữ/nhãn/grid vẽ vào hình.
- Đề xuất sheet 3072×2048, mỗi ô 1024×1024; đây là kích thước nguồn, sẽ scale khi tích hợp. Chừa biên an toàn tối thiểu 80px quanh sprite, không để hình sang ô bên cạnh.
- PNG alpha thật cho props/overlay. Fill texture là bề mặt kín; không thêm đường viền quanh mép tile. Giữ mô tả đầu nối và mép ghép nhất quán.
- Cùng 2.5D isometric như ảnh tham chiếu, ánh sáng trên trái, khối đơn giản pastel, viền mềm hoặc rất mảnh; không viền đen dày, không texture phức tạp.
- Nhân vật/props lấy chân làm pivot; nền/sàn lấy tâm mặt trên; vách đánh dấu pivot và đường nối trong manifest đi kèm, không ghi chữ lên sprite.
- Không gộp glow, bụi hoặc mây vào props nếu cần điều khiển riêng. Không gộp cây/rương vào terrain.
- Xong A thì tách, ráp và kiểm tra trước khi làm B; tiếp tục B → C → D → E. 30 subimages là bộ đề xuất đầy đủ ở mức module; ưu tiên 12 của A+B trước.

## Ảnh kiểm tra

- current-village.png: làng hiện tại.
- current-forest.png: rừng đào và nhánh rương.
- current-clearing.png: bãi quái.
- current-cave.png: hang trước khi thắng boss.
- existing-assets.png: contact sheet 51 PNG đã tách.
