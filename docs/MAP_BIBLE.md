# MAP BIBLE — Làng quê Việt Nam (`vietnamese_rural_village`)

> **NGUỒN SỰ THẬT DUY NHẤT cho bố cục map.**
> Mọi code, scene, asset sinh map PHẢI đọc file này trước. Không được tự ý đổi vị trí, kích thước,
> thứ tự khu vực. Muốn đổi → sửa file này trước (kèm lý do trong mục *Changelog*), rồi mới sửa code.
>
> Nguồn gốc: ảnh MASTER REFERENCE "Bối cảnh bản đồ – Làng quê Việt Nam" (ảnh chính + minimap
> "TỔNG QUAN MAP" + 8 khu vực + 6 loại nước + ngày/đêm + hành trình người chơi).
> Toạ độ bên dưới được **đo từ minimap** (tỉ lệ ảnh minimap ≈ 242 × 260 px ⇒ gần vuông, hơi cao).

---

## 0. Quy ước

| Mục | Giá trị |
|---|---|
| Đơn vị | 1 unit = 1 mét (thế giới thực; muỗi chỉ phóng đại hiển thị) |
| Hệ trục | **+X = Đông**, **+Z = Nam**, **+Y = lên** (Godot: +Z hướng về phía người xem, Bắc = −Z) |
| Gốc (0,0) | **Góc Tây-Bắc** (trên-trái của minimap). Map nằm trong `x ∈ [0, W]`, `z ∈ [0, D]` |
| Hướng Bắc | Mũi tên **N** của minimap chỉ **lên trên** ⇒ Bắc = z nhỏ |
| Độ cao 0 | Mặt ruộng lúa (thấp nhất trong vùng sinh hoạt) |
| Định dạng khu vực | `pos` = **tâm** (x, z); `size` = (rộng X, sâu Z); `rect` = [x0, z0, x1, z1] |
| Chuyển sang Godot | `Vector3(x − W/2, y, z − D/2)` nếu muốn gốc ở tâm map |

> ⚠️ Bản demo hiện tại (`godot/scripts/game.gd` `SITES`, `adult.gd` nền 240 × 240) dùng thế giới nén
> (±25 m quanh nhà). Bảng ở **§11 Legacy mapping** nói cách đổi sang toạ độ chuẩn khi migrate.

---

## 1. MAP — tổng thể

```yaml
map:
  name: vietnamese_rural_village
  title: "Làng quê Việt Nam"
  theme: "Gần gũi – Đời thường – Đa dạng môi trường nước"
  north: -z            # mũi tên N của minimap hướng lên
  origin: north_west
  units: meter

  dimensions:          # §2
    width_x: 500
    depth_z: 540
    playable_margin: 10   # dải đệm quanh mép (xem §12)
```

Layout cấp cao (nhìn từ trên xuống, Bắc ở trên). **Không đổi thứ tự trái → phải / trên → dưới:**

```
 x: 0                 125     220         300 322                 500
 z=0   ┌───────────────┬───────┬───────────┬──┬───────────────────┐
       │  Z06 RỪNG TRE │ SÔNG  │ Z02 VƯỜN  │ĐƯ│                   │
       │  / BỤI RẬM    │ KÊNH  │ (đông bờ) │ỜN │   Z01 NHÀ DÂN     │
  185  │  (bờ tây)     │ Z05   ├───────────┤G  │   (cụm nhà)       │
       │               │  ~    │           │LÀ │                   │
  190  │               │  ~    │           │NG ├───────────────────┤
       │               │  ~    │ Z03 AO/HỒ │Z08│                   │
       │               │  ~    │  (ao)     │   │   Z04 RUỘNG LÚA   │
  410  │               │  ~~   ├───────────┤   │  (bờ ruộng, kênh  │
       │               │   ~~~ │           │   │   nhánh ở rìa Tây)│
  505  │               │     ~~~~~~~~~~~   │   ├───────────────────┤
       │               │  (kênh uốn cong)  │   │ Z07 ĐỒNG CỎ      │
  540  └───────────────┴───────────────────┴───┴───────────────────┘
```

(Sơ đồ ASCII mang tính thứ tự tương đối; số liệu chính xác nằm ở §3–§4.)

---

## 2. World dimensions

