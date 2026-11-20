import 'package:flutter/material.dart';

import 'shared.dart';

/// SLOW: "leaderboard rendering". A Column inside a SingleChildScrollView
/// builds, lays out and keeps in memory ALL 2000 rows up front, even though
/// ~10 are visible. Opening the screen janks and memory grows with the list.
class LeaderboardBuggy extends StatelessWidget {
  const LeaderboardBuggy({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(children: [for (var i = 1; i <= kLeaderboardSize; i++) LeaderboardRow(rank: i)]),
  );
}
