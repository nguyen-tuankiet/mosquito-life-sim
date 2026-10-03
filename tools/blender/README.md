# Pipeline sinh map bằng Blender — Làng quê Việt Nam

Nguồn sự thật: [`docs/MAP_BIBLE.md`](../../docs/MAP_BIBLE.md) → bản máy đọc [`map_spec.json`](map_spec.json).
Script **không tự nghĩ ra bố cục**: mọi toạ độ, kích thước, luật đặt vật thể đều đọc từ `map_spec.json`.

```
docs/MAP_BIBLE.md ──(sửa tay, cùng commit)──▶ map_spec.json
                                                  │
                         generate_map.py ◀────────┘   (kiểm tra luật Bible → ⚠ BIBLE)
                           ├─ generate_terrain.py   Terrain (lưới cao độ, màu zone)
                           ├─ generate_water.py     Canal, Pond, Rice Field water, vũng mưa, EggSite_*
                           ├─ generate_village.py   Road, Bridge, HousePoint_* (+HOUSE_PLACEHOLDER), FencePoint_*,
                           │                        Jar/Bucket/Basin/TirePoint, LandmarkPoint_*, Zone_*, Spawn, Camera
                           └─ generate_foliage.py   Forest (tre), Grassland, lúa, cây… (procedural, seed cố định)
                                                  │
                         swap_assets.py ◀── asset_manifest.json   (placeholder → .glb thật)
                                                  │
                     out/vietnamese_rural_village.{blend,glb} + map_points.json + map_layout.json ──▶ Godot
```

## Chạy

```bash
# Blender 4.2+ (đã test với Blender 5.0)
blender -b -P tools/blender/generate_map.py -- --res 2 --swap

# hoặc không cần cài Blender:  pip install bpy numpy   (Python 3.11)
python tools/blender/generate_map.py --res 2 --swap

# ảnh top-down để so với minimap (cần Pillow, không cần GPU)
python tools/blender/preview_map.py
```

| Tham số | Mặc định | Ý nghĩa |
|---|---|---|
| `--res` | `2` | Độ phân giải lưới địa hình (m). `1` = mịn hơn, nặng gấp 4 |
| `--out` | `tools/blender/out` | Thư mục kết quả (đã gitignore) |
| `--swap` | tắt | Thay placeholder bằng model thật theo `asset_manifest.json` |
| `--no-glb` | — | Không xuất `.glb` |
| `--strict` | tắt | Dừng nếu spec vi phạm luật Bible |

Chạy riêng từng bước (debug): `blender -b -P tools/blender/generate_water.py -- --out /tmp/water.blend`.

Asset `.glb` trong repo nằm trên **Git LFS** → chạy `git lfs pull` trước khi `--swap`, nếu không swap sẽ báo
`⚠ … con trỏ Git LFS chưa tải` và giữ placeholder.

## Kết quả

| File | Nội dung |
|---|---|
| `vietnamese_rural_village.blend` | Scene đầy đủ, chia collection: Terrain, Water, Roads, Houses, Fences, Containers, Landmarks, Foliage, Zones, Gameplay, EggSites |
| `vietnamese_rural_village.glb` | Cho Godot. Gồm mọi thứ trừ point-cloud thực vật. Mỗi `*Point` là một node rỗng có `extras` (custom props) |
| `map_points.json` | Point-cloud thực vật (Bamboo/Grass/Rice/Reed/Lily/Shrub/GrassTall), toạ độ Godot, `stride 6 = [x, y, z, rot_y, scale, variant]` → dựng `MultiMeshInstance3D` |
| `map_layout.json` | Mọi empty gốc (Point, EggSite, Zone, Spawn, CameraBounds): vị trí Godot + props |

Toạ độ: Bible (gốc Tây-Bắc, +z Nam) → Blender `(x−W/2, −(z−D/2), y)` → Godot `(x−W/2, y, z−D/2)`.

## Hệ thống Point → model thật

Mỗi vật thể cần model là một **empty có tên cố định**, placeholder là con `<tên>__PH`:

| Point | Sinh ở | Placeholder |
|---|---|---|
| `HousePoint_01…07` | §7 houses | `HOUSE_PLACEHOLDER`: tường + mái ngói + cửa (mặt trước) |
| `FencePoint_001…` | §8 fence_bamboo (dọc R1, R3) | thanh 3 m |
| `JarPoint_*`, `BucketPoint_*`, `BasinPoint_*`, `TirePoint_*` | §6 egg_sites | trụ |
| `TreePoint_*`, `BananaPoint_*`, `CoconutPoint_*` | §8 (sparse) | nón |
| `LandmarkPoint_L03…` | §10 | theo loại (cột điện, đống rơm, chòi, cầu ao, thuyền, trâu…) |
| `BridgePoint_B1_R2` | §4 bridges | sàn cầu |
| `BambooPoints`, `GrassPoints`, `RicePoints`… | §8 (cloud) | proxy trong collection `ASSET_<Type>` |

