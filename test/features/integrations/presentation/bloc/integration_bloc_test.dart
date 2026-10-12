import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/integrations/presentation/bloc/integration_bloc.dart';
import 'package:opensource_command_center/services/cache/local_snapshot_store.dart';
import 'package:opensource_command_center/services/cache/provider_snapshot_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/fake_developer_provider.dart';
import '../../../../support/in_memory_connection_store.dart';

class DelayedWriteSnapshotStore extends LocalSnapshotStore {
  DelayedWriteSnapshotStore(super.preferences);

  bool delayNextWrite = false;
  final writeStarted = Completer<void>();
  final releaseWrite = Completer<void>();
  final delayedWriteCompleted = Completer<void>();

  @override
  Future<void> write({
    required String accountId,
    required String namespace,
    required Map<String, dynamic> payload,
    required int schemaVersion,
    DateTime? cachedAt,
  }) async {
    if (delayNextWrite) {
      delayNextWrite = false;
      writeStarted.complete();
      await releaseWrite.future;
    }
    await super.write(
      accountId: accountId,
      namespace: namespace,
      payload: payload,
      schemaVersion: schemaVersion,
      cachedAt: cachedAt,
    );
    if (writeStarted.isCompleted && !delayedWriteCompleted.isCompleted) {
      delayedWriteCompleted.complete();
    }
  }
}

class FailingReadSnapshotStore extends LocalSnapshotStore {
  FailingReadSnapshotStore(super.preferences);

  @override
  Future<LocalSnapshot?> read({
    required String accountId,
    required String namespace,
    required int schemaVersion,
  }) async {
    if (namespace == 'activity') {
      throw StateError('Simulated activity cache read failure');
    }
    return super.read(
      accountId: accountId,
      namespace: namespace,
      schemaVersion: schemaVersion,
    );
  }
}

