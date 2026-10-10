import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';

/// A compact, live snapshot of recent contribution activity on the dashboard.
/// All values are derived from the normalized, cached provider feed.
class DashboardActivitySummary extends StatelessWidget {
  const DashboardActivitySummary({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) =>
          previous.phase != current.phase ||
          previous.activities != current.activities ||
          previous.failure != current.failure ||
          previous.isLoadingData != current.isLoadingData,
      builder: (context, state) {
        if (!state.isConnected &&
            state.phase != IntegrationPhase.error &&
            state.phase != IntegrationPhase.expired) {
          return const SizedBox.shrink();
        }

        final recent = state.activities.take(5).toList(growable: false);
        final pullRequests = recent.where((event) =>
            event.type == DeveloperActivityType.pullRequestOpened ||
            event.type == DeveloperActivityType.pullRequestMerged).length;
        final issuesClosed = recent
            .where((event) => event.type == DeveloperActivityType.issueClosed)
            .length;

        return Container(
          width: double.infinity,
          padding: AppSpacing.cardPaddingLargeInsets,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB9F2E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF00695C),
                    ),
                  ),
                  AppSpacing.hSpaceSm,
                  Expanded(
                    child: Text(
                      'LAST 5 EVENTS',
                      style: AppTypography.labelLarge.copyWith(
                        color: scheme.onSurface,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (state.isLoadingData)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              AppSpacing.vSpaceMd,
              if (state.failure != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cloud_off_rounded, color: scheme.error, size: 18),
                      AppSpacing.hSpaceXs,
                      Expanded(
                        child: Text(
                          failureMessage(state.failure!),
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                      if (state.repositories.isNotEmpty)
                        TextButton(
                          onPressed: () => context.read<IntegrationBloc>().add(
                            const IntegrationDataRefreshRequested(),
                          ),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              if (recent.isEmpty)
                Text(
                  state.isLoadingData
                      ? 'Loading your recent activity…'
                      : 'Your recent GitHub activity will show up here.',
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _ActivityMetric(
                      label: 'Pull requests',
                      value: pullRequests,
                      accent: const Color(0xFF6C4CE8),
                    ),
                    _ActivityMetric(
                      label: 'Issues closed',
                      value: issuesClosed,
                      accent: AppColors.successAccent,
                    ),
                    _ActivityMetric(
                      label: 'Events loaded',
                      value: recent.length,
                      accent: const Color(0xFFFF8A4C),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppTypography.monoLarge.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
