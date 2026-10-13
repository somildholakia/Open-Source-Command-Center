import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

import '../../support/fake_developer_provider.dart';

void main() {
  // Thursday 2026-10-08; the current week started Monday 2026-10-05.
  final now = DateTime(2026, 10, 8, 12);

  DeveloperActivity event({
    required String id,
    required DeveloperActivityType type,
    required DateTime at,
    int? commitCount,
  }) {
    return DeveloperActivity(
      id: id,
      type: type,
      repository: 'octocat/command-center',
      title: 'event $id',
      timestamp: at,
      commitCount: commitCount,
    );
  }

  final activities = [
    event(
      id: 'commit-today',
      type: DeveloperActivityType.commitPushed,
      at: DateTime(2026, 10, 8, 9),
      commitCount: 2,
    ),
    event(
      id: 'merge-today',
      type: DeveloperActivityType.pullRequestMerged,
      at: DateTime(2026, 10, 8, 10),
    ),
    event(
      id: 'review-tuesday',
      type: DeveloperActivityType.pullRequestReviewed,
      at: DateTime(2026, 10, 6, 15),
    ),
    event(
      id: 'review-sunday',
      type: DeveloperActivityType.pullRequestReviewed,
      at: DateTime(2026, 10, 4, 15),
    ),
    event(
      id: 'commit-september',
      type: DeveloperActivityType.commitPushed,
      at: DateTime(2026, 9, 27, 9),
      commitCount: 1,
    ),
  ];

  // The provider contribution calendar: Sunday 10-04 closes the previous week,
  // Monday 10-05 opens the current one, and Wednesday 10-07 is an explicit zero.
  const contributions = ContributionSummary(
    dailyCounts: {
      '2026-09-27': 1,
      '2026-10-01': 2,
      '2026-10-02': 1,
      '2026-10-03': 1,
      '2026-10-04': 1,
      '2026-10-05': 1,
      '2026-10-06': 2,
      '2026-10-07': 0,
      '2026-10-08': 3,
    },
  );

  DeveloperIntelligence compute({
    List<DeveloperActivity>? withActivities,
    ContributionSummary? withContributions = contributions,
    List<Repository> repositories = const [],
    ProgressionRecord progression = ProgressionRecord.empty,
  }) {
    return DeveloperIntelligenceEngine.compute(
      activities: withActivities ?? activities,
      contributions: withContributions,
      repositories: repositories,
      progression: progression,
      now: now,
    );
  }

  group('metrics', () {
    test('counts typed activity across the analyzed window', () {
      final metrics = compute().metrics;

      expect(metrics.commits, 3); // 2 + 1
      expect(metrics.pullRequestsMerged, 1);
      expect(metrics.pullRequestsOpened, 0);
      expect(metrics.reviews, 2);
      expect(metrics.activityEvents, 5);
      expect(metrics.repositories, 0);
      expect(metrics.starsReceived, 0);
    });

    test(
      'uses the provider contribution calendar as the contribution source',
      () {
        final metrics = compute().metrics;

        expect(metrics.totalContributions, 12); // calendar total
        expect(metrics.contributionsToday, 3);
        expect(metrics.eventsToday, 2);
      },
    );

    test(
      'the weekly window includes Monday and excludes the previous Sunday',
      () {
        final intelligence = compute(
          withActivities: const [],
          withContributions: const ContributionSummary(
            dailyCounts: {'2026-10-04': 5, '2026-10-05': 2, '2026-10-08': 1},
          ),
        );

        expect(intelligence.metrics.contributionsThisWeek, 3); // Mon + Thu
        expect(intelligence.metrics.activeDaysThisWeek, 2);
      },
    );

    test('derives streaks from the union of calendar and activity days', () {
      final metrics = compute().metrics;

      expect(metrics.activeDays, 8);
      expect(metrics.currentStreak, 1); // 10-07 has no activity
      expect(metrics.longestStreak, 6); // 10-01 .. 10-06
    });

    test('an empty contribution calendar falls back to activity events', () {
      final intelligence = compute(
        withActivities: [
          event(
            id: 'commit-today',
            type: DeveloperActivityType.commitPushed,
            at: DateTime(2026, 10, 8, 9),
            commitCount: 2,
          ),
          event(
            id: 'merge-today',
            type: DeveloperActivityType.pullRequestMerged,
            at: DateTime(2026, 10, 8, 10),
          ),
          event(
            id: 'star-today',
            type: DeveloperActivityType.starred,
            at: DateTime(2026, 10, 8, 11),
          ),
        ],
        withContributions: const ContributionSummary(dailyCounts: {}),
      );

      expect(intelligence.metrics.totalContributions, 2);
      expect(intelligence.metrics.contributionsToday, 2);
      expect(intelligence.metrics.eventsToday, 3);
    });

    test('invalid and nonpositive calendar counts are ignored', () {
      final intelligence = compute(
        withActivities: const [],
        withContributions: const ContributionSummary(
          dailyCounts: {
            '2026-02-30': 50,
            '2026-10-07': -3,
            '2026-10-08': 2,
          },
        ),
      );

      expect(intelligence.metrics.totalContributions, 2);
      expect(intelligence.metrics.contributionsToday, 2);
      expect(intelligence.metrics.contributionsThisWeek, 2);
      expect(intelligence.metrics.activeDays, 1);
      expect(intelligence.metrics.activeDaysThisWeek, 1);
    });

    test('unknown push size does not count as one commit', () {
      final intelligence = compute(
        withActivities: [
          event(
            id: 'unknown-push',
            type: DeveloperActivityType.commitPushed,
            at: DateTime(2026, 10, 8, 9),
          ),
        ],
        withContributions: null,
      );

      expect(intelligence.metrics.commits, 0);
      expect(intelligence.metrics.totalContributions, 1);
      expect(intelligence.metrics.activityEvents, 1);
    });

    test('a star-only day earns no streak or consistency XP', () {
      final intelligence = compute(
        withActivities: [
          event(
            id: 'star-only',
            type: DeveloperActivityType.starred,
            at: DateTime(2026, 10, 8, 9),
          ),
        ],
        withContributions: null,
      );

      expect(intelligence.metrics.activityEvents, 1);
      expect(intelligence.metrics.totalContributions, 0);
      expect(intelligence.metrics.activeDays, 0);
      expect(intelligence.metrics.activeDaysThisWeek, 0);
      expect(intelligence.metrics.currentStreak, 0);
      expect(intelligence.metrics.eventsToday, 1);
      expect(intelligence.xp.activeDayXp, 0);
      expect(intelligence.xp.xpFor(DeveloperActivityType.starred), 0);
    });

    test('repository stars and counts come from the repository list', () {
      final metrics = compute(
        repositories: [
          sampleRepository(stars: 42),
          sampleRepository(id: '2', name: 'second', stars: 8),
        ],
      ).metrics;

      expect(metrics.repositories, 2);
      expect(metrics.starsReceived, 50);
    });

    test('without a calendar, contributions fall back to activity events', () {
      final intelligence = compute(
        withActivities: [
          event(
            id: 'commit-today',
            type: DeveloperActivityType.commitPushed,
            at: DateTime(2026, 10, 8, 9),
            commitCount: 2,
          ),
          event(
            id: 'merge-today',
            type: DeveloperActivityType.pullRequestMerged,
            at: DateTime(2026, 10, 8, 10),
          ),
          event(
            id: 'star-today',
            type: DeveloperActivityType.starred,
            at: DateTime(2026, 10, 8, 11),
          ),
          event(
            id: 'review-sunday',
            type: DeveloperActivityType.pullRequestReviewed,
            at: DateTime(2026, 10, 4, 15),
          ),
        ],
        withContributions: null,
      );

      expect(intelligence.metrics.totalContributions, 3);
      expect(intelligence.metrics.contributionsToday, 2); // star excluded
      expect(intelligence.metrics.eventsToday, 3);
      expect(intelligence.hasData, isTrue);
    });
  });

  group('XP and levels', () {
    test('adds activity, consistency, achievement, and quest XP', () {
      final intelligence = compute();
      final xp = intelligence.xp;

      expect(xp.activityXp, 115); // 10 + 50 + 25 + 25 + 5
      expect(xp.activeDayXp, 80); // 8 active days * 10
      expect(xp.achievementXp, 115); // 25 + 40 + 50
      expect(xp.questXp, 185); // 25 + 20 + 60 + 80
      expect(xp.totalXp, 495);
      expect(xp.eventsCounted, 5);
      expect(xp.xpFor(DeveloperActivityType.commitPushed), 15);
      expect(xp.xpFor(DeveloperActivityType.pullRequestMerged), 50);
      expect(xp.xpFor(DeveloperActivityType.pullRequestReviewed), 50);
      expect(xp.xpFor(DeveloperActivityType.starred), 0);
    });

    test('resolves total XP into a level', () {
      final level = compute().level;

      expect(level.level, 3);
      expect(level.levelTitle, 'CONTRIBUTOR');
      expect(level.totalXp, 495);
      expect(level.xpIntoLevel, 195);
      expect(level.xpForNextLevel, 300);
      expect(level.xpRemaining, 105);
      expect(level.progress, closeTo(195 / 300, 0.0001));
    });

    test('star achievements fold their reward into total XP', () {
      final intelligence = compute(repositories: [sampleRepository(stars: 42)]);

      expect(intelligence.metrics.starsReceived, 42);
      expect(
        intelligence.achievements
            .firstWhere((status) => status.id == 'star_collector')
            .unlocked,
        isTrue,
      );
      expect(intelligence.xp.achievementXp, 175); // + 60
      expect(intelligence.xp.questXp, 185);
      expect(intelligence.xp.totalXp, 555);
    });
  });

  group('achievements', () {
    test('unlock from metrics and report first-time unlocks', () {
      final intelligence = compute();

      final unlocked = intelligence.unlockedAchievements
          .map((status) => status.id)
          .toSet();
      expect(unlocked, {'first_contribution', 'warm_up', 'first_merge'});
      expect(intelligence.newlyUnlockedAchievementIds, unlocked);
      expect(intelligence.unlockedAchievementCount, 3);
      expect(
        intelligence.achievements
            .firstWhere((status) => status.id == 'first_merge')
            .progress,
        1,
      );
    });

    test('persisted unlocks survive and are not reported as new', () {
      final unlockedAt = DateTime.utc(2026, 9, 1);
      final intelligence = compute(
        progression: ProgressionRecord.empty.withAchievement(
          'first_merge',
          unlockedAt,
        ),
      );

      final merge = intelligence.achievements.firstWhere(
        (status) => status.id == 'first_merge',
      );
      expect(merge.unlocked, isTrue);
      expect(merge.unlockedAt, unlockedAt);
      expect(intelligence.newlyUnlockedAchievementIds, {
        'first_contribution',
        'warm_up',
      });
      expect(intelligence.xp.achievementXp, 115);
    });
  });

  group('quests', () {
    test('evaluate the daily and weekly periods separately', () {
      final quests = {for (final quest in compute().quests) quest.id: quest};

      expect(quests['daily_contribution']!.isCompleted, isTrue);
      expect(quests['daily_commit']!.isCompleted, isTrue);
      expect(quests['daily_commit']!.progress, 1); // capped at the target
      // Tuesday's review is inside the week but not inside today.
      expect(quests['daily_review']!.isCompleted, isFalse);
      expect(quests['weekly_contributions']!.isCompleted, isTrue); // 6 >= 5
      expect(quests['weekly_consistency']!.isCompleted, isTrue); // 3 days
      expect(quests['weekly_pull_requests']!.isCompleted, isFalse);
      expect(quests['weekly_pull_requests']!.progress, 1);
      expect(quests['weekly_issues']!.isCompleted, isFalse);
    });

    test('report completions for the current periods only', () {
      final intelligence = compute();

      expect(intelligence.completedQuestCount, 4);
      expect(intelligence.newlyCompletedQuestKeys, {
        'daily_contribution@daily:2026-10-08',
        'daily_commit@daily:2026-10-08',
        'weekly_contributions@weekly:2026-10-05',
        'weekly_consistency@weekly:2026-10-05',
      });
      expect(intelligence.completedQuests, hasLength(4));
    });

    test('recorded completions survive an empty data window', () {
      final progression = ProgressionRecord.empty
          .withQuestCompleted('daily_review@daily:2026-10-08')
          .withQuestCompleted('weekly_issues@weekly:2026-10-05')
          .withQuestCompleted('daily_commit@daily:2026-10-07');

      final intelligence = compute(
        withActivities: const [],
        withContributions: null,
        progression: progression,
      );

      final quests = {for (final quest in intelligence.quests) quest.id: quest};
      expect(quests['daily_review']!.isCompleted, isTrue);
      expect(quests['weekly_issues']!.isCompleted, isTrue);
      expect(quests['daily_commit']!.isCompleted, isFalse); // new period
      expect(intelligence.completedQuestCount, 3);
      expect(intelligence.xp.questXp, 110); // persisted daily + weekly rewards
      expect(intelligence.newlyCompletedQuestKeys, isEmpty);
    });
  });

  group('empty data', () {
    test('produces a zeroed, presentable intelligence', () {
      final intelligence = compute(
        withActivities: const [],
        withContributions: null,
      );

      expect(intelligence.hasData, isFalse);
      expect(intelligence.metrics, const DeveloperMetrics());
      expect(intelligence.xp.totalXp, 0);
      expect(intelligence.level.level, 1);
      expect(intelligence.level.levelTitle, 'NOVICE');
      expect(intelligence.unlockedAchievementCount, 0);
      expect(intelligence.completedQuestCount, 0);
      expect(
        intelligence.quests.every(
          (quest) => quest.state == QuestState.available,
        ),
        isTrue,
      );
    });
  });
}
