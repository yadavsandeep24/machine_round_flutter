import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/core/storage/key_value_store.dart';
import 'package:machine_round/features/todos/data/todo_local_store.dart';
import 'package:machine_round/features/todos/data/todo_remote.dart';
import 'package:machine_round/features/todos/data/todo_repository.dart';
import 'package:machine_round/features/todos/domain/todo.dart';
import 'package:machine_round/features/todos/sync/connectivity.dart';
import 'package:machine_round/features/todos/sync/sync_engine.dart';

class _Harness {
  _Harness({bool online = true, KeyValueStore? store})
    : store = store ?? InMemoryStore(),
      connectivity = ManualConnectivity(online: online),
      remote = FakeTodoRemote(latency: Duration.zero) {
    local = TodoLocalStore(this.store);
    engine = SyncEngine(
      local: local,
      remote: remote,
      connectivity: connectivity,
      backoff: (_) => const Duration(milliseconds: 10),
    );
    var t = 0;
    repo = TodoRepository(local, engine, clock: () => ++t);
  }

  final KeyValueStore store;
  final ManualConnectivity connectivity;
  final FakeTodoRemote remote;
  late final TodoLocalStore local;
  late final SyncEngine engine;
  late final TodoRepository repo;

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await engine.sync();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
}

void main() {
  test('offline changes stay local, then sync when back online', () async {
    final h = _Harness(online: false);
    final id = await h.repo.add('Buy milk');
    await h.settle();
    expect(h.remote.server, isEmpty);
    expect(h.local.todo(id)!.syncStatus, SyncStatus.pending);

    h.connectivity.set(true);
    await h.settle();
    expect(h.remote.server[id]!['title'], 'Buy milk');
    expect(h.local.todo(id)!.syncStatus, SyncStatus.synced);
    expect(h.local.outbox, isEmpty);
  });

  test('several offline edits to one todo coalesce into one request', () async {
    final h = _Harness(online: false);
    final id = await h.repo.add('a');
    await h.repo.rename(id, 'b');
    await h.repo.toggle(id);
    expect(h.local.outbox, hasLength(1));

    h.connectivity.set(true);
    await h.settle();
    expect(h.remote.requests, 1);
    expect(h.remote.server[id], containsPair('title', 'b'));
    expect(h.remote.server[id], containsPair('done', true));
  });

  test('created and deleted offline never reaches the server', () async {
    final h = _Harness(online: false);
    final id = await h.repo.add('temp');
    await h.repo.delete(id);
    expect(h.local.outbox, isEmpty);

    h.connectivity.set(true);
    await h.settle();
    expect(h.remote.requests, 0);
  });

  test('delete of a synced todo is sent to the server', () async {
    final h = _Harness();
    final id = await h.repo.add('x');
    await h.settle();
    await h.repo.delete(id);
    await h.settle();
    expect(h.remote.server, isEmpty);
  });

  test('transient failures keep the op and retry with backoff, in order', () async {
    final h = _Harness();
    h.remote.failNext = 2;
    final a = await h.repo.add('first');
    final b = await h.repo.add('second');
    await h.settle();
    expect(h.remote.server.keys, [a, b]);
    expect(h.local.outbox, isEmpty);
  });

  test('a lost response is replayed without creating a duplicate', () async {
    final h = _Harness();
    h.remote.dropNextResponse = true;
    final id = await h.repo.add('once');
    await h.settle();
    expect(h.remote.server, hasLength(1));
    expect(h.remote.server[id]!['title'], 'once');
    expect(h.local.todo(id)!.syncStatus, SyncStatus.synced);
  });

  test('an edit made while its op is in flight is not lost', () async {
    final h = _Harness();
    final gate = Completer<void>();
    h.remote.gate = gate;
    final id = await h.repo.add('v1'); // starts sending v1 and blocks
    await Future<void>.delayed(Duration.zero);
    await h.repo.rename(id, 'v2'); // must queue a new op, not merge into the in-flight one
    expect(h.local.outbox, hasLength(2));

    h.remote.gate = null;
    gate.complete();
    await h.settle();
    expect(h.remote.server[id]!['title'], 'v2');
    expect(h.local.todo(id)!.syncStatus, SyncStatus.synced);
  });

  test('a 503 is transient: op kept with attempts, synced after recovery', () async {
    final h = _Harness();
    h.remote.down = true; // 503 is transient
    final id = await h.repo.add('x');
    await h.settle();
    expect(h.local.outbox, hasLength(1));
    expect(h.local.outbox.first.attempts, greaterThan(0));
    h.remote.down = false;
    await h.settle();
    expect(h.local.todo(id)!.syncStatus, SyncStatus.synced);
  });

  test('a 4xx is permanent: todo marked failed, the queue keeps moving', () async {
    final h = _Harness();
    h.remote.rejectNext = true;
    final bad = await h.repo.add('rejected');
    final good = await h.repo.add('accepted');
    await h.settle();
    expect(h.local.todo(bad)!.syncStatus, SyncStatus.failed);
    expect(h.remote.server.keys, [good]);
    expect(h.local.outbox, isEmpty);
  });

  test('the outbox survives an app restart', () async {
    final store = InMemoryStore();
    final first = _Harness(online: false, store: store);
    final id = await first.repo.add('persisted');
    await first.engine.dispose();

    final second = _Harness(store: store); // relaunch, online
    await second.settle();
    expect(second.remote.server[id]!['title'], 'persisted');
  });
}
