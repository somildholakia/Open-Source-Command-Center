import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/domain.dart';

/// One day of contribution data for the heatmap.
class ContributionDayData {
  /// Calendar date (local, midnight-normalized by callers).
  final DateTime date;

  /// Contributions recorded on [date].
  final int count;

  const ContributionDayData({required this.date, required this.count});

  /// Heatmap intensity level (0-4) derived from [count].
  ///
  /// Thresholds are a presentation choice, documented here so the legend and
  /// cells stay consistent: 0 none, 1-2 low, 3-5 medium, 6-9 high, 10+ peak.
  int get level {
    if (count <= 0) return 0;
    if (count >= 10) return 4;
    if (count >= 6) return 3;
    if (count >= 3) return 2;
    return 1;
  }

  /// Builds Monday-first week rows (oldest first) ending with the week that
  /// contains [now]. Days after today in the final week are zero-filled so the
  /// grid always aligns with the Mon-Sun labels.
  static List<List<ContributionDayData>> weeksFromSummary(
    ContributionSummary summary, {
    DateTime? now,
    int weekCount = 4,
  }) {
    final today = now ?? DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    // Monday of the current week.
    final thisWeekStart = todayDate.subtract(
      Duration(days: todayDate.weekday - DateTime.monday),
    );
    final firstWeekStart = thisWeekStart.subtract(
      Duration(days: 7 * (weekCount - 1)),
    );

    return List.generate(weekCount, (weekIndex) {
      final weekStart = firstWeekStart.add(Duration(days: 7 * weekIndex));
      return List.generate(7, (dayIndex) {
        final date = weekStart.add(Duration(days: dayIndex));
        return ContributionDayData(
          date: date,
          count: summary.countForDate(date),
        );
      });
    }, growable: false);
  }
}

/// Contribution heatmap/calendar.
///
/// Renders four week rows (Mon-Sun columns):
/// - [weeks] provided: real contribution data (LIVE badge, dated week labels)
/// - [weeks] null: Phase 1 sample grid, clearly marked SAMPLE
class ContributionsCalendar extends StatelessWidget {
  /// Real contribution weeks, oldest first. Null renders the sample grid.
  final List<List<ContributionDayData>>? weeks;

  const ContributionsCalendar({super.key, this.weeks});

  /// Sample intensity levels for the preview grid (0-4).
  static const List<List<int>> _mockWeekData = [
    [0, 1, 2, 1, 0, 3, 1],
    [2, 0, 1, 3, 2, 1, 0],
    [1, 2, 0, 1, 4, 2, 1],
    [0, 1, 3, 0, 2, 1, 0],
  ];

  /// Color mapping for contribution levels (0-4).
  ///
  /// Resolved per theme in [levelColors]: the dark palette uses navy
  /// foundations with vibrant accents; the light palette uses soft tints
  /// with deepened accents so cells read on white cards.
  static const List<Color> _levelColorsDark = [
    Color(0xFF1A1E3A), // 0 - no contribution (dark surface)
    Color(0xFF0A2A2F), // 1 - low (subtle cyan tint)
    Color(0xFF00E5FF), // 2 - medium (vibrant cyan)
    Color(0xFFB388FF), // 3 - high (vibrant purple)
    Color(0xFFFF4081), // 4 - peak (vibrant pink)
  ];

  static const List<Color> _levelColorsLight = [
    Color(0xFFE7EBF2), // 0 - no contribution (subtle grey)
    Color(0xFFCFF2F5), // 1 - low (soft cyan tint)
    Color(0xFF33C4D6), // 2 - medium (cyan)
    Color(0xFF9B7BF7), // 3 - high (purple)
    Color(0xFFF0568F), // 4 - peak (pink)
  ];

