import 'package:flutter_test/flutter_test.dart';
import 'package:e3dadi/main.dart';

void main() {
  testWidgets('Sons Of King app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SonsOfKingApp());

    expect(find.text('منظومة أولاد الملك'), findsOneWidget);
  });
}