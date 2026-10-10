import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../domain/domain.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';
import '../../../progress/presentation/widgets/intelligence_visuals.dart';

/// Spotlights the current daily streak and the developer's next daily quest.
///
/// Both cards read derived [IntelligenceBloc] state — real values as soon as
/// GitHub data is available, zeros (with an honest "get started" line) before
/// that.
///
/// Adapts responsively:
/// - Mobile: vertically stacked cards
/// - Tablet & Desktop: side-by-side cards
class StreakAndQuestCards extends StatelessWidget {
  const StreakAndQuestCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveRowColumn(
      spacing: AppSpacing.md,
      children: [_StreakCard(), _DailyQuestCard()],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      buildWhen: (previous, current) =>
          previous.intelligence.streak != current.intelligence.streak ||
          previous.hasData != current.hasData,
      builder: (context, state) {
        final streak = state.intelligence.streak;
        final days = streak.currentStreak;

        return Container(
          padding: AppSpacing.cardPaddingInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: AppColors.streak.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.streakAccent,
                      size: AppSpacing.iconSizeMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.streak.withValues(alpha: 0.12),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      _statusLabel(streak),
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.streakAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceSm,
              Text(
                'CURRENT STREAK',
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              AppSpacing.vSpaceXxs,
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$days',
                    style: AppTypography.streakCounter.copyWith(fontSize: 32),
                  ),
                  AppSpacing.hSpaceXs,
                  Text(
                    days == 1 ? 'DAY' : 'DAYS',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.streakAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceXs,
              Text(
                _message(streak),
                style: AppTypography.captionMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _statusLabel(StreakStats streak) {
    if (streak.activeToday) return 'ACTIVE TODAY';
    if (streak.currentStreak > 0) return 'KEEP IT ALIVE';
    return 'READY';
  }

  static String _message(StreakStats streak) {
    if (streak.activeToday) {
      return 'Logged today — longest run so far: ${streak.longestStreak} '
          '${streak.longestStreak == 1 ? 'day' : 'days'}.';
    }
    if (streak.currentStreak > 0) {
      return 'Contribute today to keep your streak alive.';
    }
    return 'Make your first contribution today to ignite your streak.';
  }
}

class _DailyQuestCard extends StatelessWidget {
  const _DailyQuestCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<IntelligenceBloc, IntelligenceState>(
      buildWhen: (previous, current) =>
          previous.intelligence.quests != current.intelligence.quests,
      builder: (context, state) {
        final quest = _nextDailyQuest(state.intelligence);

        return Container(
          padding: AppSpacing.cardPaddingInsets,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(
              color: AppColors.quest.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.quest.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Icon(
                      questIconData(quest.definition.icon),
                      color: AppColors.questAccent,
                      size: AppSpacing.iconSizeMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: Text(
                      '+${quest.xpReward} XP',
                      style: AppTypography.captionSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.vSpaceSm,
              Text(
                'DAILY QUEST #1',
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
              AppSpacing.vSpaceXxs,
              Text(
                quest.definition.title,
                style: AppTypography.headingSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              AppSpacing.vSpaceSm,
              Semantics(
                label:
                    '${quest.definition.title} progress '
                    '${quest.progress} of ${quest.target}',
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusFull,
                  child: LinearProgressIndicator(
                    value: quest.progressRatio,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.quest,
                    ),
                  ),
                ),
              ),
              AppSpacing.vSpaceXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${quest.progress} / ${quest.target} completed',
                    style: AppTypography.captionSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    quest.isCompleted ? 'Completed' : 'In progress',
                    style: AppTypography.captionSmall.copyWith(
                      color: quest.isCompleted
                          ? AppColors.successAccent
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                      fontStyle: quest.isCompleted
                          ? FontStyle.normal
                          : FontStyle.italic,
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

  /// The first daily quest still worth doing today; when every daily quest is
  /// complete, the first one is shown as completed.
  static QuestProgress _nextDailyQuest(DeveloperIntelligence intelligence) {
    final daily = intelligence.quests
        .where((quest) => quest.definition.period == QuestPeriod.daily)
        .toList(growable: false);
    if (daily.isEmpty) {
      return intelligence.quests.first;
    }
    return daily.firstWhere(
      (quest) => !quest.isCompleted,
      orElse: () => daily.first,
    );
  }
}
