import RPi.GPIO as GPIO

# Cấu hình chế độ chân BCM MỘT LẦN DUY NHẤT ở cấp toàn cục (Global) 
# để tránh xung đột khi khởi tạo nhiều thiết bị.
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False) # Tắt các cảnh báo GPIO không cần thiết khi reboot server

class LedDevice:
    def __init__(self, name: str, pin: int): # Đổi kiểu dữ liệu chân sang int cho đúng chuẩn RPi.GPIO
        self.name = name
        self.pin = pin
        self.status = False
        
        # Chỉ setup chân OUT và xuất mức THẤP (LOW), không gọi lại setmode nữa
        GPIO.setup(self.pin, GPIO.OUT)
        GPIO.output(self.pin, GPIO.LOW)
        
    def set_state(self, is_on: bool):
        self.status = is_on
        GPIO.output(self.pin, GPIO.HIGH if is_on else GPIO.LOW)
    
    def get_info(self):
        return {
            "name": self.name,
            "status": self.status,
            "pin": self.pin
        }

class LedManager:
    def __init__(self):
        self.leds = {
            "living-room": LedDevice("Living room", 17),
            "bedroom" : LedDevice("Bed Room", 27),
            "wc" : LedDevice("Restroom", 22),
            "gara" : LedDevice("Garage", 23),
            "dining": LedDevice("Dining Room", 24)
        }       
    
    def get_led(self, room_name: str) -> LedDevice:
        return self.leds.get(room_name)
        
    def get_all_status(self):
        # ĐÃ SỬA: Chuyển từ self.led.values() thành self.leds.values()
        return [led.get_info() for led in self.leds.values()]

# Khởi tạo instance duy nhất cho toàn hệ thống
led_manager = LedManager()
