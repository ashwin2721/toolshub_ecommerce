import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Simple UI Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Toolshub'),
        ),
      ),
    );
    expect(find.text('Toolshub'), findsOneWidget);
  });
}
