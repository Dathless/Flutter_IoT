import asyncio  # Bắt buộc để dùng asyncio.to_thread
import os
import aiofiles
from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse

from app.models.stt import transcribe_audio_file
from app.models.qwen_25 import ai_process_text  # Đã sửa đổi import chính xác
from app.models.tts_with_edge import generate_tts_audio

router = APIRouter(prefix="/ai", tags=["AI Smart Home Core"])

TEMP_DIR = "app/temp_audio"
os.makedirs(TEMP_DIR, exist_ok=True)

TEMP_INPUT_WAV = os.path.join(TEMP_DIR, "user_input.wav")
RESPONSE_MP3 = os.path.join(TEMP_DIR, "ai_response.mp3")

@router.post("/process-voice")
async def process_voice_command(background_tasks: BackgroundTasks, file: UploadFile = File(...)):
    # 1. Lưu file tạm bằng Async I/O (Không gây block hệ thống)
    try:
        async with aiofiles.open(TEMP_INPUT_WAV, 'wb') as out_file:
            while content := await file.read(1024 * 1024):
                await out_file.write(content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi lưu file: {str(e)}")

    # 2. GIAI ĐOẠN STT: Đẩy tiến trình Whisper nặng xuống Threadpool riêng để chống block các route khác
    user_text = await asyncio.to_thread(transcribe_audio_file, TEMP_INPUT_WAV)
    
    if not user_text or user_text.strip() == "":
        return {"user_text": "", "ai_response": "Không nhận diện được giọng nói.", "audio_url": None}

    # 3. GIAI ĐOẠN LLM & HARDWARE: Gọi trực tiếp bằng await vì hàm ai_process_text 
    # phía trong đã tự bọc xử lý LLM đồng bộ và gọi hành vi phần cứng async chuẩn xác
    ai_response = await ai_process_text(
        user_input=user_text, 
        background_tasks=background_tasks
    )

    # 4. GIAI ĐOẠN TTS: Chuyển đổi câu thoại phản hồi dạng text sạch thành file âm thanh
    try:
        await generate_tts_audio(text=ai_response, output_file=RESPONSE_MP3, voice="vi-VN-HoaiAnNeural")
        audio_url = "/ai/download-response-audio"
    except Exception as e:
        print(f"⚠️ Lỗi TTS tại Route: {e}")
        audio_url = None

    return {
        "user_text": user_text,
        "ai_response": ai_response,
        "audio_url": audio_url
    }

@router.get("/download-response-audio")
async def download_response_audio():
    if not os.path.exists(RESPONSE_MP3):
        raise HTTPException(status_code=404, detail="Tệp tin không tồn tại.")
    return FileResponse(path=RESPONSE_MP3, media_type="audio/mpeg", filename="response.mp3")
