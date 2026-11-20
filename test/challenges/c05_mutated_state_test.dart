import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c05_mutated_state/buggy.dart';
import 'package:machine_round/challenges/c05_mutated_state/fixed.dart';

void main() {
  test('buggy: second add is swallowed by Bloc (same instance)', () async {
    final cubit = CartCubitBuggy();
    final emitted = <int>[];
    final sub = cubit.stream.listen((s) => emitted.add(s.length));
    cubit
      ..add('a')
      ..add('b');
    await Future<void>.delayed(Duration.zero);
    expect(emitted, hasLength(1)); // only the first emit got through
    expect(cubit.state, hasLength(2)); // ...but the data did change
    await sub.cancel();
    await cubit.close();
  });

  test('fixed: every add emits a new list', () async {
    final cubit = CartCubitFixed();
    final emitted = <int>[];
    final sub = cubit.stream.listen((s) => emitted.add(s.length));
    cubit
      ..add('a')
      ..add('b');
    await Future<void>.delayed(Duration.zero);
    expect(emitted, [1, 2]);
    expect(() => cubit.state.add('c'), throwsUnsupportedError);
    await sub.cancel();
    await cubit.close();
  });

  testWidgets('buggy UI shows a stale count; fixed UI is correct', (tester) async {
    for (final (widget, expected) in [(const CartBuggy(), 1), (const CartFixed(), 3)]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Add'));
        await tester.pump();
      }
      expect(find.text('Items in cart: $expected'), findsOneWidget);
    }
  });
}
