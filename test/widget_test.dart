import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_agua_san_miguel/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SistemaAguaApp());
  });
}
