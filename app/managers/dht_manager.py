from app.services.sensor_service import get_dht

class DhtManager:
    def __init__(self):
        # Bạn có thể lưu trữ trạng thái hoặc cấu hình sensor tại đây nếu cần
        pass

    def get_sensor_data(self):
        """
        Lấy dữ liệu nhiệt độ và độ ẩm từ sensor service.
        Dễ dàng tái sử dụng cho các tác vụ khác (như chạy background task để check cảnh báo).
        """
        # Sau này nếu cần format dữ liệu, validate hoặc tính toán thêm logic, bạn sẽ viết ở đây
        return get_dht()

# Khởi tạo instance duy nhất để dùng chung
dht_manager = DhtManager()
