import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

void main() {
  final unlockedAt = DateTime.utc(2026, 9, 1, 8, 30);

  group('construction', () {
    test('the empty record has no history', () {
      expect(ProgressionRecord.empty.isEmpty, isTrue);
      expect(ProgressionRecord.empty.completedQuestCount, 0);
      expect(ProgressionRecord.empty.isAchievementUnlocked('anything'), isFalse);
      expect(ProgressionRecord.empty.isQuestCompleted('anything'), isFalse);
    });

    test('adding an achievement keeps the earliest unlock', () {
      final first = ProgressionRecord.empty.withAchievement(
        'first_merge',
        unlockedAt,
      );
      final later = first.withAchievement(
        'first_merge',
        DateTime.utc(2026, 9, 5),
      );
      final earlier = first.withAchievement(
        'first_merge',
        DateTime.utc(2026, 8, 1),
      );

      expect(later.unlockedAt('first_merge'), unlockedAt);
      expect(earlier.unlockedAt('first_merge'), DateTime.utc(2026, 8, 1));
      expect(earlier.completedQuestCount, 0);
    });

    test('completing the same quest twice does not double count', () {
      final once = ProgressionRecord.empty.withQuestCompleted(
        'daily_commit@daily:2026-10-08',
      );
      final twice = once.withQuestCompleted('daily_commit@daily:2026-10-08');

      expect(twice.completedQuestCount, 1);
      expect(identical(twice, once), isTrue);
    });

    test('unlock timestamps are normalized to UTC', () {
      final local = ProgressionRecord.empty.withAchievement(
        'first_merge',
        DateTime(2026, 9, 1, 8, 30),
      );

      expect(local.unlockedAt('first_merge')!.isUtc, isTrue);
    });
  });

  group('merge', () {
    test('unions quests and keeps the earliest achievement unlock', () {
      final left = ProgressionRecord(
        unlockedAchievements: {'first_merge': DateTime.utc(2026, 9, 5)},
        completedQuestKeys: const {'daily_commit@daily:2026-10-08'},
      );
      final right = ProgressionRecord(
        unlockedAchievements: {'first_merge': unlockedAt},
        completedQuestKeys: const {'weekly_issues@weekly:2026-10-05'},
      );

      final merged = left.merge(right);

      expect(merged.unlockedAt('first_merge'), unlockedAt);
      expect(merged.completedQuestCount, 2);
    });

    test('merging with an empty record is a no-op', () {
      final record = ProgressionRecord(
        unlockedAchievements: {'first_merge': unlockedAt},
        completedQuestKeys: const {'daily_commit@daily:2026-10-08'},
      );

      expect(record.merge(ProgressionRecord.empty), record);
      expect(ProgressionRecord.empty.merge(record), record);
    });
  });

  group('serialization', () {
    test('round-trips through encode and decode', () {
      final record = ProgressionRecord(
        unlockedAchievements: {'first_merge': unlockedAt, 'warm_up': unlockedAt},
        completedQuestKeys: const {
          'daily_commit@daily:2026-10-08',
          'weekly_issues@weekly:2026-10-05',
        },
      );

      final restored = ProgressionRecord.decode(record.encode());

      expect(restored, record);
      expect(restored.unlockedAt('warm_up'), unlockedAt);
      expect(restored.completedQuestCount, 2);
    });

    test('an empty record round-trips to an equal record', () {
      expect(ProgressionRecord.decode(ProgressionRecord.empty.encode()),
          ProgressionRecord.empty);
    });

    test('malformed input degrades to an empty record instead of throwing', () {
      expect(ProgressionRecord.decode(null), ProgressionRecord.empty);
      expect(ProgressionRecord.decode(''), ProgressionRecord.empty);
      expect(ProgressionRecord.decode('   '), ProgressionRecord.empty);
      expect(ProgressionRecord.decode('not json'), ProgressionRecord.empty);
      expect(ProgressionRecord.decode('[]'), ProgressionRecord.empty);
      expect(ProgressionRecord.decode('{}'), ProgressionRecord.empty);
      expect(
        ProgressionRecord.decode('{"achievements": 5, "quests": "nope"}'),
        ProgressionRecord.empty,
      );
    });

    test('invalid entries inside a valid payload are skipped', () {
      final restored = ProgressionRecord.decode(
        '{"achievements": {"ok": "2026-09-01T08:30:00.000Z", "bad": 3},'
        ' "quests": ["valid", 7, ""]}',
      );

      expect(restored.isAchievementUnlocked('ok'), isTrue);
      expect(restored.isAchievementUnlocked('bad'), isFalse);
      expect(restored.completedQuestCount, 1);
      expect(restored.isQuestCompleted('valid'), isTrue);
    });
  });

  group('equality', () {
    test('records with the same history are equal', () {
      final a = ProgressionRecord(
        unlockedAchievements: {'first_merge': unlockedAt},
        completedQuestKeys: const {'daily_commit@daily:2026-10-08'},
      );
      final b = ProgressionRecord(
        unlockedAchievements: {'first_merge': unlockedAt},
        completedQuestKeys: const {'daily_commit@daily:2026-10-08'},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
