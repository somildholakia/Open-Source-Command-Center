import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';

/// An honest capability notice for the attention feed.
///
/// The current provider scope syncs public activity, repositories, and
/// contributions. It does not yet sync the user's inbox notifications,
/// assigned review requests, or CI status, so this widget never claims that
/// those queues are clear.
class AttentionFeedPlaceholder extends StatelessWidget {
  const AttentionFeedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) => previous.phase != current.phase,
      builder: (context, state) {
        // The connection hero already explains how to connect while
        // disconnected. Do not render a misleading "all clear" state.
        if (!state.isConnected) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final accent = Theme.of(context).brightness == Brightness.dark
            ? AppColors.accentOrange
            : AppColors.accentOrangeDark;

        return Container(
          width: double.infinity,
          padding: AppSpacing.cardPaddingLargeInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.inbox_outlined,
                      color: accent,
                      size: AppSpacing.iconSizeMedium,
                    ),
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      'INBOX & CI STATUS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  AppSpacing.hSpaceXs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      'NOT SYNCED',
                      style: AppTypography.captionSmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceMd,
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                      size: AppSpacing.iconSizeMedium,
                    ),
                    AppSpacing.hSpaceSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attention tracking is not available yet',
                            style: AppTypography.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          AppSpacing.vSpaceXxs,
                          Text(
                            'This build syncs your public GitHub activity, '
                            'repositories, and contributions. Assigned issues, '
                            'review-request inbox items, notifications, and '
                            'CI checks are not synced yet.',
                            style: AppTypography.captionMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
