import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c03_controller_in_build/buggy.dart';
import 'package:machine_round/challenges/c03_controller_in_build/fixed.dart';

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('buggy: the field is wiped by the rebuild', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchBuggy())));
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();
    expect(find.text('Searching for: "flutter"'), findsOneWidget);
    expect(_fieldText(tester), isEmpty);
  });

  testWidgets('fixed: the text survives the rebuild', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SearchFixed())));
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pump();
    expect(_fieldText(tester), 'flutter');
  });
}
