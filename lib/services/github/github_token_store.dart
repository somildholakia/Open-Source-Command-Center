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

  final FlutterSecureStorage _storage;

  /// In-memory fallback used when secure storage is unavailable (e.g. widget
  /// tests on the host). Tokens never leave the process in this mode.
  String? _memoryFallback;

  GitHubTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// Whether a token exists in secure storage.
  Future<bool> hasToken() async {
    return await _storage.containsKey(key: _key);
  }

  /// Reads the token, or an empty string when absent.
  ///
  /// Storage errors are propagated so callers can distinguish an unavailable
  /// secure store from a genuinely disconnected account.
  Future<String> read() async {
    return await _storage.read(key: _key) ?? '';
  }

  /// Writes the token to secure storage.
  ///
  /// Do not fall back to process memory when persistence fails: the connection
  /// would appear successful but disappear on restart. Tests should inject a
  /// mock store rather than relying on a non-persistent credential fallback.
  Future<void> write(String token) async {
    await _storage.write(key: _key, value: token);
    _memoryFallback = null;
  }

  /// Removes the token. Idempotent.
  Future<void> clear() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Nothing to clear.
    }
  }
}
