import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';
import '../bloc/integration_bloc.dart';
import '../utils/failure_message.dart';

/// Compact "connect GitHub" callout used by screens that are not connected.
///
/// Shows a title, an explanatory line, and a primary connect action; when the
/// last attempt failed (or authorization expired) the typed failure copy and a
/// retry label are shown instead. Actions dispatch through [IntegrationBloc].
class GithubConnectCallout extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const GithubConnectCallout({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.link_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.failure != current.failure,
      builder: (context, state) {
        final failed = state.phase == IntegrationPhase.error;
        final expired = state.phase == IntegrationPhase.expired;
        final bodyText = failed && state.failure != null
            ? failureMessage(state.failure!)
            : expired
            ? failureMessage(const AuthorizationExpired())
            : message;

        return Container(
          width: double.infinity,
          padding: AppSpacing.cardPaddingLargeInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: (failed ? colorScheme.error : colorScheme.primary)
                  .withValues(alpha: 0.35),
            ),
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
                      failed ? Icons.error_outline_rounded : icon,
                      color: failed ? colorScheme.error : colorScheme.primary,
                      size: AppSpacing.iconSizeMedium,
                    ),
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      failed ? 'GITHUB UNAVAILABLE' : title,
                      style: AppTypography.headingSmall.copyWith(
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceXs,
              Text(
                bodyText,
                style: AppTypography.bodySmall.copyWith(
                  color: failed
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.vSpaceMd,
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.read<IntegrationBloc>().add(
                    const IntegrationConnectRequested(),
                  ),
                  icon: Icon(
                    failed || expired
                        ? Icons.refresh_rounded
                        : Icons.link_rounded,
                    size: 18,
                  ),
                  label: Text(
                    failed
                        ? 'Try Again'
                        : expired
                        ? 'Reconnect GitHub'
                        : 'Connect GitHub',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
