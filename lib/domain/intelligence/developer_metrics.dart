import 'package:equatable/equatable.dart';

/// Activity counts for one time window (e.g. today, the current week).
///
/// Windows are derived from normalized provider data only; a window over a day
/// with no activity has [active] == false.
class ActivityWindow extends Equatable {
  /// Contributions credited inside the window: the provider contribution
  /// calendar when available, otherwise normalized contribution events.
  final int contributions;

  /// Normalized activity events inside the window.
  final int events;

  final int commits;
  final int pullRequestsOpened;
  final int pullRequestsMerged;
  final int reviews;
  final int issuesClosed;

  /// Distinct days in the window with at least one contribution or event.
  final int activeDays;

  const ActivityWindow({
    this.contributions = 0,
    this.events = 0,
    this.commits = 0,
    this.pullRequestsOpened = 0,
    this.pullRequestsMerged = 0,
    this.reviews = 0,
    this.issuesClosed = 0,
    this.activeDays = 0,
  });

  bool get active => activeDays > 0;

  /// Pull requests opened or merged inside the window.
  int get pullRequests => pullRequestsOpened + pullRequestsMerged;

  @override
  List<Object?> get props => [
    contributions,
    events,
    commits,
    pullRequestsOpened,
    pullRequestsMerged,
    reviews,
    issuesClosed,
    activeDays,
  ];
}

/// Provider-independent metrics derived from normalized developer data.
///
/// Every field is counted from data the provider actually returned — nothing is
/// estimated. Counts a provider cannot supply stay at 0, and the UI labels
/// preview/sample data explicitly.
class DeveloperMetrics extends Equatable {
  /// Contributions in the analyzed window: the provider contribution calendar
  /// total when available, otherwise the count of normalized contribution
  /// events.
  final int totalContributions;

  /// Distinct days with at least one contribution or activity event.
  final int activeDays;

  final int commits;
  final int pullRequestsOpened;
  final int pullRequestsMerged;
  final int pullRequestsClosed;
  final int reviews;
  final int issuesOpened;
  final int issuesClosed;
  final int issueComments;
  final int repositoriesCreated;
  final int repositoriesForked;
  final int releasesPublished;

  /// Repositories visible to the connected account (0 when unconnected).
  final int repositories;

  /// Total stars across the developer's repositories.
  final int starsReceived;

  /// Normalized activity events analyzed (the provider events window).
  final int activityEvents;

  /// Contributions on the current local day.
  final int contributionsToday;

  /// Contributions since the start of the current local week (Monday).
  final int contributionsThisWeek;

  /// Activity events on the current local day.
  final int eventsToday;

  /// Distinct active days in the current local week (Monday through today).
  final int activeDaysThisWeek;

  /// Consecutive active days ending today — or yesterday, when today is still
  /// empty (the streak stays alive until the day ends).
  final int currentStreak;

  /// Longest consecutive run of active days in the analyzed window.
  final int longestStreak;

  /// Quest instances completed across all time (derived plus persisted
  /// history; see [ProgressionRecord]).
  final int completedQuestCount;

  const DeveloperMetrics({
    this.totalContributions = 0,
    this.activeDays = 0,
    this.commits = 0,
    this.pullRequestsOpened = 0,
    this.pullRequestsMerged = 0,
    this.pullRequestsClosed = 0,
    this.reviews = 0,
    this.issuesOpened = 0,
    this.issuesClosed = 0,
    this.issueComments = 0,
    this.repositoriesCreated = 0,
    this.repositoriesForked = 0,
    this.releasesPublished = 0,
    this.repositories = 0,
    this.starsReceived = 0,
    this.activityEvents = 0,
    this.contributionsToday = 0,
    this.contributionsThisWeek = 0,
    this.eventsToday = 0,
    this.activeDaysThisWeek = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.completedQuestCount = 0,
  });

  /// Pull requests opened or merged (the number users think of as "PRs").
  int get pullRequests => pullRequestsOpened + pullRequestsMerged;

  /// Issues the developer resolved.
  int get issuesSolved => issuesClosed;

  /// Whether any real provider data backed these metrics.
  bool get hasData =>
      activityEvents > 0 || totalContributions > 0 || repositories > 0;

  @override
  List<Object?> get props => [
    totalContributions,
    activeDays,
    commits,
    pullRequestsOpened,
    pullRequestsMerged,
    pullRequestsClosed,
    reviews,
    issuesOpened,
    issuesClosed,
    issueComments,
    repositoriesCreated,
    repositoriesForked,
    releasesPublished,
    repositories,
    starsReceived,
    activityEvents,
    contributionsToday,
    contributionsThisWeek,
    eventsToday,
    activeDaysThisWeek,
    currentStreak,
    longestStreak,
    completedQuestCount,
  ];
}
