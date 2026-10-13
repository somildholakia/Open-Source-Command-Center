import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

void main() {
  // 2026-10-05 is a Monday.
  final monday = DateTime(2026, 10, 5, 12);

  group('StreakEngine.dateKey', () {
    test('formats zero-padded calendar days', () {
      expect(StreakEngine.dateKey(DateTime(2026, 1, 9)), '2026-01-09');
      expect(
        StreakEngine.dateKey(DateTime(2026, 12, 31, 23, 59)),
        '2026-12-31',
      );
    });

    test('round-trips through dateFromKey', () {
      expect(StreakEngine.dateFromKey('2026-10-05'), DateTime(2026, 10, 5));
      expect(StreakEngine.dateFromKey('nope'), isNull);
      expect(StreakEngine.dateFromKey('2026-10'), isNull);
      expect(StreakEngine.dateFromKey('2026-xx-05'), isNull);
    });
  });

  group('StreakEngine.activeDateKeys', () {
    test('ignores calendar days that are explicitly zero', () {
      final keys = StreakEngine.activeDateKeys(
        contributions: const ContributionSummary(
          dailyCounts: {'2026-10-04': 0, '2026-10-05': 2},
        ),
      );

      expect(keys, {'2026-10-05'});
    });

    test('unions the calendar with activity event days', () {
      final keys = StreakEngine.activeDateKeys(
        activities: [
          DeveloperActivity(
            id: 'a',
            type: DeveloperActivityType.commitPushed,
            repository: 'octocat/x',
            title: 'commit',
            timestamp: DateTime(2026, 10, 3, 9),
          ),
        ],
        contributions: const ContributionSummary(
          dailyCounts: {'2026-10-05': 4},
        ),
      );

      expect(keys, {'2026-10-03', '2026-10-05'});
    });

    test('stars alone do not count as an active contribution day', () {
      final keys = StreakEngine.activeDateKeys(
        activities: [
          DeveloperActivity(
            id: 'star',
            type: DeveloperActivityType.starred,
            repository: 'octocat/x',
            title: 'star',
            timestamp: DateTime(2026, 10, 8, 9),
          ),
        ],
      );

      expect(keys, isEmpty);
    });
  });

  group('StreakEngine.fromActiveDateKeys', () {
    test('empty data has no streak at all', () {
      final stats = StreakEngine.fromActiveDateKeys(const {});

      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
      expect(stats.activeToday, isFalse);
      expect(stats.activeDays, 0);
      expect(stats.lastActivityDate, isNull);
      expect(stats.lastActivityDayKey, isNull);
    });

    test('a single active day builds a streak of one', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-10-05',
      }, now: monday);

      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 1);
      expect(stats.activeToday, isTrue);
      expect(stats.activeDays, 1);
      expect(stats.lastActivityDate, DateTime(2026, 10, 5));
    });

    test('counts consecutive days ending today', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-10-03',
        '2026-10-04',
        '2026-10-05',
      }, now: monday);

      expect(stats.currentStreak, 3);
      expect(stats.longestStreak, 3);
      expect(stats.activeToday, isTrue);
    });

    test('keeps the streak alive when today has no activity yet', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-10-02',
        '2026-10-03',
        '2026-10-04',
      }, now: monday);

      expect(stats.currentStreak, 3);
      expect(stats.activeToday, isFalse);
    });

    test('breaks the current streak after a full missed day', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-10-01',
        '2026-10-02',
      }, now: monday);

      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 2);
      expect(stats.activeDays, 2);
      expect(stats.lastActivityDate, DateTime(2026, 10, 2));
    });

    test('longest streak can be older than the current one', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-09-01',
        '2026-09-02',
        '2026-09-03',
        '2026-09-04',
        '2026-10-05',
      }, now: monday);

      expect(stats.currentStreak, 1);
      expect(stats.longestStreak, 4);
    });

    test('runs continue across month boundaries', () {
      final stats = StreakEngine.fromActiveDateKeys({
        '2026-09-29',
        '2026-09-30',
        '2026-10-01',
      }, now: DateTime(2026, 10, 1, 8));

      expect(stats.longestStreak, 3);
      expect(stats.currentStreak, 3);
    });

    test('duplicate keys across sources still count one active day', () {
      final stats = StreakEngine.compute(
        activities: [
          DeveloperActivity(
            id: 'a',
            type: DeveloperActivityType.commitPushed,
            repository: 'octocat/x',
            title: 'commit',
            timestamp: DateTime(2026, 10, 4, 22),
          ),
        ],
        contributions: const ContributionSummary(
          dailyCounts: {'2026-10-04': 1},
        ),
        now: monday,
      );

      expect(stats.activeDays, 1);
      expect(stats.currentStreak, 1);
    });
  });

  group('calendar helpers', () {
    test('mondayOf returns the Monday of the current week', () {
      expect(
        StreakEngine.mondayOf(DateTime(2026, 10, 5, 23, 30)),
        DateTime(2026, 10, 5),
      );
      expect(
        StreakEngine.mondayOf(DateTime(2026, 10, 11, 6)),
        DateTime(2026, 10, 5),
      );
    });

    test('nextDay crosses month and year boundaries', () {
      expect(
        StreakEngine.nextDay(DateTime(2026, 9, 30)),
        DateTime(2026, 10, 1),
      );
      expect(
        StreakEngine.nextDay(DateTime(2026, 12, 31)),
        DateTime(2027, 1, 1),
      );
    });
  });
}
