import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

/// Builds a window where only the field used by [questId] is set.
ActivityWindow windowForValue(String questId, int value) {
  switch (questId) {
    case 'daily_contribution':
    case 'weekly_contributions':
      return ActivityWindow(contributions: value);
    case 'daily_commit':
      return ActivityWindow(commits: value);
    case 'daily_review':
      return ActivityWindow(reviews: value);
    case 'weekly_consistency':
      return ActivityWindow(activeDays: value);
    case 'weekly_pull_requests':
      return ActivityWindow(pullRequestsOpened: value);
    case 'weekly_issues':
      return ActivityWindow(issuesClosed: value);
    default:
      fail('No window mapping for quest "$questId"');
  }
}

void main() {
  final catalog = QuestCatalog.all;
  // 2026-10-05 is a Monday; 2026-10-08 is the Thursday of the same week.
  final monday = DateTime(2026, 10, 5, 12);
  final thursday = DateTime(2026, 10, 8, 12);

  group('catalog shape', () {
    test('ids are unique and cover both periods', () {
      final ids = catalog.map((quest) => quest.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(
        catalog.where((q) => q.period == QuestPeriod.daily),
        isNotEmpty,
      );
      expect(
        catalog.where((q) => q.period == QuestPeriod.weekly),
        isNotEmpty,
      );
    });

    test('every quest is presentable and worth completing', () {
      for (final quest in catalog) {
        expect(quest.title, isNotEmpty, reason: quest.id);
        expect(quest.description, isNotEmpty, reason: quest.id);
        expect(quest.target, greaterThan(0), reason: quest.id);
        expect(quest.xpReward, greaterThan(0), reason: quest.id);
      }
    });

    test('nothing is completed by an empty window', () {
      const empty = ActivityWindow();

      for (final quest in catalog) {
        expect(quest.isCompletedIn(empty), isFalse, reason: quest.id);
        expect(quest.progressIn(empty), 0, reason: quest.id);
      }
    });

    test('every quest completes exactly at its target', () {
      for (final quest in catalog) {
        expect(
          quest.isCompletedIn(windowForValue(quest.id, quest.target)),
          isTrue,
          reason: quest.id,
        );
        expect(
          quest.isCompletedIn(windowForValue(quest.id, quest.target - 1)),
          isFalse,
          reason: quest.id,
        );
      }
    });

    test('progress is capped at the target', () {
      for (final quest in catalog) {
        expect(
          quest.progressIn(windowForValue(quest.id, quest.target * 4)),
          quest.target,
          reason: quest.id,
        );
      }
    });
  });

  group('period keys', () {
    test('daily quests are keyed by the local date', () {
      final quest = catalog.firstWhere((q) => q.id == 'daily_commit');

      expect(quest.periodKey(thursday), 'daily_commit@daily:2026-10-08');
    });

    test('weekly quests are keyed by the local Monday of the week', () {
      final quest = catalog.firstWhere((q) => q.id == 'weekly_consistency');

      expect(thursday.weekday, DateTime.thursday);
      expect(quest.periodKey(thursday), 'weekly_consistency@weekly:2026-10-05');
      expect(quest.periodKey(monday), 'weekly_consistency@weekly:2026-10-05');
      // Sunday belongs to the week that started the previous Monday.
      expect(
        quest.periodKey(DateTime(2026, 10, 11, 23)),
        'weekly_consistency@weekly:2026-10-05',
      );
    });

    test('a completion in one period never collides with another', () {
      final quest = catalog.firstWhere((q) => q.id == 'daily_commit');

      expect(quest.periodKey(monday), isNot(quest.periodKey(thursday)));
    });
  });

  group('period rollover', () {
    test('daily quests roll over at the next local midnight', () {
      final quest = catalog.firstWhere((q) => q.id == 'daily_commit');

      expect(quest.periodEndsAt(thursday), DateTime(2026, 10, 9));
    });

    test('weekly quests roll over the following Monday', () {
      final quest = catalog.firstWhere((q) => q.id == 'weekly_consistency');

      expect(quest.periodEndsAt(thursday), DateTime(2026, 10, 12));
      expect(quest.periodEndsAt(monday), DateTime(2026, 10, 12));
    });
  });

  group('QuestProgress', () {
    test('exposes definition data and a clamped ratio', () {
      final definition = catalog.firstWhere((q) => q.id == 'weekly_issues');
      final progress = QuestProgress(
        definition: definition,
        state: QuestState.completed,
        progress: 50,
        periodKey: definition.periodKey(thursday),
        periodEndsAt: definition.periodEndsAt(thursday),
      );

      expect(progress.id, 'weekly_issues');
      expect(progress.target, definition.target);
      expect(progress.xpReward, definition.xpReward);
      expect(progress.isCompleted, isTrue);
      expect(progress.progressRatio, 1.0);
    });

    test('an available quest reports a partial ratio', () {
      final definition = catalog.firstWhere((q) => q.id == 'weekly_issues');
      final progress = QuestProgress(
        definition: definition,
        state: QuestState.available,
        progress: 0,
        periodKey: definition.periodKey(thursday),
        periodEndsAt: definition.periodEndsAt(thursday),
      );

      expect(progress.isCompleted, isFalse);
      expect(progress.progressRatio, 0.0);
    });
  });
}