  /// Heatmap palette for the active theme.
  static List<Color> levelColors(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _levelColorsLight
        : _levelColorsDark;
  }

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  bool get _isLive => weeks != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final levelColors = ContributionsCalendar.levelColors(context);
    final rows = _cells();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Contribution Heatmap',
                style: AppTypography.headingSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            _buildBadge(context),
          ],
        ),
        AppSpacing.vSpaceSm,

        // Day labels
        Row(
          children: [
            const SizedBox(
              width: AppSpacing.xl,
              child: Text('', style: TextStyle()),
            ),
            ..._dayLabels.map(
              (label) => Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionSmall.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.vSpaceXxs,

        // Heatmap grid
        for (var weekIndex = 0; weekIndex < rows.length; weekIndex++)
          Row(
            children: [
              // Week label
              SizedBox(
                width: AppSpacing.xl,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    _weekLabel(weekIndex),
                    style: AppTypography.captionSmall.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Day cells
              for (
                var dayIndex = 0;
                dayIndex < rows[weekIndex].length;
                dayIndex++
              )
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: AppSpacing.xs,
                      left: dayIndex > 0 ? AppSpacing.xxs : 0,
                    ),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: levelColors[rows[weekIndex][dayIndex].level],
                        borderRadius: AppSpacing.borderRadiusXs,
                        border: Border.all(
                          color: rows[weekIndex][dayIndex].level > 0
                              ? levelColors[rows[weekIndex][dayIndex].level]
                                    .withValues(alpha: 0.3)
                              : colorScheme.outline.withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Tooltip(
                        message: rows[weekIndex][dayIndex].tooltip,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        AppSpacing.vSpaceMd,

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: AppTypography.captionSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            AppSpacing.hSpaceXxs,
            ...levelColors
                .take(4)
                .map(
                  (color) => Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                  ),
                ),
            AppSpacing.hSpaceXxs,
            Text(
              'More',
              style: AppTypography.captionSmall.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Renders the SAMPLE badge for preview data or the LIVE badge for real
  /// provider data, so the two are never confused.
  Widget _buildBadge(BuildContext context) {
    final accent = _isLive ? AppColors.successAccent : AppColors.warningAccent;
    final background = _isLive
        ? accent.withValues(alpha: 0.12)
        : AppColors.warningBackground;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLive ? Icons.public_rounded : Icons.schedule_rounded,
            size: 10,
            color: accent,
          ),
          AppSpacing.hSpaceXxs,
          Text(
            _isLive ? 'LIVE' : 'SAMPLE',
            style: AppTypography.captionSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// Week row label: dated for real data (week start), W1-W4 for sample data.
  String _weekLabel(int weekIndex) {
    final live = weeks;
    if (live == null || weekIndex >= live.length || live[weekIndex].isEmpty) {
      return 'W${weekIndex + 1}';
    }
    final start = live[weekIndex].first.date;
    final month = start.month.toString().padLeft(2, '0');
    final day = start.day.toString().padLeft(2, '0');
    return '$month/$day';
  }

  /// Normalizes real and sample data into renderable cells.
  List<List<_Cell>> _cells() {
    final live = weeks;
    if (live == null) {
      return _mockWeekData
          .map(
            (week) => week
                .map(
                  (level) => _Cell(
                    level: level,
                    tooltip: level > 0
                        ? '$level contribution${level > 1 ? 's' : ''} (sample)'
                        : 'No contributions (sample)',
                  ),
                )
                .toList(growable: false),
          )
          .toList(growable: false);
    }

    return live
        .map(
          (week) => week
              .map((day) {
                final date =
                    '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}'
                    '-${day.date.day.toString().padLeft(2, '0')}';
                final count = day.count;
                return _Cell(
                  level: day.level,
                  tooltip: count > 0
                      ? '$count contribution${count == 1 ? '' : 's'} on $date'
                      : 'No contributions on $date',
                );
              })
              .toList(growable: false),
        )
        .toList(growable: false);
  }
}

/// Internal cell view model.
class _Cell {
  final int level;
  final String tooltip;

  const _Cell({required this.level, required this.tooltip});
}
