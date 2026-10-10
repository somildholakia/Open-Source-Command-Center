import 'package:flutter/material.dart';

import 'activity_item.dart';
import 'activity_timeline.dart';
import 'activity_type_badge.dart';

/// Sample timeline shown while no provider is connected.
///
/// Phase 2: this is **sample data** and is always rendered below an explicit
/// "sample data" notice — never presented as the developer's real GitHub
/// activity. Once GitHub is connected, [ActivityTimeline] renders mapped
/// domain activity instead.
class ActivityTimelinePlaceholder extends StatelessWidget {
  const ActivityTimelinePlaceholder({super.key});

  /// Sample activity items demonstrating varied event types.
  static final List<ActivityItemData> sampleActivities = [
    ActivityItemData(
      type: ActivityType.pullRequestMerged,
      title: 'Add responsive dashboard layout',
      subtitle: 'Merged by maintainer',
      repository: 'flutter/flutter',
      identifier: '#142857',
      timestamp: '2 hours ago',
    ),
    ActivityItemData(
      type: ActivityType.reviewRequested,
      title: 'Review requested: Implement authentication flow',
      repository: 'firebase/flutterfire',
      identifier: '#89234',
      timestamp: '4 hours ago',
    ),
    ActivityItemData(
      type: ActivityType.commitPushed,
      title: 'feat: add activity timeline component',
      subtitle: '3 files changed, +245 additions',
      repository: 'developer/command-center',
      identifier: 'a3f9c21',
      timestamp: '5 hours ago',
    ),
    ActivityItemData(
      type: ActivityType.pullRequestReviewed,
      title: 'Code review: Fix navigation state handling',
      subtitle: 'Approved with suggestions',
      repository: 'material/material-ui',
      identifier: '#67890',
      timestamp: 'Yesterday',
    ),
    ActivityItemData(
      type: ActivityType.issueCommented,
      title: 'Commented on: Memory leak in image loading',
      subtitle: 'Provided reproduction steps',
      repository: 'dart-lang/sdk',
      identifier: '#51234',
      timestamp: 'Yesterday',
    ),
    ActivityItemData(
      type: ActivityType.pullRequestOpened,
      title: 'refactor: migrate to latest bloc version',
      subtitle: 'Breaking changes, needs review',
      repository: 'bloc/bloc',
      identifier: '#45678',
      timestamp: '2 days ago',
    ),
    ActivityItemData(
      type: ActivityType.issueOpened,
      title: 'Feature request: Dark mode support',
      subtitle: 'Enhancement · Open for discussion',
      repository: 'community/awesome-app',
      identifier: '#12345',
      timestamp: '2 days ago',
    ),
    ActivityItemData(
      type: ActivityType.mentionReceived,
      title: 'Mentioned in: Performance optimization discussion',
      repository: 'google/flutter-samples',
      identifier: '#78901',
      timestamp: '3 days ago',
    ),
    ActivityItemData(
      type: ActivityType.issueClosed,
      title: 'Resolved: Build failing on Android 12',
      subtitle: 'Fixed and verified',
      repository: 'flutter/packages',
      identifier: '#23456',
      timestamp: '4 days ago',
    ),
    ActivityItemData(
      type: ActivityType.pullRequestClosed,
      title: 'Closed without merge: Experimental API changes',
      subtitle: 'Superseded by #45680',
      repository: 'dart-lang/language',
      identifier: '#45679',
      timestamp: '5 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ActivityTimeline(items: sampleActivities);
  }
}
