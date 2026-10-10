import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A bounded, account-scoped JSON snapshot stored on the device.
///
/// Use this for non-secret API response snapshots (repositories, activity and
/// contribution summaries), not OAuth tokens or large/unbounded histories.
/// The caller remains responsible for validating the decoded payload shape.
class LocalSnapshot {
  const LocalSnapshot({
    required this.payload,
    required this.cachedAt,
    required this.schemaVersion,
  });

  final Map<String, dynamic> payload;
  final DateTime cachedAt;
  final int schemaVersion;

  bool isStale({required Duration maxAge, DateTime? now}) {
    final current = now ?? DateTime.now();
    return current.difference(cachedAt) > maxAge;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'cachedAt': cachedAt.toUtc().toIso8601String(),
        'payload': payload,
      };

  static LocalSnapshot? fromJson(
    String? encoded, {
    required int expectedSchemaVersion,
  }) {
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['schemaVersion'] != expectedSchemaVersion) return null;
      final rawPayload = decoded['payload'];
      final rawCachedAt = decoded['cachedAt'];
      if (rawPayload is! Map<String, dynamic> || rawCachedAt is! String) {
        return null;
      }
      final cachedAt = DateTime.tryParse(rawCachedAt);
      if (cachedAt == null) return null;

      return LocalSnapshot(
        payload: rawPayload,
        cachedAt: cachedAt.toLocal(),
        schemaVersion: expectedSchemaVersion,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Small local cache for normalized, non-sensitive provider snapshots.
///
/// Keys are scoped by account and namespace to prevent data from one connected
/// account being shown for another. Credentials must never be passed here.
class LocalSnapshotStore {
  LocalSnapshotStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _prefix = 'local_snapshot_v1:';

  Future<LocalSnapshot?> read({
    required String accountId,
    required String namespace,
    required int schemaVersion,
  }) async {
    final key = _key(accountId, namespace);
    final encoded = _preferences.getString(key);
    final snapshot = LocalSnapshot.fromJson(
      encoded,
      expectedSchemaVersion: schemaVersion,
    );

    // Drop corrupt or incompatible entries so every subsequent read is clean.
    if (encoded != null && snapshot == null) {
      await _preferences.remove(key);
    }
    return snapshot;
  }

  Future<void> write({
    required String accountId,
    required String namespace,
    required Map<String, dynamic> payload,
    required int schemaVersion,
    DateTime? cachedAt,
  }) async {
    final snapshot = LocalSnapshot(
      payload: payload,
      cachedAt: cachedAt ?? DateTime.now(),
      schemaVersion: schemaVersion,
    );
    await _preferences.setString(
      _key(accountId, namespace),
      jsonEncode(snapshot.toJson()),
    );
  }

  Future<void> remove({
    required String accountId,
    required String namespace,
  }) =>
      _preferences.remove(_key(accountId, namespace));

  /// Clears only this account's snapshots, leaving other accounts and app
  /// preferences untouched. Call on explicit local-data deletion/disconnect.
  Future<void> clearAccount(String accountId) async {
    final prefix = _prefix + _encode(accountId) + ':';
    final keys = _preferences.getKeys()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _preferences.remove(key);
    }
  }

  String _key(String accountId, String namespace) =>
      _prefix + _encode(accountId) + ':' + _encode(namespace);

  String _encode(String value) =>
      base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}
