# ASSET GUIDELINES — Reference C (Asset sheet) + quy chuẩn model

> Đọc cùng [`ART_DIRECTION.md`](ART_DIRECTION.md) (Reference A) và [`MAP_BIBLE.md`](MAP_BIBLE.md) (Reference B).
>
> ⛔ **Chưa tải / tạo asset nào cho tới khi M1 Greybox được XÁC NHẬN GIỐNG** (xem [`ROADMAP.md`](ROADMAP.md)).
> Map đúng concept → tìm model phù hợp map. **Không** "có model đẹp → nhét vào map".

---

## 1. Pipeline chính: Blender → GLB → Godot

```
Concept / ảnh crop từ reference
        ↓
 AI 3D (Meshy / Rodin / Tripo)   hoặc   asset library (Quaternius, Poly Haven, Quixel… CC0)
        ↓
 Blender cleanup  (§4)
        ↓
 assets/<nhóm>/<loại>/<tên>.glb          ← kho asset gốc (nguồn sự thật cho model)
        ↓
 blender/scripts/swap_assets.py           ← HousePoint_01 → house_vn_01.glb (assets/asset_manifest.json)
        ↓
 blender/exports/<map>_env.glb  → godot/world/generated/   (generate_map.py --stage env --swap --godot)
        ↓
 Godot
```

- **Định dạng chuẩn: glTF 2.0 Binary (`.glb`).** Godot khuyến nghị glTF cho 3D. Không dùng FBX cho pipeline chính
  (FBX chỉ để nhận file từ nguồn ngoài — import vào Blender rồi xuất lại `.glb`). `.blend` không đưa thẳng vào Godot
  (bắt máy ai cũng phải cài Blender đúng phiên bản).
- `assets/` nằm **ngoài** project Godot (`godot/`): Godot chỉ nhận model qua file GLB của map do Blender xuất ra.
  Khi tới M2 cần MultiMesh cho cỏ/lúa trong Godot, script xuất sẽ copy đúng các asset thực vật đang dùng vào
  `godot/world/generated/` — không copy tay.
- Model CC0 cũ trong `godot/assets/models/` (đang dùng cho bản demo) chỉ là **fallback** tạm trong manifest.

## 2. Thư mục

```
assets/
├── asset_manifest.json      Point → file (.glb), đọc bởi swap_assets.py
├── environment/
│   ├── houses/              nhà, hiên, đồ trang trí gắn nhà
│   ├── gardens/             cây vườn, chuối, rơm, chòi, chuồng
│   ├── ponds/               cầu ao, thuyền, súng, sậy, bèo
│   ├── canals/              cầu, cống, bờ kênh
│   ├── rice_fields/         lúa, chòi ruộng, bù nhìn, núi xa
│   ├── bamboo/              tre, bụi rậm, dương xỉ
│   ├── grasslands/          cỏ, dừa, hoa dại
│   └── roads/               rào tre, cột điện, xe đạp, xe bò
├── props/
│   ├── water_jars/          lu, chum, vại
│   ├── buckets/             xô, chậu, lốp xe (vật chứa nước nhỏ)
│   ├── baskets/             rổ, thúng, nia, lồng chim
│   └── farm_tools/          cuốc, liềm, nón lá, bù nhìn
└── creatures/               gà, trâu, ếch, cá, chuồn chuồn
```

Thêm `environment/roads/` so với đề xuất ban đầu vì zone 08 Đường làng cũng cần chỗ cho asset của nó.
`swap_assets.py` tìm file **theo tên** trong toàn bộ cây trên → tên file phải duy nhất.

## 3. Đặt tên

- `snake_case`, tiếng Anh, hậu tố `_vn` cho model riêng của làng: `house_vn_01.glb`, `water_jar_vn.glb`.
- Biến thể đánh số `_01`, `_02`: `bamboo_clump_01.glb`. Texture đi kèm: `<tên>_basecolor.png`, `_orm.png`, `_normal.png`.
- Một file = một vật thể (hoặc một cụm thực vật). Không gộp nhiều nhà vào một file.

## 4. Blender cleanup (bắt buộc)

