# M3 — Cinematic: kết quả và tự đánh giá

| | |
|---|---|
| Ngày | 2026-10-05 |
| Thực hiện | Claude |
| Trạng thái | **Xong bản v1, CHỜ CHỦ DỰ ÁN DUYỆT** (M3 = "phải giống MOOD"); phần Godot **chưa chạy thử** (môi trường không có Godot, chỉ kiểm cú pháp bằng gdtoolkit) |

## 1. Đã làm

**Một nguồn thông số cho cả ảnh duyệt và game:** [`docs/art_look.json`](../../art_look.json) — khoá theo giờ (màu nắng, cường độ,
màu trời đỉnh/chân trời, mây, sương, ánh sáng môi trường, đèn cửa sổ), đường đi mặt trời (mọc 6h hướng Đông, lặn 18h30
hướng Tây-Tây Nam), trăng, color grading. Sửa file này → cả Blender lẫn Godot đổi theo.

| Hạng mục (ROADMAP M3) | Blender (ảnh duyệt) | Godot (game) |
|---|---|---|
| Nắng giờ vàng / trưa / đêm trăng | `blender/scripts/lighting.py` | `godot/world/day_night.gd` — chu kỳ ngày–đêm, `auto` = 75 s/ngày (khớp `DAY_LEN_ADULT`) |
| Trời: dải màu, mây tích, dãy núi xa phía Bắc, trăng, sao | node world (cùng cách chiếu) | `godot/shaders/village_sky.gdshader` |
| Sương xa / quầng ngược nắng | khối volume 2 × 2 km (không dùng world volume — vô hạn, nuốt hết nắng) | fog + `fog_sun_scatter` |
| Bóng đổ | mặt trời + trăng | DirectionalLight PSSM 4 tầng, 250 m |
| Đèn vàng trước cửa từng nhà ban đêm | point light | OmniLight3D đọc từ `map_layout.json` |
| Gió lay cây cỏ | — | `foliage_wind.gdshader`: tre, lúa, cỏ, sậy, bụi (MultiMesh) + chuối, dừa, cây vườn, cây đa (GLB) |
| Nước | từ M2, phản chiếu trời | `water_surface.gdshader` (M2) |
| Color grading | AgX + bão hoà/tương phản sau render | AgX + `adjustment_*` + glow |

Xem trong Godot: `godot/world/greybox_viewer.tscn` → F6. **T** = chạy/dừng thời gian · **[ ]** = ±1 giờ ·
**H** = giờ vàng · **J** = trưa · **N** = đêm (cộng các phím cũ 1–8, 0, Tab, F, G, R).

## 2. So sánh với Reference A

- Giờ vàng (key look): [`golden/compare_reference.webp`](golden/compare_reference.webp)
- Ban đêm (ô "Ban đêm" của reference): [`night/compare_reference.webp`](night/compare_reference.webp)

Chạy lại:
```
python blender/scripts/render_views.py --time golden
python blender/scripts/render_views.py --time night --samples 32
python blender/scripts/compare_reference.py --renders docs/reference/m3/golden
python blender/scripts/compare_reference.py --renders docs/reference/m3/night --night
```

| | Giống | Chưa giống |
|---|---|---|
| Giờ vàng | Trời xanh + mây tích trắng, chân trời ấm, bóng dài, kênh/ao soi bóng trời, núi xa ở ruộng lúa | Ánh nắng chưa "rực" như ảnh (ảnh reference là tranh vẽ, tương phản cao); tiền cảnh còn thưa so với ảnh |
| Ban đêm | Trời xanh đậm có sao, nhà đèn vàng ấm, vẫn đọc được hình khối | Ảnh reference có trăng trong khung hình + nhiều đèn lấp ló giữa cây; khung đêm của ta chưa quay về phía trăng |

**Nhận định:** mood (giờ vàng ấm, đêm trăng xanh) đã khớp tinh thần Reference A. Khoảng cách còn lại chủ yếu là
**độ rậm + chất lượng asset ở tiền cảnh** (cần thêm model thật: cây vườn, cây đa, lúa, sậy, bụi…), không còn là ánh sáng.

## 3. Còn mở

- Godot chưa chạy thật: cần mở `greybox_viewer.tscn` (F6) để kiểm hiệu năng (bóng đổ 250 m + ~110k instance có gió)
  và chỉnh `art_look.json` nếu màu trong game lệch so với ảnh Blender.
- Ảnh toàn cảnh ban đêm (nhìn từ 330 m qua khối sương) hơi ám vàng-xanh; không ảnh hưởng khung tầm mắt.
- Mây/dãy núi: Blender và Godot cùng cách chiếu nhưng khác hàm nhiễu → hình dạng mây/núi không trùng từng pixel.
- Asset P1 (ROADMAP) chưa làm.
