import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/activity/presentation/widgets/activity_type_badge.dart';

void main() {
  group('ActivityTypeBadge', () {
    testWidgets('renders with correct icon for pullRequestOpened', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.pullRequestOpened),
          ),
        ),
      );

      expect(find.byIcon(Icons.merge_type_rounded), findsOneWidget);
    });

    testWidgets('renders with correct icon for pullRequestMerged', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.pullRequestMerged),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders with correct icon for issueOpened', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.issueOpened),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders with correct icon for commitPushed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.commitPushed),
          ),
        ),
      );

      expect(find.byIcon(Icons.commit_rounded), findsOneWidget);
    });

    testWidgets('renders with correct icon for reviewRequested', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.reviewRequested),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });

    testWidgets('renders with correct icon for mentionReceived', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(type: ActivityType.mentionReceived),
          ),
        ),
      );

      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityTypeBadge(
              type: ActivityType.pullRequestOpened,
              size: 48,
            ),
          ),
        ),
      );

      expect(find.byType(ActivityTypeBadge), findsOneWidget);
    });
  });

  group('ActivityType enum', () {
    test('all activity types have labels', () {
      for (final type in ActivityType.values) {
        expect(type.label, isNotEmpty);
      }
    });

    test('all activity types have icons', () {
      for (final type in ActivityType.values) {
        expect(type.icon, isNotNull);
      }
    });

    test('all activity types have colors', () {
      for (final type in ActivityType.values) {
        expect(type.color, isNotNull);
      }
    });

    test('activity type labels are human-readable', () {
      expect(ActivityType.pullRequestOpened.label, equals('PR Opened'));
      expect(ActivityType.pullRequestMerged.label, equals('PR Merged'));
      expect(ActivityType.pullRequestClosed.label, equals('PR Closed'));
      expect(ActivityType.pullRequestReviewed.label, equals('PR Reviewed'));
      expect(ActivityType.issueOpened.label, equals('Issue Opened'));
      expect(ActivityType.issueClosed.label, equals('Issue Closed'));
      expect(ActivityType.issueCommented.label, equals('Issue Comment'));
      expect(ActivityType.commitPushed.label, equals('Commit'));
      expect(ActivityType.reviewRequested.label, equals('Review Request'));
      expect(ActivityType.mentionReceived.label, equals('Mention'));
    });
  });
}
