import '../../domain/domain.dart';

/// Mappers from GitHub API payloads to normalized domain entities.
///
/// Keep every GitHub field name inside this file: UI and feature layers only
/// ever see domain entities. Unknown/unsupported events are dropped (null)
/// rather than forced into a wrong category.
class GitHubMappers {
  GitHubMappers._();

  // ---------------------------------------------------------------------------
  // User → DeveloperProfile
  // ---------------------------------------------------------------------------

  /// Maps `GET /user` / `GET /users/{login}` to [DeveloperProfile].
  static DeveloperProfile profileFromJson(Map<String, dynamic> json) {
    return DeveloperProfile(
      id: (json['id'] ?? '').toString(),
      username: (json['login'] ?? '') as String,
      displayName: (json['name'] ?? '') as String? ?? '',
      avatarUrl: (json['avatar_url'] ?? '') as String? ?? '',
      profileUrl: (json['html_url'] ?? '') as String? ?? '',
      bio: (json['bio'] ?? '') as String? ?? '',
      publicRepositoryCount: (json['public_repos'] as num?)?.toInt(),
      followersCount: (json['followers'] as num?)?.toInt(),
      followingCount: (json['following'] as num?)?.toInt(),
      createdAt: _parseDate(json['created_at'] as String?),
    );
  }

  // ---------------------------------------------------------------------------
  // Repository JSON → Repository
  // ---------------------------------------------------------------------------

