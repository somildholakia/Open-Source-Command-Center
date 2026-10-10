import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opensource_command_center/features/contributions/presentation/widgets/contributions_stat_card.dart';

void main() {
  group('ContributionStatCard', () {
    const testCard = ContributionStatCard(
      label: 'Pull Requests',
      value: '12',
      icon: Icons.merge_type_rounded,
      accentColor: Color(0xFF8957E5),
      subtext: '+3',
    );

    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContributionStatCard(
              label: 'Test',
              value: '0',
              icon: Icons.circle,
              accentColor: Color(0xFF000000),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: testCard)),
      );

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: testCard)),
      );

      expect(find.byIcon(Icons.merge_type_rounded), findsOneWidget);
    });

    testWidgets('renders subtext', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: testCard)),
      );

      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('works without subtext', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContributionStatCard(
              label: 'Commits',
              value: '47',
              icon: Icons.commit_rounded,
              accentColor: Color(0xFF79C0FF),
            ),
          ),
        ),
      );

      expect(find.text('47'), findsOneWidget);
      expect(find.text('Commits'), findsOneWidget);
    });
  });
}
