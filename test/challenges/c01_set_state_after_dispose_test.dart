import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c01_set_state_after_dispose/buggy.dart';
import 'package:machine_round/challenges/c01_set_state_after_dispose/fixed.dart';

void main() {
  testWidgets('buggy: setState after the user left throws', (tester) async {
    final response = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ProfileBuggy(load: () => response.future)));
    final pending = tester.state<ProfileBuggyState>(find.byType(ProfileBuggy)).pending!;
    final failed = expectLater(pending, throwsA(isA<FlutterError>()));

    await tester.pumpWidget(const SizedBox()); // user tapped back
    response.complete('Ada');
    await failed;
  });

  testWidgets('fixed: the late response is ignored', (tester) async {
    final response = Completer<String>();
    await tester.pumpWidget(MaterialApp(home: ProfileFixed(load: () => response.future)));
    final pending = tester.state<ProfileFixedState>(find.byType(ProfileFixed)).pending!;

    await tester.pumpWidget(const SizedBox());
    response.complete('Ada');
    await expectLater(pending, completes);
  });

  testWidgets('fixed: still shows the result when the user stays', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ProfileFixed(load: () async => 'Ada')));
    await tester.pump();
    expect(find.text('Hello, Ada'), findsOneWidget);
  });
}
