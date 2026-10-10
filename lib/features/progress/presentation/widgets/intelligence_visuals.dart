import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/domain.dart';

/// Presentation mapping for the intelligence layer.
///
/// Domain engines describe *what* an achievement or quest is (an
/// [AchievementIcon], a [QuestPeriod]); this file decides how it looks. Keeping
/// the mapping here means the engines stay icon-free and the theme stays the
/// only place colors are chosen from.

IconData achievementIconData(AchievementIcon icon) => switch (icon) {
  AchievementIcon.star => Icons.star_rounded,
  AchievementIcon.flame => Icons.local_fire_department_rounded,
  AchievementIcon.merge => Icons.merge_type_rounded,
  AchievementIcon.monitor => Icons.rate_review_rounded,
  AchievementIcon.build => Icons.build_rounded,
  AchievementIcon.bugReport => Icons.bug_report_rounded,
  AchievementIcon.rocket => Icons.rocket_launch_rounded,
  AchievementIcon.treasure => Icons.workspace_premium_rounded,
  AchievementIcon.badge => Icons.military_tech_rounded,
};

IconData questIconData(QuestIcon icon) => switch (icon) {
  QuestIcon.calendar => Icons.calendar_month_rounded,
  QuestIcon.commit => Icons.commit_rounded,
  QuestIcon.merge => Icons.merge_type_rounded,
  QuestIcon.review => Icons.rate_review_rounded,
  QuestIcon.trendingUp => Icons.trending_up_rounded,
  QuestIcon.star => Icons.star_rounded,
};

/// Accent color for an achievement category (theme-resolved).
Color achievementAccent(AchievementCategory category) => switch (category) {
  AchievementCategory.contribution => AppColors.primaryAccent,
  AchievementCategory.consistency => AppColors.streakAccent,
  AchievementCategory.pullRequest => AppColors.pullRequestAccent,
  AchievementCategory.review => AppColors.reviewAccent,
  AchievementCategory.repository => AppColors.commitAccent,
  AchievementCategory.issue => AppColors.issueAccent,
  AchievementCategory.milestone => AppColors.achievementAccent,
  AchievementCategory.quest => AppColors.questAccent,
};

/// Accent color for a quest period (theme-resolved).
Color questAccent(QuestPeriod period) => switch (period) {
  QuestPeriod.daily => AppColors.primaryAccent,
  QuestPeriod.weekly => AppColors.secondaryAccent,
};

/// Short chip label for a quest period.
String questPeriodLabel(QuestPeriod period) => switch (period) {
  QuestPeriod.daily => 'DAILY',
  QuestPeriod.weekly => 'WEEKLY',
};

/// Human label for an activity type, used by the XP breakdown.
String activityTypeLabel(DeveloperActivityType type) => switch (type) {
  DeveloperActivityType.commitPushed => 'Commits',
  DeveloperActivityType.pullRequestOpened => 'Pull requests opened',
  DeveloperActivityType.pullRequestClosed => 'Pull requests closed',
  DeveloperActivityType.pullRequestMerged => 'Pull requests merged',
  DeveloperActivityType.pullRequestReviewed => 'Reviews',
  DeveloperActivityType.issueOpened => 'Issues opened',
  DeveloperActivityType.issueClosed => 'Issues closed',
  DeveloperActivityType.issueCommented => 'Issue comments',
  DeveloperActivityType.repositoryCreated => 'Repositories created',
  DeveloperActivityType.repositoryForked => 'Repositories forked',
  DeveloperActivityType.releasePublished => 'Releases',
  DeveloperActivityType.starred => 'Stars',
};
