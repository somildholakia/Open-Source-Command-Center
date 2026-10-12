import 'dart:convert';

import 'package:equatable/equatable.dart';

/// The only progression state the app persists.
///
/// Everything the intelligence engine computes is derived from normalized
/// provider data, so it is never stored — only the two facts a future data
/// window cannot recreate:
///
/// * which achievements have **ever** been unlocked (and when), so they never
///   re-lock when old activity scrolls out of the provider's window, and
/// * which quest instances have **ever** been completed
///   (`<questId>@<period>:<date>` keys), so lifetime quest counts survive.
///
/// Callers persist this record and pass it back into
/// `DeveloperIntelligenceEngine.compute`; the engine merges it with what the
/// current data shows. Nothing here is sensitive.
class ProgressionRecord extends Equatable {
  /// Achievement id -> UTC timestamp of the first unlock.
  final Map<String, DateTime> unlockedAchievements;

  /// Quest instance keys completed at least once.
  ///
  /// A key is `<questId>@<period>:<yyyy-MM-dd>` — the local date for daily
  /// quests and the local Monday for weekly quests.
  final Set<String> completedQuestKeys;

  const ProgressionRecord({
    this.unlockedAchievements = const {},
    this.completedQuestKeys = const {},
  });

  /// A record with no history.
  static const ProgressionRecord empty = ProgressionRecord();

  bool get isEmpty =>
      unlockedAchievements.isEmpty && completedQuestKeys.isEmpty;

  bool isAchievementUnlocked(String achievementId) =>
      unlockedAchievements.containsKey(achievementId);

  bool isQuestCompleted(String questKey) =>
      completedQuestKeys.contains(questKey);

  /// Quest instances completed across all time.
  int get completedQuestCount => completedQuestKeys.length;

  /// When [achievementId] was first unlocked, or null when it has never been
  /// recorded.
  DateTime? unlockedAt(String achievementId) =>
      unlockedAchievements[achievementId];

  /// This record plus [achievementId], keeping the earliest recorded unlock.
  ProgressionRecord withAchievement(String achievementId, DateTime at) {
    final existing = unlockedAchievements[achievementId];
    if (existing != null && !at.toUtc().isBefore(existing)) return this;
    return ProgressionRecord(
      unlockedAchievements: {
        ...unlockedAchievements,
        achievementId: at.toUtc(),
      },
      completedQuestKeys: completedQuestKeys,
    );
  }

  /// This record plus the completed quest instance [questKey].
  ProgressionRecord withQuestCompleted(String questKey) {
    if (completedQuestKeys.contains(questKey)) return this;
    return ProgressionRecord(
      unlockedAchievements: unlockedAchievements,
      completedQuestKeys: {...completedQuestKeys, questKey},
    );
  }

  /// This record merged with [other]; earliest unlock per achievement wins.
  ProgressionRecord merge(ProgressionRecord other) {
    if (other.isEmpty) return this;
    if (isEmpty) return other;
    final achievements = <String, DateTime>{...unlockedAchievements};
    for (final entry in other.unlockedAchievements.entries) {
      final existing = achievements[entry.key];
      if (existing == null || entry.value.isBefore(existing)) {
        achievements[entry.key] = entry.value;
      }
    }
    return ProgressionRecord(
      unlockedAchievements: achievements,
      completedQuestKeys: {...completedQuestKeys, ...other.completedQuestKeys},
    );
  }

  /// JSON-safe representation (achievement ids and ISO-8601 UTC timestamps).
  Map<String, Object?> toJson() => {
    'achievements': {
      for (final entry in unlockedAchievements.entries)
        entry.key: entry.value.toUtc().toIso8601String(),
    },
    'quests': (completedQuestKeys.toList()..sort()),
  };

  /// Parses a stored record. Malformed input yields [empty] — a corrupt
  /// progression file must never break the app.
  static ProgressionRecord decode(String? source) {
    if (source == null || source.trim().isEmpty) return empty;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return empty;

      final achievements = <String, DateTime>{};
      final rawAchievements = decoded['achievements'];
      if (rawAchievements is Map) {
        for (final entry in rawAchievements.entries) {
          final id = entry.key;
          final value = entry.value;
          if (id is! String || value is! String) continue;
          final parsed = DateTime.tryParse(value);
          if (parsed == null) continue;
          achievements[id] = parsed.toUtc();
        }
      }

      final quests = <String>{};
      final rawQuests = decoded['quests'];
      if (rawQuests is List) {
        for (final value in rawQuests) {
          if (value is String && value.isNotEmpty) quests.add(value);
        }
      }

      return ProgressionRecord(
        unlockedAchievements: achievements,
        completedQuestKeys: quests,
      );
    } catch (_) {
      return empty;
    }
  }

  /// [decode] applied to [toJson]'s JSON encoding.
  String encode() => jsonEncode(toJson());

  @override
  List<Object?> get props => [unlockedAchievements, completedQuestKeys];
}
