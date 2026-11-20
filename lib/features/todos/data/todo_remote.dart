import 'dart:async';

import '../../../core/error/app_exception.dart';
import '../domain/todo.dart';

/// The server contract. Both calls must be idempotent: the client may resend
/// an operation whose response was lost.
abstract interface class TodoRemote {
  /// PUT /todos/{id}: create or replace.
  Future<void> upsert(Todo todo);

  /// DELETE /todos/{id}: deleting a missing todo is a success.
  Future<void> delete(String id);
}

/// In-memory "server" for the demo and tests. Public mock APIs such as
/// dummyjson do not persist writes, so a real round would swap this for a
/// Dio implementation of [TodoRemote].
class FakeTodoRemote implements TodoRemote {
  FakeTodoRemote({this.latency = const Duration(milliseconds: 400)});

  Duration latency;
  final Map<String, Map<String, dynamic>> server = {};
  int requests = 0;

  /// Simulates a server outage (every call fails with a 503).
  bool down = false;

  /// Reject the next call with a 422 (validation error): permanent.
  bool rejectNext = false;

  /// Fail the next N calls with a network error.
  int failNext = 0;

  /// Apply the next call on the server but lose the response (timeout).
  bool dropNextResponse = false;

  /// Lets tests hold a request in flight.
  Completer<void>? gate;

  Future<void> _call(void Function() apply) async {
    requests++;
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    await gate?.future;
    if (down) throw const ServerException(503);
    if (rejectNext) {
      rejectNext = false;
      throw const ServerException(422);
    }
    if (failNext > 0) {
      failNext--;
      throw const NoInternetException();
    }
    apply();
    if (dropNextResponse) {
      dropNextResponse = false;
      throw const TimeoutAppException();
    }
  }

  @override
  Future<void> upsert(Todo todo) => _call(() => server[todo.id] = todo.toRemoteJson());

  @override
  Future<void> delete(String id) => _call(() => server.remove(id));
}
