import 'connection_prompt.dart';
import '../entities/entities.dart';

/// Result of a connect attempt: the account plus the normalized profile.
class ConnectionResult {
  final ConnectedAccount account;
  final DeveloperProfile profile;

  const ConnectionResult({required this.account, required this.profile});
}

/// Capability interface for developer platforms (GitHub now; GitLab,
/// Bitbucket, Jira, Linear later).
///
/// Implementations own provider-specific authentication, API communication,
/// and response mapping. UI and feature layers depend on this interface only
/// — they must never see provider-specific payloads or tokens.
///
/// Contract:
/// - Methods throw [ProviderFailure] subtypes (domain/errors) on failure.
/// - [isConnected] must be cheap and must not perform network I/O.
abstract interface class DeveloperProvider {
  /// Stable provider identifier, e.g. `github`.
  String get providerId;

  /// Human-readable provider name, e.g. `GitHub`.
  String get displayName;

  /// Whether a usable connection (e.g. stored access token) exists locally.
  ///
  /// Cheap check only: does NOT validate the token against the network.
  Future<bool> isConnected();

  /// Starts the authorization flow for this provider.
  ///
  /// Flows that need user action outside the app (device codes, browser
  /// redirects) report intermediate steps through [onPrompt]. The app may
  /// abort the flow with [cancelAuthorization], after which [connect]
  /// completes with an [AuthenticationFailed] whose detail says so.
  Future<ConnectionResult> connect({
    void Function(ConnectionPrompt prompt)? onPrompt,
  });

  /// Aborts an in-flight [connect] at the next opportunity. Idempotent.
  void cancelAuthorization();

  /// Removes the stored connection (token + record). Idempotent.
  Future<void> disconnect();

  /// The connected developer's normalized profile.
  Future<DeveloperProfile> fetchProfile();

  /// The connected developer's repositories, most recently updated first.
  Future<List<Repository>> fetchRepositories();

  /// Recent activity events, newest first, capped at [limit].
  Future<List<DeveloperActivity>> fetchActivity({int limit});

  /// Contribution counts per day over the past year (or best available).
  Future<ContributionSummary> fetchContributions();
}
