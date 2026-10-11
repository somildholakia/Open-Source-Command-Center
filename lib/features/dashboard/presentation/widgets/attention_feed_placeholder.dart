import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Presentation card displaying the "Needs Attention" / Live Stream empty state.
///
/// Phase 1: Informs the developer how review requests, CI failures, and mentions
/// will be surfaced once GitHub integration is established.
class AttentionFeedPlaceholder extends StatelessWidget {
  const AttentionFeedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingLargeInsets,
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
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.accent,
                  size: AppSpacing.iconSizeMedium,
                ),
              ),
              AppSpacing.hSpaceSm,
              Flexible(
                child: Text(
                  'NEEDS ATTENTION',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.accentGreen,
                  size: AppSpacing.iconSizeMedium,
                ),
                AppSpacing.hSpaceSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All queues clear',
                        style: AppTypography.titleSmall.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      AppSpacing.vSpaceXxs,
                      Text(
                        'Review requests, assigned issues, and CI alerts will stream here in real time.',
                        style: AppTypography.captionMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
