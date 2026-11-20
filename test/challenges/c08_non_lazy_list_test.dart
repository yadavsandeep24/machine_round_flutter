import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/challenges/c08_non_lazy_list/buggy.dart';
import 'package:machine_round/challenges/c08_non_lazy_list/fixed.dart';
import 'package:machine_round/challenges/c08_non_lazy_list/shared.dart';

void main() {
  setUp(() => LeaderboardRow.debugBuilds = 0);

  testWidgets('buggy: builds all 2000 rows to show ~10', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LeaderboardBuggy())));
    expect(LeaderboardRow.debugBuilds, kLeaderboardSize);
  });

  testWidgets('fixed: builds only what is on screen (plus cache)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LeaderboardFixed())));
    expect(LeaderboardRow.debugBuilds, lessThan(30));
  });
}
