import 'dart:async';
import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../domain/outbox_op.dart';
import '../domain/todo.dart';

/// Todos and the outbox in one store. With sqflite/drift, write both in one
/// transaction so a todo change and its outbox entry can never diverge.
class TodoLocalStore {
  TodoLocalStore(this._store) {
    _todos = {for (final t in _decode(_todosKey, Todo.fromJson)) t.id: t};
    _outbox = _decode(_outboxKey, OutboxOp.fromJson);
  }

  static const _todosKey = 'todos_v1';
  static const _outboxKey = 'todo_outbox_v1';

  final KeyValueStore _store;
  late Map<String, Todo> _todos;
  late List<OutboxOp> _outbox;
  final _changes = StreamController<List<Todo>>.broadcast(sync: true);

  List<T> _decode<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final raw = _store.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object {
      return [];
    }
  }

  List<Todo> get todos {
    final list = _todos.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(list);
  }

  Todo? todo(String id) => _todos[id];

  List<OutboxOp> get outbox => List.unmodifiable(_outbox);

  Stream<List<Todo>> watch() async* {
    yield todos;
    yield* _changes.stream;
  }

  Future<void> putTodo(Todo todo) async {
    _todos[todo.id] = todo;
    await _persistTodos();
  }

  Future<void> removeTodo(String id) async {
    _todos.remove(id);
    await _persistTodos();
  }

  Future<void> setOutbox(List<OutboxOp> ops) async {
    _outbox = [...ops];
    await _store.setString(_outboxKey, jsonEncode(_outbox.map((o) => o.toJson()).toList()));
  }

  Future<void> _persistTodos() async {
    await _store.setString(_todosKey, jsonEncode(_todos.values.map((t) => t.toJson()).toList()));
    _changes.add(todos);
  }
}
