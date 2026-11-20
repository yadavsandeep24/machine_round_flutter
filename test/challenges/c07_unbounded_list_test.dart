import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c07_unbounded_list/buggy.dart';
import 'package:machine_round/challenges/c07_unbounded_list/fixed.dart';

void main() {
  testWidgets('buggy: layout fails with unbounded height', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final original = FlutterError.onError;
    FlutterError.onError = errors.add;
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FeedBuggy())));
    FlutterError.onError = original;

    expect(errors, isNotEmpty);
    expect(errors.first.exceptionAsString(), contains('unbounded height'));
  });

  testWidgets('fixed: renders the list', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FeedFixed())));
    expect(tester.takeException(), isNull);
    expect(find.text('Story 0'), findsOneWidget);
  });
}
