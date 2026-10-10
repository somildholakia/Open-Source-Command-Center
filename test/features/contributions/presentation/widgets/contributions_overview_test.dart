import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_overview.dart';

void main() {
  group('ContributionsOverview', () {
    testWidgets('renders overview header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('renders SAMPLE DATA label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      expect(find.text('SAMPLE DATA'), findsOneWidget);
    });

    testWidgets('renders stat cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      expect(find.text('Pull Requests'), findsOneWidget);
      expect(find.text('Issues Resolved'), findsOneWidget);
      expect(find.text('Commits'), findsOneWidget);
      expect(find.text('Reviews'), findsOneWidget);
    });

    testWidgets('renders stat values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('47'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('renders heatmap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      expect(find.text('Contribution Heatmap'), findsOneWidget);
    });

    testWidgets('renders subtext indicators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsOverview())),
      );

      // Subtext values like "+3", "+1", "+12", "+5"
      expect(find.text('+3'), findsOneWidget);
      expect(find.text('+12'), findsOneWidget);
    });
  });
}
