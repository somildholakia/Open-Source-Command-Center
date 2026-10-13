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
  int get total => dailyCounts.entries.fold(
    0,
    (sum, entry) {
      if (!_isValidDateKey(entry.key) || entry.value <= 0) return sum;
      return sum + entry.value;
    },
  );

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

bool _isValidDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3 ||
      parts[0].length != 4 ||
      parts[1].length != 2 ||
      parts[2].length != 2) {
    return false;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return false;
  final date = DateTime(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}