  /// Maps a GitHub repository payload to [Repository].
  static Repository repositoryFromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return Repository(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '') as String,
      fullName: (json['full_name'] ?? '') as String,
      owner: owner is Map<String, dynamic>
          ? (owner['login'] ?? '') as String
          : ((json['full_name'] ?? '/') as String).split('/').first,
      description: (json['description'] ?? '') as String? ?? '',
      isPrivate: (json['private'] ?? false) as bool,
      isFork: (json['fork'] ?? false) as bool,
      url: (json['html_url'] ?? '') as String? ?? '',
      defaultBranch: (json['default_branch'] ?? '') as String? ?? '',
      language: (json['language'] ?? '') as String? ?? '',
      stars: (json['stargazers_count'] as num?)?.toInt(),
      forks: (json['forks_count'] as num?)?.toInt(),
      openIssues: (json['open_issues_count'] as num?)?.toInt(),
      updatedAt: _parseDate(json['updated_at'] as String?),
    );
  }

  /// Maps a list of repository payloads, skipping malformed entries.
  static List<Repository> repositoriesFromJson(List<dynamic> jsonList) {
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(repositoryFromJson)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Event JSON → DeveloperActivity
  // ---------------------------------------------------------------------------

  /// Maps a GitHub events-API payload to [DeveloperActivity].
  ///
  /// Returns null for unsupported/unknown event types so the timeline only
  /// shows meaningful normalized activity.
  static DeveloperActivity? activityFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final repo = json['repo'];
    final repository = repo is Map<String, dynamic>
        ? (repo['name'] ?? '') as String
        : '';
    final payload = (json['payload'] ?? const {}) as Map<String, dynamic>;
    final timestamp =
        _parseDate(json['created_at'] as String?) ?? DateTime.now();
    final id = (json['id'] ?? '').toString();

    switch (type) {
      case 'PushEvent':
        final commits = payload['commits'];
        // The Events API commonly omits the commit list. Prefer its size
        // field in that case, and never display a fabricated "0 commits"
        // when GitHub does not provide a count.
        final payloadSize = (payload['size'] as num?)?.toInt();
        final count = commits is List && commits.isNotEmpty
            ? commits.length
            : (payloadSize != null && payloadSize > 0 ? payloadSize : null);
        final ref = (payload['ref'] ?? '') as String? ?? '';
        final branch = ref.replaceFirst('refs/heads/', '');
        final lastMessage = commits is List && commits.isNotEmpty
            ? ((commits.last as Map<String, dynamic>)['message'] ?? '')
                  as String
            : null;
        final destination = branch.isEmpty ? 'a branch' : branch;
        final title = count == null
            ? 'Pushed updates to $destination'
            : 'Pushed $count commit${count == 1 ? '' : 's'} to $destination';
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.commitPushed,
          repository: repository,
          title: title,
          subtitle: lastMessage,
          rawType: type,
          timestamp: timestamp,
          commitCount: count,
        );

      case 'PullRequestEvent':
        final pr =
            (payload['pull_request'] ?? const {}) as Map<String, dynamic>;
        final action = (payload['action'] ?? '') as String;
        final merged = (pr['merged'] ?? false) as bool;
        final number = (pr['number'] as num?)?.toInt();
        final title = (pr['title'] ?? '') as String;
        DeveloperActivityType activityType;
        switch (action) {
          case 'opened':
          case 'reopened':
            activityType = DeveloperActivityType.pullRequestOpened;
            break;
          case 'closed':
            activityType = merged
                ? DeveloperActivityType.pullRequestMerged
                : DeveloperActivityType.pullRequestClosed;
            break;
          default:
            return null; // synchronize etc. — no user-facing meaning yet
        }
        return DeveloperActivity(
          id: id,
          type: activityType,
          repository: repository,
          title: title,
          identifier: number == null ? null : '#$number',
          subtitle: _prActionLabel(action, merged),
          rawType: type,
          timestamp: timestamp,
        );

      case 'PullRequestReviewEvent':
        final pr =
            (payload['pull_request'] ?? const {}) as Map<String, dynamic>;
        final number = (pr['number'] as num?)?.toInt();
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.pullRequestReviewed,
          repository: repository,
          title: (pr['title'] ?? '') as String,
          identifier: number == null ? null : '#$number',
          subtitle: 'Reviewed pull request',
          rawType: type,
          timestamp: timestamp,
        );

      case 'PullRequestReviewCommentEvent':
        final pr =
            (payload['pull_request'] ?? const {}) as Map<String, dynamic>;
        final number = (pr['number'] as num?)?.toInt();
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.pullRequestReviewed,
          repository: repository,
          title: (pr['title'] ?? '') as String,
          identifier: number == null ? null : '#$number',
          subtitle: 'Commented on pull request review',
          rawType: type,
          timestamp: timestamp,
        );

      case 'IssuesEvent':
        final issue = (payload['issue'] ?? const {}) as Map<String, dynamic>;
        final action = (payload['action'] ?? '') as String;
        final number = (issue['number'] as num?)?.toInt();
        final activityType = action == 'closed'
            ? DeveloperActivityType.issueClosed
            : DeveloperActivityType.issueOpened;
        return DeveloperActivity(
          id: id,
          type: activityType,
          repository: repository,
          title: (issue['title'] ?? '') as String,
          identifier: number == null ? null : '#$number',
          subtitle: _issueActionLabel(action),
          rawType: type,
          timestamp: timestamp,
        );

      case 'IssueCommentEvent':
        final issue = (payload['issue'] ?? const {}) as Map<String, dynamic>;
        final number = (issue['number'] as num?)?.toInt();
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.issueCommented,
          repository: repository,
          title: (issue['title'] ?? '') as String,
          identifier: number == null ? null : '#$number',
          subtitle: 'Commented on issue',
          rawType: type,
          timestamp: timestamp,
        );

      case 'CreateEvent':
        if ((payload['ref_type'] ?? '') as String != 'repository') {
          return null; // branch/tag creation — not surfaced yet
        }
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.repositoryCreated,
          repository: repository,
          title: 'Created repository',
          rawType: type,
          timestamp: timestamp,
        );

      case 'ForkEvent':
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.repositoryForked,
          repository: repository,
          title: 'Forked repository',
          rawType: type,
          timestamp: timestamp,
        );

      case 'ReleaseEvent':
        final release =
            (payload['release'] ?? const {}) as Map<String, dynamic>;
        final tag = (release['tag_name'] ?? '') as String? ?? '';
        final name = (release['name'] ?? '') as String? ?? '';
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.releasePublished,
          repository: repository,
          title: name.isNotEmpty ? name : 'Published release',
          identifier: tag.isNotEmpty ? tag : null,
          rawType: type,
          timestamp: timestamp,
        );

      case 'WatchEvent':
        if ((payload['action'] ?? '') as String != 'started') {
          return null;
        }
        return DeveloperActivity(
          id: id,
          type: DeveloperActivityType.starred,
          repository: repository,
          title: 'Starred repository',
          rawType: type,
          timestamp: timestamp,
        );

      default:
        return null;
    }
  }

  /// Maps a list of event payloads, dropping unsupported entries.
  static List<DeveloperActivity> activitiesFromJson(List<dynamic> jsonList) {
    final activities = <DeveloperActivity>[];
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      try {
        final activity = activityFromJson(item);
        if (activity != null) activities.add(activity);
      } catch (_) {
        // Ignore malformed event payloads without discarding valid activity.
      }
    }
    return activities.toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // GraphQL contribution calendar → ContributionSummary
  // ---------------------------------------------------------------------------

  /// Maps the `viewer.contributionsCollection.contributionCalendar` payload
  /// to a [ContributionSummary] keyed by `yyyy-MM-dd`.
  static ContributionSummary contributionSummaryFromGraphQL(
    Map<String, dynamic> calendar,
  ) {
    final counts = <String, int>{};
    final weeks = calendar['weeks'];
    if (weeks is List) {
      for (final week in weeks.whereType<Map<String, dynamic>>()) {
        final days = week['contributionDays'];
        if (days is! List) continue;
        for (final day in days.whereType<Map<String, dynamic>>()) {
          final date = _parseDate(day['date'] as String?);
          final count = (day['contributionCount'] as num?)?.toInt() ?? 0;
          if (date == null) continue;
          counts[_dateKey(date)] = count;
        }
      }
    }
    return ContributionSummary(dailyCounts: counts, fetchedAt: DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _prActionLabel(String action, bool merged) {
    if (action == 'closed' && merged) return 'Pull request merged';
    if (action == 'closed') return 'Pull request closed';
    if (action == 'reopened') return 'Pull request reopened';
    return 'Pull request opened';
  }

  static String _issueActionLabel(String action) {
    switch (action) {
      case 'closed':
        return 'Issue closed';
      case 'reopened':
        return 'Issue reopened';
      default:
        return 'Issue opened';
    }
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }
}
