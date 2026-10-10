import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'activity_item.dart';

/// Chronological timeline renderer.
///
/// Renders prepared [ActivityItemData] — either mapped from normalized domain
/// activity (connected state) or local sample data (disconnected preview).
/// Pure presentation: no provider, bloc or API access.
class ActivityTimeline extends StatelessWidget {
  final List<ActivityItemData> items;

  const ActivityTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(items.length, (index) {
          final activity = items[index];
          return ActivityItem(
            data: activity,
            showTimelineConnector: true,
            isFirst: index == 0,
            isLast: index == items.length - 1,
          );
        }),

        AppSpacing.vSpaceLg,

        // End of timeline indicator
        Opacity(
          opacity: 0.5,
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 32,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                AppSpacing.vSpaceXs,
                Text(
                  'All caught up!',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
