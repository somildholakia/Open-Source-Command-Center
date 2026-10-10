import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../domain/domain.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';

/// High-level developer metrics grid.
///
/// Phase 2: when GitHub is connected, values are counted from the normalized
/// activity feed loaded by [IntegrationBloc] (the most recent public events
/// GitHub exposes). The caption states the window so the numbers are never
/// presented as all-time totals. When disconnected, values are placeholders
/// and the caption points at the connect CTA.
class StatsOverviewGrid extends StatelessWidget {
  const StatsOverviewGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntegrationBloc, IntegrationState>(
      builder: (context, state) {
        final connected = state.isConnected;
        final activities = state.activities;
        final hasActivity = activities.isNotEmpty;
        final syncing = connected && state.isLoadingData && !hasActivity;

        final stats = _Stats.fromActivities(activities);

        final String caption;
        if (!connected) {
          caption = 'CONNECT GITHUB';
        } else if (syncing) {
          caption = 'SYNCING…';
        } else if (!hasActivity) {
          caption = 'NO RECENT EVENTS';
        } else {
          caption = 'LAST ${activities.length} EVENTS';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TELEMETRY SNAPSHOT',
                    style: AppTypography.labelLarge.copyWith(
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSpacing.hSpaceXs,
                Text(
                  caption,
                  style: AppTypography.captionSmall.copyWith(
                    color: connected && hasActivity
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            AppSpacing.vSpaceSm,
            ResponsiveGrid(
              compactColumns: 2,
              mobileColumns: 2,
              tabletColumns: 4,
              desktopColumns: 4,
              spacing: AppSpacing.sm,
              childAspectRatio: 1.45,
              children: [
                _StatCard(
                  label: 'Pull Requests',
                  value: hasActivity ? '${stats.pullRequests}' : '—',
                  icon: Icons.merge_type_rounded,
                  accentColor: AppColors.pullRequest,
                ),
                _StatCard(
                  label: 'Issues Solved',
                  value: hasActivity ? '${stats.issuesSolved}' : '—',
                  icon: Icons.adjust_rounded,
                  accentColor: AppColors.issue,
                ),
                _StatCard(
                  label: 'Commits',
                  value: hasActivity ? '${stats.commits}' : '—',
                  icon: Icons.commit_rounded,
                  accentColor: AppColors.commit,
                ),
                _StatCard(
                  label: 'Code Reviews',
                  value: hasActivity ? '${stats.reviews}' : '—',
                  icon: Icons.rate_review_rounded,
                  accentColor: AppColors.review,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Counts derived from the normalized activity feed.
class _Stats {
  final int pullRequests;
  final int issuesSolved;
  final int commits;
  final int reviews;

  const _Stats({
    required this.pullRequests,
    required this.issuesSolved,
    required this.commits,
    required this.reviews,
  });

  factory _Stats.fromActivities(List<DeveloperActivity> activities) {
    var pullRequests = 0;
    var issuesSolved = 0;
    var commits = 0;
    var reviews = 0;

    for (final activity in activities) {
      switch (activity.type) {
        case DeveloperActivityType.pullRequestOpened:
        case DeveloperActivityType.pullRequestClosed:
        case DeveloperActivityType.pullRequestMerged:
          pullRequests++;
        case DeveloperActivityType.issueClosed:
          issuesSolved++;
        case DeveloperActivityType.commitPushed:
          // Only count commits the provider actually reported a count for;
          // never invent a number.
          commits += activity.commitCount ?? 0;
        case DeveloperActivityType.pullRequestReviewed:
          reviews++;
        case DeveloperActivityType.issueOpened:
        case DeveloperActivityType.issueCommented:
        case DeveloperActivityType.repositoryCreated:
        case DeveloperActivityType.repositoryForked:
        case DeveloperActivityType.releasePublished:
        case DeveloperActivityType.starred:
          break;
      }
    }

    return _Stats(
      pullRequests: pullRequests,
      issuesSolved: issuesSolved,
      commits: commits,
      reviews: reviews,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTypography.statsValue.copyWith(
                  fontSize: 22,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusXs,
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: AppSpacing.iconSizeSmall,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