void main() {
  ProviderConnectionRecord connectedRecord({String username = 'octocat'}) {
    return ProviderConnectionRecord.connected(
      providerId: 'github',
      account: ConnectedAccount(
        providerId: 'github',
        username: username,
        avatarUrl: '',
        profileUrl: '',
      ),
    );
  }

  /// Waits until the bloc is idle (no loading/refreshing) and the given
  /// condition holds, pumping microtasks between checks.
  Future<void> waitFor(
    IntegrationBloc bloc,
    bool Function(IntegrationState state) condition,
  ) async {
    for (var i = 0; i < 50; i++) {
      if (condition(bloc.state)) return;
      await Future<void>.delayed(Duration.zero);
    }
    fail('Timed out waiting for bloc state. Last state: ${bloc.state.phase}');
  }

  group('restore (IntegrationStarted)', () {
    test('emits disconnected when no token is stored', () async {
      final bloc = IntegrationBloc(
        provider: FakeDeveloperProvider(),
        storeFactory: () async => InMemoryConnectionStore(),
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      expect(bloc.state.isConnected, isFalse);
      await bloc.close();
    });

    test(
      'restores a stored connection and refreshes normalized data',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
          repositories: [sampleRepository()],
          activities: [sampleActivity()],
          contributions: ContributionSummary(
            dailyCounts: const {'2026-10-01': 4},
            fetchedAt: DateTime(2026, 10, 1),
          ),
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

        expect(bloc.state.connection?.account?.username, 'octocat');
        expect(bloc.state.profile?.username, 'octocat');
        expect(bloc.state.repositories, hasLength(1));
        expect(bloc.state.activities, hasLength(1));
        expect(bloc.state.contributions?.total, 4);
        // A successful refresh records the sync timestamp.
        expect(store.record?.lastSyncedAt, isNotNull);
        await bloc.close();
      },
    );

    test(
      'rebuilds the record from the profile when only a token exists',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(username: 'mona'),
        );
        final store = InMemoryConnectionStore();
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );

        expect(bloc.state.connection?.account?.username, 'mona');
        // Saved at least once (the rebuild; the follow-up refresh may save the
        // updated sync timestamp too).
        expect(store.saveCalls, greaterThanOrEqualTo(1));
        await bloc.close();
      },
    );

    test(
      'clears orphaned connection metadata and cache when token is missing',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cache = LocalSnapshotStore(preferences);
        await cache.write(
          accountId: 'github:octocat',
          namespace: 'profile',
          payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
          schemaVersion: 1,
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: FakeDeveloperProvider(connected: false),
          storeFactory: () async => store,
          snapshotStoreFactory: () async => cache,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );

        expect(store.record, isNull);
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'profile',
            schemaVersion: 1,
          ),
          isNull,
        );
        await bloc.close();
      },
    );

    test('surfaces restore cleanup failure for a rejected token', () async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const AuthorizationExpired(),
        disconnectFailure: const UnknownProviderError(
          detail: 'secure credential deletion failed',
        ),
      );
      final store = InMemoryConnectionStore();
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => store,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) =>
            state.phase == IntegrationPhase.error && state.failure != null,
      );

      expect(bloc.state.failure, isA<UnknownProviderError>());
      expect(provider.disconnectCalls, greaterThan(0));
      expect(store.record, isNull);
      await bloc.close();
    });

    test('disconnects silently when the stored token was rejected', () async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        dataFailure: const AuthorizationExpired(),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(),
      );

      bloc.add(const IntegrationStarted());
      // Restoring a rejected token is not an error the user caused: the app
      // simply returns to the disconnected state.
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      expect(provider.disconnectCalls, greaterThan(0));
      await bloc.close();
    });
  });

  group('local snapshots', () {
    test('persists successful provider responses on device', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = LocalSnapshotStore(preferences);
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        repositories: [sampleRepository()],
        activities: [sampleActivity()],
        contributions: ContributionSummary(
          dailyCounts: const {'2026-10-01': 4},
          fetchedAt: DateTime(2026, 10, 1),
        ),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'profile',
          schemaVersion: 1,
        ),
        isNotNull,
      );
      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'repositories',
          schemaVersion: 1,
        ),
        isNotNull,
      );
      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'activity',
          schemaVersion: 1,
        ),
        isNotNull,
      );
      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'contributions',
          schemaVersion: 1,
        ),
        isNotNull,
      );
      await bloc.close();
    });

    test(
      'an oversized repository snapshot does not block other cache namespaces',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cache = LocalSnapshotStore(preferences);
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
          repositories: [
            sampleRepository(
              description: 'x' * (LocalSnapshotStore.maxSnapshotBytes + 1),
            ),
          ],
          activities: [sampleActivity()],
          contributions: ContributionSummary(
            dailyCounts: const {'2026-10-01': 4},
            fetchedAt: DateTime(2026, 10, 1),
          ),
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
          snapshotStoreFactory: () async => cache,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'profile',
            schemaVersion: 1,
          ),
          isNotNull,
        );
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'repositories',
            schemaVersion: 1,
          ),
          isNull,
        );
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'activity',
            schemaVersion: 1,
          ),
          isNotNull,
        );
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'contributions',
            schemaVersion: 1,
          ),
          isNotNull,
        );
        await bloc.close();
      },
    );

    test('restores cached data and keeps it when refresh is offline', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = LocalSnapshotStore(preferences);
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'profile',
        payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
        schemaVersion: 1,
      );
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'repositories',
        payload: {
          'items': ProviderSnapshotCodec.encodeRepositories([
            sampleRepository(),
          ]),
        },
        schemaVersion: 1,
      );
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'activity',
        payload: {
          'items': ProviderSnapshotCodec.encodeActivities([sampleActivity()]),
        },
        schemaVersion: 1,
      );
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'contributions',
        payload: ProviderSnapshotCodec.encodeContributions(
          ContributionSummary(dailyCounts: const {'2026-10-01': 4}),
        ),
        schemaVersion: 1,
      );
      final provider = FakeDeveloperProvider(
        connected: true,
        dataFailure: const NetworkUnavailable(),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) => state.isStale && !state.isBusy && state.failure != null,
      );

      expect(bloc.state.profile?.username, 'octocat');
      expect(bloc.state.repositories, hasLength(1));
      expect(bloc.state.activities, hasLength(1));
      expect(bloc.state.contributions?.total, 4);
      await bloc.close();
    });

    test('one cache read failure does not hide valid cached profile', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = FailingReadSnapshotStore(preferences);
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'profile',
        payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
        schemaVersion: 1,
      );
      final provider = FakeDeveloperProvider(
        connected: true,
        dataFailure: const NetworkUnavailable(),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) => state.isStale && !state.isBusy && state.failure != null,
      );

      expect(bloc.state.profile?.username, 'octocat');
      expect(bloc.state.activities, isEmpty);
      await bloc.close();
    });

    test(
      'corrupt activity snapshot does not hide valid cached profile',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cache = LocalSnapshotStore(preferences);
        await cache.write(
          accountId: 'github:octocat',
          namespace: 'profile',
          payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
          schemaVersion: 1,
        );
        await cache.write(
          accountId: 'github:octocat',
          namespace: 'activity',
          payload: {
            'items': [
              {
                'id': 'corrupt-event',
                'type': 'not-a-real-activity-type',
                'timestamp': 'not-a-timestamp',
              },
            ],
          },
          schemaVersion: 1,
        );
        final provider = FakeDeveloperProvider(
          connected: true,
          dataFailure: const NetworkUnavailable(),
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
          snapshotStoreFactory: () async => cache,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.isStale && !state.isBusy && state.failure != null,
        );

        expect(bloc.state.profile?.username, 'octocat');
        expect(bloc.state.activities, isEmpty);
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'activity',
            schemaVersion: 1,
          ),
          isNull,
        );
        await bloc.close();
      },
    );

    test(
      'surfaces provider cleanup failure instead of claiming disconnect',
      () async {
        SharedPreferences.setMockInitialValues({});
        final provider = FakeDeveloperProvider(
          connected: true,
          disconnectFailure: const UnknownProviderError(
            detail: 'secure credential deletion failed',
          ),
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

        bloc.add(const IntegrationDisconnectRequested());
        await waitFor(
          bloc,
          (state) =>
              state.phase == IntegrationPhase.error && state.failure != null,
        );

        expect(bloc.state.failure, isA<UnknownProviderError>());
        expect(bloc.state.isConnected, isFalse);
        expect(bloc.state.connection?.account?.username, 'octocat');
        expect(provider.disconnectCalls, 1);
        expect(store.record, isNotNull);
        await bloc.close();
      },
    );

    test('clears this account cache on explicit GitHub disconnect', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = LocalSnapshotStore(preferences);
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'profile',
        payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
        schemaVersion: 1,
      );
      final bloc = IntegrationBloc(
        provider: FakeDeveloperProvider(
          connected: true,
          dataFailure: const NetworkUnavailable(),
        ),
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) => state.isStale && !state.isBusy && state.failure != null,
      );
      bloc.add(const IntegrationDisconnectRequested());
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'profile',
          schemaVersion: 1,
        ),
        isNull,
      );
      await bloc.close();
    });
  });

  group('connect', () {
    test(
      'emits connecting with the device-flow prompt, then connected',
      () async {
        final gate = Completer<void>();
        final provider = FakeDeveloperProvider()..onConnect = () => gate.future;
        final store = InMemoryConnectionStore();
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationConnectRequested());

        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connecting,
        );
        expect(bloc.state.prompt?.userCode, 'ABCD-1234');
        expect(store.record, isNull);

        gate.complete();
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );
        expect(provider.connectCalls, 1);
        // Connection is persisted (never the token — that lives in the token
        // store inside the provider).
        expect(store.record?.providerId, 'github');
        expect(store.record?.account?.username, 'octocat');
        await bloc.close();
      },
    );

    test(
      'a stale connect completion does not disconnect a newer authorization',
      () async {
        final firstGate = Completer<void>();
        final secondGate = Completer<void>();
        final provider = FakeDeveloperProvider();
        provider.onConnect = () =>
            provider.connectCalls == 1
                ? firstGate.future
                : secondGate.future;
        final store = InMemoryConnectionStore();
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationConnectRequested());
        await waitFor(bloc, (state) => provider.connectCalls == 1);

        bloc.add(const IntegrationConnectRequested());
        await waitFor(bloc, (state) => provider.connectCalls == 2);

        firstGate.complete();
        await Future<void>.delayed(Duration.zero);
        expect(provider.disconnectCalls, 0);
        expect(bloc.state.phase, IntegrationPhase.connecting);

        secondGate.complete();
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );

        expect(provider.disconnectCalls, 0);
        expect(bloc.state.connection?.account?.username, 'octocat');
        expect(store.record?.account?.username, 'octocat');
        await bloc.close();
      },
    );

    test(
      'cancellation returns to disconnected without an error card',
      () async {
        final gate = Completer<void>();
        final provider = FakeDeveloperProvider()..onConnect = () => gate.future;
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(),
        );

        bloc.add(const IntegrationConnectRequested());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connecting,
        );

        provider.connectFailure = const AuthenticationFailed(
          detail: 'Authorization cancelled.',
        );
        gate.complete();

        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );
        expect(bloc.state.failure, isNull);
        await bloc.close();
      },
    );

    test('maps authorization failures to the error phase', () async {
      final provider = FakeDeveloperProvider(
        connectFailure: const AuthenticationFailed(detail: 'Denied'),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(),
      );

      bloc.add(const IntegrationConnectRequested());
      await waitFor(bloc, (state) => state.phase == IntegrationPhase.error);

      expect(bloc.state.failure, isA<AuthenticationFailed>());
      await bloc.close();
    });

    test('cancelAuthorization is forwarded to the provider', () async {
      final provider = FakeDeveloperProvider();
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(),
      );

      bloc.add(const IntegrationCancelConnectRequested());
      await Future<void>.delayed(Duration.zero);

      expect(provider.cancelAuthorizationCalls, 1);
      await bloc.close();
    });
  });

  group('refresh', () {
    test(
      'deduplicates overlapping refreshes (no duplicate API calls)',
      () async {
        final gate = Completer<void>();
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);
        final callsAfterRestore = provider.fetchProfileCalls;

        provider.onFetch = () => gate.future;
        bloc.add(const IntegrationDataRefreshRequested());
        await waitFor(bloc, (state) => state.isBusy);

        // Second request while busy must be ignored.
        bloc.add(const IntegrationDataRefreshRequested());
        await Future<void>.delayed(Duration.zero);
        expect(provider.fetchProfileCalls, callsAfterRestore + 1);

        gate.complete();
        await waitFor(bloc, (state) => !state.isBusy);
        expect(provider.fetchProfileCalls, callsAfterRestore + 1);
        await bloc.close();
      },
    );

    test(
      'does not restore connected state when disconnected during refresh',
      () async {
        final gate = Completer<void>();
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
          repositories: [sampleRepository()],
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

        var completedFetches = 0;
        final allFetchesReleased = Completer<void>();
        provider.onFetch = () async {
          await gate.future;
          completedFetches++;
          if (completedFetches == 4 && !allFetchesReleased.isCompleted) {
            allFetchesReleased.complete();
          }
        };

        bloc.add(const IntegrationDataRefreshRequested());
        await waitFor(bloc, (state) => state.isBusy);
        bloc.add(const IntegrationDisconnectRequested());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );

        gate.complete();
        await allFetchesReleased.future;
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.phase, IntegrationPhase.disconnected);
        expect(bloc.state.connection, isNull);
        expect(store.record, isNull);
        await bloc.close();
      },
    );

    test('does not restore snapshots or connection metadata when a cache write '
        'finishes after disconnect', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = DelayedWriteSnapshotStore(preferences);
      final store = InMemoryConnectionStore(connectedRecord());
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        repositories: [sampleRepository()],
        activities: [sampleActivity()],
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => store,
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) =>
            !state.isBusy &&
            state.profile != null &&
            provider.fetchProfileCalls > 0,
      );

      cache.delayNextWrite = true;
      bloc.add(const IntegrationDataRefreshRequested());
      await cache.writeStarted.future;

      bloc.add(const IntegrationDisconnectRequested());
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      // Always release the delayed write before asserting so a failed
      // assertion cannot leave the refresh handler blocked indefinitely.
      cache.releaseWrite.complete();
      await cache.delayedWriteCompleted.future;
      expect(store.record, isNull);
      for (var i = 0; i < 50; i++) {
        final snapshot = await cache.read(
          accountId: 'github:octocat',
          namespace: 'profile',
          schemaVersion: 1,
        );
        if (snapshot == null) break;
        await Future<void>.delayed(Duration.zero);
      }

      expect(bloc.state.phase, IntegrationPhase.disconnected);
      expect(bloc.state.connection, isNull);
      expect(store.record, isNull);
      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'profile',
          schemaVersion: 1,
        ),
        isNull,
      );
      await bloc.close();
    });

    test(
      'keeps cached data and surfaces the failure when a refresh fails',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
          repositories: [sampleRepository()],
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);
        expect(bloc.state.repositories, hasLength(1));

        provider.dataFailure = const NetworkUnavailable();
        bloc.add(const IntegrationDataRefreshRequested());
        await waitFor(bloc, (state) => state.failure != null);
        await waitFor(bloc, (state) => !state.isBusy);

        expect(bloc.state.phase, IntegrationPhase.connected);
        expect(bloc.state.failure, isA<NetworkUnavailable>());
        expect(bloc.state.repositories, hasLength(1));
        await bloc.close();
      },
    );

    test('preserves connection data when expiry cleanup fails', () async {
      final store = InMemoryConnectionStore(connectedRecord());
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => store,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

      provider.dataFailure = const AuthorizationExpired();
      provider.disconnectFailure = const UnknownProviderError(
        detail: 'secure credential deletion failed',
      );
      bloc.add(const IntegrationDataRefreshRequested());
      await waitFor(
        bloc,
        (state) =>
            state.phase == IntegrationPhase.error && state.failure != null,
      );

      expect(bloc.state.failure, isA<UnknownProviderError>());
      expect(bloc.state.connection?.account?.username, 'octocat');
      expect(store.record, isNotNull);
      await bloc.close();
    });

    test(
      'expires the connection when the provider rejects the token',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        );

        bloc.add(const IntegrationStarted());
        await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

        provider.dataFailure = const AuthorizationExpired();
        bloc.add(const IntegrationDataRefreshRequested());
        await waitFor(bloc, (state) => state.phase == IntegrationPhase.expired);

        // The record is kept so the UI can still name the account, while the
        // provider token has been cleared.
        expect(bloc.state.connection?.account?.username, 'octocat');
        expect(provider.disconnectCalls, greaterThan(0));
        await bloc.close();
      },
    );

    test('refreshes independent GitHub data sources concurrently', () async {
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
        repositories: [sampleRepository()],
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
      );

      bloc.add(const IntegrationStarted());
      await waitFor(bloc, (state) => !state.isBusy && state.profile != null);

      var activeRequests = 0;
      var maximumConcurrentRequests = 0;
      final allRequestsStarted = Completer<void>();
      final releaseRequests = Completer<void>();
      provider.onFetch = () async {
        activeRequests++;
        if (activeRequests > maximumConcurrentRequests) {
          maximumConcurrentRequests = activeRequests;
        }
        if (activeRequests == 4 && !allRequestsStarted.isCompleted) {
          allRequestsStarted.complete();
        }
        await releaseRequests.future;
        activeRequests--;
      };

      bloc.add(const IntegrationDataRefreshRequested());
      try {
        await allRequestsStarted.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TestFailure(
            'Expected all four provider requests to start concurrently.',
          ),
        );
        expect(maximumConcurrentRequests, 4);
        if (!releaseRequests.isCompleted) releaseRequests.complete();
        await waitFor(bloc, (state) => !state.isBusy);
        expect(bloc.state.profile, isNotNull);
        expect(bloc.state.repositories, hasLength(1));
        expect(bloc.state.failure, isNull);
      } finally {
        if (!releaseRequests.isCompleted) releaseRequests.complete();
        await bloc.close();
      }
    });

    test('does nothing while disconnected', () async {
      final provider = FakeDeveloperProvider();
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(),
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      bloc.add(const IntegrationDataRefreshRequested());
      await Future<void>.delayed(Duration.zero);

      expect(provider.fetchProfileCalls, 0);
      await bloc.close();
    });
  });

  group('disconnect and reset', () {
    test(
      'disconnect clears the provider and returns to disconnected',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );

        bloc.add(const IntegrationDisconnectRequested());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );

        expect(provider.disconnectCalls, 1);
        expect(bloc.state.connection, isNull);
        expect(store.record, isNull);
        await bloc.close();
      },
    );

    test(
      'reset (sign-out) drops in-memory state through the provider',
      () async {
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
        );

        bloc.add(const IntegrationStarted());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.connected,
        );

        bloc.add(const IntegrationResetRequested());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );

        expect(provider.disconnectCalls, 1);
        expect(bloc.state.profile, isNull);
        expect(store.record, isNull);
        await bloc.close();
      },
    );
    test('reset surfaces provider credential cleanup failures', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = FakeDeveloperProvider(
        connected: true,
        disconnectFailure: const UnknownProviderError(
          detail: 'secure credential deletion failed',
        ),
      );
      final store = InMemoryConnectionStore(connectedRecord());
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => store,
      );

      bloc.add(const IntegrationResetRequested());
      await waitFor(
        bloc,
        (state) =>
            state.phase == IntegrationPhase.error && state.failure != null,
      );

      expect(bloc.state.failure, isA<UnknownProviderError>());
      expect(provider.disconnectCalls, 1);
      expect(store.record, isNotNull);
      await bloc.close();
    });

    test('reset clears active account snapshots on sign-out', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cache = LocalSnapshotStore(preferences);
      await cache.write(
        accountId: 'github:octocat',
        namespace: 'profile',
        payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
        schemaVersion: 1,
      );
      final provider = FakeDeveloperProvider(
        connected: true,
        profile: sampleProfile(),
      );
      final bloc = IntegrationBloc(
        provider: provider,
        storeFactory: () async => InMemoryConnectionStore(connectedRecord()),
        snapshotStoreFactory: () async => cache,
      );

      bloc.add(const IntegrationStarted());
      await waitFor(
        bloc,
        (state) =>
            !state.isBusy &&
            state.profile != null &&
            provider.fetchProfileCalls > 0,
      );

      bloc.add(const IntegrationResetRequested());
      await waitFor(
        bloc,
        (state) => state.phase == IntegrationPhase.disconnected,
      );

      expect(
        await cache.read(
          accountId: 'github:octocat',
          namespace: 'profile',
          schemaVersion: 1,
        ),
        isNull,
      );
      await bloc.close();
    });

    test(
      'reset clears persisted account snapshots when sign-out races startup',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final cache = LocalSnapshotStore(preferences);
        await cache.write(
          accountId: 'github:octocat',
          namespace: 'profile',
          payload: ProviderSnapshotCodec.encodeProfile(sampleProfile()),
          schemaVersion: 1,
        );
        final store = InMemoryConnectionStore(connectedRecord());
        final provider = FakeDeveloperProvider(
          connected: true,
          profile: sampleProfile(),
        );
        final bloc = IntegrationBloc(
          provider: provider,
          storeFactory: () async => store,
          snapshotStoreFactory: () async => cache,
        );

        // Queue sign-out before startup has restored the persisted record into
        // IntegrationState, leaving state.connection temporarily null.
        bloc.add(const IntegrationStarted());
        bloc.add(const IntegrationResetRequested());
        await waitFor(
          bloc,
          (state) => state.phase == IntegrationPhase.disconnected,
        );

        expect(store.record, isNull);
        expect(
          await cache.read(
            accountId: 'github:octocat',
            namespace: 'profile',
            schemaVersion: 1,
          ),
          isNull,
        );
        await bloc.close();
      },
    );
  });
}
