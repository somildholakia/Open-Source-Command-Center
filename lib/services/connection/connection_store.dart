import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/domain.dart';

/// Persistence for the connected-provider record (never tokens).
abstract class ConnectionStore {
  /// Loads the stored record, or null when never connected.
  ProviderConnectionRecord? load();

  /// Saves the record.
  Future<void> save(ProviderConnectionRecord record);

  /// Removes the record. Idempotent.
  Future<void> clear();
}

/// SharedPreferences-backed [ConnectionStore].
///
/// SECURITY: stores only non-sensitive connection metadata (provider id,
/// username, avatar, timestamps). Access tokens live in
/// [GitHubTokenStore] (device-secure storage), never here.
class SharedPrefsConnectionStore implements ConnectionStore {
  static const String _key = 'provider_connection_record';

  final SharedPreferences _prefs;

  SharedPrefsConnectionStore(this._prefs);

  @override
  ProviderConnectionRecord? load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return _decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt record: treat as disconnected rather than crashing.
      return null;
    }
  }

  @override
  Future<void> save(ProviderConnectionRecord record) async {
    await _prefs.setString(_key, jsonEncode(_encode(record)));
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  Map<String, dynamic> _encode(ProviderConnectionRecord record) {
    return {
      'providerId': record.providerId,
      'connectedAt': record.connectedAt?.toIso8601String(),
      'lastSyncedAt': record.lastSyncedAt?.toIso8601String(),
      if (record.account != null)
        'account': {
          'providerId': record.account!.providerId,
          'username': record.account!.username,
          'avatarUrl': record.account!.avatarUrl,
          'profileUrl': record.account!.profileUrl,
          'connectedAt': record.account!.connectedAt?.toIso8601String(),
        },
    };
  }

  ProviderConnectionRecord _decode(Map<String, dynamic> json) {
    ConnectedAccount? account;
    final accountJson = json['account'];
    if (accountJson is Map<String, dynamic>) {
      account = ConnectedAccount(
        providerId: accountJson['providerId'] as String? ?? '',
        username: accountJson['username'] as String? ?? '',
        avatarUrl: accountJson['avatarUrl'] as String? ?? '',
        profileUrl: accountJson['profileUrl'] as String? ?? '',
        connectedAt: _parseDate(accountJson['connectedAt'] as String?),
      );
    }
    return ProviderConnectionRecord(
      providerId: json['providerId'] as String? ?? '',
      account: account,
      connectedAt: _parseDate(json['connectedAt'] as String?),
      lastSyncedAt: _parseDate(json['lastSyncedAt'] as String?),
    );
  }

  DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
