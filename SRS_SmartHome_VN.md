# SRS - Software Requirements Specification
# Hệ Thống Nhà Thông Minh Điều Khiển Bằng AI Trên Raspberry Pi

**Phiên bản:** 1.0  
**Loại tài liệu:** Software Requirements Specification (SRS)  
**Ngôn ngữ:** Tiếng Việt  
**Nền tảng:** Raspberry Pi 4 Model B  
**Kiến trúc:** FastAPI + AI + IoT  

---

# 1. Giới thiệu

## 1.1 Mục đích tài liệu

Tài liệu này mô tả toàn bộ yêu cầu chức năng, yêu cầu phi chức năng, kiến trúc hệ thống, luồng xử lý nghiệp vụ, thành phần phần cứng và phần mềm của hệ thống Nhà Thông Minh (Smart Home Platform) được triển khai trên Raspberry Pi.

Tài liệu đóng vai trò là cơ sở cho:

- Thiết kế hệ thống.
- Phát triển phần mềm.
- Kiểm thử hệ thống.
- Bảo trì và mở rộng trong tương lai.
- Chuyển giao dự án.

---

## 1.2 Phạm vi hệ thống

Hệ thống cung cấp nền tảng điều khiển nhà thông minh thông qua REST API và AI Voice Assistant.

Các chức năng chính:

- Giám sát nhiệt độ và độ ẩm.
- Giám sát khí gas.
- Điều khiển đèn theo khu vực.
- Điều khiển cửa trước và cửa sau bằng Servo Motor.
- Điều khiển cửa gara bằng Stepper Motor.
- Điều khiển cửa chính bằng DC Motor kết hợp mạch L298N.
- Hiển thị thông tin trên màn hình LCD.
- Phát cảnh báo bằng Buzzer.
- Điều khiển thiết bị bằng giọng nói thông qua AI.

---

## 1.3 Định nghĩa và thuật ngữ

| Thuật ngữ | Ý nghĩa |
|-----------|----------|
| API | Application Programming Interface |
| GPIO | General Purpose Input Output |
| STT | Speech To Text |
| TTS | Text To Speech |
| LLM | Large Language Model |
| PWM | Pulse Width Modulation |
| REST | Representational State Transfer |
| AI | Artificial Intelligence |
| IoT | Internet of Things |
| GPIOZero | Thư viện điều khiển GPIO trên Raspberry Pi |
| FastAPI | Framework xây dựng REST API |
| Qwen | Large Language Model dùng để xử lý ngôn ngữ tự nhiên |
| Whisper | Mô hình nhận dạng giọng nói |

---

# 2. Tổng Quan Hệ Thống

## 2.1 Mô hình kiến trúc

```text
Mobile App / Web App
           │
           ▼
      FastAPI Server
           │
 ┌─────────┼─────────┐
 ▼         ▼         ▼
Routes   Managers  Models
           │
           ▼
        Services
           │
           ▼
 Hardware Layer
```

---

## 2.2 Mục tiêu thiết kế

Hệ thống được xây dựng theo mô hình phân lớp nhằm:

- Tách biệt Business Logic và Hardware Logic.
- Dễ dàng bảo trì.
- Hạn chế phụ thuộc giữa các module.
- Dễ dàng mở rộng thiết bị mới.
- Hỗ trợ tích hợp AI.

---

# 3. Cấu Trúc Thư Mục Dự Án

Lưu ý:

README.md nằm cùng cấp với thư mục ứng dụng và môi trường ảo.

```text
project_root/
│
├── README.md
├── venv/
│
└── app/
    ├── main.py
    ├── routes/
    ├── managers/
    ├── services/
    ├── models/
    └── temp_audio/
```

---

# 4. Yêu Cầu Chức Năng (Functional Requirements)

# FR-01: Đọc dữ liệu nhiệt độ và độ ẩm

Mô tả:

Hệ thống phải cho phép người dùng đọc dữ liệu môi trường từ cảm biến DHT11.

Đầu vào:

- HTTP GET Request

Đầu ra:

