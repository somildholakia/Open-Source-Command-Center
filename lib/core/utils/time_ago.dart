/// Formats timestamps as compact human-readable relative labels matching the
/// timeline's visual language ("just now", "2 hours ago", "Yesterday").
///
/// Deliberately dependency-free (no `intl`): deterministic and unit-testable
/// via the [now] parameter.
String formatTimeAgo(DateTime timestamp, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  var difference = reference.difference(timestamp);

  // Future timestamps (clock skew): treat as just now.
  if (difference.isNegative) return 'just now';

  if (difference.inSeconds < 60) return 'just now';

  final minutes = difference.inMinutes;
  if (minutes < 60) {
    return '$minutes minute${minutes == 1 ? '' : 's'} ago';
  }

  final hours = difference.inHours;
  if (hours < 24) {
    return '$hours hour${hours == 1 ? '' : 's'} ago';
  }

  final days = difference.inDays;
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';

  // Older: compact date, e.g. "Sep 12" (or with year when not current year).
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final label = '${months[timestamp.month - 1]} ${timestamp.day}';
  if (timestamp.year == reference.year) return label;
  return '$label, ${timestamp.year}';
}
