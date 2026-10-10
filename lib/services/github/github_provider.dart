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
  Future<bool> isConnected() => _tokenStore.hasToken();

  // ---------------------------------------------------------------------------
  // Connection lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<ConnectionResult> connect({
    void Function(ConnectionPrompt prompt)? onPrompt,
  }) async {
    _authorizationCancelled = false;

    // Step 1: request a device + user code.
    final start = await _deviceFlow.start();
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
      if (_authorizationCancelled) {
        throw const AuthenticationFailed(detail: 'Authorization cancelled.');
      }
      if (DateTime.now().isAfter(start.expiresAt)) {
        throw const AuthenticationFailed(
          detail: 'The device code expired. Please try again.',
        );
      }
      token = await _deviceFlow.poll(start: start);
      if (token == null) {
        await Future<void>.delayed(interval);
      }
    }

    // Step 3: store the token securely + link to Firebase (best effort).
    await _tokenStore.write(token.accessToken);
    _accessToken = token.accessToken;

    final profile = await fetchProfile();
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

    final store = await _connectionStoreFactory();
    await store.save(
      ProviderConnectionRecord.connected(
        providerId: providerId,
        account: account,
      ),
    );

    return ConnectionResult(account: account, profile: profile);
  }

  @override
  void cancelAuthorization() {
    _authorizationCancelled = true;
  }

  @override
  Future<void> disconnect() async {
    _accessToken = '';
    _authorizationCancelled = false;
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
    final json = await _apiClient.getJson(
      '/user/events/public',
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
