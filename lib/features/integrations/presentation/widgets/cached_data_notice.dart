import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_message_card.dart';
import '../bloc/integration_bloc.dart';

/// Compact notice shown when the screens are using the last locally saved
/// provider snapshot instead of data refreshed during the current session.
class CachedDataNotice extends StatelessWidget {
  const CachedDataNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IntegrationBloc, IntegrationState>(
      buildWhen: (previous, current) => previous.isStale != current.isStale,
      builder: (context, state) {
        if (!state.isStale) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: StatusMessageCard(
            icon: Icons.cloud_off_rounded,
            message: 'Showing saved GitHub data. Refresh to check for updates.',
            actionLabel: 'Refresh',
            onAction: () => context.read<IntegrationBloc>().add(
              const IntegrationDataRefreshRequested(),
            ),
          ),
        );
      },
    );
  }
}
