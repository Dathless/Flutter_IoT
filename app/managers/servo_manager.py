from fastapi import HTTPException
from app.services.servo_service import front_servo, back_servo

class ServoManager:
    def __init__(self):
        # Lưu trữ các instance servo từ service
        self.servos = {
            "front": front_servo,
            "back": back_servo
        }

    def _get_servo(self, door_type: str):
        """Hàm bổ trợ để lấy đúng đối tượng servo dựa trên loại cửa"""
        servo = self.servos.get(door_type)
        if not servo:
            raise HTTPException(status_code=400, detail=f"Invalid door type: {door_type}")
        return servo

    def open_door(self, door_type: str, angle: float) -> dict:
        """Xử lý logic mở cửa và catch các lỗi nghiệp vụ"""
        servo = self._get_servo(door_type)
        try:
            message = servo.open_door(target_angle=angle)
            return {"status": "success", "message": message}
        except ValueError as e:
            # Bắt lỗi sai góc quay (ví dụ góc âm hoặc quá lớn)
            raise HTTPException(status_code=400, detail=str(e))
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")

    def close_door(self, door_type: str) -> dict:
        """Xử lý logic đóng cửa"""
        servo = self._get_servo(door_type)
        try:
            message = servo.close_door()
            return {"status": "success", "message": message}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")
    def get_servo_status(self, door_type: str) -> str:
        servo = self._get_servo(door_type)
        return {"status": "success", "message" : servo.get_status()}

# Khởi tạo instance duy nhất để sử dụng trong routes
servo_manager = ServoManager()
