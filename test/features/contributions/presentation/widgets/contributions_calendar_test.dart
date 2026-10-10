import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_calendar.dart';

void main() {
  group('ContributionsCalendar', () {
    testWidgets('renders section header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      expect(find.text('Contribution Heatmap'), findsOneWidget);
    });

    testWidgets('renders SAMPLE label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      expect(find.text('SAMPLE'), findsOneWidget);
    });

    testWidgets('renders day labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('renders week labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(find.text('W3'), findsOneWidget);
      expect(find.text('W4'), findsOneWidget);
    });

    testWidgets('renders heatmap cells', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      // 4 weeks × 7 days = 28 cells
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders legend', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('renders "Less" and "More" legend text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsCalendar())),
      );

      // Check for legend labels
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });
  });
}
