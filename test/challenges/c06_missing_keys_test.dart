import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c06_missing_keys/buggy.dart';
import 'package:machine_round/challenges/c06_missing_keys/fixed.dart';

bool _checked(WidgetTester tester, String label) =>
    tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Task $label')).value!;

Future<void> _checkBThenDeleteA(WidgetTester tester, Widget list) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: list)));
  await tester.tap(find.text('Task B'));
  await tester.pump();
  await tester.tap(find.byTooltip('Delete A'));
  await tester.pump();
}

void main() {
  testWidgets('buggy: the check jumps from B to C', (tester) async {
    await _checkBThenDeleteA(tester, const TasksBuggy());
    expect(_checked(tester, 'B'), isFalse);
    expect(_checked(tester, 'C'), isTrue);
  });

  testWidgets('fixed: B stays checked', (tester) async {
    await _checkBThenDeleteA(tester, const TasksFixed());
    expect(_checked(tester, 'B'), isTrue);
    expect(_checked(tester, 'C'), isFalse);
  });
}
