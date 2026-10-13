import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../domain/domain.dart';
import 'intelligence_visuals.dart';

/// One achievement, rendered from its evaluated [AchievementStatus].
///
/// Locked achievements show their real progress toward the target, so the card
/// doubles as a goal ("3 / 7 days") instead of a placeholder.
class ProgressAchievementCard extends StatelessWidget {
  final AchievementStatus status;

  /// Injectable clock for deterministic "unlocked … ago" copy in tests.
  final DateTime? now;

  const ProgressAchievementCard({super.key, required this.status, this.now});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final definition = status.definition;
    final accent = achievementAccent(definition.category);
    final unlocked = status.unlocked;
    final unlockedAt = status.unlockedAt;

    return Container(
      padding: AppSpacing.cardPaddingCompactInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: unlocked ? accent.withValues(alpha: 0.5) : colorScheme.outline,
          width: unlocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: unlocked
                  ? accent.withValues(alpha: 0.2)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              achievementIconData(definition.icon),
              size: AppSpacing.iconSizeLarge,
              color: unlocked
                  ? accent
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          AppSpacing.hSpaceMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        definition.title,
                        style: AppTypography.titleMedium.copyWith(
                          color: unlocked
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        '+${status.xpReward} XP',
                        style: AppTypography.captionSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.vSpaceXs,
                Text(
                  definition.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vSpaceXs,
                Semantics(
                  label:
                      '${definition.title} progress '
                      '${status.cappedProgress} of ${status.target}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: status.progressRatio,
                      minHeight: 5,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
                AppSpacing.vSpaceXs,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${status.cappedProgress} / ${status.target}',
                      style: AppTypography.captionSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? accent.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      child: Text(
                        unlocked ? 'UNLOCKED' : 'LOCKED',
                        style: AppTypography.captionSmall.copyWith(
                          color: unlocked
                              ? accent
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (unlocked && unlockedAt != null)
                      Text(
                        'unlocked ${formatTimeAgo(unlockedAt, now: now)}',
                        style: AppTypography.captionSmall.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
