import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/cartoon_page_banner.dart';
import '../../../../core/widgets/sample_data_banner.dart';
import '../../../../core/widgets/status_message_card.dart';
import '../../../integrations/presentation/bloc/integration_bloc.dart';
import '../../../integrations/presentation/utils/failure_message.dart';
import '../../../integrations/presentation/widgets/github_authorization_prompt_card.dart';
import '../../../integrations/presentation/widgets/github_connect_callout.dart';
import '../widgets/activity_header.dart';
import '../widgets/activity_item.dart';
import '../widgets/activity_milestones_card.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/activity_timeline_placeholder.dart';
import '../widgets/activity_type_badge.dart';

/// Activity feed screen — chronological timeline of developer contributions.
///
/// Phase 2: the timeline consumes normalized provider activity through
/// [IntegrationBloc]:
/// - connected: real activity mapped to presentation items, newest first
/// - connecting: device-flow authorization prompt
/// - disconnected / expired / error: connect callout + clearly-labeled
///   sample timeline (Phase 1 preview never disappears, never masquerades)
/// - connected with no matching data: explicit empty state
///
/// Filters are functional and applied client-side to the loaded feed.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  ActivityFilter _filter = ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity', style: AppTypography.titleLarge),
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
                    const CartoonPageBanner(
                      eyebrow: 'Your journey',
                      title: 'Every commit tells a story',
                      subtitle: 'Pick up where your open-source adventure left off.',
                      icon: Icons.rocket_launch_rounded,
                      accent: Color(0xFF008F86),
                    ),
                    AppSpacing.vSpaceLg,
                    ActivityHeader(
                      selected: _filter,
                      onChanged: (filter) => setState(() => _filter = filter),
                    ),
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
      return _buildDisconnected(context, state);
    }

    // Connected: first load, failure with nothing cached, empty, or data.
    if (state.isLoadingData && state.activities.isEmpty) {
      return const [
        StatusMessageCard(
          icon: Icons.stream_rounded,
          message: 'Loading recent GitHub activity…',
        ),
      ];
    }

    if (state.failure != null && state.activities.isEmpty) {
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

    if (state.activities.isEmpty) {
      return [
        const StatusMessageCard(
          icon: Icons.inbox_rounded,
          message:
              'No recent public activity found. GitHub may still be '
              'processing your latest events.',
        ),
      ];
    }

    final items = state.activities
        .map((activity) => ActivityItemData.fromDomain(activity))
        .where((item) => _filter.matches(item.type))
        .toList(growable: false);

    if (items.isEmpty) {
      return [
        StatusMessageCard(
          icon: Icons.filter_alt_off_rounded,
          message:
              'No ${_filter.label} activity in your recent events. Try '
              'another filter.',
        ),
      ];
    }

    return [
      const ActivityMilestonesCard(),
      AppSpacing.vSpaceLg,
      ActivityTimeline(items: items),
    ];
  }

  List<Widget> _buildDisconnected(
    BuildContext context,
    IntegrationState state,
  ) {
    if (state.phase == IntegrationPhase.connecting) {
      return const [GitHubAuthorizationPromptCard()];
    }

    return [
      const GithubConnectCallout(
        title: 'CONNECT GITHUB',
        message:
            'Link your account to turn this preview into your real '
            'contribution timeline.',
        icon: Icons.timeline_rounded,
      ),
      AppSpacing.vSpaceMd,
      const SampleDataBanner(),
      AppSpacing.vSpaceMd,
      const ActivityTimelinePlaceholder(),
    ];
  }
}
