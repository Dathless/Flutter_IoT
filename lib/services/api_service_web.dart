import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  late String baseUrl;

  ApiService({String? initialBaseUrl}) {
    baseUrl = initialBaseUrl ?? "http://10.198.184.243:8000";
  }

  // Upload bytes (web) to /ai/process-voice
  Future<Map<String, dynamic>> processVoiceBytes(
    List<int> bytes,
    String filename,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/ai/process-voice');
      final request = http.MultipartRequest('POST', uri);
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
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

  // Non-web callers may call processVoice(filePath); provide a stub for parity.
  Future<Map<String, dynamic>> processVoice(String filePath) async {
    return {
      'error':
          'processVoice(filePath) is not supported on web; use processVoiceBytes.',
    };
  }

  // On web, we can directly play server audio URLs, so downloadAudio can be a passthrough
  Future<String?> downloadAudioUrl(String audioUrl) async {
    if (audioUrl.startsWith('http')) return audioUrl;
    return '$baseUrl$audioUrl';
  }

  // Provide downloadAudio(file) for parity with IO implementation; returns null on web.
  Future<dynamic> downloadAudio(String audioUrl) async {
    // On web we typically don't download to a File; return null.
    return null;
  }

  void setBaseUrl(String url) {
    baseUrl = url;
  }

  // Other sensor methods can use regular http package
  Future<Map<String, dynamic>> getSensorData(String endpoint) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl$endpoint'));
      if (resp.statusCode == 200) return json.decode(resp.body);
      throw Exception('Failed');
    } catch (e) {
      return {'error': e.toString()};
    }
  }

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

  Future<Map<String, dynamic>> getGasStatus() async =>
      await getSensorData('/gas');
  Future<Map<String, dynamic>> getStepperStatus() async =>
      await getSensorData('/stepper/status');
  Future<String?> controlStepper(String action, [int times = 1]) async {
    if (action != 'open' && action != 'close')
      return 'Action phải là "open" hoặc "close".';
    if (times < 1 || times > 4) return 'Số lần phải là số nguyên từ 1 đến 4.';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stepper/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'action': action, 'times': times}),
      );
      if (response.statusCode == 200) return null;
      return 'HTTP ${response.statusCode}: ${response.body}';
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> controlServo(String door, String action) async {
    final allowedDoors = ['front', 'back'];
    final allowedActions = ['open', 'close'];
    if (!allowedDoors.contains(door) || !allowedActions.contains(action))
      return false;
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
  Future<Map<String, dynamic>> getMotorStatus() async =>
      await getSensorData('/motor/status');

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
