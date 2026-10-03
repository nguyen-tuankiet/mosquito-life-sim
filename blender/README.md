# blender/ — sinh map bằng script (Blender → GLB → Godot)

Nguồn sự thật: [`docs/MAP_BIBLE.md`](../docs/MAP_BIBLE.md) → bản số [`docs/map_spec.json`](../docs/map_spec.json).
Script **không tự nghĩ ra bố cục**: mọi toạ độ, kích thước, luật đặt vật thể đều đọc từ `map_spec.json`.
Thứ tự làm việc theo milestone: [`docs/ROADMAP.md`](../docs/ROADMAP.md).

```
blender/
├── master_map.blend      ← SINH RA bởi generate_map.py (gitignore, không sửa tay — sửa Bible rồi chạy lại)
├── exports/              ← GLB + JSON cho Godot (gitignore)
└── scripts/
    ├── common.py             hệ toạ độ, mask luật Bible, tiện ích Blender
    ├── blockout_2d.py        M0: 2D blockout + 8 sheet layout (numpy + Pillow, không cần Blender)
    ├── generate_map.py       entry point (--stage greybox | env)
    ├── generate_terrain.py   Terrain: lưới cao độ, màu đỉnh theo zone
    ├── generate_water.py     Canal, Pond, nước ruộng, vũng mưa, EggSite_*
    ├── generate_village.py   Road, Bridge, HousePoint_* (+HOUSE_PLACEHOLDER), FencePoint_*, Jar/Bucket/Basin/TirePoint,
    │                         LandmarkPoint_*, Zone_*, PlayerSpawn, CameraBounds
    ├── generate_foliage.py   Forest (tre), Grassland, lúa, sậy, cây… procedural, seed cố định (chỉ stage env)
    ├── swap_assets.py        placeholder → .glb thật theo assets/asset_manifest.json (chỉ stage env)
    ├── check_greybox.py      M1: kiểm tra tự động (chìm/lơ lửng, nền nhà, đường, mặt nước, bounds)
    └── render_views.py       ảnh duyệt 3D bằng Cycles CPU (toàn cảnh, 8 zone, key shot, tầm muỗi)
```

## Chạy

```bash
# M0 — 2D blockout (docs/reference/layout/*.png)
python blender/scripts/blockout_2d.py

# M1 — 3D greybox → blender/master_map.blend + exports/*_greybox.glb, copy sang godot/world/generated/
blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot

# Duyệt M1 không cần Godot/GPU: kiểm tra tự động + ảnh 3D → docs/reference/greybox/
python blender/scripts/check_greybox.py --report docs/reference/greybox/M1_check.md
python blender/scripts/render_views.py

# M2 — environment (CHỈ sau khi M1 được xác nhận) → thực vật procedural + thay model thật
blender -b -P blender/scripts/generate_map.py -- --stage env --swap --godot
```

Không cài Blender: `pip install bpy numpy` (Python 3.11) rồi `python blender/scripts/generate_map.py --stage greybox --godot`.
Blender 4.2+ (đã test với Blender 5.0).

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `--stage` | `greybox` | `greybox` (M1) hoặc `env` (M2) |
| `--godot` | tắt | Copy GLB + JSON sang `godot/world/generated/` |
| `--swap` | tắt | Thay placeholder bằng model thật — **chỉ** với `--stage env` |
| `--res` | `2` | Độ phân giải lưới địa hình (m) |
| `--strict` | tắt | Dừng nếu spec vi phạm luật Bible |
| `--out`, `--blend` | `blender/exports`, `blender/master_map.blend` | Đổi chỗ lưu |

Xem trong Godot: mở `godot/world/greybox_viewer.tscn` → **F6**. Chuột phải + kéo = nhìn, WASD/Q/E = bay,
Shift = nhanh, **1–8 = bay tới zone**, 0 = toàn cảnh, Tab = nhãn, F = sương. Scene tự nạp `*_env.glb` nếu có, không thì `*_greybox.glb`.

## Kết quả

| File | Nội dung |
|---|---|
| `master_map.blend` | Scene đầy đủ, chia collection: Terrain, Water, Roads, Houses, Fences, Containers, Landmarks, Zones, Gameplay, EggSites (+ Foliage ở env) |
| `exports/vietnamese_rural_village_<stage>.glb` | Cho Godot. Mỗi `*Point` là một node rỗng có `extras` (custom props). Không gồm point-cloud thực vật |
| `exports/map_layout.json` | Mọi empty gốc (Point, EggSite, Zone, Spawn, CameraBounds): vị trí Godot + props |
| `exports/map_points.json` | (env) Point-cloud thực vật, `stride 6 = [x, y, z, rot_y, scale, variant]` → MultiMesh |

Toạ độ: Bible (gốc Tây-Bắc, +z Nam) → Blender `(x−W/2, −(z−D/2), y)` → Godot `(x−W/2, y, z−D/2)`.

## Hệ thống Point → model thật

Mỗi vật thể cần model là một **empty tên cố định**, placeholder là con `<tên>__PH`:

| Point | Sinh ở | Placeholder |
|---|---|---|
| `HousePoint_01…07` | Bible §7 | `HOUSE_PLACEHOLDER`: tường + mái + cửa (mặt trước) |
| `FencePoint_001…` | §8 fence_bamboo (dọc R1, R3) | thanh 3 m |
| `JarPoint_*`, `BucketPoint_*`, `BasinPoint_*`, `TirePoint_*` | §6 egg_sites | trụ |
| `LandmarkPoint_L03…` | §10 | theo loại (cột điện, đống rơm, chòi, cầu ao, thuyền, trâu…) |
| `BridgePoint_B1_R2` | §4 | sàn cầu |
| `TreePoint_*`, `BananaPoint_*`, `CoconutPoint_*` | §8 sparse (env) | nón |
| `BambooPoints`, `GrassPoints`, `RicePoints`… | §8 cloud (env) | proxy trong `ASSET_<Type>` (Geometry Nodes) |

[`assets/asset_manifest.json`](../assets/asset_manifest.json) ánh xạ tên → file, luật đầu tiên khớp thắng:

```json
{"match": "HousePoint_01", "asset": "house_vn_01.glb", "fallback": "house2.glb", "fit": "footprint"},
{"match": "HousePoint_02", "asset": "house_vn_02.glb", "fallback": "house2.glb", "fit": "footprint"},
{"match": "HousePoint_03", "asset": "house_vn_01.glb", "fallback": "house2.glb", "fit": "footprint"}
```

- File được tìm **theo tên, đệ quy** trong `assets/environment`, `assets/props`, `assets/creatures`, rồi mới tới thư viện
  CC0 cũ `godot/assets/models/` (fallback tạm). Không có cả hai → giữ placeholder.
- `fit`: `footprint` (khớp nền nhà/placeholder), `length` (khớp đoạn rào/cầu), `height:<m>`.
- Chạy lại bao nhiêu lần cũng được; trên file có sẵn:
  `blender -b blender/master_map.blend -P blender/scripts/swap_assets.py -- --save --glb`
- `.glb` trong repo nằm trên Git LFS → `git lfs pull` trước, nếu không swap sẽ báo và giữ placeholder.

Danh sách model cần làm, quy chuẩn cleanup, AI 3D vs library: [`docs/ASSET_GUIDELINES.md`](../docs/ASSET_GUIDELINES.md).
