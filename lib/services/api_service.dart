import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ApiService {
  late String baseUrl;

  ApiService({String? initialBaseUrl}) {
    // baseUrl = initialBaseUrl ?? "http://192.168.1.70:8000";
    baseUrl = initialBaseUrl ?? "http://10.198.184.243:8000";
  }

  // Gửi file âm thanh (local) đến endpoint /ai/process-voice và nhận JSON response
  // Trả về Map với các khóa: user_text, ai_response, audio_url (nếu có lỗi trả về { 'error': ... })
  Future<Map<String, dynamic>> processVoice(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/ai/process-voice');
      final request = http.MultipartRequest('POST', uri);

      final file = File(filePath);
      if (!file.existsSync()) {
        return {'error': 'File not found'};
      }

      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: p.basename(file.path),
      );

      request.files.add(multipartFile);
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'error': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Tải file âm thanh từ audioUrl về một file tĩnh (ghi đè) và trả về instance File
  // Lưu file vào temporary directory với tên cố định 'response_audio.mp3'
  Future<File?> downloadAudio(String audioUrl) async {
    try {
      Uri uri;
      if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
        uri = Uri.parse(audioUrl);
      } else {
        uri = Uri.parse('$baseUrl$audioUrl');
      }

      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;

      final tmp = await getTemporaryDirectory();
      final outPath = p.join(tmp.path, 'response_audio.mp3');
      final outFile = File(outPath);
      await outFile.writeAsBytes(resp.bodyBytes, flush: true);
      return outFile;
    } catch (e) {
      return null;
    }
  }

  // Cập nhật baseUrl
  void setBaseUrl(String url) {
    baseUrl = url;
  }

  // Lấy dữ liệu cảm biến (DHT, Light, etc.)
  Future<Map<String, dynamic>> getSensorData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load sensor');
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Điều khiển thiết bị (LED, LCD)
  Future<bool> sendControl(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getGasStatus() async {
    return await getSensorData('/gas');
  }

  Future<Map<String, dynamic>> getStepperStatus() async {
    return await getSensorData('/stepper/status');
  }

  Future<String?> controlStepper(String action, [int times = 1]) async {
    if (action != 'open' && action != 'close') {
      return 'Action phải là "open" hoặc "close".';
    }
    if (times < 1 || times > 4) {
      return 'Số lần phải là số nguyên từ 1 đến 4.';
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stepper/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'action': action, 'times': times}),
      );
      if (response.statusCode == 200) {
        return null;
      }
      return 'HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> controlServo(String door, String action) async {
    final allowedDoors = ['front', 'back'];
    final allowedActions = ['open', 'close'];
    if (!allowedDoors.contains(door) || !allowedActions.contains(action)) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/servo/$door/$action'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getLedStatus() async {
    return await getSensorData('/led/');
  }

  Future<Map<String, dynamic>> getServoStatus(String door) async {
    return await getSensorData('/servo/$door');
  }

  // Motor control methods for main door
  Future<Map<String, dynamic>> getMotorStatus() async {
    return await getSensorData('/motor/status');
  }

  Future<bool> controlMotorOpen() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/motor/open'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> controlMotorClose() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/motor/close'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
