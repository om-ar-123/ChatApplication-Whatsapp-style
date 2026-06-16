import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'omar_chat_messages',
            'Messages',
            description: 'New message notifications',
            importance: Importance.high,
          ));
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init skipped: $e');
    }
  }

  Future<void> showMessageNotification({
    required int id,
    required String senderName,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      await _plugin.show(
        id,
        '$senderName sent you a message',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'omar_chat_messages',
            'Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Notification show skipped: $e');
    }
  }

  Future<void> showMentionNotification({
    required int id,
    required String senderName,
    required String groupName,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      await _plugin.show(
        id + 10000,
        '$senderName mentioned you',
        'In $groupName: $body',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'omar_chat_messages',
            'Messages',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Mention notification skipped: $e');
    }
  }
}
