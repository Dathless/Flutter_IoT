import asyncio
from gpiozero import OutputDevice

class DCMotorService:
    def __init__(self, pin_in3: int = 8, pin_in4: int = 7, pin_enb: int = 1):
        """
        Khởi tạo kết nối với L298N sử dụng cặp chân IN3, IN4 và ENB.
        """
        self.in3 = OutputDevice(pin_in3)
        self.in4 = OutputDevice(pin_in4)
        self.enb = OutputDevice(pin_enb)
        
        # Trạng thái: "closed", "opening", "open", "closing", "unknown"
        self._status = "closed"
        self._lock = asyncio.Lock()

    def get_status(self) -> str:
        return self._status

    async def open(self) -> bool:
        #if self._status in ["open", "opening"]:
         #   return False
        
        async with self._lock:
            self._status = "opening"
            try:
                self.enb.on()
                self.in3.on()
                self.in4.off()
                
                await asyncio.sleep(0.28)  
                
                self._stop_hardware()
                self._status = "open"
                return True
            except Exception:
                self._stop_hardware()
                self._status = "unknown"
                return False

    async def close(self) -> bool:
        """Đóng: IN3 = LOW, IN4 = HIGH trong 210ms"""
        #if self._status in ["closed", "closing"]:
         #   return False

        async with self._lock:
            self._status = "closing"
            try:
                self.enb.on()
                self.in3.off()
                self.in4.on()
                
                await asyncio.sleep(0.26)  
                
                self._stop_hardware()
                self._status = "closed"
                return True
            except Exception:
                self._stop_hardware()
                self._status = "unknown"
                return False

    def _stop_hardware(self):
        """Ngắt điện toàn bộ các chân kích hoạt động cơ"""
        self.enb.off()
        self.in3.off()
        self.in4.off()
        