```json
{
    "temp": 30,
    "humi": 78
}
```

Module:

- dht_route.py
- dht_manager.py
- sensor_service.py

---

# FR-02: Giám sát khí gas

Mô tả:

Hệ thống phải liên tục theo dõi trạng thái cảm biến gas.

Khi phát hiện khí gas:

- Kích hoạt buzzer.
- Cập nhật trạng thái hệ thống.
- Gửi dữ liệu cảnh báo qua API.

Module:

- gas_route.py
- gas_manager.py
- gas_service.py
- task_manager.py
- buzzer_service.py

---

# FR-03: Điều khiển hệ thống đèn

Mô tả:

Người dùng có thể bật hoặc tắt đèn theo từng khu vực.

Chức năng:

- Bật đèn.
- Tắt đèn.
- Xem trạng thái hiện tại.

API:

```http
GET /led
POST /led/{room}
```

---

# FR-04: Điều khiển cửa bằng Servo Motor

Mô tả:

Hệ thống hỗ trợ điều khiển:

- Cửa trước.
- Cửa sau.

Tác vụ:

- Open
- Close
- Status

API:

```http
GET /servo/front
POST /servo/front/open
POST /servo/front/close
```

---

# FR-05: Điều khiển cửa gara bằng Stepper Motor

Mô tả:

Người dùng có thể điều khiển cửa gara thông qua động cơ bước.

Tác vụ:

- Open
- Close
- Reset
- Status

Module:

- stepper_route.py
- stepper_manager.py
- stepper_service.py

Trạng thái:

```text
closed
opening
open
closing
stopped
```

---

# FR-06: Điều khiển cửa chính bằng DC Motor

## Mô tả

Hệ thống cung cấp cơ chế điều khiển cửa chính sử dụng:

- DC Motor
- Driver L298N

## Thành phần

### Route Layer

```text
dc_motor_route.py
```

### Manager Layer

```text
dc_motor_manager.py
```

### Service Layer

```text
motor_dc_service.py
```

## Tác vụ hỗ trợ

### Kiểm tra trạng thái

```http
GET /motor/status
```

### Mở cửa

```http
POST /motor/open
```

### Đóng cửa

```http
POST /motor/close
```

## Luồng mở cửa

1. Nhận yêu cầu từ API.
2. Chuyển tới Manager.
3. Manager gọi Service.
4. Kích hoạt chân ENB.
5. Thiết lập IN3 HIGH.
6. Thiết lập IN4 LOW.
7. Chạy động cơ trong thời gian hiệu chỉnh.
8. Dừng động cơ.
9. Cập nhật trạng thái OPEN.

## Luồng đóng cửa

1. Nhận yêu cầu từ API.
2. Chuyển tới Manager.
3. Manager gọi Service.
4. Kích hoạt ENB.
5. Thiết lập IN3 LOW.
6. Thiết lập IN4 HIGH.
7. Chạy động cơ trong thời gian hiệu chỉnh.
8. Dừng động cơ.
9. Cập nhật trạng thái CLOSED.

## Kiểm soát đồng thời

Sử dụng:

```python
asyncio.Lock()
```

nhằm ngăn chặn nhiều lệnh điều khiển đồng thời gây xung đột trạng thái.

## Trạng thái hệ thống

```text
closed
opening
open
closing
unknown
```

---

# FR-07: Hiển thị LCD

Mô tả:

Màn hình LCD hiển thị:

- Nhiệt độ.
- Độ ẩm.
- Trạng thái hệ thống.

Tần suất cập nhật:

- 2 giây/lần.

---

# FR-08: Cảnh báo bằng Buzzer

Mô tả:

Buzzer được kích hoạt khi:

- Cảm biến gas phát hiện khí gas.

Yêu cầu:

- Âm thanh phải phát ngay khi phát hiện nguy hiểm.
- Tự động dừng khi trạng thái trở lại bình thường.

---

# FR-09: Điều khiển bằng giọng nói

Mô tả:

Người dùng gửi file âm thanh tới hệ thống.

