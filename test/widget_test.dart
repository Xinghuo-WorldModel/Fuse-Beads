import 'package:flutter_test/flutter_test.dart';
import 'package:pindou/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const PindouApp());
    expect(find.text('拼豆图制作'), findsOneWidget);
  });
}
