// Stub for non-web platforms. Provides the same API surface as the web implementation
// but does nothing so it can be imported safely on all platforms.
class WebAudioRecorder {
  Future<bool> hasPermission() async => false;
  Future<void> start() async {}
  // Returns recorded bytes on web; stub returns null.
  Future<List<int>?> stop() async => null;
}
