import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omar_chat/app.dart';
import 'package:omar_chat/core/constants/app_routes.dart';
import 'package:omar_chat/data/database/in_memory_store.dart';
import 'package:omar_chat/services/persistence_service.dart';

Future<void> boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    'notifications_enabled': true,
    'sound_enabled': true,
    'tts_enabled': true,
  });
  await PersistenceService.instance.clear();
  await InMemoryStore.instance.reset();
  await initializeApp();
  await tester.pumpWidget(const OmarChatApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> settle(WidgetTester tester, [Duration d = const Duration(milliseconds: 400)]) async {
  await tester.pump(d);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> saveGolden(WidgetTester tester, String name) async {
  await settle(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../report_assets/screenshots/$name.png'),
  );
}

Future<void> openRoute(WidgetTester tester, String route, [Object? arguments]) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator));
  nav.pushNamed(route, arguments: arguments);
  await settle(tester, const Duration(seconds: 1));
}

Future<void> goBack(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator));
  nav.pop();
  await settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    for (final channel in [
      MethodChannel('com.llfbandit.record/messages'),
      MethodChannel('flutter.baseflow.com/permissions/methods'),
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
    }
  });

  testWidgets('report screenshots', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await boot(tester);
    await saveGolden(tester, '01_splash_or_loading');

    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    await saveGolden(tester, '02_chat_list');

    await openRoute(tester, AppRoutes.chatDetail, {
      'chatId': 2,
      'title': 'Ahmed',
      'otherUserId': 3,
      'isGroup': false,
    });
    await saveGolden(tester, '03_chat_detail_direct');
    await goBack(tester);

    await openRoute(tester, AppRoutes.chatDetail, {
      'chatId': 6,
      'title': 'Project Team',
      'isGroup': true,
    });
    await saveGolden(tester, '04_chat_detail_group');
    await goBack(tester);

    await openRoute(tester, AppRoutes.search);
    await saveGolden(tester, '05_search');
    await goBack(tester);

    await openRoute(tester, AppRoutes.status);
    await saveGolden(tester, '06_status');
    await goBack(tester);

    await openRoute(tester, AppRoutes.settings);
    await saveGolden(tester, '07_settings');
    await goBack(tester);

    await openRoute(tester, AppRoutes.profile);
    await saveGolden(tester, '08_profile');
    await goBack(tester);

    await openRoute(tester, AppRoutes.userDetail, {'userId': 2});
    await saveGolden(tester, '09_user_detail');
    await goBack(tester);

    await openRoute(tester, AppRoutes.createGroup);
    await saveGolden(tester, '10_create_group');

    await tester.pump(const Duration(seconds: 3));
  });
}
