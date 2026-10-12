import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/integration_bloc.dart';
import '../utils/failure_message.dart';

/// Card displayed while a GitHub device-flow authorization is in progress.
///
/// Shows the user code to enter at the verification URL plus a shortcut to
/// open the browser. Dispatches cancel through [IntegrationBloc].
class GitHubAuthorizationPromptCard extends StatelessWidget {
  const GitHubAuthorizationPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.prompt != current.prompt ||
          previous.phase != current.phase ||
          previous.failure != current.failure,
      builder: (context, state) {
        final prompt = state.prompt;

        return Container(
          padding: AppSpacing.cardPaddingLargeInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      color: colorScheme.secondary,
                      size: AppSpacing.iconSizeLarge,
                    ),
                  ),
                  AppSpacing.hSpaceMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONNECT GITHUB',
                          style: AppTypography.headingSmall.copyWith(
                            color: colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        AppSpacing.vSpaceXxs,
                        Text(
                          prompt == null ? 'Starting authorization…' : 'Enter this code to authorize the Command Center:',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (prompt?.userCode != null) ...[
                AppSpacing.vSpaceMd,
                // The user code — the one thing worth making unmissable.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.borderRadiusSm,
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 44),
                      Expanded(
                        child: SelectableText(
                          prompt!.userCode!,
                          textAlign: TextAlign.center,
                          style: AppTypography.monoLarge.copyWith(
                            color: colorScheme.onSurface,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy device code',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: prompt.userCode!),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text('GitHub device code copied'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                        },
                      ),
                    ],
                  ),
                ),
                if (prompt.expiresAt != null) ...[
                  AppSpacing.vSpaceXs,
                  Text(
                    'This code expires — complete authorization in your browser.',
                    style: AppTypography.captionSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ],
              if (state.failure != null) ...[
                AppSpacing.vSpaceSm,
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
              AppSpacing.vSpaceMd,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: prompt == null
                          ? null
                          : () => _openVerification(
                              context,
                              prompt.verificationUrl,
                            ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Open GitHub'),
                    ),
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => context.read<IntegrationBloc>().add(
                        const IntegrationCancelConnectRequested(),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openVerification(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
