import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';

/// Hero card for the developer's level and XP progress.
///
/// Everything rendered here comes from [LevelProgress]; the widget performs no
/// progression maths of its own — no XP curve, no thresholds.
class ProgressLevelCard extends StatelessWidget {
  final LevelProgress level;

  const ProgressLevelCard({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = level.progress.clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingLargeInsets,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientPremium,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LEVEL ${level.level}',
                      style: AppTypography.levelDisplay.copyWith(
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    Text(
                      level.levelTitle,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusFull,
                ),
                child: Text(
                  '${level.totalXp} TOTAL XP',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceMd,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${level.xpIntoLevel} / ${level.xpForNextLevel} XP',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              Text(
                '$percent%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceXs,
          // A short, finite reveal — no indeterminate spinner, and it settles
          // immediately for users with reduced motion (see reduceMotion below).
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Semantics(
                label:
                    'Level ${level.level} progress '
                    '${(value * 100).round()} percent',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: AppSpacing.xpBarHeightLarge,
                    backgroundColor: AppColors.textOnPrimary.withValues(
                      alpha: 0.3,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.textOnPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
          AppSpacing.vSpaceSm,
          Text(
            level.xpRemaining > 0
                ? '${level.xpRemaining} XP TO LEVEL ${level.level + 1}'
                : 'MAXIMUM LEVEL REACHED',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
