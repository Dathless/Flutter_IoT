// Web implementation of a simple audio recorder using MediaRecorder API.
// This file imports `dart:html` and must only be used on web.
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

class WebAudioRecorder {
  MediaStream? _stream;
  MediaRecorder? _recorder;
  final List<Blob> _chunks = [];

  Future<bool> hasPermission() async {
    try {
      await window.navigator.mediaDevices!.getUserMedia({'audio': true});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> start() async {
    _chunks.clear();
    _stream = await window.navigator.mediaDevices!.getUserMedia({
      'audio': true,
    });
    _recorder = MediaRecorder(_stream!);
    _recorder!.addEventListener('dataavailable', (Event ev) {
      if (ev is BlobEvent && ev.data != null) {
        _chunks.add(ev.data!);
      }
    });
    _recorder!.start();
  }

  // Stops recording and returns the recorded bytes (web) as a List<int>
  Future<List<int>?> stop() async {
    if (_recorder == null) return null;
    final completer = Completer<List<int>?>();

    _recorder!.addEventListener('stop', (Event _) async {
      try {
        final blob = Blob(_chunks);
        final reader = FileReader();
        reader.readAsArrayBuffer(blob);
        await reader.onLoad.first;
        final result = reader.result as ByteBuffer;
        final bytes = result.asUint8List();
        completer.complete(bytes);
      } catch (e) {
        completer.complete(null);
      }
    });

    _recorder!.stop();
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
    _recorder = null;
    return completer.future;
  }
}