Hệ thống thực hiện:

```text
Audio
  ↓
Whisper STT
  ↓
Text
  ↓
Qwen LLM
  ↓
Intent
  ↓
Hardware Action
  ↓
Edge TTS
  ↓
Response Audio
```

API:

```http
POST /ai/process-voice
```

---

# 5. Yêu Cầu Phi Chức Năng (Non-Functional Requirements)

# NFR-01 Hiệu năng

- API phản hồi dưới 500ms đối với tác vụ GPIO thông thường.
- Điều khiển motor phải thực thi tức thời sau khi nhận lệnh.
- Hệ thống hỗ trợ nhiều request đồng thời.

---

# NFR-02 Độ tin cậy

- Không được làm treo hệ thống khi thiết bị phần cứng lỗi.
- Mọi exception phải được xử lý.
- Motor phải tự dừng khi phát sinh lỗi.

---

# NFR-03 Khả năng bảo trì

Yêu cầu:

- Kiến trúc phân lớp.
- Tách biệt business logic.
- Tách biệt hardware logic.
- Dễ mở rộng thiết bị mới.

---

# NFR-04 Khả năng mở rộng

Hệ thống phải hỗ trợ bổ sung:

- Relay.
- Camera.
- RFID.
- Face Recognition.
- MQTT.
- Home Assistant.

mà không cần thay đổi kiến trúc lõi.

---

# NFR-05 Bảo mật

Khuyến nghị triển khai:

- JWT Authentication.
- HTTPS.
- Rate Limiting.
- API Key.

---

# 6. Thành Phần AI

## Speech To Text

Model:

```text
Faster Whisper
```

Chức năng:

- Chuyển đổi giọng nói thành văn bản.

---

## Natural Language Processing

Model:

```text
Qwen 2.5
```

Chức năng:

- Phân tích ý định.
- Trích xuất thực thể.
- Sinh phản hồi.

---

## Text To Speech

Engine:

```text
Microsoft Edge TTS
```

Chức năng:

- Sinh âm thanh phản hồi cho người dùng.

---

# 7. Danh Sách API

## Sensor APIs

```http
GET /dht
GET /gas
```

## Lighting APIs

```http
GET /led
POST /led/{room}
```

## Servo APIs

```http
GET /servo/{door}
POST /servo/{door}/open
POST /servo/{door}/close
```

## Garage APIs

```http
GET /stepper/status
POST /stepper/control
POST /stepper/reset
```

## Main Door APIs

```http
GET /motor/status
POST /motor/open
POST /motor/close
```

## AI APIs

```http
POST /ai/process-voice
GET /ai/download-response-audio
```

---

# 8. Hạn Chế Hiện Tại

- Chưa tích hợp cơ sở dữ liệu.
- Chưa có xác thực người dùng.
- Chưa hỗ trợ MQTT.
- Chưa có Dashboard quản trị.
- Chưa hỗ trợ OTA Update.

---

# 9. Định Hướng Phát Triển

Giai đoạn tiếp theo:

1. Triển khai JWT Authentication.
2. Tích hợp MQTT Broker.
3. Tích hợp Home Assistant.
4. Xây dựng Mobile Application.
5. Tích hợp Camera AI.
6. Face Recognition.
7. Cloud Synchronization.
8. Docker Deployment.
9. Monitoring Dashboard.

---

# 10. Kết Luận

Hệ thống Smart Home được thiết kế theo kiến trúc phân lớp hiện đại, hỗ trợ điều khiển thiết bị IoT, giám sát môi trường, tự động hóa nhà ở và tương tác bằng giọng nói thông qua AI.

Việc bổ sung phân hệ điều khiển cửa chính bằng DC Motor sử dụng L298N đã mở rộng khả năng kiểm soát truy cập vật lý của hệ thống. Kết hợp với Servo Motor và Stepper Motor, nền tảng hiện hỗ trợ đầy đủ nhiều cơ chế điều khiển cơ điện khác nhau trong cùng một kiến trúc phần mềm thống nhất.
