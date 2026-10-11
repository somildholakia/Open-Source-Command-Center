import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/progress/presentation/bloc/intelligence_bloc.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';

class DelayedSaveProgressionStore implements ProgressionStore {
  final InMemoryProgressionStore _delegate = InMemoryProgressionStore();
  final Completer<void> saveStarted = Completer<void>();
  final Completer<void> releaseSave = Completer<void>();
  bool _delayNextSave = true;

  @override
  ProgressionRecord load(String accountId) => _delegate.load(accountId);

  @override
  Future<void> save(String accountId, ProgressionRecord record) async {
    if (_delayNextSave) {
      _delayNextSave = false;
      saveStarted.complete();
      await releaseSave.future;
    }
    await _delegate.save(accountId, record);
  }

  @override
  Future<void> clear(String accountId) => _delegate.clear(accountId);
}

void main() {
  // Thursday 2026-10-08; the current week started Monday 2026-10-05.
  final now = DateTime(2026, 10, 8, 12);
  final syncedAt = DateTime(2026, 10, 8, 11);

  DeveloperActivity activity({
    String id = 'evt-1',
    DeveloperActivityType type = DeveloperActivityType.pullRequestMerged,
    DateTime? at,
    int? commitCount,
  }) {
    return DeveloperActivity(
      id: id,
      type: type,
      repository: 'octocat/command-center',
      title: 'event $id',
      timestamp: at ?? DateTime(2026, 10, 8, 9),
      commitCount: commitCount,
    );
  }

  const contributions = ContributionSummary(
    dailyCounts: {
      '2026-10-05': 1,
      '2026-10-06': 1,
      '2026-10-07': 1,
      '2026-10-08': 1,
    },
  );

  IntelligenceSourceChanged connectedSource({
    String accountId = 'github:octocat',
    List<DeveloperActivity> activities = const [],
    ContributionSummary? withContributions = contributions,
    bool busy = false,
    ProviderFailure? failure,
  }) {
    return IntelligenceSourceChanged(
      accountId: accountId,
      activities: activities,
      contributions: withContributions,
      status: failure == null
          ? IntelligenceSourceStatus.connected
          : IntelligenceSourceStatus.failed,
      busy: busy,
      failure: failure,
      lastSyncedAt: syncedAt,
    );
  }

  AchievementStatus achievementOf(IntelligenceState state, String id) =>
      state.intelligence.achievements.firstWhere((status) => status.id == id);

  Future<void> waitFor(
    IntelligenceBloc bloc,
    bool Function(IntelligenceState state) condition,
  ) async {
    for (var i = 0; i < 50; i++) {
      if (condition(bloc.state)) return;
      await Future<void>.delayed(Duration.zero);
    }
    fail('Timed out waiting for bloc state. Last: ${bloc.state.status}');
  }

  group('initial state', () {
    test('is zeroed, disconnected and presentable', () {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );

      expect(bloc.state.hasData, isFalse);
      expect(bloc.state.connected, isFalse);
      expect(bloc.state.needsConnection, isTrue);
      expect(bloc.state.isStale, isFalse);
      expect(bloc.state.intelligence.level.level, 1);

      bloc.close();
    });

    test('a connected account with no data has no unlocks', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );

      bloc.add(connectedSource(withContributions: null));
      await waitFor(bloc, (state) => state.computedAt != null);

      expect(bloc.state.connected, isTrue);
      expect(bloc.state.hasData, isFalse);
      expect(bloc.state.intelligence.unlockedAchievementCount, 0);

      await bloc.close();
    });
  });

  group('derivation', () {
    test('publishes real XP, level, streak, achievements and quests', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );

      bloc.add(
        connectedSource(
          activities: [
            activity(id: 'merge'),
            activity(
              id: 'commit',
              type: DeveloperActivityType.commitPushed,
              commitCount: 3,
              at: DateTime(2026, 10, 7, 9),
            ),
          ],
        ),
      );
      await waitFor(bloc, (state) => state.computedAt != null);

      final state = bloc.state;
      expect(state.hasData, isTrue);
      expect(state.connected, isTrue);
      expect(state.intelligence.metrics.commits, 3);
      expect(state.intelligence.metrics.pullRequestsMerged, 1);
      expect(state.intelligence.metrics.currentStreak, 4);
      expect(state.intelligence.level.level, greaterThanOrEqualTo(2));
      expect(state.intelligence.xp.totalXp, greaterThan(0));
      expect(state.intelligence.unlockedAchievements, isNotEmpty);
      expect(state.intelligence.quests, isNotEmpty);
      expect(state.lastSyncedAt, syncedAt);
      expect(state.computedAt, now);

      await bloc.close();
    });

    test(
      'persists first-time unlocks and quest completions per account',
      () async {
        final store = InMemoryProgressionStore();
        final bloc = IntelligenceBloc(store, clock: () => now);

        bloc.add(connectedSource(activities: [activity(id: 'merge')]));
        await waitFor(bloc, (state) => state.computedAt != null);

        final saved = store.load('github:octocat');
        expect(saved.isAchievementUnlocked('first_merge'), isTrue);
        expect(saved.unlockedAt('first_merge'), now.toUtc());
        expect(saved.completedQuestKeys, isNotEmpty);
        // Nothing is reported as new once it has been recorded.
        expect(bloc.state.intelligence.newlyUnlockedAchievementIds, isEmpty);
        expect(bloc.state.intelligence.newlyCompletedQuestKeys, isEmpty);

        await bloc.close();
      },
    );

    test('a later session keeps unlocked achievements from history', () async {
      final store = InMemoryProgressionStore();
      await store.save(
        'github:octocat',
        ProgressionRecord.empty.withAchievement(
          'ten_merges',
          DateTime.utc(2026, 9, 1),
        ),
      );

      final bloc = IntelligenceBloc(store, clock: () => now);
      bloc.add(connectedSource(activities: [activity(id: 'merge')]));
      await waitFor(bloc, (state) => state.computedAt != null);

      final tenMerges = achievementOf(bloc.state, 'ten_merges');
      expect(tenMerges.unlocked, isTrue);
      expect(tenMerges.unlockedAt, DateTime.utc(2026, 9, 1));
      expect(
        bloc.state.intelligence.xp.achievementXp,
        greaterThanOrEqualTo(90),
      );

      await bloc.close();
    });

    test(
      'does not publish an old account after switching during save',
      () async {
        final store = DelayedSaveProgressionStore();
        final bloc = IntelligenceBloc(store, clock: () => now);

        bloc.add(connectedSource(activities: [activity(id: 'merge')]));
        await store.saveStarted.future.timeout(const Duration(seconds: 2));

        bloc.add(
          connectedSource(accountId: 'github:mona', withContributions: null),
        );
        await waitFor(bloc, (state) => state.accountId == 'github:mona');

        store.releaseSave.complete();
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.accountId, 'github:mona');
        expect(bloc.state.hasData, isFalse);
        await bloc.close();
      },
    );

    test('progression never leaks between accounts', () async {
      final store = InMemoryProgressionStore();
      final bloc = IntelligenceBloc(store, clock: () => now);

      bloc.add(connectedSource(activities: [activity(id: 'merge')]));
      await waitFor(bloc, (state) => state.computedAt != null);

      bloc.add(
        connectedSource(
          accountId: 'github:someone-else',
          withContributions: null,
        ),
      );
      await waitFor(bloc, (state) => state.accountId == 'github:someone-else');

      expect(achievementOf(bloc.state, 'first_merge').unlocked, isFalse);
      expect(store.load('github:someone-else'), ProgressionRecord.empty);

      await bloc.close();
    });
  });

  group('source status', () {
    test('busy keeps the previous data and flags the refresh', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );
      final activityList = [activity(id: 'merge')];

      bloc.add(connectedSource(activities: activityList));
      await waitFor(bloc, (state) => state.hasData);
      final xpBefore = bloc.state.intelligence.xp;

      bloc.add(connectedSource(activities: activityList, busy: true));
      await waitFor(bloc, (state) => state.busy);

      expect(bloc.state.hasData, isTrue);
      expect(bloc.state.intelligence.xp, xpBefore);
      expect(bloc.state.lastSyncedAt, syncedAt);

      await bloc.close();
    });

    test('a failure with existing data is stale rather than empty', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );
      final activityList = [activity(id: 'merge')];

      bloc.add(connectedSource(activities: activityList));
      await waitFor(bloc, (state) => state.hasData);

      bloc.add(
        connectedSource(
          activities: activityList,
          failure: const NetworkUnavailable(),
        ),
      );
      await waitFor(bloc, (state) => state.failure != null);

      expect(bloc.state.hasData, isTrue);
      expect(bloc.state.isStale, isTrue);
      expect(bloc.state.connected, isTrue);

      await bloc.close();
    });

    test(
      'a failure with no data is an error state, not fake progress',
      () async {
        final bloc = IntelligenceBloc(
          InMemoryProgressionStore(),
          clock: () => now,
        );

        bloc.add(
          connectedSource(
            withContributions: null,
            failure: const ApiUnavailable(statusCode: 503),
          ),
        );
        await waitFor(bloc, (state) => state.failure != null);

        expect(bloc.state.hasData, isFalse);
        expect(bloc.state.isStale, isFalse);
        expect(bloc.state.intelligence.xp.totalXp, 0);
        expect(bloc.state.intelligence.level.level, 1);

        await bloc.close();
      },
    );

    test('expired and disconnected both need a connection', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );

      bloc.add(
        const IntelligenceSourceChanged(
          accountId: 'github:octocat',
          status: IntelligenceSourceStatus.expired,
        ),
      );
      await waitFor(
        bloc,
        (state) => state.status == IntelligenceSourceStatus.expired,
      );

      expect(bloc.state.needsConnection, isTrue);
      expect(bloc.state.hasData, isFalse);

      await bloc.close();
    });
  });

  group('account disconnect', () {
    test(
      'clears one account history without affecting the active account',
      () async {
        final store = InMemoryProgressionStore();
        await store.save(
          'github:octocat',
          ProgressionRecord.empty.withAchievement(
            'first_merge',
            DateTime.utc(2026, 9, 1),
          ),
        );
        await store.save(
          'github:mona',
          ProgressionRecord.empty.withAchievement(
            'ten_merges',
            DateTime.utc(2026, 9, 2),
          ),
        );

        final bloc = IntelligenceBloc(store, clock: () => now);
        bloc.add(
          connectedSource(accountId: 'github:mona', withContributions: null),
        );
        await waitFor(bloc, (state) => state.accountId == 'github:mona');

        bloc.add(const IntelligenceAccountDisconnected('github:octocat'));
        await waitFor(
          bloc,
          (_) => store.load('github:octocat') == ProgressionRecord.empty,
        );

        expect(bloc.state.accountId, 'github:mona');
        expect(
          store.load('github:mona').isAchievementUnlocked('ten_merges'),
          isTrue,
        );

        await bloc.close();
      },
    );
  });

  group('reset', () {
    test('forgets stored history but keeps derived achievements', () async {
      final store = InMemoryProgressionStore();
      await store.save(
        'github:octocat',
        ProgressionRecord.empty
            .withAchievement('ten_merges', DateTime.utc(2026, 9, 1))
            .withQuestCompleted('daily_commit@daily:2026-10-01'),
      );
      final bloc = IntelligenceBloc(store, clock: () => now);

      bloc.add(connectedSource(activities: [activity(id: 'merge')]));
      await waitFor(bloc, (state) => state.hasData);

      expect(achievementOf(bloc.state, 'ten_merges').unlocked, isTrue);
      expect(
        bloc.state.progression.isQuestCompleted(
          'daily_commit@daily:2026-10-01',
        ),
        isTrue,
      );

      bloc.add(const IntelligenceProgressionResetRequested());
      await waitFor(
        bloc,
        (state) => state.progression.unlockedAt('ten_merges') == null,
      );

      // History is gone: an achievement the current data cannot satisfy locks
      // again, while currently satisfied ones are legitimately re-derived.
      expect(achievementOf(bloc.state, 'ten_merges').unlocked, isFalse);
      expect(achievementOf(bloc.state, 'first_merge').unlocked, isTrue);
      expect(
        bloc.state.progression.isQuestCompleted(
          'daily_commit@daily:2026-10-01',
        ),
        isFalse,
      );

      await bloc.close();
    });

    test('is a no-op while disconnected', () async {
      final bloc = IntelligenceBloc(
        InMemoryProgressionStore(),
        clock: () => now,
      );

      bloc.add(const IntelligenceProgressionResetRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.progression, ProgressionRecord.empty);
      expect(bloc.state.computedAt, isNull);

      await bloc.close();
    });
  });
}
