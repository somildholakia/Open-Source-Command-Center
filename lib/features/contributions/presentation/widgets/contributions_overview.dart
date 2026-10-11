import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../domain/domain.dart';
import 'contributions_calendar.dart';
import 'contributions_stat_card.dart';

/// Presentation data for one contribution stat card.
class ContributionStatData {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subtext;

  const ContributionStatData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.subtext,
  });
}

/// Overview section combining contribution stats and heatmap.
///
/// - Sample mode (default): Phase 1 preview numbers, marked SAMPLE DATA.
/// - Live mode ([isSample] false): stats derived from the connected
///   provider's [ContributionSummary] and a real heatmap.
class ContributionsOverview extends StatelessWidget {
  /// Whether the section shows sample preview data.
  final bool isSample;

  /// Stat cards to render; null uses the sample set.
  final List<ContributionStatData>? stats;

  /// Real heatmap weeks; null renders the sample grid.
  final List<List<ContributionDayData>>? weeks;

  const ContributionsOverview({
    super.key,
    this.isSample = true,
    this.stats,
    this.weeks,
  });

  /// Derives honest aggregate stats from a provider contribution summary.
  ///
  /// No deltas or trends are shown: the provider gives a single window (the
  /// last year), so "+3 this week" style copy cannot be computed truthfully.
  static List<ContributionStatData> statsFromSummary(
    ContributionSummary summary,
  ) {
    final counts = summary.dailyCounts.values;
    final activeDays = counts.where((count) => count > 0).length;
    final bestDay = counts.isEmpty ? 0 : counts.reduce(math.max);
    final average = activeDays == 0 ? 0.0 : summary.total / activeDays;

    return [
      ContributionStatData(
        label: 'Contributions',
        value: '${summary.total}',
        icon: Icons.grid_view_rounded,
        accentColor: AppColors.primary,
      ),
      ContributionStatData(
        label: 'Active Days',
        value: '$activeDays',
        icon: Icons.calendar_month_rounded,
        accentColor: AppColors.commit,
      ),
      ContributionStatData(
        label: 'Best Day',
        value: '$bestDay',
        icon: Icons.local_fire_department_rounded,
        accentColor: AppColors.streak,
      ),
      ContributionStatData(
        label: 'Avg / Active Day',
        value: average.toStringAsFixed(1),
        icon: Icons.trending_up_rounded,
        accentColor: AppColors.info,
      ),
    ];
  }

  /// Phase 1 sample stat cards.
  static const List<ContributionStatData> sampleStats = [
    ContributionStatData(
      label: 'Pull Requests',
      value: '12',
      icon: Icons.merge_type_rounded,
      accentColor: AppColors.pullRequest,
      subtext: '+3',
    ),
    ContributionStatData(
      label: 'Issues Resolved',
      value: '8',
      icon: Icons.adjust_rounded,
      accentColor: AppColors.issue,
      subtext: '+1',
    ),
    ContributionStatData(
      label: 'Commits',
      value: '47',
      icon: Icons.commit_rounded,
      accentColor: AppColors.commit,
      subtext: '+12',
    ),
    ContributionStatData(
      label: 'Reviews',
      value: '19',
      icon: Icons.rate_review_rounded,
      accentColor: AppColors.review,
      subtext: '+5',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = stats ?? sampleStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text('Overview', style: AppTypography.headingSmall),
            _buildBadge(),
          ],
        ),
        AppSpacing.vSpaceMd,

        // Stats cards grid
        ResponsiveGrid(
          compactColumns: 2,
          mobileColumns: 2,
          tabletColumns: 4,
          desktopColumns: 4,
          spacing: AppSpacing.sm,
          childAspectRatio: MediaQuery.sizeOf(context).width < 360 ? 0.9 : 1.3,
          children: [
            for (final card in cards)
              ContributionStatCard(
                label: card.label,
                value: card.value,
                icon: card.icon,
                accentColor: card.accentColor,
                subtext: card.subtext ?? '',
              ),
          ],
        ),
        AppSpacing.vSpaceXl,

        // Contribution heatmap/calendar
        ContributionsCalendar(weeks: weeks),
      ],
    );
  }

  /// SAMPLE DATA for previews, LAST 12 MONTHS for real provider data.
  Widget _buildBadge() {
    if (!isSample) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.successAccent.withValues(alpha: 0.12),
          borderRadius: AppSpacing.borderRadiusFull,
          border: Border.all(
            color: AppColors.successAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_rounded,
              size: 10,
              color: AppColors.successAccent,
            ),
            AppSpacing.hSpaceXxs,
            Text(
              'LAST 12 MONTHS',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.successAccent,
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          AppSpacing.hSpaceXxs,
          Text(
            'SAMPLE DATA',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}
