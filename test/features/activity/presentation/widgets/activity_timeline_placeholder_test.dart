import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/activity/presentation/widgets/activity_timeline_placeholder.dart';
import 'package:opensource_command_center/features/activity/presentation/widgets/activity_item.dart';

void main() {
  group('ActivityTimelinePlaceholder', () {
    testWidgets('renders multiple activity items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // Should render 10 mock activities
      expect(find.byType(ActivityItem), findsNWidgets(10));
    });

    testWidgets('renders end of timeline indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      expect(find.text('All caught up!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsNWidgets(2));
    });

    testWidgets('renders varied activity types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // Check for different activity type labels
      expect(find.text('PR Merged'), findsOneWidget);
      expect(find.text('Review Request'), findsOneWidget);
      expect(find.text('Commit'), findsOneWidget);
      expect(find.text('PR Reviewed'), findsOneWidget);
      expect(find.text('Issue Comment'), findsOneWidget);
      expect(find.text('PR Opened'), findsOneWidget);
      expect(find.text('Issue Opened'), findsOneWidget);
      expect(find.text('Mention'), findsOneWidget);
      expect(find.text('Issue Closed'), findsOneWidget);
      expect(find.text('PR Closed'), findsOneWidget);
    });

    testWidgets('renders activity titles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // Check for some of the mock activity titles
      expect(find.text('Add responsive dashboard layout'), findsOneWidget);
      expect(
        find.text('feat: add activity timeline component'),
        findsOneWidget,
      );
    });

    testWidgets('renders repository names', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // Check for repository names
      expect(find.text('flutter/flutter'), findsOneWidget);
      expect(find.text('firebase/flutterfire'), findsOneWidget);
      expect(find.text('developer/command-center'), findsOneWidget);
    });

    testWidgets('renders "2 hours ago" timestamp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // "2 hours ago" appears at least once
      expect(find.text('2 hours ago'), findsWidgets);
    });

    testWidgets('renders "Yesterday" timestamp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      // "Yesterday" appears twice in the mock data
      expect(find.text('Yesterday'), findsNWidgets(2));
    });

    testWidgets('renders "2 days ago" timestamp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ActivityTimelinePlaceholder()),
          ),
        ),
      );

      expect(find.text('2 days ago'), findsNWidgets(2));
    });
  });
}
