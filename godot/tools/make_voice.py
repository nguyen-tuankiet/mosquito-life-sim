"""Tạo giọng thuyết minh (Microsoft Edge TTS, vi-VN-HoaiMyNeural). Chạy: python tools/make_voice.py"""
import asyncio, os, edge_tts
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'voice')
TXT = {
 'egg': "Giai đoạn một: trứng. Muỗi cái đẻ trứng trên thành các vật chứa nước, ngay sát mép nước. Trứng nhỏ, màu đen, có thể chịu khô hạn trong một thời gian ngắn, và chỉ nở khi gặp nước.",
 'larva': "Giai đoạn hai: lăng quăng. Sống dưới nước, lăng quăng ăn vi khuẩn, tảo, vi sinh vật và mùn bã hữu cơ. Chúng thở bằng ống thở ở mặt nước, và lột xác bốn lần qua bốn tuổi.",
 'pupa': "Giai đoạn ba: nhộng. Nhộng vẫn sống trong nước nhưng không ăn. Bên trong lớp vỏ, cơ thể đang được tái cấu trúc thành muỗi. Lúc này đã có thể phân biệt giới tính: con đực nhỏ hơn, con cái lớn hơn. Sau hai đến ba ngày, nhộng sẽ hóa thành muỗi trưởng thành.",
 'adult': "Giai đoạn bốn: muỗi trưởng thành. Muỗi sống trên cạn, thường ở những nơi râm mát, ẩm ướt. Con cái hút máu để lấy protein nuôi trứng, còn con đực chỉ hút mật hoa và dịch thực vật. Từ trứng đến muỗi trưởng thành chỉ mất khoảng bảy đến mười ngày.",
 'sex': "Làm sao phân biệt muỗi đực và muỗi cái? Muỗi đực nhỏ hơn, râu xù lông, và không hút máu. Muỗi cái lớn hơn, râu ít lông, có vòi dài để hút máu. Muỗi cái cần máu để phát triển trứng.",
 'mating': "Giao phối. Sau khi trưởng thành, muỗi cần khoảng hai mươi bốn đến bốn mươi tám giờ để hoàn thiện sinh dục. Muỗi đực bay thành đàn nhỏ, nghe tiếng vỗ cánh để tìm muỗi cái. Sau khi giao phối, muỗi cái đi tìm nguồn máu.",
 'lay': "Đẻ trứng. Sau khi hút máu và nghỉ tiêu hóa, muỗi cái tìm nơi có nước đọng để đẻ trứng. Mỗi lần đẻ khoảng bảy mươi đến một trăm trứng. Trứng có thể tồn tại nhiều tháng khi khô hạn, và nở thành lăng quăng ngay khi gặp nước.",
 'cycle': "Đó là một vòng đời khép kín: trứng, lăng quăng, nhộng, muỗi trưởng thành, giao phối, rồi lại đẻ trứng. Hiểu rõ vòng đời này giúp chúng ta phòng ngừa và kiểm soát muỗi hiệu quả.",
 'overview': "Bây giờ, bạn sẽ không chỉ đọc về vòng đời ấy. Bạn sẽ sống trọn nó, bắt đầu từ một quả trứng nhỏ trên mặt nước. Chúc bạn sống sót!",
}
VOICE = 'vi-VN-NamMinhNeural'   # giọng nam trầm kiểu phim tài liệu; đổi lại 'vi-VN-HoaiMyNeural' cho giọng nữ
async def main():
    for k, t in TXT.items():
        await edge_tts.Communicate(t, 'vi-VN-NamMinhNeural', rate='-8%', pitch='-2Hz').save(os.path.join(OUT, k + '.mp3'))
        print('ok', k)
asyncio.run(main())
