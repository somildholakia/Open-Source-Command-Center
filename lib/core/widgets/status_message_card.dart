import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Compact status card for loading, empty, and error states.
///
/// One consistent surface for every non-happy-path message so screens do not
/// reinvent banners: icon + message + optional action button. Callers pass
/// user-facing copy (already resolved from typed failures via
/// `failureMessage`), never raw exception text.
class StatusMessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StatusMessageCard({
    super.key,
    required this.icon,
    required this.message,
    this.isError = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isError ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: isError
              ? colorScheme.error.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSizeSmall, color: color),
          AppSpacing.hSpaceXs,
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
          if (actionLabel != null) ...[
            AppSpacing.hSpaceXs,
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
