import '../../../../domain/domain.dart';

/// Builds a plain-text summary of a developer's progression.
///
/// The shareable progress model is deliberately local: the app hands this text
/// to the system clipboard and never posts to a social API, so no account,
/// token or network capability is involved.
String buildProgressShareText(DeveloperIntelligence intelligence) {
  final level = intelligence.level;
  final metrics = intelligence.metrics;
  final streak = intelligence.streak;
  final unlocked = intelligence.unlockedAchievementCount;
  final total = intelligence.achievements.length;
  final completed = intelligence.completedQuestCount;

  final lines = <String>[
    'Open Source Command Center — my progression',
    '',
    'LEVEL ${level.level} • ${level.levelTitle}',
    '${level.totalXp} XP on GitHub activity',
    'Current streak: ${streak.currentStreak} '
        '${streak.currentStreak == 1 ? 'day' : 'days'} '
        '(longest ${streak.longestStreak})',
    'Achievements: $unlocked / $total',
    'Quests completed: $completed',
    'Contributions: ${metrics.totalContributions} '
        'across ${metrics.activeDays} active '
        '${metrics.activeDays == 1 ? 'day' : 'days'}',
    'Projects: ${metrics.repositories} · Reviews: ${metrics.reviews} · '
        'Merged PRs: ${metrics.pullRequestsMerged}',
  ];

  return lines.join('\n');
}
