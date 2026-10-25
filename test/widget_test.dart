import 'package:flutter_test/flutter_test.dart';
import 'package:fin_logs/main.dart';

void main() {
  testWidgets('FinSailApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinSailApp());
    expect(find.byType(FinSailApp), findsOneWidget);
    // Advance test clock past any async delays
    await tester.pump(const Duration(milliseconds: 3000));
  });
}
