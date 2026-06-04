# API - Smart Home IoT

Tài liệu này mô tả các endpoint mà app Flutter gọi tới Raspberry Pi / backend của hệ thống IoT.

## Base URL

- Mặc định: `http://10.198.184.243:8000`
- Có thể thay đổi runtime bằng phương thức `ApiService.setBaseUrl(String url)` (được gọi từ UI trong `UrlSetup`).

## Authentication / Headers / Cookies

- Không có cơ chế xác thực (token/API key) trong mã nguồn.
- Các request GET không gửi header đặc biệt.
- Các request POST sử dụng header: `Content-Type: application/json`.
- Không thấy sử dụng cookie.

## Endpoints

### GET /

- Mục đích: kiểm tra kết nối / health check.
- URL: `${baseUrl}/`
- Method: GET
- Headers: none
- Body: none
- Kỳ vọng response: JSON có `status: "success"` để coi là kết nối hợp lệ.

### GET /dht

- Mục đích: lấy dữ liệu cảm biến DHT (nhiệt độ, độ ẩm).
- URL: `${baseUrl}/dht`
- Method: GET
- Headers: none
- Body: none
- Response (ví dụ):

```json
{
  "temp": 26.5,
  "humi": 60
}
```

### GET /gas

- Mục đích: lấy trạng thái cảm biến gas.
- URL: `${baseUrl}/gas`
- Method: GET
- Headers: none
- Body: none
- Response (ví dụ):

```json
{
  "value": 120,
  "is_danger": true
}
```

### POST /led/{room}

- Mục đích: điều khiển LED theo phòng.
- URL: `${baseUrl}/led/{room}` (ví dụ: `/led/bedroom`, `/led/living-room`, `/led/dining`, `/led/wc`, `/led/gara`)
- Method: POST
- Headers: `Content-Type: application/json`
- Body (JSON):

```json
{ "status": 1 }
```

- Ý nghĩa `status`: `1` = bật, `0` = tắt.
- Response: server nên trả status code `200` khi thành công. Client (app) chỉ kiểm tra `response.statusCode == 200` và trả `true`/`false`.

### POST /lcd

- Mục đích: gửi nội dung hiển thị lên màn hình LCD.
- URL: `${baseUrl}/lcd`
- Method: POST
- Headers: `Content-Type: application/json`
- Body (JSON):

```json
{ "message": "Hello world" }
```

- Response: server trả status code `200` khi thành công; client dùng statusCode để xác định kết quả.

### POST /stepper/control

- Mục đích: điều khiển cửa gara qua stepper motor.
- URL: `${baseUrl}/stepper/control`
- Method: POST
- Headers: `Content-Type: application/json`
- Body (JSON):

```json
{
  "action": "open", // hoặc "close"
  "times": 1
}
```

- `times` nên là số nguyên từ `1` đến `4`.
- Response: server trả status code `200` khi thành công; client sẽ hiển thị lỗi nếu status khác 200.

## Ghi chú triển khai (client)

- File client: `lib/services/api_service.dart`
  - `getSensorData(String endpoint)` thực hiện `GET` tới `baseUrl + endpoint` và trả `Map<String,dynamic>` bằng `json.decode`.
  - `sendControl(String endpoint, Map<String,dynamic> data)` thực hiện `POST` với header `Content-Type: application/json` và body JSON; trả `bool` (true nếu `statusCode == 200`).
- File sử dụng API: `lib/main.dart` gọi `/`, `/dht`, `/gas`, `/led/{room}`, `/lcd`.

## Đề xuất tiếp theo

- Muốn tôi xuất file OpenAPI (YAML/JSON) từ cấu trúc này không?
