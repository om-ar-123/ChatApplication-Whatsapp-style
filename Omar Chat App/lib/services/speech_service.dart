import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechService {
  SpeechService();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tts_enabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tts_enabled', enabled);
  }

  Future<void> speakSenderName(String senderName) async {
    await speakMessageReceived(senderName);
  }

  Future<void> speakMessageReceived(String senderName) async {
    if (!await isEnabled()) return;
    await init();
    await _tts.speak('$senderName sent you a message');
  }

  Future<void> speakMention(String senderName, String groupName) async {
    if (!await isEnabled()) return;
    await init();
    await _tts.speak('$senderName mentioned you in $groupName');
  }
}
