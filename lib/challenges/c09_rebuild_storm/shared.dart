import 'package:flutter/foundation.dart';

/// Counts how many times each row's build ran (debug only, for the tests).
@visibleForTesting
final Map<int, int> debugRowBuilds = {};

void countRowBuild(int index) {
  if (kDebugMode) debugRowBuilds.update(index, (n) => n + 1, ifAbsent: () => 1);
}
