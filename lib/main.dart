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
import 'dart:typed_data';
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
  String motorStatus = "closed";
  bool isMotorBusy = false;

  bool livingRoomLed = false;
  bool bedroomLed = false;
  bool diningLed = false;
  bool wcLed = false;
  bool garageLed = false;

  DateTime? _lastLedControlTime = null;
  final Duration _ledGracePeriod = Duration(seconds: 2);

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
    _sensorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _refreshSensors();
    });
    _gasTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _refreshGasStatus();
    });
  }

  void _refreshSensors() async {
    final dhtDataFuture = api.getSensorData('/dht');
    final stepperDataFuture = api.getStepperStatus();
    final motorDataFuture = api.getMotorStatus();
    final ledDataFuture = api.getLedStatus();
    final frontServoFuture = api.getServoStatus('front');
    final backServoFuture = api.getServoStatus('back');

    final dhtData = await dhtDataFuture;
    final stepperData = await stepperDataFuture;
    final motorData = await motorDataFuture;
    final ledData = await ledDataFuture;
    final frontServoData = await frontServoFuture;
    final backServoData = await backServoFuture;

    String fetchedStepperState = '--';
    String fetchedMotorStatus = '--';
    String fetchedFrontServoStatus = '--';
    String fetchedBackServoStatus = '--';
    bool fetchedLivingRoomLed = false;
    bool fetchedBedroomLed = false;
    bool fetchedDiningLed = false;
    bool fetchedWcLed = false;
    bool fetchedGarageLed = false;

    if (stepperData['status'] == 'success') {
      fetchedStepperState =
          stepperData['state']?.toString() ??
          stepperData['message']?.toString() ??
          '--';
    }

    if (motorData['status'] != '') {
      final status = motorData['status']?.toString() ?? '--';
      if (status.toLowerCase().contains('open')) {
        fetchedMotorStatus = 'open';
      } else if (status.toLowerCase().contains('closed')) {
        fetchedMotorStatus = 'closed';
      } else {
        fetchedMotorStatus = status;
      }
    }

    if (ledData['status'] == 'success') {
      final statusMap = _extractLedMap(ledData);
      if (!_isLedUnderGracePeriod()) {
        fetchedLivingRoomLed = _parseBoolState(statusMap['living-room']);
        fetchedBedroomLed = _parseBoolState(statusMap['bedroom']);
        fetchedDiningLed = _parseBoolState(statusMap['dining']);
        fetchedWcLed = _parseBoolState(statusMap['wc']);
        fetchedGarageLed = _parseBoolState(statusMap['gara']);
      }
    }

    if (frontServoData['status'] == 'success') {
      fetchedFrontServoStatus = frontServoData['message']?.toString() ?? '--';
    }

    if (backServoData['status'] == 'success') {
      fetchedBackServoStatus = backServoData['message']?.toString() ?? '--';
    }

    if (mounted) {
      setState(() {
        temp = dhtData['temp']?.toString() ?? "--";
        humidity = dhtData['humi']?.toString() ?? "--";
        stepperState = fetchedStepperState;
        motorStatus = fetchedMotorStatus;
        frontServoState = fetchedFrontServoStatus;
        backServoState = fetchedBackServoStatus;
        if (!_isLedUnderGracePeriod()) {
          livingRoomLed = fetchedLivingRoomLed;
          bedroomLed = fetchedBedroomLed;
          diningLed = fetchedDiningLed;
          wcLed = fetchedWcLed;
          garageLed = fetchedGarageLed;
        }
      });
    }
  }

  bool _parseBoolState(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'on' ||
          normalized == 'open';
    }
    return false;
  }

  Map<String, dynamic> _extractLedMap(Map<String, dynamic> response) {
    if (response.containsKey('living-room') ||
        response.containsKey('bedroom')) {
      return response;
    }

    final possibleKeys = ['data', 'result', 'payload', 'value'];
    for (final key in possibleKeys) {
      final nested = response[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
    }

    return response;
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
    _lastLedControlTime = DateTime.now();
    api.sendControl('/led/$room', {'status': status ? 1 : 0});
  }

  bool _isLedUnderGracePeriod() {
    if (_lastLedControlTime == null) return false;
    final elapsed = DateTime.now().difference(_lastLedControlTime!);
    return elapsed < _ledGracePeriod;
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

  Future<void> _controlMotor(String action) async {
    if (isMotorBusy) return;
    setState(() => isMotorBusy = true);

    final success = action == 'open'
        ? await api.controlMotorOpen()
        : await api.controlMotorClose();

    if (mounted) {
      setState(() => isMotorBusy = false);
      final message = success
          ? 'Lệnh cửa chính "$action" đã được gửi.'
          : 'Không thể gửi lệnh cửa chính. Vui lòng kiểm tra kết nối.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      if (success) {
        _refreshMotorStatus();
      }
    }
  }

  void _refreshMotorStatus() async {
    final motorData = await api.getMotorStatus();

    String fetchedMotorStatus = '--';

    if (motorData['status'] == 'success') {
      final status = motorData['status']?.toString() ?? '--';
      // Map API status response to display status
      if (status.toLowerCase().contains('open') ||
          motorData['status']?.toString().toLowerCase() == 'open') {
        fetchedMotorStatus = 'open';
      } else if (status.toLowerCase().contains('closed') ||
          motorData['status']?.toString().toLowerCase() == 'closed') {
        fetchedMotorStatus = 'closed';
      } else {
        fetchedMotorStatus = motorData['status']?.toString() ?? '--';
      }
    }

    if (mounted) {
      setState(() {
        motorStatus = fetchedMotorStatus;
      });
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
        if (!File(path).existsSync()) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tệp ghi âm không tồn tại sau khi dừng.')),
          );
          return;
        }
        final bytes = await File(path).readAsBytes();
        if (bytes.isEmpty) {
          setState(() => _isProcessingVoice = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tệp ghi âm trống, vui lòng thử lại.')),
          );
          return;
        }

        final trimmedBytes = await _trimWavSilence(bytes, threshold: 0.02);
        if (trimmedBytes.length < bytes.length) {
          print(
            'DEBUG: Removed silence from WAV file: ${bytes.length - trimmedBytes.length} bytes',
          );
        }

        resp = await api.processVoiceBytes(trimmedBytes, 'request_audio.wav');
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

  Future<List<int>> _trimWavSilence(
    List<int> wavBytes, {
    double threshold = 0.02,
  }) async {
    if (wavBytes.length < 44) return wavBytes;
    final header = String.fromCharCodes(wavBytes.sublist(0, 4));
    final waveChunk = String.fromCharCodes(wavBytes.sublist(8, 12));
    if (header != 'RIFF' || waveChunk != 'WAVE') return wavBytes;

    final byteData = ByteData.sublistView(Uint8List.fromList(wavBytes));
    int offset = 12;
    int dataOffset = -1;
    int dataSize = 0;
    int numChannels = 1;
    int bitsPerSample = 16;
    int audioFormat = 1;

    while (offset + 8 <= wavBytes.length) {
      final chunkId = String.fromCharCodes(
        wavBytes.sublist(offset, offset + 4),
      );
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);
      final chunkDataStart = offset + 8;
      if (chunkDataStart + chunkSize > wavBytes.length) break;

      if (chunkId == 'fmt ') {
        audioFormat = byteData.getUint16(chunkDataStart, Endian.little);
        numChannels = byteData.getUint16(chunkDataStart + 2, Endian.little);
        bitsPerSample = byteData.getUint16(chunkDataStart + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataStart;
        dataSize = chunkSize;
        break;
      }

      offset = chunkDataStart + chunkSize;
      if (chunkSize.isOdd) offset += 1;
    }

    if (dataOffset < 0 || dataSize <= 0) return wavBytes;
    if (audioFormat != 1 || bitsPerSample != 16) return wavBytes;

    final frameSize = numChannels * (bitsPerSample ~/ 8);
    final frameCount = dataSize ~/ frameSize;

    bool frameHasVoice(int frameIndex) {
      final base = dataOffset + frameIndex * frameSize;
      for (int channel = 0; channel < numChannels; channel++) {
        final sampleOffset = base + channel * 2;
        final sample = byteData.getInt16(sampleOffset, Endian.little);
        final amplitude = sample.abs() / 32768.0;
        if (amplitude > threshold) return true;
      }
      return false;
    }

    int firstVoiceFrame = 0;
    while (firstVoiceFrame < frameCount && !frameHasVoice(firstVoiceFrame)) {
      firstVoiceFrame++;
    }
    int lastVoiceFrame = frameCount - 1;
    while (lastVoiceFrame >= 0 && !frameHasVoice(lastVoiceFrame)) {
      lastVoiceFrame--;
    }

    if (firstVoiceFrame == 0 && lastVoiceFrame == frameCount - 1)
      return wavBytes;
    if (firstVoiceFrame >= frameCount || lastVoiceFrame < 0) return wavBytes;

    final trimmedData = wavBytes.sublist(
      dataOffset + firstVoiceFrame * frameSize,
      dataOffset + (lastVoiceFrame + 1) * frameSize,
    );

    final result = Uint8List(wavBytes.length - dataSize + trimmedData.length);
    result.setAll(0, wavBytes.sublist(0, dataOffset));
    result.setAll(wavBytes.sublist(0, dataOffset).length, trimmedData);
    final resultView = ByteData.sublistView(result);
    resultView.setUint32(4, result.length - 8, Endian.little);
    resultView.setUint32(dataOffset - 4, trimmedData.length, Endian.little);
    return result;
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
                    title: 'Phòng khách - LED',
                    isSwitched: livingRoomLed,
                    onToggle: (val) {
                      setState(() => livingRoomLed = val);
                      _controlLed('living-room', val);
                    },
                  ),
                  Divider(height: 1),
                  _buildLedItem("Phòng ngủ", Icons.bed, bedroomLed, (val) {
                    setState(() => bedroomLed = val);
                    _controlLed('bedroom', val);
                  }),
                  Divider(height: 1),
                  _buildLedItem("Phòng ăn", Icons.restaurant, diningLed, (val) {
                    setState(() => diningLed = val);
                    _controlLed('dining', val);
                  }),
                  Divider(height: 1),
                  _buildLedItem("Nhà vệ sinh", Icons.wc, wcLed, (val) {
                    setState(() => wcLed = val);
                    _controlLed('wc', val);
                  }),
                  Divider(height: 1),
                  _buildLedItem("Gara xe", Icons.garage, garageLed, (val) {
                    setState(() => garageLed = val);
                    _controlLed('gara', val);
                  }),
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
              frontTitle: 'Cửa phòng ngủ',
              backTitle: 'Cửa phòng vệ sinh',
              frontStatus: frontServoState,
              backStatus: backServoState,
              isBusy: isServoBusy,
              onCommand: _controlServo,
            ),

            SizedBox(height: 30),

            // Điều khiển cửa chính
            Text(
              "Điều khiển cửa chính",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Trạng thái cửa chính",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              motorStatus == 'open'
                                  ? 'Mở'
                                  : motorStatus == 'closed'
                                  ? 'Đóng'
                                  : 'Không xác định',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: motorStatus == 'open'
                                    ? Colors.green
                                    : motorStatus == 'closed'
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          motorStatus == 'open'
                              ? Icons.lock_open
                              : motorStatus == 'closed'
                              ? Icons.lock
                              : Icons.help,
                          size: 40,
                          color: motorStatus == 'open'
                              ? Colors.green
                              : motorStatus == 'closed'
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.lock_open),
                            label: Text('Mở'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            onPressed: isMotorBusy
                                ? null
                                : () => _controlMotor('open'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.lock),
                            label: Text('Đóng'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: isMotorBusy
                                ? null
                                : () => _controlMotor('close'),
                          ),
                        ),
                      ],
                    ),
                    if (isMotorBusy) ...[
                      SizedBox(height: 16),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Đang gửi...'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
  Widget _buildLedItem(
    String title,
    IconData icon,
    bool isSwitched,
    Function(bool) onToggle,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSwitched ? Colors.yellow : Colors.grey,
        size: 30,
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: isSwitched,
        onChanged: onToggle,
        activeThumbColor: Colors.orangeAccent,
      ),
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
