import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';
import '../../../integrations/presentation/widgets/github_authorization_prompt_card.dart';
import '../../../integrations/presentation/widgets/github_connected_banner.dart';

/// Dashboard entry point for the GitHub provider connection.
///
/// Phase 2: fully state-driven — renders the connect CTA, the device-flow
/// authorization prompt, a connected status banner, or the typed failure for
/// expired/error states. All actions dispatch through [IntegrationBloc]; no
/// provider or API code lives here.
class GithubConnectHeroCard extends StatelessWidget {
  const GithubConnectHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.prompt != current.prompt ||
          previous.failure != current.failure,
      builder: (context, state) {
        switch (state.phase) {
          case IntegrationPhase.connected:
            return const GithubConnectedBanner();
          case IntegrationPhase.connecting:
            return const GitHubAuthorizationPromptCard();
          case IntegrationPhase.unknown:
            return const _HeroShell(
              title: 'CONNECT GITHUB',
              subtitle: 'Checking GitHub connection…',
            );
          case IntegrationPhase.disconnected:
            return _HeroShell(
              title: 'CONNECT GITHUB',
              subtitle:
                  'Link your account to replace sample data with your '
                  'real repositories, activity, and contributions.',
              showTerminalPreview: true,
              actionLabel: 'Connect GitHub Account',
              actionIcon: Icons.hub_rounded,
              onAction: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
            );
          case IntegrationPhase.expired:
            return _HeroShell(
              title: 'RECONNECT GITHUB',
              subtitle: failureMessage(const AuthorizationExpired()),
              isWarning: true,
              actionLabel: 'Reconnect GitHub Account',
              actionIcon: Icons.link_rounded,
              onAction: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
            );
          case IntegrationPhase.error:
            return _HeroShell(
              title: 'GITHUB UNAVAILABLE',
              subtitle: failureMessage(
                state.failure ?? const UnknownProviderError(),
              ),
              isError: true,
              actionLabel: 'Try Again',
              actionIcon: Icons.refresh_rounded,
              onAction: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
            );
        }
      },
    );
  }
}

class _HeroShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showTerminalPreview;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isWarning;
  final bool isError;

  const _HeroShell({
    required this.title,
    required this.subtitle,
    this.showTerminalPreview = false,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.isWarning = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isError
        ? colorScheme.error
        : isWarning
        ? AppColors.accentOrange
        : colorScheme.primary;

    // Error states tint the card (border, icon, copy) with the error color,
    // but the recovery action stays the primary action color so "Try Again"
    // reads the same here as it does on Profile, Activity and Contributions.
    final actionBackground = isError ? colorScheme.primary : accent;
    final actionForeground = isWarning
        ? AppColors.textOnAccent
        : AppColors.textOnPrimary;

    return Container(
      padding: AppSpacing.cardPaddingLargeInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.rocket_launch_rounded,
                  color: accent,
                  size: AppSpacing.iconSizeLarge,
                ),
              ),
              AppSpacing.hSpaceMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headingSmall.copyWith(
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vSpaceXxs,
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: isError
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showTerminalPreview) ...[
            AppSpacing.vSpaceMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.borderRadiusSm,
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.terminal_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  AppSpacing.hSpaceXs,
                  Expanded(
                    child: Text(
                      '\$ git command-center --connect github',
                      style: AppTypography.monoSmall.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (actionLabel != null) ...[
            AppSpacing.vSpaceMd,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionBackground,
                  foregroundColor: actionForeground,
                  padding: AppSpacing.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                ),
                icon: Icon(actionIcon ?? Icons.hub_rounded, size: 20),
                label: Text(
                  actionLabel!,
                  style: AppTypography.buttonMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
