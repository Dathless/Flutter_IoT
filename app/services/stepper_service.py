import time
import RPi.GPIO as GPIO

class StepperService:
    def __init__(self):
        self.IN1 = 5
        self.IN2 = 6
        self.IN3 = 13
        self.IN4 = 19
        
        self.pins = [self.IN1, self.IN2, self.IN3, self.IN4]
        self.state = "closed"
        
        self.STEP_PER_90_DEG = 1300 
        self.step_seq = [
            [1,0,0,0], [1,1,0,0], [0,1,0,0], [0,1,1,0],
            [0,0,1,0], [0,0,1,1], [0,0,0,1], [1,0,0,1]
        ]
    
    def _setup_gpio(self):
        GPIO.setmode(GPIO.BCM)
        for pin in self.pins:
            GPIO.setup(pin, GPIO.OUT)
            GPIO.output(pin, GPIO.LOW)
            
    def _cleanup(self):
        for pin in self.pins:
            GPIO.output(pin, GPIO.LOW)
    
    def _step(self, direction: int, steps: int, delay: float = 0.002):
        # Ép buộc cài đặt lại chân ngay trước khi xuất xung để tránh bị giải phóng luồng
        self._setup_gpio()
        seq_length = len(self.step_seq)
        step_counter = 0
        
        for _ in range(steps):
            for pin_idx in range(4):
                GPIO.output(self.pins[pin_idx], self.step_seq[step_counter][pin_idx])
            
            if direction == 1:
                step_counter = (step_counter + 1) % seq_length
            else:
                step_counter = (step_counter - 1) % seq_length
                
            # Dùng time.sleep chuẩn đồng bộ để giữ vững tần số xung ổn định
            time.sleep(delay)
            
        self._cleanup()
        
    def get_status(self) -> str:
        return self.state
    
    def open_door(self, times: int = 2) -> str:
        self.state = "opening"
        total_step = self.STEP_PER_90_DEG * times
        self._step(direction=1, steps=total_step)
        self.state = "opened"
        return f"Door open 90 deg x {times} times"
    
    def close_door(self, times: int = 2) -> str:
        self.state = "closing"
        total_step = self.STEP_PER_90_DEG * times
        self._step(direction=-1, steps=total_step)
        self.state = "closed"
        return f"Door close 90 deg x {times} times"

gara_door = StepperService()
