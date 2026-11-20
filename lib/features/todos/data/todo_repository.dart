import 'dart:math';

import '../domain/outbox_op.dart';
import '../domain/todo.dart';
import '../sync/sync_engine.dart';
import 'todo_local_store.dart';

/// Local-first: every action writes locally (instant UI), then queues the
/// change for the server. The UI never waits for the network.
class TodoRepository {
  TodoRepository(this._local, this._sync, {int Function()? clock})
    : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  final TodoLocalStore _local;
  final SyncEngine _sync;
  final int Function() _clock;
  final _random = Random();

  Stream<List<Todo>> watch() => _local.watch();

  int get pendingCount => _local.outbox.length;

  Future<String> add(String title) async {
    final id = '${_clock()}-${_random.nextInt(1 << 32).toRadixString(16)}';
    await _local.putTodo(Todo(id: id, title: title.trim(), updatedAt: _clock()));
    await _sync.enqueue(id, OpType.upsert);
    return id;
  }

  Future<void> toggle(String id) => _edit(id, (t) => t.copyWith(done: !t.done));

  Future<void> rename(String id, String title) => _edit(id, (t) => t.copyWith(title: title.trim()));

  Future<void> delete(String id) async {
    await _local.removeTodo(id);
    await _sync.enqueue(id, OpType.delete);
  }

  Future<void> retryNow() => _sync.sync();

  Future<void> _edit(String id, Todo Function(Todo) change) async {
    final todo = _local.todo(id);
    if (todo == null) return;
    await _local.putTodo(
      change(todo).copyWith(updatedAt: _clock(), syncStatus: SyncStatus.pending),
    );
    await _sync.enqueue(id, OpType.upsert);
  }
}
