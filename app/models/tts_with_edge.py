import asyncio
import edge_tts
from gtts import gTTS
import os

async def generate_tts_audio(text: str, output_file: str, voice: str = "vi-VN-HoaiAnNeural"):
    """
    Sử dụng Edge TTS để chuyển câu văn thành file âm thanh phản hồi dạng MP3.
    Nếu Server Microsoft gặp sự cố mạng (IPv6, chặn cổng) hoặc lỗi NoAudioReceived,
    hệ thống tự động Fallback sang Google TTS để cam kết luôn xuất được file âm thanh thành công.
    """
    try:
        print(f"⏳ [Edge-TTS] Đang gửi văn bản sang Server Microsoft: {text}")
        
        # Khởi tạo tiến trình giao tiếp WebSocket với Microsoft
        communicate = edge_tts.Communicate(text=text, voice=voice)
        
        # Tải và ghi file âm thanh
        await communicate.save(output_file)
        print("✅ [Edge-TTS] Xuất file âm thanh từ Microsoft thành công.")
        
    except (edge_tts.exceptions.NoAudioReceived, Exception) as e:
        print(f"⚠️ [Mạng lỗi hoặc Chặn cổng] Edge TTS thất bại ({str(e)}).")
        print("🔄 Hệ thống tự động chuyển hướng (Fallback) sang Google TTS...")
        
        try:
            # gTTS là thư viện đồng bộ, ta bọc nó trong asyncio.to_thread để tránh block Event Loop
            def run_google_tts():
                tts = gTTS(text=text, lang='vi', slow=False)
                tts.save(output_file)
                
            await asyncio.to_thread(run_google_tts)
            print("✅ [Google-TTS] Xuất file âm thanh dự phòng thành công.")
            
        except Exception as google_err:
            print(f"❌ Lỗi nghiêm trọng: Cả Microsoft và Google TTS đều thất bại do mất mạng diện rộng: {str(google_err)}")
            raise google_err
