import os
from faster_whisper import WhisperModel

print("📥 Đang nạp model Whisper 'base' (int8) vào RAM...")
# Load model một lần duy nhất khi import module để tiết kiệm tài nguyên
whisper_model = WhisperModel(
    "base",
    device="cpu",        # Đổi thành "cuda" nếu thiết bị của bạn có GPU hỗ trợ
    compute_type="int8"  # Tối ưu hóa dung lượng RAM cho thiết bị nhúng
)
print("✅ Model Whisper đã sẵn sàng.")

def transcribe_audio_file(file_path: str) -> str:
    """
    Nhận đường dẫn một file âm thanh và chuyển đổi sang văn bản tiếng Việt (STT).
    """
    if not os.path.exists(file_path):
        return ""
        
    print("🧠 AI đang dịch giọng nói từ file âm thanh...")
    segments, info = whisper_model.transcribe(file_path, language="vi")

    full_text = ""
    for segment in segments:
        full_text += segment.text + " "

    return full_text.strip()
