import 'dart:async';

import 'package:flutter/material.dart';

/// BUG: the periodic timer is never cancelled. After leaving the screen it
/// keeps firing forever: wasted CPU/battery, and `setState` after dispose.
class CountdownBuggy extends StatefulWidget {
  const CountdownBuggy({this.onTick, super.key});

  final VoidCallback? onTick;

  @override
  State<CountdownBuggy> createState() => _CountdownBuggyState();
}

class _CountdownBuggyState extends State<CountdownBuggy> {
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (_) {
      widget.onTick?.call();
      if (mounted) setState(() => seconds++); // hides the crash, not the leak
    });
  }

  @override
  Widget build(BuildContext context) => Center(child: Text('Elapsed: $seconds s'));
}
