# Cloudbound — Semantic World & Segmentation Rules

Áp dụng cho mọi công việc mới về concept scene, segmentation, semantic blueprint, placement và integration. Quy tắc này bổ sung AGENTS.md. Mục tiêu là thế giới chơi được và nhãn màu nhất quán, không phải chỉ tạo ảnh đẹp.

## 0. Mặc định mới: segmentation cơ bản, không dựng cảnh chi tiết

Khi người dùng yêu cầu tạo lại scene, scene map hoặc segmentation mà không yêu cầu minh họa chi tiết, ưu tiên **bản đồ kế hoạch semantic 2D phẳng**. Không tự động tạo thêm concept 2.5D, sheet nhiều ô hoặc toàn bộ thế giới.

**Giới hạn mặc định:**

- Tối đa 2 vùng gameplay: một vùng bắt đầu/quảng trường và một vùng đích/rừng. Chúng chỉ là vùng chức năng; không thêm màu class riêng cho mỗi vùng.
- Một mặt đất liên tục, một đường nối rộng và đơn giản; không nhánh phụ, cầu, nước, vách, thác hoặc tầng cao ở vòng đầu.
- Tối đa 2 footprint nhà và 2 footprint cây. Ít hơn được phép. Mỗi object chỉ là một hình học đơn giản, tách biệt, một màu.
- Tối đa 5 class: background `#B8D4E3`, grass `#8FCB74`, path `#E8C88F`, building `#D88C45`, tree_green `#438F52`. Giữ nguyên ID registry; không đánh số lại từ 0 cho subset.
- Giữ ít nhất 70% diện tích mặt đất không bị footprint tĩnh chiếm. Đây là kiểm tra độ thoáng, không thay thế kiểm tra kết nối/clearance.
- Không vẽ nhân vật, NPC, pickup, spawn icon, cổng, đá, hoa, UI, legend hoặc chữ trên ảnh nhãn. Spawn/goal và tương tác được ghi bằng tọa độ/metadata hoặc review overlay riêng.

**Quy ước biểu diễn:** góc nhìn overhead 2D phẳng để đọc mặt bằng. Nhà là footprint hình chữ nhật, cây là footprint hình tròn; không mái, thân, tán, hiên, bậc, phối cảnh khối hoặc extrusion. Đây là `semantic_plan`, không phải visible segmentation của một ảnh minh họa. Không dùng footprint tròn này làm silhouette tán cây khi adapt. Camera/game art 2.5D của Godot vẫn giữ nguyên; khi chuyển từ plan sang hình chiếu phải khai báo transform rõ.

**Cấm ở giai đoạn cơ bản:** gradient, bóng, texture, bevel, outline trang trí, anti-alias trong label chuẩn, chi tiết kiến trúc, cảnh nền, nhiều panel, sprite sheet, nhiều biến thể trong một ảnh. Dùng mảng màu kín và ranh giới đơn giản.

**Điều kiện nâng mức chi tiết:** chỉ thêm class, vật thể hoặc concept minh họa sau yêu cầu rõ của người dùng và sau khi layout cơ bản đã được kiểm tra. Không kế thừa mặc định “3 nhà, 4 cây đào, NPC và vật phẩm” từ prompt v2/v3 trước đây.

Ảnh do AI tạo theo prompt chỉ là bản đề xuất. Trước khi dùng làm mask chuẩn: chuẩn hóa màu/geometry bằng công cụ quyết định được ID, kiểm tra rồi mới adapt. Việc đưa mã hex vào prompt không bảo đảm output đúng RGB hoặc có đường đi hợp lệ.

## 1. Gameplay và quan hệ không gian trước

1. Chốt spawn, điểm đến và tuyến nối trước khi đặt nhà/cây/đá. Mỗi khu vực phải có lối vào/ra có chức năng; nhánh phụ phải nối vào tuyến chính.
2. Dành một **hành lang bảo vệ** quanh đường đi. Vật cản không được đè lên hành lang này. Kiểm tra hai loại độc lập:
   - Footprint/collider thực trên mặt đất.
   - Toàn bộ visual envelope: mái, hiên, bậc, tán cây, thân, đá. Không được có kiểu collision thông nhưng mái nhà che mất đoạn nối quan trọng.