```yaml
world:
  width_x: 500        # Tây → Đông
  depth_z: 540        # Bắc → Nam
  area_m2: 270000     # 27 ha
  aspect: "0.93 : 1"  # khớp tỉ lệ minimap (242 × 260)
  ground_y: 0.0       # mặt ruộng
  max_height_y: 60    # trần bay (xem camera)
  backdrop:
    north: "dãy núi xa (xanh nhạt, sương) — chỉ là skybox/billboard, không đi tới được"
    east:  "đồng ruộng/đồng cỏ kéo dài mờ dần"
    south: "đồng cỏ + kênh chảy ra ngoài map"
    west:  "rừng tre dày chắn tầm nhìn"
```

---

## 3. Zone coordinates & dimensions

8 khu vực theo đúng đánh số trong ảnh. `rect` không chồng lấn (sông/kênh được "khoét" khỏi zone).

```yaml
zones:

  house:                      # ① Nhà dân
    id: Z01
    name: "Nhà dân"
    rect: [220, 40, 425, 185]
    pos:  [322.5, 112.5]
    size: [205, 145]
    role: "Cụm nhà ngói đỏ + sân gạch + đồng hồ sinh hoạt của người. Nơi xuất phát."
    minimap_marker: [310, 54]          # số ① trong minimap
    water_sources: [W03, W02, W04b]    # chum, xô/chậu, lốp xe… (xem §6)
    mosquito_theme: "Nơi trú ẩn + nguồn máu người; đẻ trứng ở vật chứa nhân tạo"
    threat: high                       # người đập muỗi

  garden:                     # ② Vườn cây / Chuồng trại
    id: Z02
    name: "Vườn cây / Chuồng trại"
    sub:
      Z02a:                            # cụm bờ Tây của sông (marker ② trái)
        rect: [35, 140, 85, 225]
        pos: [60, 182.5]
        size: [50, 85]
      Z02b:                            # cụm bờ Đông, sát nhà (hốc cây, lu mực, chòi, chuồng)
        rect: [130, 100, 215, 290]
        pos: [172.5, 195]
        size: [85, 190]
    role: "Hốc cây, lá mục, vật chứa nước nhỏ; chuồng gà/trâu; chòi tre"
    minimap_marker: [[90, 178], [155, 330]]   # xem ghi chú ở §3.1
    mosquito_theme: "Nơi trú ẩn + nơi đẻ trứng của nhiều loài muỗi"
    threat: medium

  pond:                       # ③ Ao / Hồ
    id: Z03
    name: "Ao / Hồ"
    rect: [125, 290, 215, 385]
    pos:  [170, 337.5]
    size: [90, 95]
    water_body: pond_main              # xem §5
    role: "Nước tĩnh, nhiều sinh vật nhỏ, thích hợp cho lăng quăng phát triển. Có cầu ao + thuyền gỗ."
    minimap_marker: [165, 335]
    threat: low

  rice_field:                 # ④ Ruộng lúa
    id: Z04
    name: "Ruộng lúa"
    rect: [322, 190, 490, 405]
    pos:  [406, 297.5]
    size: [168, 215]
    role: "Nước nông, nhiều côn trùng, vi sinh vật = thức ăn cho lăng quăng. Có trâu, chòi ruộng."
    minimap_marker: [410, 280]
    water_body: paddy_main
    threat: low

  canal:                      # ⑤ Kênh mương  (chạy xuyên map — xem §4/§5)
    id: Z05
    name: "Kênh mương"
    geometry: "polyline có độ rộng — xem water.canal_main / canal_branch"
    bbox: [85, 0, 500, 540]
    role: "Dòng chảy chậm, nhiều mảnh vụn hữu cơ, có thể xuất hiện nhiều loài muỗi khác nhau."
    minimap_marker: [[85, 243], [295, 405]]
    threat: low

  bamboo:                     # ⑥ Rừng tre / Bụi rậm
    id: Z06
    name: "Rừng tre / Bụi rậm"
    rect: [0, 0, 80, 430]
    pos:  [40, 215]
    size: [80, 430]
    ext:  { rect: [0, 430, 150, 540], note: "góc Tây-Nam nối rừng tre với kênh" }
    role: "Nơi trú ẩn, nghỉ ngơi của muỗi trưởng thành, đặc biệt là các loài sống ngoài trời."
    minimap_marker: null               # không đánh số trong minimap; vùng cây rậm bờ Tây
    threat: lowest                     # gần như không có người

  meadow:                     # ⑦ Đồng cỏ / Bãi đất trống
    id: Z07
    name: "Đồng cỏ / Bãi đất trống"
    rect: [310, 410, 500, 505]
    pos:  [405, 457.5]
    size: [190, 95]
    role: "Vùng nước tạm thời sau mưa, phù hợp cho muỗi nước lũ."
    minimap_marker: [440, 454]
    water_body: [puddles_meadow]
    threat: low

  village_road:               # ⑧ Đường làng
    id: Z08
    name: "Đường làng"
    geometry: "mạng đường — xem §4 Roads"
    bbox: [100, 40, 490, 475]
    role: "Dễ tiếp cận con người và vật nuôi, thích hợp cho các loài hút máu ban ngày."
    minimap_marker: null               # không đánh số; đường thấy được trên minimap
    threat: highest
```

