import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Presentation-only settings section card with optional child content.
/// Stage 6.6: Does not navigate or implement deferred features.
class SettingsSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;

  const SettingsSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: AppSpacing.borderRadiusMd,
      child: InkWell(
        onTap: () {},
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          padding: AppSpacing.cardPaddingInsets,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  if (child != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: AppSpacing.iconSizeMedium,
                    ),
                ],
              ),
              if (child != null) ...[AppSpacing.vSpaceMd, child!],
            ],
          ),
        ),
      ),
    );
  }
}
