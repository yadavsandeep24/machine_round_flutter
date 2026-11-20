import 'package:flutter/material.dart';

import 'shared.dart';

/// FAST: ListView.builder creates rows lazily, only for the viewport plus a
/// small cache area, and recycles them while scrolling. `itemExtent` (or
/// `prototypeItem`) lets the list jump to any offset without measuring every
/// row. The same applies to GridView.builder and SliverList.builder.
class LeaderboardFixed extends StatelessWidget {
  const LeaderboardFixed({super.key});

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: kLeaderboardSize,
    itemExtent: 56,
    itemBuilder: (_, i) => LeaderboardRow(rank: i + 1),
  );
}
