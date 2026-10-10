import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_calendar.dart';

void main() {
  group('ContributionDayData.level', () {
    test('maps counts to documented intensity levels', () {
      int levelFor(int count) =>
          ContributionDayData(date: DateTime(2026, 10, 1), count: count).level;

      expect(levelFor(0), 0);
      expect(levelFor(1), 1);
      expect(levelFor(2), 1);
      expect(levelFor(3), 2);
      expect(levelFor(5), 2);
      expect(levelFor(6), 3);
      expect(levelFor(9), 3);
      expect(levelFor(10), 4);
      expect(levelFor(150), 4);
    });
  });

  group('ContributionDayData.weeksFromSummary', () {
    test('builds four Monday-first weeks ending with the current week', () {
      // Thursday 1 October 2026.
      final now = DateTime(2026, 10, 1, 15, 30);
      final summary = ContributionSummary(
        dailyCounts: const {
          '2026-09-28': 2, // Monday of the current week
          '2026-09-30': 5, // Wednesday
          '2026-09-20': 1, // Sunday of the previous week
        },
        fetchedAt: now,
      );

      final weeks = ContributionDayData.weeksFromSummary(summary, now: now);

      expect(weeks, hasLength(4));
      for (final week in weeks) {
        expect(week, hasLength(7));
      }

      // Each row starts on a Monday and ends on a Sunday.
      for (final week in weeks) {
        expect(week.first.date.weekday, DateTime.monday);
        expect(week.last.date.weekday, DateTime.sunday);
      }

      // Rows are consecutive weeks.
      expect(weeks[1].first.date.difference(weeks[0].first.date).inDays, 7);

      // The final row contains today.
      final lastWeek = weeks.last;
      expect(
        lastWeek.any(
          (day) =>
              day.date.year == now.year &&
              day.date.month == now.month &&
              day.date.day == now.day,
        ),
        isTrue,
      );

      // Counts come from the summary, zero-filled elsewhere.
      final currentWeek = weeks.last;
      expect(currentWeek.first.count, 2);
      expect(currentWeek[2].count, 5);
      expect(currentWeek[4].count, 0);
      // Sunday 2026-09-20 falls in the week before the current one.
      expect(weeks[1].last.date, DateTime(2026, 9, 20));
      expect(weeks[1].last.count, 1);
    });

    test('zero-fills future days in the current week', () {
      final now = DateTime(2026, 10, 1); // Thursday
      final weeks = ContributionDayData.weeksFromSummary(
        ContributionSummary(dailyCounts: const {}, fetchedAt: now),
        now: now,
      );

      final lastWeek = weeks.last;
      // Friday/Saturday/Sunday of the current week are in the future: they
      // must read as zero rather than as missing data.
      expect(lastWeek[4].count, 0);
      expect(lastWeek[6].count, 0);
      expect(lastWeek[6].date.isAfter(now), isTrue);
    });
  });
}
