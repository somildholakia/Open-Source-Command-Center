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
  int _lifecycleGeneration = 0;

  IntegrationBloc({
    required this.provider,
    Future<ConnectionStore> Function()? storeFactory,
    Future<LocalSnapshotStore> Function()? snapshotStoreFactory,
  }) : _storeFactory = storeFactory ?? _defaultStoreFactory,
       _snapshotStoreFactory =
           snapshotStoreFactory ?? _defaultSnapshotStoreFactory,
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
    return '${record!.providerId}:$username';
  }

  /// Resolves the account to clean up even when sign-out races startup restore.
  ///
  /// During startup, [state.connection] may still be null while the persisted
  /// connection record already identifies the account whose snapshots must be
  /// removed from this device.
  Future<String?> _accountIdForCleanup() async {
    final activeAccountId = _accountCacheId(state.connection);
    if (activeAccountId != null) return activeAccountId;

    try {
      final persistedRecord = (await _store()).load();
      return _accountCacheId(persistedRecord);
    } catch (_) {
      return null;
    }
  }

  /// Clears persisted connection metadata and that account's cached data.
  ///
  /// [generation] prevents a delayed startup cleanup from erasing a newer
  /// connection created while storage was being accessed.
  Future<void> _clearPersistedConnection({int? generation}) async {
    try {
      final store = await _store();
      if (generation != null && generation != _lifecycleGeneration) return;
      final record = store.load();
      final accountId = _accountCacheId(record);
      if (accountId != null) {
        try {
          final cache = await _snapshotStoreFactory();
          if (generation != null && generation != _lifecycleGeneration) return;
          await cache.clearAccount(accountId);
        } catch (_) {
          // Cleanup is best-effort; stale metadata must still be removed.
        }
      }
      if (generation != null && generation != _lifecycleGeneration) return;
      await store.clear();
    } catch (_) {
      // Local persistence must never prevent the app from starting.
    }
  }

  /// Decode one snapshot independently so a single corrupt namespace cannot
  /// hide other valid cached data. Invalid entries are removed best-effort.
  Future<T?> _decodeCachedSnapshot<T>({
    required LocalSnapshotStore cache,
    required String accountId,
    required String namespace,
    required LocalSnapshot? snapshot,
    required T Function() decode,
  }) async {
    if (snapshot == null) return null;
    try {
      return decode();
    } catch (_) {
      try {
        await cache.remove(accountId: accountId, namespace: namespace);
      } catch (_) {
        // A failed cleanup must not prevent the remaining cache from loading.
      }
      return null;
    }
  }

  Future<LocalSnapshot?> _readCachedSnapshotSafely({
    required LocalSnapshotStore cache,
    required String accountId,
    required String namespace,
  }) async {
    try {
      return await cache.read(
        accountId: accountId,
        namespace: namespace,
        schemaVersion: _snapshotSchemaVersion,
      );
    } catch (_) {
      // Other namespaces may still be valid and useful offline.
      return null;
    }
  }

  Future<void> _restoreCachedData(
    ProviderConnectionRecord record,
    Emitter<IntegrationState> emit, {
    required int generation,
  }) async {
    final accountId = _accountCacheId(record);
    if (accountId == null) return;
    try {
      final cache = await _snapshotStoreFactory();
      // Cache namespaces are independent. Read them concurrently and isolate
      // failures so one unavailable/corrupt key cannot hide other valid data.
      final snapshots = await Future.wait<LocalSnapshot?>([
        _readCachedSnapshotSafely(
          cache: cache,
          accountId: accountId,
          namespace: 'profile',
        ),
        _readCachedSnapshotSafely(
          cache: cache,
          accountId: accountId,
          namespace: 'repositories',
        ),
        _readCachedSnapshotSafely(
          cache: cache,
          accountId: accountId,
          namespace: 'activity',
        ),
        _readCachedSnapshotSafely(
          cache: cache,
          accountId: accountId,
          namespace: 'contributions',
        ),
      ]);
      final profileSnapshot = snapshots[0];
      final repositoriesSnapshot = snapshots[1];
      final activitySnapshot = snapshots[2];
      final contributionsSnapshot = snapshots[3];
      final profile = await _decodeCachedSnapshot<DeveloperProfile>(
        cache: cache,
        accountId: accountId,
        namespace: 'profile',
        snapshot: profileSnapshot,
        decode: () =>
            ProviderSnapshotCodec.decodeProfile(profileSnapshot!.payload),
      );
      final repositories = await _decodeCachedSnapshot<List<Repository>>(
        cache: cache,
        accountId: accountId,
        namespace: 'repositories',
        snapshot: repositoriesSnapshot,
        decode: () => ProviderSnapshotCodec.decodeRepositories(
          repositoriesSnapshot!.payload['items'],
        ),
      );
      final activities = await _decodeCachedSnapshot<List<DeveloperActivity>>(
        cache: cache,
        accountId: accountId,
        namespace: 'activity',
        snapshot: activitySnapshot,
        decode: () => ProviderSnapshotCodec.decodeActivities(
          activitySnapshot!.payload['items'],
        ),
      );
      final contributions = await _decodeCachedSnapshot<ContributionSummary>(
        cache: cache,
        accountId: accountId,
        namespace: 'contributions',
        snapshot: contributionsSnapshot,
        decode: () => ProviderSnapshotCodec.decodeContributions(
          contributionsSnapshot!.payload,
        ),
      );
      if (generation != _lifecycleGeneration) return;
      if (profile != null ||
          repositories != null ||
          activities != null ||
          contributions != null) {
        emit(
          IntegrationState(
            phase: IntegrationPhase.connected,
            connection: record,
            profile: profile,
            repositories: repositories ?? const [],
            activities: activities ?? const [],
            contributions: contributions,
            isStale: true,
          ),
        );
      }
    } catch (_) {
      // A corrupt/unavailable cache must never prevent a live refresh.
    }
  }

  bool _isRefreshCurrent(int generation, String? accountId) =>
      generation == _lifecycleGeneration &&
      state.phase == IntegrationPhase.connected &&
      _accountCacheId(state.connection) == accountId;

  /// Reconciles persistence after a refresh loses a race with disconnect or
  /// account switching. A completed async write must not resurrect old state.
  Future<void> _reconcileStaleRefreshPersistence(String? accountId) async {
    if (state.phase == IntegrationPhase.disconnected && accountId != null) {
      try {
        await (await _snapshotStoreFactory()).clearAccount(accountId);
      } catch (_) {}
    }

    try {
      final store = await _store();
      final current = state;
      if (current.phase == IntegrationPhase.disconnected) {
        await store.clear();
      } else if (current.phase == IntegrationPhase.connected &&
          current.connection != null) {
        await store.save(current.connection!);
      } else if (current.phase == IntegrationPhase.connecting &&
          _accountCacheId(store.load()) == accountId) {
        // Remove only the stale record; do not clear a newer account's record.
        await store.clear();
      }
    } catch (_) {
      // Reconciliation is best-effort and must not block the UI lifecycle.
    }
  }

  Future<void> _persistSuccessfulSnapshots(
    IntegrationState previous, {
    required int generation,
    required Object? profile,
    required Object? repositories,
    required Object? activities,
    required Object? contributions,
  }) async {
    final accountId = _accountCacheId(previous.connection);
    if (accountId == null) return;
    try {
      final cache = await _snapshotStoreFactory();

      Future<bool> stopIfStale() async {
        if (_isRefreshCurrent(generation, accountId)) return false;
        // A write may have completed after disconnect's first cleanup pass.
        if (generation != _lifecycleGeneration &&
            state.phase == IntegrationPhase.disconnected) {
          try {
            await cache.clearAccount(accountId);
          } catch (_) {}
        }
        return true;
      }

      Future<bool> writeSnapshot({
        required String namespace,
        required Map<String, dynamic> payload,
      }) async {
        if (await stopIfStale()) return true;
        // Each namespace is best-effort independently. An oversized or
        // malformed snapshot must not prevent other valid data from caching.
        try {
          await cache.write(
            accountId: accountId,
            namespace: namespace,
            payload: payload,
            schemaVersion: _snapshotSchemaVersion,
          );
        } catch (_) {}
        return stopIfStale();
      }

      if (profile is DeveloperProfile) {
        if (await writeSnapshot(
          namespace: 'profile',
          payload: ProviderSnapshotCodec.encodeProfile(profile),
        )) {
          return;
        }
      }
      if (repositories is List<Repository>) {
        if (await writeSnapshot(
          namespace: 'repositories',
          payload: {
            'items': ProviderSnapshotCodec.encodeRepositories(repositories),
          },
        )) {
          return;
        }
      }
      if (activities is List<DeveloperActivity>) {
        if (await writeSnapshot(
          namespace: 'activity',
          payload: {
            'items': ProviderSnapshotCodec.encodeActivities(activities),
          },
        )) {
          return;
        }
      }
      if (contributions is ContributionSummary) {
        await writeSnapshot(
          namespace: 'contributions',
          payload: ProviderSnapshotCodec.encodeContributions(contributions),
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
    final generation = ++_lifecycleGeneration;
    emit(const IntegrationState(phase: IntegrationPhase.unknown));

    try {
      final connected = await provider.isConnected();
      if (generation != _lifecycleGeneration) return;
      if (!connected) {
        await _clearPersistedConnection(generation: generation);
        if (generation != _lifecycleGeneration) return;
        emit(const IntegrationState(phase: IntegrationPhase.disconnected));
        return;
      }

      final store = await _store();
      if (generation != _lifecycleGeneration) return;
      final record = store.load();
      if (record != null) {
        emit(
          IntegrationState(
            phase: IntegrationPhase.connected,
            connection: record,
          ),
        );
        await _restoreCachedData(record, emit, generation: generation);
        if (generation != _lifecycleGeneration) return;
        add(const IntegrationDataRefreshRequested());
        return;
      }

      // Token exists but no record: rebuild it from the profile.
      final profile = await provider.fetchProfile();
      if (generation != _lifecycleGeneration) return;
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
      if (generation != _lifecycleGeneration) return;
      emit(
        IntegrationState(
          phase: IntegrationPhase.connected,
          connection: rebuilt,
        ),
      );
      await _restoreCachedData(rebuilt, emit, generation: generation);
      if (generation != _lifecycleGeneration) return;
      add(const IntegrationDataRefreshRequested());
    } on AuthorizationExpired {
      if (generation != _lifecycleGeneration) return;
      // Token rejected during restore: remove persisted metadata and snapshots
      // so a later launch cannot resurrect a disconnected account.
      try {
        await provider.disconnect();
      } catch (_) {}
      await _clearPersistedConnection(generation: generation);
      if (generation != _lifecycleGeneration) return;
      emit(const IntegrationState(phase: IntegrationPhase.disconnected));
    } on ProviderFailure catch (failure) {
      if (generation != _lifecycleGeneration) return;
      emit(IntegrationState(phase: IntegrationPhase.error, failure: failure));
    } catch (e) {
      if (generation != _lifecycleGeneration) return;
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
    final generation = ++_lifecycleGeneration;
    // Never display the previous account's data while a different account is
    // being authorized.
    emit(const IntegrationState(phase: IntegrationPhase.connecting));

    try {
      final result = await provider.connect(
        onPrompt: (prompt) {
          if (generation == _lifecycleGeneration &&
              state.phase == IntegrationPhase.connecting) {
            emit(state.copyWith(prompt: prompt));
          }
        },
      );

      if (generation != _lifecycleGeneration) {
        await provider.disconnect();
        return;
      }
      final record = ProviderConnectionRecord.connected(
        providerId: provider.providerId,
        account: result.account,
      );
      final store = await _store();
      if (generation != _lifecycleGeneration) {
        await provider.disconnect();
        return;
      }
      await store.save(record);
      if (generation != _lifecycleGeneration) return;

      emit(
        IntegrationState(
          phase: IntegrationPhase.connected,
          connection: record,
          profile: result.profile,
          repositories: const [],
          activities: const [],
          contributions: null,
        ),
      );
      add(const IntegrationDataRefreshRequested());
    } on ProviderFailure catch (failure) {
      if (generation != _lifecycleGeneration) return;
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
      if (generation != _lifecycleGeneration) return;
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
    final generation = ++_lifecycleGeneration;
    final accountId = await _accountIdForCleanup();
    if (generation != _lifecycleGeneration) return;

    if (accountId != null) {
      try {
        final cache = await _snapshotStoreFactory();
        if (generation != _lifecycleGeneration) return;
        await cache.clearAccount(accountId);
      } catch (_) {
        // Disconnect must still complete when local cache cleanup fails.
      }
    }
    if (generation != _lifecycleGeneration) return;

    try {
      final store = await _store();
      if (generation != _lifecycleGeneration) return;
      await store.clear();
    } catch (_) {
      // Local metadata must not prevent the disconnect.
    }
    if (generation != _lifecycleGeneration) return;

    try {
      await provider.disconnect();
    } catch (_) {
      if (generation != _lifecycleGeneration) return;
      emit(
        const IntegrationState(
          phase: IntegrationPhase.error,
          failure: UnknownProviderError(
            detail:
                'GitHub could not confirm credential removal. Check secure storage and retry.',
          ),
        ),
      );
      return;
    }
    if (generation != _lifecycleGeneration) return;

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
    final generation = _lifecycleGeneration;
    final accountId = _accountCacheId(state.connection);

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

    // These endpoints are independent. Fetch them concurrently so a slow
    // contribution response does not delay profile/repository/activity data.
    // Each request still maps its own failure into a typed result, allowing
    // partial success and preserving last-known snapshots.
    final results = await Future.wait<Object?>([
      _safe(() => provider.fetchProfile()),
      _safe(() => provider.fetchRepositories()),
      _safe(() => provider.fetchActivity()),
      _safe(() => provider.fetchContributions()),
    ]);
    if (generation != _lifecycleGeneration ||
        state.phase != IntegrationPhase.connected ||
        _accountCacheId(state.connection) != accountId) {
      return;
    }

    final profile = results[0];
    final repositories = results[1];
    final activities = results[2];
    final contributions = results[3];

    // Authorization is dead: surface expired + keep record for username.
    if (profile is AuthorizationExpired ||
        repositories is AuthorizationExpired ||
        activities is AuthorizationExpired ||
        contributions is AuthorizationExpired) {
      // The lifecycle can change while the provider disconnects (for example,
      // a user starts a new connection). Never let stale expiry tear down or
      // overwrite that newer lifecycle.
      await provider.disconnect();
      if (!_isRefreshCurrent(generation, accountId)) {
        await _reconcileStaleRefreshPersistence(accountId);
        return;
      }
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
      generation: generation,
      profile: profile,
      repositories: repositories,
      activities: activities,
      contributions: contributions,
    );
    if (!_isRefreshCurrent(generation, accountId)) {
      await _reconcileStaleRefreshPersistence(accountId);
      return;
    }

    if (failure == null && updatedRecord != null) {
      try {
        await (await _store()).save(updatedRecord);
      } catch (_) {}
      if (!_isRefreshCurrent(generation, accountId)) {
        await _reconcileStaleRefreshPersistence(accountId);
        return;
      }
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
    final generation = ++_lifecycleGeneration;
    // Signing out must not leave the previous account's cached provider data
    // on a shared device. The persisted record is also checked when startup
    // has not restored it into state yet.
    final accountId = await _accountIdForCleanup();
    if (generation != _lifecycleGeneration) return;

    if (accountId != null) {
      try {
        final cache = await _snapshotStoreFactory();
        if (generation != _lifecycleGeneration) return;
        await cache.clearAccount(accountId);
      } catch (_) {
        // A local-storage failure must not prevent sign-out.
      }
    }
    if (generation != _lifecycleGeneration) return;

    try {
      final store = await _store();
      if (generation != _lifecycleGeneration) return;
      await store.clear();
    } catch (_) {}
    if (generation != _lifecycleGeneration) return;

    try {
      await provider.disconnect();
    } catch (_) {}
    if (generation != _lifecycleGeneration) return;

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
