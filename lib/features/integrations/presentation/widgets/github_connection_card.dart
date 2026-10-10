import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/provider_avatar.dart';
import '../../../../domain/domain.dart';
import '../bloc/integration_bloc.dart';
import '../utils/failure_message.dart';
import 'github_authorization_prompt_card.dart';

/// Profile card that reflects the real GitHub provider connection.
///
/// Renders one of the [IntegrationPhase] states:
/// - disconnected: "Connect GitHub" CTA
/// - connecting: device-flow prompt ([GitHubAuthorizationPromptCard])
/// - connected: GitHub account summary, refresh + disconnect actions
/// - expired: authorization revoked, reconnect CTA
/// - error: typed failure message with retry
///
/// Contains no provider/API code — all data and actions go through
/// [IntegrationBloc].
class GithubConnectionCard extends StatelessWidget {
  const GithubConnectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntegrationBloc, IntegrationState>(
      builder: (context, state) {
        switch (state.phase) {
          case IntegrationPhase.unknown:
            // No indeterminate spinner here: this phase is a quick local
            // check, and an always-animating indicator would keep the screen
            // permanently "busy" (and break pump-and-settle in tests).
            return const _CardShell(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: 'Checking connection…',
            );
          case IntegrationPhase.connecting:
            return const GitHubAuthorizationPromptCard();
          case IntegrationPhase.disconnected:
            return const _DisconnectedCard();
          case IntegrationPhase.connected:
            return _ConnectedCard(state: state);
          case IntegrationPhase.expired:
            return const _ExpiredCard();
          case IntegrationPhase.error:
            return _ErrorCard(failure: state.failure);
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Shared shell
// -----------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;
  final Widget? trailing;

  const _CardShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPaddingLargeInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusLg,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: AppSpacing.iconSizeMedium,
                ),
              ),
              AppSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.vSpaceXxs,
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Scale the badge down instead of overflowing on very narrow
              // phones.
              if (trailing != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
            ],
          ),
          if (child != null) ...[AppSpacing.vSpaceMd, child!],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Disconnected
// -----------------------------------------------------------------------------

class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      icon: Icons.link_rounded,
      title: 'GitHub',
      subtitle: 'Not connected',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your GitHub account to replace sample data with your '
            'real repositories, activity, and contributions.',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vSpaceMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text(
                'Connect GitHub',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Connected
// -----------------------------------------------------------------------------

class _ConnectedCard extends StatelessWidget {
  final IntegrationState state;

  const _ConnectedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final account = state.connection?.account;
    final profile = state.profile;
    final username = account?.username ?? profile?.username ?? 'github';
    final avatarUrl = account?.avatarUrl ?? profile?.avatarUrl;
    final lastSyncedAt = state.connection?.lastSyncedAt;

    return _CardShell(
      icon: Icons.link_rounded,
      title: 'GitHub',
      subtitle: 'Connected',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        child: Text(
          'LIVE',
          style: AppTypography.captionSmall.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProviderAvatar(
                imageUrl: avatarUrl,
                fallbackText: username,
                size: AppSpacing.avatarSizeMedium,
              ),
              AppSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: AppTypography.titleSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (profile?.effectiveDisplayName != null &&
                        profile!.effectiveDisplayName.isNotEmpty)
                      Text(
                        profile.effectiveDisplayName,
                        style: AppTypography.captionMedium.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            AppSpacing.vSpaceSm,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                _StatPill(
                  label: 'Repos',
                  value: '${profile.publicRepositoryCount}',
                ),
                _StatPill(
                  label: 'Followers',
                  value: '${profile.followersCount}',
                ),
              ],
            ),
          ],
          AppSpacing.vSpaceSm,
          Text(
            lastSyncedAt == null
                ? 'Syncing…'
                : 'Last synced ${formatTimeAgo(lastSyncedAt)}',
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          if (state.failure != null) ...[
            AppSpacing.vSpaceXs,
            Text(
              failureMessage(state.failure!),
              style: AppTypography.captionSmall.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
          AppSpacing.vSpaceMd,
          // Side-by-side actions on normal phones; stacked when the card is
          // too narrow for two buttons.
          LayoutBuilder(
            builder: (context, constraints) {
              final refreshButton = OutlinedButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () => context.read<IntegrationBloc>().add(
                        const IntegrationDataRefreshRequested(),
                      ),
                icon: state.isBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  state.isBusy ? 'Syncing…' : 'Refresh',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
              final disconnectButton = TextButton.icon(
                onPressed: () => _confirmDisconnect(context),
                icon: const Icon(Icons.link_off_rounded, size: 18),
                label: const Text(
                  'Disconnect',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );

              if (constraints.maxWidth < 260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    refreshButton,
                    AppSpacing.vSpaceXs,
                    disconnectButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: refreshButton),
                  AppSpacing.hSpaceSm,
                  Expanded(child: disconnectButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDisconnect(BuildContext context) async {
    final bloc = context.read<IntegrationBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disconnect GitHub?'),
        content: const Text(
          'Real GitHub data will be removed from this app. You can reconnect '
          'at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      bloc.add(const IntegrationDisconnectRequested());
    }
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: AppTypography.captionMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: label,
              style: AppTypography.captionSmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Expired / error
// -----------------------------------------------------------------------------

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      icon: Icons.link_off_rounded,
      title: 'GitHub',
      subtitle: 'Authorization expired',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failureMessage(const AuthorizationExpired()),
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vSpaceMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Reconnect GitHub'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final ProviderFailure? failure;

  const _ErrorCard({this.failure});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _CardShell(
      icon: Icons.error_outline_rounded,
      title: 'GitHub',
      subtitle: 'Connection problem',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            failure == null
                ? 'Something went wrong. Please try again.'
                : failureMessage(failure!),
            style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
          ),
          AppSpacing.vSpaceMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.read<IntegrationBloc>().add(
                const IntegrationConnectRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ),
        ],
      ),
    );
  }
}
