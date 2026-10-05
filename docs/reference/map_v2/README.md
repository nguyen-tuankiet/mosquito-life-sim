# MAP v2 — làng đông đúc, tự nhiên hơn (2026-10-05)

Phản hồi của chủ dự án sau M4: *"chỉ có vài nhà cách xa nhau quá, nhìn map trống trải"* — muốn một **làng thật**
(cụm nhà + ngõ nhánh + vườn/ao xen giữa), phạm vi sửa nhỏ.

## Đã đổi (không đổi kích thước map, 8 zone, nước, ruộng, điểm đẻ trứng, nhà chính H01)

| | v1 | v2 |
|---|---|---|
| Số nhà | 7, cách nhau ≥ 25 m | **18**, 3 xóm, cách nhau ≥ 16 m, lệch hướng 3–8° |
| Đường | R1–R5 + lối mòn tre | + **ngõ N1** (xóm Đông), **ngõ N2** (sau H01), **lối nhỏ** từ cửa từng nhà ra đường gần nhất (tự sinh) |
| Xóm ao | — | 3 nhà dọc R3 sát ao làng (Z01 thêm rect [220,300,282,375]) |
| Lô đất mỗi nhà | sân đất vuông | sân bo tròn phía cửa · chum, xô, chậu · gà · đống rơm · 2–3 cây ăn trái · chuối hai bên · dừa · rào tre sau + hai bên |
| Vườn | chỉ trong Z02 | cây ăn trái xen giữa các nhà khắp Z01, thưa dần ra mép làng (không thẳng theo hình chữ nhật) |
| Game | — | thêm bác hàng xóm đi trên ngõ N1 ban ngày; cây vườn + đống rơm = chỗ ẩn/đậu (241 → 528) |

Số liệu: `docs/map_spec.json` (houses.list, houses.lots, roads.N1/N2, zones.Z01) · Bible §7 + changelog ·
code: `common.add_footpaths()`, `generate_village._lots()`, `generate_terrain` (sân), `generate_foliage` (mép vườn).

## Ảnh (Godot 4.7)

| | |
|---|---|
| ![](top_village.webp) làng chính nhìn từ trên | ![](top_pond_hamlet.webp) xóm ao cạnh ao làng |
| ![](lane_N1.webp) ngõ N1 ở tầm muỗi | ![](hamlet.webp) xóm ao ở tầm muỗi |

Bố cục 2D: [`../layout/01_house.png`](../layout/01_house.png)

## Chưa làm (để giữ phạm vi nhỏ)

- Chợ nhỏ ở ngã ba, cổng làng, giếng/ghế đá quanh ao.
- Khoảng đất trống giữa làng chính (z 185) và xóm ao (z 300) vẫn là cỏ.
- Người dân sống theo lịch cả làng (ra đồng, đi chợ, nghỉ trưa) — hiện mới có gia đình H01 theo lịch, người ngoài đường chỉ đi qua lại ban ngày.
