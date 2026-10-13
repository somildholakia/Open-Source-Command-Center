import 'package:equatable/equatable.dart';

import '../entities/contribution_summary.dart';
import '../entities/developer_activity.dart';
import '../entities/repository.dart';

import 'achievement.dart';
import 'achievement_catalog.dart';
import 'developer_metrics.dart';
import 'level_system.dart';
import 'progression_record.dart';
import 'quest.dart';
import 'quest_catalog.dart';
import 'streak_engine.dart';
import 'xp_system.dart';

/// Resolved, deterministic developer intelligence derived from normalized data.
///
/// Built by [DeveloperIntelligenceEngine]. Widgets present it as-is; nothing
/// here touches Flutter, the network, or storage — and no widget computes XP,
/// levels, streaks or progress of its own.
class DeveloperIntelligence extends Equatable {
  final DeveloperMetrics metrics;
  final XpBreakdown xp;
  final LevelProgress level;
  final StreakStats streak;

  /// Every achievement with its status, in catalog order.
  final List<AchievementStatus> achievements;

  /// Quests for the periods active at computation time, daily first.
  final List<QuestProgress> quests;

  /// Achievements unlocked for the first time by this computation; the owner
  /// of the persisted [ProgressionRecord] records them so they never re-lock.
  final Set<String> newlyUnlockedAchievementIds;

  /// Quest instances completed for the first time by this computation.
  final Set<String> newlyCompletedQuestKeys;

  const DeveloperIntelligence({
    required this.metrics,
    required this.xp,
    required this.level,
    required this.streak,
    required this.achievements,
    required this.quests,
    this.newlyUnlockedAchievementIds = const {},
    this.newlyCompletedQuestKeys = const {},
  });

  /// Whether any real provider data backed this computation.
  bool get hasData => metrics.hasData;

  List<AchievementStatus> get unlockedAchievements =>
      achievements.where((status) => status.unlocked).toList(growable: false);

  int get unlockedAchievementCount =>
      achievements.where((status) => status.unlocked).length;

  List<QuestProgress> get completedQuests =>
      quests.where((quest) => quest.isCompleted).toList(growable: false);

  /// Quest instances completed across all time (derived plus persisted).
  int get completedQuestCount => metrics.completedQuestCount;

  @override
  List<Object?> get props => [
    metrics,
    xp,
    level,
    streak,
    achievements,
    quests,
    newlyUnlockedAchievementIds,
    newlyCompletedQuestKeys,
  ];
}

/// Engine that resolves normalized provider data into developer intelligence.
///
/// Pure Dart: no Flutter, no storage, no network. Callers feed it the exact
/// normalized data they already hold and pass the persisted [ProgressionRecord]
/// back in, so the result is reproducible from the same inputs.
class DeveloperIntelligenceEngine {
  DeveloperIntelligenceEngine._();

  /// Resolves the intelligence for one session.
  ///
  /// [now] is injectable so tests are deterministic.
  static DeveloperIntelligence compute({
    required List<DeveloperActivity> activities,
    ContributionSummary? contributions,
    List<Repository> repositories = const [],
    ProgressionRecord progression = ProgressionRecord.empty,
    DateTime? now,
  }) {
    final nowLocal = (now ?? DateTime.now()).toLocal();
    final today = StreakEngine.startOfDay(nowLocal);
    final weekStart = StreakEngine.mondayOf(today);

    final streak = StreakEngine.compute(
      activities: activities,
      contributions: contributions,
      now: nowLocal,
    );

    final todayWindow = _windowedCounts(
      activities: activities,
      contributions: contributions,
      from: today,
      to: today,
    );
    final weekWindow = _windowedCounts(
      activities: activities,
      contributions: contributions,
      from: weekStart,
      to: today,
    );

    final questEvaluation = _evaluateQuests(
      todayWindow: todayWindow,
      weekWindow: weekWindow,
      now: nowLocal,
      progression: progression,
    );

    final metrics = _computeMetrics(
      activities: activities,
      contributions: contributions,
      repositories: repositories,
      streak: streak,
      todayWindow: todayWindow,
      weekWindow: weekWindow,
      completedQuestCount: questEvaluation.completedCount,
    );

    final achievements = _evaluateAchievements(
      metrics: metrics,
      progression: progression,
    );
    final achievementXp = achievements.fold<int>(
      0,
      (sum, status) => status.unlocked ? sum + status.xpReward : sum,
    );

    final xp = _computeXp(
      activities: activities,
      activeDays: metrics.activeDays,
      achievementXp: achievementXp,
      questXp: _questXp(
        progression.completedQuestKeys,
        questEvaluation.newlyCompletedKeys,
      ),
    );

    return DeveloperIntelligence(
      metrics: metrics,
      xp: xp,
      level: LevelSystem.compute(xp.totalXp),
      streak: streak,
      achievements: achievements,
      quests: questEvaluation.quests,
      newlyUnlockedAchievementIds: achievements
          .where((status) => status.unlocked && status.unlockedAt == null)
          .map((status) => status.id)
          .toSet(),
      newlyCompletedQuestKeys: questEvaluation.newlyCompletedKeys,
    );
  }

