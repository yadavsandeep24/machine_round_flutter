import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injector.dart';
import '../../../core/ui/widgets/state_views.dart';
import '../data/todo_remote.dart';
import '../domain/todo.dart';
import '../sync/connectivity.dart';
import 'todos_cubit.dart';

class TodosPage extends StatelessWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<TodosCubit>(), child: const TodosView());
}

class TodosView extends StatelessWidget {
  const TodosView({super.key, this.connectivity, this.remote});

  /// Demo controls (null in tests that do not need them).
  final ManualConnectivity? connectivity;
  final FakeTodoRemote? remote;

  @override
  Widget build(BuildContext context) {
    final conn = connectivity ?? (sl.isRegistered<Connectivity>() ? sl<Connectivity>() : null);
    final server = remote ?? (sl.isRegistered<TodoRemote>() ? sl<TodoRemote>() : null);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
        actions: [
          if (server is FakeTodoRemote) _ServerMenu(remote: server),
          if (conn is ManualConnectivity)
            BlocSelector<TodosCubit, TodosState, bool>(
              selector: (s) => s.isOnline,
              builder: (context, online) => Row(
                children: [
                  Text(online ? 'Online' : 'Offline'),
                  Switch(value: online, onChanged: conn.set),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const _StatusBanner(),
          const _AddField(),
          Expanded(
            child: BlocBuilder<TodosCubit, TodosState>(
              buildWhen: (a, b) => a.todos != b.todos,
              builder: (context, state) {
                if (state.todos.isEmpty) {
                  return const EmptyView(
                    message: 'Nothing to do',
                    icon: Icons.check_circle_outline,
                  );
                }
                return ListView.builder(
                  itemCount: state.todos.length,
                  itemBuilder: (context, i) {
                    final todo = state.todos[i];
                    return Dismissible(
                      key: ValueKey(todo.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => context.read<TodosCubit>().delete(todo.id),
                      background: Container(
                        color: Theme.of(context).colorScheme.errorContainer,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline),
                      ),
                      child: CheckboxListTile(
                        value: todo.done,
                        onChanged: (_) => context.read<TodosCubit>().toggle(todo.id),
                        title: Text(
                          todo.title,
                          style: todo.done
                              ? const TextStyle(decoration: TextDecoration.lineThrough)
                              : null,
                        ),
                        secondary: _SyncIcon(status: todo.syncStatus),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodosCubit, TodosState>(
      buildWhen: (a, b) => a.isOnline != b.isOnline || a.pendingCount != b.pendingCount,
      builder: (context, state) {
        if (state.isOnline && state.pendingCount == 0) return const SizedBox.shrink();
        final text = state.isOnline
            ? 'Syncing ${state.pendingCount} change(s)…'
            : 'Offline. ${state.pendingCount} change(s) will sync when you reconnect.';
        return MaterialBanner(
          content: Text(text),
          actions: [
            TextButton(
              onPressed: state.isOnline ? context.read<TodosCubit>().retry : null,
              child: const Text('Sync now'),
            ),
          ],
        );
      },
    );
  }
}

class _AddField extends StatefulWidget {
  const _AddField();

  @override
  State<_AddField> createState() => _AddFieldState();
}

class _AddFieldState extends State<_AddField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<TodosCubit>().add(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: TextField(
      controller: _controller,
      onSubmitted: (_) => _submit(),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'Add a todo',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(tooltip: 'Add', icon: const Icon(Icons.add), onPressed: _submit),
      ),
    ),
  );
}

class _SyncIcon extends StatelessWidget {
  const _SyncIcon({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    SyncStatus.synced => const Icon(Icons.cloud_done_outlined, semanticLabel: 'Synced'),
    SyncStatus.pending => const Icon(Icons.cloud_upload_outlined, semanticLabel: 'Pending'),
    SyncStatus.failed => Icon(
      Icons.error_outline,
      semanticLabel: 'Failed',
      color: Theme.of(context).colorScheme.error,
    ),
  };
}

/// Demo-only: break the fake server to show retries and backoff.
class _ServerMenu extends StatelessWidget {
  const _ServerMenu({required this.remote});

  final FakeTodoRemote remote;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Fake server',
    icon: const Icon(Icons.dns_outlined),
    onSelected: (value) {
      switch (value) {
        case 'down':
          remote.down = !remote.down;
        case 'fail':
          remote.failNext = 2;
        case 'drop':
          remote.dropNextResponse = true;
      }
    },
    itemBuilder: (_) => [
      CheckedPopupMenuItem(value: 'down', checked: remote.down, child: const Text('Server down')),
      const PopupMenuItem(value: 'fail', child: Text('Fail next 2 requests')),
      const PopupMenuItem(value: 'drop', child: Text('Lose next response')),
    ],
  );
}
