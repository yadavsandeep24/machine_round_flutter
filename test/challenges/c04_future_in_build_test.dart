import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c04_future_in_build/buggy.dart';
import 'package:machine_round/challenges/c04_future_in_build/fixed.dart';

void main() {
  late int calls;
  Future<String> fetch() async {
    calls++;
    return 'Ada';
  }

  setUp(() => calls = 0);

  testWidgets('buggy: every rebuild refetches and flashes the spinner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileFutureBuggy(fetch: fetch)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Like'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // flashed again
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Like'));
    await tester.pumpAndSettle();
    expect(calls, 3);
  });

  testWidgets('fixed: one request no matter how often it rebuilds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileFutureFixed(fetch: fetch)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Like'));
    await tester.pump();
    expect(find.text('Profile: Ada'), findsOneWidget);
    await tester.tap(find.textContaining('Like'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });
}
