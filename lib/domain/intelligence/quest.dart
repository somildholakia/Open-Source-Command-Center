import 'package:equatable/equatable.dart';

import 'developer_metrics.dart';
import 'streak_engine.dart';

/// Period for a quest: the window used to evaluate progress.
enum QuestPeriod {
  /// Evaluates the current local day.
  daily,

  /// Evaluates the current local Monday–Sunday week.
  weekly,
}

/// Visual icon key for a quest. Presentation maps this to an icon.
enum QuestIcon { calendar, commit, merge, review, trendingUp, star }

/// One quest definition.
///
/// Criteria are declarative and evaluate deterministically from a single
/// [ActivityWindow], so a quest can be checked in tests without any provider or
/// clock involved. Weekly windows run Monday through today; daily windows cover
/// today only.
class QuestDefinition {
  final String id;
  final String title;
  final String description;
  final QuestPeriod period;
  final QuestIcon icon;

  /// XP awarded once per completed period.
  final int xpReward;

  /// Requirement value the selector must reach inside the period.
  final int target;

  /// How the requirement value is derived from the evaluated window.
  final int Function(ActivityWindow window) selector;

  const QuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.period,
    required this.icon,
    required this.xpReward,
    required this.target,
    required this.selector,
  });

  /// Requirement progress inside [window], capped at [target].
  int progressIn(ActivityWindow window) {
    final observed = selector(window);
    if (observed < 0) return 0;
    return observed > target ? target : observed;
  }

  /// Whether [window] satisfies the quest.
  bool isCompletedIn(ActivityWindow window) => selector(window) >= target;

  /// Unique key for the quest instance active at [now].
  ///
  /// Daily quests are keyed by the local date and weekly quests by the local
  /// Monday, so a completion in one period never counts toward another.
  String periodKey(DateTime now) {
    final local = now.toLocal();
    final anchor = period == QuestPeriod.daily
        ? local
        : local.subtract(Duration(days: local.weekday - 1));
    return '$id@${period.name}:${StreakEngine.dateKey(anchor)}';
  }

  /// Local time at which the quest instance active at [now] rolls over
  /// (exclusive end of the period).
  DateTime periodEndsAt(DateTime now) {
    final local = now.toLocal();
    if (period == QuestPeriod.daily) {
      return DateTime(local.year, local.month, local.day + 1);
    }
    return DateTime(
      local.year,
      local.month,
      local.day - (local.weekday - 1) + 7,
    );
  }
}

/// Result of evaluating one quest at a point in time.
class QuestProgress extends Equatable {
  final QuestDefinition definition;
  final QuestState state;

  /// Requirement value inside the period, capped at [definition.target].
  final int progress;

  /// Key of the evaluated period (see [QuestDefinition.periodKey]).
  final String periodKey;

  /// Local time at which this period rolls over.
  final DateTime periodEndsAt;

  const QuestProgress({
    required this.definition,
    required this.state,
    required this.progress,
    required this.periodKey,
    required this.periodEndsAt,
  });

  String get id => definition.id;
  int get target => definition.target;
  int get xpReward => definition.xpReward;
  bool get isCompleted => state == QuestState.completed;
  double get progressRatio =>
      target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0).toDouble();

  @override
  List<Object?> get props => [
    definition.id,
    state,
    progress,
    periodKey,
    periodEndsAt,
  ];
}

/// Lifecycle state of a quest instance (one period of one quest).
enum QuestState {
  /// Inside the period, target not reached yet.
  available,

  /// Target reached inside the period, or recorded as completed earlier.
  completed,
}
