import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';

void main() {
  DeveloperActivity activityOf(DeveloperActivityType type, {int? commitCount}) {
    return DeveloperActivity(
      id: 'evt',
      type: type,
      repository: 'octocat/command-center',
      title: 'Test event',
      timestamp: DateTime(2026, 10, 5, 12),
      commitCount: commitCount,
    );
  }

  group('XpRules.forActivity', () {
    test('a push is worth its commit count at 5 XP per commit', () {
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.commitPushed, commitCount: 3),
        ),
        15,
      );
    });

    test('a push without a known commit count earns no commit XP', () {
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.commitPushed)),
        0,
      );
    });

    test('a bulk push is capped so imports cannot farm XP', () {
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.commitPushed, commitCount: 500),
        ),
        XpRules.maxCommitsPerPush * XpRules.perCommit,
      );
    });

    test('a zero-commit push is worth nothing', () {
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.commitPushed, commitCount: 0),
        ),
        0,
      );
    });

    test('every activity type has a deterministic value', () {
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.pullRequestOpened),
        ),
        XpRules.pullRequestOpened,
      );
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.pullRequestMerged),
        ),
        XpRules.pullRequestMerged,
      );
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.pullRequestClosed),
        ),
        XpRules.pullRequestClosed,
      );
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.pullRequestReviewed),
        ),
        XpRules.pullRequestReviewed,
      );
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.issueOpened)),
        XpRules.issueOpened,
      );
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.issueClosed)),
        XpRules.issueClosed,
      );
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.issueCommented)),
        XpRules.issueCommented,
      );
      expect(
        XpRules.forActivity(
          activityOf(DeveloperActivityType.repositoryCreated),
        ),
        XpRules.repositoryCreated,
      );
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.repositoryForked)),
        XpRules.repositoryForked,
      );
      expect(
        XpRules.forActivity(activityOf(DeveloperActivityType.releasePublished)),
        XpRules.releasePublished,
      );
    });

    test('starring a repository is tracked but never rewarded', () {
      expect(XpRules.forActivity(activityOf(DeveloperActivityType.starred)), 0);
      expect(XpRules.starred, 0);
    });
  });

  group('XpRules.baseFor', () {
    test('matches forActivity for every type (ignoring commit counts)', () {
      for (final type in DeveloperActivityType.values) {
        final expected = type == DeveloperActivityType.commitPushed
            ? XpRules.perCommit
            : XpRules.forActivity(activityOf(type));
        expect(XpRules.baseFor(type), expected, reason: type.name);
      }
    });
  });

  group('XpBreakdown', () {
    test(
      'total XP includes activity, consistency, achievements, and quests',
      () {
        const breakdown = XpBreakdown(
          activityXp: 120,
          activeDayXp: 30,
          achievementXp: 75,
          questXp: 50,
          totalXp: 275,
        );

        expect(
          breakdown.activityXp +
              breakdown.activeDayXp +
              breakdown.achievementXp +
              breakdown.questXp,
          breakdown.totalXp,
        );
      },
    );

    test('reports XP per activity type and defaults to zero', () {
      const breakdown = XpBreakdown(
        byActivityType: {DeveloperActivityType.commitPushed: 25},
        activityXp: 25,
        totalXp: 25,
      );

      expect(breakdown.xpFor(DeveloperActivityType.commitPushed), 25);
      expect(breakdown.xpFor(DeveloperActivityType.releasePublished), 0);
    });
  });
}
