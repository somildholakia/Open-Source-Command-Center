import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

/// Builds metrics where only the field used by [achievementId] is set.
DeveloperMetrics metricsForValue(String achievementId, int value) {
  switch (achievementId) {
    case 'first_contribution':
    case 'century_club':
      return DeveloperMetrics(totalContributions: value);
    case 'commit_machine':
      return DeveloperMetrics(commits: value);
    case 'warm_up':
    case 'week_storm':
      return DeveloperMetrics(longestStreak: value);
    case 'first_pull_request':
      return DeveloperMetrics(pullRequestsOpened: value);
    case 'first_merge':
    case 'ten_merges':
      return DeveloperMetrics(pullRequestsMerged: value);
    case 'trusted_reviewer':
      return DeveloperMetrics(reviews: value);
    case 'first_issue':
      return DeveloperMetrics(issuesOpened: value);
    case 'problem_solver':
      return DeveloperMetrics(issuesClosed: value);
    case 'first_repository':
      return DeveloperMetrics(repositoriesCreated: value);
    case 'star_collector':
      return DeveloperMetrics(starsReceived: value);
    case 'release_engineer':
      return DeveloperMetrics(releasesPublished: value);
    case 'quest_master':
      return DeveloperMetrics(completedQuestCount: value);
    default:
      fail('No metrics mapping for achievement "$achievementId"');
  }
}

void main() {
  final catalog = AchievementCatalog.all;

  group('catalog shape', () {
    test('is non-empty and every id is unique', () {
      expect(catalog, isNotEmpty);
      final ids = catalog.map((definition) => definition.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every definition is presentable and worth unlocking', () {
      for (final definition in catalog) {
        expect(definition.title, isNotEmpty, reason: definition.id);
        expect(definition.description, isNotEmpty, reason: definition.id);
        expect(definition.target, greaterThan(0), reason: definition.id);
        expect(definition.xpReward, greaterThan(0), reason: definition.id);
      }
    });

    test('a brand new developer has unlocked nothing', () {
      const empty = DeveloperMetrics();

      for (final definition in catalog) {
        expect(definition.isUnlocked(empty), isFalse, reason: definition.id);
        expect(definition.progress(empty), 0, reason: definition.id);
        expect(definition.cappedProgress(empty), 0, reason: definition.id);
      }
    });

    test('every definition is actually unlockable at its target', () {
      for (final definition in catalog) {
        final atTarget = metricsForValue(definition.id, definition.target);
        expect(
          definition.isUnlocked(atTarget),
          isTrue,
          reason: '${definition.id} should unlock at ${definition.target}',
        );
        expect(
          definition.cappedProgress(atTarget),
          definition.target,
          reason: definition.id,
        );
      }
    });

    test('no definition unlocks one point below its target', () {
      for (final definition in catalog) {
        final below = metricsForValue(definition.id, definition.target - 1);
        expect(
          definition.isUnlocked(below),
          isFalse,
          reason:
              '${definition.id} must not unlock at ${definition.target - 1}',
        );
        expect(definition.cappedProgress(below), definition.target - 1);
      }
    });
  });

  group('progress reporting', () {
    test('progress can exceed the target and is capped for bars', () {
      final century = catalog.firstWhere((d) => d.id == 'century_club');
      const metrics = DeveloperMetrics(totalContributions: 150);

      expect(century.progress(metrics), 150);
      expect(century.cappedProgress(metrics), 100);
      expect(century.isUnlocked(metrics), isTrue);
    });

    test('negative selectors are reported as zero', () {
      final definition = AchievementDefinition(
        id: 'test',
        title: 'Test',
        description: 'Test',
        category: AchievementCategory.milestone,
        icon: AchievementIcon.badge,
        xpReward: 10,
        target: 1,
        selector: (metrics) => -5,
      );

      expect(definition.progress(const DeveloperMetrics()), 0);
      expect(definition.isUnlocked(const DeveloperMetrics()), isFalse);
    });
  });

  group('AchievementStatus', () {
    test('ratio is capped at 1.0 and unlockedAt defaults to null', () {
      final definition = catalog.firstWhere(
        (d) => d.id == 'first_contribution',
      );
      final status = AchievementStatus(
        definition: definition,
        unlocked: true,
        progress: 5,
      );

      expect(status.id, 'first_contribution');
      expect(status.cappedProgress, definition.target);
      expect(status.progressRatio, 1.0);
      expect(status.xpReward, definition.xpReward);
      expect(status.unlockedAt, isNull);
    });

    test('unlockedAt is carried through for persisted unlocks', () {
      final at = DateTime.utc(2026, 9, 1);
      final status = AchievementStatus(
        definition: catalog.first,
        unlocked: true,
        progress: 3,
        unlockedAt: at,
      );

      expect(status.unlockedAt, at);
    });

    test('progress that is zero still yields a zero ratio', () {
      final status = AchievementStatus(
        definition: catalog.first,
        unlocked: false,
        progress: 0,
      );

      expect(status.progressRatio, 0.0);
    });
  });
}
