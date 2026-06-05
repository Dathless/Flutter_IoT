from app.services.gas_service import gas_sensor

class GasManager:
    def __init__(self):
        # Lưu trữ instance của gas_sensor service
        self.sensor = gas_sensor

    def get_current_gas_data(self) -> dict:
        """
        Lấy giá trị gas hiện tại và trả về cấu trúc dữ liệu chuẩn.
        Dễ dàng tái sử dụng cho các logic kiểm tra nồng độ vượt ngưỡng nguy hiểm.
        """
        current_value = self.sensor.get_gas_value()
        
        return {
            "status": "success",
            "value": current_value,
            "unit": "ppm"
        }

# Khởi tạo một instance duy nhất để sử dụng chung trong toàn bộ dự án
gas_manager = GasManager()
