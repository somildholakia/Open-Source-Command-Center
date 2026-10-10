import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';

/// Empty state shown when the user is not authenticated.
///
/// Displays a message prompting the user to sign in.
class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppSpacing.vSpaceXl,
            Icon(
              Icons.person_outline_rounded,
              size: AppSpacing.avatarSizeXLarge,
              color: AppColors.textTertiary,
            ),
            AppSpacing.vSpaceMd,
            Text('No Profile Data', style: AppTypography.emptyStateHeading),
            AppSpacing.vSpaceXs,
            Text(
              'Sign in to view your profile and account details.',
              style: AppTypography.emptyStateMessage,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vSpaceXl,
          ],
        ),
      ),
    );
  }
}
