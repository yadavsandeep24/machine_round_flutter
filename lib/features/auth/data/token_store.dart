import 'dart:convert';

import '../../../core/storage/key_value_store.dart';
import '../domain/auth_models.dart';

/// Keeps the session between launches. Production: use flutter_secure_storage
/// (Keychain / Android Keystore) instead of SharedPreferences for tokens.
class TokenStore {
  TokenStore(this._store) : _cached = _read(_store);

  static const _key = 'session_v1';
  final KeyValueStore _store;
  Session? _cached;

  static Session? _read(KeyValueStore store) {
    final raw = store.getString(_key);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// In memory after the first read: the interceptor calls this per request.
  Session? get session => _cached;

  Future<void> save(Session session) async {
    _cached = session;
    await _store.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _store.remove(_key);
  }
}
