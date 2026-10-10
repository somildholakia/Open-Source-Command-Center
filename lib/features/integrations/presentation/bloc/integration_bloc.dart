import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../domain/domain.dart';
import '../../../../services/cache/local_snapshot_store.dart';
import '../../../../services/cache/provider_snapshot_codec.dart';
import '../../../../services/connection/connection_store.dart';

/// Events driving the provider-connection lifecycle.
sealed class IntegrationEvent {
  const IntegrationEvent();
}

/// App started (or a user session became active): restore stored connection.
class IntegrationStarted extends IntegrationEvent {
  const IntegrationStarted();
}

/// User tapped a "Connect GitHub" CTA.
class IntegrationConnectRequested extends IntegrationEvent {
  const IntegrationConnectRequested();
}

/// User cancelled an in-progress authorization.
class IntegrationCancelConnectRequested extends IntegrationEvent {
  const IntegrationCancelConnectRequested();
}

/// User disconnected the provider.
class IntegrationDisconnectRequested extends IntegrationEvent {
  const IntegrationDisconnectRequested();
}

/// Refresh connected data (profile, repositories, activity, contributions).
class IntegrationDataRefreshRequested extends IntegrationEvent {
  const IntegrationDataRefreshRequested();
}

/// Firebase session ended (sign out) — drop in-memory connection state.
class IntegrationResetRequested extends IntegrationEvent {
  const IntegrationResetRequested();
}

/// Lifecycle phase of the provider connection.
enum IntegrationPhase {
  /// Restoring the persisted connection state.
  unknown,

  /// No connected provider. UI shows connection CTAs.
  disconnected,

  /// Authorization in progress; [IntegrationState.prompt] carries the
  /// user-facing device code when applicable.
  connecting,

  /// Connected with (possibly partial) normalized data available.
  connected,

  /// The stored token was rejected (revoked/expired). Reconnect required.
  expired,

  /// The last connect attempt failed.
  error,
}

/// Provider-connection and shared-data state.
///
/// A single app-scoped bloc owns connection state and normalized data so all
/// screens (Dashboard/Activity/Contributions/Profile) share one fetch per
/// refresh — widgets never call providers or APIs directly and never trigger
/// duplicate requests on rebuild.
class IntegrationState extends Equatable {
  final IntegrationPhase phase;

  /// Active authorization prompt (device code) while [IntegrationPhase.connecting].
  final ConnectionPrompt? prompt;

  /// Persisted connection info (never contains tokens).
  final ProviderConnectionRecord? connection;

  /// Normalized provider profile, when fetched.
  final DeveloperProfile? profile;

  /// Repositories, most recently updated first.
  final List<Repository> repositories;

  /// Recent public activity, newest first.
  final List<DeveloperActivity> activities;

  /// Contribution counts by day, when available (requires authorization).
  final ContributionSummary? contributions;

  /// True while the initial data load after connect is running.
  final bool isLoadingData;

  /// True while a user-triggered refresh is running on top of existing data.
  final bool isRefreshing;

  /// Last failure (connection or data). Cleared on successful refresh.
  final ProviderFailure? failure;

  /// True when displayed provider data came from local cache or a refresh failed.
  final bool isStale;

  const IntegrationState({
    this.phase = IntegrationPhase.unknown,
    this.prompt,
    this.connection,
    this.profile,
    this.repositories = const [],
    this.activities = const [],
    this.contributions,
    this.isLoadingData = false,
    this.isRefreshing = false,
    this.failure,
    this.isStale = false,
  });

  bool get isConnected => phase == IntegrationPhase.connected;
  bool get isConnecting => phase == IntegrationPhase.connecting;
  bool get isBusy => isLoadingData || isRefreshing;

