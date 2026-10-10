import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Activity type categories for the feed.
///
/// Presentation-side counterpart of the domain `DeveloperActivityType`
/// (see `activity_item.dart` for the mapping).
enum ActivityType {
  pullRequestOpened,
  pullRequestMerged,
  pullRequestClosed,
  pullRequestReviewed,
  issueOpened,
  issueClosed,
  issueCommented,
  commitPushed,
  reviewRequested,
  mentionReceived,
  repositoryCreated,
  repositoryForked,
  releasePublished,
  starred,
}

/// Feed filters offered by the Activity header.
enum ActivityFilter { all, pullRequests, issues, commits, reviews }

/// Display metadata for [ActivityFilter].
extension ActivityFilterMetadata on ActivityFilter {
  /// Chip label.
  String get label {
    switch (this) {
      case ActivityFilter.all:
        return 'All';
      case ActivityFilter.pullRequests:
        return 'PRs';
      case ActivityFilter.issues:
        return 'Issues';
      case ActivityFilter.commits:
        return 'Commits';
      case ActivityFilter.reviews:
        return 'Reviews';
    }
  }

  /// Whether an activity of [type] belongs to this filter.
  bool matches(ActivityType type) {
    switch (this) {
      case ActivityFilter.all:
        return true;
      case ActivityFilter.pullRequests:
        return type == ActivityType.pullRequestOpened ||
            type == ActivityType.pullRequestMerged ||
            type == ActivityType.pullRequestClosed;
      case ActivityFilter.issues:
        return type == ActivityType.issueOpened ||
            type == ActivityType.issueClosed ||
            type == ActivityType.issueCommented;
      case ActivityFilter.commits:
        return type == ActivityType.commitPushed;
      case ActivityFilter.reviews:
        return type == ActivityType.pullRequestReviewed;
    }
  }

  /// Accent color for the chip; null uses the theme primary.
  Color? get accent {
    switch (this) {
      case ActivityFilter.all:
        return null;
      case ActivityFilter.pullRequests:
        return AppColors.pullRequestAccent;
      case ActivityFilter.issues:
        return AppColors.issueAccent;
      case ActivityFilter.commits:
        return AppColors.commitAccent;
      case ActivityFilter.reviews:
        return AppColors.reviewAccent;
    }
  }
}

/// Extension providing display metadata for each activity type.
extension ActivityTypeMetadata on ActivityType {
  /// Human-readable label for the activity type.
  String get label {
    switch (this) {
      case ActivityType.pullRequestOpened:
        return 'PR Opened';
      case ActivityType.pullRequestMerged:
        return 'PR Merged';
      case ActivityType.pullRequestClosed:
        return 'PR Closed';
      case ActivityType.pullRequestReviewed:
        return 'PR Reviewed';
      case ActivityType.issueOpened:
        return 'Issue Opened';
      case ActivityType.issueClosed:
        return 'Issue Closed';
      case ActivityType.issueCommented:
        return 'Issue Comment';
      case ActivityType.commitPushed:
        return 'Commit';
      case ActivityType.reviewRequested:
        return 'Review Request';
      case ActivityType.mentionReceived:
        return 'Mention';
      case ActivityType.repositoryCreated:
        return 'Repo Created';
      case ActivityType.repositoryForked:
        return 'Forked';
      case ActivityType.releasePublished:
        return 'Release';
      case ActivityType.starred:
        return 'Starred';
    }
  }

  /// Icon representing the activity type.
  IconData get icon {
    switch (this) {
      case ActivityType.pullRequestOpened:
        return Icons.merge_type_rounded;
      case ActivityType.pullRequestMerged:
        return Icons.check_circle_rounded;
      case ActivityType.pullRequestClosed:
        return Icons.cancel_rounded;
      case ActivityType.pullRequestReviewed:
        return Icons.rate_review_rounded;
      case ActivityType.issueOpened:
        return Icons.error_outline_rounded;
      case ActivityType.issueClosed:
        return Icons.check_circle_outline_rounded;
      case ActivityType.issueCommented:
        return Icons.comment_rounded;
      case ActivityType.commitPushed:
        return Icons.commit_rounded;
      case ActivityType.reviewRequested:
        return Icons.visibility_rounded;
      case ActivityType.mentionReceived:
        return Icons.alternate_email_rounded;
      case ActivityType.repositoryCreated:
        return Icons.create_new_folder_rounded;
      case ActivityType.repositoryForked:
        return Icons.call_split_rounded;
      case ActivityType.releasePublished:
        return Icons.new_releases_rounded;
      case ActivityType.starred:
        return Icons.star_rounded;
    }
  }

  /// Color representing the activity type (from design system).
  /// Takes BuildContext to resolve theme-aware colors that stay readable
  /// in both dark and light themes.
  Color color(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case ActivityType.pullRequestOpened:
        return AppColors.pullRequestAccent;
      case ActivityType.pullRequestMerged:
        return AppColors.mergedAccent;
      case ActivityType.pullRequestClosed:
        return AppColors.closedAccent;
      case ActivityType.pullRequestReviewed:
        return AppColors.reviewAccent;
      case ActivityType.issueOpened:
        return AppColors.issueAccent;
      case ActivityType.issueClosed:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
      case ActivityType.issueCommented:
        return AppColors.infoAccent;
      case ActivityType.commitPushed:
        return AppColors.commitAccent;
      case ActivityType.reviewRequested:
        return AppColors.warningAccent;
      case ActivityType.mentionReceived:
        return AppColors.accentPink;
      case ActivityType.repositoryCreated:
        return colorScheme.primary;
      case ActivityType.repositoryForked:
        return AppColors.secondaryAccent;
      case ActivityType.releasePublished:
        return AppColors.successAccent;
      case ActivityType.starred:
        return AppColors.achievementAccent;
    }
  }
}

/// Badge component displaying the type of activity with icon and color coding.
///
/// Used in activity feed items to visually categorize events.
/// Phase 1: Presentation-only component establishing visual language.
class ActivityTypeBadge extends StatelessWidget {
  final ActivityType type;
  final double size;

  const ActivityTypeBadge({
    super.key,
    required this.type,
    this.size = AppSpacing.iconSizeMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + AppSpacing.sm,
      height: size + AppSpacing.sm,
      decoration: BoxDecoration(
        color: type.color(context).withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: type.color(context).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Icon(type.icon, color: type.color(context), size: size * 0.7),
    );
  }
}
