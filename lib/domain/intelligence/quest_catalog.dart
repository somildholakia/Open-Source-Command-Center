import 'quest.dart';

/// Daily and weekly quests, all deterministically evaluated from normalized
/// data the provider can actually supply.
///
/// The catalog is the single source of quest truth: adding a quest means adding
/// one entry here. Evaluation lives in `DeveloperIntelligenceEngine`.
class QuestCatalog {
  QuestCatalog._();

  /// All quests, daily first. Selectors read the evaluated window only, so
  /// daily quests cannot see the week and vice versa.
  static final List<QuestDefinition> all = List.unmodifiable([
    // --- Daily ---
    QuestDefinition(
      id: 'daily_contribution',
      title: 'Daily Contribution',
      description: 'Make 1 contribution today.',
      period: QuestPeriod.daily,
      icon: QuestIcon.commit,
      xpReward: 25,
      target: 1,
      selector: (window) => window.contributions,
    ),
    QuestDefinition(
      id: 'daily_commit',
      title: 'Daily Commit',
      description: 'Push 1 commit today.',
      period: QuestPeriod.daily,
      icon: QuestIcon.commit,
      xpReward: 20,
      target: 1,
      selector: (window) => window.commits,
    ),
    QuestDefinition(
      id: 'daily_review',
      title: 'Daily Review',
      description: 'Leave 1 pull request review today.',
      period: QuestPeriod.daily,
      icon: QuestIcon.review,
      xpReward: 40,
      target: 1,
      selector: (window) => window.reviews,
    ),

    // --- Weekly ---
    QuestDefinition(
      id: 'weekly_contributions',
      title: 'Week Contributions',
      description: 'Make 5 contributions this week.',
      period: QuestPeriod.weekly,
      icon: QuestIcon.calendar,
      xpReward: 60,
      target: 5,
      selector: (window) => window.contributions,
    ),
    QuestDefinition(
      id: 'weekly_consistency',
      title: 'Weekly Consistency',
      description: 'Be active on 3 different days this week.',
      period: QuestPeriod.weekly,
      icon: QuestIcon.trendingUp,
      xpReward: 80,
      target: 3,
      selector: (window) => window.activeDays,
    ),
    QuestDefinition(
      id: 'weekly_pull_requests',
      title: 'Week Pull Requests',
      description: 'Open or merge 2 pull requests this week.',
      period: QuestPeriod.weekly,
      icon: QuestIcon.merge,
      xpReward: 70,
      target: 2,
      selector: (window) =>
          window.pullRequestsOpened + window.pullRequestsMerged,
    ),
    QuestDefinition(
      id: 'weekly_issues',
      title: 'Bug Sweeper',
      description: 'Close 1 issue this week.',
      period: QuestPeriod.weekly,
      icon: QuestIcon.star,
      xpReward: 50,
      target: 1,
      selector: (window) => window.issuesClosed,
    ),
  ]);
}