### 3.1 Ghi chú đo minimap (để không đoán sai)

- Minimap có marker số: `① ② ② ④ ⑤ ⑤ ⑦` (marker ③, ⑥, ⑧ không rõ/không in). Marker ② thứ hai ở
  giữa-trái và marker ③ bị lẫn: **ao (Z03) đặt tại điểm marker giữa-trái (≈ 31 % x, 61 % z)** vì ảnh chính
  và ảnh "3. Ao / Hồ" cho thấy ao sát nhà và kề kênh.
- Hai marker ⑤ = hai đoạn kênh: **sông-kênh chính** (S-curve bờ Tây) và **kênh nhánh** chạy dọc rìa
  Tây ruộng lúa.
- Đổi pixel → mét: `x = (px − 1044)/242 × 500`, `z = (py − 50)/260 × 540`.

### 3.2 Bảng bao phủ (kiểm tra không chồng lấn)

| Zone | x0 | z0 | x1 | z1 | Diện tích (m²) |
|---|---|---|---|---|---|
| Z06 Rừng tre | 0 | 0 | 80 | 430 | 34 400 (+ ext 16 500) |
| Z02a Vườn tây | 35 | 140 | 85 | 225 | 4 250 *(nằm trong Z06, ưu tiên Z02a)* |
| Z02b Vườn đông | 130 | 100 | 215 | 290 | 16 150 |
| Z03 Ao | 125 | 290 | 215 | 385 | 8 550 |
| Z01 Nhà dân | 220 | 40 | 425 | 185 | 29 725 |
| Z04 Ruộng lúa | 322 | 190 | 490 | 405 | 36 120 |
| Z07 Đồng cỏ | 310 | 410 | 500 | 505 | 18 050 |

Phần còn lại (sông, đường, bìa rừng, đất trống giữa các zone) = **"filler"**: cỏ + bụi thấp, không có
nhiệm vụ riêng.

---

## 4. Roads

Đường làng (Z08). `w` = chiều rộng (m). Tâm đường = polyline. Mặt đường **đất nện nâu đỏ**, rìa cỏ.

```yaml
roads:
  R1_main_spine:            # trục chính Bắc→Nam, chạy giữa nhà (Tây) và ruộng (Đông)
    type: dirt_road
    w: 5
    points: [[285, 40], [285, 185], [285, 335], [285, 470]]
    embankment_y: 0.3
    note: "Hàng rào tre + cột điện dọc theo; nhà dân hai bên ở đoạn z 40–185"

  R2_bridge_lane:           # nối nhà → bờ Tây (rừng tre) qua cầu bắc kênh
    type: dirt_path
    w: 3
    points: [[285, 100], [215, 100], [111, 100], [60, 100]]
    bridge: { at: [111, 100], len: 24, w: 3, deck_y: 1.2, material: "ván gỗ + lan can tre" }

  R3_pond_lane:             # từ đường chính ra ao
    type: dirt_path
    w: 3
    points: [[285, 337], [215, 337]]
    ends_at: pond_jetty

  R4_field_bund:            # bờ ruộng đi xuyên ruộng lúa
    type: bund
    w: 1.5
    points: [[287.5, 300], [490, 300]]   # nối R1, qua kênh nhánh bằng cống L11
    height_y: 0.4

  R5_meadow_lane:           # ra đồng cỏ
    type: dirt_path
    w: 3
    points: [[285, 470], [330, 470], [330, 460]]

  T1_bamboo_trail:          # đường mòn xuyên rừng tre (§8, L12) — không đắp nền
    type: trail
    w: 1.5
    points: [[0, 215], [80, 215]]

  R6_house_yards:           # lối nhỏ vào từng nhà (sân gạch)
    type: brick_yard
    note: "sinh theo vị trí nhà §7, bán kính sân 6–8 m"
```

