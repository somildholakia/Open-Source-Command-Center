import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../domain/domain.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';
import '../../../progress/presentation/widgets/intelligence_visuals.dart';

/// Milestone strip for the Activity screen.
///
/// Turns the timeline into a progress story: what happened on GitHub today and
/// this week, the current streak, and the achievement the developer is closest
/// to unlocking. All values are derived metrics — nothing here is estimated.
///
/// Renders nothing until real provider data exists, so the Activity screen
/// never shows invented milestones.
class ActivityMilestonesCard extends StatelessWidget {
  const ActivityMilestonesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      buildWhen: (previous, current) =>
          previous.hasData != current.hasData ||
          previous.intelligence.metrics != current.intelligence.metrics ||
          previous.intelligence.achievements != current.intelligence.achievements,
      builder: (context, state) {
        if (!state.hasData) return const SizedBox.shrink();

        final metrics = state.intelligence.metrics;
        final streak = state.intelligence.streak;
        final nextUnlock = _nextUnlock(state.intelligence);
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MILESTONES',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.streakAccent.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(
                      color: AppColors.streakAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 12,
                        color: AppColors.streakAccent,
                      ),
                      AppSpacing.hSpaceXxs,
                      Text(
                        streak.activeToday
                            ? '${streak.currentStreak}D STREAK • ACTIVE TODAY'
                            : '${streak.currentStreak}D STREAK',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.streakAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
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
              childAspectRatio: 1.5,
              children: [
                _MilestoneTile(
                  icon: Icons.grid_view_rounded,
                  value: '${metrics.contributionsToday}',
                  label: 'Today',
                  color: AppColors.primaryAccent,
                ),
                _MilestoneTile(
                  icon: Icons.date_range_rounded,
                  value: '${metrics.contributionsThisWeek}',
                  label: 'This week',
                  color: AppColors.commitAccent,
                ),
                _MilestoneTile(
                  icon: Icons.event_available_rounded,
                  value: '${metrics.activeDaysThisWeek}',
                  label: 'Active days',
                  color: AppColors.accentGreenAccent,
                ),
                _MilestoneTile(
                  icon: Icons.local_fire_department_rounded,
                  value: '${metrics.longestStreak}',
                  label: 'Longest streak',
                  color: AppColors.streakAccent,
                ),
              ],
            ),
            if (nextUnlock != null) ...[
              AppSpacing.vSpaceMd,
              _NextUnlockRow(status: nextUnlock),
            ],
          ],
        );
      },
    );
  }

  /// The locked achievement closest to completion — the most motivating
  /// concrete goal to surface next to the timeline.
  static AchievementStatus? _nextUnlock(DeveloperIntelligence intelligence) {
    final locked = intelligence.achievements
        .where((status) => !status.unlocked)
        .toList();
    if (locked.isEmpty) return null;
    locked.sort((a, b) => b.progressRatio.compareTo(a.progressRatio));
    return locked.first;
  }
}

class _MilestoneTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MilestoneTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.cardPaddingCompactInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: AppSpacing.iconSizeSmall, color: color),
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NextUnlockRow extends StatelessWidget {
  final AchievementStatus status;

  const _NextUnlockRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = achievementAccent(status.definition.category);

    return Container(
      padding: AppSpacing.cardPaddingCompactInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Icon(
            achievementIconData(status.definition.icon),
            size: AppSpacing.iconSizeMedium,
            color: accent,
          ),
          AppSpacing.hSpaceSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT UNLOCK',
                  style: AppTypography.captionSmall.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  status.definition.title,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.vSpaceXxs,
                Semantics(
                  label:
                      '${status.definition.title} progress '
                      '${status.cappedProgress} of ${status.target}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      value: status.progressRatio,
                      minHeight: 4,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hSpaceSm,
          Text(
            '${status.cappedProgress} / ${status.target}',
            style: AppTypography.monoSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
