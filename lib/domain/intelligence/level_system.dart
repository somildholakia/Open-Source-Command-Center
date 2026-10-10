import 'package:equatable/equatable.dart';

/// Titles for each progression level, ordered cheapest-first.
///
/// The names follow the app's existing vocabulary (NOVICE, RISING DEVELOPER).
/// Levels above the list reuse the last title indefinitely.
const List<String> _levelTitles = [
  'NOVICE', // 1
  'RISING DEVELOPER', // 2
  'CONTRIBUTOR', // 3
  'BUILDER', // 4
  'MAINTAINER', // 5
  'ARCHITECT', // 6
  'OPEN SOURCE LEGEND', // 7
];

/// Centralized level progression.
///
/// Curve: completing level [level] costs `baseSpell * level` XP, so the total
/// XP needed to *reach* level `L` is `baseSpell * L * (L - 1)` (quadratic).
/// Early levels come quickly and later ones keep meaning. Nothing in the UI
/// knows this curve — it only renders [LevelProgress].
class LevelSystem {
  LevelSystem._();

  /// XP cost of the first level; every level costs `baseSpell` more than the
  /// previous one.
  static const int baseSpell = 50;

  /// Cumulative XP required to reach [level] (1-indexed). Level 1 is 0.
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return baseSpell * level * (level - 1);
  }

  /// XP required to complete [level] and advance to the next one.
  static int xpSpanForLevel(int level) {
    if (level < 1) return 0;
    return xpForLevel(level + 1) - xpForLevel(level);
  }

  /// Title label for [level] (1-indexed).
  static String titleForLevel(int level) {
    if (level <= 0) return _levelTitles.first;
    final index = level - 1;
    return index < _levelTitles.length
        ? _levelTitles[index]
        : _levelTitles.last;
  }

  /// Current level, progress inside it, and XP remaining.
  static LevelProgress compute(int totalXp, {int? maxLevel}) {
    final safeXp = totalXp < 0 ? 0 : totalXp;
    final level = _levelForXp(safeXp, maxLevel: maxLevel);
    final levelFloorXp = xpForLevel(level);
    final nextLevelXp = xpForLevel(level + 1);
    final span = nextLevelXp - levelFloorXp;
    final xpIntoLevel = safeXp - levelFloorXp;
    final capped = maxLevel != null && level >= maxLevel;
    final xpRemaining = nextLevelXp - safeXp;

    return LevelProgress(
      level: level,
      levelTitle: titleForLevel(level),
      totalXp: safeXp,
      xpIntoLevel: xpIntoLevel,
      xpForNextLevel: span,
      progress: capped || span <= 0
          ? (capped ? 1.0 : 0.0)
          : (xpIntoLevel / span).clamp(0.0, 1.0).toDouble(),
      xpRemaining: xpRemaining < 0 ? 0 : xpRemaining,
    );
  }

  /// Highest completed level whose threshold is met by [totalXp].
  static int _levelForXp(int totalXp, {int? maxLevel}) {
    int lo = 1;
    int hi = maxLevel ?? _upperBound(totalXp);
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (totalXp >= xpForLevel(mid)) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  static int _upperBound(int totalXp) {
    // Grow until we exceed the current threshold; bounded by the data window
    // the engine analyzes, so this never loops long.
    int candidate = 1;
    while (xpForLevel(candidate) <= totalXp) {
      candidate = candidate * 2;
    }
    return candidate;
  }
}

/// Result of resolving a developer's total XP into a level.
class LevelProgress extends Equatable {
  final int level;
  final String levelTitle;
  final int totalXp;

  /// XP earned inside the current level (`totalXp - xpForLevel(level)`).
  final int xpIntoLevel;

  /// XP the current level costs in total (its span, not a cumulative
  /// threshold). `xpIntoLevel / xpForNextLevel` is the level progress bar.
  final int xpForNextLevel;

  /// Progress inside the current level, 0.0–1.0.
  final double progress;

  /// XP still required to reach the next level.
  final int xpRemaining;

  const LevelProgress({
    required this.level,
    required this.levelTitle,
    required this.totalXp,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.progress,
    required this.xpRemaining,
  });

  @override
  List<Object?> get props => [
    level,
    levelTitle,
    totalXp,
    xpIntoLevel,
    xpForNextLevel,
    progress,
    xpRemaining,
  ];
}
