import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import '../../../core/error/app_exception.dart';
import '../../../core/network/safe_call.dart';
import '../data/todo_local_store.dart';
import '../data/todo_remote.dart';
import '../domain/outbox_op.dart';
import '../domain/todo.dart';
import 'connectivity.dart';

/// Drains the outbox in FIFO order whenever the device is online.
///
/// Guarantees:
/// - Order: ops for the same todo reach the server in the order they were made.
/// - At-least-once delivery + idempotent server calls = effectively once.
/// - An edit made while that todo's op is in flight is never lost: the
///   in-flight op is never rewritten; a new op is queued behind it.
/// - Transient failures stop the drain and retry with exponential backoff;
///   permanent failures (4xx) mark the todo as failed and drop the op.
class SyncEngine {
  SyncEngine({
    required TodoLocalStore local,
    required TodoRemote remote,
    required Connectivity connectivity,
    Duration Function(int attempt)? backoff,
  }) : _local = local,
       _remote = remote,
       _connectivity = connectivity,
       _backoff = backoff ?? _defaultBackoff {
    _connectivitySub = _connectivity.changes.listen((online) {
      if (online) unawaited(sync());
    });
  }

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: min(60, pow(2, attempt).toInt())); // 2, 4, 8 ... 60 s

  final TodoLocalStore _local;
  final TodoRemote _remote;
  final Connectivity _connectivity;
  final Duration Function(int attempt) _backoff;
  late final StreamSubscription<bool> _connectivitySub;

  Future<void>? _running;
  Timer? _retryTimer;
  String? _inFlightOpId;
  int _opCounter = 0;

  /// The op currently being sent, which must not be coalesced.
  String? get inFlightOpId => _inFlightOpId;

  /// Queues a change, merging it with an equivalent pending op when safe.
  Future<void> enqueue(String todoId, OpType type) async {
    final ops = [..._local.outbox];
    final pendingIndex = ops.lastIndexWhere((o) => o.todoId == todoId && o.opId != _inFlightOpId);
    final todo = _local.todo(todoId);

    if (pendingIndex >= 0) {
      final pending = ops[pendingIndex];
      if (type == OpType.upsert && pending.type == OpType.upsert) {
        // The upsert sends the latest local row anyway: nothing to add.
        return;
      }
      if (type == OpType.delete && pending.type == OpType.upsert) {
        ops.removeAt(pendingIndex);
        final inFlightForTodo = ops.any((o) => o.todoId == todoId && o.opId == _inFlightOpId);
        if (todo?.serverKnown != true && !inFlightForTodo) {
          // Created and deleted offline: the server never needs to know.
          await _local.setOutbox(ops);
          return;
        }
      }
    }
    ops.add(
      OutboxOp(
        opId: 'op-${DateTime.now().microsecondsSinceEpoch}-${_opCounter++}',
        todoId: todoId,
        type: type,
      ),
    );
    await _local.setOutbox(ops);
    unawaited(sync());
  }

  /// Safe to call any time: concurrent calls share one drain.
  Future<void> sync() => _running ??= _drain().whenComplete(() => _running = null);

  Future<void> _drain() async {
    _retryTimer?.cancel();
    while (_connectivity.isOnline && _local.outbox.isNotEmpty) {
      final op = _local.outbox.first;
      _inFlightOpId = op.opId;
      final todo = _local.todo(op.todoId);
      final result = await safeCall(() async {
        switch (op.type) {
          case OpType.upsert:
            if (todo != null) await _remote.upsert(todo);
          case OpType.delete:
            await _remote.delete(op.todoId);
        }
      });
      _inFlightOpId = null;

      final error = result.fold((_) => null, (e) => e);
      if (error == null) {
        await _onSuccess(op);
      } else if (_isPermanent(error)) {
        developer.log('Dropping op ${op.opId}: $error');
        await _local.setOutbox(_local.outbox.where((o) => o.opId != op.opId).toList());
        if (todo != null) await _local.putTodo(todo.copyWith(syncStatus: SyncStatus.failed));
      } else {
        final retried = op.retried();
        await _local.setOutbox([retried, ..._local.outbox.skip(1)]);
        _retryTimer = Timer(_backoff(retried.attempts), () => unawaited(sync()));
        return; // keep order: do not skip ahead past a failed op
      }
    }
  }

  Future<void> _onSuccess(OutboxOp op) async {
    final remaining = _local.outbox.where((o) => o.opId != op.opId).toList();
    await _local.setOutbox(remaining);
    final todo = _local.todo(op.todoId);
    if (todo == null) return;
    final stillPending = remaining.any((o) => o.todoId == op.todoId);
    await _local.putTodo(
      todo.copyWith(
        serverKnown: true,
        syncStatus: stillPending ? SyncStatus.pending : SyncStatus.synced,
      ),
    );
  }

  bool _isPermanent(AppException e) =>
      e is NotFoundException ||
      e is ParseException ||
      (e is ServerException && (e.statusCode ?? 500) < 500);

  Future<void> dispose() async {
    _retryTimer?.cancel();
    await _connectivitySub.cancel();
  }
}
