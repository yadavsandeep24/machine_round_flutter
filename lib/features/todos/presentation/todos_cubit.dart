import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../sync/connectivity.dart';

class TodosState extends Equatable {
  const TodosState({this.todos = const [], this.isOnline = true, this.pendingCount = 0});

  final List<Todo> todos;
  final bool isOnline;
  final int pendingCount;

  TodosState copyWith({List<Todo>? todos, bool? isOnline, int? pendingCount}) => TodosState(
    todos: todos ?? this.todos,
    isOnline: isOnline ?? this.isOnline,
    pendingCount: pendingCount ?? this.pendingCount,
  );

  @override
  List<Object?> get props => [todos, isOnline, pendingCount];
}

class TodosCubit extends Cubit<TodosState> {
  TodosCubit(this._repository, this._connectivity)
    : super(TodosState(isOnline: _connectivity.isOnline)) {
    _todosSub = _repository.watch().listen(
      (todos) => emit(state.copyWith(todos: todos, pendingCount: _repository.pendingCount)),
    );
    _onlineSub = _connectivity.changes.listen((online) => emit(state.copyWith(isOnline: online)));
  }

  final TodoRepository _repository;
  final Connectivity _connectivity;
  late final StreamSubscription<List<Todo>> _todosSub;
  late final StreamSubscription<bool> _onlineSub;

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    await _repository.add(title);
  }

  Future<void> toggle(String id) => _repository.toggle(id);
  Future<void> delete(String id) => _repository.delete(id);
  Future<void> retry() => _repository.retryNow();

  @override
  Future<void> close() async {
    await _todosSub.cancel();
    await _onlineSub.cancel();
    return super.close();
  }
}
