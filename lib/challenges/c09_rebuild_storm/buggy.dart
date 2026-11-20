import 'package:flutter/material.dart';

import 'shared.dart';

/// SLOW: "VIP-highlighted user list". Selection lives in the page's State,
/// so one tap calls setState on the whole page and EVERY visible row
/// rebuilds (plus the app bar), just to flip one checkbox.
class UsersSelectBuggy extends StatefulWidget {
  const UsersSelectBuggy({super.key});

  @override
  State<UsersSelectBuggy> createState() => _UsersSelectBuggyState();
}

class _UsersSelectBuggyState extends State<UsersSelectBuggy> {
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text('${selected.length} selected')),
        Expanded(
          child: ListView.builder(
            itemCount: 500,
            itemExtent: 56,
            itemBuilder: (_, i) => _Row(
              index: i,
              selected: selected.contains(i),
              onTap: () => setState(() {
                if (!selected.remove(i)) selected.add(i);
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, required this.selected, required this.onTap});

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    countRowBuild(index);
    return ListTile(
      title: Text('User $index'),
      trailing: Icon(selected ? Icons.star : Icons.star_border),
      selected: selected,
      onTap: onTap,
    );
  }
}
