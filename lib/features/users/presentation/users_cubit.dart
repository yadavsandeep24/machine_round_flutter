import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/result/result.dart';
import '../../../core/ui/view_status.dart';
import '../domain/user.dart';
import '../domain/user_repository.dart';

class UsersState extends Equatable {
  UsersState({
    this.status = ViewStatus.initial,
    this.users = const [],
    this.query = '',
    this.likedIds = const {},
    this.error,
  }) : visible = _filter(users, query);

  final ViewStatus status;
  final List<User> users;
  final String query;
  final Set<int> likedIds;
  final AppException? error;

  /// Computed once per state, not on every build.
  final List<User> visible;

  static List<User> _filter(List<User> users, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where((u) => u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList(growable: false);
  }

  UsersState copyWith({
    ViewStatus? status,
    List<User>? users,
    String? query,
    Set<int>? likedIds,
    AppException? Function()? error,
  }) => UsersState(
    status: status ?? this.status,
    users: users ?? this.users,
    query: query ?? this.query,
    likedIds: likedIds ?? this.likedIds,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, users, query, likedIds, error];
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repository) : super(UsersState());

  final UserRepository _repository;

  Future<void> load() async {
    if (state.status.isLoading) return; // ignore double taps on Retry
    emit(state.copyWith(status: ViewStatus.loading, error: () => null));
    final result = await _repository.getUsers();
    if (isClosed) return;
    emit(switch (result) {
      Success(:final data) => state.copyWith(status: ViewStatus.success, users: data),
      Failure(:final error) => state.copyWith(status: ViewStatus.failure, error: () => error),
    });
  }

  /// Local filter: no network, so no debounce needed for 100 items.
  void search(String query) => emit(state.copyWith(query: query));

  void toggleLike(int id) {
    final next = {...state.likedIds};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(likedIds: next));
  }
}
