import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the provider access token in device-secure storage
/// (Android Keystore / EncryptedSharedPreferences, iOS Keychain).
///
/// SECURITY:
/// - Tokens are NEVER written to SharedPreferences, logs, or source code.
/// - [read] returns an empty string when no token exists — callers treat
///   that as "not connected".
///
/// The token is injected (rather than read internally) so tests can run
/// without the platform channel.
class GitHubTokenStore {
  static const String _key = 'github_oauth_access_token';
  static const String _disconnectPendingKey = 'github_disconnect_pending';

  final FlutterSecureStorage _storage;

  GitHubTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// Whether a usable token exists in secure storage.
  ///
  /// A token is not usable while disconnect cleanup is pending, even if a
  /// failed deletion left its value behind. Keep this consistent with [read].
  Future<bool> hasToken() async {
    final disconnectPending = await _storage.read(key: _disconnectPendingKey);
    if (disconnectPending == 'true') return false;
    return await _storage.containsKey(key: _key);
  }

  /// Reads the token, or an empty string when absent.
  ///
  /// Storage errors are propagated so callers can distinguish an unavailable
  /// secure store from a genuinely disconnected account.
  Future<String> read() async {
    // A tombstone prevents a credential that could not be deleted from being
    // restored and used on a later launch or by a different app session.
    final disconnectPending = await _storage.read(key: _disconnectPendingKey);
    if (disconnectPending == 'true') return '';
    return await _storage.read(key: _key) ?? '';
  }

  /// Writes the token to secure storage.
  ///
  /// Do not fall back to process memory when persistence fails: the connection
  /// would appear successful but disappear on restart. Tests should inject a
  /// mock store rather than relying on a non-persistent credential fallback.
  Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    await _storage.delete(key: _disconnectPendingKey);
  }

  /// Removes the token.
  ///
  /// Deletion failures propagate so callers never claim the account is fully
  /// disconnected while the credential may still be present on the device.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
      await _storage.delete(key: _disconnectPendingKey);
    } catch (_) {
      // Best-effort tombstone: even if token deletion fails, prevent the app
      // from restoring the saved token until the user retries cleanup.
      try {
        await _storage.write(key: _disconnectPendingKey, value: 'true');
      } catch (_) {
        // Secure storage may be completely unavailable.
      }
      rethrow;
    }
  }
}