1. **Đơn vị mét, đúng kích thước thật** (nhà ~14 × 9 m, lu ~0.9 m, đoạn rào 3 m, cụm tre ~11 m).
2. **Gốc (origin) ở đáy-giữa**, đặt tại (0, 0, 0), Apply All Transforms.
3. **Mặt trước nhìn về −Y** trong Blender (= hướng Nam trong map, = +Z trong Godot). Rào/cầu: dài theo trục **X**.
4. Gộp mesh, xoá mặt thừa/mặt trong/vật thể rác do AI sinh; sửa normal; UV không chồng lấn.
5. Ngân sách tam giác: nhà ≤ 15k · lu/xô/chậu ≤ 2k · rào (3 m) ≤ 1.5k · cây lớn ≤ 8k · cụm tre ≤ 3k · cỏ/lúa ≤ 500.
6. Texture PBR (BaseColor / ORM / Normal), ≤ 2048 px (props ≤ 1024). Xoá ánh sáng/bóng "nướng" sẵn trong texture AI.
7. Màu phải khớp bảng màu [`ART_DIRECTION.md §3`](ART_DIRECTION.md); so cạnh ảnh reference trước khi lưu.
8. Xuất **glTF Binary (.glb)** vào đúng thư mục §2; ghi nguồn + giấy phép vào `assets/CREDITS.md` (tạo khi có asset đầu tiên).

## 5. Khi nào dùng AI 3D, khi nào dùng library

| Loại | Cách làm | Lý do |
|---|---|---|
| Nhà, lu, hàng rào tre, cầu ao, thuyền, chòi, đống rơm, cột điện… | **AI 3D** (Concept → Meshy/Rodin/Tripo) + cleanup | Đặc trưng Việt Nam, library ít có |
| Tre, cỏ, lúa, sậy, bèo, cây vườn, dừa, bụi | **Asset library + rải procedural** (`generate_foliage.py`) | Không AI-generate từng cây: hàng chục nghìn instance, cần đồng bộ & nhẹ |
| Vật liệu nền (đất, bờ ruộng, lá mục) | Texture library (Poly Haven / ambientCG) | Tileable PBR |
| Động vật | Library (đã có Quaternius CC0) → thay dần | |

## 6. Asset sheet theo zone

Ưu tiên: **P0** = cần cho M2 (map nhìn giống ảnh) · **P1** = cần cho M3 (cinematic) · **P2** = trang trí thêm.
Cột *Point* = tên điểm trong map mà asset sẽ thay (xem `assets/asset_manifest.json`).
Trạng thái hiện tại: **tất cả chưa có** (đúng quy trình — đợi xác nhận M1).

### 01 Nhà dân — 10 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `house_vn_01.glb` | environment/houses | HousePoint_01, 03, 05 (nhà chính H01: hiên gỗ, lồng chim) | AI 3D | P0 |
| 2 | `house_vn_02.glb` | environment/houses | HousePoint_02, 04, 07 | AI 3D | P0 |
| 3 | `house_vn_03.glb` | environment/houses | HousePoint_06 | AI 3D | P1 |
| 4 | `water_jar_vn.glb` | props/water_jars | JarPoint_* (chum W03 — spawn) | AI 3D | P0 |
| 5 | `bucket_vn.glb` | props/buckets | BucketPoint_* (xô xanh/đỏ) | AI 3D / library | P0 |
| 6 | `basin_vn.glb` | props/buckets | BasinPoint_* (chậu nhôm) | AI 3D / library | P0 |
| 7 | `old_tire.glb` | props/buckets | TirePoint_* | library | P1 |
| 8 | `bird_cage_vn.glb` | props/baskets | hiên H01 (L02) | AI 3D | P2 |
| 9 | `wooden_bench_vn.glb` | environment/houses | hiên nhà | AI 3D | P2 |
| 10 | `chicken_vn.glb` | creatures | LandmarkPoint_L04 | library | P1 |