---

## 5. Water bodies

Độ sâu = từ mặt nước xuống đáy. `surface_y` = cao độ mặt nước (so với 0 = mặt ruộng).

```yaml
water:

  canal_main:               # ⑤ sông-kênh uốn chữ S, bờ Tây, chảy Bắc → Nam rồi rẽ Đông ra rìa Nam
    id: Z05
    type: slow_stream
    w: 14                   # rộng lòng nước
    bank_w: 6               # mỗi bên bờ dốc
    depth: 1.8
    surface_y: -0.3
    flow: "Bắc → Nam → Đông, chậm (0.1–0.3 m/s)"
    centerline:             # polyline (x, z) — CẤM đổi thứ tự điểm
      - [95, 0]
      - [115, 80]
      - [100, 162]
      - [85, 243]
      - [110, 335]
      - [165, 432]
      - [250, 497]
      - [385, 524]
      - [500, 525]          # thoát khỏi map
    crossings: [R2 bridge @ (111,100)]
    water_class: natural_flowing   # §6

  canal_branch:             # ⑤ kênh nhánh dọc rìa Tây ruộng lúa, song song R1
    id: Z05b
    type: irrigation_ditch
    w: 4
    depth: 0.8
    surface_y: -0.25          # thấp hơn ruộng (tiêu nước), nối êm vào canal_main (-0.3)
    centerline: [[308, 190], [308, 300], [308, 405], [300, 450], [270, 495]]
    note: "nối vào canal_main tại ≈ (270, 495); cấp nước cho ruộng qua cống nhỏ"
    water_class: stagnant_slow

  pond_main:                # ③ ao làng
    id: Z03
    shape: ellipse
    center: [170, 337]
    radii: [40, 32]         # → 80 × 64 m
    depth: 2.5
    surface_y: -0.2
    props: [jetty @ (208, 337), wooden_boat @ (190, 352), lilies, reeds]
    water_class: clean_still

  paddy_main:               # ④ nước ruộng
    id: Z04
    shape: rect_with_bunds
    rect: [322, 190, 490, 405]
    depth: 0.15             # nước nông trên mặt ruộng
    surface_y: 0.15
    plots: "6 thửa × 2 hàng: bờ R4 (z = 300) chia ruộng làm 2 nửa, mỗi nửa 3 hàng thửa đều nhau (~35 m)"
    water_class: shallow_nutrient

  puddles_meadow:           # ⑦ vũng sau mưa (chỉ có sau mưa)
    id: Z07
    spawn_rule: "rain_active || rain_ended < 2 ngày game"
    patches:                # tâm, bán kính
      - [360, 440, 8]
      - [420, 470, 11]
      - [470, 450, 6]
      - [330, 450, 2]     # vũng nhỏ tại điểm đẻ trứng W01
    depth: 0.2
    water_class: temporary

  yard_containers:          # vật chứa nhân tạo trong Z01/Z02 — xem §6 (W02–W04)
    see: "§6"
```

---

## 6. Các loại nước trong map (đúng theo ảnh "CÁC LOẠI NƯỚC TRONG MAP")

| Loại (ảnh) | Mã | Ví dụ | Có trong map ở | Site game (`SITES.id`) |
|---|---|---|---|---|
| Nước sạch (ao, giếng) | `clean_still` | ao, giếng | Z03 ao; giếng ở sân nhà | `pond` |
| Nước tù (cống, mương) | `stagnant_slow` | cống, mương | `canal_branch`, rãnh quanh nhà | `canal` |
| Nước lợ (ven biển/triều) | `brackish` | — | **Không có trong map** (chỉ hiện trong infographic, để mở rộng) | — |
| Nước tạm thời (sau mưa) | `temporary` | vũng mưa | Z07 đồng cỏ, ổ gà trên R1 | `puddle` |
| Vật chứa (xô, chậu, lốp xe) | `container` | chum, xô, chậu, lốp | Z01 sân nhà, Z02 | `jar`, `bucket` |
| Nước tự nhiên (hồ, sông, suối) | `natural_flowing` | sông-kênh | `canal_main` | `canal` / `pond` |
| *(ruộng)* | `shallow_nutrient` | ruộng lúa | Z04 | `paddy` |

