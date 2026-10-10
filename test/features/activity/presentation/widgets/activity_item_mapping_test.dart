import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_item.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_type_badge.dart';

void main() {
  group('activityTypeFromDomain', () {
    test('maps every domain activity type to a presentation type', () {
      const expected = <DeveloperActivityType, ActivityType>{
        DeveloperActivityType.commitPushed: ActivityType.commitPushed,
        DeveloperActivityType.pullRequestOpened: ActivityType.pullRequestOpened,
        DeveloperActivityType.pullRequestClosed: ActivityType.pullRequestClosed,
        DeveloperActivityType.pullRequestMerged: ActivityType.pullRequestMerged,
        DeveloperActivityType.pullRequestReviewed:
            ActivityType.pullRequestReviewed,
        DeveloperActivityType.issueOpened: ActivityType.issueOpened,
        DeveloperActivityType.issueClosed: ActivityType.issueClosed,
        DeveloperActivityType.issueCommented: ActivityType.issueCommented,
        DeveloperActivityType.repositoryCreated: ActivityType.repositoryCreated,
        DeveloperActivityType.repositoryForked: ActivityType.repositoryForked,
        DeveloperActivityType.releasePublished: ActivityType.releasePublished,
        DeveloperActivityType.starred: ActivityType.starred,
      };

      for (final entry in expected.entries) {
        expect(activityTypeFromDomain(entry.key), entry.value);
      }

      // Every domain type is covered (guards against silent drift).
      expect(expected.keys.toSet(), DeveloperActivityType.values.toSet());
    });
  });

  group('ActivityItemData.fromDomain', () {
    test('carries title, subtitle, repository and identifier through', () {
      final activity = DeveloperActivity(
        id: 'e1',
        type: DeveloperActivityType.pullRequestMerged,
        repository: 'octocat/hello-world',
        title: 'Add provider abstraction',
        subtitle: 'Pull request merged',
        identifier: '#42',
        rawType: 'PullRequestEvent',
        timestamp: DateTime(2026, 10, 1, 12),
      );

      final item = ActivityItemData.fromDomain(
        activity,
        now: DateTime(2026, 10, 1, 14),
      );

      expect(item.type, ActivityType.pullRequestMerged);
      expect(item.title, 'Add provider abstraction');
      expect(item.subtitle, 'Pull request merged');
      expect(item.repository, 'octocat/hello-world');
      expect(item.identifier, '#42');
      expect(item.timestamp, '2 hours ago');
    });

    test('formats older timestamps as relative labels', () {
      final activity = DeveloperActivity(
        id: 'e2',
        type: DeveloperActivityType.commitPushed,
        repository: 'octocat/repo',
        title: 'Pushed 1 commit to main',
        timestamp: DateTime(2026, 9, 28, 9),
        commitCount: 1,
      );

      final item = ActivityItemData.fromDomain(
        activity,
        now: DateTime(2026, 10, 1, 12),
      );

      expect(item.timestamp, '3 days ago');
      expect(item.subtitle, isNull);
    });
  });
}
