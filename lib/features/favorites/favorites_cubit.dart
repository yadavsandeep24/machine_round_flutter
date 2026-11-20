import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'favorites_repository.dart';

/// App-wide state shared by the list, search results and detail screens.
/// Provided once above the router, so every screen sees the same instance.
class FavoritesCubit extends Cubit<Set<int>> {
  FavoritesCubit(this._repository) : super(const {}) {
    _subscription = _repository.watch().listen(emit);
  }

  final FavoritesRepository _repository;
  late final StreamSubscription<Set<int>> _subscription;

  bool isFavorite(int id) => state.contains(id);

  Future<void> toggle(int id) {
    // Optimistic: flip immediately, the stream confirms right after.
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    emit(next);
    return _repository.toggle(id);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
