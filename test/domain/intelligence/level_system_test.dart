import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

void main() {
  group('LevelSystem.xpForLevel', () {
    test('level 1 is free and thresholds stay on the documented curve', () {
      expect(LevelSystem.xpForLevel(0), 0);
      expect(LevelSystem.xpForLevel(1), 0);
      expect(LevelSystem.xpForLevel(2), 100);
      expect(LevelSystem.xpForLevel(3), 300);
      expect(LevelSystem.xpForLevel(4), 600);
      expect(LevelSystem.xpForLevel(5), 1000);
    });

    test('each level costs 50 XP more than the previous one', () {
      expect(LevelSystem.xpSpanForLevel(1), 100);
      expect(LevelSystem.xpSpanForLevel(2), 200);
      expect(LevelSystem.xpSpanForLevel(3), 300);
      expect(LevelSystem.xpSpanForLevel(1), LevelSystem.baseSpell * 2);
    });
  });

  group('LevelSystem.compute', () {
    test('zero XP is level 1 with an empty progress bar', () {
      final progress = LevelSystem.compute(0);

      expect(progress.level, 1);
      expect(progress.levelTitle, 'NOVICE');
      expect(progress.xpIntoLevel, 0);
      expect(progress.xpForNextLevel, 100);
      expect(progress.progress, 0.0);
      expect(progress.xpRemaining, 100);
    });

    test('progress is measured inside the current level, not cumulatively', () {
      final progress = LevelSystem.compute(250);

      expect(progress.level, 2);
      expect(progress.levelTitle, 'RISING DEVELOPER');
      expect(progress.xpIntoLevel, 150); // 250 - 100
      expect(progress.xpForNextLevel, 200); // level 3 costs 300 - 100
      expect(progress.progress, closeTo(0.75, 0.0001));
      expect(progress.xpRemaining, 50); // 300 - 250
    });

    test('exactly reaching a threshold levels up with zero remaining', () {
      final progress = LevelSystem.compute(100);

      expect(progress.level, 2);
      expect(progress.xpIntoLevel, 0);
      expect(progress.progress, 0.0);
      expect(progress.xpRemaining, 200);
    });

    test('99 XP is still level 1 with a nearly full bar', () {
      final progress = LevelSystem.compute(99);

      expect(progress.level, 1);
      expect(progress.progress, closeTo(0.99, 0.0001));
      expect(progress.xpRemaining, 1);
    });

    test('progress never exceeds 1.0', () {
      for (final xp in [0, 50, 100, 299, 300, 1000, 5000, 100000]) {
        final progress = LevelSystem.compute(xp);
        expect(progress.progress, inInclusiveRange(0.0, 1.0), reason: '$xp');
      }
    });

    test('negative totals clamp to level 1 at 0 XP', () {
      final progress = LevelSystem.compute(-40);

      expect(progress.level, 1);
      expect(progress.totalXp, 0);
      expect(progress.xpRemaining, 100);
    });

    test('maxLevel caps progression and fills the bar', () {
      final progress = LevelSystem.compute(99999, maxLevel: 3);

      expect(progress.level, 3);
      expect(progress.progress, 1.0);
      expect(progress.xpRemaining, 0);
    });
  });

  group('level titles', () {
    test('map to the app vocabulary and never run out', () {
      expect(LevelSystem.titleForLevel(1), 'NOVICE');
      expect(LevelSystem.titleForLevel(2), 'RISING DEVELOPER');
      expect(LevelSystem.titleForLevel(3), 'CONTRIBUTOR');
      expect(LevelSystem.titleForLevel(7), 'OPEN SOURCE LEGEND');
      expect(LevelSystem.titleForLevel(40), 'OPEN SOURCE LEGEND');
    });

    test('a level always resolves to a non-empty title', () {
      for (var level = 1; level <= 30; level++) {
        expect(LevelSystem.titleForLevel(level), isNotEmpty);
      }
    });
  });

  group('LevelProgress', () {
    test('two progress values are equal when every field matches', () {
      expect(LevelSystem.compute(250), LevelSystem.compute(250));
      expect(LevelSystem.compute(250), isNot(LevelSystem.compute(251)));
    });
  });
}
