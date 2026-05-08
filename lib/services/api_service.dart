import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  late String baseUrl;

  ApiService({String? initialBaseUrl}) {
    baseUrl = initialBaseUrl ?? "http://192.168.1.70:8000";
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
}
