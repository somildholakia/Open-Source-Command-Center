import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Three-card summary row for the Progress screen.
///
/// Presentation-only: every value is passed in already computed by the
/// intelligence engine, so there is no progression logic here.
class ProgressStatRow extends StatelessWidget {
  final int currentStreak;
  final int totalXp;
  final int unlockedAchievements;
  final int totalAchievements;

  const ProgressStatRow({
    super.key,
    required this.currentStreak,
    required this.totalXp,
    required this.unlockedAchievements,
    required this.totalAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ProgressStatCard(
            label: 'Current Streak',
            value: '$currentStreak',
            subtext: currentStreak == 1 ? 'day' : 'days',
            icon: Icons.local_fire_department_rounded,
            accentColor: AppColors.streakAccent,
          ),
        ),
        AppSpacing.hSpaceSm,
        Expanded(
          child: ProgressStatCard(
            label: 'Total XP',
            value: '$totalXp',
            subtext: 'earned',
            icon: Icons.auto_graph_rounded,
            accentColor: AppColors.primaryAccent,
          ),
        ),
        AppSpacing.hSpaceSm,
        Expanded(
          child: ProgressStatCard(
            label: 'Badges',
            value: '$unlockedAchievements / $totalAchievements',
            subtext: 'unlocked',
            icon: Icons.workspace_premium_rounded,
            accentColor: AppColors.achievementAccent,
          ),
        ),
      ],
    );
  }
}

/// One stat card inside [ProgressStatRow].
class ProgressStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color accentColor;

  const ProgressStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.cardPaddingInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(
              icon,
              size: AppSpacing.iconSizeSmall,
              color: accentColor,
            ),
          ),
          AppSpacing.vSpaceSm,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.monoLarge.copyWith(color: accentColor),
            ),
          ),
          AppSpacing.vSpaceXxs,
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            subtext,
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
