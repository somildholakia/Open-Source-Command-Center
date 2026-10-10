import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/activity/presentation/widgets/activity_header.dart';

void main() {
  group('ActivityHeader', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActivityHeader())),
      );

      expect(find.text('Activity Timeline'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActivityHeader())),
      );

      expect(
        find.text('Chronological feed of your open-source contributions'),
        findsOneWidget,
      );
    });

    testWidgets('renders live feed badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActivityHeader())),
      );

      expect(find.text('LIVE FEED'), findsOneWidget);
      expect(find.byIcon(Icons.stream_rounded), findsOneWidget);
    });

    testWidgets('renders filter chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActivityHeader())),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('PRs'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Commits'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
    });

    testWidgets('"All" filter is selected by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActivityHeader())),
      );

      final allChip = find.ancestor(
        of: find.text('All'),
        matching: find.byType(Container),
      );

      expect(allChip, findsWidgets);
    });
  });
}
