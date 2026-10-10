import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/status_message_card.dart';
import '../../../../domain/domain.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';
import '../../../integrations/presentation/widgets/github_connect_callout.dart';
import '../bloc/intelligence_bloc.dart';
import '../utils/progress_share_text.dart';
import '../widgets/progress_achievement_card.dart';
import '../widgets/progress_level_card.dart';
import '../widgets/progress_quest_card.dart';
import '../widgets/progress_stat_row.dart';
import '../widgets/progress_xp_breakdown_card.dart';

/// Progress screen — level, XP, streaks, achievements and quests.
///
/// Every value is derived by the intelligence engine from normalized GitHub
/// data; this screen only presents [IntelligenceState]. While nothing is
/// connected (or data failed before any arrived) it shows an explicit
/// connection/loading/error state instead of placeholder progression, so real
/// XP is never faked.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progress', style: AppTypography.titleLarge),
        elevation: 0,
        actions: [
          BlocBuilder<IntelligenceBloc, IntelligenceState>(
            buildWhen: (previous, current) =>
                previous.hasData != current.hasData,
            builder: (context, state) => IconButton(
              tooltip: 'Copy progress summary',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: state.hasData
                  ? () => _copySummary(context, state.intelligence)
                  : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<IntelligenceBloc, IntelligenceState>(
          builder: (context, state) {
            return ResponsiveContainer(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPaddingHorizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [..._buildBody(context, state), AppSpacing.vSpaceXl],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copySummary(
    BuildContext context,
    DeveloperIntelligence intelligence,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: buildProgressShareText(intelligence)),
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Progress summary copied to clipboard.')),
    );
  }

  List<Widget> _buildBody(BuildContext context, IntelligenceState state) {
    if (!state.hasData) {
      return _buildUnavailable(context, state);
    }

    final intelligence = state.intelligence;
    final dailyQuests = intelligence.quests
        .where((quest) => quest.definition.period == QuestPeriod.daily)
        .toList(growable: false);
    final weeklyQuests = intelligence.quests
        .where((quest) => quest.definition.period == QuestPeriod.weekly)
        .toList(growable: false);
    final unlocked = intelligence.unlockedAchievementCount;

    return [
      AppSpacing.vSpaceMd,
      if (state.isStale) ...[
        StatusMessageCard(
          icon: Icons.cloud_off_rounded,
          message:
              'Showing the last data that synced successfully — GitHub could '
              'not be reached for a refresh.',
          actionLabel: 'Retry',
          onAction: () => context.read<IntegrationBloc>().add(
            const IntegrationDataRefreshRequested(),
          ),
        ),
        AppSpacing.vSpaceMd,
      ],
      ProgressLevelCard(level: intelligence.level),
      AppSpacing.vSpaceXl,

      Text('Your Progress', style: AppTypography.headingSmall),
      AppSpacing.vSpaceMd,
      ProgressStatRow(
        currentStreak: intelligence.streak.currentStreak,
        totalXp: intelligence.xp.totalXp,
        unlockedAchievements: unlocked,
        totalAchievements: intelligence.achievements.length,
      ),
      AppSpacing.vSpaceMd,
      ProgressXpBreakdownCard(xp: intelligence.xp),
      AppSpacing.vSpaceXl,

      _SectionHeader(
        title: 'Achievements',
        badge: '$unlocked / ${intelligence.achievements.length} UNLOCKED',
        badgeColor: AppColors.achievementAccent,
      ),
      AppSpacing.vSpaceMd,
      for (final status in intelligence.achievements) ...[
        ProgressAchievementCard(status: status),
        AppSpacing.vSpaceSm,
      ],
      AppSpacing.vSpaceMd,

      _SectionHeader(
        title: 'Daily Quests',
        badge: 'RESETS AT MIDNIGHT',
        badgeColor: AppColors.primaryAccent,
      ),
      AppSpacing.vSpaceMd,
      for (final quest in dailyQuests) ...[
        ProgressQuestCard(quest: quest),
        AppSpacing.vSpaceSm,
      ],
      AppSpacing.vSpaceMd,

      _SectionHeader(
        title: 'Weekly Quests',
        badge: 'RESETS MONDAY',
        badgeColor: AppColors.secondaryAccent,
      ),
      AppSpacing.vSpaceMd,
      for (final quest in weeklyQuests) ...[
        ProgressQuestCard(quest: quest),
        AppSpacing.vSpaceSm,
      ],
    ];
  }

  /// States where no real progression can be shown yet.
  List<Widget> _buildUnavailable(
    BuildContext context,
    IntelligenceState state,
  ) {
    if (state.needsConnection) {
      return [
        AppSpacing.vSpaceMd,
        const GithubConnectCallout(
          title: 'CONNECT GITHUB',
          message:
              'XP, levels, streaks, achievements and quests are all derived '
              'from your real contribution data. Connect to start tracking.',
          icon: Icons.emoji_events_rounded,
        ),
        AppSpacing.vSpaceMd,
      ];
    }

    if (state.failure != null) {
      return [
        AppSpacing.vSpaceMd,
        StatusMessageCard(
          icon: Icons.error_outline_rounded,
          message: failureMessage(state.failure!),
          isError: true,
          actionLabel: 'Retry',
          onAction: () => context.read<IntegrationBloc>().add(
            const IntegrationDataRefreshRequested(),
          ),
        ),
        AppSpacing.vSpaceMd,
      ];
    }

    return [
      AppSpacing.vSpaceMd,
      const StatusMessageCard(
        icon: Icons.hourglass_top_rounded,
        message: 'Calculating your progression from GitHub…',
      ),
      AppSpacing.vSpaceMd,
    ];
  }
}

/// Section title with a compact status badge.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;

  const _SectionHeader({
    required this.title,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.headingSmall)),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: AppSpacing.borderRadiusFull,
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            badge,
            style: AppTypography.captionSmall.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
