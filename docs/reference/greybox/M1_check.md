# M1 — Kết quả kiểm tra tự động greybox

Sinh bởi `python blender/scripts/check_greybox.py` từ `docs/map_spec.json`.

| Nhóm | Kết quả | Chi tiết |
|---|---|---|
| Bố cục | ✅ PASS | Khớp luật MAP_BIBLE §7/§14 |
| Chìm / lơ lửng | ✅ PASS | 148 vật thể, sai lệch ≤ 0.15 m |
| Nền nhà | ✅ PASS | 7/7 nhà phẳng ở y = 0.6 m |
| Đường | ✅ PASS | R1_main_spine: dài 430 m, dốc max 1% |
| Đường | ✅ PASS | R2_bridge_lane: dài 225 m, dốc max 2% |
| Đường | ✅ PASS | R3_pond_lane: dài 70 m, dốc max 7% |
| Đường | ✅ PASS | R4_field_bund: dài 202 m, dốc max 1% |
| Đường | ✅ PASS | R5_meadow_lane: dài 55 m, dốc max 0% |
| Đường | ✅ PASS | T1_bamboo_trail: dài 80 m, dốc max 9% |
| Đường | ✅ PASS | Cầu B1_R2: hai đầu cầu y = 0.22 / 0.17, mặt cầu 1.2 m |
| Đường | ⚠️ WARN | Không nối với R1: T1_bamboo_trail (đi bộ không tới; muỗi bay vẫn tới) |
| Mặt nước | ✅ PASS | canal_main: bờ ≥ mặt nước -0.3 m tại 1629 điểm; lòng sâu 1.76–1.80 m; 8 m đi dưới cầu/cống |
| Mặt nước | ✅ PASS | canal_branch: bờ ≥ mặt nước -0.25 m tại 629 điểm; lòng sâu 0.59–0.84 m; 15 m đi dưới cầu/cống |
| Mặt nước | ✅ PASS | pond_main: bờ min -0.02 ≥ mặt nước -0.2; đáy -2.70 m |
| Mặt nước | ✅ PASS | paddy_main: 90% mặt ruộng ngập (còn lại là bờ ruộng); mép ruộng kín |
| Camera bounds | ✅ PASS | Mọi vật thể nằm trong playable_rect |
