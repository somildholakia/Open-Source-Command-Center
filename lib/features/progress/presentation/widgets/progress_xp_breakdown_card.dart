import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';
import 'intelligence_visuals.dart';

/// Explains where the developer's XP came from.
///
/// XP is never a mystery number: activity, consistency and achievement rewards
/// are listed separately, with the busiest activity sources underneath.
class ProgressXpBreakdownCard extends StatelessWidget {
  final XpBreakdown xp;

  const ProgressXpBreakdownCard({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topSources = xp.byActivityType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: AppSpacing.cardPaddingInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: AppSpacing.iconSizeSmall,
                color: AppColors.primaryAccent,
              ),
              AppSpacing.hSpaceXs,
              Text(
                'XP SOURCES',
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceSm,
          _XpSourceRow(
            label: 'Activity',
            description: '${xp.eventsCounted} events counted',
            value: xp.activityXp,
            color: AppColors.primaryAccent,
          ),
          _XpSourceRow(
            label: 'Consistency',
            description: 'Active-day bonus',
            value: xp.activeDayXp,
            color: AppColors.streakAccent,
          ),
          _XpSourceRow(
            label: 'Achievements',
            description: 'One-time rewards',
            value: xp.achievementXp,
            color: AppColors.achievementAccent,
          ),
          if (topSources.isNotEmpty) ...[
            AppSpacing.vSpaceMd,
            Text(
              'TOP SOURCES',
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 0.8,
              ),
            ),
            AppSpacing.vSpaceXs,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final source in topSources.take(4))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      '${activityTypeLabel(source.key)} +${source.value}',
                      style: AppTypography.captionSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _XpSourceRow extends StatelessWidget {
  final String label;
  final String description;
  final int value;
  final Color color;

  const _XpSourceRow({
    required this.label,
    required this.description,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.hSpaceXs,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.captionSmall.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+$value XP',
            style: AppTypography.monoSmall.copyWith(
              color: value > 0 ? color : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