### Điểm đẻ trứng cố định

```yaml
egg_sites:
  W01_puddle_rain:  { pos: [330, 0.05, 450],  zone: Z07, game_site: puddle }
  W02_bucket:       { pos: [292, 0.3, 66],    zone: Z01, game_site: bucket, note: "xô xanh/đỏ cạnh chum" }
  W03_jar_chum:     { pos: [300, 0.45, 80],   zone: Z01, game_site: jar,    note: "chum sành lớn trước hiên — NGUỒN SPAWN LẦN ĐẦU" }
  W04a_basin:       { pos: [296, 0.3, 90],    zone: Z01, note: "chậu nhôm, phụ" }
  W04b_tire:        { pos: [262, 0.1, 150],   zone: Z01, note: "lốp xe cũ cạnh nhà sau" }
  W05_pond:         { pos: [170, -0.2, 337],  zone: Z03, game_site: pond }
  W06_canal:        { pos: [100, -0.3, 162],  zone: Z05, game_site: canal }
  W07_paddy:        { pos: [385, 0.15, 282],  zone: Z04, game_site: paddy }
```

---

## 7. Houses

Nhà ngói đỏ / nhà gỗ mái ngói nâu, sân gạch + hàng rào tre. Hướng cửa chính ra **đường R1** (Z08).

```yaml
houses:
  default_footprint: [14.4, 9.4]      # khớp nhà trong adult.gd (HWALL…)
  roof: { type: clay_tile, color: "đỏ-nâu" }
  yard: { radius: 7, floor: brick }

  H01_hero:                           # nhà chính của người chơi (ảnh chính: hiên, lồng chim, chum, xô)
    pos: [310, 65]
    size: [14.4, 9.4]
    facing: south                     # cửa ra sân + đường R1
    props: [chum_lon @ (300,80), xo_xanh @ (292,66), xo_do @ (298,70), chau_nhom @ (296,90),
            long_chim, ga_mai, ban_ghe_hien]
    npcs: [ba_ba, me, con_nho]        # đồng hồ sinh hoạt trong nhà (xem README)
  H02: { pos: [360, 70],  size: [12, 8] }
  H03: { pos: [395, 95],  size: [12, 8] }
  H04: { pos: [255, 80],  size: [12, 8] }
  H05: { pos: [255, 150], size: [12, 8] }
  H06: { pos: [330, 155], size: [12, 8] }
  H07: { pos: [385, 160], size: [12, 8] }

  rules:
    - "Tất cả nhà nằm trong rect Z01 [220,40,425,185]."
    - "Khoảng cách nhà–nhà ≥ 25 m."
    - "Nền nhà cao +0.6 m so với mặt ruộng."
    - "Không đặt nhà trong bán kính 12 m của mặt nước."
```

---

## 8. Vegetation

```yaml
vegetation:
  banana:        { zones: [Z01, Z02], density: "cụm 3–6 cây, ~25 cụm", height: [3, 5] }
  coconut_palm:  { zones: [Z01, Z04_rim, Z07], density: "~18 cây, nằm ở rìa, KHÔNG trong ruộng", height: [10, 16] }
  big_shade_tree:{ zones: [Z02b], count: 2, pos: [[170, 150], [150, 240]], note: "cây đa/me lớn có hốc cây — thân to trong ảnh 2. Vườn cây" }
  fruit_garden:  { zones: [Z02], density: "mật độ cao, xen rau, chậu hoa" }
  bamboo_grove:  { zones: [Z06], density: "dày (~0.15 khóm/m², mỗi khóm ~15 cây, tán ~6 m)", height: [8, 14], note: "đường mòn xuyên rừng ở z≈215" }
  dense_shrub:   { zones: [Z06, canal_banks], height: [1, 2.5] }
  reeds_cattail: { zones: [pond_rim, canal_banks, paddy_bunds], height: [1.5, 2.5] }
  water_lily:    { zones: [pond_main], coverage: 0.2 }
  rice:          { zones: [Z04], height: [0.7, 1.1], color: "xanh non" }
  grass_tall:    { zones: [Z07], height: [0.5, 1.2], note: "cỏ cao 'khu vực đồng cỏ'" }
  grass_short:   { zones: [filler, road_verge], height: [0.1, 0.3] }
  hay_stack:     { count: 2, pos: [[225, 110], [190, 280]] }
  fence_bamboo:  { along: [R1, yards, pond_lane], note: "hàng rào tre / gỗ dọc đường & bờ ao" }
rules:
  - "Không cây thân gỗ trong ruộng lúa (Z04) và trên mặt đường."
  - "Cây cao chỉ chắn tầm nhìn camera ≤ 30 %."
```

