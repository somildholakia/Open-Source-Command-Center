import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/sample_data_banner.dart';
import '../../../../core/widgets/status_message_card.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';
import '../../../integrations/presentation/widgets/github_authorization_prompt_card.dart';
import '../../../integrations/presentation/widgets/github_connect_callout.dart';
import '../../../progress/presentation/bloc/intelligence_bloc.dart';
import '../widgets/contributions_calendar.dart';
import '../widgets/contributions_header.dart';
import '../widgets/contributions_overview.dart';

/// Contributions screen — overview of developer contribution analytics.
///
/// Phase 2: contribution data comes from the connected provider's
/// [ContributionSummary] through [IntegrationBloc]:
/// - connected: live stats + heatmap derived from real contribution days
/// - connecting: device-flow authorization prompt
/// - disconnected / expired / error: connect callout + clearly-labeled sample
///   preview (never presented as real data)
/// - connected with an empty calendar: explicit empty state
class ContributionsPage extends StatelessWidget {
  const ContributionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contributions', style: AppTypography.titleLarge),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<IntegrationBloc, IntegrationState>(
          builder: (context, state) {
            return ResponsiveContainer(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ContributionsHeader(isSample: !state.isConnected),
                    AppSpacing.vSpaceLg,
                    ..._buildBody(context, state),
                    AppSpacing.vSpaceXl,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, IntegrationState state) {
    if (!state.isConnected) {
      if (state.phase == IntegrationPhase.connecting) {
        return const [GitHubAuthorizationPromptCard()];
      }
      return [
        const GithubConnectCallout(
          title: 'CONNECT GITHUB',
          message:
              'Link your account to replace this preview with your real '
              'contribution history and heatmap.',
          icon: Icons.grid_view_rounded,
        ),
        AppSpacing.vSpaceMd,
        const SampleDataBanner(),
        AppSpacing.vSpaceLg,
        const ContributionsOverview(),
      ];
    }

    final summary = state.contributions;

    // First load (no data yet).
    if (summary == null && state.isLoadingData) {
      return const [
        StatusMessageCard(
          icon: Icons.calendar_month_rounded,
          message: 'Loading your contribution calendar…',
        ),
      ];
    }

    // Failure with nothing cached for this screen.
    if (summary == null && state.failure != null) {
      return [
        StatusMessageCard(
          icon: Icons.error_outline_rounded,
          message: failureMessage(state.failure!),
          isError: true,
          actionLabel: 'Retry',
          onAction: () => context.read<IntegrationBloc>().add(
            const IntegrationDataRefreshRequested(),
          ),
        ),
      ];
    }

    if (summary == null || summary.dailyCounts.isEmpty) {
      return const [
        StatusMessageCard(
          icon: Icons.inbox_rounded,
          message:
              'No contributions recorded in the last year yet. Push a '
              'commit or open a pull request to start your heatmap.',
        ),
      ];
    }

    return [
      // Progression stats (streak, current week) come from the intelligence
      // engine; the contribution aggregates come from the calendar itself.
      BlocBuilder<IntelligenceBloc, IntelligenceState>(
        builder: (context, intelligenceState) {
          final intelligence = intelligenceState.intelligence;
          final stats = <ContributionStatData>[
            ...ContributionsOverview.statsFromSummary(summary),
            if (intelligenceState.hasData) ...[
              ContributionStatData(
                label: 'Current Streak',
                value: '${intelligence.streak.currentStreak}',
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.streakAccent,
                subtext: intelligence.streak.currentStreak == 1
                    ? 'day in a row'
                    : 'days in a row',
              ),
              ContributionStatData(
                label: 'This Week',
                value: '${intelligence.metrics.contributionsThisWeek}',
                icon: Icons.date_range_rounded,
                accentColor: AppColors.secondaryAccent,
                subtext: 'since Monday',
              ),
            ],
          ];

          return ContributionsOverview(
            isSample: false,
            stats: stats,
            weeks: ContributionDayData.weeksFromSummary(summary),
          );
        },
      ),
    ];
  }
}
