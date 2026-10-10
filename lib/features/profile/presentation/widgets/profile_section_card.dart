import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A presentation-only section card with icon, title, subtitle, and chevron.
///
/// Stage 6.5: These cards (Connected Accounts, Achievements, Settings, About)
/// are display-only and do not navigate or implement functionality yet.
/// Feature implementation is deferred to later phases.
class ProfileSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const ProfileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: AppSpacing.iconSizeMedium,
              ),
              AppSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    AppSpacing.vSpaceXs,
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: AppSpacing.iconSizeMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
