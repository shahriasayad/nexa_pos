import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_pos/main.dart';

void main() {
  testWidgets('App loads dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const NexaPosApp());
    await tester.pumpAndSettle();
    expect(find.text('Nexa POS - Dashboard'), findsOneWidget);
  });
}
