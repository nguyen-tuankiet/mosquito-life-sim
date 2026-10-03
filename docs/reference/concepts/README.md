# Concept cho AI 3D (bước 1 của pipeline asset)

Ảnh concept để đưa vào **Meshy / Tripo / Rodin** (image → 3D) cho các model ưu tiên cần AI 3D
(`docs/ASSET_GUIDELINES.md §6`). Cây cỏ (tre, lúa, dừa, chuối, cỏ) **không** làm concept: lấy từ asset library.

Tạo ngày 2026-10-03 bằng OpenArt (tài khoản OpenArt của chủ dự án, gói Free → ảnh có watermark), model **Wan 2.7 Image**,
tier standard, 2K, 6 credit/ảnh. Ảnh nằm trong tài khoản OpenArt (mục Creations); môi trường của Claude không tải được
CDN OpenArt nên ảnh **không** có trong repo. Khi dùng: tải bản gốc từ OpenArt → lưu vào thư mục này với tên `<file>.png`.

| File đích | Thư mục | OpenArt historyId | Khung | Ghi chú khi làm 3D |
|---|---|---|---|---|
| `house_vn_01.glb` | `assets/environment/houses/` | `vdJDFrYbbNyPcgdDEBJj` | 16:9 | Nhà chính H01: hiên 5 cột, 3 cửa, ~14 × 9 m |
| `house_vn_02.glb` | `assets/environment/houses/` | `yjju7dzhF0Iwxx2j9qn0` | 16:9 | Nhà nhỏ tường vàng + bếp mái tôn, ~11 × 8 m |
| `water_jar_vn.glb` | `assets/props/water_jars/` | `rdkkPjnxNaN74STtaPxh` | 1:1 | Chum W03 (spawn): cao 0.9 m, **phải hở miệng + có mặt nước** |
| `bamboo_fence.glb` | `assets/environment/roads/` | `dZz8eOZIvuK4FSNCqa63` | 16:9 | Đoạn rào **dài 3 m theo trục X**, cao ~1.1 m |
| `water_buffalo.glb` | `assets/creatures/` | `OSYusFmFmPiQXMhxn6xN` | 4:3 | Trâu đứng yên, thay `cow.glb` (sai loài) |

## Từ concept tới map

1. Tải ảnh gốc từ OpenArt. Gói Free có watermark → nên xoá watermark (hoặc nâng gói / tạo lại) trước khi đưa vào AI 3D,
   vì watermark có thể bị "nặn" thành hình khối.
2. Meshy / Tripo / Rodin → *Image to 3D* → xuất **GLB** có texture PBR.
3. Blender cleanup theo `docs/ASSET_GUIDELINES.md §4` (mét, gốc đáy-giữa, mặt trước −Y, ngân sách tam giác).
4. Lưu đúng tên + thư mục ở bảng trên → `blender -b -P blender/scripts/generate_map.py -- --stage env --res 1 --swap --godot`
   → model thật tự thay bản procedural.
5. `python blender/scripts/render_views.py && python blender/scripts/compare_reference.py` → so lại với ảnh reference.
6. Ghi nguồn + giấy phép (OpenArt / Meshy…) vào `assets/CREDITS.md`, commit `.glb` qua Git LFS.

## Prompt (để tạo lại / làm biến thể cùng phong cách)

Khuôn chung: *"3D asset concept reference for image-to-3D: … isolated object only … three-quarter view … whole object
fully in frame, centered … plain flat light-grey studio background, soft even lighting, no cast shadows, no text."*
Màu lấy từ `docs/ART_DIRECTION.md §3`. Prompt đầy đủ từng ảnh xem trong OpenArt (mục chi tiết của historyId ở bảng trên).
