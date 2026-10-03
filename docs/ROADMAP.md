# ROADMAP — Map làng quê: từ ảnh reference tới game

Không cố làm "100% ảnh" ngay. Đi theo 5 milestone, **mỗi milestone phải được xác nhận rồi mới sang bước sau.**

## Quy trình bắt buộc

```
ẢNH REFERENCE (docs/reference/visual/master_reference.webp)
       ↓
MAP_BIBLE (docs/MAP_BIBLE.md + docs/map_spec.json)
       ↓
2D BLOCKOUT ……………… M0   python blender/scripts/blockout_2d.py
       ↓
3D GREYBOX ………………… M1   generate_map.py --stage greybox --godot  → godot/world/greybox_viewer.tscn
       ↓
XÁC NHẬN GIỐNG  ◀── cổng: người duyệt ký vào bảng "Xác nhận" bên dưới
       ↓
TẢI / TẠO ASSET ……… theo asset sheet (docs/ASSET_GUIDELINES.md §6), P0 trước
       ↓
REPLACE ASSET ……………… M2   generate_map.py --stage env --swap --godot
```

Tải asset trước dễ dẫn tới *"có model đẹp → cố nhét model vào map"*. Đúng phải là
*"map đúng concept → tìm model phù hợp với map"*. Vì vậy `generate_map.py` **từ chối `--swap` ở stage greybox**.

## Milestones

### M0 — 2D Map · *phải giống BỐ CỤC*

ảnh reference → top-down map.

- [x] `docs/reference/layout/00_blockout_2d.png` — toàn map, 8 zone, đường, nước, nhà, rào, landmark, điểm đẻ trứng
- [x] `01_house.png` … `08_road.png` — Reference B, mỗi zone 1 sheet (khung, kích thước, nội dung)
- [ ] **Xác nhận**: đặt `00_blockout_2d.png` cạnh minimap của ảnh reference — vị trí tương đối 8 zone, hình chữ S của
      kênh, cụm nhà Đông-Bắc, ruộng Đông, đồng cỏ Đông-Nam, rừng tre Tây phải khớp

Tạo lại: `python blender/scripts/blockout_2d.py` (cần numpy + Pillow; không cần Blender).

### M1 — 3D Greybox · *phải giống LAYOUT*

terrain · water · road · 8 zones (+ placeholder nhà/rào/landmark, spawn, camera bounds).

- [x] Script: `blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot`
      → `blender/master_map.blend`, `blender/exports/vietnamese_rural_village_greybox.glb`, `map_layout.json`
- [x] Godot: mở `godot/world/greybox_viewer.tscn` → F6. Phím 1–8 bay tới từng zone, 0 = toàn cảnh, Tab = nhãn
- [ ] **Xác nhận**: đi một vòng theo hành trình (1 → 8): tỉ lệ nhà/đường/ao/ruộng hợp lý ở góc nhìn người và muỗi,
      không có vật thể chìm/lơ lửng, đường đi liền mạch, mặt nước đúng cao độ

### M2 — Environment · *phải giống VISUAL*

house · trees · rice · bamboo · pond · canal.

- [ ] Làm/tải asset **P0** (34 asset) theo `docs/ASSET_GUIDELINES.md §6`, cleanup theo §4
- [ ] `generate_map.py --stage env --swap --godot` (thực vật procedural + thay placeholder)
- [ ] Godot: MultiMesh cho cỏ/lúa/tre đọc `map_points.json`
- [ ] **Xác nhận**: dựng lại key shot (sân H01 nhìn ra ao/ruộng) + 8 postcard shot, đặt cạnh ảnh reference

### M3 — Cinematic · *phải giống MOOD*

sunlight · fog · water · shadows · vegetation · color grading.

- [ ] Nắng giờ vàng + đêm trăng theo `docs/ART_DIRECTION.md §2`; chu kỳ ngày–đêm nối với đồng hồ game (75 s/ngày)
- [ ] Sương xa, shader nước (ao tĩnh / kênh chảy / ruộng nông / vũng), bóng đổ, gió lay tre-chuối-lúa
- [ ] Color grading khớp bảng màu §3; asset P1
- [ ] **Xác nhận**: so ảnh chụp game với ảnh reference ngày + đêm

### M4 — Gameplay · *lúc này mới thành game*

mosquito · larva · pupa · predators · food · egg laying · quests.

- [ ] Nối `SITES` trong `godot/scripts/game.gd` sang toạ độ chuẩn (MAP_BIBLE §11.1, `EggSite_*` trong `map_layout.json`)
- [ ] Spawn tại `PlayerSpawn_FirstLife` (chum W03), giới hạn bay theo `CameraBounds_*`
- [ ] Người/vật nuôi theo zone (§13), kẻ thù dưới nước theo loại nước (§6), nhiệm vụ theo hành trình 1 → 8

## Xác nhận

| Milestone | Ngày | Người duyệt | Kết quả / ghi chú |
|---|---|---|---|
| M0 2D Blockout | | | |
| M1 3D Greybox | | | |
| M2 Environment | | | |
| M3 Cinematic | | | |
| M4 Gameplay | | | |
