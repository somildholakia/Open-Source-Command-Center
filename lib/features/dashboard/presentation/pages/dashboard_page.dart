import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/cartoon_welcome_banner.dart';
import '../../../../core/widgets/sample_data_banner.dart';
import '../../../auth/presentation/bloc/auth.dart';
import '../../../integrations/presentation/widgets/cached_data_notice.dart';
import '../widgets/attention_feed_placeholder.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_activity_summary.dart';
import '../widgets/dashboard_repositories_section.dart';
import '../widgets/github_connect_hero_card.dart';
import '../widgets/stats_overview_grid.dart';
import '../widgets/streak_and_quest_cards.dart';

/// Home/Dashboard screen — Developer Command Center.
///
/// Phase 1: Presentation-first dashboard establishing the core visual identity,
/// dark navy foundation, gamified command center accents, and responsive layout.
///
/// Phase 2: connection hero, telemetry snapshot, and repositories consume
/// normalized GitHub data through [IntegrationBloc] (real data when connected;
/// clearly-labeled placeholders otherwise). Streak/quest cards remain
/// presentation-only until the gamification phase.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: AppTypography.titleLarge),
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CartoonWelcomeBanner(),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthAuthenticated &&
                        state.user.uid == 'local-demo') {
                      return const SampleDataBanner(
                        message:
                            'Local preview only — no Firebase account is signed in. GitHub data depends on configuration.',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                AppSpacing.vSpaceLg,
                const CachedDataNotice(),

                // Developer Greeting & Command Center Status Header
                const DashboardHeader(),
                AppSpacing.vSpaceLg,

                // GitHub Connect Hero CTA Card
                const GithubConnectHeroCard(),
                AppSpacing.vSpaceLg,

                // Streak and Daily Quest Spotlight Cards
                const StreakAndQuestCards(),
                AppSpacing.vSpaceLg,

                // Telemetry & Contribution Overview Metrics
                const StatsOverviewGrid(),
                AppSpacing.vSpaceLg,

                // Recent provider activity, kept compact for the dashboard.
                const DashboardActivitySummary(),
                AppSpacing.vSpaceLg,

                // Latest repositories (hidden while disconnected)
                const DashboardRepositoriesSection(),
                AppSpacing.vSpaceLg,

                // Needs Attention Live Stream Queue
                const AttentionFeedPlaceholder(),
                AppSpacing.vSpaceXl,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
