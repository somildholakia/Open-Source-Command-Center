import 'package:equatable/equatable.dart';

/// Normalized contribution data for the heatmap and summary cards.
///
/// Backed by GitHub's GraphQL contribution calendar (which includes private
/// contributions visible to the authenticated user). Providers without an
/// equivalent capability may return an empty summary rather than inventing
/// data.
class ContributionSummary extends Equatable {
  /// Contribution counts keyed by ISO-8601 date (`yyyy-MM-dd`).
  final Map<String, int> dailyCounts;

  /// When this summary was fetched. Null when not tracked.
  final DateTime? fetchedAt;

  const ContributionSummary({required this.dailyCounts, this.fetchedAt});

  /// Total contributions across all days in the summary.
  int get total => dailyCounts.values.fold(0, (sum, count) => sum + count);

  /// Count on [date] (any time of day), or 0 when no data for that date.
  int countForDate(DateTime date) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return dailyCounts[key] ?? 0;
  }

  @override
  List<Object?> get props => [dailyCounts, fetchedAt];
}