3. Nhà nằm ở rìa quảng trường, cửa hướng về vùng tiếp cận rõ. Không đặt nhà tại cổ chai giữa quảng trường và đường rừng. Lưu điểm cửa và kiểm tra điểm đó tiếp cận được.
4. Cây/đá đặt ngoài tuyến chính; pickup đặt bên chân cây, tách khỏi trunk collider và tán che. NPC phải có vùng đứng/tương tác tiếp cận được.
5. Footprint phải nằm hoàn toàn trên mặt đất phù hợp, không lơ lửng trên vực/nước. Không dùng tán cây hoặc mái nhà làm footprint.
6. Chỉ dùng cầu khi có hai đầu tiếp đất và một vùng cần vượt qua. Thác phải nối được với miệng nước và mép vách; không thêm chỉ để lấp chỗ trống.
7. Tầng cao phải có ID và kết nối riêng. Height metadata không tự chứng minh có gameplay nhiều tầng. Nếu chưa có cơ chế đó, ghi rõ mặt đi hiện là một plane 2D.
8. Đo hành lang theo kích thước nhân vật, không theo cảm giác. Với v3: agent radius 20px; đường 120px; vùng bảo vệ 160px. Khi đổi tỷ lệ phải scale tất cả đồng bộ, không dùng các số này như hằng số cho mọi map.

## 2. Một registry màu semantic duy nhất

Nguồn chuẩn: `assets/blueprints/semantic_palette.json` (schema v1).

| ID | Class | Màu RGB chính xác |
|---|---|---|
| 0 | unknown / chưa annotate | #FF00FF |
| 1 | background | #B8D4E3 |
| 2 | grass | #8FCB74 |
| 3 | path / quảng trường đất | #E8C88F |
| 4 | water | #5DBDDD |
| 5 | cliff | #8B819B |
| 6 | building | #D88C45 |
| 7 | tree_green | #438F52 |
| 8 | tree_peach | #F28FB0 |
| 9 | rock | #8A94A6 |
| 10 | spawn | #B5BCC6 |
| 11 | npc | #8D5C42 |
| 12 | player | #E5B64F |
| 13 | pickup | #FFB86B |
| 14 | bridge | #96714B |
| 15 | gate | #845CB8 |

- Cùng class luôn cùng ID/màu, giữa mọi vùng/map/batch mới. Không lấy màu trực tiếp từ ảnh minh họa để tự định nghĩa lại nhãn.
- Nhà có mái vàng/thân nâu trong concept nhưng toàn bộ nhà là một màu `building` trong label map. Phong cách/palette mỹ thuật và palette nhãn semantic là hai dữ liệu khác nhau.
- Label map phải là PNG opaque, màu RGB nguyên, không anti-alias, bóng, gradient, texture, chữ, viền trang trí hoặc alpha bán trong suốt. Không lưu JPEG; resize mask chỉ bằng nearest-neighbor.
- Không dùng màu tuyến debug, chữ hoặc legend lên file nhãn chuẩn. Xuất overlay/legend thành ảnh review riêng.
- Màu 0 có nghĩa chưa biết/chưa annotate, không có nghĩa background. Không tự gán vùng khuất hoặc ngoài phạm vi là trời.
- Không đổi ID cũ hoặc tái dùng màu cho nghĩa khác. Nếu cần class mới: bổ sung registry có version và cập nhật validator. Không phụ thuộc thứ tự key của dictionary để ánh xạ màu.
- Các artifact legacy ở `segmentation_slice` dùng mã cũ; không trộn với dataset v3. Khi tái tạo hoặc nhập chúng vào pipeline mới phải migrate sang registry này.

## 3. Tách các lớp dữ liệu

Mọi lớp cùng kích thước, gốc tọa độ và transform pixel → world:

- **Surface/amodal map:** cỏ, đất, nước, vách, background; phần đất khuất được ghi rõ là suy dựng.
- **Visible semantic map:** lớp đang nhìn thấy của từng pixel; không dùng nó để suy ra toàn bộ collision.
- **Instance map:** ID riêng cho từng đối tượng, cùng class được phép có nhiều instance. ID instance không phải ID class.
- **Footprints/collision:** chỉ phần cản trên mặt đất, không phải silhouette.
- **Walkability:** mặt đất có thể đi trừ footprint; kiểm tra sau khi tính bán kính nhân vật.
- **Height:** tầng cao và kết nối; độc lập với thứ tự vẽ.
- **Protected route:** mask riêng kiểm tra độ thông và khả năng nhìn đường.
- **Blueprint:** geometry, anchor chân, visual envelope gồm cả bậc/hiên, footprint, cửa, scale, level, role và provenance. Giữ được nền phía sau object; không đè hết dữ liệu vào một ảnh màu.

