import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'activity_type_badge.dart';

/// Header section for the Activity feed screen.
///
/// Features:
/// - Title and description
/// - Live-feed badge
/// - Functional filter chips driving [selected] through [onChanged]
class ActivityHeader extends StatelessWidget {
  /// Active filter (chips highlight it).
  final ActivityFilter selected;

  /// Called when the user taps a chip. When null the chips are decorative
  /// (used by previews/tests that render the header standalone).
  final ValueChanged<ActivityFilter>? onChanged;

  const ActivityHeader({
    super.key,
    this.selected = ActivityFilter.all,
    this.onChanged,
  });

  /// Whether [filter] is the active chip.
  bool _isSelected(ActivityFilter filter) => filter == selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with Phase 2 badge
        Row(
          children: [
            Expanded(
              child: Text(
                'Activity Timeline',
                style: AppTypography.headingLarge,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.12),
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stream_rounded,
                    size: 12,
                    color: AppColors.primaryAccent,
                  ),
                  AppSpacing.hSpaceXxs,
                  Text(
                    'LIVE FEED',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.vSpaceXs,

        // Description
        Text(
          'Chronological feed of your open-source contributions',
          style: AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        AppSpacing.vSpaceMd,

        // Filter chips (functional)
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final filter in ActivityFilter.values)
              _buildFilterChip(context: context, filter: filter),
          ],
        ),
      ],
    );
  }

  /// Builds a filter chip; tapping it reports [ActivityFilter] through
  /// [onChanged].
  Widget _buildFilterChip({
    required BuildContext context,
    required ActivityFilter filter,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _isSelected(filter);
    final effectiveColor = filter.accent ?? AppColors.primaryAccent;

    return Opacity(
      opacity: isSelected ? 1.0 : 0.6,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(filter),
        borderRadius: AppSpacing.borderRadiusFull,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.15)
                : colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(
              color: isSelected
                  ? effectiveColor.withValues(alpha: 0.5)
                  : colorScheme.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter.label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? effectiveColor
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
