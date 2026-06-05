import os
from time import sleep

try:
    from gpiozero import AngularServo
except (ImportError, OSError):
    AngularServo = None

class ServoService:
    def __init__(self, pin: int, min_angle: int = 0, max_angle: int = 180):
        self.pin = pin
        self.min_angle = min_angle
        self.max_angle = max_angle
        self.state = "closed"
        
        if AngularServo:
            self.servo = AngularServo(
                self.pin, 
                initial_angle=0, 
                min_angle=self.min_angle, 
                max_angle=self.max_angle,
                min_pulse_width=0.0005,
                max_pulse_width=0.0025
            )
            # Ngắt xung ngay khi vừa khởi tạo để tránh servo bị giật lúc vừa bật nguồn
            self.servo.value = None 
        else:
            self.servo = None

    def open_door(self, target_angle: float = 125.0):
        if target_angle > self.max_angle or target_angle < self.min_angle:
            raise ValueError(f"Góc mở phải nằm trong khoảng {self.min_angle} đến {self.max_angle}")
            
        if self.servo:
            self.servo.angle = target_angle
            sleep(0.6)              # Chờ 0.6 giây để servo quay đến nơi ổn định
            self.state = "opened"
            self.servo.value = None  # <--- QUAN TRỌNG: Ngắt xung điều khiển để chống giật
        else:
            print(f"[Mock] [GPIO {self.pin}] Quay đến góc: {target_angle}°")
        return f"Cửa điều khiển bởi GPIO {self.pin} đã mở đến góc {target_angle}°"

    def close_door(self):
        if self.servo:
            self.servo.angle = 30
            sleep(0.6)              # Chờ 0.6 giây để servo kịp quay về góc 0
            self.state = "closed"
            self.servo.value = None  # <--- QUAN TRỌNG: Ngắt xung điều khiển để chống giật
        else:
            print(f"[Mock] [GPIO {self.pin}] Quay về góc: 0°")
        return f"Cửa điều khiển bởi GPIO {self.pin} đã đóng (Về góc 0°)"
    def get_status(self):
        return self.state

# Giữ nguyên khai báo chân của bạn ở bên dưới...
front_servo = ServoService(pin=9) 
back_servo = ServoService(pin=10) 
