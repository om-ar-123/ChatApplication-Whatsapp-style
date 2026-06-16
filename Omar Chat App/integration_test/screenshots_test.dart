import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:omar_chat/app.dart';
import 'package:omar_chat/core/constants/app_routes.dart';

Future<void> boot(WidgetTester tester) async {
  await initializeApp();
  await tester.pumpWidget(const OmarChatApp());
  await tester.pumpAndSettle(const Duration(seconds: 4));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture report screenshots', (tester) async {
    await boot(tester);
    await binding.takeScreenshot('01_splash_or_loading');

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_chat_list');

    await tester.tap(find.text('Ahmed').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('03_chat_detail_direct');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Project Team').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('04_chat_detail_group');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search).first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('05_search');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt_outlined).first);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('06_status');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('07_settings');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My profile').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('08_profile');

    await tester.pageBack();
    await tester.pumpAndSettle();

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed(AppRoutes.userDetail, arguments: {'userId': 2});
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await binding.takeScreenshot('09_user_detail');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('New group').last);
    await tester.pumpAndSettle();
    await binding.takeScreenshot('10_create_group');
  });
}
