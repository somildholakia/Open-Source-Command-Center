import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/bloc/auth.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';

/// Header section for the Dashboard.
///
/// Features:
/// - Online status badge with command center tag
/// - Dynamic user greeting bound to [AuthBloc]
/// - Level chip and XP bar bound to the derived [IntelligenceBloc] state
///   (real values once GitHub data is available, zeroed until then)
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final displayName = switch (state) {
          AuthAuthenticated(:final user) => user.displayNameOrDefault,
          _ => 'Developer',
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Command Center Tag Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: AppSpacing.borderRadiusFull,
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _StatusDot(),
                      AppSpacing.hSpaceXs,
                      Text(
                        'COMMAND CENTER v0.1',
                        style: AppTypography.captionMedium.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const _LevelChip(),
              ],
            ),
            AppSpacing.vSpaceSm,

            // Developer Greeting
            Text(
              'Hello, $displayName!',
              style: AppTypography.headingLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            AppSpacing.vSpaceXxs,
            Text(
              'Ready for your next open-source quest?',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vSpaceMd,

            const _XpProgressPanel(),
          ],
        );
      },
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Level chip — `LVL 3 • CONTRIBUTOR`, straight from the engine.
class _LevelChip extends StatelessWidget {
  const _LevelChip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      buildWhen: (previous, current) =>
          previous.intelligence.level != current.intelligence.level,
      builder: (context, state) {
        final level = state.intelligence.level;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'LVL ${level.level} • ${level.levelTitle}',
            style: AppTypography.captionMedium.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

/// XP progress inside the current level.
class _XpProgressPanel extends StatelessWidget {
  const _XpProgressPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      buildWhen: (previous, current) =>
          previous.intelligence.level != current.intelligence.level ||
          previous.hasData != current.hasData,
      builder: (context, state) {
        final level = state.intelligence.level;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    '${level.xpIntoLevel} / ${level.xpForNextLevel} XP',
                    style: AppTypography.monoSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceXs,
              Semantics(
                label:
                    'Level ${level.level} progress '
                    '${(level.progress * 100).round()} percent',
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: level.progress),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: AppSpacing.xpBarHeight,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      );
                    },
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
