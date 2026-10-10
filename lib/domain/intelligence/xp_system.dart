import 'package:equatable/equatable.dart';

import '../entities/developer_activity.dart';

/// Centralized, deterministic XP rules.
///
/// Every XP value lives here so the system can be rebalanced in one place and
/// verified by unit tests. Widgets never contain XP constants.
///
/// Design intent: reward **meaningful contribution**, never spam. Merged pull
/// requests and reviews are worth the most; a push is worth its commit count,
/// capped so a bulk import cannot farm XP; starring a repository is tracked in
/// the timeline but is worth nothing.
class XpRules {
  XpRules._();

  /// XP per commit contained in a push event.
  static const int perCommit = 5;

  /// Maximum commits counted for a single push event (anti-spam cap).
  static const int maxCommitsPerPush = 10;

  static const int pullRequestOpened = 20;
  static const int pullRequestMerged = 50;
  static const int pullRequestClosed = 5;
  static const int pullRequestReviewed = 25;
  static const int issueOpened = 15;
  static const int issueClosed = 30;
  static const int issueCommented = 5;
  static const int repositoryCreated = 40;
  static const int repositoryForked = 15;
  static const int releasePublished = 35;

  /// Starring a repository is not a contribution — tracked, never rewarded.
  static const int starred = 0;

  /// Awarded once per distinct active day (consistency reward).
  static const int activeDay = 10;

  /// XP awarded by a single normalized activity event.
  static int forActivity(DeveloperActivity activity) {
    switch (activity.type) {
      case DeveloperActivityType.commitPushed:
        final commits = activity.commitCount ?? 1;
        return commits.clamp(0, maxCommitsPerPush) * perCommit;
      case DeveloperActivityType.pullRequestOpened:
        return pullRequestOpened;
      case DeveloperActivityType.pullRequestMerged:
        return pullRequestMerged;
      case DeveloperActivityType.pullRequestClosed:
        return pullRequestClosed;
      case DeveloperActivityType.pullRequestReviewed:
        return pullRequestReviewed;
      case DeveloperActivityType.issueOpened:
        return issueOpened;
      case DeveloperActivityType.issueClosed:
        return issueClosed;
      case DeveloperActivityType.issueCommented:
        return issueCommented;
      case DeveloperActivityType.repositoryCreated:
        return repositoryCreated;
      case DeveloperActivityType.repositoryForked:
        return repositoryForked;
      case DeveloperActivityType.releasePublished:
        return releasePublished;
      case DeveloperActivityType.starred:
        return starred;
    }
  }

  /// Base XP for one activity type, ignoring per-event counts (used for docs
  /// and the XP rules panel in the Progress screen).
  static int baseFor(DeveloperActivityType type) {
    switch (type) {
      case DeveloperActivityType.commitPushed:
        return perCommit;
      case DeveloperActivityType.pullRequestOpened:
        return pullRequestOpened;
      case DeveloperActivityType.pullRequestMerged:
        return pullRequestMerged;
      case DeveloperActivityType.pullRequestClosed:
        return pullRequestClosed;
      case DeveloperActivityType.pullRequestReviewed:
        return pullRequestReviewed;
      case DeveloperActivityType.issueOpened:
        return issueOpened;
      case DeveloperActivityType.issueClosed:
        return issueClosed;
      case DeveloperActivityType.issueCommented:
        return issueCommented;
      case DeveloperActivityType.repositoryCreated:
        return repositoryCreated;
      case DeveloperActivityType.repositoryForked:
        return repositoryForked;
      case DeveloperActivityType.releasePublished:
        return releasePublished;
      case DeveloperActivityType.starred:
        return starred;
    }
  }
}

/// XP earned, broken down by source, so the UI can explain where it came from.
///
/// Activity XP is recomputed from the current data window on every
/// computation. Achievement XP is awarded once per achievement and is carried
/// by the persisted [ProgressionRecord], so it survives the window rolling
/// over.
class XpBreakdown extends Equatable {
  /// XP from normalized activity events (keyed by activity type).
  final Map<DeveloperActivityType, int> byActivityType;

  /// XP from normalized activity events.
  final int activityXp;

  /// XP from distinct active days (consistency bonus).
  final int activeDayXp;

  /// XP from unlocked achievements (one-time rewards).
  final int achievementXp;

  /// Total XP: [activityXp] + [activeDayXp] + [achievementXp].
  final int totalXp;

  /// Number of activity events that contributed XP.
  final int eventsCounted;

  const XpBreakdown({
    this.byActivityType = const {},
    this.activityXp = 0,
    this.activeDayXp = 0,
    this.achievementXp = 0,
    this.totalXp = 0,
    this.eventsCounted = 0,
  });

  /// XP from one activity type.
  int xpFor(DeveloperActivityType type) => byActivityType[type] ?? 0;

  @override
  List<Object?> get props => [
    byActivityType,
    activityXp,
    activeDayXp,
    achievementXp,
    totalXp,
    eventsCounted,
  ];
}
