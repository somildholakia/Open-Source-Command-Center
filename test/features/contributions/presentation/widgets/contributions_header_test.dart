import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_header.dart';

void main() {
  group('ContributionsHeader', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(find.text('Contribution Analytics'), findsOneWidget);
    });

    testWidgets('renders description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(
        find.text('Track your open-source contribution patterns and trends'),
        findsOneWidget,
      );
    });

    testWidgets('renders ANALYTICS badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(find.text('ANALYTICS'), findsOneWidget);
    });

    testWidgets('renders SAMPLE DATA label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(find.text('SAMPLE DATA'), findsOneWidget);
    });

    testWidgets('renders filter chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('renders "All Time" chip as selected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContributionsHeader())),
      );

      expect(find.text('All Time'), findsOneWidget);
    });
  });
}
