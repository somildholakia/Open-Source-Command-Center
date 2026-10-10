import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Header section for the Contributions screen.
///
/// Features:
/// - Title and description
/// - Analytics badge
/// - SAMPLE DATA disclosure while preview data is shown; LIVE when the
///   connected provider supplies real contributions
/// - Period filter chips (still decorative)
class ContributionsHeader extends StatelessWidget {
  /// Whether preview sample data is being shown.
  final bool isSample;

  const ContributionsHeader({super.key, this.isSample = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with Phase 2 badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Contribution Analytics',
                  style: AppTypography.headingLarge,
                ),
              ),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryAccent.withValues(alpha: 0.12),
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(
                      color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        size: 12,
                        color: AppColors.secondaryAccent,
                      ),
                      AppSpacing.hSpaceXxs,
                      Text(
                        'ANALYTICS',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.secondaryAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vSpaceXs,

        // Description
        Text(
          'Track your open-source contribution patterns and trends',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vSpaceMd,

        // Phase 2 label and presentation-only filter chips
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _buildDataLabel(),
            _buildFilterChip(label: 'All Time', isSelected: true),
            _buildFilterChip(
              label: 'This Week',
              isSelected: false,
              color: AppColors.primary,
            ),
            _buildFilterChip(
              label: 'This Month',
              isSelected: false,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the data-source label: SAMPLE DATA for previews, LIVE once real
  /// provider contributions are rendered.
  Widget _buildDataLabel() {
    final accent = isSample ? AppColors.warningAccent : AppColors.successAccent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isSample
            ? AppColors.warningBackground
            : accent.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSample ? Icons.schedule_rounded : Icons.public_rounded,
            size: 12,
            color: accent,
          ),
          AppSpacing.hSpaceXxs,
          Text(
            isSample ? 'SAMPLE DATA' : 'LIVE',
            style: AppTypography.captionSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a presentation-only filter chip.
  ///
  /// Phase 1: Visual-only, non-interactive.
  /// Phase 2: Will filter contribution data.
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.primaryAccent;

    return Opacity(
      opacity: isSelected ? 1.0 : 0.6,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.5)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? effectiveColor : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
