import 'package:flutter_test/flutter_test.dart';
import 'package:opensource_command_center/domain/domain.dart';
import 'package:opensource_command_center/services/github/github_mappers.dart';

void main() {
  group('profileFromJson', () {
    test('maps the core GitHub user fields to DeveloperProfile', () {
      final profile = GitHubMappers.profileFromJson({
        'id': 583231,
        'login': 'octocat',
        'name': 'The Octocat',
        'avatar_url': 'https://avatars.githubusercontent.com/u/583231?v=4',
        'html_url': 'https://github.com/octocat',
        'bio': 'There once was...',
        'public_repos': 8,
        'followers': 18450,
        'following': 9,
        'created_at': '2011-01-25T18:44:36Z',
      });

      expect(profile.id, '583231');
      expect(profile.username, 'octocat');
      expect(profile.displayName, 'The Octocat');
      expect(profile.effectiveDisplayName, 'The Octocat');
      expect(profile.publicRepositoryCount, 8);
      expect(profile.followersCount, 18450);
      expect(profile.followingCount, 9);
      expect(profile.createdAt, DateTime.utc(2011, 1, 25, 18, 44, 36));
      expect(profile.profileUrl, 'https://github.com/octocat');
    });

    test('tolerates missing optional fields and empty name', () {
      final profile = GitHubMappers.profileFromJson({
        'id': 1,
        'login': 'ghost',
      });

      expect(profile.username, 'ghost');
      expect(profile.displayName, '');
      // Falls back to the login when no display name is set.
      expect(profile.effectiveDisplayName, 'ghost');
      expect(profile.publicRepositoryCount, isNull);
      expect(profile.createdAt, isNull);
    });
  });

  group('repositoryFromJson', () {
    test('maps repository fields including owner login', () {
      final repo = GitHubMappers.repositoryFromJson({
        'id': 1296269,
        'name': 'Hello-World',
        'full_name': 'octocat/Hello-World',
        'owner': {'login': 'octocat'},
        'description': 'My first repository',
        'private': false,
        'fork': true,
        'html_url': 'https://github.com/octocat/Hello-World',
        'default_branch': 'master',
        'language': 'Dart',
        'stargazers_count': 1500,
        'forks_count': 1200,
        'open_issues_count': 42,
        'updated_at': '2026-09-30T10:00:00Z',
      });

      expect(repo.fullName, 'octocat/Hello-World');
      expect(repo.owner, 'octocat');
      expect(repo.isFork, isTrue);
      expect(repo.language, 'Dart');
      expect(repo.stars, 1500);
      expect(repo.updatedAt, DateTime.utc(2026, 9, 30, 10));
    });

    test('derives owner from full_name when owner object is missing', () {
      final repo = GitHubMappers.repositoryFromJson({
        'id': 1,
        'name': 'repo',
        'full_name': 'someone/repo',
      });

      expect(repo.owner, 'someone');
    });

    test('repositoriesFromJson skips malformed entries', () {
      final repos = GitHubMappers.repositoriesFromJson([
        {'id': 1, 'name': 'a', 'full_name': 'o/a'},
        'not-a-map',
        42,
        {'id': 2, 'name': 'b', 'full_name': 'o/b'},
      ]);

      expect(repos, hasLength(2));
      expect(repos.map((repo) => repo.name), ['a', 'b']);
    });
  });

  group('activityFromJson', () {
    Map<String, dynamic> event(
      String type,
      Map<String, dynamic> payload, {
      String createdAt = '2026-10-01T12:00:00Z',
    }) {
      return {
        'id': 'evt-1',
        'type': type,
        'repo': {'name': 'octocat/hello-world'},
        'payload': payload,
        'created_at': createdAt,
      };
    }

    test('maps PushEvent with commit count and branch', () {
      final activity = GitHubMappers.activityFromJson(
        event('PushEvent', {
          'ref': 'refs/heads/main',
          'size': 3,
          'commits': [
            {'message': 'first'},
            {'message': 'second'},
            {'message': 'third'},
          ],
        }),
      );

      expect(activity, isNotNull);
      expect(activity!.type, DeveloperActivityType.commitPushed);
      expect(activity.repository, 'octocat/hello-world');
      expect(activity.title, 'Pushed 3 commits to main');
      expect(activity.subtitle, 'third');
      expect(activity.commitCount, 3);
    });

    test(
      'does not invent a zero commit count when push size is missing',
      () {
      final activity = GitHubMappers.activityFromJson(
        event('PushEvent', {
          'ref': 'refs/heads/feature/cartoon-local-first-redesign',
          'commits': <Map<String, dynamic>>[],
        }),
      );

      expect(activity, isNotNull);
      expect(
        activity!.title,
        'Pushed updates to feature/cartoon-local-first-redesign',
      );
      expect(activity.commitCount, isNull);
    });

    test(
      'uses payload size when the event omits its commit list',
      () {
      final activity = GitHubMappers.activityFromJson(
        event('PushEvent', {
          'ref': 'refs/heads/main',
          'size': 4,
        }),
      );

      expect(activity!.title, 'Pushed 4 commits to main');
      expect(activity.commitCount, 4);
    });

    test('maps opened and merged pull request events', () {
      final opened = GitHubMappers.activityFromJson(
        event('PullRequestEvent', {
          'action': 'opened',
          'pull_request': {'number': 12, 'title': 'Add feature'},
        }),
      );
      final merged = GitHubMappers.activityFromJson(
        event('PullRequestEvent', {
          'action': 'closed',
          'pull_request': {
            'number': 12,
            'title': 'Add feature',
            'merged': true,
          },
        }),
      );
      final closed = GitHubMappers.activityFromJson(
        event('PullRequestEvent', {
          'action': 'closed',
          'pull_request': {'number': 13, 'title': 'Revert', 'merged': false},
        }),
      );

      expect(opened!.type, DeveloperActivityType.pullRequestOpened);
      expect(opened.identifier, '#12');
      expect(merged!.type, DeveloperActivityType.pullRequestMerged);
      expect(merged.subtitle, 'Pull request merged');
      expect(closed!.type, DeveloperActivityType.pullRequestClosed);
    });

    test('drops pull request actions without user-facing meaning', () {
      final activity = GitHubMappers.activityFromJson(
        event('PullRequestEvent', {
          'action': 'synchronize',
          'pull_request': {'number': 1, 'title': 'x'},
        }),
      );

      expect(activity, isNull);
    });

    test('maps issues, comments and reviews', () {
      expect(
        GitHubMappers.activityFromJson(
          event('IssuesEvent', {
            'action': 'closed',
            'issue': {'number': 5, 'title': 'Bug'},
          }),
        )!.type,
        DeveloperActivityType.issueClosed,
      );
      expect(
        GitHubMappers.activityFromJson(
          event('IssuesEvent', {
            'action': 'opened',
            'issue': {'number': 6, 'title': 'Feature'},
          }),
        )!.type,
        DeveloperActivityType.issueOpened,
      );
      expect(
        GitHubMappers.activityFromJson(
          event('IssueCommentEvent', {
            'issue': {'number': 7, 'title': 'Discuss'},
          }),
        )!.type,
        DeveloperActivityType.issueCommented,
      );
      expect(
        GitHubMappers.activityFromJson(
          event('PullRequestReviewEvent', {
            'pull_request': {'number': 8, 'title': 'Review me'},
          }),
        )!.type,
        DeveloperActivityType.pullRequestReviewed,
      );
    });

    test('maps repository create/fork/release/star events', () {
      expect(
        GitHubMappers.activityFromJson(
          event('CreateEvent', {'ref_type': 'repository'}),
        )!.type,
        DeveloperActivityType.repositoryCreated,
      );
      // Branch/tag creation is not surfaced.
      expect(
        GitHubMappers.activityFromJson(
          event('CreateEvent', {'ref_type': 'branch'}),
        ),
        isNull,
      );
      expect(
        GitHubMappers.activityFromJson(event('ForkEvent', {}))!.type,
        DeveloperActivityType.repositoryForked,
      );
      expect(
        GitHubMappers.activityFromJson(
          event('ReleaseEvent', {
            'release': {'tag_name': 'v1.0.0', 'name': 'First release'},
          }),
        )!.type,
        DeveloperActivityType.releasePublished,
      );
      expect(
        GitHubMappers.activityFromJson(
          event('WatchEvent', {'action': 'started'}),
        )!.type,
        DeveloperActivityType.starred,
      );
    });

    test('drops unknown event types instead of guessing', () {
      expect(GitHubMappers.activityFromJson(event('GollumEvent', {})), isNull);
    });

    test(
      'activitiesFromJson skips malformed events without dropping valid ones',
      () {
        final activities = GitHubMappers.activitiesFromJson([
          event('PushEvent', {
            'ref': 'refs/heads/main',
            'commits': [
              {'message': 'valid push'},
            ],
          }),
          event('PullRequestEvent', {
            'action': 'opened',
            'pull_request': 'unexpected payload shape',
          }),
          event('ForkEvent', {}),
        ]);

        expect(activities, hasLength(2));
        expect(activities.map((activity) => activity.type), [
          DeveloperActivityType.commitPushed,
          DeveloperActivityType.repositoryForked,
        ]);
      },
    );

    test('activitiesFromJson filters unsupported events', () {
      final activities = GitHubMappers.activitiesFromJson([
        event('PushEvent', {
          'ref': 'refs/heads/main',
          'commits': [
            {'message': 'x'},
          ],
        }),
        event('GollumEvent', {}),
        event('ForkEvent', {}),
      ]);

      expect(activities, hasLength(2));
      expect(activities.map((a) => a.type), [
        DeveloperActivityType.commitPushed,
        DeveloperActivityType.repositoryForked,
      ]);
    });
  });

  group('contributionSummaryFromGraphQL', () {
    test('flattens contribution weeks into date-keyed counts', () {
      final summary = GitHubMappers.contributionSummaryFromGraphQL({
        'totalContributions': 5,
        'weeks': [
          {
            'contributionDays': [
              {'date': '2026-09-28', 'contributionCount': 2},
              {'date': '2026-09-29', 'contributionCount': 0},
            ],
          },
          {
            'contributionDays': [
              {'date': '2026-10-01', 'contributionCount': 3},
            ],
          },
        ],
      });

      expect(summary.total, 5);
      expect(summary.countForDate(DateTime(2026, 9, 28)), 2);
      expect(summary.countForDate(DateTime(2026, 9, 29)), 0);
      expect(summary.countForDate(DateTime(2026, 10, 1)), 3);
      expect(summary.fetchedAt, isNotNull);
    });

    test('returns an empty summary for an empty calendar', () {
      final summary = GitHubMappers.contributionSummaryFromGraphQL({});

      expect(summary.total, 0);
      expect(summary.dailyCounts, isEmpty);
    });
  });
}
