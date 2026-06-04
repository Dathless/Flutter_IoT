import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Use conditional ApiService implementation: web or io
import 'services/api_service_io.dart'
    if (dart.library.html) 'services/api_service_web.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
// Conditional web recorder (stub on non-web)
import 'services/web_audio_recorder_stub.dart'
    if (dart.library.html) 'services/web_audio_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'modules/sensor_card.dart';
import 'modules/led_control.dart';
import 'modules/stepper_control.dart';
import 'modules/servo_control.dart';
import 'modules/display_control.dart';
import 'modules/url_setup.dart';
import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
  final AudioRecorder _recorder = AudioRecorder();
  final WebAudioRecorder _webRecorder = WebAudioRecorder();
  bool _isRecording = false;
  bool _isProcessingVoice = false;
  String? _requestPath;
  String? _userText;
  String? _aiResponse;
  dynamic _responseAudioFile;
  String? _responseAudioUrl;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  final TextEditingController _lcdController = TextEditingController();

  String temp = "--", humidity = "--";
  double? gasValue;
  String gasUnit = "ppm";
  String stepperState = "--";
  bool isStepperBusy = false;
  String frontServoState = "--";
  String backServoState = "--";
  bool isServoBusy = false;
  bool isGasAlert = false;
  bool isGasAlertCritical = false;
  String alertTime = "";
  bool isConnected = false;
  String? connectionError;
  Timer? _sensorTimer;
  Timer? _gasTimer;

  @override
  void initState() {
    super.initState();
    api = ApiService();
  }

  @override
  void dispose() {
    _lcdController.dispose();
    _sensorTimer?.cancel();
    _gasTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String?> _testConnection(String url) async {
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

      final response = await api
          .getSensorData('/')
          .timeout(Duration(seconds: 10));

      if (response.containsKey('error')) {
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionError = 'Không thể kết nối: ${response['error']}';
          });
        }
        return 'Không thể kết nối: ${response['error']}';
      }

      if (response['status'] == 'success') {
        if (mounted) {
          setState(() {
            isConnected = true;
            connectionError = null;
          });
        }
        _startDataRefresh();
        return null;
      } else {
        if (mounted) {
          setState(() {
            isConnected = false;
            connectionError = 'Phản hồi không hợp lệ từ server';
          });
        }
        return 'Phản hồi không hợp lệ từ server';
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionError = 'Yêu cầu quá lâu. Vui lòng thử lại.';
        });
      }
      return 'Yêu cầu quá lâu. Vui lòng thử lại.';
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnected = false;
          connectionError = 'Không thể kết nối: $e';
        });
      }
      return 'Không thể kết nối: $e';
    }
  }

  void _startDataRefresh() {
    _refreshSensors();
    _refreshGasStatus();
    _sensorTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _refreshSensors();
    });
    _gasTimer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      _refreshGasStatus();
    });
  }

  void _refreshSensors() async {
    final dhtData = await api.getSensorData('/dht');
    final stepperData = await api.getStepperStatus();

    String fetchedStepperState = '--';

    if (stepperData['status'] == 'success') {
      fetchedStepperState = stepperData['state']?.toString() ?? '--';
    }

    if (mounted) {
      setState(() {
        temp = dhtData['temp']?.toString() ?? "--";
        humidity = dhtData['humi']?.toString() ?? "--";
        stepperState = fetchedStepperState;
      });
    }
  }

  void _refreshGasStatus() async {
    final gasData = await api.getGasStatus();
    double? parsedGasValue;
    String fetchedGasUnit = 'ppm';
    bool readingGasAlert = false;
    bool readingGasNormal = false;

    if (gasData['status'] == 'success') {
      final rawGasValue = gasData['value'];
      if (rawGasValue is num) {
        parsedGasValue = rawGasValue.toDouble();
      } else if (rawGasValue is String) {
        parsedGasValue = double.tryParse(rawGasValue);
      }
      fetchedGasUnit = gasData['unit']?.toString() ?? 'ppm';
      readingGasAlert = parsedGasValue == 0.0;
      readingGasNormal = parsedGasValue == 1.0;
    }

    if (mounted) {
      setState(() {
        gasValue = parsedGasValue;
        gasUnit = fetchedGasUnit;

        if (readingGasAlert) {
          isGasAlert = true;
          isGasAlertCritical = true;
          alertTime = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
        } else if (readingGasNormal && isGasAlert) {
          isGasAlertCritical = false;
        }
      });
    }
  }

  // Hàm helper để gửi lệnh điều khiển đèn theo tên phòng
  void _controlLed(String room, bool status) {
    api.sendControl('/led/$room', {'status': status ? 1 : 0});
  }

  Future<void> _controlStepper(String action, int times) async {
    if (isStepperBusy) return;
    setState(() => isStepperBusy = true);

    final errorMessage = await api.controlStepper(action, times);

    if (mounted) {
      setState(() => isStepperBusy = false);
      final message = errorMessage == null
          ? 'Lệnh cửa gara "$action" x$times đã được gửi.'
          : 'Lỗi điều khiển cửa gara: $errorMessage';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (errorMessage == null) {
        _refreshSensors();
      }
    }
  }

  Future<void> _controlServo(String door, String action) async {
    if (isServoBusy) return;
    setState(() => isServoBusy = true);

    final success = await api.controlServo(door, action);

    if (mounted) {
      setState(() => isServoBusy = false);
      final message = success
          ? 'Lệnh servo cửa $door "$action" đã được gửi.'
          : 'Không thể gửi lệnh servo cửa $door. Vui lòng kiểm tra kết nối.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (success) {
        _refreshSensors();
      }
    }
  }

  // --- Voice recording and playback helpers ---
  Future<void> _openVoiceRecorderSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ghi âm và xử lý giọng nói',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _isRecording
                          ? 'Đang thu âm...'
                          : _isProcessingVoice
                          ? 'Đang gửi và chờ phản hồi...'
                          : 'Nhấn mic để bắt đầu thu âm',
                    ),
                    if (_isProcessingVoice) ...[
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Đang xử lý phản hồi...'),
                        ],
                      ),
                    ],
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(
                            _isProcessingVoice
                                ? Icons.hourglass_top
                                : _isRecording
                                ? Icons.stop
                                : Icons.mic,
                          ),
                          label: Text(
                            _isProcessingVoice
                                ? 'Chờ phản hồi'
                                : _isRecording
                                ? 'Dừng'
                                : 'Bắt đầu',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording
                                ? Colors.red
                                : (_isProcessingVoice
                                      ? Colors.grey
                                      : Colors.blue),
                          ),
                          onPressed: _isProcessingVoice
                              ? null
                              : () async {
                                  if (_isRecording) {
                                    await _stopRecordingAndSend();
                                    setModalState(() {});
                                  } else {
                                    await _startRecording();
                                    setModalState(() {});
                                  }
                                },
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(Icons.play_arrow),
                          label: Text('Phát trả lời'),
                          onPressed:
                              (_isProcessingVoice ||
                                  (_responseAudioFile == null &&
                                      _responseAudioUrl == null))
                              ? null
                              : () async {
                                  await _playResponseAudio();
                                  setModalState(() {});
                                },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_userText != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Bạn nói:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(_userText!),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Phản hồi AI:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(_aiResponse ?? ''),
                    ],
                    SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        final hasPerm = await _webRecorder.hasPermission();
        if (!hasPerm) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quyền microphone bị từ chối trên web')),
          );
          return;
        }
        await _webRecorder.start();
        setState(() {
          _isRecording = true;
          _isProcessingVoice = false;
          _requestPath = null;
          _userText = null;
          _aiResponse = null;
          _responseAudioFile = null;
          _responseAudioUrl = null;
        });
      } else {
        // Request microphone permission at runtime
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Quyền microphone đã bị từ chối vĩnh viễn. Vui lòng bật trong cài đặt.',
                ),
              ),
            );
            openAppSettings();
            return;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Quyền microphone bị từ chối')),
            );
            return;
          }
        }
        final hasPerm = await _recorder.hasPermission();
        if (!hasPerm) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không có quyền thu âm')));
          return;
        }
        final tmpDir = await getTemporaryDirectory();
        final path = '${tmpDir.path}/request_audio.wav';
        await _recorder.start(
          RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _isProcessingVoice = false;
          _requestPath = path;
          _userText = null;
          _aiResponse = null;
          _responseAudioFile = null;
          _responseAudioUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi bắt đầu thu âm: $e')));
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessingVoice = true;
      });
      Map<String, dynamic> resp = {};
      if (kIsWeb) {
        final bytes = await _webRecorder.stop();
        if (bytes == null) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không ghi được âm trên web')));
          return;
        }
        // upload bytes
        resp = await api.processVoiceBytes(bytes, 'request_audio.webm');
      } else {
        final path = await _recorder.stop();
        if (path == null) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể dừng ghi âm hoặc lấy file đã ghi.'),
            ),
          );
          return;
        }
        setState(() => _requestPath = path);
        if (!File(path).existsSync()) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tệp ghi âm không tồn tại sau khi dừng.')),
          );
          return;
        }
        final fileSize = await File(path).length();
        if (fileSize == 0) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tệp ghi âm trống, vui lòng thử lại.')),
          );
          return;
        }
        print('DEBUG: Recording file size: $fileSize bytes');
        // Gửi file đến server
        resp = await api.processVoice(path);
      }
      if (resp.containsKey('error')) {
        setState(() => _isProcessingVoice = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi server: ${resp['error']}')));
        return;
      }

      setState(() {
        _userText = resp['user_text']?.toString();
        _aiResponse = resp['ai_response']?.toString();
      });

      final audioUrl = resp['audio_url']?.toString();
      if (audioUrl != null && audioUrl.isNotEmpty) {
        if (kIsWeb) {
          final directUrl = await api.downloadAudioUrl(audioUrl);
          if (directUrl != null) {
            // On web we can directly play from URL
            setState(() {
              _responseAudioFile = null;
              _responseAudioUrl = directUrl;
            });
          }
        } else {
          final file = await api.downloadAudio(audioUrl);
          if (file != null) setState(() => _responseAudioFile = file);
        }
      }
      setState(() => _isProcessingVoice = false);
    } catch (e) {
      setState(() => _isProcessingVoice = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi dừng/thực hiện: $e')));
    }
  }

  Future<void> _playResponseAudio() async {
    try {
      if (_responseAudioFile == null && _responseAudioUrl == null) return;
      if (_isPlayingAudio) {
        await _audioPlayer.stop();
        setState(() => _isPlayingAudio = false);
        return;
      }
      setState(() => _isPlayingAudio = true);
      if (kIsWeb) {
        if (_responseAudioUrl != null)
          await _audioPlayer.play(UrlSource(_responseAudioUrl!));
      } else {
        await _audioPlayer.play(DeviceFileSource(_responseAudioFile!.path));
      }
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlayingAudio = false);
      });
    } catch (e) {
      setState(() => _isPlayingAudio = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi phát audio: $e')));
    }
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
            children: [UrlSetup(onConnect: _testConnection)],
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
          IconButton(icon: Icon(Icons.mic), onPressed: _openVoiceRecorderSheet),
          if (isGasAlert)
            Icon(
              Icons.warning_amber_rounded,
              color: isGasAlertCritical ? Colors.red : Colors.amber,
            ),
          if (isGasAlert) SizedBox(width: 15),
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
                    "Phòng ăn",
                    Icons.restaurant,
                    (val) => _controlLed('dining', val),
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

            // Điều khiển cửa gara
            Text(
              "Điều khiển cửa gara",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            StepperControl(
              status: stepperState,
              isBusy: isStepperBusy,
              onControl: _controlStepper,
            ),

            SizedBox(height: 30),

            // Điều khiển servo cửa trước / cửa sau
            Text(
              "Điều khiển servo cửa",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ServoControl(
              frontStatus: frontServoState,
              backStatus: backServoState,
              isBusy: isServoBusy,
              onCommand: _controlServo,
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
    final alertColor = isGasAlertCritical
        ? Colors.redAccent
        : Colors.amber[700]!;
    final iconColor = Colors.white;
    final alertLabel = isGasAlertCritical
        ? "CẢNH BÁO GAS NGUY HIỂM"
        : "CẢNH BÁO GAS - KIỂM TRA LẠI";
    final statusText = isGasAlertCritical
        ? "Mức gas vượt ngưỡng"
        : "Đã ổn định tạm thời";

    return Container(
      margin: EdgeInsets.only(bottom: 25),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: iconColor, size: 40),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alertLabel,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Mức gas: ${gasValue?.toStringAsFixed(1) ?? '--'} $gasUnit",
                  style: TextStyle(
                    color: iconColor.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: iconColor.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Thời gian: $alertTime",
                  style: TextStyle(
                    color: iconColor.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.cancel, color: iconColor.withOpacity(0.85)),
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
