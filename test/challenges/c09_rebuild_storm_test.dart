import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c09_rebuild_storm/buggy.dart';
import 'package:machine_round/challenges/c09_rebuild_storm/fixed.dart';
import 'package:machine_round/challenges/c09_rebuild_storm/shared.dart';

Future<int> _rowsRebuiltByOneTap(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
  debugRowBuilds.clear();
  await tester.tap(find.text('User 3'));
  await tester.pump();
  return debugRowBuilds.length;
}

void main() {
  testWidgets('buggy: one tap rebuilds every visible row', (tester) async {
    final rebuilt = await _rowsRebuiltByOneTap(tester, const UsersSelectBuggy());
    expect(rebuilt, greaterThan(5));
    expect(find.text('1 selected'), findsOneWidget);
  });

  testWidgets('fixed: one tap rebuilds exactly one row', (tester) async {
    final rebuilt = await _rowsRebuiltByOneTap(tester, const UsersSelectFixed());
    expect(rebuilt, 1);
    expect(debugRowBuilds.keys, [3]);
    expect(find.text('1 selected'), findsOneWidget);
  });
}
