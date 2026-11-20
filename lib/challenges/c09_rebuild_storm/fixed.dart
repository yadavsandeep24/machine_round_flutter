import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shared.dart';

class SelectionCubit extends Cubit<Set<int>> {
  SelectionCubit() : super(const {});

  void toggle(int id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    emit(next);
  }
}

/// FAST: move the changing state out of the page and let each row subscribe
/// to only ITS bit (`BlocSelector`). A tap now rebuilds one row and the
/// counter. Equivalents: `context.select`, a per-item `ValueNotifier` +
/// `ValueListenableBuilder`, Riverpod `select`.
class UsersSelectFixed extends StatelessWidget {
  const UsersSelectFixed({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SelectionCubit(),
    child: Column(
      children: [
        const Padding(padding: EdgeInsets.all(12), child: _Count()),
        Expanded(
          child: ListView.builder(
            itemCount: 500,
            itemExtent: 56,
            // Rows are const-constructible and never rebuilt by the parent.
            itemBuilder: (_, i) => _Row(key: ValueKey(i), index: i),
          ),
        ),
      ],
    ),
  );
}

class _Count extends StatelessWidget {
  const _Count();

  @override
  Widget build(BuildContext context) {
    final count = context.select((SelectionCubit c) => c.state.length);
    return Text('$count selected');
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SelectionCubit, Set<int>, bool>(
      selector: (s) => s.contains(index),
      builder: (context, selected) {
        countRowBuild(index);
        return ListTile(
          title: Text('User $index'),
          trailing: Icon(selected ? Icons.star : Icons.star_border),
          selected: selected,
          onTap: () => context.read<SelectionCubit>().toggle(index),
        );
      },
    );
  }
}
