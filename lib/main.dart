import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'modules/sensor_card.dart';
import 'modules/led_control.dart';
import 'modules/display_control.dart';
import 'modules/url_setup.dart';
import 'dart:async';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? _darkTheme : _lightTheme,
      home: SmartHomeScreen(onToggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Color(0xFFF5F6F9),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.blueGrey,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: Color(0xFF1E1E1E),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}

class SmartHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SmartHomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  _SmartHomeScreenState createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  late ApiService api;
  final TextEditingController _lcdController = TextEditingController();

  String temp = "--", humidity = "--";
  bool isGasAlert = false;
  String alertTime = "";
  bool isConnected = false;
  String? connectionError;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    api = ApiService();
  }

  @override
  void dispose() {
    _lcdController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _testConnection(String url) async {
    try {
      String finalUrl = url;

      // Thêm http:// nếu chưa có
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'http://$url';
      }

      // Parse và thêm port 8000 nếu cần
      Uri uri = Uri.parse(finalUrl);
      if (uri.port == 80 || uri.port == 443) {
        uri = uri.replace(port: 8000);
      }
      finalUrl = uri.toString();

      api.setBaseUrl(finalUrl);

      final response = await api.getSensorData('/');

      if (mounted) {
        if (response['status'] == 'success') {
          setState(() {
            isConnected = true;
            connectionError = null;
          });
          _startDataRefresh();
        } else {
          setState(() {
            isConnected = false;
            connectionError = 'Phản hồi không hợp lệ từ server';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionError = 'Không thể kết nối: $e';
        });
      }
    }
  }

  void _startDataRefresh() {
    _refreshSensors();
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _refreshSensors();
    });
  }

  void _refreshSensors() async {
    final dhtData = await api.getSensorData('/dht');
    final gasData = await api.getSensorData('/gas');

    if (mounted) {
      setState(() {
        temp = dhtData['temp']?.toString() ?? "--";
        humidity = dhtData['humi']?.toString() ?? "--";

        if (gasData['gas_detected'] == true) {
          if (!isGasAlert) {
            isGasAlert = true;
            alertTime = DateFormat(
              'HH:mm:ss - dd/MM/yyyy',
            ).format(DateTime.now());
          }
        }
      });
    }
  }

  // Hàm helper để gửi lệnh điều khiển đèn theo tên phòng
  void _controlLed(String room, bool status) {
    api.sendControl('/led/$room', {'status': status ? 1 : 0});
  }

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return Scaffold(
        appBar: AppBar(title: Text("Smart Home - Kết nối")),
        body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UrlSetup(onConnect: _testConnection),
              if (connectionError != null)
                Text(connectionError!, style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Smart Home Control"),
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.brightness_7 : Icons.brightness_4,
            ),
            onPressed: widget.onToggleTheme,
          ),
          if (isGasAlert) Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 15),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Cảnh báo Gas
            if (isGasAlert) _buildGasAlertCard(),

            // Cards cảm biến
            Row(
              children: [
                Expanded(
                  child: SensorCard(
                    title: "Nhiệt độ",
                    value: temp,
                    unit: "°C",
                    icon: Icons.thermostat,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: SensorCard(
                    title: "Độ ẩm",
                    value: humidity,
                    unit: "%",
                    icon: Icons.water_drop,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // DANH SÁCH THIẾT BỊ ĐÈN
            Text(
              "Điều khiển đèn",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  LedControl(
                    // Component UI từ led_control.dart
                    onToggle: (val) => _controlLed('living-room', val),
                  ),
                  Divider(height: 1),
                  _buildLedItem(
                    "Phòng ngủ",
                    Icons.bed,
                    (val) => _controlLed('bedroom', val),
                  ),
                  Divider(height: 1),
                  _buildLedItem(
                    "Nhà vệ sinh",
                    Icons.wc,
                    (val) => _controlLed('wc', val),
                  ),
                  Divider(height: 1),
                  _buildLedItem(
                    "Gara xe",
                    Icons.garage,
                    (val) => _controlLed('gara', val),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Điều khiển LCD
            Text(
              "Màn hình LCD",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            DisplayContentControl(
              controller: _lcdController,
              onSend: (text) => api.sendControl('/lcd', {'message': text}),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshSensors,
        child: Icon(Icons.refresh),
      ),
    );
  }

  // Hàm tạo nhanh các dòng điều khiển đèn tương tự led_control.dart
  Widget _buildLedItem(String title, IconData icon, Function(bool) onToggle) {
    return StateUpdater(
      builder: (context, isSwitched, setStateItem) {
        return ListTile(
          leading: Icon(
            icon,
            color: isSwitched ? Colors.yellow : Colors.grey,
            size: 30,
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: Switch(
            value: isSwitched,
            onChanged: (value) {
              setStateItem(value);
              onToggle(value);
            },
            activeThumbColor: Colors.orangeAccent,
          ),
        );
      },
    );
  }

  Widget _buildGasAlertCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 25),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.gpp_maybe, color: Colors.white, size: 40),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PHÁT HIỆN RÒ RỈ GAS!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Lúc: $alertTime",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: Colors.white70),
            onPressed: () => setState(() => isGasAlert = false),
          ),
        ],
      ),
    );
  }
}

// Widget nhỏ để quản lý trạng thái riêng cho từng switch trong List
class StateUpdater extends StatefulWidget {
  final Widget Function(BuildContext, bool, Function(bool)) builder;
  const StateUpdater({required this.builder});
  @override
  _StateUpdaterState createState() => _StateUpdaterState();
}

class _StateUpdaterState extends State<StateUpdater> {
  bool state = false;
  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      state,
      (newVal) => setState(() => state = newVal),
    );
  }
}
