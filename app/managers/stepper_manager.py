import asyncio
from fastapi import HTTPException, BackgroundTasks
from app.services.stepper_service import gara_door

class StepperManager:
    def __init__(self):
        # Sử dụng đối tượng gara_door từ service để điều khiển phần cứng
        self.door = gara_door

    def get_door_state(self) -> dict:
        """Lấy trạng thái hiện tại của cửa gara"""
        return {
            "status": "success", 
            "state": self.door.get_status()
        }

    def _run_door_task(self, action: str, times: int):
        """Hàm xử lý chạy ngầm đồng bộ (FastAPI tự chạy trên Thread riêng)"""
        try:
            if action == "open":
                self.door.open_door(times=times) # Bỏ await
                print("--- [Manager] Cửa đã mở thành công ---")
            elif action == "close":
                self.door.close_door(times=times) # Bỏ await
                print("--- [Manager] Cửa đã đóng thành công ---")
        except Exception as e:
            self.door.state = "error"
            print(f"--- [Manager] Lỗi thực thi phần cứng: {e} ---")

    def control_door_action(self, action: str, times: int, background_tasks: BackgroundTasks) -> dict:
        """Xử lý validate logic và đẩy tác vụ vào Background Tasks của FastAPI"""
        action = action.lower().strip()

        # Kiểm tra nếu cửa đang trong quá trình di chuyển thì chặn request mới
        if self.door.get_status() in ["opening", "closing"]:
            raise HTTPException(status_code=400, detail="Door is moving")

        if action not in ["open", "close"]:
            raise HTTPException(status_code=400, detail="Action is invalid")

        # Thiết lập trạng thái động trước khi ném vào background task
        if action == "open":
            self.door.state = "opening"
            message = "Door is opening..."
        else:
            self.door.state = "closing"
            message = "Door is closing..."

        # Đăng ký hàm trung gian _run_door_task vào hàng đợi chạy ngầm của FastAPI
        background_tasks.add_task(self._run_door_task, action=action, times=times)

        return {
            "status": "success",
            "message": message,
            "state": self.door.get_status()
        }

    def reset_door_state(self) -> dict:
        """Hàm chữa cháy cứu cánh: Ép trạng thái về 'stopped' nếu vô tình bị kẹt kịch bản"""
        self.door.state = "stopped"
        return {
            "status": "success", 
            "message": "Force reset door state to 'stopped' successfully."
        }

# Khởi tạo instance duy nhất để sử dụng trong routes
stepper_manager = StepperManager()
