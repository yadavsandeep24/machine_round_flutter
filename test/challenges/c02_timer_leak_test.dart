import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c02_timer_leak/fixed.dart';

// The buggy version cannot be tested here on purpose: testWidgets itself fails
// with "A Timer is still pending even after the widget tree was disposed".
// That framework check is exactly the bug, caught for free.
void main() {
  testWidgets('fixed: ticks while visible, stops after leaving', (tester) async {
    var ticks = 0;
    await tester.pumpWidget(MaterialApp(home: CountdownFixed(onTick: () => ticks++)));
    await tester.pump(const Duration(seconds: 3));
    expect(ticks, 3);
    expect(find.text('Elapsed: 3 s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox()); // leave the screen
    await tester.pump(const Duration(seconds: 5));
    expect(ticks, 3);
  });
}
