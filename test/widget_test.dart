import 'package:flutter_test/flutter_test.dart';
import 'package:un_mart_user_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const UBMartApp());
  });
}
