import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'file_storage.dart';

class MediaService {
  MediaService();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _recordingPath;
  String? _cachedDemoVoicePath;

  /// Copies bundled notification sound to app storage for simulated voice replies.
  Future<String> demoVoiceReplyPath() async {
    if (_cachedDemoVoicePath != null) return _cachedDemoVoicePath!;
    final bytes = await rootBundle.load('assets/sounds/message_notification.wav');
    final path = await saveBytesToAppDir(bytes.buffer.asUint8List(), 'voice_reply_demo.wav');
    _cachedDemoVoicePath = path;
    return path;
  }

  Future<bool> startRecording() async {
    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordingPath!,
      );
      return true;
    }
    return false;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path ?? _recordingPath;
  }

  Future<void> playAudio(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