Bóng không phải object/collider mới. Cùng một pixel có thể là nước ở surface map, cầu ở visible map và đi được ở gameplay layer. Không ép mọi nghĩa vào một lớp ghi đè.

## 4. Quy trình bắt buộc

1. Chốt scope, nguồn ảnh, góc camera, tỷ lệ, class registry và core loop. Nếu không có yêu cầu khác, dùng giới hạn segmentation cơ bản ở mục 0.
2. Dựng topology/đường đi và vùng mặt đất đơn giản; đặt hành lang bảo vệ.
3. Đặt object theo chức năng, anchor chân, footprint và visual envelope. Giữ khoảng trống để đi và tương tác.
4. Render semantic map theo registry bằng công cụ quyết định được màu/ID. **Không dùng output ImageGen làm label mask RGB chuẩn trực tiếp.**
5. Validate geometry, màu và gameplay connectivity. Chỉ coi đạt khi không còn lỗi.
6. Chỉ tạo concept minh họa nếu người dùng yêu cầu; dùng blueprint đã qua kiểm tra làm bố cục đầu vào. Prompt phải cấm nhà/mái/bậc/tán cây chiếm hành lang bảo vệ.
7. Kiểm tra ảnh sinh thực tế. Nếu object thay vị trí/kích thước hoặc thêm đồ: sửa ảnh, hoặc cập nhật annotation/blueprint và chạy lại validator. Không gọi một mask kế hoạch là segmentation pixel chính xác của ảnh sinh.
8. Sau đó mới tạo asset theo batch, ráp Godot, đối chiếu ảnh chạy thật và chơi thử. Mỗi lần thay asset/scale làm đổi visual envelope phải kiểm tra lại.

Với concept nhiều ô: một góc tổng quan xác định tọa độ; góc cận cảnh hướng dẫn hình dáng/tỷ lệ. Không gộp các ô khác phối cảnh vào một mặt bằng.

## 5. Điều kiện đạt

- Tất cả màu nhãn thuộc registry; `RGB == LUT[class_id]` cho mọi pixel.
- Mọi class/instance ID hợp lệ, instance không trùng, mọi lớp cùng resolution.
- Spawn và đích thuộc cùng thành phần đi được sau khi erode theo bán kính agent.
- Toàn bộ centerline đi được, hành lang bảo vệ không chạm collider hoặc visual envelope của vật cản.
- Cửa nhà, NPC và pickup đều tiếp cận được; footprint không ra ngoài đất.
- Chụp kiểm tra không cho thấy nhà chắn cổ chai, mái/tán che điểm tương tác hoặc asset nổi trên nền sai chức năng.
- Khi đổi scope/resolution/scale: kiểm tra lại tất cả; không kế thừa báo cáo PASS cũ.
- Báo cáo phân biệt rõ: trace thủ công, suy dựng vùng khuất, segmentation tự động, concept minh họa và dữ liệu đã kiểm thử trong engine. Không phóng đại độ chính xác.

## 6. Công cụ tham chiếu v3 (legacy, không phải độ phức tạp mặc định)

Bộ v3 gồm 17 object và nhiều class hơn giới hạn cơ bản. Giữ để tham khảo/kiểm tra lại bản cũ; không chạy builder v3 như mặc định cho một yêu cầu tạo scene mới đơn giản. Prompt cơ bản hiện hành: `docs/prompts/BASIC_SEGMENTATION_SCENE.md`.

- Dựng lại riêng bản v3: `python3 scripts/tools/build_semantic_world.py`
- Sau khi chỉnh `layout.json` trực tiếp: thêm `--render-only` để không ghi đè geometry.
- Kiểm tra: `python3 scripts/tools/validate_semantic_world.py`
- Kết quả: `assets/blueprints/semantic_world_v3/validation.json`

Validator v3 chứng minh các điều kiện trên **bản đồ kế hoạch**. Nó không tự kiểm tra silhouette trong concept AI, nhận phím OS hoặc toàn bộ gameplay trong Godot.
