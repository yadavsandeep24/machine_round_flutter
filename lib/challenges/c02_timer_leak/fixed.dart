import 'dart:async';

import 'package:flutter/material.dart';

/// FIX: keep a reference and cancel it in `dispose`. Same for
/// StreamSubscription, AnimationController, TextEditingController,
/// ScrollController, FocusNode, and listeners added with addListener.
class CountdownFixed extends StatefulWidget {
  const CountdownFixed({this.onTick, super.key});

  final VoidCallback? onTick;

  @override
  State<CountdownFixed> createState() => _CountdownFixedState();
}

class _CountdownFixedState extends State<CountdownFixed> {
  int seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.onTick?.call();
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(child: Text('Elapsed: $seconds s'));
}
