import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/domain.dart';
import '../connection/connection_store.dart';
import 'github_api_client.dart';
import 'github_device_flow.dart';
import 'github_firebase_link.dart';
import 'github_mappers.dart';
import 'github_token_store.dart';

/// GitHub implementation of [DeveloperProvider].
///
/// Authorization: GitHub **Device Authorization Flow** (no client secret is
/// ever embedded client-side). The resulting OAuth token is stored only in
/// device-secure storage and linked to the app's Firebase account when
/// Firebase is configured (link failures degrade gracefully — see
/// [GitHubFirebaseLinker]).
///
/// All GitHub-specific payloads are mapped to domain entities inside this
/// package; UI layers consume normalized models only.
class GitHubProvider implements DeveloperProvider {
  /// Lazily-created shared-prefs-based connection store.
  static Future<ConnectionStore> defaultConnectionStoreFactory() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsConnectionStore(prefs);
  }

  final GitHubDeviceFlowClient _deviceFlow;
  final GitHubTokenStore _tokenStore;
  final GitHubFirebaseLinker _firebaseLinker;
  final Future<ConnectionStore> Function() _connectionStoreFactory;

  /// In-memory mirror of the token for synchronous header injection.
  String _accessToken = '';

  /// Set when the user cancels an in-flight authorization.
  bool _authorizationCancelled = false;

  /// Invalidates asynchronous authorization work after cancel/disconnect.
  int _authorizationGeneration = 0;

  /// [httpClient] is shared by the device-flow client and the API client and
  /// is injectable so the whole flow can be exercised without a network.
  GitHubProvider({
    GitHubDeviceFlowClient? deviceFlowClient,
    GitHubTokenStore? tokenStore,
    GitHubFirebaseLinker? firebaseLinker,
    Future<ConnectionStore> Function()? connectionStoreFactory,
    http.Client? httpClient,
  }) : _deviceFlow =
           deviceFlowClient ?? GitHubDeviceFlowClient(client: httpClient),
       _tokenStore = tokenStore ?? GitHubTokenStore(),
       _firebaseLinker = firebaseLinker ?? const FirebaseGitHubLinker(),
       _connectionStoreFactory =
           connectionStoreFactory ?? defaultConnectionStoreFactory {
    _apiClient = GitHubApiClient(
      tokenProvider: () => _accessToken,
      client: httpClient,
    );
  }

  late final GitHubApiClient _apiClient;

  @override
  String get providerId => 'github';

  @override
  String get displayName => 'GitHub';

  @override
  Future<bool> isConnected() async {
    // Secure storage survives app restarts, but the API client injects the
    // in-memory mirror. Hydrate it before any restored-session requests.
    final token = await _tokenStore.read();
    _accessToken = token;
    return token.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Connection lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<ConnectionResult> connect({
    void Function(ConnectionPrompt prompt)? onPrompt,
  }) async {
    _authorizationCancelled = false;
    final generation = ++_authorizationGeneration;

    // Step 1: request a device + user code.
    final start = await _deviceFlow.start();
    _ensureAuthorizationCurrent(generation);
    onPrompt?.call(
      ConnectionPrompt(
        instructions:
            'Enter this code on GitHub to authorize ${'the Command Center'}.',
        userCode: start.userCode,
        verificationUrl: start.verificationUrl,
        expiresAt: start.expiresAt,
      ),
    );

    // Step 2: poll until the user approves (or the code expires/cancels).
    var interval = Duration(seconds: start.intervalSeconds);
    DeviceFlowToken? token;
    while (token == null) {
      _ensureAuthorizationCurrent(generation);
      if (_authorizationCancelled) {
        throw const AuthenticationFailed(detail: 'Authorization cancelled.');
      }
      if (DateTime.now().isAfter(start.expiresAt)) {
        throw const AuthenticationFailed(
          detail: 'The device code expired. Please try again.',
        );
      }
      token = await _deviceFlow.poll(
        start: start,
        onSlowDown: () {
          // GitHub requires at least five extra seconds after slow_down.
          interval += const Duration(seconds: 5);
        },
      );
      // Cancellation may arrive while the network poll is in flight. Never
      // accept a token from a poll that outlived the authorization request.
      _ensureAuthorizationCurrent(generation);
      if (token == null) {
        await Future<void>.delayed(interval);
      }
    }

    // Step 3: store the token securely + link to Firebase (best effort).
    await _tokenStore.write(token.accessToken);
    await _ensureAuthorizationCurrentAfterStorage(generation);
    _accessToken = token.accessToken;

    final profile = await fetchProfile();
    await _ensureAuthorizationCurrentAfterStorage(generation);
    final account = ConnectedAccount(
      providerId: providerId,
      username: profile.username,
      avatarUrl: profile.avatarUrl,
      profileUrl: profile.profileUrl,
      connectedAt: DateTime.now(),
    );

    // Non-fatal: Firebase linking requires provider configuration in the
    // Firebase Console. Token-only connection remains fully functional.
    await _firebaseLinker.linkWithGitHubToken(token.accessToken);
    await _ensureAuthorizationCurrentAfterStorage(generation);

    final store = await _connectionStoreFactory();
    await _ensureAuthorizationCurrentAfterStorage(generation);
    await store.save(
      ProviderConnectionRecord.connected(
        providerId: providerId,
        account: account,
      ),
    );
    await _ensureAuthorizationCurrentAfterStorage(generation);

    return ConnectionResult(account: account, profile: profile);
  }

  @override
  void cancelAuthorization() {
    _authorizationCancelled = true;
    _authorizationGeneration++;
  }

  bool _isAuthorizationCurrent(int generation) =>
      generation == _authorizationGeneration && !_authorizationCancelled;

  void _ensureAuthorizationCurrent(int generation) {
    if (!_isAuthorizationCurrent(generation)) {
      throw const AuthenticationFailed(detail: 'Authorization cancelled.');
    }
  }

  /// Reconciles side effects if cancellation arrives after token persistence.
  ///
  /// A pending profile/link/store operation may complete after disconnect has
  /// already cleared local state. Clear those late side effects before the
  /// cancelled connection attempt returns to its caller.
  Future<void> _ensureAuthorizationCurrentAfterStorage(
    int generation,
  ) async {
    if (_isAuthorizationCurrent(generation)) return;

    if (_authorizationCancelled) {
      _accessToken = '';
      await _tokenStore.clear();
      try {
        final store = await _connectionStoreFactory();
        await store.clear();
      } catch (_) {}
      try {
        await _firebaseLinker.unlinkGitHub();
      } catch (_) {}
    }

    throw const AuthenticationFailed(detail: 'Authorization cancelled.');
  }

  @override
  Future<void> disconnect() async {
    // Keep cancellation asserted until the next connect begins. Resetting this
    // flag here could allow a pending poll to resume after a disconnect.
    _authorizationCancelled = true;
    _authorizationGeneration++;
    _accessToken = '';
    await _tokenStore.clear();
    try {
      final store = await _connectionStoreFactory();
      await store.clear();
    } catch (_) {
      // Store unavailable (e.g. test host) — token already cleared.
    }
    await _firebaseLinker.unlinkGitHub();
  }

  // ---------------------------------------------------------------------------
  // Data capabilities
  // ---------------------------------------------------------------------------

  @override
  Future<DeveloperProfile> fetchProfile() async {
    final json = await _apiClient.getJson('/user');
    if (json is! Map<String, dynamic>) throw const ApiUnavailable();
    return GitHubMappers.profileFromJson(json);
  }

  @override
  Future<List<Repository>> fetchRepositories() async {
    final json = await _apiClient.getJson(
      '/user/repos',
      queryParameters: {'type': 'owner', 'sort': 'updated', 'per_page': '30'},
    );
    if (json is! List) throw const ApiUnavailable();
    return GitHubMappers.repositoriesFromJson(json);
  }

  @override
  Future<List<DeveloperActivity>> fetchActivity({int limit = 30}) async {
    // GitHub's public user-events endpoint is username-scoped:
    // GET /users/{username}/events/public. The connection record is local, so
    // this avoids an extra profile request on the normal connected path.
    final store = await _connectionStoreFactory();
    final storedUsername = store.load()?.account?.username;
    final username = storedUsername?.isNotEmpty == true
        ? storedUsername!
        : (await fetchProfile()).username;
    if (username.isEmpty) throw const ApiUnavailable();

    final json = await _apiClient.getJson(
      '/users/${Uri.encodeComponent(username)}/events/public',
      queryParameters: {'per_page': '$limit'},
    );
    if (json is! List) throw const ApiUnavailable();
    return GitHubMappers.activitiesFromJson(json);
  }

  @override
  Future<ContributionSummary> fetchContributions() async {
    const query = '''
query {
  viewer {
    contributionsCollection {
      contributionCalendar {
        totalContributions
        weeks {
          contributionDays {
            date
            contributionCount
          }
        }
      }
    }
  }
}''';
    final data = await _apiClient.postGraphQL(query);
    final viewer = data is Map<String, dynamic> ? data['viewer'] : null;
    final collection = viewer is Map<String, dynamic>
        ? viewer['contributionsCollection']
        : null;
    final calendar = collection is Map<String, dynamic>
        ? collection['contributionCalendar']
        : null;
    if (calendar is! Map<String, dynamic>) throw const ApiUnavailable();
    return GitHubMappers.contributionSummaryFromGraphQL(calendar);
  }
}