  // --- Metrics ------------------------------------------------------------

  static DeveloperMetrics _computeMetrics({
    required List<DeveloperActivity> activities,
    required ContributionSummary? contributions,
    required List<Repository> repositories,
    required StreakStats streak,
    required ActivityWindow todayWindow,
    required ActivityWindow weekWindow,
    required int completedQuestCount,
  }) {
    var commits = 0;
    var pullRequestsOpened = 0;
    var pullRequestsMerged = 0;
    var pullRequestsClosed = 0;
    var reviews = 0;
    var issuesOpened = 0;
    var issuesClosed = 0;
    var issueComments = 0;
    var repositoriesCreated = 0;
    var repositoriesForked = 0;
    var releasesPublished = 0;

    for (final activity in activities) {
      switch (activity.type) {
        case DeveloperActivityType.commitPushed:
          // A push event is not necessarily one commit. Count only the
          // commit total GitHub actually supplied; unknown sizes must not
          // unlock commit-count achievements as if they were one commit.
          commits += activity.commitCount ?? 0;
          break;
        case DeveloperActivityType.pullRequestOpened:
          pullRequestsOpened++;
          break;
        case DeveloperActivityType.pullRequestMerged:
          pullRequestsMerged++;
          break;
        case DeveloperActivityType.pullRequestClosed:
          pullRequestsClosed++;
          break;
        case DeveloperActivityType.pullRequestReviewed:
          reviews++;
          break;
        case DeveloperActivityType.issueOpened:
          issuesOpened++;
          break;
        case DeveloperActivityType.issueClosed:
          issuesClosed++;
          break;
        case DeveloperActivityType.issueCommented:
          issueComments++;
          break;
        case DeveloperActivityType.repositoryCreated:
          repositoriesCreated++;
          break;
        case DeveloperActivityType.repositoryForked:
          repositoriesForked++;
          break;
        case DeveloperActivityType.releasePublished:
          releasesPublished++;
          break;
        case DeveloperActivityType.starred:
          break;
      }
    }

    var starsReceived = 0;
    for (final repository in repositories) {
      starsReceived += repository.stars ?? 0;
    }

    return DeveloperMetrics(
      // An empty calendar means the provider supplied no usable calendar
      // data. Fall back to normalized events rather than presenting a false
      // zero or suppressing contribution quests.
      totalContributions:
          contributions != null && contributions.dailyCounts.isNotEmpty
          ? contributions.total
          : _contributionEventCount(activities),
      activeDays: streak.activeDays,
      commits: commits,
      pullRequestsOpened: pullRequestsOpened,
      pullRequestsMerged: pullRequestsMerged,
      pullRequestsClosed: pullRequestsClosed,
      reviews: reviews,
      issuesOpened: issuesOpened,
      issuesClosed: issuesClosed,
      issueComments: issueComments,
      repositoriesCreated: repositoriesCreated,
      repositoriesForked: repositoriesForked,
      releasesPublished: releasesPublished,
      repositories: repositories.length,
      starsReceived: starsReceived,
      activityEvents: activities.length,
      contributionsToday: todayWindow.contributions,
      contributionsThisWeek: weekWindow.contributions,
      eventsToday: todayWindow.events,
      activeDaysThisWeek: weekWindow.activeDays,
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      completedQuestCount: completedQuestCount,
    );
  }