`asset_manifest.json` ánh xạ tên → file (luật đầu tiên khớp thắng, hỗ trợ `*`):

```json
{"match": "HousePoint_01", "asset": "house_vn_01.glb", "fallback": "house2.glb", "fit": "footprint"},
{"match": "HousePoint_02", "asset": "house_vn_02.glb", "fallback": "house2.glb", "fit": "footprint"},
{"match": "HousePoint_03", "asset": "house_vn_01.glb", "fallback": "house2.glb", "fit": "footprint"}
```

- `asset` chưa có → dùng `fallback` (hiện trỏ vào thư viện CC0 có sẵn trong `godot/assets/models/`) → chưa có nữa thì giữ placeholder.
  Chỉ cần thả `house_vn_01.glb` vào `godot/assets/models/map/` rồi chạy lại là nhà tự được thay.
- `fit`: `footprint` (khớp nền nhà / placeholder), `length` (khớp chiều dài đoạn rào/cầu), `height:<m>`.
- Point-cloud: `"clouds": {"BambooPoint": {"asset": ["bamboo_clump_01.glb", "bamboo_clump_02.glb"]}}` — nhiều biến
  thể được chọn theo thuộc tính `variant` của từng điểm.
- `swap_assets.py` chạy lại bao nhiêu lần cũng được; chạy trên `.blend` đã sinh:
  `blender -b tools/blender/out/vietnamese_rural_village.blend -P tools/blender/swap_assets.py -- --save --glb`

## Làm model thật

Model riêng của làng (nhà, lu, hàng rào…) → AI 3D. Cây/cỏ → **không** AI-generate từng cây: lấy asset library
(Quaternius/Poly Haven/Quixel… CC0) rồi rải procedural như trên.

| Vật thể | Quy trình | File đích (`godot/assets/models/map/`) |
|---|---|---|
| Nhà | Concept → Meshy / Rodin / Tripo → Blender cleanup → Godot | `house_vn_01.glb`, `house_vn_02.glb`, `house_vn_03.glb` |
| Lu nước | Ảnh → Meshy → cleanup | `water_jar_vn.glb` |
| Hàng rào tre | Ảnh → AI 3D → cleanup | `bamboo_fence.glb` |
| Xô, chậu, lốp xe | Ảnh → AI 3D, hoặc asset library | `bucket_vn.glb`, `basin_vn.glb`, `old_tire.glb` |
| Cầu, cầu ao, thuyền, chòi, đống rơm, cột điện | Ảnh → AI 3D | `bridge_vn.glb`, `pond_jetty_vn.glb`, `wooden_boat_vn.glb`, `bamboo_hut_vn.glb`, `field_hut_vn.glb`, `haystack_vn.glb`, `power_pole_vn.glb` |
| Tre, cỏ, lúa, sậy, bèo, cây ăn trái, dừa | **Asset library + procedural** | `bamboo_clump_0x.glb`, `grass*.glb`, `rice_patch_1m.glb`, `reed_clump.glb`, `fruit_tree_0x.glb`, `coconut_palm.glb` |

### Bước "Blender cleanup" (bắt buộc trước khi đưa vào map)

1. **Đơn vị mét, kích thước thật** (nhà ~14 × 9 m, lu ~0.9 m, đoạn rào 3 m). `fit` chỉ để chữa cháy.
2. **Gốc (origin) ở đáy-giữa**, đặt tại (0, 0, 0); Apply All Transforms.
3. **Mặt trước nhìn về −Y** trong Blender (= hướng Nam trong map; = +Z trong Godot). Đoạn rào/cầu: dài theo trục **X**.
4. Gộp mesh, xoá mặt thừa/mặt trong, Decimate: nhà ≤ 15k tris, lu/xô ≤ 2k, rào ≤ 1.5k, cụm cây/cỏ ≤ 3k (cỏ/lúa ≤ 500).
5. Texture ≤ 2048 px (props ≤ 1024), PBR (BaseColor/ORM/Normal); xoá ánh sáng nướng sẵn mà AI tạo ra.
6. Xuất glTF Binary (`.glb`) vào `godot/assets/models/map/`, ghi nguồn + giấy phép vào `godot/assets/CREDITS.md`.

## Quy tắc

- Không sửa toạ độ trong script. Muốn đổi bố cục → sửa `docs/MAP_BIBLE.md` + `map_spec.json` (ghi Changelog).
- Thêm loại vật thể mới → thêm vào Bible §8/§10 → `map_spec.json` → luật trong `asset_manifest.json`.
- Seed cố định (`foliage.seed`) → cùng spec luôn cho cùng map. Đổi seed = đổi vị trí từng cây (bố cục zone giữ nguyên).
