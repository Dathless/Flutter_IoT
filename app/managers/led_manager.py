from fastapi import HTTPException
from app.services.device_service import led_manager
from pydantic import BaseModel

# Giữ Pydantic Model ở đây hoặc chuyển hẳn vào file route tùy bạn, 
# nhưng để Manager có thể tái sử dụng hàm control độc lập, ta định nghĩa schema ở đây.
class LedControl(BaseModel):
    status: bool

class LedRouteManager:
    def __init__(self):
        # Sử dụng led_manager gốc từ device_service để tương tác với thiết bị
        self.device_manager = led_manager

    def get_all_leds_status(self):
        """Lấy trạng thái của tất cả các đèn LED"""
        return self.device_manager.get_all_status()

    def control_room_led(self, room_name: str, status: bool):
        """Xử lý logic điều khiển LED theo từng phòng và trả về thông tin"""
        led = self.device_manager.get_led(room_name)
        
        if not led:
            raise HTTPException(status_code=404, detail="Room not exist")
            
        # Áp dụng trạng thái (True/False)
        is_on = True if status else False
        led.set_state(is_on)
        
        return led.get_info()

# Khởi tạo một instance duy nhất (Singleton pattern) để reuse ở các route
led_route_manager = LedRouteManager()