  IntegrationState copyWith({
    IntegrationPhase? phase,
    ConnectionPrompt? prompt,
    bool clearPrompt = false,
    ProviderConnectionRecord? connection,
    DeveloperProfile? profile,
    List<Repository>? repositories,
    List<DeveloperActivity>? activities,
    ContributionSummary? contributions,
    bool clearContributions = false,
    bool? isLoadingData,
    bool? isRefreshing,
    ProviderFailure? failure,
    bool clearFailure = false,
    bool? isStale,
  }) {
    return IntegrationState(
      phase: phase ?? this.phase,
      prompt: clearPrompt ? null : (prompt ?? this.prompt),
      connection: connection ?? this.connection,
      profile: profile ?? this.profile,
      repositories: repositories ?? this.repositories,
      activities: activities ?? this.activities,
      contributions: clearContributions
          ? null
          : (contributions ?? this.contributions),
      isLoadingData: isLoadingData ?? this.isLoadingData,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: clearFailure ? null : (failure ?? this.failure),
      isStale: isStale ?? this.isStale,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    prompt,
    connection,
    profile,
    repositories,
    activities,
    contributions,
    isLoadingData,
    isRefreshing,
    failure,
    isStale,
  ];
}

/// App-scoped bloc for the provider connection lifecycle and shared data.
class IntegrationBloc extends Bloc<IntegrationEvent, IntegrationState> {
  final DeveloperProvider provider;
  final Future<ConnectionStore> Function() _storeFactory;
  final Future<LocalSnapshotStore> Function() _snapshotStoreFactory;
  static const int _snapshotSchemaVersion = 1;

  IntegrationBloc({
    required this.provider,
    Future<ConnectionStore> Function()? storeFactory,
    Future<LocalSnapshotStore> Function()? snapshotStoreFactory,
  }) : _storeFactory = storeFactory ?? _defaultStoreFactory,
       _snapshotStoreFactory = snapshotStoreFactory ?? _defaultSnapshotStoreFactory,
       super(const IntegrationState()) {
    on<IntegrationStarted>(_onStarted);
    on<IntegrationConnectRequested>(_onConnectRequested);
    on<IntegrationCancelConnectRequested>(_onCancelConnectRequested);
    on<IntegrationDisconnectRequested>(_onDisconnectRequested);
    on<IntegrationDataRefreshRequested>(_onDataRefreshRequested);
    on<IntegrationResetRequested>(_onResetRequested);
  }

  /// Abstraction over persisted connection storage, injectable for tests.
  Future<ConnectionStore> _store() => _storeFactory();

  static Future<ConnectionStore> _defaultStoreFactory() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsConnectionStore(prefs);
  }

