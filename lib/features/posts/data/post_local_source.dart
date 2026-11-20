import 'dart:async';
import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../domain/post.dart';

/// JSON cache on top of [KeyValueStore] that can be observed as a stream.
/// In a bigger app this would be a drift/sqflite table with a watch query.
class PostLocalSource {
  PostLocalSource(this._store);

  static const _key = 'posts_cache_v1';

  final KeyValueStore _store;
  final StreamController<List<Post>> _changes = StreamController.broadcast(sync: true);

  List<Post> read() {
    final raw = _store.getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on Object {
      return const []; // corrupt cache: treat as empty instead of crashing
    }
  }

  /// Emits the current cache immediately, then every change.
  Stream<List<Post>> watch() async* {
    yield read();
    yield* _changes.stream;
  }

  Future<void> replaceAll(List<Post> posts) async {
    await _store.setString(_key, jsonEncode(posts.map((p) => p.toJson()).toList()));
    _changes.add(List.unmodifiable(posts));
  }
}
