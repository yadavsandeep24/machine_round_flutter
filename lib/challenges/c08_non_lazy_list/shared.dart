import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const kLeaderboardSize = 2000;

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({required this.rank, super.key});

  final int rank;

  /// Debug-only build counter used by the tests to prove the difference.
  @visibleForTesting
  static int debugBuilds = 0;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugBuilds++;
    return ListTile(
      leading: CircleAvatar(child: Text('$rank')),
      title: Text('Player $rank'),
      trailing: Text('${(kLeaderboardSize - rank) * 10} pts'),
    );
  }
}
