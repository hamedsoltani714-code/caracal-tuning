import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caracal_admin/main.dart';

void main() {
  testWidgets('CARACAL ADMIN login screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('CARACAL'), findsOneWidget);
    expect(find.text('ADMIN CONTROL CENTER'), findsOneWidget);
    expect(find.text('ورود امن مالک و مدیران'), findsOneWidget);
  });
}
