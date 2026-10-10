import 'package:equatable/equatable.dart';

import 'developer_metrics.dart';

/// Declarative category for an achievement — drives icons and theming, not
/// behaviour.
enum AchievementCategory {
  contribution,
  consistency,
  pullRequest,
  review,
  repository,
  issue,
  milestone,
  quest,
}

/// Visual icon key for an achievement. Presentation maps this to an icon.
enum AchievementIcon {
  star,
  flame,
  merge,
  monitor,
  build,
  bugReport,
  rocket,
  treasure,
  badge,
}

/// One achievement definition.
///
/// Criteria are declarative so the condition is readable, testable, and never
/// duplicated in UI. Adding an achievement means adding one entry to
/// [AchievementCatalog] — no other code changes.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final AchievementIcon icon;

  /// XP awarded once, when the achievement is first unlocked.
  final int xpReward;

  /// Requirement value the selector must reach.
  final int target;

  /// How the requirement value is derived from developer metrics.
  final int Function(DeveloperMetrics metrics) selector;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.xpReward,
    required this.selector,
    required this.target,
  });

  /// Observed requirement value (may exceed [target]).
  int progress(DeveloperMetrics metrics) {
    final observed = selector(metrics);
    return observed < 0 ? 0 : observed;
  }

  /// Progress capped at [target], for progress bars.
  int cappedProgress(DeveloperMetrics metrics) {
    final observed = progress(metrics);
    return observed > target ? target : observed;
  }

  /// Unlocked when the requirement is met.
  bool isUnlocked(DeveloperMetrics metrics) => progress(metrics) >= target;
}

/// Evaluation of one achievement at a point in time.
class AchievementStatus extends Equatable {
  final AchievementDefinition definition;

  /// Whether the achievement is unlocked — by the current data window or by
  /// persisted history.
  final bool unlocked;

  /// Observed requirement value (may exceed [definition.target]).
  final int progress;

  /// When the achievement was first unlocked, when known.
  ///
  /// Null while an unlock is only derived from the current data window; the
  /// owner of the progression record persists it so achievements never re-lock
  /// when old activity scrolls out of the provider's window.
  final DateTime? unlockedAt;

  const AchievementStatus({
    required this.definition,
    required this.unlocked,
    required this.progress,
    this.unlockedAt,
  });

  String get id => definition.id;
  int get target => definition.target;
  int get xpReward => definition.xpReward;
  int get cappedProgress =>
      progress > target ? target : (progress < 0 ? 0 : progress);
  double get progressRatio =>
      target <= 0 ? 0.0 : (cappedProgress / target).toDouble();

  @override
  List<Object?> get props => [definition.id, unlocked, progress, unlockedAt];
}