---

## 9. Elevation (cao độ nền, y = 0 là mặt ruộng)

```yaml
elevation:
  rice_field:   { y: 0.0 }
  pond_bank:    { y: 0.2 }
  pond_water:   { y: -0.2, bed: -2.7 }
  canal_main:   { water: -0.3, bed: -2.1, bank_y: 0.3 }
  canal_branch: { water: -0.25, bed: -1.05 }
  road_R1:      { y: 0.3, camber: "gờ nhẹ 0.1 m" }
  house_pad:    { y: 0.6 }
  garden:       { y: 0.4 }
  bamboo_zone:  { y: 0.5, hump: "gò nhẹ +0.3 giữa rừng" }
  meadow:       { y: 0.2, depressions: "3 chỗ trũng 0.1 m tại các vũng §5" }
  max_terrain_variation: 1.0           # không có đồi — làng đồng bằng
  distant_mountains: "chỉ backdrop, không có geometry chơi"
```

---

## 10. Landmarks

Dùng làm điểm tựa định hướng cho người chơi và cho Claude (đặt đúng chỗ, không "quên").

| ID | Landmark | Pos (x, z) | Zone | Ghi chú |
|---|---|---|---|---|
| L01 | Chum sành lớn (spawn lần đầu) | (300, 80) | Z01 | W03 |
| L02 | Hiên nhà gỗ + lồng chim | (305, 60) | Z01 | nhà H01 |
| L03 | Cột điện bê tông + dây | (288, 45) | Z08 | ảnh chính: cột bên phải nhà |
| L04 | Gà mái ở sân | (292, 85) | Z01 | NPC sinh vật |
| L05 | Chòi rơm / đống rơm | (225, 110) | Z01 | sát ranh Z02 (rect Z01 bắt đầu từ x = 220) |
| L05b | Đống rơm 2 | (190, 280) | Z02 | §8 hay_stack |
| L06 | Cây đa/me lớn (hốc cây) | (170, 150) | Z02b | |
| L07 | Chòi tre nhỏ | (185, 215) | Z02b | |
| L08 | Cầu ao + thuyền gỗ | (208, 337) / (190, 352) | Z03 | |
| L09 | Cầu bắc qua sông | (111, 100) | Z05 | R2 |
| L10 | Chòi ruộng + trâu | (440, 330) / (400, 250) | Z04 | trâu đi lại trong ruộng |
| L11 | Cống nhỏ cấp nước ruộng | (308, 300) | Z05b | |
| L12 | Đường mòn rừng tre | (40, 215) | Z06 | |
| L13 | Đồng cỏ + vũng sau mưa | (420, 470) | Z07 | |
| L14 | Dãy núi xa | z < 0 (backdrop) | — | |

---

## 11. Player spawn & hành trình

```yaml
player_spawn:
  first_life:
    stage: egg
    pos: [300, 0.45, 80]               # W03 chum sành, Z01 sân nhà H01
    facing: south
  later_generations:
    stage: egg
    pos: "vị trí đẻ trứng của thế hệ trước (egg_sites §6)"
  adult_emerge:
    rule: "vũ hóa NGOÀI TRỜI, tại đúng điểm nước nơi lớn lên (README)"
    pos: "egg_site.pos + (0, 1.2, 0)"
  respawn_on_death: "bắt đầu lại từ quả trứng (Enter) — theo README"

journey_order:        # thứ tự trong ảnh "CÁC KHU VỰC TRONG MAP (theo hành trình người chơi)"
  - Z01  # Nhà dân
  - Z02  # Vườn cây
  - Z03  # Ao
  - Z04  # Ruộng lúa
  - Z05  # Kênh mương
  - Z06  # Rừng tre
  - Z07  # Đồng cỏ
  - Z08  # Đường làng
  # Đây là thứ tự GIỚI THIỆU / mở khoá, không phải thứ tự đi bắt buộc.
```