  // --- XP -----------------------------------------------------------------

  static XpBreakdown _computeXp({
    required List<DeveloperActivity> activities,
    required int activeDays,
    required int achievementXp,
    required int questXp,
  }) {
    final byActivityType = <DeveloperActivityType, int>{};
    var activityXp = 0;
    var eventsCounted = 0;

    for (final activity in activities) {
      final xp = XpRules.forActivity(activity);
      if (xp <= 0) continue;
      activityXp += xp;
      eventsCounted++;
      byActivityType[activity.type] = (byActivityType[activity.type] ?? 0) + xp;
    }

    final activeDayXp = activeDays * XpRules.activeDay;

    return XpBreakdown(
      byActivityType: byActivityType,
      activityXp: activityXp,
      activeDayXp: activeDayXp,
      achievementXp: achievementXp,
      questXp: questXp,
      totalXp: activityXp + activeDayXp + achievementXp + questXp,
      eventsCounted: eventsCounted,
    );
  }

  /// Rewards each completed quest instance once, including persisted history.
  /// Unknown/retired quest IDs are ignored rather than assigned guessed XP.
  static int _questXp(
    Set<String> recordedKeys,
    Set<String> newlyCompletedKeys,
  ) {
    final completedKeys = {...recordedKeys, ...newlyCompletedKeys};
    final rewardsById = {
      for (final quest in QuestCatalog.all) quest.id: quest.xpReward,
    };
    var total = 0;
    for (final key in completedKeys) {
      final separator = key.indexOf('@');
      if (separator <= 0) continue;
      total += rewardsById[key.substring(0, separator)] ?? 0;
    }
    return total;
  }

  // --- Achievements -------------------------------------------------------

  static List<AchievementStatus> _evaluateAchievements({
    required DeveloperMetrics metrics,
    required ProgressionRecord progression,
  }) {
    return AchievementCatalog.all
        .map((definition) {
          final unlockedAt = progression.unlockedAt(definition.id);
          return AchievementStatus(
            definition: definition,
            unlocked: unlockedAt != null || definition.isUnlocked(metrics),
            unlockedAt: unlockedAt,
            progress: definition.progress(metrics),
          );
        })
        .toList(growable: false);
  }

  // --- Quests -------------------------------------------------------------

  static _QuestEvaluation _evaluateQuests({
    required ActivityWindow todayWindow,
    required ActivityWindow weekWindow,
    required DateTime now,
    required ProgressionRecord progression,
  }) {
    final quests = <QuestProgress>[];
    final newlyCompleted = <String>{};

    for (final definition in QuestCatalog.all) {
      final window = definition.period == QuestPeriod.daily
          ? todayWindow
          : weekWindow;
      final periodKey = definition.periodKey(now);
      final recorded = progression.isQuestCompleted(periodKey);
      final observed = definition.selector(window);
      final completed = recorded || observed >= definition.target;
      if (completed && !recorded) newlyCompleted.add(periodKey);

      quests.add(
        QuestProgress(
          definition: definition,
          state: completed ? QuestState.completed : QuestState.available,
          progress: completed
              ? definition.target
              : definition.progressIn(window),
          periodKey: periodKey,
          periodEndsAt: definition.periodEndsAt(now),
        ),
      );
    }

    return _QuestEvaluation(
      quests: List.unmodifiable(quests),
      newlyCompletedKeys: newlyCompleted,
      completedCount: progression.completedQuestCount + newlyCompleted.length,
    );
  }

  // --- Windowing ----------------------------------------------------------

