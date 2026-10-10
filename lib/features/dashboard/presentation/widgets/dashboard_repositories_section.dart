import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';
import '../../../repositories/presentation/widgets/repository_list.dart';

/// Dashboard section listing the developer's most recently updated
/// repositories from the connected provider.
///
/// Renders nothing while disconnected (the connect hero covers that), and
/// handles loading, empty and error states explicitly. All data comes from
/// [IntegrationBloc] — no provider or API access here.
class DashboardRepositoriesSection extends StatelessWidget {
  const DashboardRepositoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.repositories != current.repositories ||
          previous.isLoadingData != current.isLoadingData ||
          previous.failure != current.failure,
      builder: (context, state) {
        // Nothing to show until a provider is connected.
        if (state.phase == IntegrationPhase.disconnected ||
            state.phase == IntegrationPhase.unknown ||
            state.phase == IntegrationPhase.connecting ||
            state.phase == IntegrationPhase.expired) {
          return const SizedBox.shrink();
        }

        // Self-spacing: the section disappears entirely while disconnected,
        // so the dashboard must not leave a doubled gap behind it.
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'REPOSITORIES',
                      style: AppTypography.labelLarge.copyWith(
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppSpacing.hSpaceXs,
                  Text(
                    jobLabel(state),
                    style: AppTypography.captionSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceSm,
              _body(context, state),
            ],
          ),
        );
      },
    );
  }

  /// Caption reflecting the section's current data condition.
  static String jobLabel(IntegrationState state) {
    if (state.isLoadingData && state.repositories.isEmpty) return 'LOADING…';
    if (state.repositories.isEmpty) return 'NONE FOUND';
    return 'MOST RECENT';
  }

  Widget _body(BuildContext context, IntegrationState state) {
    // Loading (first load) — static copy rather than an indeterminate spinner.
    if (state.isLoadingData && state.repositories.isEmpty) {
      return _MessageCard(
        icon: Icons.folder_rounded,
        message: 'Loading repositories…',
      );
    }

    // Error / rate limit with nothing cached to show.
    if (state.failure != null && state.repositories.isEmpty) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        message: failureMessage(state.failure!),
        isError: true,
        actionLabel: 'Retry',
        onAction: () => context.read<IntegrationBloc>().add(
          const IntegrationDataRefreshRequested(),
        ),
      );
    }

    // Connected but the provider returned no repositories.
    if (state.repositories.isEmpty) {
      return _MessageCard(
        icon: Icons.folder_off_rounded,
        message: 'No repositories found for this account.',
      );
    }

    return RepositoryList(repositories: state.repositories, maxItems: 3);
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageCard({
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
