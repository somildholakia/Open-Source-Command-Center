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
    try {
      return await _storage.containsKey(key: _key);
    } catch (_) {
      return _memoryFallback != null;
    }
  }

  /// Reads the token, or an empty string when absent/unavailable.
  Future<String> read() async {
    try {
      return await _storage.read(key: _key) ?? '';
    } catch (_) {
      return _memoryFallback ?? '';
    }
  }

  /// Writes the token to secure storage.
  Future<void> write(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {
      _memoryFallback = token;
    }
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
