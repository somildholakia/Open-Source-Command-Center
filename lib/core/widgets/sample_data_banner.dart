import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Disclosure banner marking preview data as sample data.
///
/// Required by the Phase 2 rule that mock content must never be mistaken for
/// real provider data: every screen still showing Phase 1 sample content puts
/// this banner directly above it until real data is connected.
class SampleDataBanner extends StatelessWidget {
  /// What the user should do to replace the sample data.
  final String message;

  const SampleDataBanner({
    super.key,
    this.message =
        'Sample data shown for preview. Connect GitHub to see your own.',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningAccent.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: AppColors.warningAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_outlined,
            size: AppSpacing.iconSizeSmall,
            color: AppColors.warningAccent,
          ),
          AppSpacing.hSpaceXs,
          Expanded(
            child: Text(
              message,
              style: AppTypography.captionSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
