import 'package:flutter/material.dart';

/// BUG: check "B", delete "A": now "C" is checked and "B" is not. Rows are
/// StatefulWidgets of the same type with no key, so Flutter matches
/// Elements (and their State) by POSITION. After a removal, the State that
/// belonged to index 1 is reused for whatever is now at index 1.
class TasksBuggy extends StatefulWidget {
  const TasksBuggy({super.key});

  @override
  State<TasksBuggy> createState() => _TasksBuggyState();
}

class _TasksBuggyState extends State<TasksBuggy> {
  final items = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final item in items)
        TaskRowBuggy(label: item, onDelete: () => setState(() => items.remove(item))),
    ],
  );
}

class TaskRowBuggy extends StatefulWidget {
  const TaskRowBuggy({required this.label, required this.onDelete, super.key});

  final String label;
  final VoidCallback onDelete;

  @override
  State<TaskRowBuggy> createState() => _TaskRowBuggyState();
}

class _TaskRowBuggyState extends State<TaskRowBuggy> {
  bool done = false;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: done,
    onChanged: (v) => setState(() => done = v ?? false),
    title: Text('Task ${widget.label}'),
    secondary: IconButton(
      tooltip: 'Delete ${widget.label}',
      icon: const Icon(Icons.delete_outline),
      onPressed: widget.onDelete,
    ),
  );
}
