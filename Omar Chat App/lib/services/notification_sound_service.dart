import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays a short alert sound when a new message arrives.
class NotificationSoundService {
  NotificationSoundService();

  static const _assetPath = 'assets/sounds/message_notification.wav';

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await _player.setAsset(_assetPath);
      _initialized = true;
    } catch (e) {
      debugPrint('Notification sound init skipped: $e');
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }

  Future<void> playMessageSound() async {
    if (!await isEnabled()) return;
    try {
      await init();
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      debugPrint('Notification sound play skipped: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
