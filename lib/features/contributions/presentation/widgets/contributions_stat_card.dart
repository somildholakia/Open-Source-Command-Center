import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Stat card for individual contribution metrics.
///
/// Displays a color-coded icon, mock numerical value, and label.
/// All values are presentation-only sample data for Phase 1.
/// Phase 2 will connect to real GitHub data.
class ContributionStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String subtext; // e.g. "vs last week"

  const ContributionStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtext = '',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.cardPaddingCompactInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xxs),
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
              if (subtext.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.borderRadiusXs,
                  ),
                  child: Text(
                    subtext,
                    style: AppTypography.captionSmall.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ],
          ),
          AppSpacing.vSpaceXxs,
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(color: accentColor),
          ),
          AppSpacing.vSpaceXxs,
          Text(
            label,
            style: AppTypography.captionMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