### 11.1 Legacy mapping (demo hiện tại → toạ độ chuẩn)

`game.gd` `SITES.pos` đang theo thế giới nén (x, z, bán kính) quanh nhà. Khi migrate, **thay bằng toạ độ §6**:

| `SITES.id` | pos cũ (x, z) | pos chuẩn mới (x, z) |
|---|---|---|
| puddle | (−15, 13) | (330, 450) |
| bucket | (−9.2, 2.5) | (292, 66) |
| jar | (10.5, 6.5) | (300, 80) |
| pond | (21, −4) | (170, 337) |
| canal | (9, 19.2) | (100, 162) |
| paddy | (−22, −17) | (385, 282) |

> **Đã migrate (M4, 2026-10-05):** khi có map (`godot/world/generated/`), `adult.gd` đặt gốc toạ độ thế giới
> trưởng thành tại `HousePoint_01` (Godot (60, 0.6, −205) = nền nhà H01) và lấy site từ `EggSite_*` theo `game_site`
> (`Game.site_pos()` / `Game.site_wy()`); cột "pos cũ" chỉ còn dùng khi không có map.

---

## 12. Camera bounds

```yaml
camera:
  playable_rect: [10, 10, 490, 530]    # x0, z0, x1, z1  (map trừ margin 10 m)
  hard_rect:     [0, 0, 500, 540]      # tường vô hình, không bao giờ vượt
  soft_edge: 10                        # vùng đệm: giảm tốc + mờ viền (vignette) khi tới gần mép
  altitude:
    adult_min_y: 0.15                  # sát mặt đất
    adult_max_y: 25                    # trần bay muỗi trưởng thành
    sky_ceiling_y: 60                  # camera không vượt quá
    indoor_ceiling_y: 3.4              # trong nhà (HWALL)
  underwater:
    pond_floor_y: -2.7
    canal_floor_y: -2.1
    paddy_floor_y: -0.15
    surface_clamp: "camera dưới nước không vượt lên mặt nước trừ khi vũ hóa"
  collision:
    - "Camera không xuyên tường nhà, thân cây tre, mái nhà."
    - "Near-plane ≥ 0.05; tự co spring-arm khi gần vật cản."
  backdrop:
    skybox: "trời xanh, mây trắng (ban ngày) / trăng + sao (ban đêm)"
    mountains: "billboard phía Bắc, cách ≥ 800 m"
```

---

## 13. Environmental rules

```yaml
environment:
  time_of_day:
    day_length_real_s: 75              # = DAY_LEN_ADULT
    phases: [dawn 05:00, day 06:00–17:00, dusk 17:00–19:00, night 19:00–05:00]
    sun: "ấm, góc thấp sáng sớm/chiều; ban đêm trăng + ánh đèn nhà"
  weather:
    states: [clear, cloudy, rain]
    rain: { effect: "tạo vũng tạm thời ở Z07, ổ gà R1; tăng độ sâu ruộng +0.05 m; muỗi bay chậm" }
    wind: "nhẹ; tre/chuối đung đưa; làm lệch quỹ đạo bay nhỏ"
  activity_by_zone:
    Z01: "người sinh hoạt theo đồng hồ; ngủ khó phát hiện; xem TV ít chú ý; đi lại/chơi rất tinh mắt"
    Z08: "người + vật nuôi qua lại ban ngày — nguy hiểm nhất"
    Z06: "gần như vắng người — an toàn nghỉ ngơi"
  mosquito_habitat_affinity:           # độ hợp (0–1) để điều chỉnh AI/nhiệm vụ
    Z01: { container_breeders: 1.0, human_blood: 1.0 }
    Z02: { tree_hole_breeders: 0.9, animal_blood: 0.7 }
    Z03: { clean_still_water: 0.9, predators: high }
    Z04: { shallow_nutrient: 0.95 }
    Z05: { slow_flow_debris: 0.8 }
    Z06: { resting_outdoor: 1.0 }
    Z07: { flood_water: 0.8 }
    Z08: { daytime_biters: 0.9, human_threat: 1.0 }
  sound: { day: "ve, chim, gà", night: "ếch nhái, dế, côn trùng", ambient_by_zone: true }
```

---

## 14. Quy tắc cho Claude khi sửa map

