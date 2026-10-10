import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/core/utils/time_ago.dart';

void main() {
  final now = DateTime(2026, 10, 3, 12, 0, 0);

  group('formatTimeAgo', () {
    test('renders "just now" for very recent timestamps', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(seconds: 5)), now: now),
        'just now',
      );
      expect(formatTimeAgo(now, now: now), 'just now');
    });

    test('treats future timestamps (clock skew) as just now', () {
      expect(
        formatTimeAgo(now.add(const Duration(minutes: 5)), now: now),
        'just now',
      );
    });

    test('renders minutes with correct singular/plural', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        formatTimeAgo(now.subtract(const Duration(minutes: 45)), now: now),
        '45 minutes ago',
      );
    });

    test('renders hours with correct singular/plural', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
      expect(
        formatTimeAgo(now.subtract(const Duration(hours: 23)), now: now),
        '23 hours ago',
      );
    });

    test('renders Yesterday for exactly one day', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(days: 1)), now: now),
        'Yesterday',
      );
    });

    test('renders days for the past week', () {
      expect(
        formatTimeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
      expect(
        formatTimeAgo(now.subtract(const Duration(days: 6)), now: now),
        '6 days ago',
      );
    });

    test('renders a compact date beyond a week', () {
      expect(formatTimeAgo(DateTime(2026, 9, 12), now: now), 'Sep 12');
    });

    test('includes the year for older years', () {
      expect(formatTimeAgo(DateTime(2024, 12, 31), now: now), 'Dec 31, 2024');
    });
  });
}
