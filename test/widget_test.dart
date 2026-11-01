import 'package:flutter_test/flutter_test.dart';
import 'package:caracal_tuning/main.dart';

void main() {
  testWidgets('Caracal app starts', (tester) async {
    await tester.pumpWidget(const CaracalApp());
    expect(find.text('CARACAL TUNING'), findsWidgets);
  });
}
