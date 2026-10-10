/// GitHub integration configuration.
///
/// SECURITY: only the OAuth **client id** is embedded in the client — it is a
/// public identifier, not a secret. No client secret, token, or key ever
/// lives in this repository or in the compiled app. See
/// `docs/GITHUB_SETUP.md` for the required external configuration.
class GitHubConfig {
  GitHubConfig._();

  /// OAuth app / Firebase GitHub provider **client id** (public value).
  ///
  /// Supplied at build time:
  /// ```
  /// flutter run --dart-define=GITHUB_OAUTH_CLIENT_ID=your_oauth_app_client_id
  /// ```
  static const String clientId = String.fromEnvironment(
    'GITHUB_OAUTH_CLIENT_ID',
  );

  /// OAuth scopes requested during authorization.
  ///
  /// Minimum required for this phase:
  /// - `read:user` — read public profile data
  ///
  /// Public events and the public contribution calendar are readable with
  /// this scope. Private-repo scopes are intentionally NOT requested.
  static const List<String> scopes = ['read:user'];

  /// Whether a client id has been provided for this build.
  static bool get hasClientId => clientId.isNotEmpty;

  /// True when running in an environment where the device-flow is usable
  /// (needs a browser capable of opening the verification URL).
  static bool get supportsDeviceFlow => hasClientId;
}
