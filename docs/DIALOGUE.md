# Thoại NPC — làng quê miền Tây Nam Bộ

Ảnh: [chợ sáng](reference/dialogue/market.webp) · [hóng mát buổi tối](reference/dialogue/evening2.webp)

Kho câu: [`godot/data/thoai_mientay.json`](../godot/data/thoai_mientay.json) · bộ chọn câu: `godot/scripts/talk.gd` ·
gắn vào game: `godot/scripts/adult.gd` (mục "thoại NPC") · kiểm thử: `--scenario=test_talk`.

## 1. Quy tắc viết (bắt buộc)

1. **Nói như người thật ngoài đời**, không "diễn giọng miền Tây", không văn viết, không thoại phim truyền hình.
2. **Câu ngắn**, có nhịp nói: một ý, có khi cụt lủn ("Ngứa.", "Làm. Nói chi nhiều.").
3. **Khẩu ngữ Nam Bộ dùng khi hợp**, không nhét vào mọi câu: *hổng, hông, dzậy, coi, hoài, dữ vậy, quá trời, thiệt, dìa,
   bây, mậy, chớ…* — kiểm thử giữ tỉ lệ câu có các từ này khoảng 12–55 % (hiện ~21 %).
4. **Không lạm dụng** "mèn ơi", "trời đất ơi", "nghen", "hen" (kiểm thử: tối đa 1 lần trong cả kho).
5. **Xưng hô theo quan hệ**: má, tía, ông, bà, cô, chú, anh Hai, chị Ba, con… ; "tao–mày" giữa bạn bè, người nhà, trẻ con
   với nhau, hoặc khi bực. Người nói tự xưng bằng `{t}` (tự điền: tao / tui / ông / bà / con theo tính cách & giới).
6. **Chửi vui / cà khịa ~5–10 %** và chỉ khi gặp chuyện khó chịu (bị chích, đập hụt…): đánh dấu câu bằng `~` ở đầu.
   Chửi phải hài, mộc, không tục quá: *Má mày, Má nó, Đậu má, Con quỷ, Cha nó, Đồ quỷ, Bộ máu tao ngon lắm hả?*
   Con nít không chửi (chỉ "Con muỗi quỷ!").
7. **NPC có đời sống riêng** — đa số câu là chuyện làm ruộng, bán hàng, nấu ăn, sửa đồ, đi chợ, con cái, đám giỗ, giá lúa…
   Muỗi chỉ là một phần đời họ.
8. **Phản ứng với muỗi tuỳ người**: có người chỉ gãi, có người đập, có người chửi vui, có người **mặc kệ** (chuỗi rỗng `""` = im).

## 2. Tính cách

| Mã | Tính cách | Tự xưng | Chửi vui | Nói nhiều | Ai |
|---|---|---|---|---|---|
| `hien` | Hiền | tui | 4 % | ít | cô bán rau, một số người làng |
| `nong` | Nóng tính | tao | 35 % | vừa | mẹ (nhà H01), người qua đường |
| `ron` | Cà rỡn | tao | 22 % | nhiều | bố (nhà H01), người đi chợ |
| `gia` | Lớn tuổi | ông / bà | 8 % | vừa | cụ già các nhà, bà bán quả |
| `nit` | Con nít | con | 0 % | nhiều | bé nhà H01, trẻ con trong xóm |
| `thatha` | Thật thà | tui | 8 % | vừa | người làng, người đi chợ |
| `coc` | Cộc tính | tao | 30 % | rất ít | bác bán cá, một số người làng |

"Chửi vui" = xác suất bốc câu `~` khi ngữ cảnh có câu đó. Trung bình cả làng khi bị muỗi làm phiền: **~5,4 %** (kiểm thử 4–12 %).

## 3. Ngữ cảnh

| Nhóm | Ngữ cảnh | Khi nào |
|---|---|---|
| Đời thường (người làng) | `field` `market_sell` `market_buy` `yard` `sit` `pond` `kid` `walk` | theo việc đang làm (lịch người dân, chợ) khi muỗi ở trong 20 m, mỗi 9–20 s |
| Đời thường (nhà H01) | `cook` `eat` `tv` `chore` `read` `water` `study` `play` `exercise` `sleep` | theo lịch sinh hoạt trong nhà |
| Muỗi | `hear` (nghe vo ve) · `night_hear` (đang ngủ) · `scratch` (gãi) · `swat` (giơ tay đập) · `miss` (hụt) · `hit` (trúng) · `bitten` (đang bị hút) · `lost` (muỗi bay mất) | theo mức cảnh giác ? → ! → ĐẬP |
| Hàng xóm | `chat` — cặp hỏi–đáp | hai người lớn đứng/ngồi trong 5 m: người này hỏi, người kia đáp sau ~2 s |

## 4. Thêm câu

- Thêm vào đúng ngữ cảnh + tính cách (`"*"` = ai cũng nói được). Câu ≤ 72 ký tự.
- Câu chửi vui bắt đầu bằng `~`. Câu có tự xưng dùng `{t}` / `{T}` (đầu câu).
- Chạy `godot --headless --fixed-fps 60 --path godot --quit-after 300 -- --scenario=test_talk` để kiểm: đủ câu cho mọi tính cách,
  tỉ lệ chửi vui, không lạm dụng từ "giả giọng", in vài câu mẫu.
