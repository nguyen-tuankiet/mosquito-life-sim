# Mosquito: Life Cycle (Godot 4)

Game sinh tồn 3D: bạn điều khiển cả một **dòng họ muỗi** qua nhiều thế hệ.
Trứng → Lăng quăng → Nhộng → Muỗi trưởng thành → Giao phối → Đẻ trứng → Thế hệ tiếp theo.

## Chạy game
- Bấm đúp **`start.bat`** (cần Godot 4.7 — cài bằng `winget install GodotEngine.GodotEngine`), hoặc mở thư mục này bằng Godot rồi nhấn F5.

## Mở đầu
Game bắt đầu bằng một **story giới thiệu** (~70 giây): 9 tranh minh họa (trứng → lăng quăng → nhộng → muỗi trưởng thành → đực/cái → giao phối → đẻ trứng → vòng đời khép kín), zoom chậm, rồi infographic tổng quát và nút Bắt đầu. Click/Enter để bỏ qua. Mã vẽ tranh nằm ở `tools/illus/` (Python + Pillow/numpy): `python tools/illus/scenes.py <thư mục>`.

## Điều khiển
| Phím | Tác dụng |
|---|---|
| Chuột (click để khóa chuột, Esc để nhả) / phím mũi tên | Xoay hướng nhìn |
| W A S D | Bơi / bay theo hướng nhìn |
| Space / Shift | Lên / xuống |
| E | Hành động: quẫy nước, bám nhộng, hút mật hoa, giao phối, đẻ trứng |
| **Chuột phải** (hoặc Q) | **Hút máu:** bay lại gần và ngắm chấm tâm vào cơ thể người/thú (chấm chuyển sang màu đỏ), GIỮ chuột phải để muỗi tự bay tới đậu và hút; THẢ ra để tự rút lui khỏi tầm đập |
| M / P | Tắt âm / Tạm dừng |

## Luật chơi chính
- Muỗi cái phải hút máu để **không chết đói**, nhưng người sinh hoạt theo đồng hồ trong nhà sẽ phát hiện và **đập** bạn.
- Dấu hiệu bị phát hiện: dấu ? (nghi ngờ, họ quay đầu nhìn muỗi) → dấu ! (khó chịu, đưa tay lên gãi) → ĐẬP! (giơ tay cao, có vùng đỏ và đếm ngược). Thả chuột phải ngay để muỗi tự bay lên chỗ an toàn.
- Người ngủ khó phát hiện hơn; người xem TV ít chú ý; người đang đi lại hoặc chơi đùa rất tinh mắt. Bay sát trần nhà là an toàn với người lớn.
- Chết là chết luôn: vòng đời kết thúc và bạn bắt đầu vòng đời mới từ quả trứng (Enter).
- Lịch vòng đời thực tế (nén thời gian): 1 ngày dưới nước = 18 giây, 1 ngày trưởng thành = 75 giây. Trứng ngày 1–2, lăng quăng ngày 3–7 (4 tuổi), nhộng ngày 8–9, vũ hóa ngày 10. Muỗi cái: giao phối ngày 10, tìm máu & hút máu ngày 11, tiêu hóa ngày 12, đẻ trứng ngày 13. Mỗi ngày mở thêm nhiệm vụ mới; nhiệm vụ hoàn thành sẽ đẩy thanh lớn lên.
- Muỗi no máu bay chậm hơn; nhấn E gần bụi cây/tường/trần để đậu nghỉ tiêu hóa.
- Bản đồ là một **làng quê Việt Nam** 500 × 540 m (map thật trong `world/generated/`, theo `docs/MAP_BIBLE.md`): (1) nhà dân, (2) vườn cây / chuồng trại, (3) ao / hồ, (4) ruộng lúa, (5) kênh mương, (6) rừng tre / bụi rậm, (7) đồng cỏ, (8) đường làng. Mini map góc trái dưới vẽ cả làng, đánh số các khu vực và nhấp nháy **chặng hành trình kế tiếp**.
- **Hành trình 1 → 8:** bay vào khu vực kế tiếp theo thứ tự để được tính thêm một nhiệm vụ (thêm trứng) và xem thông tin về muỗi ở khu đó. Tiến độ giữ qua các thế hệ của dòng họ.
- Làng rộng: **bay cao (Space) để bay nhanh hơn** (tới 6,5 m/s khi cao ≥ 7,5 m), nhưng chuồn chuồn ở ao, ruộng, kênh, đồng cỏ săn muỗi; bay thấp trong rừng tre để ẩn.
- **Người dân sống theo lịch** (≈ 29 người ở 17 nhà): sáng ra đồng / ra chợ / ra ao / đi học, trưa về nhà nghỉ, chiều đi làm tiếp, chạng vạng (18–21h) ngồi hóng mát trước sân — lúc dễ hút máu nhất; đêm ở trong nhà. Đến gần sẽ thấy nhãn việc đang làm.
- **NPC nói chuyện kiểu miền Tây** (bong bóng thoại trên đầu, xem `docs/DIALOGUE.md`): người làng nói chuyện đời thường theo việc đang làm, hàng xóm hỏi han nhau; khi bị muỗi làm phiền thì tuỳ tính cách — gãi, đập, chửi vui ("Má nó, chích gì chích dữ vậy!") hoặc mặc kệ.
- Người & vật nuôi theo khu vực: gia đình trong nhà, gà ngoài sân, lợn trong vườn, trâu + bác nông dân ngoài ruộng, người qua đường trên đường làng (hai người này chỉ ra ngoài ban ngày).
- 6 nguồn nước đẻ trứng: vũng nước mưa, xô, chum nước, ao làng, kênh mương, ruộng lúa → môi trường dưới nước ở thế hệ sau khác nhau. Muỗi luôn vũ hóa ngoài trời, tại đúng nguồn nước nơi nó lớn lên.
- Chuyển giai đoạn mô phỏng đời thực: trứng nở (vỏ rỗng còn nổi), lột xác (xác lột trôi đi), hóa nhộng, vũ hóa (vỏ nhộng nổi trên mặt nước, cánh nhăn nở dần khi hong khô).

## Map làng (M4)
- Giai đoạn trưởng thành nạp map từ `world/generated/` (sinh bởi `blender/scripts/generate_map.py --stage env --swap --godot`, đã commit sẵn). Không có thư mục này thì game tự dùng thế giới nén cũ quanh nhà; ép dùng thế giới cũ: `-- --legacy-world`.
- `world/village_map.gd` dùng chung cho game và `world/greybox_viewer.tscn` (xem map, F6).

## Asset
Toàn bộ model/texture dùng giấy phép **CC0** (Quaternius, Kenney, Poly Haven) — xem `assets/CREDITS.md`.

## Kiểm thử tự động (tùy chọn)
```
godot --headless --fixed-fps 60 --path . --quit-after 14000 -- --scenario=auto
godot --headless --fixed-fps 60 --path . --quit-after 1500 -- --scenario=test_rules
godot --headless --fixed-fps 60 --path . --quit-after 300 -- --scenario=test_village   # M4: map làng trong game
godot --headless --fixed-fps 60 --path . --quit-after 300 -- --scenario=test_talk      # thoại NPC miền Tây
godot --path . --fixed-fps 60 -- --scenario=adult_v_jar --shot=jar.png --frames=30          # ảnh: jar yard pond paddy road bamboo canal night high
```
