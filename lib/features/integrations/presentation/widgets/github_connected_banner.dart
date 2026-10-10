import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/provider_avatar.dart';
import '../bloc/integration_bloc.dart';
import '../utils/failure_message.dart';

/// Compact "GitHub connected" banner for screens that need a status strip
/// rather than the full Profile connection card.
///
/// Shows the connected account, last successful sync, and a refresh action.
/// Data and actions are dispatched through [IntegrationBloc] only.
class GithubConnectedBanner extends StatelessWidget {
  const GithubConnectedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.connection != current.connection ||
          previous.profile != current.profile ||
          previous.isBusy != current.isBusy ||
          previous.failure != current.failure,
      builder: (context, state) {
        final account = state.connection?.account;
        final username =
            account?.username ?? state.profile?.username ?? 'github';
        final avatarUrl = account?.avatarUrl ?? state.profile?.avatarUrl;
        final lastSyncedAt = state.connection?.lastSyncedAt;

        return Container(
          padding: AppSpacing.cardPaddingInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: ProviderAvatar(
                      imageUrl: avatarUrl,
                      fallbackText: username,
                      size: AppSpacing.avatarSizeSmall,
                    ),
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '@$username',
                                style: AppTypography.titleSmall.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppSpacing.hSpaceXs,
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          lastSyncedAt == null
                              ? 'Connected — syncing…'
                              : 'Synced ${formatTimeAgo(lastSyncedAt)}',
                          style: AppTypography.captionSmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh GitHub data',
                    onPressed: state.isBusy
                        ? null
                        : () => context.read<IntegrationBloc>().add(
                            const IntegrationDataRefreshRequested(),
                          ),
                    icon: state.isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              if (state.failure != null) ...[
                AppSpacing.vSpaceXs,
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: AppSpacing.iconSizeSmall,
                      color: colorScheme.error,
                    ),
                    AppSpacing.hSpaceXs,
                    Expanded(
                      child: Text(
                        failureMessage(state.failure!),
                        style: AppTypography.captionSmall.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
