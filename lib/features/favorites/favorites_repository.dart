import 'dart:async';
import 'dart:convert';

import '../../core/storage/key_value_store.dart';

abstract interface class FavoritesRepository {
  /// Emits the current ids immediately, then every change.
  Stream<Set<int>> watch();
  Future<void> toggle(int id);
}

class LocalFavoritesRepository implements FavoritesRepository {
  LocalFavoritesRepository(this._store);

  static const _key = 'favorite_ids_v1';
  final KeyValueStore _store;
  final _changes = StreamController<Set<int>>.broadcast(sync: true);

  Set<int> _read() {
    final raw = _store.getString(_key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<int>().toSet();
    } on Object {
      return {};
    }
  }

  @override
  Stream<Set<int>> watch() async* {
    yield _read();
    yield* _changes.stream;
  }

  @override
  Future<void> toggle(int id) async {
    final ids = _read();
    if (!ids.remove(id)) ids.add(id);
    await _store.setString(_key, jsonEncode(ids.toList()));
    _changes.add(Set.unmodifiable(ids));
  }
}
