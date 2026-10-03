# Nguồn gốc & giấy phép asset (assets/)

| File | Nguồn | Giấy phép / điều khoản | Xử lý (blender/scripts/import_asset.py, assets/import_config.json) |
|---|---|---|---|
| `environment/houses/house_vn_01.glb` | Hunyuan3D-2.1 (Tencent) — chỉ dựng hình, từ concept OpenArt `vdJDFrYbbNyPcgdDEBJj` | Tencent Hunyuan 3D 2.1 Community License (không áp dụng tại EU, UK, Hàn Quốc) | scale 14.4 m, 40k → 15k tris, vật liệu tự gán theo vùng (`auto_house`) |
| `environment/houses/house_vn_02.glb` | AI 3D có texture, từ concept OpenArt `yjju7dzhF0Iwxx2j9qn0` | theo điều khoản công cụ AI 3D đã dùng | xoay 180°, scale 11 m, 30.8k → 15k tris, texture 1024 |
| `props/water_jars/water_jar_vn.glb` | Hunyuan3D-2.1 — chỉ dựng hình, từ concept OpenArt `rdkkPjnxNaN74STtaPxh` | Tencent Hunyuan 3D 2.1 Community License | cao 0.9 m, 20k → 6k tris, men sành procedural (UV trụ), thêm mặt nước |
| `environment/roads/bamboo_fence.glb` | Hunyuan3D-2.1 — chỉ dựng hình, từ concept OpenArt `dZz8eOZIvuK4FSNCqa63` | Tencent Hunyuan 3D 2.1 Community License | 3.0 × 0.2 × 1.1 m (scale từng trục), 20k → 6k tris, tre khô procedural |
| `environment/bamboo/bamboo_clump_01.glb`, `bamboo_clump_02.glb` | model do chủ dự án cung cấp (`bamboo.glb`); 02 là biến thể xoay 137°, thấp hơn | chưa ghi — **chủ dự án bổ sung** | 56k → 4k tris, cao 11 m / 9.5 m |
| `environment/gardens/banana_clump_vn.glb` | model do chủ dự án cung cấp (`banana_plant.glb`) | chưa ghi — **chủ dự án bổ sung** | cao 3.5 m, 4.3k tris, texture ≤ 1K |
| `environment/grasslands/coconut_palm.glb` | model do chủ dự án cung cấp (`coconut_palm.glb`, cặp 2 cây dừa) | chưa ghi — **chủ dự án bổ sung** | cao 13 m, 6.6k tris, texture ≤ 1K |
| `creatures/chicken_vn.glb` | model do chủ dự án cung cấp (`chicken.glb`, nguồn Sketchfab) | chưa ghi — **kiểm tra giấy phép Sketchfab** | áp tư thế rig → mesh tĩnh, cao 0.45 m, texture 2K → 1K |
| `creatures/water_buffalo.glb` | model do chủ dự án cung cấp (`african_buffalo.glb`, nguồn Sketchfab) — **trâu châu Phi**, tạm thay trâu nước VN | chưa ghi — **kiểm tra giấy phép Sketchfab** | áp tư thế rig → mesh tĩnh, xoay 45°, cao 1.5 m |
| `environment/gardens/flower_pot_vn.glb` | Poly Haven — *Potted Plant 02* | CC0 | 70k → 8k tris, texture 4K → 1K (chưa đặt vào map: chưa có Point chậu cây) |

Ảnh concept: OpenArt (Wan 2.7 Image), xem `docs/reference/concepts/README.md`.
