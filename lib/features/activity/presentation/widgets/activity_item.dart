import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../domain/domain.dart';
import 'activity_type_badge.dart';

/// Model representing a single activity item for presentation.
///
/// Built either from normalized domain activity ([ActivityItemData.fromDomain])
/// or from local sample data (Phase 1 preview). Provider payloads never reach
/// this model.
class ActivityItemData {
  final ActivityType type;
  final String title;
  final String? subtitle;
  final String repository;
  final String? identifier; // PR/Issue number or commit hash
  final String timestamp;

  const ActivityItemData({
    required this.type,
    required this.title,
    this.subtitle,
    required this.repository,
    this.identifier,
    required this.timestamp,
  });

  /// Maps a normalized [DeveloperActivity] into presentation data.
  ///
  /// Timestamps are rendered with [formatTimeAgo]; [now] is injectable so
  /// tests get deterministic copy.
  factory ActivityItemData.fromDomain(
    DeveloperActivity activity, {
    DateTime? now,
  }) {
    return ActivityItemData(
      type: activityTypeFromDomain(activity.type),
      title: activity.title,
      subtitle: activity.subtitle,
      repository: activity.repository,
      identifier: activity.identifier,
      timestamp: formatTimeAgo(activity.timestamp, now: now),
    );
  }
}

/// Maps a domain activity type to its presentation counterpart.
ActivityType activityTypeFromDomain(DeveloperActivityType type) {
  switch (type) {
    case DeveloperActivityType.commitPushed:
      return ActivityType.commitPushed;
    case DeveloperActivityType.pullRequestOpened:
      return ActivityType.pullRequestOpened;
    case DeveloperActivityType.pullRequestClosed:
      return ActivityType.pullRequestClosed;
    case DeveloperActivityType.pullRequestMerged:
      return ActivityType.pullRequestMerged;
    case DeveloperActivityType.pullRequestReviewed:
      return ActivityType.pullRequestReviewed;
    case DeveloperActivityType.issueOpened:
      return ActivityType.issueOpened;
    case DeveloperActivityType.issueClosed:
      return ActivityType.issueClosed;
    case DeveloperActivityType.issueCommented:
      return ActivityType.issueCommented;
    case DeveloperActivityType.repositoryCreated:
      return ActivityType.repositoryCreated;
    case DeveloperActivityType.repositoryForked:
      return ActivityType.repositoryForked;
    case DeveloperActivityType.releasePublished:
      return ActivityType.releasePublished;
    case DeveloperActivityType.starred:
      return ActivityType.starred;
  }
}

/// Timeline-style activity feed item card.
///
/// Displays:
/// - Timeline connector (left edge)
/// - Activity type badge
/// - Activity title and details
/// - Repository name (monospace)
/// - Timestamp
///
/// Phase 1: Presentation-only component with mock data.
class ActivityItem extends StatelessWidget {
  final ActivityItemData data;
  final bool showTimelineConnector;
  final bool isFirst;
  final bool isLast;

  const ActivityItem({
    super.key,
    required this.data,
    this.showTimelineConnector = true,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector column
        if (showTimelineConnector) _buildTimelineConnector(context),

        // Activity card content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(
              bottom: isLast ? 0 : AppSpacing.activityItemGap,
            ),
            padding: AppSpacing.cardPaddingInsets,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: data.type.color(context).withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: badge + type label + timestamp
                Row(
                  children: [
                    ActivityTypeBadge(type: data.type),
                    AppSpacing.hSpaceSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.type.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: data.type.color(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            data.timestamp,
                            style: AppTypography.captionSmall.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceXs,

                // Activity title
                Text(
                  data.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Optional subtitle
                if (data.subtitle != null) ...[
                  AppSpacing.vSpaceXxs,
                  Text(
                    data.subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                AppSpacing.vSpaceXs,

                // Repository and identifier row
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    Text(
                      data.repository,
                      style: AppTypography.monoSmall.copyWith(
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    if (data.identifier != null) ...[
                      Text(
                        '•',
                        style: AppTypography.captionSmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      Text(
                        data.identifier!,
                        style: AppTypography.monoSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the timeline connector visual (left edge line and dot).
  Widget _buildTimelineConnector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: AppSpacing.xl,
      child: Column(
        children: [
          // Top line connector (hidden for first item)
          if (!isFirst)
            Container(
              width: 2,
              height: AppSpacing.sm,
              color: colorScheme.outline,
            ),

          // Timeline dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: data.type.color(context),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 2),
            ),
          ),

          // Bottom line connector (hidden for last item)
          if (!isLast) Container(width: 2, color: colorScheme.outline),
        ],
      ),
    );
  }
}
