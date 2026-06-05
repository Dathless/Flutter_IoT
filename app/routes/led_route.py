from fastapi import APIRouter
from app.managers.led_manager import led_route_manager, LedControl

router = APIRouter(prefix="/led", tags=["Smart Lighting"])

@router.get("/")
def list_all_leds():
    # Gọi thẳng instance của manager để lấy dữ liệu
    return led_route_manager.get_all_leds_status()
	
@router.post("/{room_name}")
def control_led(room_name: str, data: LedControl):
    # Chuyển tiếp tham số vào manager xử lý logic nghiệp vụ
    return led_route_manager.control_room_led(room_name, data.status)

@router.post("/turn_on_all")
def turn_on_all():
    return ""
    
@router.post("/turn_off_all")
def turn_off_all():
    return ""
