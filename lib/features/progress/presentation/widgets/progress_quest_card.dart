import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';
import 'intelligence_visuals.dart';

/// One quest, rendered from its evaluated [QuestProgress].
///
/// Shows the real window progress, the XP it pays out and when the period rolls
/// over, so a quest is always a concrete, time-boxed goal.
class ProgressQuestCard extends StatelessWidget {
  final QuestProgress quest;

  /// Injectable clock for deterministic countdown copy in tests.
  final DateTime? now;

  const ProgressQuestCard({super.key, required this.quest, this.now});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final definition = quest.definition;
    final accent = questAccent(definition.period);
    final completed = quest.isCompleted;
    final clock = now ?? DateTime.now();

    return Container(
      padding: AppSpacing.cardPaddingInsets,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: accent.withValues(alpha: completed ? 0.5 : 0.25),
          width: completed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  questIconData(definition.icon),
                  size: AppSpacing.iconSizeSmall,
                  color: accent,
                ),
              ),
              AppSpacing.hSpaceSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questPeriodLabel(definition.period),
                      style: AppTypography.captionSmall.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      definition.title,
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 1,
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
          AppSpacing.vSpaceXs,
          Text(
            definition.description,
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vSpaceSm,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quest.progress} / ${quest.target}',
                style: AppTypography.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                completed
                    ? 'COMPLETED'
                    : _resetLabel(quest.periodEndsAt, clock),
                style: AppTypography.captionSmall.copyWith(
                  color: completed
                      ? accent
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: completed ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          AppSpacing.vSpaceXs,
          Semantics(
            label:
                '${definition.title} progress '
                '${quest.progress} of ${quest.target}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: quest.progressRatio,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Human countdown until the quest period rolls over.
  static String _resetLabel(DateTime endsAt, DateTime now) {
    final remaining = endsAt.difference(now);
    if (remaining.inMinutes <= 0) return 'RESETS SOON';
    final hours = remaining.inHours;
    if (hours >= 24) return 'RESETS IN ${remaining.inDays}D ${hours % 24}H';
    if (hours > 0) return 'RESETS IN ${hours}H ${remaining.inMinutes % 60}M';
    return 'RESETS IN ${remaining.inMinutes}M';
  }
}