  static Future<LocalSnapshotStore> _defaultSnapshotStoreFactory() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalSnapshotStore(prefs);
  }

  String? _accountCacheId(ProviderConnectionRecord? record) {
    final username = record?.account?.username;
    if (username == null || username.isEmpty) return null;
    return record!.providerId + ':' + username;
  }

  Future<void> _restoreCachedData(
    ProviderConnectionRecord record,
    Emitter<IntegrationState> emit,
  ) async {
    final accountId = _accountCacheId(record);
    if (accountId == null) return;
    try {
      final cache = await _snapshotStoreFactory();
      final profileSnapshot = await cache.read(
        accountId: accountId, namespace: 'profile',
        schemaVersion: _snapshotSchemaVersion,
      );
      final repositoriesSnapshot = await cache.read(
        accountId: accountId, namespace: 'repositories',
        schemaVersion: _snapshotSchemaVersion,
      );
      final activitySnapshot = await cache.read(
        accountId: accountId, namespace: 'activity',
        schemaVersion: _snapshotSchemaVersion,
      );
      final contributionsSnapshot = await cache.read(
        accountId: accountId, namespace: 'contributions',
        schemaVersion: _snapshotSchemaVersion,
      );
      final profile = profileSnapshot == null
          ? null
          : ProviderSnapshotCodec.decodeProfile(profileSnapshot.payload);
      final repositories = repositoriesSnapshot == null
          ? null
          : ProviderSnapshotCodec.decodeRepositories(
              repositoriesSnapshot.payload['items'],
            );
      final activities = activitySnapshot == null
          ? null
          : ProviderSnapshotCodec.decodeActivities(
              activitySnapshot.payload['items'],
            );
      final contributions = contributionsSnapshot == null
          ? null
          : ProviderSnapshotCodec.decodeContributions(
              contributionsSnapshot.payload,
            );
      if (profile != null || repositories != null || activities != null ||
          contributions != null) {
        emit(IntegrationState(
          phase: IntegrationPhase.connected,
          connection: record,
          profile: profile,
          repositories: repositories ?? const [],
          activities: activities ?? const [],
          contributions: contributions,
          isStale: true,
        ));
      }
    } catch (_) {
      // A corrupt/unavailable cache must never prevent a live refresh.
    }
  }

  Future<void> _persistSuccessfulSnapshots(
    IntegrationState previous, {
    required Object? profile,
    required Object? repositories,
    required Object? activities,
    required Object? contributions,
  }) async {
    final accountId = _accountCacheId(previous.connection);
    if (accountId == null) return;
    try {
      final cache = await _snapshotStoreFactory();
      if (profile is DeveloperProfile) {
        await cache.write(
          accountId: accountId, namespace: 'profile',
          payload: ProviderSnapshotCodec.encodeProfile(profile),
          schemaVersion: _snapshotSchemaVersion,
        );
      }
      if (repositories is List<Repository>) {
        await cache.write(
          accountId: accountId, namespace: 'repositories',
          payload: {'items': ProviderSnapshotCodec.encodeRepositories(repositories)},
          schemaVersion: _snapshotSchemaVersion,
        );
      }
      if (activities is List<DeveloperActivity>) {
        await cache.write(
          accountId: accountId, namespace: 'activity',
          payload: {'items': ProviderSnapshotCodec.encodeActivities(activities)},
          schemaVersion: _snapshotSchemaVersion,
        );
      }
      if (contributions is ContributionSummary) {
        await cache.write(
          accountId: accountId, namespace: 'contributions',
          payload: ProviderSnapshotCodec.encodeContributions(contributions),
          schemaVersion: _snapshotSchemaVersion,
        );
      }
    } catch (_) {
      // Caching is best-effort; storage failure must not block live data.
    }
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onStarted(
    IntegrationStarted event,
    Emitter<IntegrationState> emit,
  ) async {
    emit(const IntegrationState(phase: IntegrationPhase.unknown));

    try {
      final connected = await provider.isConnected();
      if (!connected) {
        emit(const IntegrationState(phase: IntegrationPhase.disconnected));
        return;
      }

      final store = await _store();
      final record = store.load();
      if (record != null) {
        emit(
          IntegrationState(
            phase: IntegrationPhase.connected,
            connection: record,
          ),
        );
        await _restoreCachedData(record, emit);
        add(const IntegrationDataRefreshRequested());
        return;
      }

      // Token exists but no record: rebuild it from the profile.
      final profile = await provider.fetchProfile();
      final rebuilt = ProviderConnectionRecord.connected(
        providerId: provider.providerId,
        account: ConnectedAccount(
          providerId: provider.providerId,
          username: profile.username,
          avatarUrl: profile.avatarUrl,
          profileUrl: profile.profileUrl,
          connectedAt: DateTime.now(),
        ),
      );
      await store.save(rebuilt);
      emit(
        IntegrationState(
          phase: IntegrationPhase.connected,
          connection: rebuilt,
        ),
      );
      await _restoreCachedData(rebuilt, emit);
      add(const IntegrationDataRefreshRequested());
    } on AuthorizationExpired {
      // Token rejected: silently disconnect (clears stored state).
      try {
        await provider.disconnect();
      } catch (_) {}
      emit(const IntegrationState(phase: IntegrationPhase.disconnected));
    } on ProviderFailure catch (failure) {
      emit(IntegrationState(phase: IntegrationPhase.error, failure: failure));
    } catch (e) {
      emit(
        IntegrationState(
          phase: IntegrationPhase.error,
          failure: UnknownProviderError(detail: e.toString()),
        ),
      );
    }
  }

  Future<void> _onConnectRequested(
    IntegrationConnectRequested event,
    Emitter<IntegrationState> emit,
  ) async {
    emit(
      state.copyWith(
        phase: IntegrationPhase.connecting,
        prompt: null,
        clearFailure: true,
      ),
    );

    try {
      final result = await provider.connect(
        onPrompt: (prompt) {
          if (state.phase == IntegrationPhase.connecting) {
            emit(state.copyWith(prompt: prompt));
          }
        },
      );

      final record = ProviderConnectionRecord.connected(
        providerId: provider.providerId,
        account: result.account,
      );
      final store = await _store();
      await store.save(record);

      emit(
        IntegrationState(
          phase: IntegrationPhase.connected,
          connection: record,
          profile: result.profile,
          repositories: state.repositories,
          activities: state.activities,
          contributions: state.contributions,
        ),
      );
      add(const IntegrationDataRefreshRequested());
    } on ProviderFailure catch (failure) {
      final cancelled =
          failure is AuthenticationFailed &&
          (failure.detail?.contains('cancelled') ?? false);
      emit(
        IntegrationState(
          phase: cancelled
              ? IntegrationPhase.disconnected
              : IntegrationPhase.error,
          failure: cancelled ? null : failure,
        ),
      );
    } catch (e) {
      emit(
        IntegrationState(
          phase: IntegrationPhase.error,
          failure: UnknownProviderError(detail: e.toString()),
        ),
      );
    }
  }

  Future<void> _onCancelConnectRequested(
    IntegrationCancelConnectRequested event,
    Emitter<IntegrationState> emit,
  ) async {
    provider.cancelAuthorization();
  }

  Future<void> _onDisconnectRequested(
    IntegrationDisconnectRequested event,
    Emitter<IntegrationState> emit,
  ) async {
    final accountId = _accountCacheId(state.connection);
    if (accountId != null) {
      try {
        await (await _snapshotStoreFactory()).clearAccount(accountId);
      } catch (_) {
        // Disconnect must still complete when local cache cleanup fails.
      }
    }
    try {
      await provider.disconnect();
    } catch (_) {
      // Best-effort; local state is cleared regardless.
    }
    emit(const IntegrationState(phase: IntegrationPhase.disconnected));
  }

  Future<void> _onDataRefreshRequested(
    IntegrationDataRefreshRequested event,
    Emitter<IntegrationState> emit,
  ) async {
    // Deduplicate: never run overlapping refreshes (Stage 10 — no duplicate
    // API calls from widget rebuilds).
    if (state.isBusy) return;
    if (state.phase != IntegrationPhase.connected) return;

    final hadData =
        state.profile != null ||
        state.repositories.isNotEmpty ||
        state.activities.isNotEmpty ||
        state.contributions != null;
    emit(
      state.copyWith(
        isLoadingData: !hadData,
        isRefreshing: hadData,
        clearFailure: true,
      ),
    );

    final profile = await _safe(() => provider.fetchProfile());
    final repositories = await _safe(() => provider.fetchRepositories());
    final activities = await _safe(() => provider.fetchActivity());
    final contributions = await _safe(() => provider.fetchContributions());

    // Authorization is dead: surface expired + keep record for username.
    if (profile is AuthorizationExpired ||
        repositories is AuthorizationExpired ||
        activities is AuthorizationExpired ||
        contributions is AuthorizationExpired) {
      await provider.disconnect();
      emit(
        IntegrationState(
          phase: IntegrationPhase.expired,
          connection: state.connection,
        ),
      );
      return;
    }

    ProviderFailure? failure;
    if (profile is ProviderFailure) failure = profile;
    if (repositories is ProviderFailure && failure == null) {
      failure = repositories;
    }
    if (activities is ProviderFailure && failure == null) {
      failure = activities;
    }
    if (contributions is ProviderFailure && failure == null) {
      failure = contributions;
    }

    final updatedRecord = state.connection?.copyWith(
      lastSyncedAt: failure == null ? DateTime.now() : null,
    );

    await _persistSuccessfulSnapshots(
      state,
      profile: profile,
      repositories: repositories,
      activities: activities,
      contributions: contributions,
    );

    if (failure == null && updatedRecord != null) {
      try {
        await (await _store()).save(updatedRecord);
      } catch (_) {}
    }

    emit(
      state.copyWith(
        phase: IntegrationPhase.connected,
        connection: updatedRecord,
        // Preserve the last-known profile if this refresh failed. A partial
        // network failure must not erase useful offline data.
        profile: profile is DeveloperProfile ? profile : state.profile,
        repositories: repositories is List<Repository>
            ? repositories
            : state.repositories,
        activities: activities is List<DeveloperActivity>
            ? activities
            : state.activities,
        contributions: contributions is ContributionSummary
            ? contributions
            : state.contributions,
        isLoadingData: false,
        isRefreshing: false,
        failure: failure,
        isStale: failure != null,
      ),
    );
  }

  Future<void> _onResetRequested(
    IntegrationResetRequested event,
    Emitter<IntegrationState> emit,
  ) async {
    try {
      await provider.disconnect();
    } catch (_) {}
    emit(const IntegrationState(phase: IntegrationPhase.disconnected));
  }

  /// Runs [action], returning its result or the [ProviderFailure] it threw.
  Future<Object?> _safe(Future<Object?> Function() action) async {
    try {
      return await action();
    } on ProviderFailure catch (failure) {
      return failure;
    } catch (e) {
      return UnknownProviderError(detail: e.toString());
    }
  }
}
