import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/progression/progression_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryProgressionStore', () {
    test('starts empty per account', () {
      final store = InMemoryProgressionStore();

      expect(store.load('github:octocat'), ProgressionRecord.empty);
      expect(store.load('github:someone-else'), ProgressionRecord.empty);
    });

    test('saves and loads per account', () async {
      final store = InMemoryProgressionStore();
      final record = ProgressionRecord.empty
          .withAchievement('first_merge', DateTime.utc(2026, 9, 1))
          .withQuestCompleted('daily_commit@daily:2026-10-08');

      await store.save('github:octocat', record);

      expect(store.load('github:octocat'), record);
      expect(store.load('github:someone-else'), ProgressionRecord.empty);
    });

    test('clear removes only the requested account', () async {
      final store = InMemoryProgressionStore();
      await store.save(
        'github:octocat',
        ProgressionRecord.empty.withAchievement('a', DateTime.utc(2026, 9, 1)),
      );
      await store.save(
        'github:other',
        ProgressionRecord.empty.withAchievement('b', DateTime.utc(2026, 9, 1)),
      );

      await store.clear('github:octocat');

      expect(store.load('github:octocat'), ProgressionRecord.empty);
      expect(store.load('github:other').isAchievementUnlocked('b'), isTrue);
    });
  });

  group('SharedPrefsProgressionStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips a record through preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsProgressionStore(prefs);
      final record = ProgressionRecord.empty
          .withAchievement('first_merge', DateTime.utc(2026, 9, 1))
          .withQuestCompleted('daily_commit@daily:2026-10-08');

      await store.save('github:octocat', record);
      final reloaded = SharedPrefsProgressionStore(prefs);

      expect(reloaded.load('github:octocat'), record);
    });

    test('keeps accounts separate', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsProgressionStore(prefs);

      await store.save(
        'github:octocat',
        ProgressionRecord.empty.withAchievement('a', DateTime.utc(2026, 9, 1)),
      );

      expect(store.load('github:other'), ProgressionRecord.empty);
    });

    test('clear removes the stored value', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsProgressionStore(prefs);
      await store.save(
        'github:octocat',
        ProgressionRecord.empty.withAchievement('a', DateTime.utc(2026, 9, 1)),
      );

      await store.clear('github:octocat');

      expect(store.load('github:octocat'), ProgressionRecord.empty);
      expect(
        SharedPrefsProgressionStore(prefs).load('github:octocat'),
        ProgressionRecord.empty,
      );
    });

    test('a corrupt stored value degrades to an empty record', () async {
      SharedPreferences.setMockInitialValues({
        'progression_record_v1:github:octocat': 'not json',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = SharedPrefsProgressionStore(prefs);

      expect(store.load('github:octocat'), ProgressionRecord.empty);
    });
  });

  group('loadProgressionStore', () {
    test('returns a usable store', () async {
      SharedPreferences.setMockInitialValues({});

      final store = await loadProgressionStore();

      expect(store.load('github:octocat'), ProgressionRecord.empty);
    });
  });
}
