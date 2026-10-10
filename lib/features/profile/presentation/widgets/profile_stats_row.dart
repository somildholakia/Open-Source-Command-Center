import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';

/// Level, XP and streak for the signed-in developer.
///
/// Values come from the derived [IntelligenceBloc] state — the same numbers the
/// Dashboard and Progress screens show. Before any GitHub data is available the
/// cards read `—` rather than inventing a level.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      builder: (context, state) {
        final hasData = state.hasData;
        final level = state.intelligence.level;
        final xp = state.intelligence.xp;
        final streak = state.intelligence.streak;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _StatCard(
                label: 'Level',
                value: hasData ? '${level.level}' : '—',
                subtext: hasData ? level.levelTitle : null,
                color: AppColors.secondaryAccent,
              ),
            ),
            Container(width: 1, height: 40, color: colorScheme.outline),
            Expanded(
              child: _StatCard(
                label: 'XP',
                value: hasData ? '${xp.totalXp}' : '—',
                subtext: hasData ? 'total earned' : null,
                color: AppColors.primaryAccent,
              ),
            ),
            Container(width: 1, height: 40, color: colorScheme.outline),
            Expanded(
              child: _StatCard(
                label: 'Streak',
                value: hasData ? '${streak.currentStreak}' : '—',
                subtext: hasData
                    ? (streak.currentStreak == 1 ? 'day' : 'days')
                    : null,
                color: AppColors.streakAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(value, style: AppTypography.monoMedium.copyWith(color: color)),
        if (subtext != null) ...[
          AppSpacing.vSpaceXxs,
          Text(
            subtext!,
            style: AppTypography.captionSmall.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
        AppSpacing.vSpaceXs,
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