### 02 Vườn cây / Chuồng trại — 15 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `fruit_tree_01.glb` | environment/gardens | TreePoint_* | library | P0 |
| 2 | `fruit_tree_02.glb` | environment/gardens | TreePoint_* | library | P0 |
| 3 | `banyan_tree.glb` | environment/gardens | LandmarkPoint_L06, L06b (cây lớn có hốc) | AI 3D / library | P0 |
| 4 | `banana_clump_vn.glb` | environment/gardens | BananaPoint_* | library | P0 |
| 5 | `haystack_vn.glb` | environment/gardens | LandmarkPoint_L05, L05b | AI 3D | P0 |
| 6 | `bamboo_hut_vn.glb` | environment/gardens | LandmarkPoint_L07 | AI 3D | P1 |
| 7 | `chicken_coop_vn.glb` | environment/gardens | cạnh L07 | AI 3D | P1 |
| 8 | `leaf_litter` (material) | environment/gardens | nền Z02 | texture library | P1 |
| 9 | `clay_pot_small.glb` | props/water_jars | vật chứa nước nhỏ trong vườn | AI 3D | P1 |
| 10 | `pig_pen_vn.glb` | environment/gardens | Z02b | AI 3D | P2 |
| 11 | `woodpile_vn.glb` | environment/gardens | Z02 | library | P2 |
| 12 | `flower_pot_vn.glb` | environment/gardens | sân, hiên | library | P2 |
| 13 | `vegetable_bed_vn.glb` | environment/gardens | Z02b | AI 3D | P2 |
| 14 | `compost_pile.glb` | environment/gardens | Z02 | library | P2 |
| 15 | `bamboo_basket_vn.glb` | props/baskets | rải trong vườn | AI 3D | P2 |

### 03 Ao / Hồ — 20 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `pond_jetty_vn.glb` | environment/ponds | LandmarkPoint_L08 | AI 3D | P0 |
| 2 | `wooden_boat_vn.glb` | environment/ponds | LandmarkPoint_L08b | AI 3D | P0 |
| 3 | `lily_pad_vn.glb` | environment/ponds | LilyPoints | library | P0 |
| 4 | `reed_clump.glb` | environment/ponds | ReedPoints (ao, kênh, ruộng) | library | P0 |
| 5 | `pond_water` (shader) | godot/shaders | Water_pond_main | viết shader | P0 |
| 6 | `pond_bank_mud` (material) | environment/ponds | bờ ao (terrain) | texture library | P0 |
| 7 | `lotus_vn.glb` | environment/ponds | mặt ao | library | P1 |
| 8 | `cattail_clump.glb` | environment/ponds | ven bờ | library | P1 |
| 9 | `water_hyacinth.glb` | environment/ponds | bèo tây trôi | library | P1 |
| 10 | `duckweed` (decal) | environment/ponds | bèo tấm mặt nước | texture | P1 |
| 11 | `floating_debris.glb` | environment/ponds | lá, cành trôi | library | P1 |
| 12 | `fish_small.glb` | creatures | dưới nước | library (đã có fish1/2) | P1 |
| 13 | `frog.glb` | creatures | bờ ao | library (đã có) | P1 |
| 14 | `pond_stones.glb` | environment/ponds | bờ | library | P2 |
| 15 | `fallen_log.glb` | environment/ponds | bờ | library | P2 |
| 16 | `bamboo_fish_trap_vn.glb` | environment/ponds | cái lờ | AI 3D | P2 |
| 17 | `bamboo_pole.glb` | environment/ponds | sào cắm ao | AI 3D | P2 |
| 18 | `algae` (decal) | environment/ponds | rêu mặt nước | texture | P2 |
| 19 | `bank_shrub.glb` | environment/ponds | bờ ao | library | P2 |
| 20 | `dragonfly.glb` | creatures | bay trên mặt ao | library | P2 |

### 04 Ruộng lúa — 10 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `rice_patch_1m.glb` | environment/rice_fields | RicePoints (lúa non) | library + chỉnh | P0 |
| 2 | `paddy_bund` (material) | environment/rice_fields | bờ ruộng (terrain) | texture | P0 |
| 3 | `field_hut_vn.glb` | environment/rice_fields | LandmarkPoint_L10 | AI 3D | P0 |
| 4 | `water_buffalo.glb` | creatures | LandmarkPoint_L10b | AI 3D / library | P0 |
| 5 | `distant_mountains` (backdrop) | environment/rice_fields | phía Bắc, ngoài map | billboard / mesh thấp | P1 |
| 6 | `culvert_vn.glb` | environment/canals | LandmarkPoint_L11 | AI 3D | P1 |
| 7 | `rice_patch_1m_mature.glb` | environment/rice_fields | biến thể lúa chín | library | P2 |
| 8 | `scarecrow_vn.glb` | props/farm_tools | giữa ruộng | AI 3D | P2 |
| 9 | `conical_hat.glb` | props/farm_tools | chòi ruộng | AI 3D | P2 |
| 10 | `irrigation_gate_vn.glb` | environment/rice_fields | cửa cống bờ ruộng | AI 3D | P2 |