  /// Counts contributions and activity events between [from] and [to]
  /// (inclusive local days).
  ///
  /// Contribution counts come from the provider calendar when it exists — it is
  /// the source of truth for contributions and already contains PRs, issues and
  /// reviews, so activity events are not added on top. Without a calendar,
  /// normalized contribution events are counted instead (starring a repository
  /// is activity, not a contribution). Typed counts always come from activity
  /// events, and an active day is any day with either source.
  static ActivityWindow _windowedCounts({
    required List<DeveloperActivity> activities,
    required ContributionSummary? contributions,
    required DateTime from,
    required DateTime to,
  }) {
    final activeDays = <String>{};

    var calendarContributions = 0;
    final dailyCounts = contributions?.dailyCounts;
    if (dailyCounts != null) {
      for (final entry in dailyCounts.entries) {
        final date = StreakEngine.dateFromKey(entry.key);
        if (date == null) continue;
        if (date.isBefore(from) || date.isAfter(to)) continue;
        calendarContributions += entry.value;
        if (entry.value > 0) activeDays.add(entry.key);
      }
    }

    final eventsByDay = <String, List<DeveloperActivity>>{};
    for (final activity in activities) {
      final day = StreakEngine.startOfDay(activity.timestamp);
      if (day.isBefore(from) || day.isAfter(to)) continue;
      eventsByDay
          .putIfAbsent(StreakEngine.dateKey(day), () => [])
          .add(activity);
    }

    var contributionsInWindow = calendarContributions;
    // A missing or empty calendar is unavailable data, not proof that the
    // developer made zero contributions during this window.
    if (dailyCounts == null || dailyCounts.isEmpty) {
      for (final events in eventsByDay.values) {
        for (final event in events) {
          if (event.type != DeveloperActivityType.starred) {
            contributionsInWindow++;
          }
        }
      }
    }

    var events = 0;
    var commits = 0;
    var pullRequestsOpened = 0;
    var pullRequestsMerged = 0;
    var reviews = 0;
    var issuesClosed = 0;

    for (final entry in eventsByDay.entries) {
      if (entry.value.any(
        (activity) => activity.type != DeveloperActivityType.starred,
      )) {
        activeDays.add(entry.key);
      }
      for (final activity in entry.value) {
        events++;
        switch (activity.type) {
          case DeveloperActivityType.commitPushed:
            commits += activity.commitCount ?? 0;
            break;
          case DeveloperActivityType.pullRequestOpened:
            pullRequestsOpened++;
            break;
          case DeveloperActivityType.pullRequestMerged:
            pullRequestsMerged++;
            break;
          case DeveloperActivityType.pullRequestReviewed:
            reviews++;
            break;
          case DeveloperActivityType.issueClosed:
            issuesClosed++;
            break;
          case DeveloperActivityType.issueOpened:
          case DeveloperActivityType.issueCommented:
          case DeveloperActivityType.repositoryCreated:
          case DeveloperActivityType.repositoryForked:
          case DeveloperActivityType.releasePublished:
          case DeveloperActivityType.starred:
          case DeveloperActivityType.pullRequestClosed:
            break;
        }
      }
    }

    return ActivityWindow(
      contributions: contributionsInWindow,
      events: events,
      commits: commits,
      pullRequestsOpened: pullRequestsOpened,
      pullRequestsMerged: pullRequestsMerged,
      reviews: reviews,
      issuesClosed: issuesClosed,
      activeDays: activeDays.length,
    );
  }

  /// Contribution events across the whole activity window, used only when the
  /// provider supplied no contribution calendar.
  static int _contributionEventCount(List<DeveloperActivity> activities) {
    var count = 0;
    for (final activity in activities) {
      if (activity.type != DeveloperActivityType.starred) count++;
    }
    return count;
  }
}

/// Intermediate quest evaluation result.
class _QuestEvaluation {
  final List<QuestProgress> quests;
  final Set<String> newlyCompletedKeys;
  final int completedCount;

  const _QuestEvaluation({
    required this.quests,
    required this.newlyCompletedKeys,
    required this.completedCount,
  });
}
