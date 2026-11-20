import 'package:flutter/material.dart';

/// FIX: give each row a stable identity key from the DATA (`ValueKey(id)`),
/// never the index (`ValueKey(index)` has the same bug). Better still, keep
/// "done" in the model so rows can be stateless.
class TasksFixed extends StatefulWidget {
  const TasksFixed({super.key});

  @override
  State<TasksFixed> createState() => _TasksFixedState();
}

class _TasksFixedState extends State<TasksFixed> {
  final items = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (final item in items)
        TaskRowFixed(
          key: ValueKey(item),
          label: item,
          onDelete: () => setState(() => items.remove(item)),
        ),
    ],
  );
}

class TaskRowFixed extends StatefulWidget {
  const TaskRowFixed({required this.label, required this.onDelete, super.key});

  final String label;
  final VoidCallback onDelete;

  @override
  State<TaskRowFixed> createState() => _TaskRowFixedState();
}

class _TaskRowFixedState extends State<TaskRowFixed> {
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
