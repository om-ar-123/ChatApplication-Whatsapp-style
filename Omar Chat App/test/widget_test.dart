import 'package:flutter_test/flutter_test.dart';
import 'package:omar_chat/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OmarChatApp());
    expect(find.text('OMAR Chat'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
