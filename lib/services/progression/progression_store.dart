import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/domain.dart';

/// Persistence for the [ProgressionRecord] — the only progression state the
/// app stores.
///
/// Records are scoped by **account** (`<providerId>:<username>`), so signing in
/// as a different developer on the same device never shows one account's
/// achievements or quest history to another.
///
/// Only non-derivable facts are persisted (see [ProgressionRecord]); XP,
/// levels, streaks and metrics are always recomputed from provider data.
abstract class ProgressionStore {
  /// Loads [accountId]'s record, or an empty record when there is none.
  ProgressionRecord load(String accountId);

  /// Saves [accountId]'s record.
  Future<void> save(String accountId, ProgressionRecord record);

  /// Removes [accountId]'s record. Idempotent.
  Future<void> clear(String accountId);
}

/// Loads the SharedPreferences-backed store, falling back to in-memory storage
/// when preferences are unavailable.
///
/// Progression is a nice-to-have: a storage failure must never block launch.
Future<ProgressionStore> loadProgressionStore() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsProgressionStore(prefs);
  } catch (_) {
    return InMemoryProgressionStore();
  }
}

/// In-memory [ProgressionStore] for tests and non-persistent sessions.
class InMemoryProgressionStore implements ProgressionStore {
  final Map<String, ProgressionRecord> _records = {};

  @override
  ProgressionRecord load(String accountId) =>
      _records[accountId] ?? ProgressionRecord.empty;

  @override
  Future<void> save(String accountId, ProgressionRecord record) async {
    _records[accountId] = record;
  }

  @override
  Future<void> clear(String accountId) async {
    _records.remove(accountId);
  }
}

/// SharedPreferences-backed [ProgressionStore].
///
/// SECURITY: progression history is non-sensitive (achievement ids, quest
/// period keys, unlock timestamps). Credentials never live here — tokens stay
/// in [GitHubTokenStore] device-secure storage.
class SharedPrefsProgressionStore implements ProgressionStore {
  static const String _keyPrefix = 'progression_record_v1:';

  final SharedPreferences _prefs;
  final Map<String, ProgressionRecord> _cache = {};

  SharedPrefsProgressionStore(this._prefs);

  @override
  ProgressionRecord load(String accountId) {
    return _cache.putIfAbsent(
      accountId,
      () => ProgressionRecord.decode(_prefs.getString(_keyFor(accountId))),
    );
  }

  @override
  Future<void> save(String accountId, ProgressionRecord record) async {
    _cache[accountId] = record;
    await _prefs.setString(_keyFor(accountId), record.encode());
  }

  @override
  Future<void> clear(String accountId) async {
    _cache.remove(accountId);
    await _prefs.remove(_keyFor(accountId));
  }

  static String _keyFor(String accountId) => '$_keyPrefix$accountId';
}
