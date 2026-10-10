import 'package:opensource_command_center/domain/domain.dart';

/// In-memory [DeveloperProvider] for tests.
///
/// All capabilities return configurable data (or throw a configured
/// [ProviderFailure]); it records calls so tests can assert on
/// duplicate-request prevention and cancellation.
class FakeDeveloperProvider implements DeveloperProvider {
  FakeDeveloperProvider({
    this.providerId = 'github',
    this.displayName = 'GitHub',
    this.connected = false,
    this.profile,
    List<Repository>? repositories,
    List<DeveloperActivity>? activities,
    this.contributions,
    this.connectFailure,
    this.dataFailure,
  }) : repositories = repositories ?? const [],
       activities = activities ?? const [];

  @override
  final String providerId;

  @override
  final String displayName;

  /// Whether the fake reports a stored connection.
  bool connected;

  DeveloperProfile? profile;
  List<Repository> repositories;
  List<DeveloperActivity> activities;
  ContributionSummary? contributions;

  /// When set, [connect] throws this instead of succeeding.
  ProviderFailure? connectFailure;

  /// When set, data capabilities throw this instead of returning data.
  ProviderFailure? dataFailure;

  /// When set, [connect] awaits this before returning (test-controlled).
  Future<void> Function()? onConnect;

  /// When set, every data capability awaits this first (test-controlled).
  Future<void> Function()? onFetch;

  // Call accounting.
  int connectCalls = 0;
  int disconnectCalls = 0;
  int fetchProfileCalls = 0;
  int fetchRepositoriesCalls = 0;
  int fetchActivityCalls = 0;
  int fetchContributionsCalls = 0;
  int cancelAuthorizationCalls = 0;

  /// Last prompt emitted during [connect], if any.
  ConnectionPrompt? lastPrompt;

  bool get isMarkedConnected => connected;

  @override
  Future<bool> isConnected() async => connected;

  @override
  Future<ConnectionResult> connect({
    void Function(ConnectionPrompt prompt)? onPrompt,
  }) async {
    connectCalls++;

    // Mirror the real flow: the user-facing prompt is emitted first, then the
    // provider waits for the user to authorize (test-controlled delay).
    lastPrompt = ConnectionPrompt(
      instructions: 'Enter this code on GitHub.',
      userCode: 'ABCD-1234',
      verificationUrl: 'https://github.com/login/device',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    onPrompt?.call(lastPrompt!);

    if (onConnect != null) {
      await onConnect!();
    }
    final failure = connectFailure;
    if (failure != null) throw failure;

    connected = true;
    return ConnectionResult(
      account: ConnectedAccount(
        providerId: providerId,
        username: profile?.username ?? 'octocat',
        avatarUrl: profile?.avatarUrl ?? '',
        profileUrl: profile?.profileUrl ?? '',
        connectedAt: DateTime.now(),
      ),
      profile: profile ?? sampleProfile(),
    );
  }

  @override
  void cancelAuthorization() {
    cancelAuthorizationCalls++;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
    connected = false;
  }

  @override
  Future<DeveloperProfile> fetchProfile() async {
    fetchProfileCalls++;
    if (onFetch != null) await onFetch!();
    final failure = dataFailure;
    if (failure != null) throw failure;
    return profile ?? sampleProfile();
  }

  @override
  Future<List<Repository>> fetchRepositories() async {
    fetchRepositoriesCalls++;
    if (onFetch != null) await onFetch!();
    final failure = dataFailure;
    if (failure != null) throw failure;
    return repositories;
  }

  @override
  Future<List<DeveloperActivity>> fetchActivity({int limit = 30}) async {
    fetchActivityCalls++;
    if (onFetch != null) await onFetch!();
    final failure = dataFailure;
    if (failure != null) throw failure;
    return activities;
  }

  @override
  Future<ContributionSummary> fetchContributions() async {
    fetchContributionsCalls++;
    if (onFetch != null) await onFetch!();
    final failure = dataFailure;
    if (failure != null) throw failure;
    return contributions ??
        ContributionSummary(dailyCounts: const {}, fetchedAt: DateTime.now());
  }
}

/// A minimal valid profile for tests.
DeveloperProfile sampleProfile({
  String username = 'octocat',
  String displayName = 'The Octocat',
  int publicRepositoryCount = 8,
  int followersCount = 120,
}) {
  return DeveloperProfile(
    id: '1',
    username: username,
    displayName: displayName,
    avatarUrl: 'https://avatars.githubusercontent.com/u/1?v=4',
    profileUrl: 'https://github.com/$username',
    bio: 'Test developer',
    publicRepositoryCount: publicRepositoryCount,
    followersCount: followersCount,
    followingCount: 3,
    createdAt: DateTime(2011, 1, 25),
  );
}

/// A minimal repository for tests.
Repository sampleRepository({
  String id = '1',
  String name = 'command-center',
  String description = 'Developer command center',
  String language = 'Dart',
  int stars = 42,
  int forks = 7,
  DateTime? updatedAt,
}) {
  return Repository(
    id: id,
    name: name,
    fullName: 'octocat/$name',
    owner: 'octocat',
    description: description,
    isPrivate: false,
    isFork: false,
    url: 'https://github.com/octocat/$name',
    defaultBranch: 'main',
    language: language,
    stars: stars,
    forks: forks,
    openIssues: 2,
    updatedAt: updatedAt ?? DateTime(2026, 9, 30),
  );
}

/// A sample activity for tests.
DeveloperActivity sampleActivity({
  String id = 'evt-1',
  DeveloperActivityType type = DeveloperActivityType.commitPushed,
  String title = 'Pushed 3 commits to octocat/command-center',
  DateTime? timestamp,
  String repository = 'octocat/command-center',
  String? identifier,
  int? commitCount = 3,
}) {
  return DeveloperActivity(
    id: id,
    type: type,
    repository: repository,
    title: title,
    subtitle: 'main',
    identifier: identifier,
    rawType: 'PushEvent',
    timestamp: timestamp ?? DateTime(2026, 10, 2, 12),
    commitCount: commitCount,
  );
}
