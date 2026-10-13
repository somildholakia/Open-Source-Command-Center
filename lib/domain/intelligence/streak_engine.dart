import 'package:equatable/equatable.dart';

import '../entities/contribution_summary.dart';
import '../entities/developer_activity.dart';

/// Streak statistics for a developer's activity days.
class StreakStats extends Equatable {
  /// Consecutive activity days ending today (or yesterday, if today has no
  /// activity yet — the streak is still considered alive until the day ends).
  final int currentStreak;

  /// Longest consecutive run of activity days in the analyzed window.
  final int longestStreak;

  /// Whether the developer has activity on today's date.
  final bool activeToday;

  /// Most recent activity day (local midnight), or null when there is none.
  final DateTime? lastActivityDate;

  /// Number of distinct activity days in the analyzed window.
  final int activeDays;

  const StreakStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.activeToday = false,
    this.lastActivityDate,
    this.activeDays = 0,
  });

  /// Stable, timezone-independent representation of [lastActivityDate].
  String? get lastActivityDayKey =>
      lastActivityDate == null ? null : StreakEngine.dateKey(lastActivityDate!);

  @override
  List<Object?> get props => [
    currentStreak,
    longestStreak,
    activeToday,
    lastActivityDayKey,
    activeDays,
  ];
}

/// Computes streaks from normalized provider data.
///
/// An **activity day** is a calendar day (in the device's local timezone) with
/// at least one meaningful contribution or normalized activity event. App opens
/// never count.
///
/// Timezone rule: contribution calendar dates are already calendar dates in the
/// user's GitHub timezone and are used verbatim; activity event timestamps are
/// UTC and converted to the device's local date.
///
/// This class also owns the intelligence layer's shared calendar helpers
/// ([dateKey], [dateFromKey], [startOfDay], [mondayOf]) so every engine buckets
/// days exactly the same way.
class StreakEngine {
  StreakEngine._();

  /// `yyyy-MM-dd` key for a [DateTime] in its own (local) zone.
  static String dateKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Parses a `yyyy-MM-dd` key into local midnight, or null when malformed.
  static DateTime? dateFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// Local midnight of the day [value] falls on.
  static DateTime startOfDay(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Local midnight of the Monday that starts [date]'s week.
  static DateTime mondayOf(DateTime date) {
    final local = startOfDay(date);
    return DateTime(local.year, local.month, local.day - (local.weekday - 1));
  }

  /// Local midnight of the day after [date], computed without `Duration`
  /// arithmetic so DST transitions cannot shift the day.
  static DateTime nextDay(DateTime date) {
    final local = startOfDay(date);
    return DateTime(local.year, local.month, local.day + 1);
  }

  /// Union of active date keys from the contribution calendar and the
  /// normalized activity feed.
  ///
  /// The calendar (when available) is the more complete source: it includes
  /// contributions GitHub counts beyond the limited events window.
  static Set<String> activeDateKeys({
    List<DeveloperActivity> activities = const [],
    ContributionSummary? contributions,
  }) {
    final keys = <String>{};
    final counts = contributions?.dailyCounts;
    if (counts != null) {
      for (final entry in counts.entries) {
        if (entry.value > 0) keys.add(entry.key);
      }
    }
    for (final activity in activities) {
      // Stars remain visible in the activity feed, but are not meaningful
      // contributions and must not sustain a streak or earn consistency XP.
      if (activity.type == DeveloperActivityType.starred) continue;
      keys.add(dateKey(activity.timestamp));
    }
    return keys;
  }

  /// Computes [StreakStats] from already-normalized data.
  ///
  /// [now] is injectable so tests are deterministic.
  static StreakStats compute({
    List<DeveloperActivity> activities = const [],
    ContributionSummary? contributions,
    DateTime? now,
  }) {
    return fromActiveDateKeys(
      activeDateKeys(activities: activities, contributions: contributions),
      now: now,
    );
  }

  /// Computes [StreakStats] from a set of active `yyyy-MM-dd` keys.
  static StreakStats fromActiveDateKeys(
    Set<String> activeDateKeys, {
    DateTime? now,
  }) {
    if (activeDateKeys.isEmpty) return const StreakStats();

    final today = startOfDay(now ?? DateTime.now());
    final todayKey = dateKey(today);
    final sorted = activeDateKeys.toList()..sort();

    // --- Longest streak: longest run of consecutive calendar days. ---
    var longest = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      final previous = dateFromKey(sorted[i - 1]);
      final current = dateFromKey(sorted[i]);
      if (previous != null &&
          current != null &&
          _isNextDay(previous, current)) {
        run++;
      } else {
        run = 1;
      }
      if (run > longest) longest = run;
    }

    // --- Current streak: consecutive days ending today or yesterday. ---
    final activeToday = activeDateKeys.contains(todayKey);
    final yesterday = _previousDay(today);
    final activeYesterday = activeDateKeys.contains(dateKey(yesterday));

    var current = 0;
    if (activeToday || activeYesterday) {
      // Walk backwards from today (or yesterday when today is still empty).
      var cursor = activeToday ? today : yesterday;
      while (activeDateKeys.contains(dateKey(cursor))) {
        current++;
        cursor = _previousDay(cursor);
      }
    }

    final lastDate = dateFromKey(sorted.last);

    return StreakStats(
      currentStreak: current,
      longestStreak: longest,
      activeToday: activeToday,
      lastActivityDate: lastDate,
      activeDays: activeDateKeys.length,
    );
  }

  /// Whether [current] is exactly the calendar day after [previous].
  static bool _isNextDay(DateTime previous, DateTime current) {
    final expected = nextDay(previous);
    return current.year == expected.year &&
        current.month == expected.month &&
        current.day == expected.day;
  }

  /// Local midnight of the day before [date], safe across DST transitions.
  static DateTime _previousDay(DateTime date) {
    final local = startOfDay(date);
    return DateTime(local.year, local.month, local.day - 1);
  }
}
