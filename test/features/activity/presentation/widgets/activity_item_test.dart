import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/activity/presentation/widgets/activity_item.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_type_badge.dart';

void main() {
  group('ActivityItemData', () {
    test('creates with required fields', () {
      final data = ActivityItemData(
        type: ActivityType.pullRequestOpened,
        title: 'Test PR',
        repository: 'test/repo',
        timestamp: '2 hours ago',
      );

      expect(data.type, equals(ActivityType.pullRequestOpened));
      expect(data.title, equals('Test PR'));
      expect(data.repository, equals('test/repo'));
      expect(data.timestamp, equals('2 hours ago'));
      expect(data.subtitle, isNull);
      expect(data.identifier, isNull);
    });

    test('creates with optional fields', () {
      final data = ActivityItemData(
        type: ActivityType.pullRequestMerged,
        title: 'Merged PR',
        subtitle: 'Successfully merged',
        repository: 'org/repo',
        identifier: '#123',
        timestamp: '1 day ago',
      );

      expect(data.subtitle, equals('Successfully merged'));
      expect(data.identifier, equals('#123'));
    });
  });

  group('ActivityItem', () {
    late ActivityItemData testData;

    setUp(() {
      testData = ActivityItemData(
        type: ActivityType.pullRequestOpened,
        title: 'Add new feature',
        subtitle: 'Implements feature X',
        repository: 'test/repository',
        identifier: '#123',
        timestamp: '2 hours ago',
      );
    });

    testWidgets('renders activity type badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.byType(ActivityTypeBadge), findsOneWidget);
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('Add new feature'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('Implements feature X'), findsOneWidget);
    });

    testWidgets('renders repository name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('test/repository'), findsOneWidget);
    });

    testWidgets('renders identifier', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('#123'), findsOneWidget);
    });

    testWidgets('renders timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('2 hours ago'), findsOneWidget);
    });

    testWidgets('renders activity type label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: testData)),
        ),
      );

      expect(find.text('PR Opened'), findsOneWidget);
    });

    testWidgets('renders timeline connector when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ActivityItem(
                    data: testData,
                    showTimelineConnector: true,
                    isFirst: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Find the timeline dot
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('works without subtitle', (tester) async {
      final dataWithoutSubtitle = ActivityItemData(
        type: ActivityType.commitPushed,
        title: 'Fix bug',
        repository: 'org/repo',
        identifier: 'abc123',
        timestamp: '3 hours ago',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: dataWithoutSubtitle)),
        ),
      );

      expect(find.text('Fix bug'), findsOneWidget);
      expect(find.text('org/repo'), findsOneWidget);
    });

    testWidgets('works without identifier', (tester) async {
      final dataWithoutIdentifier = ActivityItemData(
        type: ActivityType.issueOpened,
        title: 'Bug report',
        repository: 'test/repo',
        timestamp: '1 hour ago',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: dataWithoutIdentifier)),
        ),
      );

      expect(find.text('Bug report'), findsOneWidget);
    });
  });

  group('ActivityItem timeline variants', () {
    testWidgets('renders merged PR correctly', (tester) async {
      final data = ActivityItemData(
        type: ActivityType.pullRequestMerged,
        title: 'Feature merged',
        repository: 'org/repo',
        identifier: '#456',
        timestamp: 'Yesterday',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: data)),
        ),
      );

      expect(find.text('PR Merged'), findsOneWidget);
      expect(find.text('Feature merged'), findsOneWidget);
    });

    testWidgets('renders issue closed correctly', (tester) async {
      final data = ActivityItemData(
        type: ActivityType.issueClosed,
        title: 'Bug fixed',
        repository: 'org/repo',
        identifier: '#789',
        timestamp: '2 days ago',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: data)),
        ),
      );

      expect(find.text('Issue Closed'), findsOneWidget);
    });

    testWidgets('renders mention received correctly', (tester) async {
      final data = ActivityItemData(
        type: ActivityType.mentionReceived,
        title: 'You were mentioned',
        repository: 'org/repo',
        timestamp: '3 days ago',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ActivityItem(data: data)),
        ),
      );

      expect(find.text('Mention'), findsOneWidget);
    });
  });
}
