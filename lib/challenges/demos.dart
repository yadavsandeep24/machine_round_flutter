import 'package:flutter/material.dart';

/// C01 demo: open a screen whose request takes 2 s, and leave it early.
class LeaveEarlyDemo extends StatelessWidget {
  const LeaveEarlyDemo({required this.screen, super.key});

  final Widget Function(Future<String> Function() load) screen;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Profile')),
                body: screen(() => Future.delayed(const Duration(seconds: 2), () => 'Ada')),
              ),
            ),
          ),
          child: const Text('Open profile'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Tap back within 2 seconds, then check the debug console.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}

/// C02 demo: open a timer screen, go back, and watch ticks keep counting.
class LeakDemo extends StatefulWidget {
  const LeakDemo({required this.screen, super.key});

  final Widget Function(VoidCallback onTick) screen;

  @override
  State<LeakDemo> createState() => _LeakDemoState();
}

class _LeakDemoState extends State<LeakDemo> {
  final _ticks = ValueNotifier<int>(0);

  @override
  void dispose() {
    _ticks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Timer')),
                body: widget.screen(() => _ticks.value++),
              ),
            ),
          ),
          child: const Text('Open timer screen'),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<int>(
          valueListenable: _ticks,
          builder: (_, ticks, __) => Text('Timer callbacks so far: $ticks'),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Go back after a few seconds. If the count keeps growing, the timer leaked.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
