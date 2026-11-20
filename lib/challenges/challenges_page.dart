import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'challenge.dart';
import 'challenges.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bugs & optimisation: top 10')),
      body: ListView.separated(
        itemCount: challenges.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = challenges[i];
          final isBug = c.kind == ChallengeKind.bug;
          return ListTile(
            leading: CircleAvatar(child: Text('${c.number}')),
            title: Text(c.title),
            subtitle: Text(c.symptom, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Chip(
              label: Text(isBug ? 'Bug' : 'Perf'),
              avatar: Icon(isBug ? Icons.bug_report_outlined : Icons.speed, size: 16),
            ),
            onTap: () => context.push('/challenge/${c.number}'),
          );
        },
      ),
    );
  }
}

enum _Mode { buggy, fixed }

class ChallengeDetailPage extends StatefulWidget {
  const ChallengeDetailPage({required this.number, super.key});

  final int number;

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> {
  _Mode _mode = _Mode.buggy;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final matches = challenges.where((c) => c.number == widget.number);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Unknown challenge')),
      );
    }
    final c = matches.first;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('${c.number}. ${c.title}')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Symptom', style: text.labelLarge),
                Text(c.symptom),
                const SizedBox(height: 6),
                Text('Try it', style: text.labelLarge),
                Text(c.reproduce),
                if (_showAnswer) ...[
                  const SizedBox(height: 6),
                  Text('Root cause', style: text.labelLarge),
                  Text(c.rootCause),
                  const SizedBox(height: 6),
                  Text('Fix', style: text.labelLarge),
                  Text(c.fix),
                ],
                Row(
                  children: [
                    SegmentedButton<_Mode>(
                      segments: const [
                        ButtonSegment(value: _Mode.buggy, label: Text('Buggy')),
                        ButtonSegment(value: _Mode.fixed, label: Text('Fixed')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) => setState(() => _mode = s.first),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _showAnswer = !_showAnswer),
                      child: Text(_showAnswer ? 'Hide answer' : 'Show answer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            // A new key per mode gives the demo a fresh State each switch.
            child: KeyedSubtree(
              key: ValueKey(_mode),
              child: Builder(builder: _mode == _Mode.buggy ? c.buggy : c.fixed),
            ),
          ),
        ],
      ),
    );
  }
}