1. Trước khi đụng tới `adult.gd` / `aquatic.gd` / scene map → **đọc file này**.
2. Không đổi `rect`, `centerline`, `pos`, `size`, thứ tự zone nếu chưa sửa Bible.
3. Mọi object mới phải gán `zone id` (Z01–Z08) và nằm trong `rect` của zone đó.
4. Không đặt nhà trong ruộng, cây thân gỗ trong ruộng, nhà sát mặt nước (< 12 m).
5. Sau mỗi thay đổi lớn: so sánh với ảnh MASTER REFERENCE + minimap; số marker ①–⑦ phải khớp §3.
6. Nếu xung đột giữa file này và ảnh → **ảnh thắng**, rồi sửa file này.

---

## 15. Pipeline sinh map (Blender → GLB → Godot)

File này là **Reference B (Layout)**. Hai reference còn lại: A Visual = [`ART_DIRECTION.md`](ART_DIRECTION.md),
C Asset sheet = [`ASSET_GUIDELINES.md`](ASSET_GUIDELINES.md). Thứ tự milestone: [`ROADMAP.md`](ROADMAP.md).

- **Dữ liệu máy đọc**: [`docs/map_spec.json`](map_spec.json) là bản sao số liệu của file này. Sửa Bible → sửa JSON cho khớp
  (cùng một commit). Các script tự kiểm tra luật §7/§14 và in cảnh báo `⚠ BIBLE` (`--strict` để dừng).
- **M0 2D blockout**: `python blender/scripts/blockout_2d.py` → `docs/reference/layout/00_blockout_2d.png` + 8 sheet zone.
- **M1 3D greybox**: `blender -b -P blender/scripts/generate_map.py -- --stage greybox --godot` → Terrain, Water, Road,
  8 Zone, House placeholders, Fence, các `*Point`, Spawn, Camera bounds → xem bằng `godot/world/greybox_viewer.tscn`.
- **M2 thay model thật** (chỉ sau khi M1 được xác nhận): `--stage env --swap` với `assets/asset_manifest.json`
  (`HousePoint_01 → house_vn_01.glb`…).
- Hướng dẫn chi tiết: [`blender/README.md`](../blender/README.md).

---

## 16. Changelog

| Ngày | Thay đổi |
|---|---|
| 2026-10-05 | **M4** — game dùng map này cho giai đoạn trưởng thành (§11.1 đã migrate). Không đổi số liệu bố cục; `map_spec.json` được copy sang `godot/world/generated/` để game tra zone/đường/kênh/vùng bay. |
| 2026-10-03 | Mật độ rừng tre 0.35 → ~0.15 khóm/m² (`min_dist` 1.7 → 2.6 m) khi thay bằng model tre thật (khóm lớn ~15 cây, tán 6 m): rừng vẫn kín, giảm ~55% số khóm cho Godot. Không đổi vị trí zone. |
| 2026-10-03 | **Duyệt M1** (`check_greybox.py`) — sửa lỗi hình học: cầu R2 dời về đúng tâm kênh (114 → 111) và dài 16 → 24 m để phủ hết hai bờ; W07 dời (406,297) → (385,282) vì cũ nằm trên giao điểm bờ ruộng (khô); bờ thửa ruộng căn theo R4 (z = 300) thay vì chia đều 6 hàng (trước đó có 2 bờ cách nhau 2.5 m); R4 nối tới R1 qua cống L11; kênh nhánh hạ mặt nước 0.0 → −0.25 m để hợp lưu êm với kênh chính. |
| 2026-10-03 | Tổ chức lại: spec → `docs/map_spec.json`, script → `blender/scripts/`, manifest → `assets/`; thêm M0 blockout + 3 loại reference (§15). Không đổi số liệu bố cục. |
| 2026-10-03 | Thêm §15 pipeline + `map_spec.json`. Sửa nhất quán (không đổi vị trí): L05 thuộc Z01 (toạ độ (225,110) nằm trong rect Z01); thêm vũng `[330,450,2]` cho W01; khai báo đường mòn tre T1 (đã có ở §8/L12). |
| 2026-10-03 | Bản đầu tiên: số liệu đo từ minimap của ảnh MASTER REFERENCE. Kích thước 500 × 540 m (tỉ lệ minimap), khác ví dụ 500 × 400 ban đầu để giữ đúng bố cục ảnh. |
