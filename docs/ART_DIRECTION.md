# ART DIRECTION — Reference A (Visual)

> **"Game must look like this."**
> Ảnh chuẩn: [`docs/reference/visual/master_reference.webp`](reference/visual/master_reference.webp)
> (ảnh "Bối cảnh bản đồ – Làng quê Việt Nam").
>
> Map dùng **3 loại reference**, phải dùng cả 3 khi làm map:
>
> | Loại | Trả lời câu hỏi | File |
> |---|---|---|
> | **A — Visual** | Trông như thế nào? (màu, ánh sáng, mood, vật liệu) | file này + ảnh gốc |
> | **B — Layout** | Cái gì nằm ở đâu, to bao nhiêu? | [`MAP_BIBLE.md`](MAP_BIBLE.md), [`map_spec.json`](map_spec.json), [`reference/layout/`](reference/layout/) (`00_blockout_2d.png`, `01_house.png` … `08_road.png`) |
> | **C — Asset sheet** | Cần những model nào cho từng zone? | [`ASSET_GUIDELINES.md`](ASSET_GUIDELINES.md) |
>
> Khi xung đột: **B thắng về vị trí/kích thước**, **A thắng về màu/ánh sáng/hình dáng**, C phải phục vụ A + B.

---

## 1. Tinh thần

**Gần gũi – Đời thường – Đa dạng môi trường nước.** Một làng quê đồng bằng Việt Nam bình thường, sống động,
hơi ẩm, nhiều nước đọng — nhìn qua là thấy "chỗ này muỗi sống được".

- Bán hiện thực (stylized-realistic), **không** cartoon, **không** low-poly phẳng màu.
- Chi tiết dày, lộn xộn có chủ đích: chậu, xô, lu, lốp xe, rơm, lá rụng, rêu — đời sống thật, không sạch sẽ kiểu showroom.
- Mọi thứ nhìn từ **góc nhìn con muỗi** cũng phải đẹp: bề mặt nước, mép lu, lá chuối, thân tre ở cự ly gần.

## 2. Ánh sáng & thời gian

| Thời điểm | Đặc điểm (theo ảnh chính + ô "THỜI TIẾT & THỜI GIAN") |
|---|---|
| **Ban ngày (key look)** | Nắng **chiều muộn / giờ vàng**: mặt trời thấp, ánh vàng-cam ấm, bóng dài mềm; bầu trời xanh trong với mây tích trắng lớn; phía xa có lớp sương mỏng làm nhạt núi |
| **Ban đêm** | Xanh dương đậm, trăng tròn sáng, sao; đèn vàng ấm từ cửa sổ nhà; mặt nước phản chiếu trăng; tối nhưng **vẫn đọc được hình khối** |
| Chuyển tiếp | Bình minh/hoàng hôn lấy cảm hứng từ key look; không có cảnh trưa gắt màu trắng |

- Mặt trời key look: cao ~30–35°, chiếu xiên từ phía sau-bên → viền sáng (rim light) trên lá, rơm, mái ngói.
- Tương phản vừa phải; vùng tối dưới tán cây hơi xanh-lục, không đen kịt.
- Sương xa (aerial perspective) bắt buộc: núi và hàng dừa xa nhạt dần sang xanh-xám.

## 3. Bảng màu mục tiêu

| Vai trò | Màu gợi ý | Ghi chú |
|---|---|---|
| Trời (đỉnh → chân trời) | `#4F86C6` → `#BFD7E6` | mây trắng ấm `#F4F1EA` |
| Lá xanh đậm (tre, cây vườn) | `#2F5A22` | bóng lá `#1E3A18` |
| Lá xanh sáng (chuối, cỏ nắng) | `#7DA83A` | |
| Lúa non | `#8DBF3F` | sáng và rực hơn mọi mảng xanh khác |
| Đất đường làng | `#9A6B45` | đất ẩm sẫm hơn `#6E4B33` |
| Mái ngói | `#A4532F` | ngói cũ có rêu xám-lục |
| Tường vôi | `#D9CBB0` | ố vàng, bong tróc |
| Gỗ (hiên, cầu ao, thuyền) | `#6B4A30` | |
| Lu sành | `#5E4030` | men nâu bóng nhẹ |
| Nước ao | `#4E7680` | phản chiếu trời, hơi đục xanh lục |
| Nước tù / mương | `#5B6B48` | đục, có bèo |
| Đêm | `#14223F` | ánh đèn `#F2B35C` |

Màu zone trong greybox (`map_spec.json → zones.*.color`) chỉ để phân biệt khu vực, **không** phải màu cuối.

## 4. Vật liệu & hình dáng theo zone

| Zone | Phải thấy được |
|---|---|
| 01 Nhà dân | Nhà một tầng mái ngói đỏ-nâu, hiên gỗ, cột gỗ, tường vôi cũ; sân gạch/đất; lồng chim treo hiên; lu sành lớn, xô nhựa xanh/đỏ, chậu nhôm; gà |
| 02 Vườn / Chuồng trại | Cây lớn có hốc, chuối, cây ăn trái, đống rơm, chòi tre, chuồng gà, lá mục dưới gốc |
| 03 Ao / Hồ | Mặt nước tĩnh soi bóng, bèo, súng, sậy ven bờ, cầu ao bằng gỗ, thuyền gỗ nhỏ |
| 04 Ruộng lúa | Thửa ruộng ngập nước nông, bờ ruộng thẳng, lúa non xanh rực, trâu, chòi ruộng, núi xa |
| 05 Kênh mương | Dòng nước hẹp chảy chậm, bờ đất dốc, cỏ và chuối ven bờ, cầu nhỏ |
| 06 Rừng tre / Bụi rậm | Tre dày cao, ánh sáng lọt qua kẽ lá, lối mòn đất, lá tre khô phủ nền |
| 07 Đồng cỏ | Cỏ cao xanh-vàng, vũng nước sau mưa, cây lẻ, cảm giác trống trải |
| 08 Đường làng | Đường đất đỏ có vệt bánh xe, hàng rào tre/gỗ hai bên, cột điện + dây |

## 5. Bố cục khung hình (camera)

- Key shot = **ảnh chính**. Vì layout (Reference B) đặt ao cách nhà H01 ~270 m, khung hình được dựng lại theo hướng (a)
  ([`M1_REVIEW.md §4`](reference/greybox/M1_REVIEW.md)): đứng ở **bờ Đông ao cạnh cầu ao L08**, nhìn về Tây — tiền cảnh
  bờ + sậy, trung cảnh ao + cầu ao + bèo, hậu cảnh vườn + rừng tre. Tinh thần "lu + xô + sân nhà" được giữ ở postcard 1.
  Camera: `blender/scripts/render_views.py → POSTCARDS`.
- Mỗi ảnh nhỏ 1–8 trong reference = 1 "postcard shot" của zone đó; M3 phải có 8 camera bookmark tương ứng.

## 6. Không được

- Không màu bão hoà kiểu game mobile; không cỏ xanh neon.
- Không asset phong cách khác nhau đặt cạnh nhau (VD: nhà low-poly cạnh cây photoscan).
- Không đổi bố cục để "vừa" một model đẹp — tìm model vừa bố cục (xem [`ROADMAP.md`](ROADMAP.md)).