### 05 Kênh mương — 8 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `bridge_vn.glb` | environment/canals | BridgePoint_B1_R2 | AI 3D | P0 |
| 2 | `canal_water` (shader) | godot/shaders | Water_canal_* (chảy chậm) | viết shader | P0 |
| 3 | `canal_bank` (material) | environment/canals | bờ kênh (terrain) | texture | P0 |
| 4 | `concrete_drain_pipe.glb` | environment/canals | cống tròn | library | P1 |
| 5 | `canal_debris.glb` | environment/canals | rác, lá trôi | library | P1 |
| 6 | `plank_bridge_small.glb` | environment/canals | cầu ván nhỏ | AI 3D | P2 |
| 7 | `stepping_stones.glb` | environment/canals | bậc xuống nước | library | P2 |
| 8 | `floating_trash.glb` | environment/canals | túi nilon, chai | library | P2 |

### 06 Rừng tre / Bụi rậm — 8 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `bamboo_clump_01.glb` | environment/bamboo | BambooPoints | library | P0 |
| 2 | `bamboo_clump_02.glb` | environment/bamboo | BambooPoints | library | P0 |
| 3 | `bamboo_leaf_litter` (material) | environment/bamboo | nền Z06 | texture | P0 |
| 4 | `shrub_tropical_01.glb` | environment/bamboo | ShrubPoints | library | P0 |
| 5 | `shrub_tropical_02.glb` | environment/bamboo | ShrubPoints | library | P1 |
| 6 | `fern_clump.glb` | environment/bamboo | ShrubPoints | library | P1 |
| 7 | `bamboo_single_tall.glb` | environment/bamboo | cây tre lẻ ven kênh | library | P1 |
| 8 | `fallen_bamboo.glb` | environment/bamboo | thân tre đổ | library | P2 |

### 07 Đồng cỏ / Bãi đất trống — 8 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `grass_tall.glb` | environment/grasslands | GrassTallPoints | library | P0 |
| 2 | `grass_clump_vn.glb` | environment/grasslands | GrassPoints (cỏ thấp toàn map) | library | P0 |
| 3 | `coconut_palm.glb` | environment/grasslands | CoconutPoint_* | library | P0 |
| 4 | `puddle` (material) | environment/grasslands | vũng sau mưa | shader/texture | P0 |
| 5 | `lone_tree.glb` | environment/grasslands | cây lẻ | library | P1 |
| 6 | `wildflowers.glb` | environment/grasslands | xen cỏ | library | P2 |
| 7 | `termite_mound.glb` | environment/grasslands | ụ đất | library | P2 |
| 8 | `goat.glb` | creatures | gặm cỏ | library | P2 |

### 08 Đường làng — 8 assets

| # | File | Thư mục | Point / dùng ở | Cách làm | Ưu tiên |
|---|---|---|---|---|---|
| 1 | `bamboo_fence.glb` | environment/roads | FencePoint_* (đoạn 3 m) | AI 3D | P0 |
| 2 | `dirt_road` (material) | environment/roads | Road_* | texture | P0 |
| 3 | `power_pole_vn.glb` | environment/roads | LandmarkPoint_L03 | AI 3D | P0 |
| 4 | `power_line` (curve) | environment/roads | dây điện giữa các cột | procedural | P1 |
| 5 | `road_puddle` (decal) | environment/roads | ổ gà trên R1 | texture | P1 |
| 6 | `bicycle_vn.glb` | environment/roads | dựng cạnh nhà | library | P2 |
| 7 | `ox_cart_vn.glb` | environment/roads | ven đường | AI 3D | P2 |
| 8 | `gravel_edge.glb` | environment/roads | mép đường | library | P2 |

**Tổng: 87 asset** — P0: 34 · P1: 24 · P2: 29. Làm P0 trước, theo thứ tự zone của hành trình người chơi.

## 7. Quy tắc

- Asset mới phải có dòng trong bảng §6 **trước** khi làm, và luật tương ứng trong `assets/asset_manifest.json`.
- Thêm vật thể mới vào map (không chỉ thay model) → sửa `MAP_BIBLE.md` + `map_spec.json` trước.
- Mỗi asset P0 khi xong: chạy `generate_map.py --stage env --swap --godot`, chụp lại key shot, so với Reference A.
